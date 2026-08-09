import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_manager.dart';

enum TranslationAccessStatus {
  allowed,
  loginRequired,
  limitReached,
  unavailable,
}

class TranslationAccessResult {
  final TranslationAccessStatus status;
  final int remaining;
  final String message;

  const TranslationAccessResult({
    required this.status,
    required this.remaining,
    required this.message,
  });

  bool get isAllowed => status == TranslationAccessStatus.allowed;
}

class TranslationQuotaService extends ChangeNotifier {
  static final TranslationQuotaService _instance =
      TranslationQuotaService._internal();
  factory TranslationQuotaService() => _instance;
  TranslationQuotaService._internal();

  static const int freeLimit = 25;
  static const String _localUsageKey = 'translation_local_usage_count_v1';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PurchaseManager _purchaseManager = PurchaseManager();

  int _used = 0;
  bool _isLoading = false;

  int get used => _used;
  int get remaining => (freeLimit - _used).clamp(0, freeLimit).toInt();
  bool get isLoading => _isLoading;
  bool get isPremium => _purchaseManager.isPremium;

  Future<void> refresh() async {
    final user = _auth.currentUser;
    if (user == null || _purchaseManager.isPremium) {
      _used = 0;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final usageDoc = await _usageRef(user.uid).get();
      final accountUsed = (usageDoc.data()?['count'] as num?)?.toInt() ?? 0;
      final localUsed = await _getLocalUsageCount();
      _used = _effectiveUsed(accountUsed, localUsed);
    } catch (e) {
      debugPrint('[TranslationQuota] refresh failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TranslationAccessResult> reserveTranslation() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const TranslationAccessResult(
        status: TranslationAccessStatus.loginRequired,
        remaining: 0,
        message: 'Ceviri icin giris yapman gerekiyor.',
      );
    }

    if (_purchaseManager.isPremium) {
      return const TranslationAccessResult(
        status: TranslationAccessStatus.allowed,
        remaining: freeLimit,
        message: 'Premium kullanici.',
      );
    }

    try {
      final localUsed = await _getLocalUsageCount();
      if (localUsed >= freeLimit) {
        _used = freeLimit;
        notifyListeners();
        return const TranslationAccessResult(
          status: TranslationAccessStatus.limitReached,
          remaining: 0,
          message: "Daha fazla ceviri yapabilmek icin Premium'a gecin.",
        );
      }

      final usageRef = _usageRef(user.uid);
      final accountNewCount = await _firestore.runTransaction<int>((
        transaction,
      ) async {
        final snapshot = await transaction.get(usageRef);
        final current = (snapshot.data()?['count'] as num?)?.toInt() ?? 0;
        if (current >= freeLimit) return freeLimit + 1;

        transaction.set(usageRef, {
          'count': current + 1,
          'limit': freeLimit,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return current + 1;
      });

      if (accountNewCount > freeLimit) {
        _used = freeLimit;
        notifyListeners();
        return const TranslationAccessResult(
          status: TranslationAccessStatus.limitReached,
          remaining: 0,
          message: "Daha fazla ceviri yapabilmek icin Premium'a gecin.",
        );
      }

      final localNewCount = await _setLocalUsageCount(localUsed + 1);
      _used = _effectiveUsed(accountNewCount, localNewCount);
      notifyListeners();

      return TranslationAccessResult(
        status: TranslationAccessStatus.allowed,
        remaining: (freeLimit - _used).clamp(0, freeLimit).toInt(),
        message: 'Ceviri hakki kullanildi.',
      );
    } catch (e) {
      debugPrint('[TranslationQuota] reserve failed: $e');
      return const TranslationAccessResult(
        status: TranslationAccessStatus.unavailable,
        remaining: 0,
        message: 'Ceviri hakki kontrol edilemedi. Baglantini kontrol et.',
      );
    }
  }

  DocumentReference<Map<String, dynamic>> _usageRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('featureUsage')
        .doc('dialectTranslation');
  }

  int _effectiveUsed(int accountUsed, int localUsed) {
    return accountUsed > localUsed
        ? accountUsed.clamp(0, freeLimit).toInt()
        : localUsed.clamp(0, freeLimit).toInt();
  }

  Future<int> _getLocalUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_localUsageKey) ?? 0;
  }

  Future<int> _setLocalUsageCount(int count) async {
    final value = count.clamp(0, freeLimit).toInt();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_localUsageKey, value);
    return value;
  }
}
