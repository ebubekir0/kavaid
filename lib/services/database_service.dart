// kavaid/lib/services/database_service.dart

import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word_model.dart';
import '../data/embedded_words.dart';
import '../utils/perf_log.dart';
import 'search_ranking.dart';
import 'search_store.dart';

export 'search_ranking.dart' show RankedWord, WordMatchType;

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
    _pendingWordsCache = null;
  }

  Future<int> getPendingAiWordsCount() async {
    if (kIsWeb) return 0;
    final db = await instance.database;
    if (db == null) return 0;
    final result = await db.rawQuery('SELECT COUNT(*) FROM pending_ai_words');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Anlamın harfi cer bölümü (|| sonrası) hariç ana kısmı.
  static String _mainMeaning(String? anlam) => SearchStore.mainMeaningOf(anlam);

  // Arama fihristi (normalize edilmiş hâller, yaygınlık) ve kayıtlara erişim.
  // Arama izolesi sözlük sürümü değişince bir kez kurup telefona yazar, sonra
  // her açılışta yalnız fihristi okur (search_store.dart). Ana izolede yalnızca
  // izole başlatılamazsa (yedek yol) bellekte kurulur.
  static SearchStore? _store;
  static Future<void>? _prewarmFuture;

  static SearchIsolateWorker _worker = SearchIsolateWorker();

  static bool get isSearchCacheReady => kIsWeb ? true : _worker.isReady;

  static Future<void> ensureSearchCacheReady() async {
    if (kIsWeb) return;
    await _worker.start();
  }

  /// İlk kurulum ve sözlük güncellemesi: arama izolesini, fihristi veritabanı için
  /// çözülen kelime listesinden kuracak şekilde başlatır; listenin gönderileceği
  /// portu döndürür (sözlük bir kez çözülür). Fihrist zaten varsa ya da izole başka
  /// yoldan başlamışsa null.
  static Future<SendPort?> searchWordsPort() async {
    if (kIsWeb) return null;
    await _worker.start(awaitWords: true);
    return _worker.wordsPort;
  }

  /// Yedek yol (izole başlatılamadı): fihristi ana izolede, arayüzü
  /// dondurmadan parça parça kurar.
  static Future<void> prewarmCache() async {
    if (_store != null) return;
    if (_prewarmFuture != null) return _prewarmFuture;
    _prewarmFuture = () async {
      _store = await SearchStore.buildInMemory(await EmbeddedWords.load());
    }().whenComplete(() {
      _prewarmFuture = null;
    });
    return _prewarmFuture;
  }

  // ─── Fihristte arama (Isolate-safe, bu izoledeki _store'u okur) ──────────
  static List<Map<String, dynamic>> _runIsolateSearch(
    Map<String, dynamic> args,
  ) {
    final query = SearchQuery.fromMap(args);

    final store = _store;
    if (store == null || query.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final kCache = store.nKelime;
    final hkCache = store.nHarekeli;
    final rootCache = store.nKoku;
    final mCache = store.meanings;
    final popularity = store.popularity;
    final guess = query.arabicGuess;
    final alt = query.latinAlt;

    final results = <({int rank, int sec, int idx, WordMatchType type})>[];

    for (int i = 0; i < store.length; i++) {
      final nK = kCache[i];
      final nHK = hkCache[i];
      final nRoot = rootCache[i];
      final meanings = mCache[i];

      // ⚡ Hızlı ön-filtre: sorguyla hiçbir şekilde eşleşemeyecek kayıtlar
      // detaylı puanlamaya hiç girmez. Arapçada eşleşme ancak yazımda geçen
      // ya da kökü aynı olan kayıtlarda mümkün; Türkçede anlamda sorgu
      // (veya mastarın geçmiş zaman hali ya da Latin tahmini) geçmeli.
      if (query.isArabic) {
        final q = query.arabic;
        if (!nHK.contains(q) &&
            !nK.contains(q) &&
            nRoot != q &&
            !meanings.contains(q)) {
          continue;
        }
      } else if (!_meaningMayMatch(meanings, query) &&
          !(alt.isNotEmpty && meanings.contains(alt)) &&
          !(guess.isNotEmpty &&
              (nHK.contains(guess) ||
                  nK.contains(guess) ||
                  nRoot.contains(guess)))) {
        continue;
      }

      final r = rankEntry(
        query: query,
        kelime: store.kelime[i],
        harekeli: store.harekeli[i],
        koku: store.koku[i],
        nKelime: nK,
        nHarekeli: nHK,
        nKoku: nRoot,
        meanings: meanings,
        rawMeaning: query.isArabic ? '' : store.mainMeaning[i],
        popularity: popularity[i],
        imperative: store.imperative[i],
      );
      if (r == null) continue;
      if (query.isArabic && r.rank >= 6 && results.length >= 360) continue;
      results.add((rank: r.rank, sec: r.sec, idx: i, type: r.type));
    }

    // Türkçe aramada "anlam ailesi": her kökten bu aramayla eşleşen kayıt
    // sayısı. "gitmek" için ذهب kökünden pek çok kayıt eşleşir (ذَهَبَ,
    // تَذْهَبْ "gidiyorsun", لِيَذْهَبْ "gitsin"), روح kökünden birkaç tane;
    // aynı puandaki sonuçlarda ailesi büyük olan (daha yaygın anlam) öne gelir.
    final family = <String, int>{};
    if (!query.isArabic) {
      for (final r in results) {
        final root = rootCache[r.idx];
        if (root.isEmpty) continue;
        final key = root.replaceAll(' ', '');
        family[key] = (family[key] ?? 0) + 1;
      }
    }
    int familyOf(int idx) {
      final root = rootCache[idx];
      return root.isEmpty ? 0 : family[root.replaceAll(' ', '')] ?? 0;
    }

    // Önce puan, sonra anlam ailesi, sonra ikincil ölçüt; eşitlikte sözlük
    // sırası (kararlı sonuç).
    results.sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      if (byRank != 0) return byRank;
      if (family.isNotEmpty) {
        final byFamily = familyOf(b.idx).compareTo(familyOf(a.idx));
        if (byFamily != 0) return byFamily;
      }
      final bySec = a.sec.compareTo(b.sec);
      return bySec != 0 ? bySec : a.idx.compareTo(b.idx);
    });

    // UI jank'ini azaltmak için ilk 120 sonuçla sınırlı tutuluyor.
    return results.take(120).map((r) {
      final m = store.record(r.idx);
      m['rank'] = r.rank;
      m['sec'] = r.sec;
      m['fam'] = familyOf(r.idx);
      m['matchType'] = r.type.index;
      return m;
    }).toList();
  }

  /// Ön eleme: kısa Türkçe sorguda yalnızca anlamın başında (tek harf) ya
  /// da bir kelimenin başında (iki harf) geçen kayıtlar puanlamaya girer.
  static bool _meaningMayMatch(String meanings, SearchQuery query) {
    final q = query.latin;
    switch (query.maxMeaningTier) {
      case 2:
        return _hasPartStartingWith(meanings, q);
      case 4:
        return _hasWordStartingWith(meanings, q);
      default:
        return meanings.contains(q);
    }
  }

  /// Virgül/noktalı virgülle ayrılmış anlamlardan biri [token] ile mi
  /// başlıyor?
  static bool _hasPartStartingWith(String text, String token) {
    var from = 0;
    while (true) {
      final at = text.indexOf(token, from);
      if (at < 0) return false;
      var i = at - 1;
      while (i >= 0 && text.codeUnitAt(i) == 0x20) {
        i--;
      }
      if (i < 0 || text[i] == ',' || text[i] == ';') return true;
      from = at + 1;
    }
  }

  /// Metindeki bir kelime [token] ile mi başlıyor? ([foldLatin] çıktısında
  /// kelime harfleri a-z ve 0-9.)
  static bool _hasWordStartingWith(String text, String token) {
    var from = 0;
    while (true) {
      final at = text.indexOf(token, from);
      if (at < 0) return false;
      if (at == 0 || !_isWordUnit(text.codeUnitAt(at - 1))) return true;
      from = at + 1;
    }
  }

  static bool _isWordUnit(int c) =>
      (c >= 0x61 && c <= 0x7A) || (c >= 0x30 && c <= 0x39);

  // Kullanıcının AI ile bulduğu kelimeler (pending_ai_words). Küçük bir tablo;
  // her tuş vuruşunda SQLite'a gitmemek için bellekte tutulur.
  static List<Map<String, dynamic>>? _pendingWordsCache;

  Future<List<Map<String, dynamic>>> _loadPendingWords() async {
    final cached = _pendingWordsCache;
    if (cached != null) return cached;
    final db = await instance.database;
    if (db == null) return const [];
    return _pendingWordsCache = await db.query('pending_ai_words');
  }

  static final RegExp _whitespaceRx = RegExp(r'\s+');

  /// Sözlükte arar; sonuçları eşleşme türleriyle birlikte, en iyi eşleşme
  /// başta olacak şekilde döndürür. Türkçe karakter (guzel/güzel) ve Arapça
  /// yazım farkları (hemze, ة/ه, uzatma çizgisi) sonucu değiştirmez.
  Future<List<RankedWord>> searchWordsRanked(String input) async {
    if (kIsWeb) return [];
    final raw = input.trim();
    if (raw.isEmpty) return [];
    final query = SearchQuery.parse(
      raw,
      arabicGuess: containsArabic(raw) ? '' : _latinToArabicGuess(raw),
    );
    if (query.isEmpty) return [];
    final sw = Stopwatch()..start();

    // UI frame'inin render edilmesine fırsat ver, sonra aramayı yap.
    await Future.delayed(Duration.zero);

    final candidates =
        <
          ({
            Map<String, dynamic> map,
            int rank,
            int fam,
            int sec,
            int order,
            WordMatchType type,
          })
        >[];

    // Ana arama: arka plan izolesinde, önceden normalize edilmiş sözlükte.
    final mainResults = await _worker.search(query.toMap());
    for (var i = 0; i < mainResults.length; i++) {
      final m = mainResults[i];
      candidates.add((
        map: m,
        rank: m['rank'] as int,
        fam: m['fam'] as int? ?? 0,
        sec: m['sec'] as int,
        order: i,
        type: WordMatchType.values[m['matchType'] as int],
      ));
    }

    // AI ile bulunan kelimeler aynı kurallarla puanlanıp sonuçlara katılır.
    try {
      final pending = await _loadPendingWords();
      for (var i = 0; i < pending.length; i++) {
        final p = pending[i];
        final kelime = p['kelime'] as String? ?? '';
        final harekeli = p['harekeliKelime'] as String? ?? '';
        final koku = p['koku'] as String? ?? '';
        final mainMeaning = _mainMeaning(p['anlam'] as String?);
        final r = rankEntry(
          query: query,
          kelime: kelime,
          harekeli: harekeli,
          koku: koku,
          nKelime: normalizeArabic(kelime),
          nHarekeli: normalizeArabic(harekeli),
          nKoku: normalizeArabic(koku),
          meanings: normalizeMeaning(mainMeaning),
          rawMeaning: mainMeaning,
        );
        if (r == null) continue;
        candidates.add((
          map: p,
          rank: r.rank,
          fam: 0,
          sec: r.sec,
          order: mainResults.length + i,
          type: r.type,
        ));
      }
    } catch (_) {}

    // Aynı sırayla: puan, anlam ailesi (izolede hesaplanır), ikincil ölçüt.
    candidates.sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      if (byRank != 0) return byRank;
      final byFamily = b.fam.compareTo(a.fam);
      if (byFamily != 0) return byFamily;
      final bySec = a.sec.compareTo(b.sec);
      return bySec != 0 ? bySec : a.order.compareTo(b.order);
    });

    // Uzun ifadeleri (örnek cümleler) çıkar ve aynı kelimeyi tekrar gösterme
    final seen = <String>{};
    final results = <RankedWord>[];
    for (final c in candidates) {
      final hk = (c.map['harekeliKelime'] as String? ?? '').trim();
      if (hk.isNotEmpty &&
          hk.split(_whitespaceRx).where((p) => p.isNotEmpty).length > 2) {
        continue;
      }
      final dedupeKey = hk.isNotEmpty ? hk : (c.map['kelime'] as String? ?? '');
      if (dedupeKey.isNotEmpty && !seen.add(dedupeKey)) continue;

      results.add(RankedWord(_dbMapToWord(c.map), c.type));
    }

    // Aynı kelimenin kopyaları tek sonuçta: isimlerde hal/takı farkı
    // (بَيْتٌ, الْبَيْتُ), Türkçe aramada ayrıca aynı kökten aynı anlamdaki
    // varyantlar (كَتَبَ / كَتَبَتِ "yazdı").
    final collapsed = collapseVariants(results, turkishQuery: !query.isArabic);
    PerfLog.took('search "$raw" (${collapsed.length})', sw);
    return collapsed;
  }

  /// [searchWordsRanked] sonucundaki kelimeler (eşleşme türü olmadan).
  Future<List<WordModel>> searchWords(String query) async =>
      (await searchWordsRanked(query)).map((r) => r.word).toList();

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
    _pendingWordsCache = null;
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

  /// Harekeli başlığa göre kelimelerin dilbilgisi alanı (Arapça maddesi `arDef` burada).
  Future<Map<String, Map<String, dynamic>>> grammarByHeadwords(Set<String> headwords) async {
    final out = <String, Map<String, dynamic>>{};
    if (kIsWeb || headwords.isEmpty) return out;
    final db = await instance.database;
    if (db == null) return out;
    final list = headwords.toList();
    for (var start = 0; start < list.length; start += 400) {
      final chunk = list.sublist(start, start + 400 < list.length ? start + 400 : list.length);
      final rows = await db.query(
        'words',
        columns: ['harekeliKelime', 'dilbilgiselOzellikler'],
        where: 'harekeliKelime IN (${List.filled(chunk.length, '?').join(',')})',
        whereArgs: chunk,
      );
      for (final r in rows) {
        final raw = r['dilbilgiselOzellikler'];
        if (raw is! String || raw.isEmpty) continue;
        final decoded = json.decode(raw);
        if (decoded is Map) {
          out[r['harekeliKelime'] as String] = Map<String, dynamic>.from(decoded);
        }
      }
    }
    return out;
  }

  /// Sözlük dili değişince: arama izolesini ve fihristi bırakır; bir sonraki
  /// [ensureSearchCacheReady] yeni dilin fihristini kurar.
  static void restartSearch() {
    _worker.stop();
    _store?.close();
    _store = null;
    _pendingWordsCache = null;
    _worker = SearchIsolateWorker();
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
  bool _awaitingWords = false;

  bool get isReady => _isInitialized && !_hasError;

  /// Kelime listesini bekleyen izolenin portu; beklemiyorsa null.
  SendPort? get wordsPort => _awaitingWords && !_hasError ? _sendPort : null;

  /// Birden çok kez çağrılabilir; izole yalnızca bir kez başlatılır.
  /// (Eskiden başlangıçtaki zaman aşımı sonrası ikinci çağrı ikinci bir
  /// izole açıyor ve arama yanlışlıkla yedek yola düşüyordu.)
  /// [awaitWords]: fihrist yoksa sözlüğü kendisi çözmez, [wordsPort]'a gönderilecek
  /// kelime listesini bekler (veritabanı için çözülen veri paylaşılır).
  Future<void> start({bool awaitWords = false}) => _startFuture ??= _start(awaitWords);

  Future<void> _start(bool awaitWords) async {
    try {
      // Fihrist bu sözlük sürümü için telefonda varsa izole yalnız onu okur.
      // Yoksa sıkıştırılmış veri ana izolede okunur (rootBundle burada çalışır);
      // çözme, normalize etme ve dosyaları yazma işi arama izolesinde yapılır.
      final version = await EmbeddedWords.currentVersion();
      String? dir;
      try {
        dir = await getDatabasesPath();
      } catch (_) {
        dir = null; // birim testleri: dosya yok, fihrist bellekte kurulur
      }
      final hasIndex = dir != null && SearchStore.exists(dir, version);
      _awaitingWords = awaitWords && !hasIndex;
      final sources = hasIndex || _awaitingWords
          ? null
          : await EmbeddedWords.loadSources();
      final receivePort = ReceivePort();
      final sendPortCompleter = Completer<SendPort>();
      receivePort.listen((message) {
        if (message is SendPort) {
          if (!sendPortCompleter.isCompleted) {
            sendPortCompleter.complete(message);
          }
        } else if (message == _cacheReadyMessage) {
          PerfLog.mark('searchCacheReady');
          if (!_cacheReadyCompleter.isCompleted) {
            _cacheReadyCompleter.complete();
          }
          receivePort.close();
        } else if (message == _cacheErrorMessage) {
          debugPrint('❌ SearchIsolateWorker: sözlük verisi çözülemedi');
          _markFailed();
          receivePort.close();
        }
      });
      _isolate = await Isolate.spawn(_isolateEntry, <Object?>[
        receivePort.sendPort,
        dir,
        version,
        sources,
        _awaitingWords,
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
      if (DatabaseService._store == null) {
        unawaited(DatabaseService.prewarmCache());
        debugPrint('⚠️ [Search] Isolate yok, cache arka planda kuruluyor');
        return <Map<String, dynamic>>[];
      }
      // Cache zaten kuruluysa senkron arama makul (10-30ms).
      return DatabaseService._runIsolateSearch(args);
    }
    final responsePort = ReceivePort();
    _sendPort!.send({'args': args, 'replyPort': responsePort.sendPort});
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

  static void _isolateEntry(List<Object?> init) {
    final sendPort = init[0] as SendPort;
    final dir = init[1] as String?;
    final version = init[2] as String;
    final sources = init[3] as List<Object?>?;
    final awaitWords = init[4] as bool;
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    // Fihristi telefondaki dosyadan oku; yoksa (ilk açılış, sözlük güncellemesi)
    // sözlüğü çöz ya da veritabanı için çözülen listeyi bekle, fihristi kur ve
    // dosyaları yaz. Gelen aramalar bu iş bitene kadar kuyrukta bekler.
    void prepare(List<Map<String, dynamic>>? words) {
      try {
        var store = dir == null ? null : SearchStore.open(dir, version);
        if (store == null) {
          if (words == null && sources == null) throw StateError('sözlük verisi yok');
          store = SearchStore.build(words ?? EmbeddedWords.decode(sources!), dir: dir, version: version);
        }
        DatabaseService._store = store;
        sendPort.send(_cacheReadyMessage);
      } catch (_) {
        sendPort.send(_cacheErrorMessage);
      }
    }

    if (!awaitWords) prepare(null);

    receivePort.listen((message) {
      // Veritabanı için çözülen kelime listesi (yalnız awaitWords ile, bir kez)
      if (message is List) {
        if (DatabaseService._store == null) {
          prepare(List<Map<String, dynamic>>.from(message));
        }
        return;
      }
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
