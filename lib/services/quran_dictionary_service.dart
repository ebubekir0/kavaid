import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/quran_word_model.dart';

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
  static final QuranDictionaryService _instance =
      QuranDictionaryService._internal();
  static QuranDictionaryService get instance => _instance;

  QuranDictionaryService._internal();

  List<QuranWordModel> _allWords = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  bool get isLoaded => _isLoaded;
  int get wordCount => _allWords.length;

  /// Servisi başlat ve CSV verisini yükle
  Future<void> initialize() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      final String contents =
          await rootBundle.loadString('assets/data/quran_sozluk_okunakli.csv');

      // Ağır CSV ayrıştırmayı arka plan isolate'te yap
      _allWords = await compute(_parseCsvInIsolate, contents);

      _isLoaded = true;
      debugPrint(
          'QuranDictionaryService: ${_allWords.length} kelime yüklendi (CSV).');
    } catch (e) {
      debugPrint('QuranDictionaryService initialization error: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Arapça harekelerini kaldır
  String removeArabicDiacritics(String text) {
    return text.replaceAll(
        RegExp(r'[\u064B-\u065F\u0670\u0653-\u0655]'), '');
  }

  /// Kelime ara (kelime + kök + anlam üzerinden)
  Future<List<QuranWordModel>> searchWords(String query) async {
    if (!_isLoaded) await initialize();

    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(cleanQuery);
    final normalizedQuery = hasArabic
        ? removeArabicDiacritics(cleanQuery)
        : cleanQuery.toLowerCase();

    final exact = <QuranWordModel>[];
    final startsWith = <QuranWordModel>[];
    final contains = <QuranWordModel>[];
    final rootMatch = <QuranWordModel>[];
    final meaningMatch = <QuranWordModel>[];

    for (final word in _allWords) {
      if (hasArabic) {
        // Arapça arama
        final normKelime = removeArabicDiacritics(word.kelime);
        final normKok = removeArabicDiacritics(word.kok);

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
        final anlam = word.anlamlar.toLowerCase();
        final kok = word.kok.toLowerCase();

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
      final total = exact.length +
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
