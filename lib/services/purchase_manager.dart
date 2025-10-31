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
  bool _isAdsFree = false;
  Set<String> _purchasedBooks = {};
  String _lastError = '';
  
  // Product mappings
  static const Map<String, String> _products = {
    'ads_free': 'kavaid_remove_ads_lifetime',
    'book_1': 'kavaid_kitab_kiraath_1',
    'book_2': 'kavaid_book_kiraath_2', 
    'book_3': 'kavaid_book_kiraath_3',
  };

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAdsFree => _isAdsFree;
  Future<bool> get isAvailable async {
  return await _inAppPurchase.isAvailable();
}
  String get lastError => _lastError;
  Set<String> get purchasedBooks => _purchasedBooks;

  // Initialize
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🚀 [PurchaseManager] Başlatılıyor...');
      
      // Purchase stream'i dinle
      _subscription = _inAppPurchase.purchaseStream.listen(
        _listenToPurchaseUpdated,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('❌ [PurchaseManager] Stream hatası: $error'),
      );

      // Kullanıcı verilerini yükle
      await _loadUserPurchases();
      
      _isInitialized = true;
      debugPrint('✅ [PurchaseManager] Başlatıldı');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Başlatma hatası: $e');
      _lastError = 'Başlatılamadı: $e';
    }
  }

  // Kullanıcı satın almalarını yükle
  Future<void> _loadUserPurchases() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('🚪 [PurchaseManager] Giriş yapılmamış');
        return;
      }

      // Local cache'den yükle
      final prefs = await SharedPreferences.getInstance();
      _isAdsFree = prefs.getBool('is_ads_free') ?? false;
      final books = prefs.getStringList('purchased_books') ?? [];
      _purchasedBooks = books.toSet();

      // Firestore'dan yükle
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('purchases')
          .doc('active')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _isAdsFree = data['is_ads_free'] ?? false;
        final books = List<String>.from(data['purchased_books'] ?? []);
        _purchasedBooks = books.toSet();
        
        // Local cache'i güncelle
        await _saveToPrefs();
      }

      debugPrint('📦 [PurchaseManager] Satın almalar yüklendi: AdsFree=$_isAdsFree, Books=$_purchasedBooks');
      
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Satın alma yükleme hatası: $e');
    }
  }

  // Satın alma dinleyici
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('🔄 [PurchaseManager] Satın alma güncellemesi: ${purchaseDetails.status}');
      
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _processPurchase(purchaseDetails);
      }
      
      // Transaction'ı tamamla
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

      // Doğrula
      if (!_isValidPurchase(purchase)) {
        debugPrint('❌ [PurchaseManager] Geçersiz satın alma');
        return;
      }

      // Ürün tipini belirle
      final productType = _getProductType(purchase.productID);
      if (productType == null) {
        debugPrint('❌ [PurchaseManager] Bilinmeyen ürün: ${purchase.productID}');
        return;
      }

      // Firestore'a kaydet
      await _savePurchaseToFirestore(
        userId: currentUser.uid,
        productType: productType,
        purchase: purchase,
      );

      // Local state'i güncelle
      _updateLocalState(productType);

      debugPrint('✅ [PurchaseManager] Satın alma işlendi: $productType');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Satın alma işleme hatası: $e');
      _lastError = 'Satın alma işlenemedi: $e';
    }
  }

  // Satın alma doğrulama
  bool _isValidPurchase(PurchaseDetails purchase) {
    final purchaseId = purchase.purchaseID ?? '';
    if (!purchaseId.startsWith('GPA.') || purchaseId.length <= 10) {
      return false;
    }
    return true;
  }

  // Ürün tipini getir
  String? _getProductType(String productId) {
    for (final entry in _products.entries) {
      if (entry.value == productId) {
        return entry.key;
      }
    }
    return null;
  }

  // Firestore'a kaydet
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

      await docRef.set({
        'is_ads_free': _isAdsFree || productType == 'ads_free',
        'purchased_books': _purchasedBooks.toList(),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('💾 [PurchaseManager] Firestore\'a kaydedildi: $productType');
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Firestore kayıt hatası: $e');
    }
  }

  // Local state'e kaydet
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_ads_free', _isAdsFree);
      await prefs.setStringList('purchased_books', _purchasedBooks.toList());
      debugPrint('💾 [PurchaseManager] Local state kaydedildi');
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Local state kaydetme hatası: $e');
    }
  }

  // Local state'i güncelle
  void _updateLocalState(String productType) {
    if (productType == 'ads_free') {
      _isAdsFree = true;
    } else if (productType.startsWith('book_')) {
      _purchasedBooks.add(productType);
    }
    
    // Local'e kaydet
    _saveToPrefs();
    
    // Analytics gönder
    _sendAnalytics(productType);

    debugPrint('✅ [PurchaseManager] Satın alma işlendi: $productType');
    notifyListeners();
  }

  // Analytics gönder
  Future<void> _sendAnalytics(String productType) async {
    try {
      // Analytics gönderilecek -暂时 basitleştirildi
      debugPrint('📊 [PurchaseManager] Analytics gönder: $productType');
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Analytics hatası: $e');
    }
  }

  // Reklam kaldırma satın al
  Future<bool> purchaseAdsFree() async {
    return await _purchaseProduct('ads_free');
  }

  // Kitap satın al
  Future<bool> purchaseBook(String bookId) async {
    final productKey = 'book_${bookId.split('_').last}';
    return await _purchaseProduct(productKey);
  }

  // Ürün satın al
  Future<bool> _purchaseProduct(String productKey) async {
    try {
      if (!(await isAvailable)) {
        _lastError = 'Store kullanılamıyor';
        return false;
      }

      final productId = _products[productKey];
      if (productId == null) {
        _lastError = 'Ürün bulunamadı';
        return false;
      }

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        _lastError = 'Ürün detayları alınamadı';
        return false;
      }

      final purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );

      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Satın alma hatası: $e');
      _lastError = 'Satın alma hatası: $e';
      return false;
    }
  }

  // Fiyat getir
  String getProductPrice(String productKey) {
    switch (productKey) {
      case 'ads_free':
        return '₺149,99';
      case 'book_1':
      case 'book_2':
      case 'book_3':
        return '₺89,99';
      default:
        return '₺89,99';
    }
  }

  // Kitap satın alınmış mı
  bool isBookPurchased(String bookId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    final bookNumber = bookId.split('_').last;
    return _purchasedBooks.contains('book_$bookNumber');
  }

  // Satın alma geri yükle
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('✅ [PurchaseManager] Geri yükleme başlatıldı');
    } catch (e) {
      debugPrint('❌ [PurchaseManager] Geri yükleme hatası: $e');
      _lastError = 'Geri yükleme hatası: $e';
    }
  }

  // DEBUG: Satın alma durumunu yazdır
  Future<void> debugPrintPurchaseStatus() async {
    debugPrint('🔍 [PurchaseManager] Satın Alma Durumu:');
    debugPrint('  - Başlatıldı: $isInitialized');
    debugPrint('  - Ads Free: $isAdsFree');
    debugPrint('  - Kitap Satın Almaları: $_purchasedBooks');
    debugPrint('  - Son Hata: $lastError');
  }

  // DEBUG: Mock premium ayarla
  Future<void> mockSetPremium() async {
    if (kDebugMode) {
      _isAdsFree = true;
      await _saveToPrefs();
      notifyListeners();
      debugPrint('🧪 [PurchaseManager] Mock premium ayarlandı');
    }
  }

  // DEBUG: Mock premium sıfırla
  Future<void> mockResetPremium() async {
    if (kDebugMode) {
      _isAdsFree = false;
      _purchasedBooks.clear();
      await _saveToPrefs();
      notifyListeners();
      debugPrint('🧪 [PurchaseManager] Mock premium sıfırlandı');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
