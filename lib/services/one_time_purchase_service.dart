import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_data_service.dart';
import 'credits_service.dart';
import 'turkce_analytics_service.dart';
import 'admob_service.dart';

class OneTimePurchaseService extends ChangeNotifier {
  static const String _removeAdsProductId = 'kavaid_remove_ads_lifetime';
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final DeviceDataService _deviceDataService = DeviceDataService();
  final CreditsService _creditsService = CreditsService();
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String _lastError = '';
  bool _isLifetimeAdsFree = false;
  bool _isLoadingProducts = false; // Ürün yükleme kontrolü
  bool _isInitialized = false; // Initialize kontrolü
  DateTime? _lastFirestoreCheck; // Son Firestore kontrol zamanı
  static const Duration _firestoreCacheDuration = Duration(minutes: 5); // Cache süresi
  static const String _localCacheKey = 'lifetime_ads_free_cache'; // SharedPreferences key
  static const String _localCacheTimestampKey = 'lifetime_ads_free_timestamp'; // Cache timestamp

  // Singleton
  static final OneTimePurchaseService _instance = OneTimePurchaseService._internal();
  factory OneTimePurchaseService() => _instance;
  OneTimePurchaseService._internal() {
    // Keep entitlement in sync with account login/logout
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        debugPrint('🚪 [OneTimePurchase] Kullanıcı çıkış yaptı - reklamsız durum deaktif ediliyor');
        
        // KRİTİK: Kullanıcı giriş yapmamışsa reklamsız özellik ASLA aktif olmamalı
        _isLifetimeAdsFree = false;
        await _creditsService.setLifetimeAdsFree(false);
        await _clearLocalCache(); // Cache'i temizle
        notifyListeners();
        return;
      }
      
      debugPrint('👤 [OneTimePurchase] Kullanıcı girişi tespit edildi: ${user.uid}');
      
      // Yeni kullanıcı giriş yaptığında cache geçerliliğini kontrol et
      final isValidCache = await _isLocalCacheValidForCurrentUser(user.uid);
      if (!isValidCache) {
        debugPrint('🔄 [OneTimePurchase] Farklı kullanıcı girişi - cache temizleniyor');
        await _clearLocalCache();
      }
      
      // Firestore'dan reklamsız durumu kontrol et (retry mekanizması ile)
      await _checkLifetimeFromFirestore(user.uid, retryCount: 3);
    });
  }
  
  // Getter'lar
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  List<ProductDetails> get products => _products;
  String get removeAdsPrice => _getRemoveAdsPrice();
  String get lastError => _lastError;
  bool get hasError => _lastError.isNotEmpty;
  bool get isLifetimeAdsFree => _isLifetimeAdsFree;
  
  Future<void> initialize() async {
    // Eğer zaten başlatılmışsa tekrar başlatma
    if (_isInitialized) {

      return;
    }
    

    _isInitialized = true;
    
    try {
      // Önce Firebase'den cihaz verisini kontrol et
      await _checkLifetimeAdsFree();
      
      // Store bağlantısını kontrol et
      _isAvailable = await _inAppPurchase.isAvailable();

      
      if (!_isAvailable) {
        _lastError = 'In-App Purchase bu cihazda kullanılamıyor';

        notifyListeners();
        return;
      }
      
      // Satın alma stream'ini dinle (sadece bir kez)
      if (_subscription == null) {
        final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
        _subscription = purchaseUpdated.listen(
          _listenToPurchaseUpdated,
          onDone: () {

            _subscription?.cancel();
          }, 
          onError: (error) {

            _lastError = 'Satın alma dinleme hatası: $error';
            notifyListeners();
          }
        );
      }
      
      // Play Console entegrasyonu - ürünleri yükle
      await loadProducts();
      // restorePurchases'i otomatik çağırma, sadece kullanıcı istediğinde
      // await restorePurchases();
      

      
    } catch (e) {

      _lastError = 'Tek seferlik satın alma servisi başlatılamadı: $e';
      _isInitialized = false; // Hata durumunda reset
      notifyListeners();
    }
  }
  
  // Firebase'den ömür boyu reklamsız durumunu kontrol et
  Future<void> _checkLifetimeAdsFree() async {
    debugPrint('🔍 [OneTimePurchase] _checkLifetimeAdsFree başlatılıyor...');
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('❌ [OneTimePurchase] Kullanıcı giriş yapmamış');
      _isLifetimeAdsFree = false;
      await _creditsService.setLifetimeAdsFree(false);
      notifyListeners();
      return;
    }
    
    // Cache kontrolü - 5 dakika içinde kontrol edildiyse atla
    if (_lastFirestoreCheck != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastFirestoreCheck!);
      if (timeSinceLastCheck < _firestoreCacheDuration && _isLifetimeAdsFree) {
        debugPrint('✅ [OneTimePurchase] Cache geçerli, Firestore kontrolü atlandı');
        return;
      }
    }
    
    // CRITICAL: Önce local cache'i kontrol et (offline destek)
    final localStatus = await _getLocalCachedStatus();
    if (localStatus != null) {
      debugPrint('💾 [OneTimePurchase] Local cache bulundu: $localStatus');
      _isLifetimeAdsFree = localStatus;
      await _creditsService.setLifetimeAdsFree(localStatus);
      notifyListeners();
      // Local cache var, arka planda Firestore'u kontrol et
      _checkLifetimeFromFirestore(currentUser.uid, retryCount: 2, silent: true);
    } else {
      // Local cache yok, Firestore'dan oku
      await _checkLifetimeFromFirestore(currentUser.uid, retryCount: 2);
    }
  }
  
  // Firestore'dan reklamsız durumu kontrol et (retry mekanizması ile)
  Future<void> _checkLifetimeFromFirestore(String userId, {int retryCount = 3, bool silent = false}) async {
    int attempt = 0;
    
    while (attempt < retryCount) {
      try {
        if (!silent) {
          debugPrint('🔄 [OneTimePurchase] Firestore kontrol denemesi ${attempt + 1}/$retryCount');
        }
        
        // Firestore offline persistence sayesinde önce cache'den okur
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        _lastFirestoreCheck = DateTime.now();
        
        if (doc.exists) {
          final data = doc.data() ?? {};
          final lifetime = data['lifetimeAdsFree'] == true;
          
          _isLifetimeAdsFree = lifetime;
          await _creditsService.setLifetimeAdsFree(lifetime);
          
          // CRITICAL: Local cache'e kaydet (offline destek)
          await _saveLocalCachedStatus(lifetime);
          
          if (lifetime) {
            debugPrint('✅ [OneTimePurchase] Kullanıcı REKLAMSIZ (Firestore)');
          } else {
            debugPrint('📱 [OneTimePurchase] Kullanıcı normal (Firestore)');
          }
          
          if (!silent) {
            notifyListeners();
          }
          return; // Başarılı, çık
          
        } else {
          // Belge yok, yeni kullanıcı
          debugPrint('📝 [OneTimePurchase] Yeni kullanıcı, belge bulunamadı');
          _isLifetimeAdsFree = false;
          await _creditsService.setLifetimeAdsFree(false);
          await _saveLocalCachedStatus(false);
          if (!silent) {
            notifyListeners();
          }
          return;
        }
        
      } catch (e) {
        attempt++;
        debugPrint('⚠️ [OneTimePurchase] Firestore okuma hatası (Deneme $attempt/$retryCount): $e');
        
        if (attempt < retryCount) {
          // Bir sonraki deneme için bekle
          await Future.delayed(Duration(seconds: attempt * 2));
        } else {
          // Tüm denemeler başarısız - İnternet yok olabilir!
          debugPrint('🔌 [OneTimePurchase] İnternet sorunu olabilir, local cache kontrol ediliyor...');
          
          // Local cache'den oku
          final localStatus = await _getLocalCachedStatus();
          if (localStatus != null) {
            debugPrint('💾 [OneTimePurchase] OFFLINE MODE: Local cache kullanılıyor: $localStatus');
            _isLifetimeAdsFree = localStatus;
            await _creditsService.setLifetimeAdsFree(localStatus);
          } else {
            debugPrint('❌ [OneTimePurchase] Local cache de yok, varsayılan: false');
            _isLifetimeAdsFree = false;
            await _creditsService.setLifetimeAdsFree(false);
          }
        }
      }
    }
    
    if (!silent) {
      notifyListeners();
    }
  }
  
  // Local cache'den reklamsız durumu oku
  Future<bool?> _getLocalCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedValue = prefs.getBool(_localCacheKey);
      final cachedTimestamp = prefs.getInt(_localCacheTimestampKey);
      
      if (cachedValue != null && cachedTimestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTimestamp;
        final cacheDays = cacheAge / (1000 * 60 * 60 * 24);
        
        debugPrint('💾 [OneTimePurchase] Local cache: $cachedValue (${cacheDays.toStringAsFixed(1)} gün önce kaydedilmiş)');
        
        // Cache 30 günden eskiyse geçersiz say
        if (cacheDays > 30) {
          debugPrint('⏰ [OneTimePurchase] Cache çok eski, geçersiz');
          return null;
        }
        
        return cachedValue;
      }
      
      return null;
    } catch (e) {
      debugPrint('⚠️ [OneTimePurchase] Local cache okuma hatası: $e');
      return null;
    }
  }
  
  // Local cache'e reklamsız durumu ve kullanıcı ID'si kaydet
  Future<void> _saveLocalCachedStatus(bool isAdsFree) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = FirebaseAuth.instance.currentUser;
      
      await prefs.setBool(_localCacheKey, isAdsFree);
      await prefs.setInt('${_localCacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      // KRİTİK: Satın alan kullanıcı ID'sini kaydet
      if (currentUser != null && isAdsFree) {
        await prefs.setString('${_localCacheKey}_user_id', currentUser.uid);
        debugPrint('💾 [OneTimePurchase] Local cache kaydedildi: $isAdsFree (User: ${currentUser.uid})');
      } else if (!isAdsFree) {
        await prefs.remove('${_localCacheKey}_user_id');
        debugPrint('💾 [OneTimePurchase] Local cache temizlendi');
      }
    } catch (e) {
      debugPrint('❌ [OneTimePurchase] Local cache kayıt hatası: $e');
    }
  }

  // Local cache'in mevcut kullanıcı için geçerli olup olmadığını kontrol et
  Future<bool> _isLocalCacheValidForCurrentUser(String? currentUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('${_localCacheKey}_user_id');
      final cachedValue = prefs.getBool(_localCacheKey);
      
      // Cache yoksa geçersiz
      if (cachedValue != true || cachedUserId == null) {
        debugPrint('❌ [OneTimePurchase] Cache yok veya negatif');
        return false;
      }
      
      // Kullanıcı null (çıkış) ama cache var - GEÇİCİ auth null olabilir
      if (currentUserId == null) {
        debugPrint('🤔 [OneTimePurchase] Auth null ama cache var (User: $cachedUserId) - geçici koruma');
        return true; // Geçici koruma sağla
      }
      
      // Kullanıcı ID'leri aynı mı?
      final isValid = cachedUserId == currentUserId;
      if (isValid) {
        debugPrint('✅ [OneTimePurchase] Cache geçerli - aynı kullanıcı ($currentUserId)');
      } else {
        debugPrint('❌ [OneTimePurchase] Cache geçersiz - farklı kullanıcı (Cache: $cachedUserId, Current: $currentUserId)');
      }
      
      return isValid;
    } catch (e) {
      debugPrint('⚠️ [OneTimePurchase] Cache geçerlilik kontrol hatası: $e');
      return false;
    }
  }

  // Local cache'i tamamen temizle
  Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localCacheKey);
      await prefs.remove('${_localCacheKey}_timestamp');
      await prefs.remove('${_localCacheKey}_user_id');
      debugPrint('🧹 [OneTimePurchase] Local cache tamamen temizlendi');
    } catch (e) {
      debugPrint('❌ [OneTimePurchase] Cache temizleme hatası: $e');
    }
  }
  
  // Not: Realtime Database kullanılmıyor, bu metod kaldırıldı
  
  // Ürünleri yükle
  Future<void> loadProducts() async {
    // Zaten yükleme yapılıyorsa bekle
    if (_isLoadingProducts) {

      return;
    }
    

    _isLoadingProducts = true;
    
    try {
      Set<String> kIds = <String>{_removeAdsProductId};
      final ProductDetailsResponse productDetailResponse = await _inAppPurchase.queryProductDetails(kIds);
      
      if (productDetailResponse.error != null) {
        _lastError = 'Ürün yükleme hatası: ${productDetailResponse.error!.message}';

        _products = [];
        notifyListeners();
        return;
      }
      
      if (productDetailResponse.productDetails.isEmpty) {
        _lastError = 'Reklam kaldırma ürünü store\'da bulunamadı';

        _products = [];
        notifyListeners();
        return;
      }
      
      _products = productDetailResponse.productDetails;
      _lastError = '';

      
      for (var product in _products) {



      }
      
      notifyListeners();
      
    } catch (e) {

      _lastError = 'Ürünler yüklenirken hata oluştu: $e';
      notifyListeners();
    } finally {
      _isLoadingProducts = false;
    }
  }
  
  // Satın alma işlemi
  Future<bool> buyRemoveAds() async {

    
    try {
      _lastError = '';
      // Giriş zorunluluğu
      if (FirebaseAuth.instance.currentUser == null) {
        _lastError = 'Satın alma için önce giriş yapmalısınız';
        notifyListeners();
        return false;
      }
      
      if (_isLifetimeAdsFree) {
        _lastError = 'Bu cihaz zaten ömür boyu reklamsız';

        AdMobService().clearInAppActionFlag();
        notifyListeners();
        return false;
      }
      
      if (!_isAvailable) {
        _lastError = 'Store kullanılamıyor';

        AdMobService().clearInAppActionFlag();
        notifyListeners();
        return false;
      }
      
      if (_products.isEmpty) {

        await loadProducts();
        if (_products.isEmpty) {
          _lastError = 'Reklam kaldırma ürünü bulunamadı';
          AdMobService().clearInAppActionFlag();
          notifyListeners();
          return false;
        }
      }
      
      if (_purchasePending) {

        _purchasePending = false;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
      }
      
      final ProductDetails productDetails = _products[0];


      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );
      
      _purchasePending = true;
      notifyListeners();
      
      // Tek seferlik satın alma (non-consumable)
      bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (success) {

        return true;
      } else {

        _purchasePending = false;
        _lastError = 'Satın alma başlatılamadı';
        AdMobService().clearInAppActionFlag();
        notifyListeners();
        return false;
      }
      
    } catch (e) {

      _purchasePending = false;
      _lastError = 'Satın alma hatası: $e';
      AdMobService().clearInAppActionFlag();
      notifyListeners();
      return false;
    }
  }
  
  // Satın alma güncellemelerini dinle
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {


      
      
      // ÖNEMLİ: Sadece reklam kaldırma ürününü işle
      // Kitap satın almaları bu servisi ilgilendirmez
      if (purchaseDetails.productID != _removeAdsProductId) {

        // Eğer satın alma tamamlanmamışsa tamamla (başka servis işleyecek)
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
        continue; // Bu satın almayı atla
      }
      if (purchaseDetails.status == PurchaseStatus.pending) {

        _purchasePending = true;
        _lastError = '';
        notifyListeners();
        
      } else if (purchaseDetails.status == PurchaseStatus.error) {

        _purchasePending = false;
        
        if (purchaseDetails.error != null) {
          switch (purchaseDetails.error!.code) {
            case 'user_canceled':
            case 'BillingResponse.USER_CANCELED':
            case '1':
              _lastError = 'Satın alma iptal edildi';
              break;
            default:
              _lastError = 'Satın alma başarısız: ${purchaseDetails.error!.message}';
          }
        } else {
          _lastError = 'Bilinmeyen satın alma hatası';
        }
        
        // Satın alma hatası, uygulama içi işlem flag'ini temizle
        AdMobService().clearInAppActionFlag();
        notifyListeners();
        
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        debugPrint('✅ [OneTimePurchase] PURCHASED event alındı');
        _purchasePending = false;
        
        // Sadece yeni satın almaları işle
        _verifyAndDeliverPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        debugPrint('🔄 [OneTimePurchase] RESTORED event alındı');
        
        // RESTORED durumunda kullanıcı kontrolü yap
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          debugPrint('❌ [OneTimePurchase] Restore için giriş gerekli, atlanıyor');
          continue;
        }
        
        // Firestore'da bu kullanıcıya ait satın alma var mı kontrol et
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists && doc.data()?['lifetimeAdsFree'] == true) {
          debugPrint('✅ [OneTimePurchase] Kullanıcıda zaten reklamsız kayıtlı, restore işleniyor');
          _purchasePending = false;
          _verifyAndDeliverPurchase(purchaseDetails);
        } else {
          debugPrint('⚠️ [OneTimePurchase] Bu kullanıcıda reklamsız kaydı yok, restore atlanıyor');
          // Restore'u atla ama complete et
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {

        _purchasePending = false;
        _lastError = 'Satın alma iptal edildi';
        
        // Satın alma iptal edildi, uygulama içi işlem flag'ini temizle
        AdMobService().clearInAppActionFlag();
        notifyListeners();
      }
      
      // Satın alma işlemini tamamla
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails).then((_) {

        }).catchError((error) {

        });
      }
    }
  }
  
  // Satın almayı doğrula ve teslim et
  Future<void> _verifyAndDeliverPurchase(PurchaseDetails purchaseDetails) async {

    
    try {
      // Burada gerçek uygulamada sunucu tarafında doğrulama yapılmalı
      bool valid = true; // Test için
      
      if (valid) {

        await _deliverProduct(purchaseDetails);
        _lastError = '';
      } else {

        _lastError = 'Satın alma doğrulanamadı';
      }
      
    } catch (e) {

      _lastError = 'Reklam kaldırma aktifleştirilemedi: $e';
    }
    
    _purchasePending = false;
    notifyListeners();
  }
  
  // Ürünü teslim et
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    debugPrint('📦 [OneTimePurchase] Satın alma teslim ediliyor...');
    
    try {
      // Kullanıcı giriş yapmış mı kontrol et
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [OneTimePurchase] Kullanıcı giriş yapmamış!');
        throw Exception('Satın alma için giriş yapmalısınız');
      }
      
      final userEmail = currentUser.email;
      final userId = currentUser.uid;
      final deviceId = await _deviceDataService.getDeviceId();
      final purchaseTimestamp = DateTime.now().millisecondsSinceEpoch;
      
      debugPrint('💾 [OneTimePurchase] Firestore\'a kaydediliyor...');
      
      // Firestore'a kaydet (retry ile güvenli)
      await _saveToFirestoreWithRetry(
        userId: userId,
        userEmail: userEmail,
        deviceId: deviceId,
        purchaseDetails: purchaseDetails,
        purchaseTimestamp: purchaseTimestamp,
      );
      
      debugPrint('✅ [OneTimePurchase] Firestore kaydı başarılı');
      
      // Local state'i güncelle
      _isLifetimeAdsFree = true;
      _lastFirestoreCheck = DateTime.now();
      
      // CRITICAL: Local cache'e de kaydet (offline destek)
      await _saveLocalCachedStatus(true);
      
      // Credits service'e bildir
      await _creditsService.setLifetimeAdsFree(true);
      
      // Analytics event'lerini gönder
      double price = 0.0;
      if (_products.isNotEmpty) {
        final priceString = _products[0].price.replaceAll(RegExp(r'[^\d,.]'), '');
        final priceFormatted = priceString.replaceAll(',', '.');
        price = double.tryParse(priceFormatted) ?? 99.90;
      }
      
      await TurkceAnalyticsService.premiumSatinAlinaBasarili('tek_seferlik', price);
      await TurkceAnalyticsService.kullaniciOzellikleriniGuncelle(premiumMu: true);
      
      debugPrint('🎉 [OneTimePurchase] Satın alma başarıyla tamamlandı!');
      
      // Satın alma işlemi tamamlandı, uygulama içi işlem flag'ini temizle
      AdMobService().clearInAppActionFlag();
      
    } catch (e) {
      debugPrint('❌ [OneTimePurchase] _deliverProduct hatası: $e');
      _lastError = 'Ömür boyu reklamsız aktifleştirilemedi: $e';
      // Hata durumunda da flag'i temizle
      AdMobService().clearInAppActionFlag();
      throw e;
    }
  }
  
  // Firestore'a güvenli kayıt (retry mekanizması ile)
  Future<void> _saveToFirestoreWithRetry({
    required String userId,
    required String? userEmail,
    required String deviceId,
    required PurchaseDetails purchaseDetails,
    required int purchaseTimestamp,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        debugPrint('🔄 [OneTimePurchase] Firestore kayıt denemesi ${attempt + 1}/$maxRetries');
        
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'lifetimeAdsFree': true,
          'purchaseDate': purchaseTimestamp,
          'purchaseId': purchaseDetails.purchaseID,
          'productId': purchaseDetails.productID,
          'purchaseVerified': true,
          'premiumType': 'tek_seferlik_satin_alma',
          'email': userEmail,
          'deviceId': deviceId,
          'lastUpdated': FieldValue.serverTimestamp(),
          'purchaseDetails': {
            'transactionDate': purchaseTimestamp,
            'productId': purchaseDetails.productID,
            'purchaseToken': purchaseDetails.purchaseID,
            'verificationStatus': 'verified',
          }
        }, SetOptions(merge: true));
        
        debugPrint('✅ [OneTimePurchase] Firestore kayıt başarılı (Deneme ${attempt + 1})');
        
        // Local cache'e de kaydet
        await _saveLocalCachedStatus(true);
        
        return; // Başarılı, çık
        
      } catch (e) {
        attempt++;
        debugPrint('⚠️ [OneTimePurchase] Firestore kayıt hatası (Deneme $attempt/$maxRetries): $e');
        
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        } else {
          debugPrint('❌ [OneTimePurchase] Firestore kaydı başarısız, tüm denemeler tükendi');
          throw e;
        }
      }
    }
  }
  
  // Not: Realtime Database kullanılmıyor, bu metod kaldırıldı
  
  // Satın almaları geri yükle
  Future<void> restorePurchases() async {

    
    try {
      await _inAppPurchase.restorePurchases();

      
    } catch (e) {

      _lastError = 'Satın almalar geri yüklenemedi: $e';
      notifyListeners();
    }
  }
  
  // Fiyat bilgisi - Play Console'dan dinamik çeker
  String _getRemoveAdsPrice() {
    if (_products.isEmpty) {

      // Ürünler henüz gelmediyse arka planda tekrar dene
      loadProducts();
      return '₺69,99'; // Yüklenene kadar varsayılan
    }

    final product = _products[0];
    final price = product.price; // Localized price (e.g., "₺69,99" or "69,99 TL")


    String formattedPrice = price;
    if (!price.contains('TL') && !price.contains('₺')) {
      formattedPrice = price.contains(',') ? price : '₺$price';
    }

    return formattedPrice;
  }

  // DEBUG: Mevcut kullanıcıya doğrudan ömür boyu reklamsız tanımla
  Future<void> debugGrantLifetimeForCurrentUser() async {
    if (kReleaseMode) {

      throw Exception('Sadece debug modunda kullanılabilir');
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {

      throw Exception('Önce giriş yapın');
    }

    try {
      final userId = currentUser.uid;
      final userEmail = currentUser.email;
      final now = DateTime.now().millisecondsSinceEpoch;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'lifetimeAdsFree': true,
        'purchaseDate': now,
        'purchaseId': 'debug_$now',
        'productId': _removeAdsProductId,
        'purchaseVerified': true,
        'premiumType': 'debug_grant',
        'email': userEmail,
        'purchaseDetails': {
          'transactionDate': now,
          'productId': _removeAdsProductId,
          'purchaseToken': 'debug_$now',
          'verificationStatus': 'debug_granted',
        },
      }, SetOptions(merge: true));

      _isLifetimeAdsFree = true;
      await _creditsService.setLifetimeAdsFree(true);
      await TurkceAnalyticsService.kullaniciOzellikleriniGuncelle(premiumMu: true);

      _lastError = '';

      notifyListeners();
    } catch (e) {

      _lastError = 'Debug grant hatası: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // Temizlik
  @override
  void dispose() {

    _subscription?.cancel();

    super.dispose();
  }
} 
