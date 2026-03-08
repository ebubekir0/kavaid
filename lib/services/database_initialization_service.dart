// kavaid/lib/services/database_initialization_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../data/embedded_words_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseInitializationService {
  static final DatabaseInitializationService instance = DatabaseInitializationService._init();
  DatabaseInitializationService._init();

  final DatabaseService _dbService = DatabaseService.instance;
  static const String _dbVersionKey = 'database_version_embedded';
  static const int _currentDbVersion = 5000; // pubspec version ile uyumlu olabilir

  Function(double progress, String message)? onProgress;

  Future<bool> isDatabaseUpToDate() async {
    if (kIsWeb) return true;
    
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt(_dbVersionKey) ?? 0;
    
    if (savedVersion < _currentDbVersion) return false;
    
    // Ayrıca kelime sayısını kontrol et
    final wordCount = await _dbService.getWordsCount();
    return wordCount > 0;
  }

  Future<Map<String, dynamic>> getDatabaseInfo() async {
    if (kIsWeb) return {'wordCount': 0};
    final count = await _dbService.getWordsCount();
    return {'wordCount': count};
  }

  Future<bool> forceReloadEmbeddedData() async {
    return await initializeDatabase(force: true);
  }

  Future<bool> initializeDatabase({bool force = false}) async {
    if (kIsWeb) return true;

    try {
      final db = await _dbService.database;
      if (db == null) return false;

      onProgress?.call(0.1, 'Sözlük verileri hazılanıyor...');
      
      // Batch işlemi için verileri hazırla
      final List<Map<String, dynamic>> words = embeddedWordsData;
      final int totalWords = words.length;
      
      if (totalWords == 0) return true;

      // Veritabanını temizle (eğer force ise)
      if (force) {
        await db.delete('words');
      }

      onProgress?.call(0.2, 'Veritabanına aktarılıyor...');

      // Batch insert (Performans için)
      int batchSize = 500;
      for (int i = 0; i < totalWords; i += batchSize) {
        final end = (i + batchSize < totalWords) ? i + batchSize : totalWords;
        final batch = db.batch();
        
        for (int j = i; j < end; j++) {
          final wordData = words[j];
          batch.insert('words', {
            'kelime': wordData['kelime'],
            'harekeliKelime': wordData['harekeliKelime'],
            'anlam': wordData['anlam'],
            'koku': wordData['koku'],
            'dilbilgiselOzellikler': _safeJsonEncode(wordData['dilbilgiselOzellikler']),
            'ornekCumleler': _safeJsonEncode(wordData['ornekCumleler']),
            'fiilCekimler': _safeJsonEncode(wordData['fiilCekimler']),
            'eklenmeTarihi': wordData['eklenmeTarihi'] ?? DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        
        await batch.commit(noResult: true);
        
        double progress = 0.2 + (0.7 * (end / totalWords));
        onProgress?.call(progress, 'Yükleniyor: $end / $totalWords');
      }

      // Versiyonu kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dbVersionKey, _currentDbVersion);

      onProgress?.call(1.0, 'Sözlük hazır!');
      return true;
    } catch (e) {
      debugPrint('DatabaseInitializationService hatası: $e');
      return false;
    }
  }

  String _safeJsonEncode(dynamic data) {
    try {
      return json.encode(data ?? {});
    } catch (e) {
      return '{}';
    }
  }
}
