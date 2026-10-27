import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart' show XZDecoder;
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_word_model.dart';
import 'search_ranking.dart' show foldLatin, normalizeArabic;

/// CSV satırlarını ayrıştıran yardımcı fonksiyon (tırnak içi virgülleri dikkate alır)
List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  bool inQuotes = false;
  StringBuffer current = StringBuffer();

  for (int i = 0; i < line.length; i++) {
    final ch = line[i];

    if (ch == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        current.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch == ',' && !inQuotes) {
      fields.add(current.toString());
      current = StringBuffer();
    } else {
      current.write(ch);
    }
  }
  fields.add(current.toString());
  return fields;
}

/// Isolate'te CSV ayrıştırma
List<QuranWordModel> _parseCsvInIsolate(String contents) {
  final ls = const LineSplitter();
  final lines = ls.convert(contents);

  final Map<String, QuranWordModel> wordMap = {};

  // İlk satır başlık → atla
  for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final fields = _parseCsvLine(line);
    if (fields.isEmpty || fields[0].trim().isEmpty) continue;

    final word = QuranWordModel.fromCsvRow(fields);

    // Aynı harekeli kelime (birebir aynı) ise listeye ekleme
    if (!wordMap.containsKey(word.kelime)) {
      wordMap[word.kelime] = word;
    }
  }

  return wordMap.values.toList();
}

class QuranDictionaryService {
  static final RegExp _diacriticsRx = RegExp(r'[\u064B-\u065F\u0670\u0653-\u0655]');
  static final RegExp _arabicRx = RegExp(r'[\u0600-\u06FF]');

  static final QuranDictionaryService _instance =
      QuranDictionaryService._internal();
  static QuranDictionaryService get instance => _instance;

  QuranDictionaryService._internal();

  List<QuranWordModel> _allWords = [];
  bool _isLoaded = false;
  bool _isLoading = false;
  Future<void>? _loadingFuture;

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  int get wordCount => _allWords.length;

  // Kuran sözlüğünü kullanmış kullanıcıda açılışta önceden yüklenir;
  // kullanmayanda 17 MB'lık veri boşuna belleğe alınmaz.
  static const _usedKey = 'quran_dictionary_used_v1';

  /// Daha önce kullanıldıysa sözlüğü arka planda hazırlar.
  Future<void> warmUpIfUsed() async {
    if (_isLoaded || _loadingFuture != null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_usedKey) ?? false) await _load();
  }

  /// Servisi başlat ve CSV verisini yükle (kullanıcı Kuran sözlüğünü açtı)
  Future<void> initialize() async {
    if (_isLoaded) return;
    unawaited(
      SharedPreferences.getInstance().then((p) => p.setBool(_usedKey, true)),
    );
    await _load();
  }

  Future<void> _load() async {
    if (_isLoaded) return;
    if (_loadingFuture != null) return _loadingFuture;

    _isLoading = true;
    _loadingFuture = _loadDictionary();

    try {
      await _loadingFuture;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<void> _loadDictionary() async {
    try {
      final String contents = await _loadCsv();

      // Ağır CSV ayrıştırmayı arka plan isolate'te yap
      _allWords = await compute(_parseCsvInIsolate, contents);

      _isLoaded = true;
      debugPrint(
        'QuranDictionaryService: ${_allWords.length} kelime yüklendi (CSV).',
      );
    } catch (e) {
      debugPrint('QuranDictionaryService initialization error: $e');
    } finally {
      _isLoading = false;
    }
  }

  // Uygulamada xz ile sıkıştırılmış (17,6 MB → 1,6 MB). İlk kullanımda bir kez açılıp
  // telefona yazılır; sonraki açılışlarda o dosya okunur. Veri değişirse sürümü artırın.
  static const _csvAsset = 'assets/data/quran_sozluk_okunakli.csv.xz';
  static const _csvFile = 'quran_sozluk_v1.csv';

  Future<String> _loadCsv() async {
    final file = File(join(await getDatabasesPath(), _csvFile));
    if (await file.exists()) {
      try {
        return await file.readAsString();
      } catch (_) {}
    }
    final data = await rootBundle.load(_csvAsset);
    final packed = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final contents = await Isolate.run(() => utf8.decode(XZDecoder().decodeBytes(packed)));
    try {
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(contents, flush: true);
      await tmp.rename(file.path);
    } catch (e) {
      debugPrint('QuranDictionaryService: CSV önbelleğe yazılamadı: $e');
    }
    return contents;
  }

  /// Arapça harekelerini kaldır
  String removeArabicDiacritics(String text) {
    return text.replaceAll(_diacriticsRx, '');
  }

  /// Kelime ara (kelime + kök + anlam üzerinden)
  Future<List<QuranWordModel>> searchWords(String query) async {
    if (!_isLoaded) await initialize();

    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final hasArabic = _arabicRx.hasMatch(cleanQuery);
    // Kelimelerle aynı normalleştirme: elif/hemze ve Türkçe karakter farkı
    // aramayı engellemez.
    final normalizedQuery = hasArabic
        ? normalizeArabic(cleanQuery)
        : foldLatin(cleanQuery);
    if (normalizedQuery.isEmpty) return [];

    final exact = <QuranWordModel>[];
    final startsWith = <QuranWordModel>[];
    final contains = <QuranWordModel>[];
    final rootMatch = <QuranWordModel>[];
    final meaningMatch = <QuranWordModel>[];

    for (final word in _allWords) {
      if (hasArabic) {
        // Arapça arama
        final normKelime = word.normalizedKelime;
        final normKok = word.normalizedKok;

        if (normKelime == normalizedQuery) {
          exact.add(word);
        } else if (normKelime.startsWith(normalizedQuery)) {
          startsWith.add(word);
        } else if (normKok == normalizedQuery) {
          rootMatch.add(word);
        } else if (normKelime.contains(normalizedQuery)) {
          contains.add(word);
        }
      } else {
        // Türkçe/Latin arama → anlam üzerinden
        final anlam = word.normalizedAnlamlar;
        final kok = word.normalizedKok;

        if (anlam == normalizedQuery) {
          exact.add(word);
        } else if (anlam.startsWith(normalizedQuery)) {
          startsWith.add(word);
        } else if (kok == normalizedQuery) {
          rootMatch.add(word);
        } else if (anlam.contains(normalizedQuery)) {
          meaningMatch.add(word);
        }
      }

      // Performans: max 100 sonuç
      final total =
          exact.length +
          startsWith.length +
          rootMatch.length +
          contains.length +
          meaningMatch.length;
      if (total >= 100) break;
    }

    return [
      ...exact,
      ...startsWith,
      ...rootMatch,
      ...contains,
      ...meaningMatch,
    ];
  }

  /// Rastgele kelimeler getir (öneri için)
  List<QuranWordModel> getRandomWords(int count) {
    if (!_isLoaded || _allWords.isEmpty) return [];
    final shuffled = List<QuranWordModel>.from(_allWords)..shuffle();
    return shuffled.take(count).toList();
  }
}
