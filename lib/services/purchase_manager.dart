import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// RevenueCat API Keys
const _apiKeyAndroid = 'goog_JUkLUxlscZqowPzLzmvYPKddTbE'; // RevenueCat SDK Public Key (Production)
const _apiKeyIOS = 'goog_JUkLUxlscZqowPzLzmvYPKddTbE';     // Production Key

class PurchaseManager extends ChangeNotifier {
  static final PurchaseManager _instance = PurchaseManager._internal();
  factory PurchaseManager() => _instance;
  PurchaseManager._internal();

  bool _isInitialized = false;
  
  // States
  bool _isPremium = false;        // Abonelik durumu
  bool _isLifetimeNoAds = false;  // Eski 'Reklam Kaldır' satın alımı
  Set<String> _purchasedBooks = {};
  
  String _lastError = '';
  
  // RevenueCat Offerings and Packages
  Offerings? _offerings;
  
  // Getters
  bool get isInitialized => _isInitialized;
  
  // Reklam gösterilmeli mi? (Premium DEĞİLSE ve Ömür Boyu Reklamsız DEĞİLSE)
  bool get shouldShowAds => !_isPremium && !_isLifetimeNoAds;
  
  // Premium mu?
  bool get isPremium => _isPremium;
  
  // Eski kullanıcı mı?
  bool get isLifetimeNoAds => _isLifetimeNoAds;

  bool get isAvailable => _isInitialized; 
  String get lastError => _lastError;
  Set<String> get purchasedBooks => _purchasedBooks;
  
  // RevenueCat'de expiry otomatik yönetilir
  DateTime? get subscriptionExpiryDate => null; // Detaylı bilgi istenirse CustomerInfo'dan alınabilir

  // İçeriğe erişim izni var mı?
  bool canAccessContent(String bookId, bool isFreeContent) {
    if (isFreeContent) return true; // Herkese açık
    if (_isPremium) return true;    // Abone her şeyi görür
    
    // Tekil olarak satın alınmış kitap kontrolü (Eski veya Yeni)
    if (_purchasedBooks.contains(bookId)) {
      return true;
    }

    return false;
  }

  // Initialize
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🚀 [RevenueCat] Başlatılıyor...');
      
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_apiKeyAndroid);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_apiKeyIOS);
      } else {
        return;
      }
      
      await Purchases.configure(configuration);
      
      // Dinleyici ekle
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateCustomerStatus(customerInfo);
      });

      // Firebase Auth ile Senkronizasyon (Login)
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          debugPrint('👤 [RevenueCat] Kullanıcı giriş yaptı: ${user.uid}');
          await Purchases.logIn(user.uid);
          
          // ESKİ KULLANICILAR İÇİN OTOMATİK MİGRASYON / SENKRONİZASYON
          // Kullanıcı "Geri Yükle"ye basmadan aboneliği algılamak için.
          debugPrint('🔄 [RevenueCat] Otomatik senkronizasyon yapılıyor...');
          try {
             await Purchases.syncPurchases();
          } catch (e) {
             debugPrint('⚠️ [RevenueCat] Sync hatası (Önemli değil): $e');
          }
        } else {
           debugPrint('🚪 [RevenueCat] Kullanıcı çıkış yaptı');
           
           // State'i temizle
           _isPremium = false;
           _isLifetimeNoAds = false;
           _purchasedBooks.clear();
           notifyListeners();
           
           if (!await Purchases.isAnonymous) {
             await Purchases.logOut();
           }
        }
        // Logout sonrası anonim customer info çekmeye gerek olabilir veya olmayabilir,
        // ama temiz ui için yukarıdaki temizlik şart.
        await _fetchCustomerInfo();
      });

      await _fetchCustomerInfo();
      // Önce legacy kontrolü yap (Firebase)
      await _checkLegacyPermissions(onLegacyFound: (a,b){});
      await fetchProducts(); // Offerings'i çek

      _isInitialized = true;
      debugPrint('✅ [RevenueCat] Başlatıldı');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ [RevenueCat] Başlatma hatası: $e');
      _lastError = 'Başlatılamadı: $e';
    }
  }

  // Müşteri bilgisini çek ve işle
  Future<void> _fetchCustomerInfo() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateCustomerStatus(customerInfo);
    } catch (e) {
      debugPrint('❌ [RevenueCat] CustomerInfo hatası: $e');
    }
  }

  // Durumu güncelle
  Future<void> _updateCustomerStatus(CustomerInfo customerInfo) async {
    final EntitlementInfo? premiumEntitlement = customerInfo.entitlements.all['premium'];
    final EntitlementInfo? adsFreeEntitlement = customerInfo.entitlements.all['ads_free'];
    
    // RevenueCat'den gelen durum
    bool newPremiumStatus = premiumEntitlement?.isActive ?? false;
    bool newAdsFreeStatus = adsFreeEntitlement?.isActive ?? false;

    // HIBRID KONTROL: Her durumda legacy kontrolü yap ki kitaplar ve reklam kaldırma gelsin
    await _checkLegacyPermissions(
      onLegacyFound: (legacyPremium, legacyAdsFree) {
        if (legacyPremium) newPremiumStatus = true;
        
        // Eğer yeni sistemde ads_free yoksa ama eskide varsa, eskiyi kabul et
        if (!newAdsFreeStatus && legacyAdsFree) {
           newAdsFreeStatus = true;
        }
      }
    );
    
    // Değişiklik varsa güncelle
    if (_isPremium != newPremiumStatus || _isLifetimeNoAds != newAdsFreeStatus) {
       _isPremium = newPremiumStatus;
       _isLifetimeNoAds = newAdsFreeStatus;
       notifyListeners();
       debugPrint('🔄 [PurchaseManager] Durum Güncellendi -> Premium: $_isPremium, AdsFree: $_isLifetimeNoAds');
    }
  }

  // Reklam kaldırma ID'leri (Legacy)
  static const List<String> _legacyAdsIds = [
    'remove_ads', 'ads_remove', 'reklam_kaldir', 'reklam_kaldirma',
    'ads_free', 'no_ads', 'ad_free', 'premium_ads', 'adsfree', 'noads',
    'lifetime_ads', 'removeads'
  ];

  // Aktif kitabı var mı? (Reklam kaldırma hariç)
  bool get hasActiveBooks {
    if (_purchasedBooks.isEmpty) return false;
    // Eğer tüm satın alımları sadece reklam kaldırmadan ibaretse false dön
    return _purchasedBooks.any((id) => !_legacyAdsIds.contains(id.toLowerCase()));
  }

  // Eski sistemdeki (Firestore) satın alımları kontrol et
  Future<void> _checkLegacyPermissions({
    required Function(bool isLegacyPremium, bool isLegacyAdsFree) onLegacyFound
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return;
      
      final data = doc.data()!;
      bool legacyAdsFree = false;

      // 1. Ömür Boyu Reklam Kaldırma Kontrolü
      // Farklı varyasyonları kontrol et (isAdsRemoved, adsRemoved, ads_removed)
      // Tip kontrolü de yap (bool, string, vb)
      bool checkBoolField(String field) {
        final val = data[field];
        if (val == true) return true;
        if (val is String && val.toLowerCase() == 'true') return true;
        if (val is int && val == 1) return true;
        return false;
      }

      if (checkBoolField('lifetimeAdsFree') || 
          checkBoolField('isAdsRemoved') || 
          checkBoolField('adsRemoved') || 
          checkBoolField('ads_removed') ||
          checkBoolField('removeAds') || 
          checkBoolField('is_ads_removed')) {
        legacyAdsFree = true;
        debugPrint('🏛️ [PurchaseManager] Eski sistemden "Reklam Kaldırma" hakkı bulundu (Field Check: lifetimeAdsFree veya diğerleri).');
      }

      // 2. Satın Alınan Kitapları Yükle & remove_ads kontrolü
      if (data['purchasedBooks'] is List) {
        final List<dynamic> books = data['purchasedBooks'];
        
        // Kitapları hafızaya set olarak al
        _purchasedBooks = books.map((e) => e.toString()).toSet();
        debugPrint('📚 [PurchaseManager] Eski satın alınan kitaplar yüklendi: $_purchasedBooks');

        // Liste içinde remove_ads var mı?
        if (books.any((bookId) => _legacyAdsIds.contains(bookId.toString().toLowerCase()))) {
           legacyAdsFree = true;
           debugPrint('🏛️ [PurchaseManager] Eski sistemden "Reklam Kaldırma" hakkı bulundu (purchasedBooks array).');
        }
      }

      // NOT: Eskiden "Premium" diye bir şey olmadığı için legacyPremium hep false döner.
      onLegacyFound(false, legacyAdsFree);
      
    } catch (e) {
      debugPrint('⚠️ [PurchaseManager] Legacy kontrol hatası: $e');
    }
  }

  // Ürünleri (Offerings) çek
  Future<void> fetchProducts() async {
    try {
      _offerings = await Purchases.getOfferings();
      if (_offerings != null && _offerings!.current != null) {
         debugPrint('📦 [RevenueCat] Offerings yüklendi. Paketler: ${_offerings!.current!.availablePackages.length}');
      }
    } catch (e) {
      debugPrint('❌ [RevenueCat] Offerings hatası: $e');
    }
  }
  
  // Fiyat bilgisi al
  String getPrice(String packageId) {
    if (_offerings == null || _offerings!.current == null) return '';
    
    // Basit eşleşme: 'monthly' veya 'yearly' içeren paketleri bul
    try {
      if (packageId == 'monthly' && _offerings!.current!.monthly != null) {
        return _offerings!.current!.monthly!.storeProduct.priceString;
      }
      if (packageId == 'yearly' && _offerings!.current!.annual != null) {
        return _offerings!.current!.annual!.storeProduct.priceString;
      }
      
      // Fallback: Identifier içinde ara
       final p = _offerings!.current!.availablePackages.firstWhere(
        (p) => p.identifier.toLowerCase().contains(packageId.toLowerCase()),
      );
      return p.storeProduct.priceString;
    } catch (_) {
      return '';
    }
  }

  // Yıllık planın aylık maliyeti (Basit hesap)
  String getMonthlyCostForYearly() {
    try {
      final annualPackage = _offerings?.current?.annual;
      if (annualPackage != null) {
        final price = annualPackage.storeProduct.price;
        final monthlyCost = price / 12;
        return '${annualPackage.storeProduct.currencyCode} ${monthlyCost.toStringAsFixed(2)} /ay'; 
      }
    } catch (_) {}
    return '';
  }

  // Satın Al (Paket)
  Future<void> buyPackage(Package package) async {
    try {
      _lastError = '';
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      _updateCustomerStatus(customerInfo);
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        _lastError = 'Satın alma hatası: ${e.message}';
        debugPrint('❌ [RevenueCat] Satın alma hatası: $e');
        notifyListeners();
      }
    } catch (e) {
        _lastError = 'Beklenmedik hata: $e';
        notifyListeners();
    }
  }

  Future<void> buyPremiumMonthly() async {
    Package? package = _offerings?.current?.monthly;
    
    // Eğer standart 'monthly' boşsa, içinde 'monthly' geçen ilk paketi ara
    if (package == null && _offerings?.current != null) {
      try {
        package = _offerings!.current!.availablePackages.firstWhere(
          (p) => p.identifier.toLowerCase().contains('monthly')
        );
      } catch (_) {}
    }

    if (package != null) {
      await buyPackage(package);
    } else {
      _lastError = 'Aylık paket bulunamadı. Lütfen: \n1. RevenueCat panelinde Products kısmında App olarak "Test Store" değil, gerçek uygulamanızın seçili olduğunu.\n2. Products içindeki Product IDlerin Google Play Console ile aynı olduğunu kontrol edin.';
      notifyListeners();
    }
  }

  Future<void> buyPremiumYearly() async {
    Package? package = _offerings?.current?.annual;
    
    // Eğer standart 'annual' boşsa, içinde 'yearly' veya 'annual' geçen ilk paketi ara
    if (package == null && _offerings?.current != null) {
      try {
        package = _offerings!.current!.availablePackages.firstWhere(
          (p) => p.identifier.toLowerCase().contains('yearly') || p.identifier.toLowerCase().contains('annual')
        );
      } catch (_) {}
    }

    if (package != null) {
      await buyPackage(package);
    } else {
      _lastError = 'Yıllık paket bulunamadı. Lütfen: \n1. RevenueCat panelinde Products kısmında App olarak "Test Store" değil, gerçek uygulamanızın seçili olduğunu.\n2. Products içindeki Product IDlerin Google Play Console ile aynı olduğunu kontrol edin.';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    try {
      debugPrint('🔄 [RevenueCat] Restore...');
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateCustomerStatus(customerInfo);
      
      if (customerInfo.entitlements.active.isEmpty) {
        _lastError = 'Aktif bir abonelik bulunamadı.';
        notifyListeners(); 
      }
    } catch (e) {
       _lastError = 'Restore hatası: $e';
       notifyListeners();
    }
  }

  // LEGACY METODLAR (Eski kodlarla uyumluluk için)
  Future<void> loadUserPurchases() async {
    await _fetchCustomerInfo();
  }

  Future<void> mockSetPremium() async {
    if (kDebugMode) {
      _isPremium = true;
      notifyListeners();
    }
  }

  Future<void> mockResetPremium() async {
    if (kDebugMode) {
      _isPremium = false;
      _isLifetimeNoAds = false;
      notifyListeners();
    }
  }
}
