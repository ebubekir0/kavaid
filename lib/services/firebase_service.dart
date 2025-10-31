import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/word_model.dart';

class FirebaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final DatabaseReference _wordsRef = _database.ref().child('kelimeler');

  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Cache için
  static Map<String, List<WordModel>>? _cachedData;
  static DateTime? _lastCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  // Cache'i temizle
  static void clearCache() {
    _cachedData = null;
    _lastCacheTime = null;
    debugPrint('🗑️ Cache temizlendi');
  }

  // Helper fonksiyonlar - Type casting için
  static Map<String, dynamic>? _safeCastMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value.map((k, v) => MapEntry(k.toString(), v)));
    }
    return null;
  }

  static List<Map<String, dynamic>>? _safeCastList(dynamic value) {
    if (value == null) return null;
    if (value is List<Map<String, dynamic>>) return value;
    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) return item;
        if (item is Map) {
          return Map<String, dynamic>.from(item.map((k, v) => MapEntry(k.toString(), v)));
        }
        return <String, dynamic>{};
      }).toList();
    }
    return null;
  }

  // Kelime arama - HomeScreen için (hızlandırılmış)
  Future<List<WordModel>> searchWords(String query, {int limit = 999}) async {
    return await searchWordsInDatabase(query, limit: limit);
  }

  // Hızlandırılmış kelime arama
  Future<List<WordModel>> searchWordsInDatabase(String query, {int limit = 999}) async {
    if (query.isEmpty) return [];

    try {
      // Cache kontrolü - Yeni kelime eklendiğinde cache'i atla
      final now = DateTime.now();
      if (_cachedData != null && 
          _lastCacheTime != null && 
          now.difference(_lastCacheTime!).compareTo(_cacheTimeout) < 0) {
        debugPrint('📦 Cache\'den arama yapılıyor');
        return _searchInCache(query, limit: limit);
      }
      
      debugPrint('🔍 Firebase\'den fresh arama yapılıyor');

      final snapshot = await _wordsRef.get();
      
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final words = <WordModel>[];
      final results = <WordModel>[];

      // Yeni yapıya göre parsing ve arama
      for (final entry in data.entries) {
        try {
          final key = entry.key.toString(); // Harekeli kelime key olarak
          final value = entry.value;
          
          if (value != null && value is Map) {
            final wordData = Map<String, dynamic>.from(value.map((k, v) => MapEntry(k.toString(), v)));
            
            // Yeni yapıya uygun WordModel oluştur
            WordModel word;
            if (wordData.containsKey('kelimeBilgisi')) {
              // Eski format uyumluluğu
              word = WordModel.fromJson(wordData);
            } else {
              // Yeni format - direkt kelime bilgileri
              word = WordModel(
                kelime: wordData['kelime'] ?? key,
                harekeliKelime: wordData['harekeliKelime'] ?? key,
                anlam: wordData['anlam'],
                koku: wordData['koku'],
                dilbilgiselOzellikler: _safeCastMap(wordData['dilbilgiselOzellikler']),
                ornekCumleler: _safeCastList(wordData['ornekCumleler']),
                fiilCekimler: _safeCastMap(wordData['fiilCekimler']),
                eklenmeTarihi: wordData['eklenmeTarihi'],
                bulunduMu: true,
              );
            }
            
            words.add(word);
            
            // Sadece başlangıç eşleşmeleri - kelime başında olmalı
            final lowerQuery = query.toLowerCase();
            final lowerKelime = word.kelime.toLowerCase();
            final lowerHarekeli = word.harekeliKelime?.toLowerCase() ?? '';
            final lowerAnlam = word.anlam?.toLowerCase() ?? '';
            final lowerKey = key.toLowerCase(); // Key'i de kontrol et
            
            if (lowerKelime.startsWith(lowerQuery) || 
                lowerHarekeli.startsWith(lowerQuery) ||
                lowerKey.startsWith(lowerQuery) ||
                _checkMeaningStartsWith(lowerAnlam, lowerQuery)) { // Tüm anlamları kontrol et
              results.add(word);
              
              // Limit kontrolü
              if (results.length >= limit) break;
            }
          }
        } catch (e) {
          debugPrint('Kelime parse hatası: $e');
          // Hata durumunda devam et
          continue;
        }
      }

      // Cache'i güncelle
      _cachedData = {'all': words};
      _lastCacheTime = now;

      // Hızlı sıralama - sadece score hesapla
      results.sort((a, b) => 
        b.searchScore(query).compareTo(a.searchScore(query)));

      return results;
    } catch (e) {
      print('Firebase arama hatası: $e');
      return [];
    }
  }

  // Cache'de arama
  List<WordModel> _searchInCache(String query, {int limit = 999}) {
    if (_cachedData == null) return [];
    
    final allWords = _cachedData!['all'] ?? [];
    final results = <WordModel>[];
    final lowerQuery = query.toLowerCase();

    for (final word in allWords) {
      final lowerKelime = word.kelime.toLowerCase();
      final lowerHarekeli = word.harekeliKelime?.toLowerCase() ?? '';
      final lowerAnlam = word.anlam?.toLowerCase() ?? '';
      
      if (lowerKelime.startsWith(lowerQuery) || 
          lowerHarekeli.startsWith(lowerQuery) ||
          _checkMeaningStartsWith(lowerAnlam, lowerQuery)) { // Tüm anlamları kontrol et
        results.add(word);
        
        if (results.length >= limit) break;
      }
    }

    results.sort((a, b) => 
      b.searchScore(query).compareTo(a.searchScore(query)));

    return results;
  }

  // Öneriler için hızlı arama (debounce ile her harf girişinde)
  Stream<List<WordModel>> getSuggestions(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }

    return _wordsRef
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return <WordModel>[];

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final suggestions = <WordModel>[];

      data.forEach((key, value) {
        try {
          final keyStr = key.toString(); // Harekeli kelime key olarak
          
          if (value != null && value is Map) {
            final wordData = Map<String, dynamic>.from(value.map((k, v) => MapEntry(k.toString(), v)));
            
            // Yeni yapıya uygun WordModel oluştur
            WordModel word;
            if (wordData.containsKey('kelimeBilgisi')) {
              // Eski format uyumluluğu
              word = WordModel.fromJson(wordData);
            } else {
              // Yeni format - direkt kelime bilgileri
              word = WordModel(
                kelime: wordData['kelime'] ?? keyStr,
                harekeliKelime: wordData['harekeliKelime'] ?? keyStr,
                anlam: wordData['anlam'],
                koku: wordData['koku'],
                dilbilgiselOzellikler: _safeCastMap(wordData['dilbilgiselOzellikler']),
                ornekCumleler: _safeCastList(wordData['ornekCumleler']),
                fiilCekimler: _safeCastMap(wordData['fiilCekimler']),
                eklenmeTarihi: wordData['eklenmeTarihi'],
                bulunduMu: true,
              );
            }
            
            // Sadece başlangıç eşleşmeleri
            final kelimeMatch = word.kelime.toLowerCase().startsWith(query.toLowerCase());
            final harekeliMatch = word.harekeliKelime?.toLowerCase().startsWith(query.toLowerCase()) ?? false;
            final keyMatch = keyStr.toLowerCase().startsWith(query.toLowerCase());
            final anlamMatch = _checkMeaningStartsWith(word.anlam?.toLowerCase() ?? '', query.toLowerCase()); // Tüm anlamları kontrol et
            
            if (kelimeMatch || harekeliMatch || keyMatch || anlamMatch) {
              suggestions.add(word);
            }
          }
        } catch (e) {
          debugPrint('Öneri parse hatası: $e');
        }
      });

      // Arama skoruna göre sırala ve sınırla
      suggestions.sort((a, b) => 
        b.searchScore(query).compareTo(a.searchScore(query)));

      return suggestions.take(5).toList();
    });
  }

  // Yeni kelime kaydet
  Future<bool> saveWord(WordModel word) async {
    try {
      // Sadece bulunmuş kelimeleri kaydet
      if (!word.bulunduMu) return false;

      // Kelime zaten var mı kontrol et
      final existingWord = await getWordByName(word.kelime);
      if (existingWord != null) {
        print('Kelime zaten mevcut: ${word.kelime}');
        return true;
      }

      // Yeni kelime ID'si oluştur
      final newWordRef = _wordsRef.push();
      
      // Firebase'e kaydet
      await newWordRef.set(word.toFirebaseJson());
      
      // Cache'i temizle - yeni kelime eklendiği için
      clearCache();
      
      print('Kelime kaydedildi: ${word.kelime}');
      return true;
    } catch (e) {
      print('Kelime kaydetme hatası: $e');
      return false;
    }
  }

  // Kelimeyi isimle getir - geniş arama (kelime, harekeli, anlam)
  Future<WordModel?> getWordByName(String wordName) async {
    try {
      final snapshot = await _wordsRef.get();
      
      if (!snapshot.exists) return null;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final searchTerm = wordName.toLowerCase().trim();
      
      debugPrint('🔍 Firebase\'de aranıyor: $searchTerm');
      
      // Tüm kelimeleri kontrol et
      for (final entry in data.entries) {
        try {
          final key = entry.key.toString(); // Harekeli kelime key olarak
          final value = entry.value;
          
          if (value != null && value is Map) {
            final wordData = Map<String, dynamic>.from(value.map((k, v) => MapEntry(k.toString(), v)));
            
            // Yeni yapıya uygun WordModel oluştur
            WordModel word;
            if (wordData.containsKey('kelimeBilgisi')) {
              // Eski format uyumluluğu
              word = WordModel.fromJson(wordData);
            } else {
              // Yeni format - direkt kelime bilgileri
              word = WordModel(
                kelime: wordData['kelime'] ?? key,
                harekeliKelime: wordData['harekeliKelime'] ?? key,
                anlam: wordData['anlam'],
                koku: wordData['koku'],
                dilbilgiselOzellikler: _safeCastMap(wordData['dilbilgiselOzellikler']),
                ornekCumleler: _safeCastList(wordData['ornekCumleler']),
                fiilCekimler: _safeCastMap(wordData['fiilCekimler']),
                eklenmeTarihi: wordData['eklenmeTarihi'],
                bulunduMu: true,
              );
            }
            
            // Geniş arama: kelime, harekeli kelime, key ve anlam kontrolü
            bool found = false;
            
            // 1. Kelime tam eşleşmesi
            if (word.kelime.toLowerCase() == searchTerm ||
                word.harekeliKelime?.toLowerCase() == searchTerm ||
                key.toLowerCase() == searchTerm) {
              found = true;
            }
            
            // 2. Anlam kontrolü - Türkçe kelime aranıyorsa anlamlar içinde ara
            if (!found && word.anlam != null && word.anlam!.isNotEmpty) {
              final anlam = word.anlam!.toLowerCase();
              
              // Tam eşleşme
              if (anlam == searchTerm) {
                found = true;
              } else {
                // Anlamları ayır ve kontrol et (virgül, noktalı virgül, nokta ile ayrılmış)
                final anlamlar = anlam
                    .split(RegExp(r'[,;.\n]'))
                    .map((m) => m.trim())
                    .where((m) => m.isNotEmpty)
                    .toList();
                
                for (final anlamParcasi in anlamlar) {
                  if (anlamParcasi == searchTerm) {
                    found = true;
                    break;
                  }
                }
              }
            }
            
            if (found) {
              debugPrint('✅ Firebase\'de kelime bulundu: ${word.kelime}');
              return word;
            }
          }
        } catch (e) {
          debugPrint('Kelime kontrol hatası: $e');
        }
      }
      
      debugPrint('❌ Firebase\'de kelime bulunamadı: $searchTerm');
      return null;
    } catch (e) {
      print('Kelime getirme hatası: $e');
      return null;
    }
  }

  // Son eklenen kelimeleri getir
  Future<List<WordModel>> getRecentWords({int limit = 10}) async {
    try {
      final snapshot = await _wordsRef.get();

      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final words = <WordModel>[];

      data.forEach((key, value) {
        try {
          final keyStr = key.toString(); // Harekeli kelime key olarak
          
          if (value != null && value is Map) {
            final wordData = Map<String, dynamic>.from(value.map((k, v) => MapEntry(k.toString(), v)));
            
            // Yeni yapıya uygun WordModel oluştur
            WordModel word;
            if (wordData.containsKey('kelimeBilgisi')) {
              // Eski format uyumluluğu
              word = WordModel.fromJson(wordData);
            } else {
              // Yeni format - direkt kelime bilgileri
              word = WordModel(
                kelime: wordData['kelime'] ?? keyStr,
                harekeliKelime: wordData['harekeliKelime'] ?? keyStr,
                anlam: wordData['anlam'],
                koku: wordData['koku'],
                dilbilgiselOzellikler: _safeCastMap(wordData['dilbilgiselOzellikler']),
                ornekCumleler: _safeCastList(wordData['ornekCumleler']),
                fiilCekimler: _safeCastMap(wordData['fiilCekimler']),
                eklenmeTarihi: wordData['eklenmeTarihi'],
                bulunduMu: true,
              );
            }
            
            words.add(word);
          }
        } catch (e) {
          debugPrint('Son kelime parse hatası: $e');
        }
      });

      // Ekleme tarihine göre sırala (en yeni önce)
      words.sort((a, b) {
        final aTime = a.eklenmeTarihi ?? 0;
        final bTime = b.eklenmeTarihi ?? 0;
        return bTime.compareTo(aTime);
      });

      return words.take(limit).toList();
    } catch (e) {
      print('Son kelimeler getirme hatası: $e');
      return [];
    }
  }

  // Toplam kelime sayısını getir
  Future<int> getTotalWordCount() async {
    try {
      final snapshot = await _wordsRef.get();
      if (!snapshot.exists) return 0;
      
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.length;
    } catch (e) {
      print('Kelime sayısı getirme hatası: $e');
      return 0;
    }
  }

  // Database bağlantısını test et
  Future<bool> testConnection() async {
    try {
      await _wordsRef.limitToFirst(1).get();
      return true;
    } catch (e) {
      print('Firebase bağlantı testi hatası: $e');
      return false;
    }
  }

  // Database'den rastgele kelime getir
  Future<List<WordModel>> getRandomWords({int count = 5}) async {
    try {
      final snapshot = await _wordsRef.limitToFirst(20).get();

      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final words = <WordModel>[];

      data.forEach((key, value) {
        try {
          final keyStr = key.toString(); // Harekeli kelime key olarak
          
          if (value != null && value is Map) {
            final wordData = Map<String, dynamic>.from(value.map((k, v) => MapEntry(k.toString(), v)));
            
            // Yeni yapıya uygun WordModel oluştur
            WordModel word;
            if (wordData.containsKey('kelimeBilgisi')) {
              // Eski format uyumluluğu
              word = WordModel.fromJson(wordData);
            } else {
              // Yeni format - direkt kelime bilgileri
              word = WordModel(
                kelime: wordData['kelime'] ?? keyStr,
                harekeliKelime: wordData['harekeliKelime'] ?? keyStr,
                anlam: wordData['anlam'],
                koku: wordData['koku'],
                dilbilgiselOzellikler: _safeCastMap(wordData['dilbilgiselOzellikler']),
                ornekCumleler: _safeCastList(wordData['ornekCumleler']),
                fiilCekimler: _safeCastMap(wordData['fiilCekimler']),
                eklenmeTarihi: wordData['eklenmeTarihi'],
                bulunduMu: true,
              );
            }
            
            words.add(word);
          }
        } catch (e) {
          debugPrint('Rastgele kelime parse hatası: $e');
        }
      });

      // Karıştır ve istenilen sayıda döndür
      words.shuffle();
      return words.take(count).toList();
    } catch (e) {
      print('Rastgele kelimeler getirme hatası: $e');
      return [];
    }
  }

  // Anlam eşleşmesi kontrolü - tüm anlamları kontrol eder
  bool _checkMeaningStartsWith(String meanings, String query) {
    if (meanings.isEmpty || query.isEmpty) return false;
    
    // Anlamları ayır (virgül, noktalı virgül, satır sonu ile)
    final meaningList = meanings
        .split(RegExp(r'[,;.\n]'))
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();
    
    for (final meaning in meaningList) {
      if (meaning.startsWith(query)) return true;
    }
    
    return false;
  }

  // ============== SYNC METOTLARI ==============

  Future<Set<String>> getExistingWordKeys() async {
    final snapshot = await _wordsRef.get();
    if (!snapshot.exists) return {};
    
    final data = snapshot.value as Map<dynamic, dynamic>;
    final keys = <String>{};
    for (final value in data.values) {
      if (value != null && value is Map) {
        // Kullanıcının isteği üzerine, bir kelimenin varlığını
        // sadece 'harekeliKelime' alanına göre kontrol ediyoruz.
        if (value['harekeliKelime'] != null) {
          keys.add(value['harekeliKelime'] as String);
        }
      }
    }
    return keys;
  }

  Future<void> batchAddWords(List<WordModel> words) async {
    if (words.isEmpty) return;

    // Realtime Database için multi-path update oluştur
    final Map<String, dynamic> updates = {};
    for (final word in words) {
      // Her kelime için Firebase'den yeni bir benzersiz anahtar al
      final newWordKey = _wordsRef.push().key;
      if (newWordKey != null) {
        updates[newWordKey] = word.toFirebaseJson();
      }
    }
    
    if (updates.isNotEmpty) {
      await _wordsRef.update(updates);
      clearCache(); // Yeni kelimeler eklendiği için cache'i temizle
    }
  }

  Future<void> recalculateAndSetTotalWordsCount() async {
    try {
      final count = await getTotalWordCount();
      await _database.ref().child('stats').child('kelime_sayisi').set(count);
      debugPrint('Firebase\'deki /stats/kelime_sayisi güncellendi: $count');
    } catch (e) {
      debugPrint('❌ Firebase kelime sayacı güncellenirken hata: $e');
    }
  }

  // Tüm kelimeleri Firebase'den çekmek için yeni fonksiyon
  Future<List<WordModel>> getAllWordsFromFirebase() async {
    try {
      final snapshot = await _wordsRef.get();
      
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final words = <WordModel>[];

      for (final entry in data.entries) {
        try {
          final key = entry.key.toString();
          final value = entry.value;
          
          if (value != null && value is Map) {
            final wordData = Map<String, dynamic>.from(value.map((k, v) => MapEntry(k.toString(), v)));
            
            WordModel word;
            if (wordData.containsKey('kelimeBilgisi')) {
              word = WordModel.fromJson(wordData);
            } else {
              word = WordModel(
                kelime: wordData['kelime'] ?? key,
                harekeliKelime: wordData['harekeliKelime'] ?? key,
                anlam: wordData['anlam'],
                koku: wordData['koku'],
                dilbilgiselOzellikler: _safeCastMap(wordData['dilbilgiselOzellikler']),
                ornekCumleler: _safeCastList(wordData['ornekCumleler']),
                fiilCekimler: _safeCastMap(wordData['fiilCekimler']),
                eklenmeTarihi: wordData['eklenmeTarihi'],
                bulunduMu: true,
              );
            }
            words.add(word);
          }
        } catch (e) {
          debugPrint('Kelime parse hatası (getAllWordsFromFirebase): $e');
          continue;
        }
      }
      debugPrint('Firebase\'den toplam ${words.length} kelime çekildi.');
      return words;
    } catch (e) {
      print('Tüm kelimeleri Firebase\'den çekerken hata: $e');
      return [];
    }
  }
} 