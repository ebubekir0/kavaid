import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'performance_utils.dart';

/// 🚀 PERFORMANCE MOD: Adaptif image cache ve memory yönetimi
class ImageCacheManager {
  static bool _isInitialized = false;
  
  // 🚀 PERFORMANCE MOD: Gelişmiş Image Cache Manager
  static Map<String, Map<String, int>> cacheSettings = {
    'high_end': {
      'max_size_mb': 300,
      'max_count': 3000,
      'background_size_mb': 150,
      'background_count': 1500,
    },
    'mid_range': {
      'max_size_mb': 200,
      'max_count': 2000,
      'background_size_mb': 100,
      'background_count': 1000,
    },
    'low_end': {
      'max_size_mb': 100,
      'max_count': 1000,
      'background_size_mb': 50,
      'background_count': 500,
    },
  };
  
  static void initialize() {
    if (kIsWeb) return;
    
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Cihaz kategorisine göre ayarları belirle
    final deviceCategory = PerformanceUtils.deviceCategory;
    final settings = cacheSettings[deviceCategory] ?? cacheSettings['mid_range']!;
    
    // Foreground cache ayarları
    PaintingBinding.instance.imageCache.maximumSizeBytes = 
        settings['max_size_mb']! * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSize = 
        settings['max_count']!;
    
    debugPrint('📈 Image cache başlatıldı: ${settings['max_size_mb']}MB, ${settings['max_count']} image (Kategori: $deviceCategory)');
  }
  
  // 🚀 PERFORMANCE MOD: Adaptif memory pressure handling
  static void handleMemoryPressure() {
    final isLowEnd = PerformanceUtils.isLowEndDevice;
    
    if (isLowEnd) {
      // Düşük performanslı cihazlarda agresif temizlik
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Cache boyutunu küçült
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
      PaintingBinding.instance.imageCache.maximumSize = 500;
      
      debugPrint('🧹 Agresif cache temizliği (düşük performans cihaz)');
    } else {
      // Normal cihazlarda kısmi temizlik
      final currentSize = PaintingBinding.instance.imageCache.currentSizeBytes;
      final maxSize = PaintingBinding.instance.imageCache.maximumSizeBytes;
      
      if (currentSize > maxSize * 0.8) {
        // Cache'in %20'sini temizle
        PaintingBinding.instance.imageCache.clear();
        debugPrint('🧹 Kısmi cache temizliği (memory pressure)');
      }
    }
    
    // Garbage collection tetikle
    SystemChannels.platform.invokeMethod('System.gc');
  }
  
  // 🚀 PERFORMANCE MOD: Background'a geçerken cache boyutunu küçült
  static void optimizeForBackground() {
    if (kIsWeb) return;
    
    final deviceCategory = PerformanceUtils.deviceCategory;
    final settings = cacheSettings[deviceCategory] ?? cacheSettings['mid_range']!;
    
    final sizeBefore = PaintingBinding.instance.imageCache.currentSizeBytes;
    final countBefore = PaintingBinding.instance.imageCache.currentSize;
    
    // Background cache ayarları
    PaintingBinding.instance.imageCache.maximumSizeBytes = 
        settings['background_size_mb']! * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSize = 
        settings['background_count']!;
    
    final sizeAfter = PaintingBinding.instance.imageCache.currentSizeBytes;
    final countAfter = PaintingBinding.instance.imageCache.currentSize;
    
    debugPrint('📉 Background cache optimize: ${(sizeBefore / 1024 / 1024).toStringAsFixed(1)}MB -> ${(sizeAfter / 1024 / 1024).toStringAsFixed(1)}MB');
    debugPrint('📉 Image count: $countBefore -> $countAfter');
  }
  
  // 🚀 PERFORMANCE MOD: Foreground'a dönerken cache boyutunu artır
  static void restoreForForeground() {
    if (kIsWeb) return;
    
    final deviceCategory = PerformanceUtils.deviceCategory;
    final settings = cacheSettings[deviceCategory] ?? cacheSettings['mid_range']!;
    
    // Foreground cache ayarlarına geri dön
    PaintingBinding.instance.imageCache.maximumSizeBytes = 
        settings['max_size_mb']! * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSize = 
        settings['max_count']!;
    
    debugPrint('📈 Foreground cache restore: ${settings['max_size_mb']}MB, ${settings['max_count']} images (Kategori: $deviceCategory)');
  }
  
  // 🚀 PERFORMANCE MOD: Manuel cache temizleme (düşük performans durumları için)
  static void clearCache({bool aggressive = false}) {
    if (kIsWeb) return;
    
    final sizeBefore = PaintingBinding.instance.imageCache.currentSizeBytes;
    final countBefore = PaintingBinding.instance.imageCache.currentSize;
    
    if (aggressive) {
      // 🚀 PERFORMANCE MOD: Agresif temizlik - tüm cache'i sil
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Düşük performanslı cihazlar için cache boyutunu minimize et
      if (PerformanceUtils.isLowEndDevice) {
        PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
        PaintingBinding.instance.imageCache.maximumSize = 500;
        debugPrint('🧹 Agresif cache temizliği (düşük performans cihaz)');
      }
    } else {
      // Normal temizlik
      PaintingBinding.instance.imageCache.clear();
    }
    
    final sizeAfter = PaintingBinding.instance.imageCache.currentSizeBytes;
    final countAfter = PaintingBinding.instance.imageCache.currentSize;
    
    debugPrint('🧹 Cache temizlendi: ${(sizeBefore / 1024 / 1024).toStringAsFixed(1)}MB -> ${(sizeAfter / 1024 / 1024).toStringAsFixed(1)}MB');
    debugPrint('🧹 Image count: $countBefore -> $countAfter');
  }
  
  // 🚀 PERFORMANCE MOD: Düşük memory durumları için acil cache temizleme
  static void onLowMemory() {
    if (kIsWeb) return;
    
    debugPrint('🆘 ACİL CACHE TEMİZLİĞİ!');
    
    // Tüm cache'i temizle
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    
    // Minimum cache boyutuna indir
    PaintingBinding.instance.imageCache.maximumSizeBytes = 25 * 1024 * 1024; // 25MB
    PaintingBinding.instance.imageCache.maximumSize = 250;
    
    debugPrint('🧹 Acil cache temizliği tamamlandı: 25MB, 250 images');
  }
  
  // 🚀 PERFORMANCE MOD: Cache durumunu raporla
  static void reportCacheStatus() {
    if (kIsWeb) return;
    
    final currentSize = PaintingBinding.instance.imageCache.currentSizeBytes;
    final maxSize = PaintingBinding.instance.imageCache.maximumSizeBytes;
    final currentCount = PaintingBinding.instance.imageCache.currentSize;
    final maxCount = PaintingBinding.instance.imageCache.maximumSize;
    
    final usagePercentage = (currentSize / maxSize * 100).toStringAsFixed(1);
    
    debugPrint('📊 Cache Durumu:');
    debugPrint('   • Boyut: ${(currentSize / 1024 / 1024).toStringAsFixed(1)}MB / ${(maxSize / 1024 / 1024).toStringAsFixed(1)}MB ($usagePercentage%)');
    debugPrint('   • Count: $currentCount / $maxCount');
    debugPrint('   • Cihaz Kategorisi: ${PerformanceUtils.deviceCategory}');
  }
} 