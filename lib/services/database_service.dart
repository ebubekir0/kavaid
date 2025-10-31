// kavaid/lib/services/database_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  /// Arapça harekelerini kaldır (normalizasyon)
  String _removeArabicDiacritics(String text) {
    // Arapça harekeler: َ ِ ُ ً ٌ ٍ ّ ْ ٓ ٰ ٔ ٕ
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0653-\u0655]'), '');
  }

  /// Metinde Arapça hareke var mı kontrol et
  bool _hasArabicDiacritics(String text) {
    return RegExp(r'[\u064B-\u065F\u0670\u0653-\u0655]').hasMatch(text);
  }

  /// Türkçe anlamda arama teriminin pozisyonunu bul
  /// İlk anlamda olanlar için 0, ikinci anlamda olanlar için daha büyük sayı döner
  int _getMeaningPosition(String anlam, String query) {
    if (anlam.isEmpty || query.isEmpty) return 999;
    
    // Anlamları virgül ve noktalı virgülle ayır
    final meanings = anlam.split(RegExp(r'[,;]')).map((m) => m.trim()).toList();
    
    // Her anlamda arama terimini ara
    for (int i = 0; i < meanings.length; i++) {
      final meaning = meanings[i].toLowerCase().trim();
      final queryLower = query.toLowerCase().trim();
      
      // 1. TAM EŞLEŞİR - anlam tamamı aranan kelimeyle aynı ("katıldı" == "katıldı")
      if (meaning == queryLower) {
        return i; // 1. anlam: 0, 2. anlam: 1, 3. anlam: 2
      }
    }
    
    // 2. BAŞLANGIÇ EŞLEŞİR - hangi anlamda olursa olsun aynı puan
    for (int i = 0; i < meanings.length; i++) {
      final meaning = meanings[i].toLowerCase().trim();
      final queryLower = query.toLowerCase().trim();
      
      // Başlangıçta mı geçiyor (ama tam eşleşme değil)
      if (meaning.startsWith(queryLower) && meaning != queryLower) {
        return 100; // Hep aynı puan: başlangıç önemli, anlam sırası değil
      }
    }
    
    // 3. KELİME İÇİ EŞLEŞİR - anlam sırasına göre
    for (int i = 0; i < meanings.length; i++) {
      final meaning = meanings[i].toLowerCase().trim();
      final queryLower = query.toLowerCase().trim();
      
      // Kelime arasında geçiyor mu
      if (meaning.contains(' $queryLower') || meaning.contains('-$queryLower') || 
          meaning.contains('$queryLower ') || meaning.contains(queryLower)) {
        return 200 + i; // Kelime içi: 200, 201, 202...
      }
    }
    
    // Hiçbir anlamda yoksa en sona at
    return 999;
  }

  /// Kısmi hareke eşleşmesi - query'deki harekeler nerede olursa olsun target'ta da aynı pozisyonda olmalı
  /// Örnek: query="كِتا" target="كِتَابٌ" → true (harekeler uyuşuyor)
  ///        query="كِتا" target="كَتَابٌ" → false (harekeler farklı)
  ///        query="كتابٌ" target="كِتَابٌ" → true (son hareke uyuşuyor)
  ///        query="كتَاب" target="كِتَابٌ" → true (ortadaki hareke uyuşuyor)
  bool _matchesPartialDiacritics(String query, String target) {
    if (query.isEmpty || target.isEmpty) return false;
    
    // 1. Önce harekesiz versiyonların başlangıç eşleşmesini kontrol et
    final normalizedQuery = _removeArabicDiacritics(query);
    final normalizedTarget = _removeArabicDiacritics(target);
    
    if (!normalizedTarget.startsWith(normalizedQuery)) {
      return false; // Harekesiz hali bile eşleşmiyorsa devam etme
    }
    
    // 2. Query'deki harekeler target'ta da aynı pozisyonda olmalı
    // Her iki string'i de karakter listesine çevir
    final queryRunes = query.runes.toList();
    final targetRunes = target.runes.toList();
    
    int queryIndex = 0;
    int targetIndex = 0;
    
    while (queryIndex < queryRunes.length && targetIndex < targetRunes.length) {
      final queryChar = String.fromCharCode(queryRunes[queryIndex]);
      final targetChar = String.fromCharCode(targetRunes[targetIndex]);
      
      final isQueryDiacritic = _hasArabicDiacritics(queryChar);
      final isTargetDiacritic = _hasArabicDiacritics(targetChar);
      
      // Eğer query'de hareke varsa
      if (isQueryDiacritic) {
        // Target'ta da aynı hareke olmalı
        if (queryChar != targetChar) {
          return false;
        }
        queryIndex++;
        targetIndex++;
      } 
      // Query'de hareke yoksa (normal harf)
      else {
        // Target'taki karakteri kontrol et
        if (isTargetDiacritic) {
          // Target'ta hareke var ama query'de yok - target harekeyi atla
          targetIndex++;
        } else {
          // Her ikisi de normal harf - eşleşmeli
          if (queryChar != targetChar) {
            return false;
          }
          queryIndex++;
          targetIndex++;
        }
      }
    }
    
    // Query'nin tüm karakterleri eşleşti mi?
    return queryIndex == queryRunes.length;
  }

  Future<Database?> get database async {
    // Web platformunda null döndür
    if (kIsWeb) {
      return null;
    }
    
    if (_database != null) return _database!;
    _database = await _initDB('kavaid.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError('Database is not supported on web platform');
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB, onOpen: (db) async {
      // Her açılışta tabloların var olduğundan emin ol
      await _createDB(db, 1);
    });
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY NOT NULL';
    const textType = 'TEXT';
    const intType = 'INTEGER';

    await db.execute('''
CREATE TABLE IF NOT EXISTS words ( 
  kelime ${idType}, harekeliKelime ${textType}, anlam ${textType}, koku ${textType}, dilbilgiselOzellikler ${textType}, ornekCumleler ${textType}, fiilCekimler ${textType}, eklenmeTarihi ${intType}
)''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS pending_ai_words ( 
  kelime ${idType}, harekeliKelime ${textType}, anlam ${textType}, koku ${textType}, dilbilgiselOzellikler ${textType}, ornekCumleler ${textType}, fiilCekimler ${textType}, eklenmeTarihi ${intType}
)''');
    
    // ANR önleme için performans indeksleri
    await db.execute('CREATE INDEX IF NOT EXISTS idx_words_kelime ON words(kelime COLLATE NOCASE)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_words_harekeli ON words(harekeliKelime COLLATE NOCASE)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pending_kelime ON pending_ai_words(kelime COLLATE NOCASE)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pending_harekeli ON pending_ai_words(harekeliKelime COLLATE NOCASE)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pending_anlam ON pending_ai_words(anlam COLLATE NOCASE)');
  }

  Map<String, dynamic> _wordToDbMap(WordModel word) {
    // Örnek cümleler için özel işleme
    dynamic ornekCumlelerData;
    if (word.ornekCumleler != null) {
      // Eğer Map listesi ise direkt encode et
      if (word.ornekCumleler!.isNotEmpty && word.ornekCumleler![0] is Map) {
        ornekCumlelerData = json.encode(word.ornekCumleler);
      } 
      // Eğer başka bir format ise (örn: Ornek objesi) Map'e çevir
      else {
        ornekCumlelerData = json.encode(word.ornekCumleler!.map((e) {
          if (e is Map) {
            return {
              'arapcaCumle': e['arapcaCumle'] ?? '',
              'turkceCeviri': e['turkceCeviri'] ?? '',
            };
          }
          // Ornek objesi ise Map'e çevir (dynamic türü için)
          try {
            return {
              'arapcaCumle': (e as dynamic)?.arapcaCumle ?? '',
              'turkceCeviri': (e as dynamic)?.turkceCeviri ?? '',
            };
          } catch (_) {
            return {
              'arapcaCumle': '',
              'turkceCeviri': '',
            };
          }
        }).toList());
      }
    }
    
    return {
      'kelime': word.kelime, 
      'harekeliKelime': word.harekeliKelime, 
      'anlam': word.anlam, 
      'koku': word.koku,
      'dilbilgiselOzellikler': json.encode(word.dilbilgiselOzellikler),
      'ornekCumleler': ornekCumlelerData,
      'fiilCekimler': json.encode(word.fiilCekimler), 
      'eklenmeTarihi': word.eklenmeTarihi,
    };
  }
  
  WordModel _dbMapToWord(Map<String, dynamic> map) {
    // ornekCumleler için güvenli dönüştürme
    final decodedOrnekler = json.decode(map['ornekCumleler'] ?? '[]');
    final ornekCumlelerList = (decodedOrnekler is List)
        ? decodedOrnekler.map((e) {
            // Map<String, dynamic> olarak parse et - String değil!
            final ornekMap = Map<String, dynamic>.from(e as Map);
            
            // Debug: Örnek cümle içeriğini kontrol et
            debugPrint('🔍 DB\'den okunan örnek cümle:');
            debugPrint('  arapcaCumle: ${ornekMap['arapcaCumle']}');
            debugPrint('  turkceCeviri: ${ornekMap['turkceCeviri']}');
            
            return ornekMap;
          }).toList()
        : <Map<String, dynamic>>[];

    // dilbilgiselOzellikler için güvenli dönüştürme
    final decodedOzellikler = json.decode(map['dilbilgiselOzellikler'] ?? '{}');
    final ozelliklerMap = (decodedOzellikler is Map)
        ? Map<String, dynamic>.from(decodedOzellikler)
        : <String, dynamic>{};

    // fiilCekimler için güvenli dönüştürme
    final decodedCekimler = json.decode(map['fiilCekimler'] ?? '{}');
    final cekimlerMap = (decodedCekimler is Map)
        ? Map<String, dynamic>.from(decodedCekimler)
        : <String, dynamic>{};

    return WordModel(
      kelime: map['kelime'], 
      harekeliKelime: map['harekeliKelime'], 
      anlam: map['anlam'], 
      koku: map['koku'],
      dilbilgiselOzellikler: ozelliklerMap,
      ornekCumleler: ornekCumlelerList,
      fiilCekimler: cekimlerMap, 
      eklenmeTarihi: map['eklenmeTarihi'], 
      bulunduMu: true,
    );
  }

  Future<void> addPendingAiWord(WordModel word) async {
    if (kIsWeb) return;
    final db = await instance.database;
    if (db == null) return;
    await db.insert('pending_ai_words', _wordToDbMap(word), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> getPendingAiWordsCount() async {
    if (kIsWeb) return 0;
    final db = await instance.database;
    if (db == null) return 0;
    final result = await db.rawQuery('SELECT COUNT(*) FROM pending_ai_words');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<WordModel>> searchWords(String query) async {
    if (kIsWeb) return [];
    final db = await instance.database;
    if (db == null) return [];
    if (query.isEmpty) return [];

    // Kullanıcı harekeli mi yazdı kontrol et
    final queryHasDiacritics = _hasArabicDiacritics(query);
    final normalizedQuery = _removeArabicDiacritics(query);
    
    // Arama için terimleri hazırla
    final lowerTurkishQuery = query.toLowerCase();

    // Arapça karakter kontrolü - sadece Arapça arama için geniş sorgu
    final hasArabicChars = RegExp(r'[\u0600-\u06FF]').hasMatch(query);
    
    final List<Map<String, dynamic>> allMaps;
    
    if (hasArabicChars) {
      // 🔍 ARAPÇA ARAMA: TÜM Arapça kelimeleri çek, Dart tarafında hareke-aware filtreleme yap
      debugPrint('🔍 Arapça arama - Query: "$query" (harekeli: $queryHasDiacritics)');
      debugPrint('   Normalized: "$normalizedQuery"');
      
      // TÜM Arapça kelimeleri çek - filtre yok
      allMaps = await db.rawQuery('''
        SELECT * FROM (
            SELECT * FROM words 
            WHERE kelime GLOB '*[؀-ۿ]*' OR harekeliKelime GLOB '*[؀-ۿ]*'
            UNION ALL
            SELECT * FROM pending_ai_words 
            WHERE kelime GLOB '*[؀-ۿ]*' OR harekeliKelime GLOB '*[؀-ۿ]*'
        )
      ''');
      
      debugPrint('   SQL\'den gelen tüm Arapça kelimeler: ${allMaps.length}');
      debugPrint('   Dart tarafında "$normalizedQuery" ile filtrelenecek...');
    } else {
      // 🔍 TÜRKÇE ARAMA: Normal LIKE sorgusu + LIMIT (performans için)
      debugPrint('🔍 Türkçe arama: "$lowerTurkishQuery"');
      allMaps = await db.rawQuery('''
        SELECT * FROM (
            SELECT * FROM words 
            WHERE anlam LIKE ?
            UNION ALL
            SELECT * FROM pending_ai_words 
            WHERE anlam LIKE ?
        )
        LIMIT 100
      ''', [
        '%$lowerTurkishQuery%',
        '%$lowerTurkishQuery%'
      ]);
      debugPrint('   SQL\'den gelen sonuç: ${allMaps.length} kelime');
    }

    // Dart tarafında gelişmiş hareke-aware filtreleme (sadece gerekli olanlar için)
    final filteredWords = <WordModel>[];
    for (final map in allMaps) {
      final kelime = map['kelime'] as String? ?? '';
      final harekeliKelime = map['harekeliKelime'] as String? ?? '';
      final anlam = (map['anlam'] as String? ?? '').toLowerCase();
      
      // LATİN HARF KONTROLÜ - Latin harf içeren kelimeleri çıkar
      if (kelime.isNotEmpty && !_hasOnlyArabicCharacters(kelime)) {
        continue; // Bu kelimeyi atla
      }
      if (harekeliKelime.isNotEmpty && !_hasOnlyArabicCharacters(harekeliKelime)) {
        continue; // Bu kelimeyi atla
      }
      
      // ARAPÇA ARAMA KONTROLÜ
      if (hasArabicChars) {
        if (queryHasDiacritics) {
          // Kullanıcı harekeli yazdı → KİSMİ hareke eşleşmesi
          // Örnek: 'كِتا' yazarsa 'كِتَابٌ' eşleşir ama 'كَتَابٌ' eşleşmez
          if (_matchesPartialDiacritics(query, kelime) || 
              _matchesPartialDiacritics(query, harekeliKelime)) {
            filteredWords.add(_dbMapToWord(map));
            continue;
          }
        } else {
          // ✅ Kullanıcı harekesiz yazdı → harekesiz karşılaştır (tüm versiyonlar çıksın)
          final normalizedKelime = _removeArabicDiacritics(kelime);
          final normalizedHarekeli = _removeArabicDiacritics(harekeliKelime);
          
          // Harekesiz formlarda eşleşme var mı kontrol et
          if (normalizedKelime.contains(normalizedQuery) || 
              normalizedHarekeli.contains(normalizedQuery)) {
            filteredWords.add(_dbMapToWord(map));
            debugPrint('   ✅ Eşleşti: "$kelime" / "$harekeliKelime"');
            continue;
          }
        }
      }
      
      // TÜRKÇE ANLAM KONTROLÜ
      if (anlam.startsWith(lowerTurkishQuery) ||
          anlam.contains(',$lowerTurkishQuery') ||
          anlam.contains(', $lowerTurkishQuery') ||
          anlam.contains(lowerTurkishQuery)) {  // Eklenen: herhangi bir yerde geçiyor mu
        filteredWords.add(_dbMapToWord(map));
        continue;
      }
    }

    // Filtreleme sonucu
    if (hasArabicChars) {
      debugPrint('   📊 Filtreleme sonrası: ${filteredWords.length} kelime');
    }
    
    // SIRALAMA - Arama kalitesine göre önceliklendirme
    filteredWords.sort((a, b) {
      // 0. ÖNCE TÜRKÇE ANLAM SIRALAMASI YAP (tüm aramalar için)
      final aAnlam = (a.anlam ?? '').toLowerCase();
      final bAnlam = (b.anlam ?? '').toLowerCase();
      
      // Anlamda arama teriminin pozisyonunu bul
      int aMeaningIndex = _getMeaningPosition(aAnlam, lowerTurkishQuery);
      int bMeaningIndex = _getMeaningPosition(bAnlam, lowerTurkishQuery);
      
      // İlk anlamda olanlar önce gelsin
      if (aMeaningIndex != bMeaningIndex) {
        final result = aMeaningIndex.compareTo(bMeaningIndex);
        return result;
      }

      if (queryHasDiacritics) {
        // Harekeli arama - tam eşleşme öncelikli
        final aExactMatch = a.kelime == query || a.harekeliKelime == query;
        final bExactMatch = b.kelime == query || b.harekeliKelime == query;
        if (aExactMatch && !bExactMatch) return -1;
        if (bExactMatch && !aExactMatch) return 1;
        
        final aStartsWith = a.kelime.startsWith(query) || (a.harekeliKelime ?? '').startsWith(query);
        final bStartsWith = b.kelime.startsWith(query) || (b.harekeliKelime ?? '').startsWith(query);
        if (aStartsWith && !bStartsWith) return -1;
        if (bStartsWith && !aStartsWith) return 1;
      } else {
        // Harekesiz arama - normalize ederek sırala
        final aNormKelime = _removeArabicDiacritics(a.kelime);
        final aNormHarekeli = _removeArabicDiacritics(a.harekeliKelime ?? '');
        final bNormKelime = _removeArabicDiacritics(b.kelime);
        final bNormHarekeli = _removeArabicDiacritics(b.harekeliKelime ?? '');
        
        // 1. Tam eşleşme (en yüksek öncelik)
        final aExactMatch = aNormKelime == normalizedQuery || aNormHarekeli == normalizedQuery;
        final bExactMatch = bNormKelime == normalizedQuery || bNormHarekeli == normalizedQuery;
        if (aExactMatch && !bExactMatch) return -1;
        if (bExactMatch && !aExactMatch) return 1;
        
        // 2. Kelime sonu eşleşmesi (en yüksek öncelik - sadece tek kelimeler)
        final aEndsWith = aNormKelime.endsWith(normalizedQuery) || aNormHarekeli.endsWith(normalizedQuery);
        final bEndsWith = bNormKelime.endsWith(normalizedQuery) || bNormHarekeli.endsWith(normalizedQuery);
        final aHasSpace = aNormKelime.contains(' ') || aNormHarekeli.contains(' ');
        final bHasSpace = bNormKelime.contains(' ') || bNormHarekeli.contains(' ');
        
        // Sadece tek kelimelerde sonu eşleşmesi en öncelikli ("katı" -> "sıkı" en önce)
        final aEndsWithSingleWord = aEndsWith && !aHasSpace;
        final bEndsWithSingleWord = bEndsWith && !bHasSpace;
        
        if (aEndsWithSingleWord && !bEndsWithSingleWord) return -1;
        if (bEndsWithSingleWord && !aEndsWithSingleWord) return 1;
        
        // İkisi de sonu eşleşen tek kelime ise, Türkçe anlamdaki sıraya göre sırala
        if (aEndsWithSingleWord && bEndsWithSingleWord) {
          final aAnlam = (a.anlam ?? '').toLowerCase();
          final bAnlam = (b.anlam ?? '').toLowerCase();
          
          // Anlamda arama teriminin pozisyonunu bul
          int aMeaningIndex = _getMeaningPosition(aAnlam, lowerTurkishQuery);
          int bMeaningIndex = _getMeaningPosition(bAnlam, lowerTurkishQuery);
          
          // İlk anlamda olanlar önce gelsin
          if (aMeaningIndex != bMeaningIndex) {
            final result = aMeaningIndex.compareTo(bMeaningIndex);
            return result;
          }
        }
        
        // 3. Başlangıç eşleşmesi - önce TEK KELİME tamlamalar, sonra BAŞLANGIÇ eşleşenler
        final aStartsWith = aNormKelime.startsWith(normalizedQuery) || aNormHarekeli.startsWith(normalizedQuery);
        final bStartsWith = bNormKelime.startsWith(normalizedQuery) || bNormHarekeli.startsWith(normalizedQuery);
        
        // 3a. Tam geçip biten tamlamalar ("katı kalpli") önce
        final aStartsWithPhrase = aStartsWith && aHasSpace;
        final bStartsWithPhrase = bStartsWith && bHasSpace;
        if (aStartsWithPhrase && !bStartsWithPhrase) return -1;
        if (bStartsWithPhrase && !aStartsWithPhrase) return 1;
        
        // İkisi de tamlama ise anlam sırasına göre
        if (aStartsWithPhrase && bStartsWithPhrase) {
          final aAnlam = (a.anlam ?? '').toLowerCase();
          final bAnlam = (b.anlam ?? '').toLowerCase();
          
          int aMeaningIndex = _getMeaningPosition(aAnlam, lowerTurkishQuery);
          int bMeaningIndex = _getMeaningPosition(bAnlam, lowerTurkishQuery);
          
          if (aMeaningIndex != bMeaningIndex) {
            return aMeaningIndex.compareTo(bMeaningIndex);
          }
        }
        
        // 3b. Kelime arasında geçen tek kelimeler ("katıksız") en sonda
        final aStartsWithSingle = aStartsWith && !aHasSpace;
        final bStartsWithSingle = bStartsWith && !bHasSpace;
        if (aStartsWithSingle && !bStartsWithSingle) return -1;
        if (bStartsWithSingle && !aStartsWithSingle) return 1;
        
        // İkisi de tek kelime ise anlam sırasına göre
        if (aStartsWithSingle && bStartsWithSingle) {
          final aAnlam = (a.anlam ?? '').toLowerCase();
          final bAnlam = (b.anlam ?? '').toLowerCase();
          
          int aMeaningIndex = _getMeaningPosition(aAnlam, lowerTurkishQuery);
          int bMeaningIndex = _getMeaningPosition(bAnlam, lowerTurkishQuery);
          
          if (aMeaningIndex != bMeaningIndex) {
            return aMeaningIndex.compareTo(bMeaningIndex);
          }
        }
        
        // 4. Kelime uzunluğu (kısa kelimeler daha alakalı)
        final aMinLength = [aNormKelime.length, aNormHarekeli.length].where((l) => l > 0).fold(999, (a, b) => a < b ? a : b);
        final bMinLength = [bNormKelime.length, bNormHarekeli.length].where((l) => l > 0).fold(999, (a, b) => a < b ? a : b);
        if (aMinLength != bMinLength) return aMinLength.compareTo(bMinLength);
      }
      
      return 0;
    });

    return filteredWords;
  }

  Future<List<WordModel>> getPendingAiWords() async {
    if (kIsWeb) return [];
    final db = await instance.database;
    if (db == null) return [];
    final maps = await db.query('pending_ai_words');
    return maps.map((json) => _dbMapToWord(json)).toList();
  }

  Future<void> clearPendingAiWords() async {
    if (kIsWeb) return;
    final db = await instance.database;
    if (db == null) return;
    await db.delete('pending_ai_words');
  }

  Future<void> recreateWordsTable(List<WordModel> words) async {
    if (kIsWeb) return;
    
    final db = await instance.database;
    if (db == null) return;
    
    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.delete('words');
      for (final word in words) {
        batch.insert('words', _wordToDbMap(word), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> getWordsCount() async {
    if (kIsWeb) return 0;
    
    final db = await instance.database;
    if (db == null) return 0;
    
    final result = await db.rawQuery('SELECT COUNT(*) FROM words');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // YEREL ARAMA İÇİN TÜM KELİMELERİ GETİR
  Future<List<WordModel>> getAllWords() async {
    if (kIsWeb) return [];
    
    final db = await instance.database;
    if (db == null) return [];
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM words
      UNION ALL
      SELECT * FROM pending_ai_words
    ''');
    
    if (maps.isEmpty) {
      return [];
    }
    
    return maps.map((json) => _dbMapToWord(json)).toList();
  }

  Future<void> addWord(WordModel word) async {
    if (kIsWeb) return;
    final db = await instance.database;
    if (db == null) return;
    await db.insert('words', _wordToDbMap(word), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<WordModel?> getWordByExactMatch(String query) async {
    if (kIsWeb) return null;
    final db = await instance.database;
    if (db == null) return null;
    
    final trimmedQuery = query.trim();
    final queryHasDiacritics = _hasArabicDiacritics(trimmedQuery);
    
    // Tüm kelimeleri al ve Dart'ta kontrol et
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM words
      UNION
      SELECT * FROM pending_ai_words
    ''');

    for (final map in maps) {
      final kelime = map['kelime'] as String? ?? '';
      final harekeliKelime = map['harekeliKelime'] as String? ?? '';
      
      // LATİN HARF KONTROLÜ - Latin harf içeren kelimeleri atla
      if (kelime.isNotEmpty && !_hasOnlyArabicCharacters(kelime)) {
        continue;
      }
      if (harekeliKelime.isNotEmpty && !_hasOnlyArabicCharacters(harekeliKelime)) {
        continue;
      }
      
      if (queryHasDiacritics) {
        // Harekeli TAM eşleşme - tüm kelime aynı olmalı
        if (kelime == trimmedQuery || harekeliKelime == trimmedQuery) {
          return _dbMapToWord(map);
        }
      } else {
        // Harekesiz arama - normalize ederek karşılaştır
        final normalizedQuery = _removeArabicDiacritics(trimmedQuery);
        final normalizedKelime = _removeArabicDiacritics(kelime);
        final normalizedHarekeli = _removeArabicDiacritics(harekeliKelime);
        
        if (normalizedKelime.toLowerCase() == normalizedQuery.toLowerCase() ||
            normalizedHarekeli.toLowerCase() == normalizedQuery.toLowerCase()) {
          return _dbMapToWord(map);
        }
      }
    }
    
    return null;
  }

  Future<WordModel?> getWordByHarekeliKelime(String harekeliKelime) async {
    if (kIsWeb) return null;
    final db = await instance.database;
    if (db == null) return null;
    
    if (harekeliKelime.isEmpty) return null;
    
    
    // HEM words HEM pending_ai_words tablosunda ara (UNION ile)
    final maps = await db.rawQuery('''
      SELECT * FROM words WHERE harekeliKelime = ?
      UNION
      SELECT * FROM pending_ai_words WHERE harekeliKelime = ?
      LIMIT 1
    ''', [harekeliKelime, harekeliKelime]);
    
    if (maps.isNotEmpty) {
      return _dbMapToWord(maps.first);
    }
    
    return null;
  }

  // AI kelime arama öncesi tekrar kontrolü - harekeli Arapça ile
  Future<bool> isWordExistsByHarekeliArabic(String harekeliKelime) async {
    if (harekeliKelime.isEmpty) return false;
    if (kIsWeb) return false;
    
    final db = await instance.database;
    if (db == null) return false;
    
    // Hem ana tabloda hem de pending AI words tablosunda kontrol et
    final mainTableResult = await db.query(
      'words',
      where: 'harekeliKelime = ? COLLATE NOCASE',
      whereArgs: [harekeliKelime],
      limit: 1,
    );
    
    if (mainTableResult.isNotEmpty) {
      return true;
    }
    
    // Pending AI words tablosunda da kontrol et
    final pendingTableResult = await db.query(
      'pending_ai_words',
      where: 'harekeliKelime = ? COLLATE NOCASE',
      whereArgs: [harekeliKelime],
      limit: 1,
    );
    
    if (pendingTableResult.isNotEmpty) {
      return true;
    }
    
    return false;
  }

  /// Rastgele bir kelime getir
  Future<WordModel?> getRandomWord() async {
    try {
      if (kIsWeb) return null;
      final db = await instance.database;
      if (db == null) return null;
      
      // Toplam kelime sayısını al
      final countResult = await db.rawQuery('''
        SELECT COUNT(*) as total FROM (
          SELECT kelime FROM words
          UNION ALL
          SELECT kelime FROM pending_ai_words
        )
      ''');
      
      final totalWords = Sqflite.firstIntValue(countResult) ?? 0;
      if (totalWords == 0) {
        return null;
      }
      
      // Rastgele offset hesapla
      final randomOffset = (totalWords * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000).floor();
      
      // Rastgele kelime getir
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT * FROM (
          SELECT * FROM words
          UNION ALL
          SELECT * FROM pending_ai_words
        )
        ORDER BY kelime
        LIMIT 1 OFFSET ?
      ''', [randomOffset]);
      
      if (maps.isNotEmpty) {
        final word = _dbMapToWord(maps.first);
        return word;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Rastgele kelime getir (alternatif yöntem - daha performanslı)
  Future<WordModel?> getRandomWordFast() async {
    try {
      if (kIsWeb) return null;
      final db = await instance.database;
      if (db == null) return null;
      
      // SQLite'ın RANDOM() fonksiyonunu kullan
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT * FROM (
          SELECT * FROM words
          UNION ALL
          SELECT * FROM pending_ai_words
        )
        ORDER BY RANDOM()
        LIMIT 1
      ''');
      
      if (maps.isNotEmpty) {
        final word = _dbMapToWord(maps.first);
        return word;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Latin harf kontrolü - sadece Arapça harfler olmalı
  bool _hasOnlyArabicCharacters(String text) {
    if (text.isEmpty) return false;
    
    // Arapça karakter aralıkları:
    // U+0600-U+06FF: Arapça temel blok
    // U+0750-U+077F: Arapça ek blok
    // U+08A0-U+08FF: Arapça genişletilmiş blok
    // U+FB50-U+FDFF: Arapça sunum formları A
    // U+FE70-U+FEFF: Arapça sunum formları B
    
    final arabicPattern = RegExp(r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\s]+$');
    return arabicPattern.hasMatch(text);
  }

  /// Veritabanındaki duplicate harekeli kelimeleri bul
  Future<Map<String, List<Map<String, dynamic>>>> findDuplicateHarekeliWords() async {
    if (kIsWeb) return {};
    final db = await instance.database;
    if (db == null) return {};

    // Harekeli kelimeye göre grupla ve birden fazla olanları bul
    final result = await db.rawQuery('''
      SELECT harekeliKelime, COUNT(*) as count, GROUP_CONCAT(rowid) as rowids
      FROM words 
      WHERE harekeliKelime IS NOT NULL 
      AND harekeliKelime != ''
      GROUP BY harekeliKelime 
      HAVING count > 1
      ORDER BY count DESC
    ''');

    final duplicates = <String, List<Map<String, dynamic>>>{};
    
    for (final row in result) {
      final harekeliKelime = row['harekeliKelime'] as String;
      final rowIds = (row['rowids'] as String).split(',');
      
      // Bu harekeli kelimeye ait tüm satırları getir
      final words = await db.rawQuery('''
        SELECT * FROM words 
        WHERE harekeliKelime = ? 
        ORDER BY rowid
      ''', [harekeliKelime]);
      
      duplicates[harekeliKelime] = words;
    }
    
    return duplicates;
  }

  /// Latin harfleri olan Arapça kelimeleri bul
  Future<List<Map<String, dynamic>>> findWordsWithLatinInArabic() async {
    if (kIsWeb) return [];
    final db = await instance.database;
    if (db == null) return [];

    final allWords = await db.query('words');
    final problematicWords = <Map<String, dynamic>>[];

    for (final word in allWords) {
      final harekeliKelime = word['harekeliKelime'] as String? ?? '';
      final kelime = word['kelime'] as String? ?? '';
      
      // Harekeli kelime varsa ve Latin harf içeriyorsa
      if (harekeliKelime.isNotEmpty && !_hasOnlyArabicCharacters(harekeliKelime)) {
        problematicWords.add(word);
        continue;
      }
      
      // Normal kelime de Arapça olmalı ama Latin harf içeriyorsa
      if (kelime.isNotEmpty && kelime != harekeliKelime && !_hasOnlyArabicCharacters(kelime)) {
        problematicWords.add(word);
      }
    }
    
    return problematicWords;
  }

  /// Duplicate harekeli kelimeleri temizle (en eski olanı koru)
  Future<int> cleanDuplicateHarekeliWords() async {
    if (kIsWeb) return 0;
    final db = await instance.database;
    if (db == null) return 0;

    final duplicates = await findDuplicateHarekeliWords();
    int deletedCount = 0;

    for (final entry in duplicates.entries) {
      final harekeliKelime = entry.key;
      final words = entry.value;
      
      if (words.length <= 1) continue;
      
      // İlk kelimeyi koru (en eski), diğerlerini sil
      final wordsToDelete = words.skip(1).toList();
      
      for (final word in wordsToDelete) {
        final rowId = word['rowid'];
        await db.delete('words', where: 'rowid = ?', whereArgs: [rowId]);
        deletedCount++;
      }
      
      print('🗑️ Duplicate temizlendi: "$harekeliKelime" (${wordsToDelete.length} kopya silindi)');
    }
    
    return deletedCount;
  }

  /// Latin harfleri olan kelimeleri sil
  Future<int> cleanWordsWithLatinInArabic() async {
    if (kIsWeb) return 0;
    final db = await instance.database;
    if (db == null) return 0;

    final problematicWords = await findWordsWithLatinInArabic();
    int deletedCount = 0;

    for (final word in problematicWords) {
      final rowId = word['rowid'];
      final kelime = word['kelime'] as String? ?? '';
      final harekeliKelime = word['harekeliKelime'] as String? ?? '';
      
      await db.delete('words', where: 'rowid = ?', whereArgs: [rowId]);
      deletedCount++;
      
      print('🗑️ Latin harf içeren kelime silindi: "$kelime" / "$harekeliKelime"');
    }
    
    return deletedCount;
  }

  /// Tam veritabanı temizliği yap
  Future<Map<String, int>> performDatabaseCleanup() async {
    if (kIsWeb) return {};
    
    print('🧹 Veritabanı temizliği başlatılıyor...');
    
    final duplicatesDeleted = await cleanDuplicateHarekeliWords();
    final latinDeleted = await cleanWordsWithLatinInArabic();
    
    final totalWords = await getWordsCount();
    
    print('✅ Veritabanı temizliği tamamlandı!');
    print('   - Duplicate silinen: $duplicatesDeleted');
    print('   - Latin harf silinen: $latinDeleted');
    print('   - Kalan toplam: $totalWords');
    
    return {
      'duplicatesDeleted': duplicatesDeleted,
      'latinDeleted': latinDeleted,
      'totalRemaining': totalWords,
    };
  }

  Future close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    if (db == null) return;
    db.close();
  }
}