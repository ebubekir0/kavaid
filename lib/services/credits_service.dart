import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'turkce_analytics_service.dart';
import 'one_time_purchase_service.dart';

class CreditsService extends ChangeNotifier {
  bool _isPremium = false; // Genel premium durumu (gelecekte kullanılabilir)
  bool _isLifetimeAdsFree = false; // Reklamları kaldırma durumu
  DateTime? _premiumExpiry;
  bool _cacheLoaded = false;
  
  // Cache keys
  static const String _cacheKey = 'credits_lifetime_ads_free';
  static const String _cacheUserKey = 'credits_cache_user_id';
  static const String _cacheTimestampKey = 'credits_cache_timestamp';
  
  // Singleton instance
  static final CreditsService _instance = CreditsService._internal();
  factory CreditsService() => _instance;
  CreditsService._internal() {
    // Cache yüklemeyi kaldırdık - sadece giriş yapıldığında satın alımlar aktif olmalı
    
    // Auth state değişikliklerini dinle
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        debugPrint('🚪 [CreditsService] Kullanıcı çıkış yaptı - satın alımlar deaktif ediliyor');
        
        // KRİTİK: Kullanıcı giriş yapmamışsa satın alımlar ASLA aktif olmamalı
        _isLifetimeAdsFree = false; // Reklamsız durumu sıfırla
        _isPremium = false; // Premium durumu sıfırla
        _premiumExpiry = null;
        await _clearLocalCache(); // Cache'i temizle
        notifyListeners();
      } else {
        debugPrint('👤 [CreditsService] Kullanıcı girişi tespit edildi: ${user.uid}');
        
        // Farklı kullanıcı girişi kontrolü
        final isValidCache = await _isLocalCacheValidForCurrentUser(user.uid);
        if (!isValidCache) {
          debugPrint('🔄 [CreditsService] Farklı kullanıcı girişi - cache temizleniyor');
          await _clearLocalCache();
          _isLifetimeAdsFree = false; // Reklamsız durumu sıfırla
          _isPremium = false; // Premium durumu sıfırla
          _premiumExpiry = null;
        }
        // Initialize çağrılacak
      }
    });
  }
  
  // Giriş kontrolü
  bool _isUserSignedIn() => FirebaseAuth.instance.currentUser != null;
  String? _getCurrentUserId() => FirebaseAuth.instance.currentUser?.uid;
  
  // Getter'lar - KRİTİK: Giriş yoksa her zaman false
  bool get isPremium {
    // Kullanıcı giriş yapmamışsa ASLA premium değil
    if (!_isUserSignedIn()) {
      return false;
    }
    return _isPremium;
  }
  
  DateTime? get premiumExpiry => _premiumExpiry;
  
  bool get isLifetimeAdsFree {
    // Kullanıcı giriş yapmamışsa ASLA reklamsız değil
    if (!_isUserSignedIn()) {
      return false;
    }
    return _isLifetimeAdsFree;
  }
  
  Future<void> initialize() async {
    debugPrint('🚀 [CreditsService] Initialize başlıyor...');
    
    // KRİTİK: OneTimePurchaseService'ten durumu al
    final oneTimeService = OneTimePurchaseService();
    if (oneTimeService.isLifetimeAdsFree) {
      debugPrint('✓ [CreditsService] OneTimePurchaseService reklamsız durumu tespit edildi');
      _isLifetimeAdsFree = true; // Sadece reklamları kaldırma durumunu güncelle
      _premiumExpiry = DateTime.now().add(const Duration(days: 365 * 100));
      notifyListeners();
      return;
    }
    
    // Giriş yapmamışsa hiçbir şey yapma
    if (!_isUserSignedIn()) {
      debugPrint('❌ [CreditsService] Kullanıcı giriş yapmamış, initialize atlanıyor');
      _isPremium = false;
      _premiumExpiry = null;
      notifyListeners();
      return;
    }
    
    final userId = _getCurrentUserId()!;
    debugPrint('👤 [CreditsService] Kullanıcı ID: $userId');
    
    // Firestore'dan kullanıcı premium durumunu kontrol et
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
           .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        debugPrint('✅ [CreditsService] Kullanıcı verileri bulundu: $data');
        
        // Sadece lifetimeAdsFree kontrol et
        if (data['lifetimeAdsFree'] == true) {
          _isLifetimeAdsFree = true; // Sadece reklamsız durumu
          _premiumExpiry = DateTime.now().add(const Duration(days: 365 * 100)); // 100 yıl
          debugPrint('🔒 [CreditsService] Kullanıcı hesabı reklamsız!');
          // KRİTİK: Cache'e kaydet
          await _saveToCache(true, userId);
        } else {
          _isLifetimeAdsFree = false; // Sadece reklamsız durumu
          _premiumExpiry = null;
          debugPrint('📱 [CreditsService] Kullanıcı hesabı normal');
          // Cache'i temizle
          await _clearLocalCache();
        }
      } else {
        // Kullanıcı belgesi yoksa varsayılan değerler
        _isLifetimeAdsFree = false; // Reklamsız değil
        _isPremium = false; // Premium değil
        _premiumExpiry = null;
        debugPrint('📏 [CreditsService] Yeni kullanıcı, varsayılan değerler atandı');
      }
      
      debugPrint('🎯 [CreditsService] Initialize tamamlandı - isPremium: $_isPremium, isLifetimeAdsFree: $_isLifetimeAdsFree');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ [CreditsService] Initialize hatası: $e');
      _isLifetimeAdsFree = false;
      _isPremium = false;
      _premiumExpiry = null;
      notifyListeners();
    }
  }
  
  // GIZLI KOD: Premium üyelik sonsuza kadar aktifleştir
  Future<void> activatePremiumForever() async {
    if (!_isUserSignedIn()) {
      debugPrint('❌ [CreditsService] Giriş yapılmamış, premium aktifleştirilemez');
      return;
    }
    
     final userEmail = FirebaseAuth.instance.currentUser!.email!.toLowerCase();
     final userId = _getCurrentUserId()!;
    _isPremium = true;
    // 100 yıl sonraya ayarla (pratikte sonsuza kadar)
    _premiumExpiry = DateTime.now().add(const Duration(days: 365 * 100));
    
    try {
      // Firestore'a kullanıcı hesabına kaydet (sadece lifetimeAdsFree)
       await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'lifetimeAdsFree': true,
        'premiumActivatedAt': FieldValue.serverTimestamp(),
        'premiumType': 'gizli_kod',
        'email': userEmail,
      }, SetOptions(merge: true));
      
      debugPrint('✅ [CreditsService] Premium hesaba başarıyla aktifleştirildi');
      
      // KRİTİK: Cache'e kaydet
      await _saveToCache(true, userId);
      
      // Analytics user properties'ini güncelle
      await TurkceAnalyticsService.kullaniciOzellikleriniGuncelle(premiumMu: _isPremium);
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [CreditsService] Premium aktifleştirme hatası: $e');
    }
  }
  
  // GIZLI KOD: Premium durumunu toggle et (premium ise free yap, free ise premium yap)
  Future<bool> togglePremiumStatus() async {
    if (isPremium) {
      // Premium'dan free'ye geç
      await cancelPremium();
      return false; // Artık free
    } else {
      // Free'den premium'a geç
      await activatePremiumForever();
      return true; // Artık premium
    }
  }
  
  // Premium'u iptal et (test için)
  Future<void> cancelPremium() async {
    if (!_isUserSignedIn()) {
      debugPrint('❌ [CreditsService] Giriş yapılmamış, premium iptal edilemez');
      return;
    }
    
    final userId = _getCurrentUserId()!;
    _isPremium = false;
    _premiumExpiry = null;
    
    try {
      // Firestore'dan premium durumunu kaldır (sadece lifetimeAdsFree)
       await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'lifetimeAdsFree': false,
      });
      
      debugPrint('✅ [CreditsService] Premium iptal edildi');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [CreditsService] Premium iptal hatası: $e');
    }
  }

  // KRİTİK: Bu metod sadece local state güncellemeli
  // Firestore'a dokunmamalı ve local cache'i silmemeli
  Future<void> setLifetimeAdsFree(bool value) async {
    debugPrint(' [CreditsService] setLifetimeAdsFree çağrıldı: $value');
    
    // Sadece reklamsız durumu güncelle (_isPremium DEĞİL!)
    _isLifetimeAdsFree = value;
    if (value) {
      _premiumExpiry = DateTime.now().add(const Duration(days: 365 * 100));
      debugPrint(' [CreditsService] Local reklamsız state: TRUE');
      
      // KRİTİK: Cache'e de kaydet (OneTimePurchaseService'ten çağrıldığında)
      final userId = _getCurrentUserId();
      if (userId != null) {
        await _saveToCache(true, userId);
      }
    } else {
      _premiumExpiry = null;
      debugPrint(' [CreditsService] Local reklamsız state: FALSE');
      // Value false ise cache temizleme, auth state değişikliğinde zaten kontrol edilecek
    }
    
    // UI'ı güncelle
    notifyListeners();
    
    // KRİTİK: Firestore'a dokunma!
    // Bu metod sadece diğer servislerle senkronizasyon için
  }

  Future<void> activatePremiumMonthly() async {
    // Artık aylık premium yok, direkt lifetime yap
    await activatePremiumForever();
  }

  Future<void> checkPremiumStatus() async {
    // Premium durumu kontrol et
    await initialize();
  }

  // Kelime açma kontrolü - premium yoksa hep true
  Future<bool> canOpenWord(String kelime) async {
    return true; // Premium sistem yok, herkese açık
  }

  // Kredi tüketme - premium yoksa hep true
  Future<bool> consumeCredit(String kelime) async {
    return true; // Premium sistem yok, kredi tüketme yok
  }

  // Eski sistemle uyumluluk için eksik getter'lar
  int get credits => 999; // Premium sistem yok, sınırsız
  bool get hasInitialCredits => true; // Premium sistem yok, hep true
  
  // Test için eksik metod
  Future<void> toggleAdsFreeForTest() async {
    await togglePremiumStatus();
  }
  
  // Cache'den premium durumu yükle
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedValue = prefs.getBool(_cacheKey);
      final cachedUserId = prefs.getString(_cacheUserKey);
      final cachedTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cachedValue != null && cachedValue == true) {
        final cacheAge = cachedTimestamp != null 
            ? DateTime.now().millisecondsSinceEpoch - cachedTimestamp
            : 999999999;
        final cacheDays = cacheAge / (1000 * 60 * 60 * 24);
        
        debugPrint('💾 [CreditsService] Cache bulundu: Premium=$cachedValue, User=$cachedUserId, ${cacheDays.toStringAsFixed(1)} gün önce');
        
        // 30 günden eskiyse geçersiz say
        if (cacheDays > 30) {
          debugPrint('⏰ [CreditsService] Cache çok eski, geçersiz');
          _cacheLoaded = false;
          return;
        }
        
        _isLifetimeAdsFree = cachedValue; // Reklamsız durumu cache'den yükle
        _premiumExpiry = DateTime.now().add(const Duration(days: 365 * 100));
        _cacheLoaded = true;
        debugPrint('✅ [CreditsService] Cache\'den reklamsız durumu yüklendi');
      } else {
        _cacheLoaded = false;
        debugPrint('❌ [CreditsService] Cache\'de premium durumu yok');
      }
    } catch (e) {
      debugPrint('⚠️ [CreditsService] Cache okuma hatası: $e');
      _cacheLoaded = false;
    }
  }
  
  // Cache'e premium durumu kaydet
  Future<void> _saveToCache(bool isPremium, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKey, isPremium);
      await prefs.setString(_cacheUserKey, userId);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('💾 [CreditsService] Cache kaydedildi: Premium=$isPremium, User=$userId');
      _cacheLoaded = true;
    } catch (e) {
      debugPrint('❌ [CreditsService] Cache kayıt hatası: $e');
    }
  }
  
  // Cache'in mevcut kullanıcı için geçerli olup olmadığını kontrol et
  Future<bool> _isLocalCacheValidForCurrentUser(String? currentUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString(_cacheUserKey);
      final cachedValue = prefs.getBool(_cacheKey);
      
      // Cache yoksa geçersiz
      if (cachedValue != true || cachedUserId == null) {
        debugPrint('❌ [CreditsService] Cache yok veya negatif');
        return false;
      }
      
      // Kullanıcı null (çıkış) ama cache var - GEÇİCİ auth null olabilir
      if (currentUserId == null) {
        debugPrint('🤔 [CreditsService] Auth null ama cache var (User: $cachedUserId) - geçici koruma');
        return true; // Geçici koruma sağla
      }
      
      // Kullanıcı ID'leri aynı mı?
      final isValid = cachedUserId == currentUserId;
      if (isValid) {
        debugPrint('✅ [CreditsService] Cache geçerli - aynı kullanıcı ($currentUserId)');
      } else {
        debugPrint('❌ [CreditsService] Cache geçersiz - farklı kullanıcı (Cache: $cachedUserId, Current: $currentUserId)');
      }
      
      return isValid;
    } catch (e) {
      debugPrint('⚠️ [CreditsService] Cache geçerlilik kontrol hatası: $e');
      return false;
    }
  }
  
  // Cache'i temizle
  Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheUserKey);
      await prefs.remove(_cacheTimestampKey);
      _cacheLoaded = false;
      debugPrint('🧹 [CreditsService] Cache temizlendi');
    } catch (e) {
      debugPrint('❌ [CreditsService] Cache temizleme hatası: $e');
    }
  }
}