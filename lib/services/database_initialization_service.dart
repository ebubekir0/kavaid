import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../data/embedded_words.dart';
import '../utils/perf_log.dart';
import 'package:kavaid/l10n/l10n.dart';

class DatabaseInitializationService {
  static final DatabaseInitializationService instance =
      DatabaseInitializationService._init();

  DatabaseInitializationService._init();

  /// Yerel SQLite sözlüğünün hangi veri sürümünden kurulduğunu tutar.
  /// Uygulamayla gelen veri (embeddedWordsVersion) değişince sözlük
  /// açılışta yeniden kurulur; eskiden sabit bir "v3" bayrağı kullanıldığı
  /// için güncellenen kelimeler mevcut kullanıcılara hiç ulaşmıyordu.
  static const String dataVersionKey = 'embedded_words_version';

  // Eski sürümlerin kullandığı anahtarlar (temizlik için)
  static const List<String> _legacyKeys = [
    'embedded_data_loaded',
    'embedded_data_loaded_v3',
  ];

  // Progress callback
  Function(double progress, String message)? onProgress;

  /// Yerel sözlük, uygulamayla gelen veri sürümüyle aynı mı?
  Future<bool> isInstalledDataCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(dataVersionKey) == await EmbeddedWords.currentVersion();
  }

  /// Embedded data'yı yükle
  Future<bool> initializeDatabase() async {
    // Kelime listesini bekleyen arama izolesi (liste verilene kadar dolu)
    SendPort? searchPort;
    try {
      onProgress?.call(0.0, l10n.sozlukHazirlaniyor);

      // Lokal database kontrolü
      final dbService = DatabaseService.instance;
      final existingCount = await dbService.getWordsCount();

      // Veritabanı dolu ve uygulamadaki veriyle aynı sürümdeyse atla
      final prefs = await SharedPreferences.getInstance();
      if (existingCount > 0 && await isInstalledDataCurrent()) {
        onProgress?.call(1.0, l10n.sozlukHazirExistingcountKelimeMevcut(existingCount));
        return true;
      }

      onProgress?.call(0.1, l10n.sozlukAyarlaniyor);

      // Uygulamayla gelen sözlük verisi bir kez çözülür: önce veritabanına yazılır,
      // sonra aynı liste arama izolesine verilir ve fihrist ondan kurulur (izole
      // ikinci kez çözmez). Fihrist yazmayla aynı anda kurulmuyor: izoleler aynı
      // çöp toplayıcıyı paylaştığı için yazma 4-7 sn uzuyordu (Galaxy A16).
      searchPort = await DatabaseService.searchWordsPort();
      final wordsJson = await EmbeddedWords.load();
      PerfLog.mark('dictDecoded');

      onProgress?.call(0.3, l10n.kelimelerYukleniyor);

      // İlk kurulumda Android input dispatch'i bloklanmasın diye parça parça yaz.
      await dbService.recreateWordsTableFromEmbeddedMaps(
        wordsJson,
        onChunkCommitted: (loadedCount) {
          final progress = 0.3 + (0.6 * (loadedCount / wordsJson.length));
          onProgress?.call(progress, l10n.sozlukAyarlaniyor);
        },
      );

      onProgress?.call(0.9, l10n.sozlukAyarlaniyor);
      PerfLog.mark('dbWritten');

      searchPort?.send(wordsJson);
      searchPort = null;

      // Hangi veri sürümünün kurulduğunu işaretle
      final version = await EmbeddedWords.currentVersion();
      await prefs.setString(dataVersionKey, version);
      await prefs.setString('database_version', 'embedded_$version');
      await prefs.remove('embedded_data_loaded_v3');
      await prefs.setString(
        'last_update_date',
        DateTime.now().toIso8601String(),
      );

      onProgress?.call(1.0, l10n.sozlukHazir2);

      return true;
    } catch (e) {
      debugPrint('Database initialization hatası: $e');
      onProgress?.call(0.0, 'Hata: ${e.toString()}');

      // Liste arama izolesine verilmedi: arama sözlüğü kendisi çözsün
      if (searchPort != null) DatabaseService.restartSearch();

      // Hata durumunda lokal database varsa true dön
      final dbService = DatabaseService.instance;
      final count = await dbService.getWordsCount();

      if (count > 0) {
        onProgress?.call(1.0, l10n.mevcutVeritabaniKullanilacak);
        return true;
      }

      return false;
    }
  }

  /// Database bilgilerini getir
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final dbService = DatabaseService.instance;

    return {
      'version': prefs.getString('database_version') ?? 'Bilinmiyor',
      'lastUpdate': prefs.getString('last_update_date') ?? l10n.hicGuncellenmedi,
      'wordCount': await dbService.getWordsCount(),
      'pendingAiWords': await dbService.getPendingAiWordsCount(),
      'hasInternet': false, // Artık internet kontrolü yapmıyoruz
    };
  }

  /// Database'i temizle ve embedded data'yı yeniden yükle
  Future<bool> forceReloadEmbeddedData() async {
    try {
      debugPrint('🔄 Force reload embedded data başlatılıyor...');

      // SharedPreferences'ı temizle (eski ve yeni key'ler)
      final prefs = await SharedPreferences.getInstance();
      for (final key in _legacyKeys) {
        await prefs.remove(key);
      }
      await prefs.remove(dataVersionKey);
      await prefs.remove('database_version');
      await prefs.remove('last_update_date');
      debugPrint('✅ SharedPreferences temizlendi');

      // Database'i sıfırla
      final dbService = DatabaseService.instance;
      await dbService.recreateWordsTable([]);
      debugPrint('✅ Database temizlendi');

      // Yeni embedded data'yı yükle
      final success = await initializeDatabase();

      if (success) {
        debugPrint('✅ Embedded data başarıyla yeniden yüklendi');
        return true;
      } else {
        debugPrint('❌ Embedded data yüklenemedi');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Force reload hatası: $e');
      return false;
    }
  }

  /// Database'i temizle (sadece geliştirme için)
  Future<void> clearDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('database_version');
    await prefs.remove('last_update_date');
    await prefs.remove(dataVersionKey);
    for (final key in _legacyKeys) {
      await prefs.remove(key);
    }

    final dbService = DatabaseService.instance;
    await dbService.recreateWordsTable([]);
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
