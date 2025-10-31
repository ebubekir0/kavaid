import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Note: Book purchases are independent from lifetime ads entitlement.

class BookInfo {
  final String id;
  final String title;
  final String subtitle;
  final String priceText;
  final String imageBase; // assets/images/<base>.(jpg|png)

  BookInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceText,
    required this.imageBase,
  });

  String get imageAsset => '$imageBase.jpg';
}

class BookStoreService extends ChangeNotifier {
  static final BookStoreService _instance = BookStoreService._internal();
  factory BookStoreService() => _instance;
  BookStoreService._internal() {
    // React to auth changes so UI updates according to account state
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        debugPrint('🚪 [BookStore] Kullanıcı çıkış yaptı - kitap satın almaları deaktif ediliyor');
        
        // KRİTİK: Kullanıcı giriş yapmamışsa kitaplar ASLA aktif olmamalı
        _purchasedBookIds = <String>{};
        _loaded = true;
        await _clearLocalCache(); // Cache'i temizle
        notifyListeners();
        return;
      }
      // Signed in: reset and load account entitlements
      _loaded = false;
      _purchasedBookIds = <String>{};
      await initialize();
      await _applyEntitlementFromAccount();
    });
    // No dependency on OneTimePurchaseService for book unlocks
  }

  static final List<BookInfo> books = [
    BookInfo(
      id: 'kitab_kiraah_1',
      title: 'Kitabul Kıraat 1 Kelimeleri',
      subtitle: 'Başlangıç seviye',
      priceText: 'Satın Al',
      imageBase: 'assets/images/kitab_kiraah_1',
    ),
    BookInfo(
      id: 'kitab_kiraah_2',
      title: 'Kitabul Kıraat 2 Kelimeleri',
      subtitle: 'Orta seviye',
      priceText: 'Satın Al',
      imageBase: 'assets/images/kitab_kiraah_2',
    ),
    BookInfo(
      id: 'kitab_kiraah_3',
      title: 'Kitabul Kıraat 3 Kelimeleri',
      subtitle: 'İleri seviye',
      priceText: 'Satın Al',
      imageBase: 'assets/images/kitab_kiraah_3',
    ),
  ];

  Set<String> _purchasedBookIds = <String>{};
  bool _loaded = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  String get _prefsKey => 'purchased_books_$_uid';

  Future<void> initialize() async {
    if (_loaded) return;
    
    // Önce cache'den yüklemeyi dene
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('${_prefsKey}_user_id');
      final currentUserId = _uid;
      
      // Cache kullanıcı ID kontrolü
      if (cachedUserId != null && currentUserId != 'guest') {
        if (cachedUserId == currentUserId) {
          // Aynı kullanıcı, cache'den yükle
          final list = prefs.getStringList(_prefsKey) ?? <String>[];
          _purchasedBookIds = list.toSet();
          _loaded = true;
          debugPrint('📚 [BookStore] Cache\'den yüklendi (User: $cachedUserId): $_purchasedBookIds');
        } else {
          // Farklı kullanıcı, cache'i temizle
          debugPrint('🔄 [BookStore] Farklı kullanıcı tespit edildi, cache temizleniyor');
          await _clearLocalCache();
          _purchasedBookIds = <String>{};
          _loaded = true;
        }
      } else {
        // Cache yok veya guest kullanıcı
        final list = prefs.getStringList(_prefsKey) ?? <String>[];
        _purchasedBookIds = list.toSet();
        _loaded = true;
      }
    } catch (e) {
      debugPrint('❌ [BookStore] Initialize error: $e');
      _purchasedBookIds = <String>{};
      _loaded = true;
    }
    notifyListeners();
  }

  bool isPurchased(String bookId) {
    // Artık tüm kitaplar ücretli
    return _purchasedBookIds.contains(bookId);
  }

  Future<void> mockPurchase(String bookId) async {
    await initialize();
    _purchasedBookIds.add(bookId);
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        // Kullanıcı ID'si ile birlikte cache'e kaydet
        await _saveToCache(uid);
        
        // Also mirror to Firestore under the account
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'purchasedBooks': _purchasedBookIds.toList(),
        }, SetOptions(merge: true));
        
        debugPrint('✅ [BookStore] Kitap satın alması kaydedildi: $bookId (User: $uid)');
      } catch (e) {
        debugPrint('❌ [BookStore] Save purchase error: $e');
      }
    } else {
      debugPrint('❌ [BookStore] Kullanıcı giriş yapmamış, satın alma kaydedilemedi');
    }
    notifyListeners();
  }

  Future<void> removePurchase(String bookId) async {
    await initialize();
    _purchasedBookIds.remove(bookId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _purchasedBookIds.toList());
      // Mirror to Firestore as well if signed in
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'purchasedBooks': _purchasedBookIds.toList(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('❌ [BookStore] Remove purchase error: $e');
    }
    notifyListeners();
  }

  Future<void> _applyEntitlementFromAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        notifyListeners();
        return;
      }
      
      // Yeni kullanıcı giriş yaptığında cache geçerliliğini kontrol et
      final isValidCache = await _isLocalCacheValidForCurrentUser(user.uid);
      if (!isValidCache) {
        debugPrint('🔄 [BookStore] Farklı kullanıcı girişi - cache temizleniyor');
        await _clearLocalCache();
      } else if (_loaded && _purchasedBookIds.isNotEmpty) {
        // Cache geçerliyse ve kitaplar varsa, mevcut durumu koru
        debugPrint('📚 [BookStore] Cache geçerli, mevcut kitaplar korunuyor: $_purchasedBookIds');
        return; // Firestore kontrolü yapma
      }
      
      // Firestore'dan kontrol et (retry mekanizması ile)
      int retryCount = 0;
      while (retryCount < 3) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final data = doc.data() ?? {};
          final List<dynamic>? arr = data['purchasedBooks'] as List<dynamic>?;
          if (arr != null) {
            _purchasedBookIds = arr.map((e) => e.toString()).toSet();
            debugPrint('✅ [BookStore] Firestore\'dan kitaplar yüklendi: $_purchasedBookIds');
          } else {
            debugPrint('📝 [BookStore] Firestore\'da kitap bulunamadı');
          }
          
          // Kullanıcı ID'si ile birlikte cache'e kaydet
          await _saveToCache(user.uid);
          notifyListeners();
          return; // Başarılı, çık
          
        } catch (e) {
          retryCount++;
          debugPrint('⚠️ [BookStore] Firestore okuma hatası (Deneme $retryCount/3): $e');
          
          if (retryCount < 3) {
            await Future.delayed(Duration(seconds: retryCount * 2));
          } else {
            // Tüm denemeler başarısız, cache'den devam et
            debugPrint('🔌 [BookStore] İnternet sorunu olabilir, cache\'den devam ediliyor');
            await _loadFromCache();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [BookStore] Apply entitlement error: $e');
    }
  }

  // Local cache'in mevcut kullanıcı için geçerli olup olmadığını kontrol et
  Future<bool> _isLocalCacheValidForCurrentUser(String? currentUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('${_prefsKey}_user_id');
      final cachedBooks = prefs.getStringList(_prefsKey);
      
      // Cache yoksa geçersiz
      if (cachedBooks == null || cachedBooks.isEmpty || cachedUserId == null) {
        debugPrint('❌ [BookStore] Cache yok veya boş');
        return false;
      }
      
      // Kullanıcı null (çıkış) ama cache var - GEÇİCİ auth null olabilir
      if (currentUserId == null) {
        debugPrint('🤔 [BookStore] Auth null ama cache var (User: $cachedUserId) - geçici koruma');
        return true; // Geçici koruma sağla
      }
      
      // Kullanıcı ID'leri aynı mı?
      final isValid = cachedUserId == currentUserId;
      if (isValid) {
        debugPrint('✅ [BookStore] Cache geçerli - aynı kullanıcı ($currentUserId)');
      } else {
        debugPrint('❌ [BookStore] Cache geçersiz - farklı kullanıcı (Cache: $cachedUserId, Current: $currentUserId)');
      }
      
      return isValid;
    } catch (e) {
      debugPrint('⚠️ [BookStore] Cache geçerlilik kontrol hatası: $e');
      return false;
    }
  }

  // Cache'den kitapları yükle
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedBooks = prefs.getStringList(_prefsKey) ?? <String>[];
      _purchasedBookIds = cachedBooks.toSet();
      _loaded = true;
      debugPrint('📚 [BookStore] Cache\'den kitaplar yüklendi: $cachedBooks');
    } catch (e) {
      debugPrint('⚠️ [BookStore] Cache yükleme hatası: $e');
      _purchasedBookIds = <String>{};
      _loaded = true;
    }
  }

  // Kullanıcı ID'si ile birlikte cache'e kaydet
  Future<void> _saveToCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _purchasedBookIds.toList());
      await prefs.setString('${_prefsKey}_user_id', userId);
      debugPrint('💾 [BookStore] Cache kaydedildi: ${_purchasedBookIds.toList()} (User: $userId)');
    } catch (e) {
      debugPrint('❌ [BookStore] Cache kayıt hatası: $e');
    }
  }

  // Local cache'i tamamen temizle
  Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await prefs.remove('${_prefsKey}_user_id');
      debugPrint('🧹 [BookStore] Local cache tamamen temizlendi');
    } catch (e) {
      debugPrint('❌ [BookStore] Cache temizleme hatası: $e');
    }
  }
}


