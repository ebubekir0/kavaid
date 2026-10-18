import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_ranking.dart' show foldLatin, normalizeArabic;

class EmsileDatabaseService {
  static final EmsileDatabaseService instance = EmsileDatabaseService._init();
  static Database? _database;

  EmsileDatabaseService._init();

  static const String _dbAsset = 'assets/data/emsile.db';
  static const String _dbName = 'emsile.db';
  static const String _tempName = 'emsile.db.installing';
  static const String _sizePrefsKey = 'emsile_db_installed_size_v1';

  /// Yazma tamponu. 30 MB'lık DB'yi tek seferde writeAsBytes ile yazmak
  /// ikinci bir büyük tampon oluşturuyordu; parça parça yazıyoruz.
  static const int _writeChunkSize = 512 * 1024;

  /// DB'nin gerçek boyutundan küçükse dosya yarım kalmış demektir.
  static const int _minPlausibleSize = 1024 * 1024;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openVerified();
    return _database!;
  }

  /// Kalıcı çözüm: DB'yi "kur-oku-yoksa kendini yeniden kur" mantığıyla aç.
  ///
  /// Önceden sadece `databaseExists` kontrolü vardı. Yazma sırasında uygulama
  /// öldürülürse (iOS jetsam, düşük bellek, disk dolması) dosya YARIM olarak
  /// diskte kalıyordu. `exists == true` olduğu için bir daha asla kopyalanmıyor
  /// ve Emsile kalıcı olarak bozuk kalıyordu. Veri silinene kadar düzelmiyordu.
  ///
  /// Artık:
  ///  - kurulum geçici dosyaya yapılır (yarım yazma hedef dosyayı bozmaz)
  ///  - boyut doğrulanır
  ///  - dosya atomik olarak hedefe taşınır
  ///  - açılışta bir probe sorgusuyla içerik gerçekten okunabiliyor mu test edilir
  ///  - herhangi bir aşama başarısız olursa dosya silinip bir sonraki açılışta
  ///    baştan kurulur
  Future<Database> _openVerified() async {
    final dbPath = await getDatabasesPath();
    final target = join(dbPath, _dbName);

    _cleanupOldDbs(dbPath);

    // 1) Mevcut dosya gerçekten kullanılabilir mi?
    if (await _probeUsable(target)) {
      try {
        return await openDatabase(target, readOnly: true);
      } catch (e) {
        debugPrint('[Emsile] DB acilamadi, yeniden kurulacak: $e');
      }
    }

    // 2) Bozuk/eksik/yarim dosyayi temizle
    await _deleteQuietly(target);

    // 3) Atomik kurulum
    await _install(dbPath, target);

    // 4) Kurulumdan sonra dogrula, sonra ac
    if (!await _probeUsable(target)) {
      await _deleteQuietly(target);
      throw StateError(
        'Emsile veritabani kurulamadi. Dosya dogrulanamadi, sonraki acilista yeniden denenecek.',
      );
    }

    final db = await openDatabase(target, readOnly: true);
    // Icgerik kontrolu: tablo gercekten okunabiliyor mu
    await db.rawQuery('SELECT COUNT(*) AS c FROM emsile');
    return db;
  }

  /// Dosya var mi, boyutu tutuyor mu VE icerik okunabiliyor mu?
  Future<bool> _probeUsable(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;

    int size;
    try {
      size = await file.length();
    } catch (_) {
      return false;
    }
    if (size < _minPlausibleSize) {
      debugPrint('[Emsile] Dosya cok kucuk, yarim kalmis olabilir: $size byte');
      return false;
    }

    // Onceki basarili kurulumdan kaydedilen boyutla karsilastir.
    // Boyut degistiyse dosya bozulmus demektir.
    final prefs = await SharedPreferences.getInstance();
    final expected = prefs.getInt(_sizePrefsKey);
    if (expected != null && expected != size) {
      debugPrint('[Emsile] Boyut uyusmadi (beklenen $expected, bulunan $size) - bozuk dosya');
      return false;
    }

    // icerik probe
    try {
      final db = await openDatabase(path, readOnly: true);
      final res = await db.rawQuery('SELECT COUNT(*) AS c FROM emsile');
      await db.close();
      final count = (res.first['c'] as int?) ?? 0;
      if (count <= 0) {
        debugPrint('[Emsile] Tablo bos, dosya bozuk');
        return false;
      }
    } catch (e) {
      debugPrint('[Emsile] Icerik probe basarisiz: $e');
      return false;
    }

    return true;
  }

  /// DB'yi gecici dosyaya yaz, dogrula, sonra atomik olarak hedefe tasi.
  Future<void> _install(String dbPath, String target) async {
    final temp = join(dbPath, _tempName);
    await _deleteQuietly(temp);

    ByteData data;
    try {
      data = await rootBundle.load(_dbAsset);
    } catch (e, st) {
      // Hata mesajini GERCEKTEN yaz (onceki kodda '\$e' kaçisi vardi,
      // bu yuzden hicbir sey gorunmuyordu).
      debugPrint('[Emsile] Asset okunamadi ($_dbAsset): $e');
      debugPrintStack(stackTrace: st, label: '[Emsile] asset stack');
      rethrow;
    }

    // asUint8List bir GORUNUM (kopyalamaz), ayri bir 30MB tampon olusmaz.
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    try {
      final raf = await File(temp).open(mode: FileMode.write);
      var written = 0;
      try {
        while (written < bytes.length) {
          final end = min(written + _writeChunkSize, bytes.length);
          // writeFrom(buffer, start, end) -> end MUTLAK indeks, fark degil.
          await raf.writeFrom(bytes, written, end);
          written = end;
        }
        await raf.flush();
      } finally {
        await raf.close();
      }

      // Boyut dogrula: yarim kalmis gecici dosyayi hedefe tasima.
      final writtenLength = await File(temp).length();
      if (writtenLength != bytes.length) {
        throw StateError(
          'Yazma dogrulamasi basarisiz: beklenen ${bytes.length}, yazilan $writtenLength',
        );
      }

      // Atomik degistir
      await File(temp).rename(target);

      // Basarili boyutu kaydet (gelecek acilis icin referans)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sizePrefsKey, writtenLength);
      debugPrint('[Emsile] DB kuruldu ve dogrulandi: $writtenLength byte');
    } catch (e, st) {
      debugPrint('[Emsile] DB kurulumu basarisiz: $e');
      debugPrintStack(stackTrace: st, label: '[Emsile] install stack');
      await _deleteQuietly(temp);
      rethrow;
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Eski veritabanı dosyalarını temizle
  void _cleanupOldDbs(String dbPath) {
    try {
      final dir = Directory(dbPath);
      if (dir.existsSync()) {
        for (var f in dir.listSync()) {
          if (f is File) {
            final name = f.path.split(Platform.pathSeparator).last;
            if (name.startsWith('emsile') && name != 'emsile.db') {
              f.deleteSync();
            }
          }
        }
      }
    } catch (_) {}
  }

  bool _containsArabic(String s) => RegExp(r'[\u0600-\u06FF]').hasMatch(s);

  /// Arama sütununun SQL'de normalleştirilmiş hali: hemzeli elifler ve
  /// benzeri yazım farkları sorguyla aynı biçime iner (Ana Sözlük'teki
  /// normalizeArabic ile aynı kurallar). Böylece "امن" yazınca "آمن" ve
  /// "أمن" fiilleri de bulunur.
  static const String _normalizedSearchColumn =
      "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
      "search_text_arabic, 'أ', 'ا'), 'إ', 'ا'), 'آ', 'ا'), 'ٱ', 'ا'), "
      "'ء', 'ا'), 'ؤ', 'و'), 'ئ', 'ي'), 'ى', 'ي'), 'ة', 'ه')";

  /// Türkçe arama sütununun küçük harfli, Türkçe karaktersiz hali
  /// (foldLatin ile aynı: ç→c, ğ→g, ı/İ→i, ö→o, ş→s, ü→u).
  static const String _foldedTurkishColumn =
      "LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("
      "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(search_text"
      ", 'Ç', 'c')"
      ", 'Ğ', 'g')"
      ", 'İ', 'i')"
      ", 'I', 'i')"
      ", 'Ö', 'o')"
      ", 'Ş', 's')"
      ", 'Ü', 'u')"
      ", 'ç', 'c')"
      ", 'ğ', 'g')"
      ", 'ı', 'i')"
      ", 'ö', 'o')"
      ", 'ş', 's')"
      ", 'ü', 'u')"
      ", 'â', 'a')"
      ", 'î', 'i')"
      ", 'û', 'u'))";

  /// Veritabanını önceden başlat (soğuk başlangıç gecikmesini önlemek için)
  Future<void> preInit() async {
    await instance.database;
  }

  /// Toplam fiil sayısını döndür
  Future<int> getTotalCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM emsile');
    return result.first['cnt'] as int;
  }

  /// Sayfalı emsile sonucu getir (offset + limit) - Sözlüğe göre değil, pseudo-random (herkese aynı rastgele)
  Future<List<Map<String, dynamic>>> getEmsilePagedAsc({
    int offset = 0, 
    int limit = 200,
    bool isPremium = false,
    int? seed,
  }) async {
    final db = await instance.database;
    final String orderClause = isPremium 
        ? (seed != null ? '(id * $seed) % 999983 ASC' : '(id * 2654435761) % 999983 ASC')
        : 'CASE WHEN (id * 2654435761) % 7000 < 200 THEN 0 ELSE 1 END ASC, (id * 2654435761) % 999983 ASC';

    final results = await db.rawQuery('''
      SELECT * FROM emsile 
      ORDER BY $orderClause
      LIMIT ? OFFSET ?
    ''', [limit, offset]);
    return _parseResults(results);
  }

  /// Rastgele emsile sonucu getir
  Future<List<Map<String, dynamic>>> getEmsileRandom({int limit = 200}) async {
    final db = await instance.database;
    final results = await db.rawQuery('''
      SELECT * FROM emsile ORDER BY RANDOM() LIMIT ?
    ''', [limit]);
    return _parseResults(results);
  }

  /// Sabit 100 emsile sonucu getir (arama yokken gösterilecek) - eski uyumluluk
  Future<List<Map<String, dynamic>>> getDefaultEmsile({int limit = 100}) async {
    final db = await instance.database;
    final results = await db.rawQuery('''
      SELECT * FROM emsile ORDER BY id ASC LIMIT ?
    ''', [limit]);
    return _parseResults(results);
  }

  /// Aramaya göre ilk N sonucu döndür (Arapça + Türkçe)
  Future<List<Map<String, dynamic>>> searchEmsile(String query, {int limit = 1000}) async {
    final db = await instance.database;
    query = query.trim();
    if (query.isEmpty) return [];

    List<Map<String, dynamic>> results;

    if (_containsArabic(query)) {
      final normalizedQuery = normalizeArabic(query);
      final likePattern = '%$normalizedQuery%';
      final startsPattern = '$normalizedQuery%';

      // Tek tarama: normalleştirilmiş arama metni her satır için bir kez
      // hesaplanır. Sıra: tam eşleşme, başında geçen, içinde geçen.
      results = await db.rawQuery('''
        SELECT *, CASE
            WHEN mazi = ?1 OR n = ?2 OR n LIKE ?3 OR mazi LIKE ?4 OR muzari = ?1
              THEN 0
            WHEN n LIKE ?5 OR mazi LIKE ?5 OR muzari LIKE ?5 THEN 1
            ELSE 2
          END AS rank
        FROM (SELECT *, $_normalizedSearchColumn AS n FROM emsile)
        WHERE n LIKE ?6 OR mazi = ?1 OR muzari = ?1 OR mazi LIKE ?4
        ORDER BY rank ASC, LENGTH(mazi) ASC
        LIMIT ?7
      ''', [
        query,
        normalizedQuery,
        '$normalizedQuery %',
        '$query %',
        startsPattern,
        likePattern,
        limit,
      ]);
    } else {
      // Türkçe karakterden bağımsız: "inandi" yazınca "inandı" da bulunur.
      final folded = foldLatin(query);
      if (folded.isEmpty) return [];
      results = await db.rawQuery('''
        SELECT *, CASE
            WHEN t = ?1 THEN 0
            WHEN t LIKE ?2 OR t LIKE ?3 THEN 1
            ELSE 2
          END AS rank
        FROM (SELECT *, $_foldedTurkishColumn AS t FROM emsile)
        WHERE t LIKE ?4
        ORDER BY rank ASC, LENGTH(anlamlar) ASC
        LIMIT ?5
      ''', [folded, '$folded%', '% $folded%', '%$folded%', limit]);
    }

    return _parseResults(results);
  }

  /// Kimliğine göre tek fiil kaydı (kayıtlı listeler için).
  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await instance.database;
    final results = await db.rawQuery(
      'SELECT * FROM emsile WHERE id = ? LIMIT 1',
      [id],
    );
    if (results.isEmpty) return null;
    final parsed = _parseResults(results);
    return parsed.isNotEmpty ? parsed.first : null;
  }

  /// Mazi formuna göre emsile kaydı ara (sözlük entegrasyonu için)
  Future<Map<String, dynamic>?> searchByMazi(String maziForm) async {
    final db = await instance.database;
    final normalized = normalizeArabic(maziForm.trim());
    if (normalized.isEmpty) return null;

    final results = await db.rawQuery('''
      SELECT * FROM emsile 
      WHERE mazi = ? 
      OR $_normalizedSearchColumn = ? 
      OR $_normalizedSearchColumn LIKE ? 
      OR $_normalizedSearchColumn LIKE ?
      LIMIT 1
    ''', [maziForm.trim(), normalized, '$normalized %', '% $normalized %']);

    if (results.isEmpty) return null;
    final parsed = _parseResults(results);
    return parsed.isNotEmpty ? parsed.first : null;
  }

  List<Map<String, dynamic>> _parseResults(List<Map<String, Object?>> results) {
    final existingIds = <int>{};
    final deduplicated = <Map<String, dynamic>>[];
    for(var row in results) {
      int id = row['id'] as int;
      if (!existingIds.contains(id)) {
        existingIds.add(id);
        deduplicated.add(row);
      }
    }

    final parsedDeduped = <Map<String, dynamic>>[];
    for(var row in deduplicated) {
      parsedDeduped.add({
        'id': row['id'],
        'custom_id': row['custom_id'],
        'anlamlar': json.decode(row['anlamlar'] as String),
        'emsile_24': json.decode(row['emsile_24'] as String),
        'cekimler': {
           'mazi': json.decode(row['cekim_mazi'] as String),
           'muzari': json.decode(row['cekim_muzari'] as String),
           'emir': json.decode(row['cekim_emir'] as String),
        }
      });
    }

    return parsedDeduped;
  }
}
