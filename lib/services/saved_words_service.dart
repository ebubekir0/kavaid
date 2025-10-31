import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word_model.dart';
import 'turkce_analytics_service.dart';
import 'auth_service.dart';
import 'cloud_saved_words_service.dart';

class SavedWordsService extends ChangeNotifier {
  // Singleton pattern
  static final SavedWordsService _instance = SavedWordsService._internal();
  factory SavedWordsService() => _instance;
  SavedWordsService._internal();

  // Database ve Cache için
  Database? _database;
  List<WordModel> _cachedSavedWords = [];
  Set<String> _savedWordKeys = {};
  bool _isInitialized = false;
  final bool _isWebPlatform = kIsWeb;
  final Map<String, bool> _operationInProgress = {};
  String? _currentUserId; // Mevcut kullanıcı ID'si
  
  // 🚀 PERFORMANCE: ValueNotifier'lar için cache
  final Map<String, ValueNotifier<bool>> _savedNotifiers = {};

  // Database'i aç veya oluştur
  Future<Database?> _getDatabase() async {
    try {
      if (_isWebPlatform) {
        debugPrint('🌐 [SavedWords] Web platformu - database kullanılmıyor');
        return null;
      }

      if (_database != null && _database!.isOpen) {
        return _database;
      }

      final dbPath = await getDatabasesPath();
      // Kullanıcı bazlı veritabanı dosyası
      final userId = AuthService().userId ?? 'guest';
      final path = join(dbPath, 'saved_words_$userId.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE saved_words(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              kelime TEXT UNIQUE NOT NULL,
              word_data TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_kelime ON saved_words(kelime)'
          );
        },
      );

      return _database;
    } catch (e) {
      print('SavedWordsService: Database açma hatası: $e');
      return null;
    }
  }

  // Servisi başlat
  Future<void> initialize() async {
    final currentUserId = AuthService().userId ?? 'guest';
    
    // Kullanıcı değişmişse cache'i temizle ve yeniden yükle
    if (_currentUserId != currentUserId) {
      debugPrint('🔄 SavedWords: Kullanıcı değişti ($_currentUserId -> $currentUserId), cache temizleniyor');
      _currentUserId = currentUserId;
      _cachedSavedWords.clear();
      _savedWordKeys.clear();
      _isInitialized = false;
      
      // Eski database bağlantısını kapat
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
      
      // ValueNotifier'ları güncelle
      for (var notifier in _savedNotifiers.values) {
        notifier.value = false;
      }
    }
    
    if (_isInitialized) return;
    await getSavedWords();
  }

  // Getter
  bool get isInitialized => _isInitialized;
  
  // 🚀 PERFORMANCE: ValueListenableBuilder için notifier döndür
  ValueNotifier<bool> isWordSavedNotifier(WordModel word) {
    final key = word.kelime;
    
    // Notifier yoksa oluştur
    if (!_savedNotifiers.containsKey(key)) {
      _savedNotifiers[key] = ValueNotifier<bool>(isWordSavedSync(word));
    }
    
    return _savedNotifiers[key]!;
  }
  
  // Kaydedilen kelimeleri getir
  Future<List<WordModel>> getSavedWords() async {
    try {
      // Web platformunda cache'den döndür
      if (_isWebPlatform) {
        _isInitialized = true;
        return _cachedSavedWords;
      }

      final db = await _getDatabase();
      if (db == null) {
        _isInitialized = true;
        return _cachedSavedWords;
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'saved_words',
        orderBy: 'created_at DESC',
      );

      _cachedSavedWords = maps.map((map) {
        final wordData = jsonDecode(map['word_data'] as String);
        return WordModel.fromJson(wordData);
      }).toList();

      // Hızlı erişim için kelime anahtarlarını set'e ekle
      _savedWordKeys = _cachedSavedWords.map((word) => word.kelime).toSet();
      
      // 🚀 PERFORMANCE: Mevcut notifier'ları güncelle
      for (var entry in _savedNotifiers.entries) {
        final kelime = entry.key;
        final notifier = entry.value;
        notifier.value = _savedWordKeys.contains(kelime);
      }
      
      _isInitialized = true;
      notifyListeners();
      
      return _cachedSavedWords;
    } catch (e) {
      print('SavedWordsService: Kelimeleri getirme hatası: $e');
      _isInitialized = true;
      return _cachedSavedWords;
    }
  }

  // Kelime kayıtlı mı kontrol et (hızlı cache'den)
  bool isWordSavedSync(WordModel word) {
    // Null veya boş kelime kontrolü
    if (word.kelime.isEmpty) {
      return false;
    }
    
    // Cache yüklenmemişse false döndür
    if (!_isInitialized || _cachedSavedWords == null) {
      return false;
    }
    
    // Kelime anahtarını kontrol et
    return _savedWordKeys.contains(word.kelime);
  }

  // Kelime kayıtlı mı kontrol et (async - backward compatibility)
  Future<bool> isWordSaved(WordModel word) async {
    // Null veya boş kelime kontrolü
    if (word.kelime.isEmpty) {
      return false;
    }
    
    // Cache boşsa önce yükle
    if (!_isInitialized) {
      await getSavedWords();
    }
    
    return _savedWordKeys.contains(word.kelime);
  }

  // Kelime kaydet
  Future<bool> saveWord(WordModel word) async {
    try {
      // Duplicate operation kontrolü
      final operationKey = 'save_${word.kelime}';
      if (_operationInProgress[operationKey] == true) {
        return false;
      }
      _operationInProgress[operationKey] = true;
      
      // Önce cache'i güncelle - immediate feedback
      if (!_savedWordKeys.contains(word.kelime)) {
        _cachedSavedWords.insert(0, word);
        _savedWordKeys.add(word.kelime);
        
        // 🚀 PERFORMANCE: ValueNotifier'ı güncelle
        if (_savedNotifiers.containsKey(word.kelime)) {
          _savedNotifiers[word.kelime]!.value = true;
        }
        
        notifyListeners();
      } else {
        _operationInProgress.remove(operationKey);
        return true; // Zaten kayıtlı
      }
      
      // Web platformunda sadece cache kullan
      if (_isWebPlatform) {
        _operationInProgress.remove(operationKey);
        return true;
      }
      
      final db = await _getDatabase();
      if (db == null) {
        // Database yoksa sadece cache'de tut
        _operationInProgress.remove(operationKey);
        return true;
      }
      
      try {
        // Database'e kaydet
        await db.transaction((txn) async {
          // Önce varsa sil (duplicate önlemek için)
          await txn.delete(
            'saved_words',
            where: 'kelime = ?',
            whereArgs: [word.kelime],
          );
          
          // Yeni kaydet
          await txn.insert(
            'saved_words',
            {
              'kelime': word.kelime,
              'word_data': jsonEncode(word.toJson()),
              'created_at': DateTime.now().millisecondsSinceEpoch,
            },
          );
        });
        
        // Analytics event'i gönder
        await TurkceAnalyticsService.kelimeKaydedildi(word.kelime);
        
        // Kullanıcı giriş yapmışsa buluta da kaydet
        if (AuthService().isSignedIn) {
          try {
            await CloudSavedWordsService().syncUpFromLocal();
            debugPrint('✅ SavedWords: Kelime buluta da kaydedildi: ${word.kelime}');
          } catch (e) {
            debugPrint('⚠️ SavedWords: Buluta kaydetme hatası: $e');
          }
        }
        
        _operationInProgress.remove(operationKey);
        return true;
      } catch (e) {
        // Database hatası durumunda cache'i geri al
        _cachedSavedWords.removeWhere((w) => w.kelime == word.kelime);
        _savedWordKeys.remove(word.kelime);
        notifyListeners();
        _operationInProgress.remove(operationKey);
        return false;
      }
    } catch (e) {
      print('SavedWordsService: Save error: $e');
      _operationInProgress.remove('save_${word.kelime}');
      return false;
    }
  }

  // Kelimeyi kaldır
  Future<bool> removeWord(WordModel word) async {
    try {
      // Duplicate operation kontrolü
      final operationKey = 'remove_${word.kelime}';
      if (_operationInProgress[operationKey] == true) {
        return false;
      }
      _operationInProgress[operationKey] = true;
      
      // Cache'de yoksa zaten silinmiş
      if (!_savedWordKeys.contains(word.kelime)) {
        _operationInProgress.remove(operationKey);
        return true;
      }
      
      // Önce cache'den kaldır - immediate feedback
      final removedWord = _cachedSavedWords.firstWhere(
        (w) => w.kelime == word.kelime,
        orElse: () => word,
      );
      _cachedSavedWords.removeWhere((w) => w.kelime == word.kelime);
      _savedWordKeys.remove(word.kelime);
      
      // 🚀 PERFORMANCE: ValueNotifier'ı güncelle
      if (_savedNotifiers.containsKey(word.kelime)) {
        _savedNotifiers[word.kelime]!.value = false;
      }
      
      notifyListeners();
      
      // Web platformunda sadece cache kullan
      if (_isWebPlatform) {
        _operationInProgress.remove(operationKey);
        return true;
      }
      
      final db = await _getDatabase();
      if (db == null) {
        // Database yoksa sadece cache'den kaldır
        _operationInProgress.remove(operationKey);
        return true;
      }
      
      try {
        // Database'den sil
        await db.delete(
          'saved_words',
          where: 'kelime = ?',
          whereArgs: [word.kelime],
        );
        
        // Analytics event'i gönder
        await TurkceAnalyticsService.kelimeKayittanCikarildi(word.kelime);
        
        // Kullanıcı giriş yapmışsa buluttan da sil
        if (AuthService().isSignedIn) {
          try {
            await CloudSavedWordsService().removeWordFromCloud(word.kelime);
            debugPrint('✅ SavedWords: Kelime buluttan da silindi: ${word.kelime}');
          } catch (e) {
            debugPrint('⚠️ SavedWords: Buluttan silme hatası: $e');
          }
        }
        
        _operationInProgress.remove(operationKey);
        return true;
      } catch (e) {
        // Database hatası durumunda cache'i geri yükle
        _cachedSavedWords.add(removedWord);
        _savedWordKeys.add(word.kelime);
        notifyListeners();
        _operationInProgress.remove(operationKey);
        return false;
      }
    } catch (e) {
      print('SavedWordsService: Remove error: $e');
      _operationInProgress.remove('remove_${word.kelime}');
      return false;
    }
  }

  // Tüm kayıtlı kelimeleri temizle
  Future<void> clearAllSavedWords() async {
    try {
      print('DEBUG: Tüm kayıtlı kelimeler temizleniyor');
      
      // Temizlenecek kelime sayısını al
      final kelimeSayisi = _cachedSavedWords.length;
      
      // Web platformunda sadece cache'i temizle
      if (_isWebPlatform) {
        _cachedSavedWords = [];
        _savedWordKeys.clear();
        
        // 🚀 PERFORMANCE: Tüm notifier'ları false yap
        for (var notifier in _savedNotifiers.values) {
          notifier.value = false;
        }
        
        // Analytics event'i gönder
        await TurkceAnalyticsService.tumKelimelerTemizlendi(kelimeSayisi);
        
        notifyListeners();
        return;
      }

      final db = await _getDatabase();
      if (db != null) {
        // Database'i temizle
        await db.delete('saved_words');
      }
      
      // Cache'i temizle
      _cachedSavedWords = [];
      _savedWordKeys.clear();
      
      // 🚀 PERFORMANCE: Tüm notifier'ları false yap
      for (var notifier in _savedNotifiers.values) {
        notifier.value = false;
      }
      
      // Analytics event'i gönder
      await TurkceAnalyticsService.tumKelimelerTemizlendi(kelimeSayisi);
      
      // Tüm dinleyicileri bilgilendir
      notifyListeners();
      
      print('DEBUG: Tüm kayıtlı kelimeler başarıyla temizlendi');
    } catch (e) {
      print('DEBUG: Kayıtlı kelimeler temizleme hatası: $e');
    }
  }

  // Kaydedilen kelime sayısını al
  int get savedWordsCount => _cachedSavedWords.length;
  
  // Kaydedilen kelimeleri direkt cache'den al
  List<WordModel> get savedWords => List<WordModel>.from(_cachedSavedWords);

  // Database durumunu kontrol et
  bool get isDatabaseReady => _isWebPlatform || _database != null;
  
  // Test için cache'i sıfırla
  void resetForTesting() {
    _cachedSavedWords = [];
    _savedWordKeys.clear();
    _isInitialized = false;
    
    // 🚀 PERFORMANCE: Notifier'ları temizle
    for (var notifier in _savedNotifiers.values) {
      notifier.dispose();
    }
    _savedNotifiers.clear();
  }

  // Database'i kapat (uygulamadan çıkarken)
  Future<void> closeDatabase() async {
    if (!_isWebPlatform && _database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      print('DEBUG: Database kapatıldı');
    }
  }

  // Kelime listesini yenile (manuel refresh için)
  Future<void> refresh() async {
    final currentUserId = AuthService().userId ?? 'guest';
    
    // Kullanıcı değişmişse database bağlantısını da yenile
    if (_currentUserId != currentUserId) {
      debugPrint('🔄 SavedWords: Refresh sırasında kullanıcı değişikliği tespit edildi');
      _currentUserId = currentUserId;
      
      // Eski database bağlantısını kapat
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
    }
    
    _cachedSavedWords = [];
    _savedWordKeys.clear();
    _isInitialized = false;
    
    // ValueNotifier'ları temizle
    for (var notifier in _savedNotifiers.values) {
      notifier.value = false;
    }
    
    await getSavedWords();
    debugPrint('✅ SavedWords: Refresh tamamlandı (Kullanıcı: $_currentUserId)');
  }
} 