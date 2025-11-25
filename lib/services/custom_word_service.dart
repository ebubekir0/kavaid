import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_word.dart';
import '../models/custom_word_list.dart';
import '../models/word_model.dart';
import 'package:uuid/uuid.dart';
import 'saved_words_service.dart';

class CustomWordService {
  static const String _wordsKey = 'user_custom_words';
  static const String _listsKey = 'user_custom_word_lists';
  static const String _migrationKey = 'saved_words_migrated_v1';
  final Uuid _uuid = const Uuid();

  // --- Migration ---

  Future<void> migrateSavedWords() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;

    final savedService = SavedWordsService();
    await savedService.initialize(); // Ensure it's ready
    final oldWords = await savedService.getSavedWords();

    if (oldWords.isEmpty) {
      await prefs.setBool(_migrationKey, true);
      return;
    }

    // Ensure 'Kaydedilenler' list exists
    final lists = await getLists();
    CustomWordList? targetList = lists.firstWhere(
      (l) => l.name == 'Kaydedilenler', 
      orElse: () => CustomWordList(id: '', name: '', createdAt: DateTime.now()) // Dummy
    );

    if (targetList.id.isEmpty) {
      targetList = await createList('Kaydedilenler');
    }

    // Add words
    for (final word in oldWords) {
      await addWord(word.kelime, word.anlam ?? '', targetList.id);
    }

    await prefs.setBool(_migrationKey, true);
  }

  // --- Listeler ---

  Future<List<CustomWordList>> getLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_listsKey);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((e) => CustomWordList.fromMap(e)).toList();
      // Sort kaldırıldı, kullanıcı sıralaması geçerli
    } catch (e) {
      return [];
    }
  }

  Future<void> saveListsOrder(List<CustomWordList> lists) async {
    await _saveLists(lists);
  }

  /// Kelimenin hangi listelerde olduğunu döndürür (ID listesi)
  Future<List<String>> getListsWithWord(String arabicWord) async {
    final allWords = await getAllWords();
    return allWords
        .where((w) => w.arabic == arabicWord && w.listId != null)
        .map((w) => w.listId!)
        .toList();
  }

  /// Kelimeyi belirli bir listeden kaldırır
  Future<void> removeWordFromList(String arabicWord, String listId) async {
    final words = await getAllWords();
    words.removeWhere((w) => w.listId == listId && w.arabic == arabicWord);
    await _saveWords(words);
  }

  Future<CustomWordList> createList(String name) async {
    final lists = await getLists();
    final newList = CustomWordList(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    lists.insert(0, newList);
    await _saveLists(lists);
    return newList;
  }

  Future<void> renameList(String id, String newName) async {
    final lists = await getLists();
    final index = lists.indexWhere((l) => l.id == id);
    if (index != -1) {
      lists[index] = CustomWordList(
        id: id,
        name: newName,
        createdAt: lists[index].createdAt,
      );
      await _saveLists(lists);
    }
  }

  Future<void> deleteList(String id) async {
    final lists = await getLists();
    lists.removeWhere((l) => l.id == id);
    await _saveLists(lists);
    
    // O listeye ait kelimeleri de sil
    final words = await getAllWords();
    words.removeWhere((w) => w.listId == id);
    await _saveWords(words);
  }

  Future<void> _saveLists(List<CustomWordList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(lists.map((e) => e.toMap()).toList());
    await prefs.setString(_listsKey, data);
  }

  // --- Kelimeler ---

  Future<List<CustomWord>> getAllWords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_wordsKey);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((e) => CustomWord.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<CustomWord>> getWordsByList(String listId) async {
    final allWords = await getAllWords();
    // Return words in the order they are stored, filtering by listId
    // We remove the sort by date to respect user reordering
    return allWords.where((w) => w.listId == listId).toList();
  }

  Future<void> saveReorderedWords(List<CustomWord> reorderedWords) async {
    if (reorderedWords.isEmpty) return;
    
    final listId = reorderedWords.first.listId;
    final allWords = await getAllWords();
    
    // Remove all words belonging to this list
    allWords.removeWhere((w) => w.listId == listId);
    
    // Add the reordered words back (preserving their new order)
    // We can add them at the beginning or end. Let's add at the beginning to keep them accessible.
    allWords.insertAll(0, reorderedWords);
    
    await _saveWords(allWords);
  }

  /// WordModel ile kelime ekle (tüm bilgilerle)
  Future<bool> addWordFromModel(WordModel wordModel, String listId) async {
    final words = await getAllWords();
    
    // Duplicate check: Aynı listede aynı Arapça kelime varsa ekleme
    final exists = words.any((w) => w.listId == listId && w.arabic == wordModel.kelime);
    if (exists) return false;

    final newWord = CustomWord.fromWordModel(wordModel, _uuid.v4(), listId);
    
    words.insert(0, newWord);
    await _saveWords(words);
    return true;
  }

  /// Eski metod - geriye uyumluluk için
  Future<bool> addWord(String arabic, String turkish, String listId, {String? harekeliKelime}) async {
    final words = await getAllWords();
    
    // Duplicate check: Aynı listede aynı Arapça kelime varsa ekleme
    final exists = words.any((w) => w.listId == listId && w.arabic == arabic);
    if (exists) return false;

    final newWord = CustomWord(
      id: _uuid.v4(),
      arabic: arabic,
      turkish: turkish,
      harekeliKelime: harekeliKelime,
      createdAt: DateTime.now(),
      listId: listId,
    );
    
    words.insert(0, newWord);
    await _saveWords(words);
    return true;
  }

  Future<void> deleteWord(String id) async {
    final words = await getAllWords();
    words.removeWhere((w) => w.id == id);
    await _saveWords(words);
  }

  Future<void> updateWord(String id, String newArabic, String newTurkish) async {
    final words = await getAllWords();
    final index = words.indexWhere((w) => w.id == id);
    if (index != -1) {
      words[index] = CustomWord(
        id: id,
        arabic: newArabic,
        turkish: newTurkish,
        createdAt: words[index].createdAt,
        listId: words[index].listId,
      );
      await _saveWords(words);
    }
  }

  Future<void> _saveWords(List<CustomWord> words) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(words.map((e) => e.toMap()).toList());
    await prefs.setString(_wordsKey, data);
  }
}
