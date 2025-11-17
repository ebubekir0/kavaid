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

  /// Basit Latin->Arapça tahmini (en yaygın harfler, ünlüleri atla)
  /// Örn: "zehebe" -> "ذهب"
  String _latinToArabicGuess(String input) {
    if (input.isEmpty) return '';
    final s = input.toLowerCase();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      // İki harfli kombinasyonlar (önce bunları kontrol et)
      if (i + 1 < s.length) {
        final pair = s.substring(i, i + 2);
        if (pair == 'sh') { buffer.write('ش'); i++; continue; }
        if (pair == 'kh') { buffer.write('خ'); i++; continue; }
        if (pair == 'dh') { buffer.write('ذ'); i++; continue; }
        if (pair == 'th') { buffer.write('ث'); i++; continue; }
        if (pair == 'gh') { buffer.write('غ'); i++; continue; }
        if (pair == 'ch') { buffer.write('چ'); i++; continue; }
      }
      
      // Tek harf eşlemeleri (basit)
      switch (ch) {
        case 'a': case 'e': case 'i': case 'o': case 'u': case 'ı': case 'ö': case 'ü':
          // Kelimenin başındaki ilk ünlü için ع ekleyerek 'arab' -> 'عرب' gibi tahminleri yakala
          if (i == 0) buffer.write('ع');
          // Diğer ünlüleri atla (iskeleti koru)
          break;
        case 'b': buffer.write('ب'); break;
        case 't': buffer.write('ت'); break;
        case 'j': buffer.write('ج'); break;
        case 'h': buffer.write('ه'); break;
        case 'd': buffer.write('د'); break;
        case 'z': buffer.write('ذ'); break; // 'z' için ذ tercih (ذهب örneği)
        case 'r': buffer.write('ر'); break;
        case 's': buffer.write('س'); break;
        case 'f': buffer.write('ف'); break;
        case 'q': buffer.write('ق'); break;
        case 'k': buffer.write('ك'); break;
        case 'l': buffer.write('ل'); break;
        case 'm': buffer.write('م'); break;
        case 'n': buffer.write('ن'); break;
        case 'w': buffer.write('و'); break;
        case 'y': buffer.write('ي'); break;
        case 'g': buffer.write('ك'); break; // yaklaşık
        case 'c': buffer.write('س'); break; // yaklaşık
        case 'p': buffer.write('ب'); break; // yaklaşık
        case 'v': buffer.write('ف'); break; // yaklaşık
        case 'x': buffer.write('كس'); break; // yaklaşık
        default:
          // Diğer karakterleri atla
          break;
      }
    }
    return buffer.toString();
  }

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
            
            // Debug print'leri prodüksiyon için kaldırıldı
            
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
    final lowerTurkishQuery = query.toLowerCase();
    final hasArabicChars = RegExp(r'[\u0600-\u06FF]').hasMatch(query);
    // Latin sorgular için Arapça tahmini (ör. "arab" -> "عرب")
    final arabicGuess = hasArabicChars ? '' : _latinToArabicGuess(query);
    final isLatinGuessActive = !hasArabicChars && arabicGuess.isNotEmpty && query.trim().length <= 3;

    // Arapça karakter kontrolü - sadece Arapça arama için geniş sorgu
    // hasArabicChars üstte hesaplandı, burada tekrar tanımlama yok
    // Arapça için, harekeleri atlayarak eşleşebilecek LIKE pattern'i oluştur (örn: "ذ%ه%ب%")
    String _buildArabicWildcardPattern(String text) {
      if (text.isEmpty) return '';
      final runes = text.runes.toList();
      final buffer = StringBuffer();
      for (int i = 0; i < runes.length; i++) {
        buffer.write(String.fromCharCode(runes[i]));
        if (i != runes.length - 1) buffer.write('%');
      }
      return buffer.toString();
    }
    
    final List<Map<String, dynamic>> allMaps;
    
    if (hasArabicChars) {
      // 🔍 ARAPÇA ARAMA (daha hızlı):
      // Aşamalı ve indeks-dostu sıralama
      // 1) Eşitlik (tam eşleşme)
      // 2) Başlangıç eşleşmesi (query% ve diakritik toleranslı likePatternStarts)
      // 3) İçinde geçen (%query%)

      final likePatternStarts = '${_buildArabicWildcardPattern(query)}%';    // ذ%ه%ب%
      final containsWildcard = '%${_buildArabicWildcardPattern(query)}%';    // %ذ%ه%ب%
      final startsQuery = '$query%';                                        // ذهب%
      final startsNormalized = '${_removeArabicDiacritics(query)}%';        // normalize prefix (e.g., ذهب%)
      final containsQuery = '%$query%';                                     // %ذهب%

      allMaps = await db.rawQuery('''
        SELECT * FROM (
          -- 0: TAM EŞLEŞME
          SELECT *, 0 AS rank FROM words WHERE kelime = ? OR harekeliKelime = ?
          UNION ALL
          SELECT *, 0 AS rank FROM pending_ai_words WHERE kelime = ? OR harekeliKelime = ?

          -- 1: BAŞLANGIÇ EŞLEŞMESİ (indeks dostu + diakritik toleranslı)
          UNION ALL
          SELECT *, 1 AS rank FROM words 
          WHERE (kelime LIKE ? OR harekeliKelime LIKE ? OR kelime LIKE ? OR harekeliKelime LIKE ? OR kelime LIKE ? OR harekeliKelime LIKE ?)
          UNION ALL
          SELECT *, 1 AS rank FROM pending_ai_words 
          WHERE (kelime LIKE ? OR harekeliKelime LIKE ? OR kelime LIKE ? OR harekeliKelime LIKE ? OR kelime LIKE ? OR harekeliKelime LIKE ?)

          -- 2: İÇİNDE GEÇEN (küçük limitli kalacak) + KÖK-BENZERİ WILDCARD
          UNION ALL
          SELECT *, 2 AS rank FROM words WHERE (kelime LIKE ? OR harekeliKelime LIKE ? OR kelime LIKE ? OR harekeliKelime LIKE ?)
          UNION ALL
          SELECT *, 2 AS rank FROM pending_ai_words WHERE (kelime LIKE ? OR harekeliKelime LIKE ? OR kelime LIKE ? OR harekeliKelime LIKE ?)
        )
        ORDER BY rank ASC, LENGTH(kelime) ASC
        LIMIT 200
      ''', [
        // 0 - EXACT
        query, query,
        query, query,
        // 1 - PREFIX (query%, normalizedQuery%, likePatternStarts)
        startsQuery, startsQuery, startsNormalized, startsNormalized, likePatternStarts, likePatternStarts,
        startsQuery, startsQuery, startsNormalized, startsNormalized, likePatternStarts, likePatternStarts,
        // 2 - CONTAINS (%query%) + ROOT-LIKE (%q%u%e%)
        containsQuery, containsQuery, containsWildcard, containsWildcard,
        containsQuery, containsQuery, containsWildcard, containsWildcard,
      ]);
      
    } else {
      // 🔍 LATİN/TÜRKÇE ARAMA: anlam LIKE + (varsa) Arapça tahmine göre kelime prefix/contains
      final arabicGuess = _latinToArabicGuess(query);
      if (isLatinGuessActive) {
        final arabicPrefix = '$arabicGuess%';
        final arabicContains = '%$arabicGuess%';
        allMaps = await db.rawQuery('''
          SELECT * FROM (
              -- Anlam bazlı eşleşmeler (case-insensitive) - en yüksek öncelik, sadece BAŞLANGIÇ
              SELECT *, 0 AS rank FROM words WHERE (
                LOWER(anlam) LIKE ? OR LOWER(anlam) LIKE ? OR LOWER(anlam) LIKE ?
              )
              UNION ALL
              SELECT *, 0 AS rank FROM pending_ai_words WHERE (
                LOWER(anlam) LIKE ? OR LOWER(anlam) LIKE ? OR LOWER(anlam) LIKE ?
              )

              -- Arapça kelime tahmini ile prefix (anlamlardan sonra gelsin)
              UNION ALL
              SELECT *, 1 AS rank FROM words WHERE (kelime LIKE ? OR harekeliKelime LIKE ?)
              UNION ALL
              SELECT *, 1 AS rank FROM pending_ai_words WHERE (kelime LIKE ? OR harekeliKelime LIKE ?)

              -- Arapça kelime tahmini ile contains (düşük öncelik)
              UNION ALL
              SELECT *, 2 AS rank FROM words WHERE (kelime LIKE ? OR harekeliKelime LIKE ?)
              UNION ALL
              SELECT *, 2 AS rank FROM pending_ai_words WHERE (kelime LIKE ? OR harekeliKelime LIKE ?)
          )
          ORDER BY rank ASC, LENGTH(kelime) ASC
          LIMIT 120
        ''', [
          '${lowerTurkishQuery}%',
          '%,${lowerTurkishQuery}%',
          '%, ${lowerTurkishQuery}%',
          '${lowerTurkishQuery}%',
          '%,${lowerTurkishQuery}%',
          '%, ${lowerTurkishQuery}%',
          arabicPrefix, arabicPrefix,
          arabicPrefix, arabicPrefix,
          arabicContains, arabicContains,
          arabicContains, arabicContains,
        ]);
      } else {
        // Türkçe/LATİN sorgu: anlamın BAŞINDA ve İÇİNDE eşleşmeleri al
        allMaps = await db.rawQuery('''
          SELECT * FROM (
              SELECT * FROM words 
              WHERE (
                LOWER(anlam) LIKE ? OR LOWER(anlam) LIKE ? OR LOWER(anlam) LIKE ? OR LOWER(anlam) LIKE ?
              )
              UNION ALL
              SELECT * FROM pending_ai_words 
              WHERE (
                LOWER(anlam) LIKE ? OR LOWER(anlam) LIKE ? OR LOWER(anlam) LIKE ? OR LOWER(anlam) LIKE ?
              )
          )
          LIMIT 100
        ''', [
          '${lowerTurkishQuery}%','%,${lowerTurkishQuery}%','%, ${lowerTurkishQuery}%','%${lowerTurkishQuery}%',
          '${lowerTurkishQuery}%','%,${lowerTurkishQuery}%','%, ${lowerTurkishQuery}%','%${lowerTurkishQuery}%',
        ]);
      }
    }

    // Dart tarafında gelişmiş hareke-aware filtreleme (sadece gerekli olanlar için)
    final filteredWords = <WordModel>[];
    for (final map in allMaps) {
      final kelime = map['kelime'] as String? ?? '';
      final harekeliKelime = map['harekeliKelime'] as String? ?? '';
      // Harekeli kelime 2'den fazla kelime içeriyorsa (ör. uzun ifade/cümle) bu kaydı sözlük sonuçlarından çıkar
      final hkTrim = harekeliKelime.trim();
      if (hkTrim.isNotEmpty) {
        final wordCount = hkTrim.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length;
        if (wordCount > 2) {
          continue;
        }
      }

      final anlam = (map['anlam'] as String? ?? '').toLowerCase();
      final koku = (map['koku'] as String? ?? '').trim();
      
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
          // ✅ Kullanıcı harekesiz yazdı → sadece başlangıç + KÖK eşleşmesi
          final normalizedKelime = _removeArabicDiacritics(kelime);
          final normalizedHarekeli = _removeArabicDiacritics(harekeliKelime);
          final normalizedKoku = _removeArabicDiacritics(koku);

          // Başlangıç eşleşmesi (prefix)
          final bool prefixMatch = normalizedKelime.startsWith(normalizedQuery) ||
              normalizedHarekeli.startsWith(normalizedQuery);

          // Kök eşleşmesi: Önce 'koku' alanına göre, yoksa harf-sıralama fallback
          bool rootMatch = false;
          if (normalizedQuery.length >= 2) {
            if (normalizedKoku.isNotEmpty) {
              rootMatch = normalizedKoku == normalizedQuery;
            } else {
              rootMatch = _hasSequentialLetters(normalizedKelime, normalizedQuery) ||
                         _hasSequentialLetters(normalizedHarekeli, normalizedQuery);
            }
          }

          if (prefixMatch || rootMatch) {
            filteredWords.add(_dbMapToWord(map));
            continue;
          }
        }
      }
      
      // LATİN/TÜRKÇE SORGU: anlamın TÜM parçalarında arama yap
      // _getMeaningPosition, virgüllerle ayrılmış tüm anlamlarda tam, başlangıç
      // ve içinde geçme eşleşmelerini kontrol eder. 999 değilse bu kelimeyi kabul et.
      if (!hasArabicChars) {
        final meaningPos = _getMeaningPosition(anlam, lowerTurkishQuery);
        if (meaningPos == 999) {
          // Anlamda hiç eşleşme yoksa, latin tahminiyle gelenler dahil çıkar
          continue;
        }

        filteredWords.add(_dbMapToWord(map));
        continue;
      }

      if (isLatinGuessActive) {
        final normKel = _removeArabicDiacritics(kelime);
        final normHar = _removeArabicDiacritics(harekeliKelime);
        if (kelime.startsWith(arabicGuess) ||
            (harekeliKelime).startsWith(arabicGuess) ||
            normKel.startsWith(arabicGuess) ||
            normHar.startsWith(arabicGuess)) {
          filteredWords.add(_dbMapToWord(map));
          continue;
        }
      }

      // Buraya yalnızca ARAPÇA sorgularda düşeriz; Türkçe/LATİN sorgular yukarıda
      // anlam eşleşmesi ile zaten filteredWords'e eklenmiştir.
    }

    // Filtreleme sonucu
    if (hasArabicChars) {
      debugPrint('   📊 Filtreleme sonrası: ${filteredWords.length} kelime');
    }
    
    // YENİ SIRALAMA - Basit ve net öncelik sistemi
    if (hasArabicChars) {
      final nq = normalizedQuery.toLowerCase();
      final exactNormalized = <WordModel>[];
      final others = <WordModel>[];
      for (final w in filteredWords) {
        final n1 = _removeArabicDiacritics(w.kelime).toLowerCase();
        final n2 = _removeArabicDiacritics(w.harekeliKelime ?? '').toLowerCase();
        if (n1 == nq || n2 == nq) {
          exactNormalized.add(w);
        } else {
          others.add(w);
        }
      }
      // exactNormalized içinde baz formu öne al:
      // 1) Kullanıcının yazdığı string ile bire bir eşit olan kelimeler (kelime/harekeliKelime == query)
      // 2) Prefix cezası (س ، سوف ، و ، ل vb. ile başlayan çekimleri geriye at)
      // 3) Uzunluk (sorgu uzunluğuna en yakın / kısa formu öne al)
      exactNormalized.sort((a, b) {
        // 1) Doğrudan giriş eşleşmesi (normalize etmeden)
        final aDirect = a.kelime == query || (a.harekeliKelime ?? '') == query;
        final bDirect = b.kelime == query || (b.harekeliKelime ?? '') == query;
        if (aDirect != bDirect) return aDirect ? -1 : 1;

        // 2) Prefix cezası
        final aPref = _getArabicPrefixPenalty(a.harekeliKelime ?? '');
        final bPref = _getArabicPrefixPenalty(b.harekeliKelime ?? '');
        if (aPref != bPref) return aPref.compareTo(bPref);

        // 3) Uzunluk yakınlığı
        final normAKel = _removeArabicDiacritics(a.kelime);
        final normAHar = _removeArabicDiacritics(a.harekeliKelime ?? '');
        final normBKel = _removeArabicDiacritics(b.kelime);
        final normBHar = _removeArabicDiacritics(b.harekeliKelime ?? '');
        int lenA = [normAKel.length, normAHar.length]
            .where((l) => l > 0)
            .fold(999, (p, c) => p < c ? p : c);
        int lenB = [normBKel.length, normBHar.length]
            .where((l) => l > 0)
            .fold(999, (p, c) => p < c ? p : c);
        final qLen = normalizedQuery.toLowerCase().length;
        final aDist = (lenA - qLen).abs();
        final bDist = (lenB - qLen).abs();
        if (aDist != bDist) return aDist.compareTo(bDist);

        return lenA.compareTo(lenB);
      });
      others.sort((a, b) => _compareWordsByNewPriority(
            a,
            b,
            query,
            lowerTurkishQuery,
            normalizedQuery,
            queryHasDiacritics,
            hasArabicChars,
          ));
      filteredWords
        ..clear()
        ..addAll(exactNormalized)
        ..addAll(others);
    } else {
      filteredWords.sort((a, b) {
        return _compareWordsByNewPriority(
          a,
          b,
          query,
          lowerTurkishQuery,
          normalizedQuery,
          queryHasDiacritics,
          hasArabicChars,
        );
      });
    }

    // DEDUPE: Aynı harekeliKelime'ye sahip olanları tekille (ilk görüleni koru)
    final seenHarekeli = <String>{};
    final deduped = <WordModel>[];
    for (final w in filteredWords) {
      final hk = (w.harekeliKelime ?? '').trim();
      if (hk.isEmpty) {
        deduped.add(w);
        continue;
      }
      if (seenHarekeli.add(hk)) {
        deduped.add(w);
      }
    }
    return deduped;
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

      /// YENİ GELİŞTİRİLMİŞ ARAMA SIRALAMASI
      /// 1. TAM EŞLEŞME - Arama terimi ile tam uyuşan kelimeler
      /// 2. İÇİNDE GEÇEN - Arama teriminin kelime içinde geçtiği durumlar
      /// 3. KÖK EŞLEŞMESI - Kök olarak içinde geçenler
      int _compareWordsByNewPriority(
        WordModel a,
        WordModel b,
        String originalQuery,
        String lowerTurkishQuery,
        String normalizedQuery,
        bool queryHasDiacritics,
        bool isArabicQuery,
      ) {
        final aAnlam = (a.anlam ?? '').toLowerCase();
        final bAnlam = (b.anlam ?? '').toLowerCase();
        
        // Arapça arama için normalleştirilmiş kelimeler
        final aNormKelime = _removeArabicDiacritics(a.kelime);
        final aNormHarekeli = _removeArabicDiacritics(a.harekeliKelime ?? '');
        final bNormKelime = _removeArabicDiacritics(b.kelime);
        final bNormHarekeli = _removeArabicDiacritics(b.harekeliKelime ?? '');
        
        // ARAPÇA SORGUSU: Tam eşleşme > başlangıç > içinde geçme (anlam önceliğini atla)
        if (isArabicQuery) {
          if (queryHasDiacritics) {
            // 1) Harekeli tam eşleşme
            final aExact = a.kelime == originalQuery || a.harekeliKelime == originalQuery;
            final bExact = b.kelime == originalQuery || b.harekeliKelime == originalQuery;
            if (aExact != bExact) return aExact ? -1 : 1;

            // 2) Normalize tam eşleşme (base formu öne al)
            final nq = normalizedQuery.toLowerCase();
            final aNormExact = aNormKelime.toLowerCase() == nq || aNormHarekeli.toLowerCase() == nq;
            final bNormExact = bNormKelime.toLowerCase() == nq || bNormHarekeli.toLowerCase() == nq;
            if (aNormExact != bNormExact) return aNormExact ? -1 : 1;
            if (aNormExact && bNormExact) {
              // 2.1 Baz formu öne al: harekeliKelime'nin normalize hali sorguya tam eşitse tercih et
              final aHarekeliNormEq = aNormHarekeli.toLowerCase() == nq;
              final bHarekeliNormEq = bNormHarekeli.toLowerCase() == nq;
              if (aHarekeliNormEq != bHarekeliNormEq) return aHarekeliNormEq ? -1 : 1;

              // 2.2 Prefiks cezası: harekeliKelime başında parçacık varsa (س, سوف, و, ل) cezalandır
              final aPref = _getArabicPrefixPenalty(a.harekeliKelime ?? '');
              final bPref = _getArabicPrefixPenalty(b.harekeliKelime ?? '');
              if (aPref != bPref) return aPref.compareTo(bPref);

              // 2.3 Uzunluk yakınlığı - baz formu öne al
              final aLen = [aNormKelime.length, aNormHarekeli.length].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
              final bLen = [bNormKelime.length, bNormHarekeli.length].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
              final qLen = nq.length;
              final aDist = (aLen - qLen).abs();
              final bDist = (bLen - qLen).abs();
              if (aDist != bDist) return aDist.compareTo(bDist);
            }

            // 3) Harekeli başlangıç eşleşmesi
            final aStarts = a.kelime.startsWith(originalQuery) || (a.harekeliKelime ?? '').startsWith(originalQuery);
            final bStarts = b.kelime.startsWith(originalQuery) || (b.harekeliKelime ?? '').startsWith(originalQuery);
            if (aStarts != bStarts) return aStarts ? -1 : 1;

            // 4) Normalize başlangıç ve 5) Normalize içinde geçme
            final aNormStarts = aNormKelime.toLowerCase().startsWith(nq) || aNormHarekeli.toLowerCase().startsWith(nq);
            final bNormStarts = bNormKelime.toLowerCase().startsWith(nq) || bNormHarekeli.toLowerCase().startsWith(nq);
            if (aNormStarts != bNormStarts) return aNormStarts ? -1 : 1;
            final aNormCont = aNormKelime.toLowerCase().contains(nq) || aNormHarekeli.toLowerCase().contains(nq);
            final bNormCont = bNormKelime.toLowerCase().contains(nq) || bNormHarekeli.toLowerCase().contains(nq);
            if (aNormCont != bNormCont) return aNormCont ? -1 : 1;
          } else {
            // Harekesiz: normalize ederek tam eşleşme
            final nq = normalizedQuery.toLowerCase();
            final aExact = aNormKelime.toLowerCase() == nq || aNormHarekeli.toLowerCase() == nq;
            final bExact = bNormKelime.toLowerCase() == nq || bNormHarekeli.toLowerCase() == nq;
            if (aExact != bExact) return aExact ? -1 : 1;
            // Her ikisi de normalize tam eşleşmeyse: sorgu uzunluğuna en yakın olanı (tercihen eşit) önce gelsin
            if (aExact && bExact) {
              final aLen = [aNormKelime.length, aNormHarekeli.length].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
              final bLen = [bNormKelime.length, bNormHarekeli.length].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
              final qLen = nq.length;
              final aDist = (aLen - qLen).abs();
              final bDist = (bLen - qLen).abs();
              if (aDist != bDist) return aDist.compareTo(bDist); // tam eşleşmeye en yakın uzunluk (0 en iyi)
            }
            // Başlangıç (normalize)
            final aStarts = aNormKelime.toLowerCase().startsWith(nq) || aNormHarekeli.toLowerCase().startsWith(nq);
            final bStarts = bNormKelime.toLowerCase().startsWith(nq) || bNormHarekeli.toLowerCase().startsWith(nq);
            if (aStarts != bStarts) return aStarts ? -1 : 1;
            // İçinde geçiyor (normalize)
            final aCont = aNormKelime.toLowerCase().contains(nq) || aNormHarekeli.toLowerCase().contains(nq);
            final bCont = bNormKelime.toLowerCase().contains(nq) || bNormHarekeli.toLowerCase().contains(nq);
            if (aCont != bCont) return aCont ? -1 : 1;
          }
          // Eşitlikte kısa kelimeyi öne al
          final aMinLength = [aNormKelime.length, aNormHarekeli.length].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
          final bMinLength = [bNormKelime.length, bNormHarekeli.length].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
          if (aMinLength != bMinLength) return aMinLength.compareTo(bMinLength);
          // Son çare: anlam uzunluğu
          return aAnlam.length.compareTo(bAnlam.length);
        }

        // ============= 1. TÜRKÇE ANLAM KONTROLÜ ============= (Türkçe veya Latin sorgular için)
        
        // 1a. TAM ANLAM EŞLEŞMESI - "katıldı" aradığında "katıldı" anlamı olan kelimeler en önce
        final aExactMeaningMatch = _hasExactMeaningMatch(aAnlam, lowerTurkishQuery);
        final bExactMeaningMatch = _hasExactMeaningMatch(bAnlam, lowerTurkishQuery);
        
        if (aExactMeaningMatch && !bExactMeaningMatch) return -1;
        if (bExactMeaningMatch && !aExactMeaningMatch) return 1;
        
        // 1b. ANLAM BAŞLANGICI - "kat" aradığında "katıldı, katılmak" olan kelimeler
        final aMeaningStartsWith = _hasMeaningStartsWith(aAnlam, lowerTurkishQuery);
        final bMeaningStartsWith = _hasMeaningStartsWith(bAnlam, lowerTurkishQuery);
        
        if (aMeaningStartsWith && !bMeaningStartsWith) return -1;
        if (bMeaningStartsWith && !aMeaningStartsWith) return 1;

        // 1c. ANLAM POZISYONU ÖNCELİĞİ - ilk anlamda geçenler daha önde
        final aMeaningPos = _getMeaningPosition(aAnlam, lowerTurkishQuery);
        final bMeaningPos = _getMeaningPosition(bAnlam, lowerTurkishQuery);
        if (aMeaningPos != bMeaningPos) return aMeaningPos.compareTo(bMeaningPos);

        // 1c. TÜRKÇE İÇİN İÇİNDE GEÇME KALDIRILDI - Sadece başlangıç eşleşmeleri!

        // ============= 2. LATİN SORGU İÇİN ARAPÇA TAHMİN ÖNCELİĞİ =============
        // Latin sorgularda, Türkçe anlam önceliğinden SONRA Arapça tahminle (guess) kelime eşleşmelerini ele al
        if (!isArabicQuery && originalQuery.trim().length <= 3) {
          final guess = _latinToArabicGuess(originalQuery).toLowerCase();
          if (guess.isNotEmpty) {
            // Ön Kural: Arapça yazımı olan kelimeleri öncele
            bool aHasArabic = _hasOnlyArabicCharacters(a.kelime) || _hasOnlyArabicCharacters(a.harekeliKelime ?? '');
            bool bHasArabic = _hasOnlyArabicCharacters(b.kelime) || _hasOnlyArabicCharacters(b.harekeliKelime ?? '');
            if (aHasArabic != bHasArabic) return aHasArabic ? -1 : 1;

            final aExactGuess = aNormKelime.toLowerCase() == guess || aNormHarekeli.toLowerCase() == guess;
            final bExactGuess = bNormKelime.toLowerCase() == guess || bNormHarekeli.toLowerCase() == guess;
            if (aExactGuess != bExactGuess) return aExactGuess ? -1 : 1;
            if (aExactGuess && bExactGuess) {
              // Uzunluk yakınlığı - baz formu öne al
              final aLen = [aNormKelime.length, aNormHarekeli.length].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
              final bLen = [bNormKelime.length, bNormHarekeli.length].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
              final qLen = guess.length;
              final aDist = (aLen - qLen).abs();
              final bDist = (bLen - qLen).abs();
              if (aDist != bDist) return aDist.compareTo(bDist);
            }

            final aStartsGuess = aNormKelime.toLowerCase().startsWith(guess) || aNormHarekeli.toLowerCase().startsWith(guess);
            final bStartsGuess = bNormKelime.toLowerCase().startsWith(guess) || bNormHarekeli.toLowerCase().startsWith(guess);
            if (aStartsGuess != bStartsGuess) return aStartsGuess ? -1 : 1;

            final aContGuess = aNormKelime.toLowerCase().contains(guess) || aNormHarekeli.toLowerCase().contains(guess);
            final bContGuess = bNormKelime.toLowerCase().contains(guess) || bNormHarekeli.toLowerCase().contains(guess);
            if (aContGuess != bContGuess) return aContGuess ? -1 : 1;
          }
        }

        // ============= 2. ARAPÇA KELİME KONTROLÜ =============
        
        if (queryHasDiacritics) {
          // Harekeli arama - tam eşleşme öncelikli
          final aExactMatch = a.kelime == originalQuery || a.harekeliKelime == originalQuery;
          final bExactMatch = b.kelime == originalQuery || b.harekeliKelime == originalQuery;
          
          if (aExactMatch && !bExactMatch) return -1;
          if (bExactMatch && !aExactMatch) return 1;
          
          // Başlangıç eşleşmesi
          final aStartsWith = a.kelime.startsWith(originalQuery) || (a.harekeliKelime ?? '').startsWith(originalQuery);
          final bStartsWith = b.kelime.startsWith(originalQuery) || (b.harekeliKelime ?? '').startsWith(originalQuery);
          
          if (aStartsWith && !bStartsWith) return -1;
          if (bStartsWith && !aStartsWith) return 1;
        } else {
          // Harekesiz arama için normalize ederek karşılaştır
          final nqLower = normalizedQuery.toLowerCase();

          // 2a. TAM KELİME EŞLEŞMESI
          final aExactMatch = aNormKelime.toLowerCase() == nqLower || 
                             aNormHarekeli.toLowerCase() == nqLower;
          final bExactMatch = bNormKelime.toLowerCase() == nqLower || 
                             bNormHarekeli.toLowerCase() == nqLower;
          
          if (aExactMatch && !bExactMatch) return -1;
          if (bExactMatch && !aExactMatch) return 1;
          
          // 2b. KÖK EŞLEŞMESI - harfler sıralı olarak geçiyor mu? (normalized)
          final aRootMatch = nqLower.length >= 2 && (
              _hasSequentialLetters(aNormKelime.toLowerCase(), nqLower) ||
              _hasSequentialLetters(aNormHarekeli.toLowerCase(), nqLower));
          final bRootMatch = nqLower.length >= 2 && (
              _hasSequentialLetters(bNormKelime.toLowerCase(), nqLower) ||
              _hasSequentialLetters(bNormHarekeli.toLowerCase(), nqLower));

          if (aRootMatch && !bRootMatch) return -1;
          if (bRootMatch && !aRootMatch) return 1;
          
          // 2c. KELİME BAŞLANGICI
          final aStartsWith = aNormKelime.toLowerCase().startsWith(nqLower) || 
                             aNormHarekeli.toLowerCase().startsWith(nqLower);
          final bStartsWith = bNormKelime.toLowerCase().startsWith(nqLower) || 
                             bNormHarekeli.toLowerCase().startsWith(nqLower);
          
          if (aStartsWith && !bStartsWith) return -1;
          if (bStartsWith && !aStartsWith) return 1;
          
          // 2d. KELİME İÇİNDE GEÇİYOR (DOĞRUDAN SUBSTRING)
          final aContains = aNormKelime.toLowerCase().contains(nqLower) || 
                           aNormHarekeli.toLowerCase().contains(nqLower);
          final bContains = bNormKelime.toLowerCase().contains(nqLower) || 
                           bNormHarekeli.toLowerCase().contains(nqLower);
          
          if (aContains && !bContains) return -1;
          if (bContains && !aContains) return 1;
        }
        
        // ============= 3. KELIME UZUNLUĞU (KISA KELİMELER DAHA ÖNCELİKLİ) =============
        final aMinLength = [aNormKelime.length, aNormHarekeli.length]
            .where((l) => l > 0)
            .fold(999, (prev, curr) => prev < curr ? prev : curr);
        final bMinLength = [bNormKelime.length, bNormHarekeli.length]
            .where((l) => l > 0)
            .fold(999, (prev, curr) => prev < curr ? prev : curr);
        
        if (aMinLength != bMinLength) return aMinLength.compareTo(bMinLength);
        
        // ============= 4. ANLAM UZUNLUĞU (KISA ANLAMLAR DAHA ÖNCELİKLİ) =============
        final aAnlamLength = aAnlam.length;
        final bAnlamLength = bAnlam.length;
        
        return aAnlamLength.compareTo(bAnlamLength);
      }
      
      /// Tam anlam eşleşmesi kontrolü - "katıldı" aradığında "katıldı" anlamı olan kelimeler
      bool _hasExactMeaningMatch(String meanings, String query) {
        if (meanings.isEmpty || query.isEmpty) return false;
        
        final meaningList = meanings
            .split(RegExp(r'[,;.\n]'))
            .map((m) => m.trim())
            .where((m) => m.isNotEmpty)
            .toList();
        
        return meaningList.any((meaning) => meaning == query);
      }
      
      /// Anlam başlangıcı kontrolü - "kat" aradığında "katıldı, katılmak" olan kelimeler
      bool _hasMeaningStartsWith(String meanings, String query) {
        if (meanings.isEmpty || query.isEmpty) return false;
        
        final meaningList = meanings
            .split(RegExp(r'[,;.\n]'))
            .map((m) => m.trim())
            .where((m) => m.isNotEmpty)
            .toList();
        
        return meaningList.any((meaning) => meaning.startsWith(query) && meaning != query);
      }
      
      /// Anlam içinde geçme kontrolü - "katıl" aradığında "iştirak, katılım" olan kelimeler
      bool _hasMeaningContains(String meanings, String query) {
        if (meanings.isEmpty || query.isEmpty) return false;
        
        final meaningList = meanings
            .split(RegExp(r'[,;.\n]'))
            .map((m) => m.trim())
            .where((m) => m.isNotEmpty)
            .toList();
        
        return meaningList.any((meaning) => 
            meaning.contains(query) && 
            !meaning.startsWith(query) && 
            meaning != query
        );
      }

      /// Arapça fiillerde geleceğe / bağlaçlara işaret eden önekler için küçük ceza
      /// "سوف" başlarsa 2, "س" veya "و" veya "ل" ile başlarsa 1, diğer tüm durumlarda 0 döner
      int _getArabicPrefixPenalty(String s) {
        if (s.isEmpty) return 0;
        final trimmed = _removeArabicDiacritics(s);
        if (trimmed.startsWith('سوف')) return 2;
        if (trimmed.startsWith('س') || trimmed.startsWith('و') || trimmed.startsWith('ل')) return 1;
        return 0;
      }

      /// Kök eşleşmesi kontrolü - Arapça morfoloji kurallarına göre
      bool _isRootMatch(String kelime1, String kelime2, String query) {
        if (query.length < 2) return false; // En az 2 harf olmalı
        
        final lowerQuery = query.toLowerCase();
        final lowerKelime1 = kelime1.toLowerCase(); 
        final lowerKelime2 = kelime2.toLowerCase();
        
        // Kök eşleşmesi: query'nin harfleri sırasıyla kelimede geçiyor mu?
        // Örnek: "كتب" kökü "كاتب", "مكتوب", "كتابة" kelimelerinde geçer
        return _hasSequentialLetters(lowerKelime1, lowerQuery) || 
               _hasSequentialLetters(lowerKelime2, lowerQuery);
      }
      
      /// Harflerin sıralı olarak geçip geçmediğini kontrol eder
      bool _hasSequentialLetters(String word, String query) {
        if (word.isEmpty || query.isEmpty) return false;
        
        int queryIndex = 0;
        
        for (int i = 0; i < word.length && queryIndex < query.length; i++) {
          if (word[i] == query[queryIndex]) {
            queryIndex++;
          }
        }
        
        // Sorgunun tüm harfleri sırasıyla bulundu mu?
        return queryIndex == query.length;
      }

      Future close() async {
        if (kIsWeb) return;
        final db = await instance.database;
        if (db == null) return;
        db.close();
      }
    }