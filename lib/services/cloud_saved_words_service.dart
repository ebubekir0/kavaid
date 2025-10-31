import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/word_model.dart';
import 'auth_service.dart';
import 'saved_words_service.dart';

/// CloudSavedWordsService
/// Kullanıcının kayıtlı kelimelerini Google hesabına (Firestore) yedekler ve geri yükler.
class CloudSavedWordsService {
  static final CloudSavedWordsService _instance = CloudSavedWordsService._internal();
  factory CloudSavedWordsService() => _instance;
  CloudSavedWordsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  final SavedWordsService _local = SavedWordsService();

  /// Kullanıcının kayıtlı kelimelerini Firestore'a yükler (merge).
  Future<void> syncUpFromLocal() async {
    if (!_auth.isSignedIn) return;

    final List<WordModel> localWords = _local.savedWords;

    if (localWords.isEmpty) return;

    debugPrint('[CloudSavedWords] syncUpFromLocal: ${localWords.length} kelime');

    final batch = _firestore.batch();
    final userCol = _firestore.collection('users').doc(_auth.userId!).collection('saved_words');

    for (final word in localWords) {
      final docRef = userCol.doc(word.kelime);
      batch.set(docRef, {
        'kelime': word.kelime,
        'word_data': word.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint('[CloudSavedWords] Buluta yedekleme tamamlandı');
  }

  /// Firestore'daki kelimeleri indirir ve lokale merge eder.
  Future<int> syncDownToLocal() async {
    if (!_auth.isSignedIn) return 0;

    final userCol = _firestore.collection('users').doc(_auth.userId!).collection('saved_words');

    final snapshot = await userCol.get();
    if (snapshot.docs.isEmpty) return 0;

    int added = 0;
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        final dynamic raw = data['word_data'];
        // Eski sürümler için JSON string desteği
        final Map<String, dynamic> jsonMap = raw is String
            ? jsonDecode(raw) as Map<String, dynamic>
            : Map<String, dynamic>.from(raw as Map);
        final word = WordModel.fromJson(jsonMap);
        final already = _local.isWordSavedSync(word);
        if (!already) {
          await _local.saveWord(word);
          added++;
        }
      } catch (e) {
        debugPrint('[CloudSavedWords] syncDown parse/güncelleme hatası: $e');
      }
    }

    debugPrint('[CloudSavedWords] Buluttan indirme tamamlandı. Yeni eklenen: $added');
    return added;
  }

  /// Buluttan belirli bir kelimeyi siler
  Future<void> removeWordFromCloud(String kelime) async {
    if (!_auth.isSignedIn) return;

    try {
      final userCol = _firestore.collection('users').doc(_auth.userId!).collection('saved_words');
      await userCol.doc(kelime).delete();
      debugPrint('[CloudSavedWords] Kelime buluttan silindi: $kelime');
    } catch (e) {
      debugPrint('[CloudSavedWords] Buluttan silme hatası: $e');
    }
  }

  /// Yerel olarak silinen kelimeleri buluttan da siler
  Future<void> syncDeletedWords() async {
    if (!_auth.isSignedIn) return;

    try {
      // Buluttaki tüm kelimeleri al
      final userCol = _firestore.collection('users').doc(_auth.userId!).collection('saved_words');
      final snapshot = await userCol.get();
      
      // Yerel kayıtlı kelimeleri al
      final localWords = _local.savedWords.map((w) => w.kelime).toSet();
      
      // Bulutta olup yerel olarak olmayan kelimeleri sil
      final batch = _firestore.batch();
      int deletedCount = 0;
      
      for (final doc in snapshot.docs) {
        final kelime = doc.id;
        if (!localWords.contains(kelime)) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }
      
      if (deletedCount > 0) {
        await batch.commit();
        debugPrint('[CloudSavedWords] Buluttan $deletedCount kelime silindi');
      }
    } catch (e) {
      debugPrint('[CloudSavedWords] Silinen kelimeler senkronizasyon hatası: $e');
    }
  }

  /// İki yönlü eşitleme: önce buluttan indir, ardından lokali buluta yükle, silinen kelimeleri temizle
  Future<void> mergeSync() async {
    if (!_auth.isSignedIn) return;
    await _local.initialize();
    await syncDownToLocal();
    await syncUpFromLocal();
    await syncDeletedWords(); // Silinen kelimeleri de senkronize et
    
    // Senkronizasyon sonrası UI'ı güncelle
    await _local.refresh();
    debugPrint('[CloudSavedWords] UI güncellendi');
  }
}



