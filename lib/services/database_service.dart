// kavaid/lib/services/database_service.dart

import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word_model.dart';
import '../data/embedded_words_data.dart';

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
        if (pair == 'sh') {
          buffer.write('ش');
          i++;
          continue;
        }
        if (pair == 'kh') {
          buffer.write('خ');
          i++;
          continue;
        }
        if (pair == 'dh') {
          buffer.write('ذ');
          i++;
          continue;
        }
        if (pair == 'th') {
          buffer.write('ث');
          i++;
          continue;
        }
        if (pair == 'gh') {
          buffer.write('غ');
          i++;
          continue;
        }
        if (pair == 'ch') {
          buffer.write('چ');
          i++;
          continue;
        }
      }

      // Tek harf eşlemeleri (basit)
      switch (ch) {
        case 'a':
        case 'e':
        case 'i':
        case 'o':
        case 'u':
        case 'ı':
        case 'ö':
        case 'ü':
          // Kelimenin başındaki ilk ünlü için ع ekleyerek 'arab' -> 'عرب' gibi tahminleri yakala
          if (i == 0) buffer.write('ع');
          // Diğer ünlüleri atla (iskeleti koru)
          break;
        case 'b':
          buffer.write('ب');
          break;
        case 't':
          buffer.write('ت');
          break;
        case 'j':
          buffer.write('ج');
          break;
        case 'h':
          buffer.write('ه');
          break;
        case 'd':
          buffer.write('د');
          break;
        case 'z':
          buffer.write('ذ');
          break; // 'z' için ذ tercih (ذهب örneği)
        case 'r':
          buffer.write('ر');
          break;
        case 's':
          buffer.write('س');
          break;
        case 'f':
          buffer.write('ف');
          break;
        case 'q':
          buffer.write('ق');
          break;
        case 'k':
          buffer.write('ك');
          break;
        case 'l':
          buffer.write('ل');
          break;
        case 'm':
          buffer.write('م');
          break;
        case 'n':
          buffer.write('ن');
          break;
        case 'w':
          buffer.write('و');
          break;
        case 'y':
          buffer.write('ي');
          break;
        case 'g':
          buffer.write('ك');
          break; // yaklaşık
        case 'c':
          buffer.write('س');
          break; // yaklaşık
        case 'p':
          buffer.write('ب');
          break; // yaklaşık
        case 'v':
          buffer.write('ف');
          break; // yaklaşık
        case 'x':
          buffer.write('كس');
          break; // yaklaşık
        default:
          // Diğer karakterleri atla
          break;
      }
    }
    return buffer.toString();
  }

  static final RegExp _diacriticsRegex = RegExp(
    r'[\u064B-\u065F\u0670\u0653-\u0655]',
  );

  /// Arapça harekelerini kaldır (normalizasyon)
  String _removeArabicDiacritics(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll(_diacriticsRegex, '');
  }

  /// Metinde Arapça hareke var mı kontrol et
  bool _hasArabicDiacritics(String text) {
    return _diacriticsRegex.hasMatch(text);
  }

  /// Türkçe anlamda arama teriminin pozisyonunu bul
  /// İlk anlamda olanlar için 0, ikinci anlamda olanlar için daha büyük sayı döner
  int _getMeaningPosition(String anlam, String query) {
    if (anlam.isEmpty || query.isEmpty) return 999;

    // Anlamları virgül ve noktalı virgülle ayır
    final meanings = anlam.split(_commaSemicolonRx).map((m) => m.trim()).toList();

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

    // 3. KELİME BAŞI EŞLEŞİR (yeni kelimeye başlayan) - anlam sırasına göre
    for (int i = 0; i < meanings.length; i++) {
      final meaning = meanings[i].toLowerCase().trim();
      final queryLower = query.toLowerCase().trim();

      // Yeni kelime başında mı geçiyor (boşluk veya tire sonrası)
      // Örn: "okul, ilim" aramasında "i" yazınca "ilim" eşleşir
      // Ama "güçlendirici" gibi kelime içinde geçenler eşleşmez
      if (meaning.contains(' $queryLower') ||
          meaning.contains('-$queryLower') ||
          meaning.contains(', $queryLower') ||
          meaning.contains('; $queryLower')) {
        return 200 + i; // Kelime başı: 200, 201, 202...
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
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        // Her açılışta tabloların var olduğundan emin ol
        await _createDB(db, 1);
      },
    );
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
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_kelime ON words(kelime COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_harekeli ON words(harekeliKelime COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pending_kelime ON pending_ai_words(kelime COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pending_harekeli ON pending_ai_words(harekeliKelime COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pending_anlam ON pending_ai_words(anlam COLLATE NOCASE)',
    );
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
        ornekCumlelerData = json.encode(
          word.ornekCumleler!.map((e) {
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
              return {'arapcaCumle': '', 'turkceCeviri': ''};
            }
          }).toList(),
        );
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

  Map<String, dynamic> _embeddedMapToDbMap(Map<String, dynamic> word) {
    return {
      'kelime': word['kelime'] as String? ?? '',
      'harekeliKelime': word['harekeliKelime'] as String? ?? '',
      'anlam': word['anlam'] as String? ?? '',
      'koku': word['koku'] as String? ?? '',
      'dilbilgiselOzellikler': json.encode(
        word['dilbilgiselOzellikler'] ?? <String, dynamic>{},
      ),
      'ornekCumleler': json.encode(word['ornekCumleler'] ?? <dynamic>[]),
      'fiilCekimler': json.encode(word['fiilCekimler'] ?? <String, dynamic>{}),
      'eklenmeTarihi': word['eklenmeTarihi'] as int? ?? 0,
    };
  }

  WordModel _dbMapToWord(Map<String, dynamic> map) {
    // ornekCumleler için güvenli dönüştürme (Hem String json hem de List formunu destekler)
    var ornekRaw = map['ornekCumleler'];
    final decodedOrnekler = (ornekRaw is String)
        ? json.decode(ornekRaw.isEmpty ? '[]' : ornekRaw)
        : (ornekRaw ?? []);
    final ornekCumlelerList = (decodedOrnekler is List)
        ? decodedOrnekler.map((e) {
            final ornekMap = Map<String, dynamic>.from(e as Map);
            return ornekMap;
          }).toList()
        : <Map<String, dynamic>>[];

    // dilbilgiselOzellikler için güvenli dönüştürme
    var ozellikRaw = map['dilbilgiselOzellikler'];
    final decodedOzellikler = (ozellikRaw is String)
        ? json.decode(ozellikRaw.isEmpty ? '{}' : ozellikRaw)
        : (ozellikRaw ?? {});
    final ozelliklerMap = (decodedOzellikler is Map)
        ? Map<String, dynamic>.from(decodedOzellikler)
        : <String, dynamic>{};

    // fiilCekimler için güvenli dönüştürme
    var cekimRaw = map['fiilCekimler'];
    final decodedCekimler = (cekimRaw is String)
        ? json.decode(cekimRaw.isEmpty ? '{}' : cekimRaw)
        : (cekimRaw ?? {});
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
    await db.insert(
      'pending_ai_words',
      _wordToDbMap(word),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getPendingAiWordsCount() async {
    if (kIsWeb) return 0;
    final db = await instance.database;
    if (db == null) return 0;
    final result = await db.rawQuery('SELECT COUNT(*) FROM pending_ai_words');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── Statik Regex — tek seferde derlenir ─────────────────────────────────
  static final RegExp _diacriticsRx = RegExp(
    r'[\u064B-\u065F\u0670\u0640\u0653-\u0655]',
  );
  static final RegExp _arabicRx = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _hamzaRx = RegExp('[\u0623\u0625\u0622\u0621\u0671]');
  static final RegExp _nonLatinAlphanumericRx = RegExp(r'[^a-z0-9\s,;]');
  static final RegExp _whitespaceRx = RegExp(r'\s+');
  static final RegExp _meaningSplitRx = RegExp(r'[,،;]');
  static final RegExp _commaSemicolonRx = RegExp(r'[,;]');

  // ─── Hemze normalizasyonu: أ إ آ ء → ا ───────────────────────────────────
  static String _normalizeHamza(String text) {
    return text
        .replaceAll(_hamzaRx, '\u0627')
        .replaceAll('\u0624', '\u0648')
        .replaceAll('\u0626', '\u064A')
        .replaceAll('\u0649', '\u064A');
  }

  // ─── Tam normalize (harekeleri + hemze) ──────────────────────────────────
  static String _fullNormalize(String text) {
    if (text.isEmpty) return text;
    return _normalizeHamza(text.replaceAll(_diacriticsRx, ''));
  }

  static String _normalizeLatinSearch(String text) {
    if (text.isEmpty) return '';
    return text
        .toLowerCase()
        .replaceAll('\u00E7', 'c')
        .replaceAll('\u011F', 'g')
        .replaceAll('\u0131', 'i')
        .replaceAll('\u0307', '')
        .replaceAll('\u00F6', 'o')
        .replaceAll('\u015F', 's')
        .replaceAll('\u00FC', 'u')
        .replaceAll(_nonLatinAlphanumericRx, ' ')
        .replaceAll(_whitespaceRx, ' ')
        .trim();
  }

  // ─── Önceden normalize edilmiş harekeliKelime cache'i ────────────────────────────
  static List<String>? _normalizedKelimeCache;
  static List<String>? _normalizedHKCache;
  static List<String>? _normalizedRootCache;
  static Map<int, String>? _meaningCache;
  static bool _isPrewarming = false;
  static Future<void>? _prewarmFuture;

  static final SearchIsolateWorker _worker = SearchIsolateWorker();

  static bool get isSearchCacheReady => kIsWeb ? true : _worker.isReady;

  static Future<void> ensureSearchCacheReady() async {
    if (kIsWeb) return;
    await _worker.start();
  }

  static void _buildCache() {
    if (_normalizedHKCache != null) return;
    final kList = <String>[];
    final hkList = <String>[];
    final rootList = <String>[];
    final mList = <int, String>{};

    for (int i = 0; i < embeddedWordsData.length; i++) {
      final map = embeddedWordsData[i];
      final rawK = map['kelime'] as String? ?? '';
      final rawHK = map['harekeliKelime'] as String? ?? '';
      final rawRoot = map['koku'] as String? ?? '';
      final rawA = map['anlam'] as String? ?? '';

      kList.add(rawK.isEmpty ? '' : _fullNormalize(rawK));
      hkList.add(rawHK.isEmpty ? '' : _fullNormalize(rawHK));
      rootList.add(rawRoot.isEmpty ? '' : _fullNormalize(rawRoot));

      final pipIdx = rawA.indexOf('||');
      mList[i] = _normalizeLatinSearch(
        pipIdx >= 0 ? rawA.substring(0, pipIdx) : rawA,
      );
    }
    _normalizedKelimeCache = kList;
    _normalizedHKCache = hkList;
    _normalizedRootCache = rootList;
    _meaningCache = mList;
  }

  /// Uygulamanin başlangıcında cache'i önceden çak. main.dart veya initState'den çağrın.
  static Future<void> _buildCacheIncrementally({int chunkSize = 700}) async {
    if (_normalizedHKCache != null) return;
    final kList = <String>[];
    final hkList = <String>[];
    final rootList = <String>[];
    final mList = <int, String>{};

    for (int i = 0; i < embeddedWordsData.length; i++) {
      final map = embeddedWordsData[i];
      final rawK = map['kelime'] as String? ?? '';
      final rawHK = map['harekeliKelime'] as String? ?? '';
      final rawRoot = map['koku'] as String? ?? '';
      final rawA = map['anlam'] as String? ?? '';

      kList.add(rawK.isEmpty ? '' : _fullNormalize(rawK));
      hkList.add(rawHK.isEmpty ? '' : _fullNormalize(rawHK));
      rootList.add(rawRoot.isEmpty ? '' : _fullNormalize(rawRoot));

      final pipIdx = rawA.indexOf('||');
      mList[i] = _normalizeLatinSearch(
        pipIdx >= 0 ? rawA.substring(0, pipIdx) : rawA,
      );

      if (i > 0 && i % chunkSize == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    _normalizedKelimeCache = kList;
    _normalizedHKCache = hkList;
    _normalizedRootCache = rootList;
    _meaningCache = mList;
  }

  static Future<void> prewarmCache() async {
    if (_normalizedHKCache != null) return;
    if (_prewarmFuture != null) return _prewarmFuture;
    _isPrewarming = true;
    _prewarmFuture = _buildCacheIncrementally().whenComplete(() {
      _isPrewarming = false;
      _prewarmFuture = null;
    });
    return _prewarmFuture;
  }

  // ─── Türkçe anlamdaki tüm anlamları döndür (||HARFI_CER bölümünü at) ──────
  static String _extractMeanings(String anlam) {
    // "anlam1, anlam2||HARFI_CER:..." formatından sadece anlam kısmını al
    final pipIndex = anlam.indexOf('||');
    return pipIndex >= 0 ? anlam.substring(0, pipIndex) : anlam;
  }

  static bool _hasWholeToken(String text, String token) {
    if (text.isEmpty || token.isEmpty) return false;
    return text == token ||
        text.startsWith('$token ') ||
        text.endsWith(' $token') ||
        text.contains(' $token ');
  }

  static bool _hasTokenStartingWith(String text, String token) {
    if (text.isEmpty || token.isEmpty) return false;
    return text.startsWith(token) || text.contains(' $token');
  }

  // ─── RAM'de arama (Isolate-safe, embeddedWordsData'yı okur) ──────────────
  static List<Map<String, dynamic>> _runIsolateSearch(
    Map<String, dynamic> args,
  ) {
    final query = args['query'] as String;
    final normQuery = args['normQuery'] as String; // tam normalize
    final turkQuery = args['turkQuery'] as String; // lowercase turkish
    final isArabic = args['isArabic'] as bool;
    final arabicGuess = args['arabicGuess'] as String;
    final latinGuessOn = args['latinGuessOn'] as bool;

    // Cache yoksa (prewarm henüz bitmedi) oluştur
    _buildCache();
    final kCache = _normalizedKelimeCache!;
    final hkCache = _normalizedHKCache!;
    final rootCache = _normalizedRootCache!;
    final mCache = _meaningCache!;

    // Sonuçlar: [rank, sec, index]
    final results = <({int rank, int sec, int idx})>[];

    for (int i = 0; i < embeddedWordsData.length; i++) {
      final map = embeddedWordsData[i];
      final rawK = map['kelime'] as String? ?? '';
      final rawHK = map['harekeliKelime'] as String? ?? '';
      final rawRoot = map['koku'] as String? ?? '';
      final nK = kCache[i];
      final nHK = hkCache[i]; // önceden normalize edilmiş
      final nRoot = rootCache[i];

      int rank = 9999;
      int sec = 0;

      if (isArabic) {
        // ── Arapça arama: SADECE harekeliKelime kullanılır ────────────────────
        if (rawHK.isEmpty && rawK.isEmpty && rawRoot.isEmpty) continue;

        if (rawHK == query || rawK == query || rawRoot == query) {
          rank = 0;
          sec = nHK.isNotEmpty ? nHK.length : nK.length;
        } else if (nHK == normQuery || nK == normQuery) {
          rank = 1;
          sec = nHK.isNotEmpty ? nHK.length : nK.length;
        } else if (nRoot == normQuery) {
          rank = 2;
          sec = nRoot.length;
        } else if (nHK.startsWith(normQuery) || nK.startsWith(normQuery)) {
          rank = 3;
          sec = nHK.isNotEmpty ? nHK.length : nK.length;
        } else if (_hasWholeToken(nHK, normQuery) ||
            _hasWholeToken(nK, normQuery)) {
          rank = 4;
          sec = nHK.isNotEmpty ? nHK.length : nK.length;
        } else if (_hasTokenStartingWith(nHK, normQuery) ||
            _hasTokenStartingWith(nK, normQuery)) {
          rank = 5;
          sec = nHK.isNotEmpty ? nHK.length : nK.length;
        } else if (nHK.contains(normQuery) || nK.contains(normQuery)) {
          rank = 6;
          sec = nHK.isNotEmpty ? nHK.length : nK.length;
        }
      } else {
        // ── Türkçe arama ──────────────────────────────────────────
        final meanings =
            mCache[i] ?? ""; // önceden dönüştürülmüş lowercase anlam

        // ⚡ Hızlı ön-filtre: anlam içinde geçmiyorsa direkt atla
        // Bu 55k yerine sadece eşleşen yüzlerce entry için detaylı analiz yapar
        final hasMeaning = meanings.isNotEmpty;
        final quickHit = hasMeaning && meanings.contains(turkQuery);
        final quickLatin =
            latinGuessOn &&
            arabicGuess.isNotEmpty &&
            (nHK.contains(arabicGuess) ||
                nK.contains(arabicGuess) ||
                nRoot.contains(arabicGuess));

        if (!quickHit && !quickLatin) continue; // ← büyük performans kazancı

        if (!hasMeaning) {
          if (latinGuessOn && arabicGuess.isNotEmpty) {
            if (nHK.startsWith(arabicGuess) || nK.startsWith(arabicGuess)) {
              rank = 90;
              sec = nHK.isNotEmpty ? nHK.length : nK.length;
            } else if (nRoot == arabicGuess) {
              rank = 91;
              sec = nRoot.length;
            } else if (nHK.contains(arabicGuess) || nK.contains(arabicGuess)) {
              rank = 92;
              sec = nHK.isNotEmpty ? nHK.length : nK.length;
            }
          }
        } else {
          final parts = meanings.split(_meaningSplitRx);
          int? bestRank;
          int bestSec = 99;

          for (int j = 0; j < parts.length; j++) {
            final m = parts[j].trim();
            if (m.isEmpty || !m.contains(turkQuery))
              continue; // hızlı eleman skiple
            int r = 9999;
            if (m == turkQuery) {
              r = 0 + j;
            } else if (m.startsWith('$turkQuery ') ||
                m.startsWith('$turkQuery,') ||
                m.startsWith('$turkQuery;')) {
              r = 5 + j;
            } else if (m.startsWith(turkQuery)) {
              r = 10 + j;
            } else {
              final wb =
                  m.contains(' $turkQuery ') ||
                  m.contains(' $turkQuery,') ||
                  m.contains(' $turkQuery;') ||
                  m.endsWith(' $turkQuery');
              if (wb) {
                r = 20 + j;
              } else {
                r = 30 + j;
              }
            }
            if (r < (bestRank ?? 9999)) {
              bestRank = r;
              bestSec = j;
            }
          }

          if (bestRank != null) {
            rank = bestRank;
            sec = bestSec;
          } else if (latinGuessOn && arabicGuess.isNotEmpty) {
            if (nHK.startsWith(arabicGuess) || nK.startsWith(arabicGuess)) {
              rank = 90;
              sec = nHK.isNotEmpty ? nHK.length : nK.length;
            } else if (nRoot == arabicGuess) {
              rank = 91;
              sec = nRoot.length;
            } else if (nHK.contains(arabicGuess) || nK.contains(arabicGuess)) {
              rank = 92;
              sec = nHK.isNotEmpty ? nHK.length : nK.length;
            }
          }
        }
      }

      if (rank < 9999) {
        if (isArabic && rank >= 6 && results.length >= 360) {
          continue;
        }
        results.add((rank: rank, sec: sec, idx: i));
      }
    }

    // Sırala: önce rank, sonra secondary
    results.sort((a, b) {
      final r = a.rank.compareTo(b.rank);
      if (r != 0) return r;
      return a.sec.compareTo(b.sec);
    });

    // Map listesine dönüştür (idx üzerinden). UI jank'ini azaltmak için ilk
    // anlamlı sonuç grubuyla sınırlı tutuyoruz; kalanlar genelde düşük skorlu.
    return results.take(120).map((r) {
      final m = Map<String, dynamic>.from(embeddedWordsData[r.idx]);
      m['rank'] = r.rank;
      return m;
    }).toList();
  }

  Future<List<WordModel>> searchWords(
    String query, {
    bool exactMatch = false,
  }) async {
    if (kIsWeb) return [];
    if (query.isEmpty) return [];

    final isArabic = _arabicRx.hasMatch(query);
    final normQuery = _fullNormalize(query);
    final turkQuery = _normalizeLatinSearch(query.trim());
    if (!isArabic && turkQuery.isEmpty) return [];
    final arabicGuess = isArabic ? '' : _latinToArabicGuess(query);
    final latinGuessOn =
        !isArabic && arabicGuess.isNotEmpty && query.trim().length <= 5;

    // UI frame'inin render edilmesine fırsat ver, sonra aramayı yap.
    await Future.delayed(Duration.zero);

    // PERFORMANCE: Ana thread'de senkron arama — ÖNCEden kurulmuş cache ile
    // compute() KULLANILMIYOR çünkü her çağrıda yeni Isolate açıp 55K cache'i
    // sıfırdan kuruyordu (~500ms+ overhead). prewarmCache() bir kez çalıştırılıyor
    // ve cache bellekte kalıyor — arama ~10-30ms sürüyor.
    final searchArgs = {
      'query': query,
      'normQuery': normQuery,
      'turkQuery': turkQuery,
      'isArabic': isArabic,
      'arabicGuess': arabicGuess,
      'latinGuessOn': latinGuessOn,
    };
    final List<Map<String, dynamic>> rawResults = kIsWeb
        ? _runIsolateSearch(searchArgs)
        : await _worker.search(searchArgs);

    // pending_ai_words tablosundan da ekle (SQLite - küçük tablo, hızlı)
    try {
      final db = await instance.database;
      if (db != null) {
        if (isArabic) {
          final pt = '%$normQuery%';
          final pending = await db.rawQuery(
            'SELECT *, 0 as rank FROM pending_ai_words WHERE kelime LIKE ? OR harekeliKelime LIKE ? LIMIT 50',
            [pt, pt],
          );
          rawResults.addAll(pending);
        } else {
          final pt = '%$turkQuery%';
          final pending = await db.rawQuery(
            'SELECT *, 0 as rank FROM pending_ai_words WHERE LOWER(anlam) LIKE ? LIMIT 50',
            [pt],
          );
          rawResults.addAll(pending);
        }
      }
    } catch (_) {}

    // Modüle dönüştür + uzun kelime ifadeleri filtrele + dedupe
    final seen = <String>{};
    final results = <WordModel>[];
    for (final map in rawResults) {
      final hk = (map['harekeliKelime'] as String? ?? '').trim();
      // 3'ten fazla kelime içeren ifadeleri (örnek cümleler) listeden çıkar
      if (hk.isNotEmpty &&
          hk.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length > 2)
        continue;
      // Dedupe: aynı harekeli kelimeyi ikinci kez gösterme
      final dedupeKey = hk.isNotEmpty ? hk : (map['kelime'] as String? ?? '');
      if (dedupeKey.isNotEmpty && !seen.add(dedupeKey)) continue;

      results.add(_dbMapToWord(map));
    }

    return results;
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
        batch.insert(
          'words',
          _wordToDbMap(word),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> recreateWordsTableFromEmbeddedMaps(
    List<Map<String, dynamic>> words, {
    int chunkSize = 400,
    ValueChanged<int>? onChunkCommitted,
  }) async {
    if (kIsWeb) return;

    final db = await instance.database;
    if (db == null) return;

    await db.delete('words');

    for (var start = 0; start < words.length; start += chunkSize) {
      final end = (start + chunkSize < words.length)
          ? start + chunkSize
          : words.length;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (var i = start; i < end; i++) {
          batch.insert(
            'words',
            _embeddedMapToDbMap(words[i]),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });

      onChunkCommitted?.call(end);

      // Give Android's input dispatcher and Flutter's frame scheduler a chance
      // to run during first-install database creation.
      await Future<void>.delayed(Duration.zero);
    }
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
    await db.insert(
      'words',
      _wordToDbMap(word),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // PERFORMANCE: SQL WHERE clause ile indeksli arama — tüm DB'yi belleğe çekmek yerine
  Future<WordModel?> getWordByExactMatch(String query) async {
    if (kIsWeb) return null;
    final db = await instance.database;
    if (db == null) return null;

    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return null;

    final queryHasDiacritics = _hasArabicDiacritics(trimmedQuery);

    if (queryHasDiacritics) {
      // Harekeli TAM eşleşme — indeksli WHERE sorgusu
      final maps = await db.rawQuery(
        '''
        SELECT * FROM words WHERE kelime = ? OR harekeliKelime = ?
        UNION
        SELECT * FROM pending_ai_words WHERE kelime = ? OR harekeliKelime = ?
        LIMIT 1
      ''',
        [trimmedQuery, trimmedQuery, trimmedQuery, trimmedQuery],
      );

      if (maps.isNotEmpty) {
        return _dbMapToWord(maps.first);
      }
    } else {
      // Harekesiz arama — LIKE ile normalize arama
      // Önce tam eşleşme dene (indeksli, hızlı)
      final exactMaps = await db.rawQuery(
        '''
        SELECT * FROM words WHERE kelime = ? COLLATE NOCASE OR harekeliKelime = ? COLLATE NOCASE
        UNION
        SELECT * FROM pending_ai_words WHERE kelime = ? COLLATE NOCASE OR harekeliKelime = ? COLLATE NOCASE
        LIMIT 1
      ''',
        [trimmedQuery, trimmedQuery, trimmedQuery, trimmedQuery],
      );

      if (exactMaps.isNotEmpty) {
        return _dbMapToWord(exactMaps.first);
      }

      // Tam eşleşme bulunamadıysa, normalize karşılaştırma için
      // harekesiz halini SQL LIKE ile daralt, sonra Dart'ta kesin kontrol yap
      final normalizedQuery = _removeArabicDiacritics(
        trimmedQuery,
      ).toLowerCase();
      final likeMaps = await db.rawQuery(
        '''
        SELECT * FROM words WHERE kelime LIKE ? OR harekeliKelime LIKE ?
        UNION
        SELECT * FROM pending_ai_words WHERE kelime LIKE ? OR harekeliKelime LIKE ?
        LIMIT 20
      ''',
        [
          '%$normalizedQuery%',
          '%$normalizedQuery%',
          '%$normalizedQuery%',
          '%$normalizedQuery%',
        ],
      );

      for (final map in likeMaps) {
        final kelime = map['kelime'] as String? ?? '';
        final harekeliKelime = map['harekeliKelime'] as String? ?? '';

        final normalizedKelime = _removeArabicDiacritics(kelime).toLowerCase();
        final normalizedHarekeli = _removeArabicDiacritics(
          harekeliKelime,
        ).toLowerCase();

        if (normalizedKelime == normalizedQuery ||
            normalizedHarekeli == normalizedQuery) {
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
    final maps = await db.rawQuery(
      '''
      SELECT * FROM words WHERE harekeliKelime = ?
      UNION
      SELECT * FROM pending_ai_words WHERE harekeliKelime = ?
      LIMIT 1
    ''',
      [harekeliKelime, harekeliKelime],
    );

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
      final randomOffset =
          (totalWords * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)
              .floor();

      // Rastgele kelime getir
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT * FROM (
          SELECT * FROM words
          UNION ALL
          SELECT * FROM pending_ai_words
        )
        ORDER BY kelime
        LIMIT 1 OFFSET ?
      ''',
        [randomOffset],
      );

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

    final arabicPattern = RegExp(
      r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\s]+$',
    );
    return arabicPattern.hasMatch(text);
  }

  /// Veritabanındaki duplicate harekeli kelimeleri bul
  Future<Map<String, List<Map<String, dynamic>>>>
  findDuplicateHarekeliWords() async {
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
      final words = await db.rawQuery(
        '''
        SELECT * FROM words 
        WHERE harekeliKelime = ? 
        ORDER BY rowid
      ''',
        [harekeliKelime],
      );

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
      if (harekeliKelime.isNotEmpty &&
          !_hasOnlyArabicCharacters(harekeliKelime)) {
        problematicWords.add(word);
        continue;
      }

      // Normal kelime de Arapça olmalı ama Latin harf içeriyorsa
      if (kelime.isNotEmpty &&
          kelime != harekeliKelime &&
          !_hasOnlyArabicCharacters(kelime)) {
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

      print(
        '🗑️ Duplicate temizlendi: "$harekeliKelime" (${wordsToDelete.length} kopya silindi)',
      );
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

      print(
        '🗑️ Latin harf içeren kelime silindi: "$kelime" / "$harekeliKelime"',
      );
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
        final aExact =
            a.kelime == originalQuery || a.harekeliKelime == originalQuery;
        final bExact =
            b.kelime == originalQuery || b.harekeliKelime == originalQuery;
        if (aExact != bExact) return aExact ? -1 : 1;

        // 2) Normalize tam eşleşme (base formu öne al)
        final nq = normalizedQuery.toLowerCase();
        final aNormExact =
            aNormKelime.toLowerCase() == nq ||
            aNormHarekeli.toLowerCase() == nq;
        final bNormExact =
            bNormKelime.toLowerCase() == nq ||
            bNormHarekeli.toLowerCase() == nq;
        if (aNormExact != bNormExact) return aNormExact ? -1 : 1;
        if (aNormExact && bNormExact) {
          // 2.1 Baz formu öne al: harekeliKelime'nin normalize hali sorguya tam eşitse tercih et
          final aHarekeliNormEq = aNormHarekeli.toLowerCase() == nq;
          final bHarekeliNormEq = bNormHarekeli.toLowerCase() == nq;
          if (aHarekeliNormEq != bHarekeliNormEq)
            return aHarekeliNormEq ? -1 : 1;

          // 2.2 Prefiks cezası: harekeliKelime başında parçacık varsa (س, سوف, و, ل) cezalandır
          final aPref = _getArabicPrefixPenalty(a.harekeliKelime ?? '');
          final bPref = _getArabicPrefixPenalty(b.harekeliKelime ?? '');
          if (aPref != bPref) return aPref.compareTo(bPref);

          // 2.3 Uzunluk yakınlığı - baz formu öne al
          final aLen = [
            aNormKelime.length,
            aNormHarekeli.length,
          ].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
          final bLen = [
            bNormKelime.length,
            bNormHarekeli.length,
          ].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
          final qLen = nq.length;
          final aDist = (aLen - qLen).abs();
          final bDist = (bLen - qLen).abs();
          if (aDist != bDist) return aDist.compareTo(bDist);
        }

        // 3) Harekeli başlangıç eşleşmesi
        final aStarts =
            a.kelime.startsWith(originalQuery) ||
            (a.harekeliKelime ?? '').startsWith(originalQuery);
        final bStarts =
            b.kelime.startsWith(originalQuery) ||
            (b.harekeliKelime ?? '').startsWith(originalQuery);
        if (aStarts != bStarts) return aStarts ? -1 : 1;

        // 4) Normalize başlangıç ve 5) Normalize içinde geçme
        final aNormStarts =
            aNormKelime.toLowerCase().startsWith(nq) ||
            aNormHarekeli.toLowerCase().startsWith(nq);
        final bNormStarts =
            bNormKelime.toLowerCase().startsWith(nq) ||
            bNormHarekeli.toLowerCase().startsWith(nq);
        if (aNormStarts != bNormStarts) return aNormStarts ? -1 : 1;
        final aNormCont =
            aNormKelime.toLowerCase().contains(nq) ||
            aNormHarekeli.toLowerCase().contains(nq);
        final bNormCont =
            bNormKelime.toLowerCase().contains(nq) ||
            bNormHarekeli.toLowerCase().contains(nq);
        if (aNormCont != bNormCont) return aNormCont ? -1 : 1;
      } else {
        // Harekesiz: normalize ederek tam eşleşme
        final nq = normalizedQuery.toLowerCase();
        final aExact =
            aNormKelime.toLowerCase() == nq ||
            aNormHarekeli.toLowerCase() == nq;
        final bExact =
            bNormKelime.toLowerCase() == nq ||
            bNormHarekeli.toLowerCase() == nq;
        if (aExact != bExact) return aExact ? -1 : 1;
        // Her ikisi de normalize tam eşleşmeyse: sorgu uzunluğuna en yakın olanı (tercihen eşit) önce gelsin
        if (aExact && bExact) {
          final aLen = [
            aNormKelime.length,
            aNormHarekeli.length,
          ].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
          final bLen = [
            bNormKelime.length,
            bNormHarekeli.length,
          ].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
          final qLen = nq.length;
          final aDist = (aLen - qLen).abs();
          final bDist = (bLen - qLen).abs();
          if (aDist != bDist)
            return aDist.compareTo(
              bDist,
            ); // tam eşleşmeye en yakın uzunluk (0 en iyi)
        }
        // Başlangıç (normalize)
        final aStarts =
            aNormKelime.toLowerCase().startsWith(nq) ||
            aNormHarekeli.toLowerCase().startsWith(nq);
        final bStarts =
            bNormKelime.toLowerCase().startsWith(nq) ||
            bNormHarekeli.toLowerCase().startsWith(nq);
        if (aStarts != bStarts) return aStarts ? -1 : 1;
        // İçinde geçiyor (normalize)
        final aCont =
            aNormKelime.toLowerCase().contains(nq) ||
            aNormHarekeli.toLowerCase().contains(nq);
        final bCont =
            bNormKelime.toLowerCase().contains(nq) ||
            bNormHarekeli.toLowerCase().contains(nq);
        if (aCont != bCont) return aCont ? -1 : 1;
      }
      // Eşitlikte kısa kelimeyi öne al
      final aMinLength = [
        aNormKelime.length,
        aNormHarekeli.length,
      ].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
      final bMinLength = [
        bNormKelime.length,
        bNormHarekeli.length,
      ].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
      if (aMinLength != bMinLength) return aMinLength.compareTo(bMinLength);
      // Son çare: anlam uzunluğu
      return aAnlam.length.compareTo(bAnlam.length);
    }

    // ============= 1. TÜRKÇE ANLAM KONTROLÜ ============= (Türkçe veya Latin sorgular için)

    // ANLAM POZISYONU ÖNCELİĞİ - ilk anlamda tam eşleşme en önce, 2. anlam sonra...
    // _getMeaningPosition değerleri:
    // - Tam eşleşme ilk anlam: 0, ikinci anlam: 1, üçüncü anlam: 2...
    // - Başlangıç eşleşmesi: 100
    // - Kelime başı eşleşmesi: 200+
    // - Eşleşme yok: 999
    final aMeaningPos = _getMeaningPosition(aAnlam, lowerTurkishQuery);
    final bMeaningPos = _getMeaningPosition(bAnlam, lowerTurkishQuery);
    if (aMeaningPos != bMeaningPos) return aMeaningPos.compareTo(bMeaningPos);

    // TÜRKÇE İÇİN İÇİNDE GEÇME KALDIRILDI - Sadece başlangıç eşleşmeleri!

    // ============= 2. LATİN SORGU İÇİN ARAPÇA TAHMİN ÖNCELİĞİ =============
    // Latin sorgularda, Türkçe anlam önceliğinden SONRA Arapça tahminle (guess) kelime eşleşmelerini ele al
    if (!isArabicQuery && originalQuery.trim().length <= 3) {
      final guess = _latinToArabicGuess(originalQuery).toLowerCase();
      if (guess.isNotEmpty) {
        // Ön Kural: Arapça yazımı olan kelimeleri öncele
        bool aHasArabic =
            _hasOnlyArabicCharacters(a.kelime) ||
            _hasOnlyArabicCharacters(a.harekeliKelime ?? '');
        bool bHasArabic =
            _hasOnlyArabicCharacters(b.kelime) ||
            _hasOnlyArabicCharacters(b.harekeliKelime ?? '');
        if (aHasArabic != bHasArabic) return aHasArabic ? -1 : 1;

        final aExactGuess =
            aNormKelime.toLowerCase() == guess ||
            aNormHarekeli.toLowerCase() == guess;
        final bExactGuess =
            bNormKelime.toLowerCase() == guess ||
            bNormHarekeli.toLowerCase() == guess;
        if (aExactGuess != bExactGuess) return aExactGuess ? -1 : 1;
        if (aExactGuess && bExactGuess) {
          // Uzunluk yakınlığı - baz formu öne al
          final aLen = [
            aNormKelime.length,
            aNormHarekeli.length,
          ].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
          final bLen = [
            bNormKelime.length,
            bNormHarekeli.length,
          ].where((l) => l > 0).fold(999, (p, c) => p < c ? p : c);
          final qLen = guess.length;
          final aDist = (aLen - qLen).abs();
          final bDist = (bLen - qLen).abs();
          if (aDist != bDist) return aDist.compareTo(bDist);
        }

        final aStartsGuess =
            aNormKelime.toLowerCase().startsWith(guess) ||
            aNormHarekeli.toLowerCase().startsWith(guess);
        final bStartsGuess =
            bNormKelime.toLowerCase().startsWith(guess) ||
            bNormHarekeli.toLowerCase().startsWith(guess);
        if (aStartsGuess != bStartsGuess) return aStartsGuess ? -1 : 1;

        final aContGuess =
            aNormKelime.toLowerCase().contains(guess) ||
            aNormHarekeli.toLowerCase().contains(guess);
        final bContGuess =
            bNormKelime.toLowerCase().contains(guess) ||
            bNormHarekeli.toLowerCase().contains(guess);
        if (aContGuess != bContGuess) return aContGuess ? -1 : 1;
      }
    }

    // ============= 2. ARAPÇA KELİME KONTROLÜ =============

    if (queryHasDiacritics) {
      // Harekeli arama - tam eşleşme öncelikli
      final aExactMatch =
          a.kelime == originalQuery || a.harekeliKelime == originalQuery;
      final bExactMatch =
          b.kelime == originalQuery || b.harekeliKelime == originalQuery;

      if (aExactMatch && !bExactMatch) return -1;
      if (bExactMatch && !aExactMatch) return 1;

      // Başlangıç eşleşmesi
      final aStartsWith =
          a.kelime.startsWith(originalQuery) ||
          (a.harekeliKelime ?? '').startsWith(originalQuery);
      final bStartsWith =
          b.kelime.startsWith(originalQuery) ||
          (b.harekeliKelime ?? '').startsWith(originalQuery);

      if (aStartsWith && !bStartsWith) return -1;
      if (bStartsWith && !aStartsWith) return 1;
    } else {
      // Harekesiz arama için normalize ederek karşılaştır
      final nqLower = normalizedQuery.toLowerCase();

      // 2a. TAM KELİME EŞLEŞMESI
      final aExactMatch =
          aNormKelime.toLowerCase() == nqLower ||
          aNormHarekeli.toLowerCase() == nqLower;
      final bExactMatch =
          bNormKelime.toLowerCase() == nqLower ||
          bNormHarekeli.toLowerCase() == nqLower;

      if (aExactMatch && !bExactMatch) return -1;
      if (bExactMatch && !aExactMatch) return 1;

      // 2b. KÖK EŞLEŞMESI - harfler sıralı olarak geçiyor mu? (normalized)
      final aRootMatch =
          nqLower.length >= 2 &&
          (_hasSequentialLetters(aNormKelime.toLowerCase(), nqLower) ||
              _hasSequentialLetters(aNormHarekeli.toLowerCase(), nqLower));
      final bRootMatch =
          nqLower.length >= 2 &&
          (_hasSequentialLetters(bNormKelime.toLowerCase(), nqLower) ||
              _hasSequentialLetters(bNormHarekeli.toLowerCase(), nqLower));

      if (aRootMatch && !bRootMatch) return -1;
      if (bRootMatch && !aRootMatch) return 1;

      // 2c. KELİME BAŞLANGICI
      final aStartsWith =
          aNormKelime.toLowerCase().startsWith(nqLower) ||
          aNormHarekeli.toLowerCase().startsWith(nqLower);
      final bStartsWith =
          bNormKelime.toLowerCase().startsWith(nqLower) ||
          bNormHarekeli.toLowerCase().startsWith(nqLower);

      if (aStartsWith && !bStartsWith) return -1;
      if (bStartsWith && !aStartsWith) return 1;

      // 2d. KELİME İÇİNDE GEÇİYOR (DOĞRUDAN SUBSTRING)
      final aContains =
          aNormKelime.toLowerCase().contains(nqLower) ||
          aNormHarekeli.toLowerCase().contains(nqLower);
      final bContains =
          bNormKelime.toLowerCase().contains(nqLower) ||
          bNormHarekeli.toLowerCase().contains(nqLower);

      if (aContains && !bContains) return -1;
      if (bContains && !aContains) return 1;
    }

    // ============= 3. KELIME UZUNLUĞU (KISA KELİMELER DAHA ÖNCELİKLİ) =============
    final aMinLength = [
      aNormKelime.length,
      aNormHarekeli.length,
    ].where((l) => l > 0).fold(999, (prev, curr) => prev < curr ? prev : curr);
    final bMinLength = [
      bNormKelime.length,
      bNormHarekeli.length,
    ].where((l) => l > 0).fold(999, (prev, curr) => prev < curr ? prev : curr);

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

    return meaningList.any(
      (meaning) => meaning.startsWith(query) && meaning != query,
    );
  }

  /// Anlam içinde geçme kontrolü - "katıl" aradığında "iştirak, katılım" olan kelimeler
  bool _hasMeaningContains(String meanings, String query) {
    if (meanings.isEmpty || query.isEmpty) return false;

    final meaningList = meanings
        .split(RegExp(r'[,;.\n]'))
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();

    return meaningList.any(
      (meaning) =>
          meaning.contains(query) &&
          !meaning.startsWith(query) &&
          meaning != query,
    );
  }

  /// Arapça fiillerde geleceğe / bağlaçlara işaret eden önekler için küçük ceza
  /// "سوف" başlarsa 2, "س" veya "و" veya "ل" ile başlarsa 1, diğer tüm durumlarda 0 döner
  int _getArabicPrefixPenalty(String s) {
    if (s.isEmpty) return 0;
    final trimmed = _removeArabicDiacritics(s);
    if (trimmed.startsWith('سوف')) return 2;
    if (trimmed.startsWith('س') ||
        trimmed.startsWith('و') ||
        trimmed.startsWith('ل'))
      return 1;
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

class SearchIsolateWorker {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _readyCompleter = Completer<void>();
  bool _isInitialized = false;
  bool _hasError = false;

  bool get isReady => _isInitialized && !_hasError;

  Future<void> start() async {
    if (_isInitialized || _hasError) return;
    try {
      final receivePort = ReceivePort();
      _isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);
      
      // Wait for the first message, which is the worker's SendPort
      final firstMessage = await receivePort.first;
      _sendPort = firstMessage as SendPort;
      _isInitialized = true;
      _readyCompleter.complete();
    } catch (e) {
      debugPrint('❌ SearchIsolateWorker failed to start: $e');
      _hasError = true;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }
  }

  Future<List<Map<String, dynamic>>> search(Map<String, dynamic> args) async {
    if (!_isInitialized && !_hasError) {
      await _readyCompleter.future;
    }
    if (_hasError || _sendPort == null) {
      // Fallback to synchronous search on the main thread
      return DatabaseService._runIsolateSearch(args);
    }
    final responsePort = ReceivePort();
    _sendPort!.send({
      'args': args,
      'replyPort': responsePort.sendPort,
    });
    final response = await responsePort.first;
    responsePort.close();
    return (response as List).cast<Map<String, dynamic>>();
  }

  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    // Build cache inside the background isolate!
    DatabaseService._buildCache();

    receivePort.listen((message) {
      final msg = message as Map<String, dynamic>;
      final args = msg['args'] as Map<String, dynamic>;
      final replyPort = msg['replyPort'] as SendPort;

      final results = DatabaseService._runIsolateSearch(args);
      replyPort.send(results);
    });
  }

  void stop() {
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _sendPort = null;
    _isInitialized = false;
  }
}
