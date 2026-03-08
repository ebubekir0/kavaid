import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/word_model.dart';

class WebDatabaseService {
  static final WebDatabaseService _instance = WebDatabaseService._internal();
  static WebDatabaseService get instance => _instance;

  WebDatabaseService._internal();

  Map<String, String>? _dictionary;
  final Map<String, WordModel> _aiWords = {};
  final List<WordModel> _pendingAiWords = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  Future<void> initialize() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      debugPrint('WebDatabaseService: Loading dictionary JSON...');
      final String content = await rootBundle.loadString('assets/data/sozluk.json');
      final dynamic decoded = jsonDecode(content);
      
      if (decoded is Map) {
        _dictionary = decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
      }
      
      _isLoaded = true;
      debugPrint('WebDatabaseService: ${_dictionary?.length ?? 0} words loaded.');
    } catch (e) {
      debugPrint('WebDatabaseService initialization error: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<WordModel?> getWordByExactMatch(String query) async {
    if (!_isLoaded) await initialize();
    final cleanQuery = query.trim().toLowerCase();
    
    // Check AI words first
    if (_aiWords.containsKey(cleanQuery)) return _aiWords[cleanQuery];

    // Check dictionary
    if (_dictionary != null && _dictionary!.containsKey(query)) {
      return WordModel(kelime: query, anlam: _dictionary![query]!, bulunduMu: true);
    }
    
    // Try lowercase match
    final dictionaryMatch = _dictionary?.entries.firstWhere(
      (e) => e.key.toLowerCase() == cleanQuery,
      orElse: () => const MapEntry('', ''),
    );
    
    if (dictionaryMatch != null && dictionaryMatch.key.isNotEmpty) {
      return WordModel(kelime: dictionaryMatch.key, anlam: dictionaryMatch.value, bulunduMu: true);
    }

    return null;
  }

  Future<WordModel?> getWordByHarekeliKelime(String harekeliKelime) async {
    // In simple web version, we treat harekeli same as normal for lookup if not indexed
    return getWordByExactMatch(harekeliKelime);
  }

  Future<bool> isWordExistsByHarekeliArabic(String harekeliKelime) async {
    final word = await getWordByHarekeliKelime(harekeliKelime);
    return word != null;
  }

  Future<void> addPendingAiWord(WordModel word) async {
    _pendingAiWords.add(word);
    if (word.kelime.isNotEmpty) {
      _aiWords[word.kelime.toLowerCase()] = word;
      if (word.harekeliKelime != null) {
        _aiWords[word.harekeliKelime!.toLowerCase()] = word;
      }
    }
  }

  Future<int> getPendingAiWordsCount() async => _pendingAiWords.length;
  
  Future<List<WordModel>> getPendingAiWords() async => List.from(_pendingAiWords);
  
  Future<void> clearPendingAiWords() async => _pendingAiWords.clear();

  Future<void> addWord(WordModel word) async {
    if (word.kelime.isNotEmpty) {
      _aiWords[word.kelime.toLowerCase()] = word;
    }
  }

  Future<List<WordModel>> searchWords(String query) async {
    if (!_isLoaded) await initialize();
    if (query.isEmpty) return [];

    final cleanQuery = query.trim().toLowerCase();
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(cleanQuery);
    
    final List<WordModel> results = [];
    final List<WordModel> exactMatches = [];
    final List<WordModel> startsWithMatches = [];
    final List<WordModel> containsMatches = [];

    // Search AI words
    _aiWords.forEach((key, word) {
      if (key == cleanQuery) {
        exactMatches.add(word);
      } else if (key.startsWith(cleanQuery)) {
        startsWithMatches.add(word);
      } else if (key.contains(cleanQuery)) {
        containsMatches.add(word);
      }
    });

    // Search Dictionary
    if (_dictionary != null) {
      _dictionary!.forEach((word, meaning) {
        final lowerWord = word.toLowerCase();
        final lowerMeaning = meaning.toLowerCase();

        if (hasArabic) {
          if (word == query || lowerWord == cleanQuery) {
            exactMatches.add(WordModel(kelime: word, anlam: meaning, bulunduMu: true));
          } else if (lowerWord.startsWith(cleanQuery)) {
            startsWithMatches.add(WordModel(kelime: word, anlam: meaning, bulunduMu: true));
          } else if (lowerWord.contains(cleanQuery)) {
            containsMatches.add(WordModel(kelime: word, anlam: meaning, bulunduMu: true));
          }
        } else {
          if (lowerMeaning == cleanQuery) {
            exactMatches.add(WordModel(kelime: word, anlam: meaning, bulunduMu: true));
          } else if (lowerMeaning.startsWith(cleanQuery)) {
            startsWithMatches.add(WordModel(kelime: word, anlam: meaning, bulunduMu: true));
          } else if (lowerMeaning.contains(cleanQuery)) {
            containsMatches.add(WordModel(kelime: word, anlam: meaning, bulunduMu: true));
          }
        }

        if (exactMatches.length + startsWithMatches.length + containsMatches.length > 100) {
          return;
        }
      });
    }

    return [...exactMatches, ...startsWithMatches, ...containsMatches].take(100).toList();
  }
}
