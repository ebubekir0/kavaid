import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/turkce_analytics_service.dart';

class PurchaseManager extends ChangeNotifier {
  static final PurchaseManager _instance = PurchaseManager._internal();
  factory PurchaseManager() => _instance;
  PurchaseManager._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  bool _isInitialized = false;
  
  // States
  bool _isPremium = false;        // Abonelik durumu
  bool _isLifetimeNoAds = false;  // Eski 'Reklam Kaldır' satın alımı
  DateTime? _premiumExpiry;       // Abonelik bitiş tarihi
  Set<String> _purchasedBooks = {};
  
  String _lastError = '';
  
  // Product mappings
  static Map<String, String> get _products {
    if (Platform.isAndroid) {
      return {
        'premium_monthly': 'premium_monthly',
        'premium_yearly': 'premium_yearly',
        'ads_free': 'ads_free', // Veya remove_ads
      };
    } else if (Platform.isIOS) {
       // iOS ID'leri (App Store Connect ile eşleşmeli)
       return {
        'premium_monthly': 'premium_monthly', 
        'premium_yearly': 'premium_yearly',
        'ads_free': 'ads_free',
      };
    }
    return {};
  }

  // Getters
  bool get isInitialized => _isInitialized;
  
  // Reklam gösterilmeli mi? (Premium DEĞİLSE ve Ömür Boyu Reklamsız DEĞİLSE)
  bool get shouldShowAds => !_isPremium && !_isLifetimeNoAds;
  
  // Premium mu?
  bool get isPremium {
    if (_isPremium) {
      // Eğer bitiş tarihi varsa, tarihin geçip geçmediğini kontrol et
      if (_premiumExpiry != null) {
        return _premiumExpiry!.isAfter(DateTime.now());
      }
      // Tarih yoksa ama premium true ise (eski kullanıcı), true döndür 
      // (arka planda loadUserPurchases bunu güncelleyecektir)
      return true;
    }
    return false;
  }
  
  // Bitiş tarihi bilgisini UI'da göstermek için
  DateTime? get premiumExpiry => _premiumExpiry;
  
  // Eski kullanıcı mı?
  bool get isLifetimeNoAds => _isLifetimeNoAds;

  Future<bool> get isAvailable async {
    return await _inAppPurchase.isAvailable();
  }
  String get lastError => _lastError;
  Set<String> get purchasedBooks => _purchasedBooks;

  // İçeriğe erişim izni var mı?
  bool canAccessContent(String bookId, bool isFreeContent) {
    if (isFreeContent) return true; // Herkese açık
    if (_isPremium) return true;    // Abone her şeyi görür
    if (_purchasedBooks.contains('book_${bookId.split('_').last}')) return true; // Satın alınmış kitap
    return false;
  }

  // Satın alma işlemini başlat
  Future<void> buyProduct(String productId) async {
    try {
      if (!await _inAppPurchase.isAvailable()) {
        _lastError = 'Mağaza kullanılamıyor.';
        notifyListeners();
        return;
      }
      
      final Set<String> ids = {productId};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(ids);
      
      if (response.notFoundIDs.isNotEmpty) {
        _lastError = 'Ürün bulunamadı: $productId';
        notifyListeners();
        debugPrint('❌ [PurchaseManager] Ürün bulunamadı: ${response.notFoundIDs}');
        return;
      }
      
      final List<ProductDetails> products = response.productDetails;
      if (products.isEmpty) {
        _lastError = 'Ürün detayları alınamadı.';
        notifyListeners();
        return;
      }
      
      final ProductDetails productDetails = products.first;
      
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      
      // Abonelikler non-consumable olarak işlem görür
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
    } catch (e) {
      _lastError = 'Satın alma başlatılamadı: $e';
      notifyListeners();
      debugPrint('❌ [PurchaseManager] Buy error: $e');
    }
  }

  Future<void> buyPremiumMonthly() async {
    await buyProduct(_products['premium_monthly']!);
  }



  Future<void> buyPremiumYearly() async {
    await buyProduct(_products['premium_yearly']!);
  }

  // ... inside PurchaseManager

  static final Map<String, ProductDetails> _productDetailsMap = {};
  Map<String, ProductDetails> get productDetailsMap => _productDetailsMap;

  // ... other methods

  // Initialize
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🚀 [PurchaseManager] Başlatılıyor...');
      
      // Auth değişikliklerini dinle
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          debugPrint('👤 [PurchaseManager] Kullanıcı giriş yaptı, veriler yükleniyor...');
          loadUserPurchases().then((_) {
            // Eğer premium ama tarih yoksa (eski kullanıcı), sessizce doğrula
            if (_isPremium && _premiumExpiry == null) {
              _silentVerifySubscription();
            }
          });
        } else {
          debugPrint('門 [PurchaseManager] Kullanıcı çıkış yaptı');
          _resetState();
        }
      });

      // Store bağlantısını kur
      _subscription = _inAppPurchase.purchaseStream.listen(
        _listenToPurchaseUpdated,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('❌ [PurchaseManager] Stream hatası: $error'),
      );

      // Kullanıcı verilerini yükle
      await loadUserPurchases();
      
      // Ürün detaylarını (fiyatları) çek
      await fetchProducts();

      _isInitialized = true;
      debugPrint('✅ [PurchaseManager] Başlatıldı');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Başlatma hatası: $e');
      _lastError = 'Başlatılamadı: $e';
    }
  }

  void _resetState() {
    _isPremium = false;
    _isLifetimeNoAds = false;
    _premiumExpiry = null;
    _purchasedBooks = {};
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    if (!await _inAppPurchase.isAvailable()) return;
    
    final ids = _products.values.toSet();
    final response = await _inAppPurchase.queryProductDetails(ids);
    
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('❌ Ürünler bulunamadı: ${response.notFoundIDs}');
    }

    _productDetailsMap.clear();
    for (var product in response.productDetails) {
       // Map by our internal keys (e.g. 'premium_monthly') instead of store ID if possible, 
       // but here store ID is easier. Or better, map 'kavaid_premium_monthly' -> ProductDetails
       // UI uses internal keys 'monthly', 'yearly', so let's map carefully.
       _productDetailsMap[product.id] = product;
    }
    notifyListeners();
  }
  
  // Helper to get price
  String getPrice(String internalKey) {
    final storeId = _products['premium_$internalKey'];
    if (storeId == null) return '';
    final details = _productDetailsMap[storeId];
    return details?.price ?? ''; // Marketten dönen formatlı fiyat (örn: ₺49.99)
  }

  // Helper to get raw price for calculations
  double? getRawPrice(String internalKey) {
     final storeId = _products['premium_$internalKey'];
     if (storeId == null) return null;
     
     final details = _productDetailsMap[storeId];
     if (details == null) return null;

     // Fiyat metninden sayıyı ayıkla (Örn: "₺479,99" -> 479.99)
     String cleanPrice = details.price.replaceAll(RegExp(r'[^0-9.,]'), '');
     
     // Virgül ve nokta karmaşasını çöz (Sonuncusu ondalık ayracıdır)
     if (cleanPrice.contains(',') && cleanPrice.contains('.')) {
       // Hem nokta hem virgül varsa, sondakini ondalık kabul et
       if (cleanPrice.lastIndexOf(',') > cleanPrice.lastIndexOf('.')) {
         cleanPrice = cleanPrice.replaceAll('.', '').replaceAll(',', '.');
       } else {
         cleanPrice = cleanPrice.replaceAll(',', '');
       }
     } else if (cleanPrice.contains(',')) {
       // Sadece virgül varsa noktaya çevir
       cleanPrice = cleanPrice.replaceAll(',', '.');
     }
     
     return double.tryParse(cleanPrice);
  }

  // Yıllık planın aylık maliyetini hesapla
  String getMonthlyCostForYearly() {
    try {
      final yearlyPriceStr = getPrice('yearly'); // Örn: ₺479,99
      if (yearlyPriceStr.isEmpty) return '';

      final yearlyRaw = getRawPrice('yearly');
      if (yearlyRaw == null || yearlyRaw == 0) return '';

      // Aylık maliyeti hesapla
      final monthlyCost = yearlyRaw / 12;

      // Para birimi sembolünü bul (Rakam olmayan karakterler)
      String currencySymbol = yearlyPriceStr.replaceAll(RegExp(r'[0-9.,\s]'), '');
      
      // Sembolün konumunu bul (Başta mı sonda mı?)
      bool symbolAtStart = yearlyPriceStr.trim().startsWith(currencySymbol);

      // Fiyatı formatla (Daima 2 ondalık hane)
      // Eğer orijinal fiyat virgül kullanıyorsa virgül, nokta kullanıyorsa nokta kullan
      bool useComma = yearlyPriceStr.contains(',');
      String formattedPrice = monthlyCost.toStringAsFixed(2);
      if (useComma) formattedPrice = formattedPrice.replaceAll('.', ',');

      if (symbolAtStart) {
        return '$currencySymbol$formattedPrice/ay';
      } else {
        return '$formattedPrice$currencySymbol /ay';
      }
    } catch (e) {
      debugPrint('Fiyat hesaplama hatası: $e');
      return '';
    }
  }

  // Kullanıcı satın almalarını yükle
  Future<void> loadUserPurchases() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('🚪 [PurchaseManager] Giriş yapılmamış');
        return;
      }

      // Local cache'den yükle
      final prefs = await SharedPreferences.getInstance();
      _isLifetimeNoAds = prefs.getBool('is_lifetime_no_ads') ?? prefs.getBool('is_ads_free') ?? false; 
      _isPremium = prefs.getBool('is_premium') ?? false;
      final books = prefs.getStringList('purchased_books') ?? [];
      _purchasedBooks = books.toSet();

      // FIRESTORE: İki farklı yerden de kontrol ediyoruz (Mevcut karmaşıklığı çözmek için)
      
      // 1. Root User Dokümanı (BookPurchaseService buraya kaydediyor)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        
        // 1. Kitaplar (Her iki versiyonu da kontrol et)
        final books = (data['purchasedBooks'] as List<dynamic>?) ?? 
                      (data['purchased_books'] as List<dynamic>?) ?? [];
        
        for (var b in books) {
          _purchasedBooks.add(b.toString());
        }
        
        // 2. Premium / Reklamsız (Tüm versiyonları kontrol et)
        _isPremium = data['is_premium'] ?? data['isPremium'] ?? _isPremium;
        _isLifetimeNoAds = data['is_ads_free'] ?? data['isAdsFree'] ?? data['lifetimeAdsFree'] ?? _isLifetimeNoAds;
        
        // Bitiş tarihini yükle
        if (data['premium_expiry'] != null) {
          if (data['premium_expiry'] is Timestamp) {
            _premiumExpiry = (data['premium_expiry'] as Timestamp).toDate();
          } else if (data['premium_expiry'] is int) {
            _premiumExpiry = DateTime.fromMillisecondsSinceEpoch(data['premium_expiry']);
          }
        }
      }

      // 2. Purchases Sub-collection (PurchaseManager'ın yeni stili)
      final purchaseDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('purchases')
          .doc('active')
          .get();

      if (purchaseDoc.exists) {
        final data = purchaseDoc.data() as Map<String, dynamic>;
        
        _isLifetimeNoAds = data['is_ads_free'] ?? data['isAdsFree'] ?? data['lifetimeAdsFree'] ?? _isLifetimeNoAds;
        _isPremium = data['is_premium'] ?? data['isPremium'] ?? _isPremium;
        
        // Bitiş tarihini yükle (alt koleksiyondan da kontrol)
        if (data['premium_expiry'] != null) {
          if (data['premium_expiry'] is Timestamp) {
            _premiumExpiry = (data['premium_expiry'] as Timestamp).toDate();
          } else if (data['premium_expiry'] is int) {
            _premiumExpiry = DateTime.fromMillisecondsSinceEpoch(data['premium_expiry']);
          }
        }
        
        final books = (data['purchased_books'] as List<dynamic>?) ?? 
                      (data['purchasedBooks'] as List<dynamic>?) ?? [];
        
        for (var b in books) {
          _purchasedBooks.add(b.toString());
        }
      }

      // Local cache'i güncelle
      await _saveToPrefs();
      notifyListeners();

      debugPrint('📦 [PurchaseManager] Yüklendi: Premium=$_isPremium, BooksCount=${_purchasedBooks.length}');
      
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Satın alma yükleme hatası: $e');
    }
  }

  // Satın alma dinleyici
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('🔄 [PurchaseManager] Güncelleme: ${purchaseDetails.status}');
      
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _processPurchase(purchaseDetails);
      }
      
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Satın almayı işle
  Future<void> _processPurchase(PurchaseDetails purchase) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      if (!_isValidPurchase(purchase)) {
        return;
      }

      final productType = _getProductType(purchase.productID);
      
      // Firestore'a kaydet
      await _savePurchaseToFirestore(
        userId: currentUser.uid,
        productType: productType ?? 'unknown',
        purchase: purchase,
      );

      // Local state'i güncelle
      _updateLocalState(productType, purchase.productID);

      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ [PurchaseManager] İşleme hatası: $e');
    }
  }

  bool _isValidPurchase(PurchaseDetails purchase) {
    // Basitleştirilmiş validasyon
    return true; 
  }

  String? _getProductType(String productId) {
    for (final entry in _products.entries) {
      if (entry.value == productId) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _savePurchaseToFirestore({
    required String userId,
    required String productType,
    required PurchaseDetails purchase,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('purchases')
          .doc('active');

      Map<String, dynamic> updateData = {
        'last_updated': FieldValue.serverTimestamp(),
      };

      if (productType == 'ads_free') {
        updateData['is_ads_free'] = true;
      } else if (productType.startsWith('premium')) {
        updateData['is_premium'] = true;
        updateData['premium_type'] = productType; 
        updateData['subscription_start'] = FieldValue.serverTimestamp();
        
        // Bitiş tarihini hesapla (Monthly: 30 gün + 3 gün tampon, Yearly: 365 gün + 7 gün tampon)
        // Tampon süreler market senkronizasyon gecikmeleri içindir
        DateTime now = DateTime.now();
        DateTime expiry;
        if (productType.contains('yearly')) {
          expiry = now.add(const Duration(days: 372)); 
        } else {
          expiry = now.add(const Duration(days: 33));
        }
        updateData['premium_expiry'] = Timestamp.fromDate(expiry);
        _premiumExpiry = expiry; // Local state'i de hemen güncelle
      } else if (productType.startsWith('book_')) {
         // Kitap mantığı korunuyor
         updateData['purchased_books'] = FieldValue.arrayUnion([productType]);
      }

      await docRef.set(updateData, SetOptions(merge: true));

    } catch (e) {
      debugPrint('❌ Firestore kayıt hatası: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_lifetime_no_ads', _isLifetimeNoAds);
    await prefs.setBool('is_premium', _isPremium);
    if (_premiumExpiry != null) {
      await prefs.setInt('premium_expiry', _premiumExpiry!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('premium_expiry');
    }
    await prefs.setStringList('purchased_books', _purchasedBooks.toList());
  }

  // Eski kullanıcılar veya şüpheli durumlar için sessiz doğrulama
  Future<void> _silentVerifySubscription() async {
    try {
      debugPrint('🔄 [PurchaseManager] Sessiz doğrulama başlatıldı...');
      // Bu metod marketten satın almaları çeker ve local/firestore verilerini günceller
      await _inAppPurchase.restorePurchases();
      debugPrint('✅ [PurchaseManager] Sessiz doğrulama tamamlandı');
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Sessiz doğrulama hatası: $e');
    }
  }

  void _updateLocalState(String? productType, String productId) {
    if (productType == 'ads_free') {
      _isLifetimeNoAds = true;
    } else if (productType != null && productType.startsWith('premium')) {
      _isPremium = true;
    } else if (productType != null && productType.startsWith('book_')) {
      _purchasedBooks.add(productType);
    }
    _saveToPrefs();
  }

  // MOCK METHODS FOR TESTING
  Future<void> mockSetPremium() async {
    if (kDebugMode) {
      _isPremium = true;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> mockResetPremium() async {
    if (kDebugMode) {
      _isPremium = false;
      _isLifetimeNoAds = false;
      await _saveToPrefs();
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
