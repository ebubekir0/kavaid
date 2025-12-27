import 'package:flutter/foundation.dart';
import 'purchase_manager.dart';

/// SubscriptionService artık kullanılmıyor.
/// Tüm abonelik işlemleri PurchaseManager üzerinden yapılır.
/// Bu dosya geriye dönük uyumluluk için korunmaktadır.
class SubscriptionService extends ChangeNotifier {
  // Singleton
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();
  
  final PurchaseManager _purchaseManager = PurchaseManager();
  
  // ========== GETTER'LAR ==========
  
  bool get isAvailable => true;
  bool get purchasePending => false;
  List<dynamic> get products => [];
  String get lastError => '';
  bool get hasError => false;
  
  /// Aylık fiyat - PurchaseManager'dan alınır
  String get monthlyPrice => _purchaseManager.getPrice('monthly').isEmpty 
      ? '₺79,99' 
      : _purchaseManager.getPrice('monthly');
  
  // ========== METODLAR (PurchaseManager'a yönlendirir) ==========
  
  Future<void> initialize() async {
    debugPrint('⚠️ [SubscriptionService] initialize() - Artık PurchaseManager kullanılıyor');
    // PurchaseManager zaten main.dart'ta initialize ediliyor
  }
  
  Future<void> loadProducts() async {
    await _purchaseManager.fetchProducts();
  }
  
  Future<bool> buySubscription() async {
    debugPrint('⚠️ [SubscriptionService] buySubscription() -> PurchaseManager.buyPremiumMonthly()');
    await _purchaseManager.buyPremiumMonthly();
    return true;
  }
  
  Future<void> restorePurchases() async {
    await _purchaseManager.loadUserPurchases();
  }
  
  Future<void> checkSubscriptionStatus() async {
    await _purchaseManager.loadUserPurchases();
  }
  
  void clearError() {
    // Artık kullanılmıyor
  }
}