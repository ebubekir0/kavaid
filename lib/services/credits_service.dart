import 'package:flutter/foundation.dart';
import 'purchase_manager.dart';

/// CreditsService artık sadece PurchaseManager'ın bir proxy'sidir.
/// Tüm premium/reklamsız kontrolü PurchaseManager üzerinden yapılır.
/// Bu dosya geriye dönük uyumluluk için korunmaktadır.
class CreditsService extends ChangeNotifier {
  // Singleton instance
  static final CreditsService _instance = CreditsService._internal();
  factory CreditsService() => _instance;
  
  final PurchaseManager _purchaseManager = PurchaseManager();
  
  CreditsService._internal() {
    // PurchaseManager'ı dinle ve değişiklikleri yansıt
    _purchaseManager.addListener(_onPurchaseManagerChanged);
  }
  
  void _onPurchaseManagerChanged() {
    // PurchaseManager değiştiğinde bu servisi de güncelle
    notifyListeners();
  }
  
  // ========== ANA GETTER'LAR (PurchaseManager'dan) ==========
  
  /// Premium durumu - PurchaseManager'dan alınır
  bool get isPremium => _purchaseManager.isPremium;
  
  /// Ömür boyu reklamsız durumu - PurchaseManager'dan alınır
  bool get isLifetimeAdsFree => _purchaseManager.isLifetimeNoAds;
  
  /// Premium bitiş tarihi (artık kullanılmıyor)
  DateTime? get premiumExpiry => null;
  
  // ========== ESKİ SİSTEM UYUMLULUK METODLARI ==========
  
  /// Artık bir işlem yapmaz, PurchaseManager kendi initialize eder
  Future<void> initialize() async {
    debugPrint('🔄 [CreditsService] initialize() - PurchaseManager\'a yönlendirildi');
    // PurchaseManager zaten main.dart'ta initialize ediliyor
  }
  
  /// Premium durumu kontrol et
  Future<void> checkPremiumStatus() async {
    await _purchaseManager.loadUserPurchases();
  }
  
  /// Eski metodlar - artık kullanılmıyor ama geriye uyumluluk için
  Future<void> activatePremiumForever() async {
    debugPrint('⚠️ [CreditsService] activatePremiumForever() çağrıldı - DEVRE DIŞI');
    // Artık Play Store üzerinden yapılmalı
  }
  
  Future<void> activatePremiumMonthly() async {
    debugPrint('⚠️ [CreditsService] activatePremiumMonthly() çağrıldı - DEVRE DIŞI');
    // Artık Play Store üzerinden yapılmalı
  }
  
  Future<void> cancelPremium() async {
    debugPrint('⚠️ [CreditsService] cancelPremium() çağrıldı - DEVRE DIŞI');
    // Artık Play Store üzerinden yapılmalı
  }
  
  Future<bool> togglePremiumStatus() async {
    debugPrint('⚠️ [CreditsService] togglePremiumStatus() çağrıldı - DEVRE DIŞI');
    return isPremium;
  }
  
  Future<void> setLifetimeAdsFree(bool value) async {
    debugPrint('⚠️ [CreditsService] setLifetimeAdsFree() çağrıldı - DEVRE DIŞI');
    // Artık PurchaseManager yönetiyor
  }
  
  Future<void> toggleAdsFreeForTest() async {
    // Debug modda test için
    if (kDebugMode) {
      if (_purchaseManager.isPremium) {
        await _purchaseManager.mockResetPremium();
      } else {
        await _purchaseManager.mockSetPremium();
      }
    }
  }
  
  // ========== KREDİ SİSTEMİ (ARTIK YOK) ==========
  
  int get credits => 999; // Sınırsız
  bool get hasInitialCredits => true;
  
  Future<bool> canOpenWord(String kelime) async => true;
  Future<bool> consumeCredit(String kelime) async => true;
  
  @override
  void dispose() {
    _purchaseManager.removeListener(_onPurchaseManagerChanged);
    super.dispose();
  }
}