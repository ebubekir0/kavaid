// kavaid/lib/utils/database_cleanup_utility.dart

import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class DatabaseCleanupUtility {
  static final DatabaseService _dbService = DatabaseService.instance;

  /// Veritabanı problemlerini kontrol et ve rapor al
  static Future<Map<String, dynamic>> analyzeDatabase() async {
    if (kIsWeb) return {'error': 'Web platformunda çalışmaz'};

    print('🔍 Veritabanı analizi başlatılıyor...');
    
    try {
      // 1. Duplicate harekeli kelimeleri bul
      final duplicates = await _dbService.findDuplicateHarekeliWords();
      print('📊 Duplicate harekeli kelime sayısı: ${duplicates.length}');
      
      // 2. Latin harf içeren kelimeleri bul
      final latinWords = await _dbService.findWordsWithLatinInArabic();
      print('📊 Latin harf içeren kelime sayısı: ${latinWords.length}');
      
      // 3. Toplam kelime sayısı
      final totalWords = await _dbService.getWordsCount();
      print('📊 Toplam kelime sayısı: $totalWords');
      
      // 4. Örnek problemli kelimeler göster
      if (duplicates.isNotEmpty) {
        print('\n🔴 Örnek Duplicate Kelimeler:');
        final samples = duplicates.entries.take(3);
        for (final entry in samples) {
          final harekeliKelime = entry.key;
          final count = entry.value.length;
          print('   "$harekeliKelime" → $count kez tekrarlanıyor');
        }
      }
      
      if (latinWords.isNotEmpty) {
        print('\n🔴 Örnek Latin Harf İçeren Kelimeler:');
        final samples = latinWords.take(3);
        for (final word in samples) {
          final kelime = word['kelime'] as String? ?? '';
          final harekeliKelime = word['harekeliKelime'] as String? ?? '';
          print('   "$kelime" / "$harekeliKelime"');
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
      print('❌ Veritabanı analiz hatası: $e');
      return {'error': e.toString()};
    }
  }

  /// Otomatik veritabanı temizliği yap
  static Future<Map<String, dynamic>> performAutoCleanup() async {
    if (kIsWeb) return {'error': 'Web platformunda çalışmaz'};

    print('🧹 Otomatik veritabanı temizliği başlatılıyor...');
    
    try {
      final result = await _dbService.performDatabaseCleanup();
      
      print('✅ Otomatik temizlik tamamlandı!');
      
      return {
        'success': true,
        'duplicatesDeleted': result['duplicatesDeleted'] ?? 0,
        'latinDeleted': result['latinDeleted'] ?? 0,
        'totalRemaining': result['totalRemaining'] ?? 0,
      };
      
    } catch (e) {
      print('❌ Otomatik temizlik hatası: $e');
      return {'error': e.toString()};
    }
  }

  /// Debug: Veritabanı durumunu yazdır
  static Future<void> printDatabaseStatus() async {
    if (kIsWeb) {
      print('🌐 Web platformu - veritabanı kontrol edilemiyor');
      return;
    }

    print('\n' + '='*50);
    print('📊 VERİTABANI DURUM RAPORU');
    print('='*50);
    
    final analysis = await analyzeDatabase();
    
    if (analysis.containsKey('error')) {
      print('❌ Hata: ${analysis['error']}');
      return;
    }
    
    final totalWords = analysis['totalWords'] ?? 0;
    final duplicateCount = analysis['duplicateCount'] ?? 0;
    final latinCount = analysis['latinCount'] ?? 0;
    
    print('📈 Toplam kelime: $totalWords');
    print('🔄 Duplicate kelime türü: $duplicateCount');
    print('🔤 Latin harf içeren: $latinCount');
    
    final healthScore = totalWords > 0 
        ? ((totalWords - duplicateCount - latinCount) / totalWords * 100).round()
        : 0;
    
    print('💚 Sağlık skoru: $healthScore% ${_getHealthEmoji(healthScore)}');
    
    if (duplicateCount > 0 || latinCount > 0) {
      print('\n🔧 Önerilen işlem: performAutoCleanup() çağırın');
    } else {
      print('\n✨ Veritabanı temiz durumda!');
    }
    
    print('='*50 + '\n');
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

    print('🔍 "$harekeliKelime" kelimesi kontrol ediliyor...');
    
    try {
      final db = await _dbService.database;
      if (db == null) return;

      final results = await db.query(
        'words',
        where: 'harekeliKelime = ?',
        whereArgs: [harekeliKelime],
      );

      if (results.isEmpty) {
        print('❌ Kelime bulunamadı');
        return;
      }

      if (results.length == 1) {
        print('✅ Kelime tekil (sorun yok)');
      } else {
        print('🔴 Kelime ${results.length} kez duplicate!');
        for (int i = 0; i < results.length; i++) {
          final word = results[i];
          final kelime = word['kelime'] as String? ?? '';
          final anlam = word['anlam'] as String? ?? '';
          print('   ${i + 1}. "$kelime" → $anlam');
        }
      }

      // Latin harf kontrolü
      final arabicPattern = RegExp(r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\s]+$');
      final hasLatin = !arabicPattern.hasMatch(harekeliKelime);
      if (hasLatin) {
        print('🔤 Uyarı: Latin harf içeriyor!');
      }

    } catch (e) {
      print('❌ Kontrol hatası: $e');
    }
  }
}
