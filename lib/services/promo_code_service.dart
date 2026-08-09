import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/purchase_manager.dart';

/// Promo kod sistemi — Sosyal medya kampanyası için
/// Her kod tek kullanımlık ve kullanıcıya özeldir.
class PromoCodeService extends ChangeNotifier {
  static final PromoCodeService _instance = PromoCodeService._internal();
  factory PromoCodeService() => _instance;
  PromoCodeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== KULLANICI FONKSİYONLARI ==========

  /// Promo kodu kullan (redeem)
  /// Dönen değerler: 'success', 'invalid', 'expired', 'used', 'already_used', 'login_required'
  Future<String> redeemPromoCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'login_required';

    final trimmedCode = code.trim().toUpperCase();
    if (trimmedCode.isEmpty) return 'invalid';

    // 🧪 DEBUG TEST: "hxpruat" kodu ile 15 saniyelik premium (test amaçlı)
    if (kDebugMode && trimmedCode == 'HXPRUAT') {
      final testExpiry = DateTime.now().add(const Duration(minutes: 30));
      await _firestore.collection('users').doc(user.uid).set({
        'promoPremiumUntil': Timestamp.fromDate(testExpiry),
        'usedPromoCodes': FieldValue.arrayUnion(['DEBUG_TEST']),
        'lastPromoRedeemAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('🧪 [PromoCode] DEBUG TEST: 15 saniyelik premium aktif! Bitiş: $testExpiry');
      await PurchaseManager().checkPromoPremium(); // Anında algılaması için
      notifyListeners();
      return 'success';
    }

    try {
      final docRef = _firestore.collection('promo_codes').doc(trimmedCode);
      final doc = await docRef.get();

      if (!doc.exists) {
        debugPrint('❌ [PromoCode] Kod bulunamadı: $trimmedCode');
        return 'invalid';
      }

      final data = doc.data()!;
      
      // Aktif mi?
      if (data['isActive'] != true) {
        debugPrint('❌ [PromoCode] Kod deaktif: $trimmedCode');
        return 'expired';
      }

      // Süresi geçmiş mi?
      final expiresAt = data['expiresAt'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        debugPrint('❌ [PromoCode] Kod süresi dolmuş: $trimmedCode');
        return 'expired';
      }

      // Kullanım limiti aşılmış mı?
      final maxUses = data['maxUses'] as int? ?? 1;
      final usedCount = data['usedCount'] as int? ?? 0;
      if (usedCount >= maxUses) {
        debugPrint('❌ [PromoCode] Kod kullanım limiti dolmuş: $trimmedCode');
        return 'used';
      }

      // Bu kullanıcı daha önce kullanmış mı?
      final usedBy = List<String>.from(data['usedBy'] ?? []);
      if (usedBy.contains(user.uid)) {
        debugPrint('❌ [PromoCode] Kullanıcı bu kodu zaten kullanmış: $trimmedCode');
        return 'already_used';
      }

      // Bu kullanıcı daha önce herhangi bir promo kodu kullanmış mı?
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final usedCodes = List<String>.from(userData['usedPromoCodes'] ?? []);
        if (usedCodes.isNotEmpty) {
          debugPrint('⚠️ [PromoCode] Kullanıcı daha önce promo kodu kullanmış, yine de izin veriliyor.');
        }
      }

      // Her şey OK — kodu kullan
      final durationDays = data['durationDays'] as int? ?? 30;
      final premiumUntil = DateTime.now().add(Duration(days: durationDays));

      // Batch write ile atomik güncelleme
      final batch = _firestore.batch();

      // 1. Promo kodu güncelle
      batch.update(docRef, {
        'usedBy': FieldValue.arrayUnion([user.uid]),
        'usedCount': FieldValue.increment(1),
        'lastUsedAt': FieldValue.serverTimestamp(),
      });

      // 2. Kullanıcı dokümanını güncelle
      batch.set(
        _firestore.collection('users').doc(user.uid),
        {
          'promoPremiumUntil': Timestamp.fromDate(premiumUntil),
          'usedPromoCodes': FieldValue.arrayUnion([trimmedCode]),
          'lastPromoRedeemAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      debugPrint('✅ [PromoCode] Kod başarıyla kullanıldı: $trimmedCode -> Premium ${premiumUntil.toString()}\'e kadar');
      await PurchaseManager().checkPromoPremium(); // Anında algılaması için
      notifyListeners();
      return 'success';
    } catch (e) {
      debugPrint('❌ [PromoCode] Redeem hatası: $e');
      return 'error';
    }
  }

  /// Kullanıcının promo premium'u aktif mi?
  Future<bool> isPromoPremiumActive() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Varsayılan çekme (en güncel veriyi otomatik dener)
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      
      final promoPremiumUntil = data['promoPremiumUntil'] as Timestamp?;
      if (promoPremiumUntil == null) return false;

      final isActive = promoPremiumUntil.toDate().isAfter(DateTime.now());
      debugPrint('🎁 [PromoCode] Premium kontrol: aktif=$isActive, bitiş=${promoPremiumUntil.toDate()}');
      return isActive;
    } catch (e) {
      debugPrint('❌ [PromoCode] Premium kontrol hatası: $e');
      return false;
    }
  }

  /// Bu hesap daha önce herhangi bir promo kodu kullanmış mı? (Hesap bazlı kontrol)
  Future<bool> hasUsedAnyPromoCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Taze veri için sunucudan çekiyoruz
      DocumentSnapshot doc;
      try {
        doc = await _firestore.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
      } catch (_) {
        doc = await _firestore.collection('users').doc(user.uid).get(const GetOptions(source: Source.cache));
      }
      
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      
      final usedCodes = List<String>.from(data['usedPromoCodes'] ?? []);
      // DEBUG_TEST kodunu sayma (test kodu)
      final realCodes = usedCodes.where((c) => c != 'DEBUG_TEST').toList();
      return realCodes.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [PromoCode] hasUsedAnyPromoCode hatası: $e');
      return false;
    }
  }

  /// Promo premium bitiş tarihi
  Future<DateTime?> getPromoExpiryDate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final promoPremiumUntil = data['promoPremiumUntil'] as Timestamp?;
      if (promoPremiumUntil == null) return null;

      final expiryDate = promoPremiumUntil.toDate();
      if (expiryDate.isBefore(DateTime.now())) return null;

      return expiryDate;
    } catch (e) {
      debugPrint('❌ [PromoCode] Expiry kontrol hatası: $e');
      return null;
    }
  }

  // ========== ADMİN FONKSİYONLARI ==========

  /// Tek bir promo kodu oluştur
  Future<String?> createPromoCode({
    int durationDays = 30,
    int maxUses = 1,
    DateTime? expiresAt,
  }) async {
    try {
      final code = _generateCode();
      await _firestore.collection('promo_codes').doc(code).set({
        'code': code,
        'type': 'premium_${durationDays}_days',
        'durationDays': durationDays,
        'maxUses': maxUses,
        'usedBy': [],
        'usedCount': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
      });

      debugPrint('✅ [PromoCode] Kod oluşturuldu: $code');
      return code;
    } catch (e) {
      debugPrint('❌ [PromoCode] Kod oluşturma hatası: $e');
      return null;
    }
  }

  /// Toplu promo kod oluştur
  Future<List<String>> createBatchPromoCodes({
    required int count,
    int durationDays = 30,
    int maxUses = 1,
  }) async {
    final codes = <String>[];
    for (int i = 0; i < count; i++) {
      final code = await createPromoCode(
        durationDays: durationDays,
        maxUses: maxUses,
      );
      if (code != null) codes.add(code);
    }
    debugPrint('✅ [PromoCode] ${codes.length}/$count kod toplu oluşturuldu');
    return codes;
  }

  /// Tüm promo kodlarını listele (admin)
  Future<List<Map<String, dynamic>>> listPromoCodes({bool activeOnly = false}) async {
    try {
      Query query = _firestore.collection('promo_codes').orderBy('createdAt', descending: true);
      
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ [PromoCode] Liste hatası: $e');
      return [];
    }
  }

  /// Promo kodu deaktif et
  Future<bool> deactivatePromoCode(String code) async {
    try {
      await _firestore.collection('promo_codes').doc(code.toUpperCase()).update({
        'isActive': false,
      });
      debugPrint('✅ [PromoCode] Kod deaktif edildi: $code');
      return true;
    } catch (e) {
      debugPrint('❌ [PromoCode] Deaktif hatası: $e');
      return false;
    }
  }

  /// Promo kodu sil
  Future<bool> deletePromoCode(String code) async {
    try {
      await _firestore.collection('promo_codes').doc(code.toUpperCase()).delete();
      debugPrint('✅ [PromoCode] Kod silindi: $code');
      return true;
    } catch (e) {
      debugPrint('❌ [PromoCode] Silme hatası: $e');
      return false;
    }
  }

  // ========== YARDIMCI ==========

  /// 8 karakterli benzersiz promo kodu oluştur (KVAID + 4 alfanumerik)
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Karışıklık olmaması için I,O,0,1 çıkarıldı
    final random = Random.secure();
    final suffix = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'KVD$suffix'; // Örnek: KVDH7X3P
  }
}
