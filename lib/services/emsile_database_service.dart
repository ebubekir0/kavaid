import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class EmsileDatabaseService {
  static final EmsileDatabaseService instance = EmsileDatabaseService._init();
  static Database? _database;

  EmsileDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('emsile.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Only copy if the database does not exist to avoid redundant disk writes and UI blocks
    final exists = await databaseExists(path);
    if (!exists) {
      await _copyDbFromAssets(path);
    }

    // Eski veritabanı dosyalarını temizle (yer açmak için)
    _cleanupOldDbs(dbPath);

    return await openDatabase(path, readOnly: true);
  }

  Future<void> _copyDbFromAssets(String path) async {
    try {
      ByteData data = await rootBundle.load('assets/data/emsile.db');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    } catch (e) {
      print("Error copying Emsile database: \$e");
    }
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

  String _removeArabicDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0653-\u0655]'), '');
  }

  bool _containsArabic(String s) => RegExp(r'[\u0600-\u06FF]').hasMatch(s);

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
      final normalizedQuery = _removeArabicDiacritics(query);
      final likePattern = '%$normalizedQuery%';
      final startsPattern = '$normalizedQuery%';

      results = await db.rawQuery('''
        SELECT * FROM (
          SELECT *, 0 AS rank FROM emsile 
          WHERE mazi = ? 
          OR search_text_arabic = ? 
          OR search_text_arabic LIKE ? 
          OR mazi LIKE ? 
          OR muzari = ?
          UNION ALL
          SELECT *, 1 AS rank FROM emsile WHERE search_text_arabic LIKE ? OR mazi LIKE ? OR muzari LIKE ?
          UNION ALL
          SELECT *, 2 AS rank FROM emsile WHERE search_text_arabic LIKE ?
        )
        ORDER BY rank ASC, LENGTH(mazi) ASC
        LIMIT ?
      ''', [
        query, normalizedQuery, '$normalizedQuery %', '$query %', query,
        startsPattern, startsPattern, startsPattern,
        likePattern,
        limit
      ]);
    } else {
      final lowerQuery = query.toLowerCase();
      results = await db.rawQuery('''
        SELECT * FROM (
          SELECT *, 0 AS rank FROM emsile WHERE search_text = ?
          UNION ALL
          SELECT *, 1 AS rank FROM emsile WHERE search_text LIKE ? OR search_text LIKE ?
          UNION ALL
          SELECT *, 2 AS rank FROM emsile WHERE search_text LIKE ?
        )
        ORDER BY rank ASC, LENGTH(anlamlar) ASC
        LIMIT ?
      ''', [
        lowerQuery,
        '$lowerQuery%', '% $lowerQuery%',
        '%$lowerQuery%',
        limit
      ]);
    }

    return _parseResults(results);
  }

  /// Mazi formuna göre emsile kaydı ara (sözlük entegrasyonu için)
  Future<Map<String, dynamic>?> searchByMazi(String maziForm) async {
    final db = await instance.database;
    final normalized = _removeArabicDiacritics(maziForm.trim());
    if (normalized.isEmpty) return null;

    final results = await db.rawQuery('''
      SELECT * FROM emsile 
      WHERE mazi = ? 
      OR search_text_arabic = ? 
      OR search_text_arabic LIKE ? 
      OR search_text_arabic LIKE ?
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
