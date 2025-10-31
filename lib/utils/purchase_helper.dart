import 'dart:async';
import 'package:flutter/material.dart';

/// In-app purchase işlemlerini güvenli bir şekilde yönetmek için yardımcı sınıf
/// "Reply already submitted" hatasını önler
class PurchaseHelper {
  static final Map<String, DateTime> _lastLoadRequests = {};
  static final Map<String, Completer> _loadingCompleters = {};
  static const Duration _minRequestInterval = Duration(milliseconds: 500);
  
  /// Ürün detaylarını güvenli bir şekilde yükler
  /// Aynı ürün için çoklu istekleri engeller
  static Future<void> safeLoadProduct({
    required String productId,
    required Future<void> Function() loadFunction,
  }) async {
    // Eğer bu ürün için aktif bir yükleme varsa, onu bekle
    if (_loadingCompleters.containsKey(productId)) {
      await _loadingCompleters[productId]!.future;
      return;
    }
    
    // Son istek zamanını kontrol et
    final lastRequest = _lastLoadRequests[productId];
    if (lastRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(lastRequest);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }
    
    // Yeni bir completer oluştur
    final completer = Completer<void>();
    _loadingCompleters[productId] = completer;
    _lastLoadRequests[productId] = DateTime.now();
    
    try {
      await loadFunction();
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      // Completer'ı temizle
      _loadingCompleters.remove(productId);
    }
  }
  
  /// Tüm önbelleği temizler
  static void clearCache() {
    _lastLoadRequests.clear();
    _loadingCompleters.clear();
  }
  
  /// Belirli bir ürün için önbelleği temizler
  static void clearProductCache(String productId) {
    _lastLoadRequests.remove(productId);
    _loadingCompleters.remove(productId);
  }
}
