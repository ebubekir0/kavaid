import 'dart:async';
import 'package:flutter/material.dart';
import '../services/one_time_purchase_service.dart';
import 'purchase_helper.dart';

/// OneTimePurchaseService için güvenli wrapper
/// "Reply already submitted" hatasını önlemek için kullanılır
class SafePurchaseWrapper {
  static final OneTimePurchaseService _service = OneTimePurchaseService();
  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;
  
  /// Servisi güvenli bir şekilde başlatır
  static Future<void> initializeService() async {
    // Eğer zaten başlatılmışsa veya başlatılıyorsa bekle
    if (_isInitialized) {
      debugPrint('⚠️ [SafePurchaseWrapper] Servis zaten başlatılmış');
      return;
    }
    
    if (_initCompleter != null) {
      debugPrint('⏳ [SafePurchaseWrapper] Servis başlatılıyor, bekleniyor...');
      await _initCompleter!.future;
      return;
    }
    
    _initCompleter = Completer<void>();
    
    try {
      debugPrint('🚀 [SafePurchaseWrapper] OneTimePurchaseService başlatılıyor...');
      await _service.initialize();
      _isInitialized = true;
      _initCompleter!.complete();
      debugPrint('✅ [SafePurchaseWrapper] OneTimePurchaseService başarıyla başlatıldı');
    } catch (e) {
      debugPrint('❌ [SafePurchaseWrapper] Başlatma hatası: $e');
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }
  
  /// Ürünleri güvenli bir şekilde yükler
  static Future<void> safeLoadProducts() async {
    if (!_isInitialized) {
      debugPrint('⚠️ [SafePurchaseWrapper] Servis başlatılmamış, önce başlatılıyor...');
      await initializeService();
    }
    
    await PurchaseHelper.safeLoadProduct(
      productId: 'kavaid_remove_ads_lifetime',
      loadFunction: () => _service.loadProducts(),
    );
  }
  
  /// Satın alma işlemini güvenli bir şekilde başlatır
  static Future<bool> safeBuyRemoveAds() async {
    if (!_isInitialized) {
      debugPrint('⚠️ [SafePurchaseWrapper] Servis başlatılmamış, önce başlatılıyor...');
      await initializeService();
    }
    
    // Ürünler yüklenmemişse önce yükle
    if (_service.products.isEmpty) {
      await safeLoadProducts();
    }
    
    return await _service.buyRemoveAds();
  }
  
  /// Servise doğrudan erişim (gerektiğinde)
  static OneTimePurchaseService get service => _service;
  
  /// Servisin başlatılıp başlatılmadığını kontrol eder
  static bool get isInitialized => _isInitialized;
}
