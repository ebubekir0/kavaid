// kavaid/lib/services/database_service.dart

import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word_model.dart';
import '../data/embedded_words.dart';

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
  kelime $idType, harekeliKelime $textType, anlam $textType, koku $textType, dilbilgiselOzellikler $textType, ornekCumleler $textType, fiilCekimler $textType, eklenmeTarihi $intType
)''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS pending_ai_words ( 
  kelime $idType, harekeliKelime $textType, anlam $textType, koku $textType, dilbilgiselOzellikler $textType, ornekCumleler $textType, fiilCekimler $textType, eklenmeTarihi $intType
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
      if (word.ornekCumleler!.isNotEmpty) {
        ornekCumlelerData = json.encode(word.ornekCumleler);
      }
      // Eğer başka bir format ise (örn: Ornek objesi) Map'e çevir
      else {
        ornekCumlelerData = json.encode(
          word.ornekCumleler!.map((e) {
            return {
              'arapcaCumle': e['arapcaCumle'] ?? '',
              'turkceCeviri': e['turkceCeviri'] ?? '',
            };
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
  static Future<void>? _prewarmFuture;

  // Bellek içi arama için sözlük verisi. Her izolenin kendi kopyası vardır:
  // arama izolesi başlarken asset'ten çözer; ana izolede yalnızca izole
  // başlatılamazsa (yedek yol) yüklenir.
  static List<Map<String, dynamic>>? _words;

  static final SearchIsolateWorker _worker = SearchIsolateWorker();

  static bool get isSearchCacheReady => kIsWeb ? true : _worker.isReady;

  static Future<void> ensureSearchCacheReady() async {
    if (kIsWeb) return;
    await _worker.start();
  }

  static void _buildCache() {
    if (_normalizedHKCache != null) return;
    final words = _words;
    if (words == null) return;
    final kList = <String>[];
    final hkList = <String>[];
    final rootList = <String>[];
    final mList = <int, String>{};

    for (int i = 0; i < words.length; i++) {
      final map = words[i];
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
    final words = _words ??= await EmbeddedWords.load();
    final kList = <String>[];
    final hkList = <String>[];
    final rootList = <String>[];
    final mList = <int, String>{};

    for (int i = 0; i < words.length; i++) {
      final map = words[i];
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
    _prewarmFuture = _buildCacheIncrementally().whenComplete(() {
      _prewarmFuture = null;
    });
    return _prewarmFuture;
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

  // ─── RAM'de arama (Isolate-safe, bu izoledeki _words'ü okur) ──────────────
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
    final words = _words;
    if (words == null || _normalizedHKCache == null) {
      return <Map<String, dynamic>>[];
    }
    final kCache = _normalizedKelimeCache!;
    final hkCache = _normalizedHKCache!;
    final rootCache = _normalizedRootCache!;
    final mCache = _meaningCache!;

    // Sonuçlar: [rank, sec, index]
    final results = <({int rank, int sec, int idx})>[];

    for (int i = 0; i < words.length; i++) {
      final map = words[i];
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
            if (m.isEmpty || !m.contains(turkQuery)) {
              continue; // hızlı eleman skiple
            }
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
      final m = Map<String, dynamic>.from(words[r.idx]);
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
          hk.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length > 2) {
        continue;
      }
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

      debugPrint(
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

      debugPrint(
        '🗑️ Latin harf içeren kelime silindi: "$kelime" / "$harekeliKelime"',
      );
    }

    return deletedCount;
  }

  /// Tam veritabanı temizliği yap
  Future<Map<String, int>> performDatabaseCleanup() async {
    if (kIsWeb) return {};

    debugPrint('🧹 Veritabanı temizliği başlatılıyor...');

    final duplicatesDeleted = await cleanDuplicateHarekeliWords();
    final latinDeleted = await cleanWordsWithLatinInArabic();

    final totalWords = await getWordsCount();

    debugPrint('✅ Veritabanı temizliği tamamlandı!');
    debugPrint('   - Duplicate silinen: $duplicatesDeleted');
    debugPrint('   - Latin harf silinen: $latinDeleted');
    debugPrint('   - Kalan toplam: $totalWords');

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

class SearchIsolateWorker {
  static const _cacheReadyMessage = 'cache_ready';
  static const _cacheErrorMessage = 'cache_error';

  Isolate? _isolate;
  SendPort? _sendPort;
  // İzole sözlük verisini çözüp arama cache'ini kurunca tamamlanır.
  final _cacheReadyCompleter = Completer<void>();
  Future<void>? _startFuture;
  bool _isInitialized = false;
  bool _hasError = false;

  bool get isReady => _isInitialized && !_hasError;

  /// Birden çok kez çağrılabilir; izole yalnızca bir kez başlatılır.
  /// (Eskiden başlangıçtaki zaman aşımı sonrası ikinci çağrı ikinci bir
  /// izole açıyor ve arama yanlışlıkla yedek yola düşüyordu.)
  Future<void> start() => _startFuture ??= _start();

  Future<void> _start() async {
    try {
      // Sıkıştırılmış veri ana izolede okunur (rootBundle burada çalışır),
      // çözme ve normalize etme işi arama izolesinde yapılır.
      final compressed = await EmbeddedWords.loadCompressed();
      final receivePort = ReceivePort();
      final sendPortCompleter = Completer<SendPort>();
      receivePort.listen((message) {
        if (message is SendPort) {
          if (!sendPortCompleter.isCompleted) sendPortCompleter.complete(message);
        } else if (message == _cacheReadyMessage) {
          if (!_cacheReadyCompleter.isCompleted) _cacheReadyCompleter.complete();
          receivePort.close();
        } else if (message == _cacheErrorMessage) {
          debugPrint('❌ SearchIsolateWorker: sözlük verisi çözülemedi');
          _markFailed();
          receivePort.close();
        }
      });
      _isolate = await Isolate.spawn(_isolateEntry, <Object>[
        receivePort.sendPort,
        TransferableTypedData.fromList([compressed]),
      ]).timeout(const Duration(seconds: 4));
      // ANR: isolate başlamazsa (düşük RAM) sonsuza kadar bekleme.
      _sendPort = await sendPortCompleter.future.timeout(
        const Duration(seconds: 4),
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ SearchIsolateWorker failed to start: $e');
      _markFailed();
    }
  }

  void _markFailed() {
    _hasError = true;
    _sendPort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    if (!_cacheReadyCompleter.isCompleted) _cacheReadyCompleter.complete();
  }

  Future<List<Map<String, dynamic>>> search(Map<String, dynamic> args) async {
    if (!_isInitialized && !_hasError) {
      // ANR: isolate hazır değilken sonsuza kadar bekleme.
      try {
        await start().timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
    if (!_hasError && _sendPort != null && !_cacheReadyCompleter.isCompleted) {
      // İlk aramalar: izole veriyi çözerken "sonuç yok" göstermek yerine
      // cache hazır olana kadar bekle (düşük cihazlarda birkaç saniye).
      try {
        await _cacheReadyCompleter.future.timeout(const Duration(seconds: 15));
      } catch (_) {}
    }
    if (_hasError || _sendPort == null) {
      // ANR: Eski yol UI thread'inde senkron _runIsolateSearch çağırıyordu;
      // o da _buildCache() ile 55K kelimeyi senkron normalize ediyordu
      // (tek seferde 5sn+ blok, "Input dispatching timed out").
      // Artık: UI thread'inde cache senkron kurulmaz. Kurulum arka planda
      // parçalı (zaman aralıklı) yapılır, bu arama boş döner.
      if (DatabaseService._normalizedHKCache == null) {
        unawaited(DatabaseService.prewarmCache());
        debugPrint('⚠️ [Search] Isolate yok, cache arka planda kuruluyor');
        return <Map<String, dynamic>>[];
      }
      // Cache zaten kuruluysa senkron arama makul (10-30ms).
      return DatabaseService._runIsolateSearch(args);
    }
    final responsePort = ReceivePort();
    _sendPort!.send({
      'args': args,
      'replyPort': responsePort.sendPort,
    });
    // ANR: isolate cevap vermezse UI await'te takılı kalmasın, boş dön.
    try {
      final response = await responsePort.first.timeout(
        const Duration(seconds: 4),
      );
      responsePort.close();
      return (response as List).cast<Map<String, dynamic>>();
    } catch (_) {
      responsePort.close();
      return <Map<String, dynamic>>[];
    }
  }

  static void _isolateEntry(List<Object> init) {
    final sendPort = init[0] as SendPort;
    final compressed = init[1] as TransferableTypedData;
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    // Sözlüğü bu izolede çöz ve arama cache'ini kur. Gelen aramalar
    // bu iş bitene kadar kuyrukta bekler.
    try {
      DatabaseService._words = EmbeddedWords.decode(
        compressed.materialize().asUint8List(),
      );
      DatabaseService._buildCache();
      sendPort.send(_cacheReadyMessage);
    } catch (_) {
      sendPort.send(_cacheErrorMessage);
      return;
    }

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
