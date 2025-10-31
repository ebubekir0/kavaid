// kavaid/lib/services/sync_service.dart

import 'package:flutter/foundation.dart';
import 'package:kavaid/models/word_model.dart';
import 'package:kavaid/services/database_service.dart';
import 'package:kavaid/services/database_initialization_service.dart';
import 'package:kavaid/services/global_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _dbService = DatabaseService.instance;
  final DatabaseInitializationService _dbInitService = DatabaseInitializationService.instance;
  final GlobalConfigService _configService = GlobalConfigService();

  bool _isDbInitializing = false;
  static const String _syncCompletedKey = 'embedded_data_loaded';

  Future<void> initializeLocalDatabase({bool force = false, void Function(int wordCount, int approxBytes)? onFetched}) async {
    // Web platformunda database kullanmıyoruz
    if (kIsWeb) {
      debugPrint('🌐 [Sync] Web platformu - database başlatma atlanıyor');
      return;
    }
    
    if (_isDbInitializing && !force) {
      debugPrint('Veritabanı başlatma zaten devam ediyor. Atlanıyor.');
      return;
    }
    _isDbInitializing = true;
    debugPrint('Yerel veritabanı durumu kontrol ediliyor (force: $force)...');

    try {
      final db = await _dbService.database;
      if (db == null) {
        debugPrint('🌐 [Sync] Database null - web platformu');
        _isDbInitializing = false;
        return;
      }
      
      // 1. Veritabanının fiziksel durumunu kontrol et
      final tableInfo = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='words'");
      bool tableExists = tableInfo.isNotEmpty;
      int wordCount = 0;
      if (tableExists) {
        final countResult = await db.rawQuery('SELECT COUNT(*) FROM words');
        wordCount = Sqflite.firstIntValue(countResult) ?? 0;
      }

      // 2. Embedded data yüklenmesi gerekip gerekiyor mu?
      // Koşullar:
      // - Zorlanmışsa (force == true)
      // - 'words' tablosu yoksa
      // - 'words' tablosu boşsa
      if (force || !tableExists || wordCount == 0) {
        if (force) {
            debugPrint('Zorunlu veritabanı yüklemesi tetiklendi.');
        } else {
            debugPrint('Yerel veritabanı boş veya bozuk. Embedded data\'dan yüklenecek.');
        }

        try {
          // Embedded data'yı yükle
          final success = await _dbInitService.initializeDatabase();
          
          if (success) {
            final countResult = await db.rawQuery('SELECT COUNT(*) FROM words');
            final finalWordCount = Sqflite.firstIntValue(countResult) ?? 0;
            
            // Callback gönder
            try {
              onFetched?.call(finalWordCount, 0);
            } catch (e) {
              debugPrint('onFetched callback çağrısı hatası (yok sayılıyor): $e');
            }
            
            debugPrint('Lokal veritabanı başarıyla $finalWordCount kelime ile kuruldu.');
          } else {
            debugPrint('Embedded data yüklenemedi.');
          }
        } catch (e) {
          debugPrint('initializeLocalDatabase sırasında hata: $e');
        }
      } else {
        debugPrint('Lokal veritabanı zaten dolu ($wordCount kelime). Yükleme atlanıyor.');
        // Bayrağın doğru ayarlandığından emin ol
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool(_syncCompletedKey) ?? false)) {
          await prefs.setBool(_syncCompletedKey, true);
        }
      }
    } catch (e) {
        debugPrint('Yerel veritabanı durumu kontrol edilirken kritik hata: $e');
    } finally {
      _isDbInitializing = false;
    }
  }

  Future<void> handleAiFoundWord(WordModel word) async {
    debugPrint('Yeni AI kelimesi işleniyor: ${word.kelime}');
    // AI kelimelerini pending_ai_words tablosunda sakla
    await _dbService.addPendingAiWord(word);
    
    final pendingCount = await _dbService.getPendingAiWordsCount();
    debugPrint('Bekleyen AI kelime sayısı: $pendingCount');
    
    // Not: Firebase kaldırıldığı için artık senkronizasyon yapılmıyor
    // AI kelimeleri lokal olarak pending_ai_words tablosunda saklanıyor
  }
  
  // Bekleyen AI kelimelerini ana veritabanına taşı
  Future<void> movePendingWordsToMainDatabase() async {
    try {
      debugPrint('📝 Bekleyen AI kelimeleri ana veritabanına taşınıyor...');
      
      // Bekleyen kelimeleri al
      final pendingWords = await _dbService.getPendingAiWords();
      
      if (pendingWords.isEmpty) {
        debugPrint('Taşınacak bekleyen kelime yok.');
        return;
      }
      
      debugPrint('${pendingWords.length} kelime ana veritabanına taşınacak.');
      
      // Ana veritabanına ekle (words tablosuna)
      for (final word in pendingWords) {
        try {
          // Örnek cümlelerin doğru aktarıldığından emin ol
          if (word.ornekCumleler != null && word.ornekCumleler!.isNotEmpty) {
            debugPrint('📖 Kelime örnek cümleleriyle: ${word.kelime} - ${word.ornekCumleler!.length} örnek');
            // İlk örnek cümleyi detaylı logla
            final firstExample = word.ornekCumleler![0];
            debugPrint('   Arapça cümle: ${firstExample['arapcaCumle'] ?? 'null'}');
            debugPrint('   Türkçe çeviri: ${firstExample['turkceCeviri'] ?? 'null'}');
          }
          
          // Ana veritabanına ekle
          await _dbService.addWord(word);
          debugPrint('✅ Kelime ana veritabanına eklendi: ${word.kelime}');
        } catch (e) {
          debugPrint('❌ Kelime eklenemedi: ${word.kelime} - $e');
        }
      }
      
      // Pending tablosunu temizle
      await _dbService.clearPendingAiWords();
      
      debugPrint('✅ ${pendingWords.length} kelime başarıyla ana veritabanına taşındı.');
      
    } catch (e) {
      debugPrint('❌ movePendingWordsToMainDatabase hatası: $e');
    }
  }
}