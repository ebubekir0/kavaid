import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'credits_service.dart';
import 'admob_service.dart';
import '../services/turkce_analytics_service.dart';

class OneTimePurchaseService extends ChangeNotifier {
  static const String _removeAdsEntitlement = 'ads_free';
  
  // Singleton
  static final OneTimePurchaseService _instance = OneTimePurchaseService._internal();
  factory OneTimePurchaseService() => _instance;
  OneTimePurchaseService._internal();

  bool _isLifetimeAdsFree = false;
  String _lastError = '';
  
  bool get isLifetimeAdsFree => _isLifetimeAdsFree;
  String get lastError => _lastError;
  
  // RevenueCat ile bu daha basit, offering'den 'lifetime' paketini bulup fiyatını dönebiliriz.
  String get removeAdsPrice => '₺69.99'; // Placeholder, offering'den çekilebilir.
  
  // LEGACY: Eski kodlarla uyumluluk için
  List<dynamic> get products => []; // Artık kullanılmıyor ama hata vermemesi için
  bool get isAvailable => true;
  bool get purchasePending => false;
  bool get hasError => _lastError.isNotEmpty;

  Future<void> initialize() async {
    // RevenueCat zaten PurchaseManager tarafından configure ediliyor.
    // Biz sadece dinleyebiliriz veya CustomerInfo çekebiliriz.
    // Ancak emin olmak için listener ekleyelim.
    Purchases.addCustomerInfoUpdateListener((info) {
      _updateStatus(info);
    });
    
    try {
      final info = await Purchases.getCustomerInfo();
      _updateStatus(info);
    } catch (_) {}
  }

  void _updateStatus(CustomerInfo info) {
    final bool newStatus = info.entitlements.all[_removeAdsEntitlement]?.isActive ?? false;
    if (_isLifetimeAdsFree != newStatus) {
      _isLifetimeAdsFree = newStatus;
      CreditsService().setLifetimeAdsFree(newStatus);
      notifyListeners();
    }
  }

  Future<bool> buyRemoveAds() async {
    try {
      _lastError = '';
      if (FirebaseAuth.instance.currentUser == null) {
        _lastError = 'Giriş yapmalısınız.';
        notifyListeners();
        return false;
      }

      // 'lifetime' paketini bulmaya çalışalım
      final offerings = await Purchases.getOfferings();
      final lifetimePackage = offerings.current?.lifetime; // RevenueCat dashboard'da "Lifetime" olarak işaretlenmeli

      if (lifetimePackage != null) {
         final info = await Purchases.purchasePackage(lifetimePackage);
         _updateStatus(info);
         if (_isLifetimeAdsFree) {
           await TurkceAnalyticsService.premiumSatinAlinaBasarili('tek_seferlik', 0); // Fiyat bilgisi eklenebilir
           AdMobService().clearInAppActionFlag();
           return true;
         }
      } else {
        _lastError = 'Paket bulunamadı (Lifetime).';
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        _lastError = e.message ?? 'Hata oluştu';
      }
    } catch (e) {
      _lastError = 'Beklenmedik hata: $e';
    }
    notifyListeners();
    return false;
  }
  
  // Eski metodların boş implementasyonları (uygulama patlamasın diye)
  Future<void> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _updateStatus(info);
    } catch (_) {}
  }
  
  Future<void> debugGrantLifetimeForCurrentUser() async {
    // Debug modunda RC ile grant zordur (sandbox user gerekir), şimdilik boş geçiyoruz.
  }
  
  // LEGACY: Eski kodlarla uyumluluk
  Future<void> loadProducts() async {
    // Artık RevenueCat offerings kullanılıyor, bu boş kalabilir.
  }
}
