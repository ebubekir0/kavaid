// kavaid/lib/utils/database_cleanup_utility.dart

import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class DatabaseCleanupUtility {
  static final DatabaseService _dbService = DatabaseService.instance;

  /// Veritabanı problemlerini kontrol et ve rapor al
  static Future<Map<String, dynamic>> analyzeDatabase() async {
    if (kIsWeb) return {'error': 'Web platformunda çalışmaz'};

    debugPrint('🔍 Veritabanı analizi başlatılıyor...');
    
    try {
      // 1. Duplicate harekeli kelimeleri bul
      final duplicates = await _dbService.findDuplicateHarekeliWords();
      debugPrint('📊 Duplicate harekeli kelime sayısı: ${duplicates.length}');
      
      // 2. Latin harf içeren kelimeleri bul
      final latinWords = await _dbService.findWordsWithLatinInArabic();
      debugPrint('📊 Latin harf içeren kelime sayısı: ${latinWords.length}');
      
      // 3. Toplam kelime sayısı
      final totalWords = await _dbService.getWordsCount();
      debugPrint('📊 Toplam kelime sayısı: $totalWords');
      
      // 4. Örnek problemli kelimeler göster
      if (duplicates.isNotEmpty) {
        debugPrint('\n🔴 Örnek Duplicate Kelimeler:');
        final samples = duplicates.entries.take(3);
        for (final entry in samples) {
          final harekeliKelime = entry.key;
          final count = entry.value.length;
          debugPrint('   "$harekeliKelime" → $count kez tekrarlanıyor');
        }
      }
      
      if (latinWords.isNotEmpty) {
        debugPrint('\n🔴 Örnek Latin Harf İçeren Kelimeler:');
        final samples = latinWords.take(3);
        for (final word in samples) {
          final kelime = word['kelime'] as String? ?? '';
          final harekeliKelime = word['harekeliKelime'] as String? ?? '';
          debugPrint('   "$kelime" / "$harekeliKelime"');
        }
      }
      
      return {
        'success': true,
        'totalWords': totalWords,
        'duplicateCount': duplicates.length,
        'duplicateWords': duplicates.keys.toList(),
        'latinCount': latinWords.length,
        'latinWords': latinWords.take(10).toList(), // İlk 10 örnek
        'duplicateDetails': duplicates,
      };
      
    } catch (e) {
      debugPrint('❌ Veritabanı analiz hatası: $e');
      return {'error': e.toString()};
    }
  }

  /// Otomatik veritabanı temizliği yap
  static Future<Map<String, dynamic>> performAutoCleanup() async {
    if (kIsWeb) return {'error': 'Web platformunda çalışmaz'};

    debugPrint('🧹 Otomatik veritabanı temizliği başlatılıyor...');
    
    try {
      final result = await _dbService.performDatabaseCleanup();
      
      debugPrint('✅ Otomatik temizlik tamamlandı!');
      
      return {
        'success': true,
        'duplicatesDeleted': result['duplicatesDeleted'] ?? 0,
        'latinDeleted': result['latinDeleted'] ?? 0,
        'totalRemaining': result['totalRemaining'] ?? 0,
      };
      
    } catch (e) {
      debugPrint('❌ Otomatik temizlik hatası: $e');
      return {'error': e.toString()};
    }
  }

  /// Debug: Veritabanı durumunu yazdır
  static Future<void> printDatabaseStatus() async {
    if (kIsWeb) {
      debugPrint('🌐 Web platformu - veritabanı kontrol edilemiyor');
      return;
    }

    debugPrint('\n${'='*50}');
    debugPrint('📊 VERİTABANI DURUM RAPORU');
    debugPrint('='*50);
    
    final analysis = await analyzeDatabase();
    
    if (analysis.containsKey('error')) {
      debugPrint('❌ Hata: ${analysis['error']}');
      return;
    }
    
    final totalWords = analysis['totalWords'] ?? 0;
    final duplicateCount = analysis['duplicateCount'] ?? 0;
    final latinCount = analysis['latinCount'] ?? 0;
    
    debugPrint('📈 Toplam kelime: $totalWords');
    debugPrint('🔄 Duplicate kelime türü: $duplicateCount');
    debugPrint('🔤 Latin harf içeren: $latinCount');
    
    final healthScore = totalWords > 0 
        ? ((totalWords - duplicateCount - latinCount) / totalWords * 100).round()
        : 0;
    
    debugPrint('💚 Sağlık skoru: $healthScore% ${_getHealthEmoji(healthScore)}');
    
    if (duplicateCount > 0 || latinCount > 0) {
      debugPrint('\n🔧 Önerilen işlem: performAutoCleanup() çağırın');
    } else {
      debugPrint('\n✨ Veritabanı temiz durumda!');
    }
    
    debugPrint('='*50 + '\n');
  }

  static String _getHealthEmoji(int score) {
    if (score >= 95) return '🟢';
    if (score >= 80) return '🟡';
    if (score >= 60) return '🟠';
    return '🔴';
  }

  /// Belirli bir harekeli kelimeyi kontrol et
  static Future<void> checkSpecificWord(String harekeliKelime) async {
    if (kIsWeb) return;

    debugPrint('🔍 "$harekeliKelime" kelimesi kontrol ediliyor...');
    
    try {
      final db = await _dbService.database;
      if (db == null) return;

      final results = await db.query(
        'words',
        where: 'harekeliKelime = ?',
        whereArgs: [harekeliKelime],
      );

      if (results.isEmpty) {
        debugPrint('❌ Kelime bulunamadı');
        return;
      }

      if (results.length == 1) {
        debugPrint('✅ Kelime tekil (sorun yok)');
      } else {
        debugPrint('🔴 Kelime ${results.length} kez duplicate!');
        for (int i = 0; i < results.length; i++) {
          final word = results[i];
          final kelime = word['kelime'] as String? ?? '';
          final anlam = word['anlam'] as String? ?? '';
          debugPrint('   ${i + 1}. "$kelime" → $anlam');
        }
      }

      // Latin harf kontrolü
      final arabicPattern = RegExp(r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\s]+$');
      final hasLatin = !arabicPattern.hasMatch(harekeliKelime);
      if (hasLatin) {
        debugPrint('🔤 Uyarı: Latin harf içeriyor!');
      }

    } catch (e) {
      debugPrint('❌ Kontrol hatası: $e');
    }
  }
}
