import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/custom_word.dart';
import '../models/custom_word_list.dart';
import '../models/word_model.dart';
import 'package:uuid/uuid.dart';
import 'auth_service.dart';

/// Offline-first kelime listesi servisi
/// İşlemler önce yerelde yapılır, internet varsa arka planda Firestore'a senkronize edilir
class CustomWordService {
  static final CustomWordService _instance = CustomWordService._internal();
  
  factory CustomWordService() {
    return _instance;
  }

  CustomWordService._internal() {
    // Bağlantı değişikliklerini dinle
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && _isUserLoggedIn) {
        // İnternet açıldığında bekleyen işlemleri senkronize et
        _syncPendingChangesToFirestore();
      }
    });
    
    // Uygulama başladığında bekleyen işlemleri kontrol et
    _checkAndSyncOnStartup();
  }
  
  /// Uygulama başladığında bekleyen işlemleri kontrol et
  Future<void> _checkAndSyncOnStartup() async {
    // Biraz bekle, auth durumu yüklensin
    await Future.delayed(const Duration(seconds: 2));
    
    if (_isUserLoggedIn) {
      final hasConnection = await _hasInternetConnection();
      if (hasConnection) {
        debugPrint('🔄 [CustomWordService] Uygulama başladı, bekleyen işlemler kontrol ediliyor...');
        await _syncPendingChangesToFirestore();
      }
    }
  }
  
  /// Kullanıcı giriş yaptığında çağrılır - bekleyen işlemleri senkronize et
  Future<void> onUserLogin() async {
    final hasConnection = await _hasInternetConnection();
    if (hasConnection) {
      debugPrint('🔄 [CustomWordService] Kullanıcı giriş yaptı, senkronizasyon başlıyor...');
      await _syncPendingChangesToFirestore();
      await syncFromFirestore();
    }
  }

  // Firestore collection references
  static const String _listsCollection = 'word_lists';
  static const String _wordsCollection = 'custom_words';
  
  // Local storage keys
  static const String _localListsKey = 'local_word_lists';
  static const String _localWordsKey = 'local_custom_words';
  static const String _pendingSyncKey = 'pending_sync_operations';
  static const String _migrationKey = 'migrated_to_firestore_v3';
  static const String _lastSyncKey = 'last_firestore_sync';
  
  final Uuid _uuid = const Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final _changeController = StreamController<void>.broadcast();
  Stream<void> get onWordsChanged => _changeController.stream;

  void _notifyListeners() {
    _changeController.add(null);
  }

  /// Kullanıcının Firestore document path'i
  String? get _userPath {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return null;
    return 'users/$userId';
  }

  /// Kullanıcı giriş yapmış mı kontrol et
  bool get _isUserLoggedIn => _authService.isSignedIn;

  /// İnternet bağlantısı var mı kontrol et
  Future<bool> _hasInternetConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // LOCAL STORAGE OPERATIONS
  // ============================================================

  /// Yerel listeleri getir
  Future<List<CustomWordList>> _getLocalLists() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _authService.currentUser?.uid ?? 'guest';
    final key = '${_localListsKey}_$userId';
    final String? data = prefs.getString(key);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((e) => CustomWordList.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Yerel listeleri kaydet
  Future<void> _saveLocalLists(List<CustomWordList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _authService.currentUser?.uid ?? 'guest';
    final key = '${_localListsKey}_$userId';
    final String data = json.encode(lists.map((e) => e.toMap()).toList());
    await prefs.setString(key, data);
  }

  /// Yerel kelimeleri getir
  Future<List<CustomWord>> _getLocalWords() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _authService.currentUser?.uid ?? 'guest';
    final key = '${_localWordsKey}_$userId';
    final String? data = prefs.getString(key);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((e) => CustomWord.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Yerel kelimeleri kaydet
  Future<void> _saveLocalWords(List<CustomWord> words) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _authService.currentUser?.uid ?? 'guest';
    final key = '${_localWordsKey}_$userId';
    final String data = json.encode(words.map((e) => e.toMap()).toList());
    await prefs.setString(key, data);
  }

  // ============================================================
  // PENDING SYNC OPERATIONS
  // ============================================================

  /// Bekleyen senkronizasyon işlemlerini kaydet
  Future<void> _addPendingOperation(String type, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _authService.currentUser?.uid ?? 'guest';
    final key = '${_pendingSyncKey}_$userId';
    
    List<Map<String, dynamic>> pending = [];
    final existingData = prefs.getString(key);
    if (existingData != null) {
      try {
        pending = List<Map<String, dynamic>>.from(json.decode(existingData));
      } catch (_) {}
    }
    
    pending.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(key, json.encode(pending));
  }

  /// Bekleyen işlemleri Firestore'a senkronize et
  Future<void> _syncPendingChangesToFirestore() async {
    if (!_isUserLoggedIn || _userPath == null) return;
    
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) return;
    
    final prefs = await SharedPreferences.getInstance();
    final userId = _authService.currentUser?.uid;
    final key = '${_pendingSyncKey}_$userId';
    
    final existingData = prefs.getString(key);
    if (existingData == null) return;
    
    List<Map<String, dynamic>> pending;
    try {
      pending = List<Map<String, dynamic>>.from(json.decode(existingData));
    } catch (_) {
      return;
    }
    
    if (pending.isEmpty) return;
    
    debugPrint('🔄 [CustomWordService] ${pending.length} bekleyen işlem senkronize ediliyor...');
    
    final successfulOps = <int>[];
    
    for (int i = 0; i < pending.length; i++) {
      final op = pending[i];
      try {
        final type = op['type'] as String;
        final data = Map<String, dynamic>.from(op['data']);
        
        switch (type) {
          case 'create_list':
            await _firestore
                .collection('$_userPath/$_listsCollection')
                .doc(data['id'])
                .set(data);
            break;
          case 'rename_list':
            await _firestore
                .collection('$_userPath/$_listsCollection')
                .doc(data['id'])
                .update({'name': data['name']});
            break;
          case 'delete_list':
            // Listedeki kelimeleri sil
            final wordsSnapshot = await _firestore
                .collection('$_userPath/$_wordsCollection')
                .where('listId', isEqualTo: data['id'])
                .get();
            final batch = _firestore.batch();
            for (final doc in wordsSnapshot.docs) {
              batch.delete(doc.reference);
            }
            batch.delete(_firestore.collection('$_userPath/$_listsCollection').doc(data['id']));
            await batch.commit();
            break;
          case 'add_word':
            await _firestore
                .collection('$_userPath/$_wordsCollection')
                .doc(data['id'])
                .set(data);
            break;
          case 'delete_word':
            await _firestore
                .collection('$_userPath/$_wordsCollection')
                .doc(data['id'])
                .delete();
            break;
          case 'remove_word_from_list':
            final snapshot = await _firestore
                .collection('$_userPath/$_wordsCollection')
                .where('listId', isEqualTo: data['listId'])
                .where('arabic', isEqualTo: data['arabic'])
                .get();
            for (final doc in snapshot.docs) {
              await doc.reference.delete();
            }
            break;
        }
        successfulOps.add(i);
      } catch (e) {
        debugPrint('⚠️ [CustomWordService] Sync hatası: $e');
      }
    }
    
    // Başarılı işlemleri listeden kaldır
    for (int i = successfulOps.length - 1; i >= 0; i--) {
      pending.removeAt(successfulOps[i]);
    }
    
    if (pending.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, json.encode(pending));
    }
    
    debugPrint('✅ [CustomWordService] ${successfulOps.length} işlem senkronize edildi');
  }

  /// Firestore'dan yerele tam senkronizasyon
  Future<void> syncFromFirestore() async {
    if (!_isUserLoggedIn || _userPath == null) return;
    
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) return;
    
    try {
      // Listeleri indir
      final listsSnapshot = await _firestore
          .collection('$_userPath/$_listsCollection')
          .get();
      final lists = listsSnapshot.docs
          .map((doc) => CustomWordList.fromMap(doc.data()))
          .toList();
      await _saveLocalLists(lists);
      
      // Kelimeleri indir
      final wordsSnapshot = await _firestore
          .collection('$_userPath/$_wordsCollection')
          .get();
      final words = wordsSnapshot.docs
          .map((doc) => CustomWord.fromMap(doc.data()))
          .toList();
      await _saveLocalWords(words);
      
      // Son sync zamanını kaydet
      final prefs = await SharedPreferences.getInstance();
      final userId = _authService.currentUser?.uid;
      await prefs.setString('${_lastSyncKey}_$userId', DateTime.now().toIso8601String());
      
      debugPrint('✅ [CustomWordService] Firestore\'dan senkronizasyon tamamlandı');
      _notifyListeners();
    } catch (e) {
      debugPrint('❌ [CustomWordService] Sync hatası: $e');
    }
  }

  // ============================================================
  // MIGRATION: Eski Firestore saved_words'den yeni sisteme geçiş
  // ============================================================

  /// Eski Firestore saved_words koleksiyonundaki kelimeleri yeni sisteme migrate et
  Future<void> migrateToFirestore() async {
    if (!_isUserLoggedIn || _userPath == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final userId = _authService.currentUser?.uid;
    final migrationCheckKey = '${_migrationKey}_$userId';
    
    if (prefs.getBool(migrationCheckKey) == true) {
      return;
    }
    
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      debugPrint('⚠️ [CustomWordService] İnternet yok, migration atlandı');
      return;
    }
    
    debugPrint('🔄 [CustomWordService] Migration başlıyor...');
    
    try {
      // Yeni sistemde veri var mı kontrol et
      final localLists = await _getLocalLists();
      if (localLists.isNotEmpty) {
        await prefs.setBool(migrationCheckKey, true);
        return;
      }
      
      // Firestore'daki yeni sistemde veri var mı
      final firestoreLists = await _firestore
          .collection('$_userPath/$_listsCollection')
          .limit(1)
          .get();
      
      if (firestoreLists.docs.isNotEmpty) {
        // Firestore'dan yerele senkronize et
        await syncFromFirestore();
        await prefs.setBool(migrationCheckKey, true);
        return;
      }
      
      // Eski saved_words'den migration
      final oldSavedWordsSnapshot = await _firestore
          .collection('$_userPath/saved_words')
          .get();
      
      if (oldSavedWordsSnapshot.docs.isEmpty) {
        await prefs.setBool(migrationCheckKey, true);
        return;
      }
      
      debugPrint('📋 [CustomWordService] ${oldSavedWordsSnapshot.docs.length} eski kelime bulundu');
      
      // Default liste oluştur
      final defaultList = CustomWordList(
        id: _uuid.v4(),
        name: 'Kaydedilenler',
        createdAt: DateTime.now(),
        isDefault: true,
      );
      
      // Yerele kaydet
      await _saveLocalLists([defaultList]);
      
      // Kelimeleri migrate et
      final migratedWords = <CustomWord>[];
      for (final doc in oldSavedWordsSnapshot.docs) {
        try {
          final data = doc.data();
          final dynamic wordDataRaw = data['word_data'];
          
          Map<String, dynamic> wordData;
          if (wordDataRaw is String) {
            wordData = Map<String, dynamic>.from(json.decode(wordDataRaw));
          } else if (wordDataRaw is Map) {
            wordData = Map<String, dynamic>.from(wordDataRaw);
          } else {
            continue;
          }
          
          final kelime = data['kelime'] as String? ?? wordData['kelime'] as String? ?? '';
          if (kelime.isEmpty) continue;
          
          migratedWords.add(CustomWord(
            id: _uuid.v4(),
            arabic: kelime,
            turkish: wordData['anlam'] as String? ?? '',
            harekeliKelime: wordData['harekeliKelime'] as String?,
            wordData: wordData,
            createdAt: DateTime.now(),
            listId: defaultList.id,
          ));
        } catch (e) {
          debugPrint('⚠️ [CustomWordService] Kelime migration hatası: $e');
        }
      }
      
      // Yerele kaydet
      await _saveLocalWords(migratedWords);
      
      // Firestore'a kaydet (arka planda)
      _syncAllToFirestore();
      
      await prefs.setBool(migrationCheckKey, true);
      debugPrint('✅ [CustomWordService] ${migratedWords.length} kelime migrate edildi');
      
      _notifyListeners();
    } catch (e) {
      debugPrint('❌ [CustomWordService] Migration hatası: $e');
    }
  }

  /// Tüm yerel veriyi Firestore'a senkronize et
  Future<void> _syncAllToFirestore() async {
    if (!_isUserLoggedIn || _userPath == null) return;
    
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) return;
    
    try {
      final lists = await _getLocalLists();
      final words = await _getLocalWords();
      
      final batch = _firestore.batch();
      
      for (final list in lists) {
        batch.set(
          _firestore.collection('$_userPath/$_listsCollection').doc(list.id),
          list.toMap(),
        );
      }
      
      for (final word in words) {
        batch.set(
          _firestore.collection('$_userPath/$_wordsCollection').doc(word.id),
          word.toMap(),
        );
      }
      
      await batch.commit();
      debugPrint('✅ [CustomWordService] Tüm veriler Firestore\'a senkronize edildi');
    } catch (e) {
      debugPrint('❌ [CustomWordService] Sync hatası: $e');
    }
  }

  // ============================================================
  // PUBLIC API - Listeler
  // ============================================================

  /// Tüm listeleri getir (önce yerelden)
  Future<List<CustomWordList>> getLists() async {
    if (!_isUserLoggedIn) return [];
    
    // Yerelden al
    final lists = await _getLocalLists();
    return lists;
  }

  /// En az bir liste olduğundan emin ol, yoksa "Kaydedilenler" oluştur
  Future<CustomWordList> getOrCreateDefaultList() async {
    if (!_isUserLoggedIn) {
      return CustomWordList(
        id: 'temp_default',
        name: 'Kaydedilenler',
        createdAt: DateTime.now(),
        isDefault: true,
      );
    }
    
    // Migration'ı çalıştır
    await migrateToFirestore();
    
    final lists = await getLists();
    
    if (lists.isNotEmpty) {
      return lists.first;
    }
    
    // Hiç liste yoksa "Kaydedilenler" oluştur
    return await createList('Kaydedilenler');
  }

  /// Yeni liste oluştur
  Future<CustomWordList> createList(String name) async {
    if (!_isUserLoggedIn) {
      throw Exception('Giriş yapılmamış');
    }
    
    final newList = CustomWordList(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      isDefault: false,
    );
    
    // Yerele kaydet
    final lists = await _getLocalLists();
    lists.insert(0, newList);
    await _saveLocalLists(lists);
    
    // Arka planda Firestore'a kaydet
    _syncListToFirestore(newList);
    
    _notifyListeners();
    return newList;
  }

  /// Arka planda listeyi Firestore'a kaydet
  Future<void> _syncListToFirestore(CustomWordList list) async {
    final hasConnection = await _hasInternetConnection();
    if (hasConnection && _userPath != null) {
      try {
        await _firestore
            .collection('$_userPath/$_listsCollection')
            .doc(list.id)
            .set(list.toMap());
      } catch (e) {
        // Başarısız olursa pending'e ekle
        await _addPendingOperation('create_list', list.toMap());
      }
    } else {
      await _addPendingOperation('create_list', list.toMap());
    }
  }

  /// Liste adını değiştir
  Future<void> renameList(String id, String newName) async {
    if (!_isUserLoggedIn) return;
    
    // Yerelde güncelle
    final lists = await _getLocalLists();
    final index = lists.indexWhere((l) => l.id == id);
    if (index != -1) {
      lists[index] = CustomWordList(
        id: id,
        name: newName,
        createdAt: lists[index].createdAt,
        isDefault: lists[index].isDefault,
      );
      await _saveLocalLists(lists);
    }
    
    // Arka planda Firestore'a kaydet
    final hasConnection = await _hasInternetConnection();
    if (hasConnection && _userPath != null) {
      try {
        await _firestore
            .collection('$_userPath/$_listsCollection')
            .doc(id)
            .update({'name': newName});
      } catch (e) {
        await _addPendingOperation('rename_list', {'id': id, 'name': newName});
      }
    } else {
      await _addPendingOperation('rename_list', {'id': id, 'name': newName});
    }
    
    _notifyListeners();
  }

  /// Liste sil (ve içindeki kelimeleri)
  Future<void> deleteList(String id) async {
    if (!_isUserLoggedIn) return;
    
    // Yerelden sil
    final lists = await _getLocalLists();
    lists.removeWhere((l) => l.id == id);
    await _saveLocalLists(lists);
    
    final words = await _getLocalWords();
    words.removeWhere((w) => w.listId == id);
    await _saveLocalWords(words);
    
    // Arka planda Firestore'dan sil
    final hasConnection = await _hasInternetConnection();
    if (hasConnection && _userPath != null) {
      try {
        final wordsSnapshot = await _firestore
            .collection('$_userPath/$_wordsCollection')
            .where('listId', isEqualTo: id)
            .get();
        final batch = _firestore.batch();
        for (final doc in wordsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        batch.delete(_firestore.collection('$_userPath/$_listsCollection').doc(id));
        await batch.commit();
      } catch (e) {
        await _addPendingOperation('delete_list', {'id': id});
      }
    } else {
      await _addPendingOperation('delete_list', {'id': id});
    }
    
    _notifyListeners();
  }

  /// Kelimenin hangi listelerde olduğunu döndürür
  Future<List<String>> getListsWithWord(String arabicWord) async {
    if (!_isUserLoggedIn) return [];
    
    // Yerelden kontrol et
    final words = await _getLocalWords();
    return words
        .where((w) => w.arabic == arabicWord && w.listId != null)
        .map((w) => w.listId!)
        .toList();
  }

  // ============================================================
  // PUBLIC API - Kelimeler
  // ============================================================

  /// Tüm kelimeleri getir (yerelden)
  Future<List<CustomWord>> getAllWords() async {
    if (!_isUserLoggedIn) return [];
    return await _getLocalWords();
  }

  /// Belirli listedeki kelimeleri getir (yerelden)
  Future<List<CustomWord>> getWordsByList(String listId) async {
    if (!_isUserLoggedIn) return [];
    
    final words = await _getLocalWords();
    return words
        .where((w) => w.listId == listId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// WordModel ile kelime ekle
  Future<bool> addWordFromModel(WordModel wordModel, String listId) async {
    if (!_isUserLoggedIn) return false;
    
    // Yerelden duplicate check
    final words = await _getLocalWords();
    final exists = words.any((w) => w.listId == listId && w.arabic == wordModel.kelime);
    if (exists) return false;

    final newWord = CustomWord.fromWordModel(wordModel, _uuid.v4(), listId);
    
    // Yerele kaydet
    words.insert(0, newWord);
    await _saveLocalWords(words);
    
    // Arka planda Firestore'a kaydet
    _syncWordToFirestore(newWord);
    
    _notifyListeners();
    return true;
  }

  /// Arka planda kelimeyi Firestore'a kaydet
  Future<void> _syncWordToFirestore(CustomWord word) async {
    final hasConnection = await _hasInternetConnection();
    if (hasConnection && _userPath != null) {
      try {
        await _firestore
            .collection('$_userPath/$_wordsCollection')
            .doc(word.id)
            .set(word.toMap());
      } catch (e) {
        await _addPendingOperation('add_word', word.toMap());
      }
    } else {
      await _addPendingOperation('add_word', word.toMap());
    }
  }

  /// Basit kelime ekle (geriye uyumluluk)
  Future<bool> addWord(String arabic, String turkish, String listId, {String? harekeliKelime}) async {
    if (!_isUserLoggedIn) return false;
    
    // Yerelden duplicate check
    final words = await _getLocalWords();
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
    
    // Yerele kaydet
    words.insert(0, newWord);
    await _saveLocalWords(words);
    
    // Arka planda Firestore'a kaydet
    _syncWordToFirestore(newWord);
    
    _notifyListeners();
    return true;
  }

  /// Kelimeyi listeden kaldır
  Future<void> removeWordFromList(String arabicWord, String listId) async {
    if (!_isUserLoggedIn) return;
    
    // Yerelden kaldır
    final words = await _getLocalWords();
    words.removeWhere((w) => w.listId == listId && w.arabic == arabicWord);
    await _saveLocalWords(words);
    
    // Arka planda Firestore'dan kaldır
    final hasConnection = await _hasInternetConnection();
    if (hasConnection && _userPath != null) {
      try {
        final snapshot = await _firestore
            .collection('$_userPath/$_wordsCollection')
            .where('listId', isEqualTo: listId)
            .where('arabic', isEqualTo: arabicWord)
            .get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        await _addPendingOperation('remove_word_from_list', {
          'listId': listId,
          'arabic': arabicWord,
        });
      }
    } else {
      await _addPendingOperation('remove_word_from_list', {
        'listId': listId,
        'arabic': arabicWord,
      });
    }
    
    _notifyListeners();
  }

  /// Kelime sil (ID ile)
  Future<void> deleteWord(String id) async {
    if (!_isUserLoggedIn) return;
    
    // Yerelden sil
    final words = await _getLocalWords();
    words.removeWhere((w) => w.id == id);
    await _saveLocalWords(words);
    
    // Arka planda Firestore'dan sil
    final hasConnection = await _hasInternetConnection();
    if (hasConnection && _userPath != null) {
      try {
        await _firestore
            .collection('$_userPath/$_wordsCollection')
            .doc(id)
            .delete();
      } catch (e) {
        await _addPendingOperation('delete_word', {'id': id});
      }
    } else {
      await _addPendingOperation('delete_word', {'id': id});
    }
    
    _notifyListeners();
  }

  /// Kelime güncelle
  Future<void> updateWord(String id, String newArabic, String newTurkish) async {
    if (!_isUserLoggedIn) return;
    
    // Yerelde güncelle
    final words = await _getLocalWords();
    final index = words.indexWhere((w) => w.id == id);
    if (index != -1) {
      words[index] = CustomWord(
        id: id,
        arabic: newArabic,
        turkish: newTurkish,
        harekeliKelime: words[index].harekeliKelime,
        wordData: words[index].wordData,
        createdAt: words[index].createdAt,
        listId: words[index].listId,
      );
      await _saveLocalWords(words);
    }
    
    // Arka planda Firestore'da güncelle
    final hasConnection = await _hasInternetConnection();
    if (hasConnection && _userPath != null) {
      try {
        await _firestore
            .collection('$_userPath/$_wordsCollection')
            .doc(id)
            .update({
              'arabic': newArabic,
              'turkish': newTurkish,
            });
      } catch (e) {
        // Pending operation eklenebilir
      }
    }
    
    _notifyListeners();
  }

  /// Kelimeleri yeniden sırala
  Future<void> saveReorderedWords(List<CustomWord> reorderedWords) async {
    if (!_isUserLoggedIn || reorderedWords.isEmpty) return;
    
    final listId = reorderedWords.first.listId;
    final allWords = await _getLocalWords();
    
    // Bu listedeki kelimeleri kaldır
    allWords.removeWhere((w) => w.listId == listId);
    
    // Yeni sırayla ekle
    allWords.insertAll(0, reorderedWords);
    
    await _saveLocalWords(allWords);
    _notifyListeners();
  }

  // ============================================================
  // LEGACY MIGRATION SUPPORT
  // ============================================================

  /// Eski migrateSavedWords metodu
  Future<void> migrateSavedWords() async {
    await migrateToFirestore();
  }

  /// Liste sırasını kaydet
  Future<void> saveListsOrder(List<CustomWordList> lists) async {
    await _saveLocalLists(lists);
    _notifyListeners();
  }
  
  /// Servisi dispose et
  void dispose() {
    _connectivitySubscription?.cancel();
    _changeController.close();
  }
}
