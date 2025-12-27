import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../utils/purchase_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_store_service.dart';
import 'turkce_analytics_service.dart';

/// Non-consumable kitap satın alma servisi
/// SKU eşlemesi:
///  - kitab_kiraah_1 -> kavaid_book_kiraat_1 (Play Console managed product)
class BookPurchaseService extends ChangeNotifier {
  BookPurchaseService._internal();
  static final BookPurchaseService _instance = BookPurchaseService._internal();
  factory BookPurchaseService() => _instance;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final BookStoreService _bookStore = BookStoreService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  bool _purchasePending = false;
  String _lastError = '';
  // Dinamik olarak seçilen kitap için ürün detayı tutulur
  ProductDetails? _currentProduct;
  String? _currentBookId; // kitab_kiraah_1 gibi
  bool _isLoadingProduct = false; // Ürün yükleme kontrolü

  // BookId -> Store SKU (iOS ve Android için aynı)
  // App Store Connect ve Play Console'da aynı SKU'lar kullanılmalı
  static const Map<String, String> _skuMap = {
    'kitab_kiraah_1': 'kavaid_kitab_kiraah_1',  // 1. kitap
    'kitab_kiraah_2': 'kavaid_book_kiraat_2',   // 2. kitap 
    'kitab_kiraah_3': 'kavaid_book_kiraat_3',   // 3. kitap
    'taysir_sira': 'kavaid_taysir_sira',        // Sira kitabı
  };

  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  String get lastError => _lastError;
  bool get hasError => _lastError.isNotEmpty;
  ProductDetails? get currentProduct => _currentProduct;
  
  // Fallback fiyat bilgisi (Play Console bağlantısı yoksa)
  String get currentBookPrice {
    if (_currentProduct != null) {
      return _currentProduct!.price;
    }
    // Tüm kitaplar için tek fiyat
    return '₺89,99';
  }

  Future<void> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        _lastError = 'In-App Purchase bu cihazda kullanılamıyor';
        notifyListeners();
        return;
      }

      // Eğer subscription zaten varsa tekrar oluşturma
      if (_subscription != null) {
        return;
      }
      
      final purchaseUpdated = _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _listenToPurchaseUpdated,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          _lastError = 'Satın alma dinleme hatası: $error';
          notifyListeners();
        },
      );
    } catch (e) {
      _lastError = 'Kitap satın alma servisi başlatılamadı: $e';
      notifyListeners();
    }
  }

  Future<void> loadProductFor(String bookId) async {
    _lastError = '';
    _currentBookId = bookId;

    final sku = _skuMap[bookId];
    
    if (sku == null) {
      _lastError = 'Bu kitap için Play ürün kimliği tanımlı değil';
      notifyListeners();
      return;
    }

    // Eğer aynı ürün zaten yüklenmişse tekrar yükleme
    if (_currentProduct != null && _currentProduct!.id == sku) {
      return;
    }

    // PurchaseHelper kullanarak güvenli yükleme yap
    await PurchaseHelper.safeLoadProduct(
      productId: sku,
      loadFunction: () async {
        final resp = await _inAppPurchase.queryProductDetails({sku});
        if (resp.error != null) {
          _lastError = 'Ürün yükleme hatası: ${resp.error!.message}';
          _currentProduct = null;
          notifyListeners();
          return;
        }
        if (resp.productDetails.isEmpty) {
          _lastError = 'Play Console ürün bulunamadı: $sku';
          _currentProduct = null;
          notifyListeners();
          return;
        }
        _currentProduct = resp.productDetails.first;
        _lastError = ''; // Başarılı yükleme
        notifyListeners();
      },
    );
  }

  Future<bool> buyBook(String bookId) async {
    try {
      _lastError = '';
      if (FirebaseAuth.instance.currentUser == null) {
        _lastError = 'Satın alma için önce giriş yapmalısınız';
        notifyListeners();
        return false;
      }
      if (!_isAvailable) {
        _lastError = 'Store kullanılamıyor';
        notifyListeners();
        return false;
      }

      if (_currentBookId != bookId || _currentProduct == null) {
        await loadProductFor(bookId);
        if (_currentProduct == null) return false;
      }

      if (_purchasePending) {
        _purchasePending = false;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final purchaseParam = PurchaseParam(productDetails: _currentProduct!);
      _purchasePending = true;
      notifyListeners();

      final success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        _purchasePending = false;
        _lastError = 'Satın alma başlatılamadı';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _purchasePending = false;
      _lastError = 'Satın alma hatası: $e';
      notifyListeners();
      return false;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> list) async {
    for (final p in list) {
      
      // ÖNEMLİ: Sadece kitap ürünlerini işle
      // Reklam kaldırma satın almaları bu servisi ilgilendirmez
      bool isBookProduct = _skuMap.containsValue(p.productID);
      if (!isBookProduct) {
        // Eğer satın alma tamamlanmamışsa tamamla (başka servis işleyecek)
        if (p.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(p);
        }
        continue; // Bu satın almayı atla
      }
      if (p.status == PurchaseStatus.pending) {
        _purchasePending = true;
        _lastError = '';
        notifyListeners();
      } else if (p.status == PurchaseStatus.error) {
        _purchasePending = false;
        _lastError = p.error?.message ?? 'Satın alma hatası';
        notifyListeners();
      } else if (p.status == PurchaseStatus.purchased) {
        debugPrint('✅ [BookPurchase] PURCHASED event alındı');
        _purchasePending = false;
        _verifyAndDeliver(p);
      } else if (p.status == PurchaseStatus.restored) {
        debugPrint('🔄 [BookPurchase] RESTORED event alındı');
        
        // RESTORED durumunda kullanıcı kontrolü yap
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          debugPrint('❌ [BookPurchase] Restore için giriş gerekli, atlanıyor');
          // Complete et ama işleme
          if (p.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(p);
          }
          continue;
        }
        
        // Firestore'da bu kullanıcıya ait bu kitap satın alması var mı?
        final String? bookId = _bookIdFromProductId(p.productID);
        if (bookId == null) {
          debugPrint('⚠️ [BookPurchase] Geçersiz kitap ürünü, restore atlanıyor');
          if (p.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(p);
          }
          continue;
        }
        
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        final purchasedBooks = doc.data()?['purchasedBooks'] as List<dynamic>?;
        if (purchasedBooks != null && purchasedBooks.contains(bookId)) {
          debugPrint('✅ [BookPurchase] Kullanıcıda $bookId zaten kayıtlı, restore işleniyor');
          _purchasePending = false;
          _verifyAndDeliver(p);
        } else {
          debugPrint('⚠️ [BookPurchase] Kullanıcıda $bookId kaydı yok, restore atlanıyor');
          // Restore'u atla ama complete et
          if (p.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(p);
          }
        }
      } else if (p.status == PurchaseStatus.canceled) {
        // Kullanıcı iptal etti: hiçbir teslimat yapma, state'i temizle
        _purchasePending = false;
        _lastError = 'Satın alma iptal edildi';
        notifyListeners();
      }

      if (p.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(p);
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails p) async {
    try {
      // Test için doğrudan geçerli sayıyoruz
      // Ürün kimliğinden doğru kitabı çözümle
      final String? bookId = _bookIdFromProductId(p.productID);
      if (bookId == null) {
        // Bu satın alma uygulamadaki kitaplardan birine ait değil; teslim etme
        _lastError = 'Geçersiz kitap ürünü: ${p.productID}';
        notifyListeners();
        return;
      }
      await _deliver(p, bookId);
      _lastError = '';
    } catch (e) {
      _lastError = 'Teslimat hatası: $e';
    }
    notifyListeners();
  }

  // Ürün SKU'sundan bookId elde et (ters eşleme)
  String? _bookIdFromProductId(String productId) {
    try {
      final entry = _skuMap.entries.firstWhere(
        (e) => e.value == productId,
        orElse: () => const MapEntry<String, String>('', ''),
      );
      if (entry.key.isEmpty) return null;
      return entry.key;
    } catch (_) {
      return null;
    }
  }

  Future<void> _deliver(PurchaseDetails p, String bookId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Oturum bulunamadı');
    }

    // Kullanıcının satın aldığı kitapları Firestore altında tutalım
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'purchasedBooks': FieldValue.arrayUnion([bookId]),
        'lastBookPurchaseAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (_) {}

    // Yerel ve UI senkronizasyonu için BookStoreService'e yaz
    await _bookStore.mockPurchase(bookId);

    // Analytics
    double price = 0.0;
    if (_currentProduct != null) {
      final priceString = _currentProduct!.price.replaceAll(RegExp(r'[^\d,.]'), '');
      final priceFormatted = priceString.replaceAll(',', '.');
      price = double.tryParse(priceFormatted) ?? 0.0;
    }
    await TurkceAnalyticsService.premiumSatinAlinaBasarili('kitap', price);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
