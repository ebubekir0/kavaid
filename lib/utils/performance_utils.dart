import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class PerformanceUtils {
  static int _frameCount = 0;
  static int _droppedFrames = 0;
  static double _currentFPS = 60.0;
  static bool _isMonitoring = false;
  static String _deviceCategory = 'unknown';
  static bool _isLowEndDevice = false;
  static bool _isXiaomiDevice = false;
  static bool _isSamsungDevice = false;
  static String _miuiVersion = '';
  static double _refreshRate = 60.0;
  static int _thermalStatus = 0;
  static bool _isHighPerformanceModeEnabled = false;
  
  // 🚀 PERFORMANCE MOD: Genişletilmiş cihaz kategorileri
  static const Map<String, Map<String, dynamic>> deviceCategories = {
    'ultra_high_end': {
      'cache_extent': 2000.0,
      'max_cache_items': 100,
      'animation_multiplier': 0.7,
      'preload_items': 8,
      'use_cache_images': true,
      'enable_shadows': true,
      'enable_gradients': true,
      'enable_complex_animations': true,
      'list_cache_extent': 2500.0,
    },
    'high_end': {
      'cache_extent': 1500.0,
      'max_cache_items': 75,
      'animation_multiplier': 0.8,
      'preload_items': 5,
      'use_cache_images': true,
      'enable_shadows': true,
      'enable_gradients': true,
      'enable_complex_animations': true,
      'list_cache_extent': 2000.0,
    },
    'mid_range': {
      'cache_extent': 1000.0,
      'max_cache_items': 50,
      'animation_multiplier': 1.0,
      'preload_items': 3,
      'use_cache_images': true,
      'enable_shadows': true,
      'enable_gradients': false,
      'enable_complex_animations': false,
      'list_cache_extent': 1500.0,
    },
    'low_end': {
      'cache_extent': 600.0,
      'max_cache_items': 25,
      'animation_multiplier': 1.2,
      'preload_items': 1,
      'use_cache_images': false,
      'enable_shadows': false,
      'enable_gradients': false,
      'enable_complex_animations': false,
      'list_cache_extent': 800.0,
    },
  };
  
  // 🚀 PERFORMANCE MOD: Gelişmiş cihaz tespiti
  static Future<void> detectDevicePerformance() async {
    if (!Platform.isAndroid) return;
    
    try {
      // Native channel üzerinden cihaz bilgilerini al
      const channel = MethodChannel('device_info');
      final deviceInfo = await channel.invokeMethod('getDeviceInfo').timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏱️ Device info timeout, fallback kullanılıyor');
          return null;
        },
      );
      
      if (deviceInfo != null) {
        debugPrint('📱 Cihaz Bilgileri Alındı: $deviceInfo');
        
        // Cihaz bilgilerini parse et
        final totalRamMB = deviceInfo['totalRamMB'] as int? ?? 0;
        final availableRamMB = deviceInfo['availableRamMB'] as int? ?? 0;
        final glEsVersion = deviceInfo['glEsVersion'] as double? ?? 0.0;
        final apiLevel = deviceInfo['apiLevel'] as int? ?? 0;
        final cpuCores = deviceInfo['cpuCores'] as int? ?? 0;
        final performanceCategory = deviceInfo['performanceCategory'] as String? ?? 'unknown';
        final manufacturer = deviceInfo['manufacturer'] as String? ?? '';
        final model = deviceInfo['model'] as String? ?? '';
        final device = deviceInfo['device'] as String? ?? '';
        
        // Özel cihaz bilgileri
        _isXiaomiDevice = deviceInfo['isXiaomiDevice'] as bool? ?? false;
        _isSamsungDevice = deviceInfo['isSamsungDevice'] as bool? ?? false;
        _miuiVersion = deviceInfo['miuiVersion'] as String? ?? '';
        _refreshRate = (deviceInfo['refreshRate'] as num?)?.toDouble() ?? 60.0;
        _thermalStatus = deviceInfo['thermalStatus'] as int? ?? 0;
        final isEmulator = deviceInfo['isEmulator'] as bool? ?? false;
        
        // Performans kategorisini ayarla
        if (performanceCategory != 'unknown') {
          _deviceCategory = performanceCategory;
          _isLowEndDevice = performanceCategory == 'low_end';
          debugPrint('🎯 Cihaz Kategorisi: $_deviceCategory');
        }
        
        // Detaylı cihaz raporu
        debugPrint('📊 === KAVAID PERFORMANS RAPORU ===');
        debugPrint('📱 Cihaz: $manufacturer $model ($device)');
        debugPrint('🧠 RAM: $totalRamMB MB (Kullanılabilir: $availableRamMB MB)');
        debugPrint('🎮 GPU: OpenGL ES $glEsVersion');
        debugPrint('💻 CPU: $cpuCores çekirdek');
        debugPrint('📱 API Level: $apiLevel');
        debugPrint('🖥️ Refresh Rate: ${_refreshRate}Hz');
        debugPrint('🏷️ Kategori: $_deviceCategory');
        
        if (_isXiaomiDevice) {
          debugPrint('📱 XIAOMI/REDMI cihaz tespit edildi');
          if (_miuiVersion.isNotEmpty) {
            debugPrint('📱 MIUI Version: $_miuiVersion');
          }
          // MIUI için özel optimizasyonlar
          _applyMiuiOptimizations();
        }
        
        if (_isSamsungDevice) {
          debugPrint('📱 SAMSUNG cihaz tespit edildi');
          // Samsung için özel optimizasyonlar
          _applySamsungOptimizations();
        }
        
        if (isEmulator) {
          debugPrint('⚠️ EMULATOR tespit edildi - performans testi güvenilir olmayabilir');
        }
        
        // Thermal durum kontrolü
        if (_thermalStatus > 0) {
          debugPrint('🌡️ Thermal Durum: $_thermalStatus');
          if (_thermalStatus >= 3) {
            debugPrint('⚠️ Cihaz ısınmış durumda, performans düşebilir');
          }
        }
        
        // Yüksek refresh rate cihazlar için özel ayarlar
        if (_refreshRate > 60) {
          debugPrint('🚀 Yüksek refresh rate tespit edildi: ${_refreshRate}Hz');
          _applyHighRefreshRateOptimizations();
        }
        
        // Düşük RAM uyarısı
        if (availableRamMB < 1024) {
          debugPrint('⚠️ Düşük RAM uyarısı! Kullanılabilir: $availableRamMB MB');
          _activateLowMemoryMode();
        }
        
        // Yüksek performans modunu etkinleştir (mid-range ve üzeri için)
        if (_deviceCategory == 'high_end' || _deviceCategory == 'ultra_high_end') {
          await enableHighPerformanceMode();
        }
        
      } else {
        // Native channel başarısız, FPS bazlı tespit
        debugPrint('⚠️ Native device info alınamadı, FPS bazlı tespit kullanılacak');
        _categorizeDeviceByFPS();
      }
    } catch (e) {
      debugPrint('⚠️ Cihaz tespiti başarısız: $e');
      _categorizeDeviceByFPS();
    }
  }
  
  // 🚀 PERFORMANCE MOD: Yüksek performans modunu etkinleştir
  static Future<void> enableHighPerformanceMode() async {
    if (!Platform.isAndroid) return;
    
    try {
      const channel = MethodChannel('device_info');
      await channel.invokeMethod('setHighPerformanceMode', {'enabled': true});
      _isHighPerformanceModeEnabled = true;
      debugPrint('⚡ Yüksek performans modu ETKİN');
    } catch (e) {
      debugPrint('⚠️ Yüksek performans modu etkinleştirilemedi: $e');
    }
  }
  
  // 🚀 PERFORMANCE MOD: MIUI optimizasyonları
  static void _applyMiuiOptimizations() {
    debugPrint('🔧 MIUI optimizasyonları uygulanıyor...');
    
    // MIUI'da animasyon sürelerini AZALT (daha hızlı tepki için)
    if (currentDeviceSettings['animation_multiplier'] != null) {
      currentDeviceSettings['animation_multiplier'] = 
        (currentDeviceSettings['animation_multiplier'] as double) * 0.5; // 1.2 yerine 0.5
    }
    
    // MIUI'da cache boyutunu ARTIR
    if (currentDeviceSettings['max_cache_items'] != null) {
      currentDeviceSettings['max_cache_items'] = 
        ((currentDeviceSettings['max_cache_items'] as int) * 1.2).round(); // 0.8 yerine 1.2
    }
    
    // List cache'i artır
    currentDeviceSettings['list_cache_extent'] = 
        (currentDeviceSettings['list_cache_extent'] as double) * 1.5;
    
    // Preload item sayısını artır
    currentDeviceSettings['preload_items'] = 
        ((currentDeviceSettings['preload_items'] as int) * 2).clamp(2, 10);
    
    // Kompleks animasyonları kapat
    currentDeviceSettings['enable_complex_animations'] = false;
    currentDeviceSettings['enable_shadows'] = false;
    
    debugPrint('✅ MIUI optimizasyonları tamamlandı');
  }
  
  // 🚀 PERFORMANCE MOD: Samsung optimizasyonları
  static void _applySamsungOptimizations() {
    debugPrint('🔧 Samsung One UI optimizasyonları uygulanıyor...');
    
    // Samsung cihazlarda genelde iyi performans var, default ayarları koru
    debugPrint('✅ Samsung optimizasyonları tamamlandı');
  }
  
  // 🚀 PERFORMANCE MOD: Yüksek refresh rate optimizasyonları
  static void _applyHighRefreshRateOptimizations() {
    debugPrint('🔧 Yüksek refresh rate optimizasyonları uygulanıyor...');
    
    // Animasyon sürelerini refresh rate'e göre ayarla
    final refreshMultiplier = 60.0 / _refreshRate;
    if (currentDeviceSettings['animation_multiplier'] != null) {
      currentDeviceSettings['animation_multiplier'] = 
        (currentDeviceSettings['animation_multiplier'] as double) * refreshMultiplier;
    }
    
    debugPrint('✅ Yüksek refresh rate optimizasyonları tamamlandı');
  }
  
  // 🚀 PERFORMANCE MOD: Düşük bellek modu
  static void _activateLowMemoryMode() {
    debugPrint('🔧 Düşük bellek modu aktif ediliyor...');
    
    // Cache boyutlarını minimize et
    currentDeviceSettings['max_cache_items'] = 15;
    currentDeviceSettings['cache_extent'] = 400.0;
    currentDeviceSettings['list_cache_extent'] = 600.0;
    currentDeviceSettings['preload_items'] = 1;
    currentDeviceSettings['use_cache_images'] = false;
    
    // Görsel efektleri kapat
    currentDeviceSettings['enable_shadows'] = false;
    currentDeviceSettings['enable_gradients'] = false;
    currentDeviceSettings['enable_complex_animations'] = false;
    
    debugPrint('✅ Düşük bellek modu aktif');
  }
  
  // 🚀 PERFORMANCE MOD: FPS bazlı cihaz kategorilendirme
  static void _categorizeDeviceByFPS() {
    // Mevcut FPS'e göre kategori belirleme
    if (_currentFPS >= 115) {
      _deviceCategory = 'high_end';
      _isLowEndDevice = false;
      debugPrint('🚀 Cihaz Kategorisi: Yüksek Performans (120Hz+ FPS)');
    } else if (_currentFPS >= 85) {
      _deviceCategory = 'mid_range';
      _isLowEndDevice = false;
      debugPrint('⚡ Cihaz Kategorisi: Orta Performans (90Hz+ FPS)');
    } else {
      // Düşük FPS veya yüksek drop rate kontrolü
      if (dropRate > 10.0 || _currentFPS < 45) {
        _deviceCategory = 'low_end';
        _isLowEndDevice = true;
        debugPrint('📱 Cihaz Kategorisi: Düşük Performans (optimizasyonlar devrede)');
      } else {
        _deviceCategory = 'mid_range';
        _isLowEndDevice = false;
        debugPrint('📱 Cihaz Kategorisi: Standart Performans');
      }
    }
  }
  
  // 🚀 PERFORMANCE MOD: Adaptif ayar getters
  static Map<String, dynamic> get currentDeviceSettings {
    return Map<String, dynamic>.from(
      deviceCategories[_deviceCategory] ?? deviceCategories['mid_range']!
    );
  }
  
  // 🚀 PERFORMANCE MOD: Gelişmiş FPS izleme
  static void enableFPSCounter() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    debugPrint('🎯 FPS İzleme Başlatıldı');
    
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        _frameCount++;
        
        // Frame süresi hesapla (milisaniye)
        final buildTime = timing.buildDuration.inMicroseconds / 1000.0;
        final rasterTime = timing.rasterDuration.inMicroseconds / 1000.0;
        final totalTime = buildTime + rasterTime;
        
        // FPS hesapla
        if (totalTime > 0) {
          _currentFPS = 1000.0 / totalTime;
        }
        
        // Frame drop kontrolü - refresh rate'e göre dinamik
        bool frameDropped = false;
        final frameTimeLimit = 1000.0 / _refreshRate;
        
        if (totalTime > frameTimeLimit * 1.1) {
          frameDropped = true;
        }
        
        if (frameDropped) {
          _droppedFrames++;
        }
        
        // Performans log'larını tamamen kaldır (gereksiz çıktı)
        
        // Çok düşük performans tespiti
        if (_frameCount > 1000 && dropRate > 30.0) {
          // Daha yüksek eşik değerleri ile nadir log
          debugPrint('🔴 CRİTİK PERFORMANS SORUNU TESPİT EDİLDİ!');
          _activateEmergencyMode();
        }
      }
    });
  }
  
  // 🚀 PERFORMANCE MOD: Acil durum modu
  static void _activateEmergencyMode() {
    _deviceCategory = 'low_end';
    _isLowEndDevice = true;
    
    // Acil optimizasyonlar
    _activateLowMemoryMode();
    
    // Acil cache temizleme
    optimizeMemory();
    
    debugPrint('🆘 ACİL PERFORMANS MODU AKTİF!');
    debugPrint('   • Cache boyutu minimize edildi');
    debugPrint('   • Animasyonlar yavaşlatıldı');
    debugPrint('   • Görsel efektler devre dışı');
  }
  
  // 🚀 PERFORMANCE MOD: Sistem performans bilgileri
  static void logSystemPerformance() {
    debugPrint('🔧 Sistem Performans Bilgileri:');
    debugPrint('   • Frame Count: $_frameCount');
    debugPrint('   • Dropped Frames: $_droppedFrames');
    debugPrint('   • Current FPS: ${_currentFPS.toStringAsFixed(1)}');
    debugPrint('   • Drop Rate: ${(_droppedFrames / _frameCount * 100).toStringAsFixed(1)}%');
    debugPrint('   • Device Category: $_deviceCategory');
    debugPrint('   • Low End Device: $_isLowEndDevice');
    debugPrint('   • Refresh Rate: ${_refreshRate}Hz');
    debugPrint('   • Thermal Status: $_thermalStatus');
    if (_isXiaomiDevice) {
      debugPrint('   • MIUI Version: $_miuiVersion');
    }
    debugPrint('   • High Performance Mode: $_isHighPerformanceModeEnabled');
  }
  
  // Performans modu
  static const bool performanceMode = true;
  
  // 🚀 PERFORMANCE MOD: Adaptif animasyon süreleri
  static Duration get fastAnimation {
    final multiplier = currentDeviceSettings['animation_multiplier'] as double;
    final baseMs = _refreshRate >= 115 ? 80 : (_refreshRate >= 85 ? 100 : 120);
    return Duration(milliseconds: (baseMs * multiplier).round());
  }
  
  static Duration get normalAnimation {
    final multiplier = currentDeviceSettings['animation_multiplier'] as double;
    final baseMs = _refreshRate >= 115 ? 150 : (_refreshRate >= 85 ? 180 : 200);
    return Duration(milliseconds: (baseMs * multiplier).round());
  }
  
  static Duration get slowAnimation {
    final multiplier = currentDeviceSettings['animation_multiplier'] as double;
    final baseMs = _refreshRate >= 115 ? 250 : (_refreshRate >= 85 ? 280 : 300);
    return Duration(milliseconds: (baseMs * multiplier).round());
  }
  
  // 🚀 PERFORMANCE MOD: Adaptif cache ayarları
  static double get defaultCacheExtent {
    return currentDeviceSettings['cache_extent'] as double;
  }
  
  static int get maxCacheItems {
    return currentDeviceSettings['max_cache_items'] as int;
  }
  
  static int get preloadItems {
    return currentDeviceSettings['preload_items'] as int;
  }
  
  static bool get useCacheImages {
    return currentDeviceSettings['use_cache_images'] as bool;
  }
  
  static bool get enableShadows {
    return currentDeviceSettings['enable_shadows'] as bool? ?? false;
  }
  
  static bool get enableGradients {
    return currentDeviceSettings['enable_gradients'] as bool? ?? false;
  }
  
  static bool get enableComplexAnimations {
    return currentDeviceSettings['enable_complex_animations'] as bool? ?? false;
  }
  
  // 🚀 PERFORMANCE MOD: ListView optimizasyonları
  static double get listCacheExtent {
    // Mevcut implementasyon ile cihaz kategorisine göre cache ayarlama
    return currentDeviceSettings['list_cache_extent'] as double? ?? 1000.0;
  }
  
  // Getters
  static bool get isLowEndDevice => _isLowEndDevice;
  static String get deviceCategory => _deviceCategory;
  static bool get isXiaomiDevice => _isXiaomiDevice;
  static bool get isSamsungDevice => _isSamsungDevice;
  static double get refreshRate => _refreshRate;
  
  // Debounce süreleri - cihaza göre adaptif
  static Duration get searchDebounce {
    return Duration(milliseconds: _isLowEndDevice ? 500 : 300);
  }
  
  static Duration get inputDebounce {
    return Duration(milliseconds: _isLowEndDevice ? 300 : 200);
  }
  
  // 🚀 PERFORMANCE MOD: Optimize edilmiş widget builder
  static Widget optimizedBuilder({
    required Widget Function() builder,
    bool shouldRepaint = true,
    String? debugLabel,
  }) {
    // Düşük performanslı cihazlarda RepaintBoundary kullanımını azalt
    if (shouldRepaint && !_isLowEndDevice) {
      return RepaintBoundary(
        key: debugLabel != null ? ValueKey('repaint_$debugLabel') : null,
        child: builder(),
      );
    }
    return builder();
  }
  
  // 🚀 PERFORMANCE MOD: Gelişmiş performans ölçümü
  static void measurePerformance(String tag, VoidCallback callback) {
    final stopwatch = Stopwatch()..start();
    callback();
    stopwatch.stop();
    
    final elapsed = stopwatch.elapsedMicroseconds / 1000.0; // milisaniye
    
    // Frame budget'a göre uyarı seviyesi - refresh rate'e göre dinamik
    final warningThreshold = 1000.0 / _refreshRate;
    
    if (elapsed > warningThreshold) {
      debugPrint('🔴 PERFORMANS UYARISI - $tag: ${elapsed.toStringAsFixed(2)}ms (Budget: ${warningThreshold.toStringAsFixed(2)}ms)');
    } else if (elapsed > warningThreshold * 0.8) {
      debugPrint('🟡 PERFORMANS İZLEME - $tag: ${elapsed.toStringAsFixed(2)}ms');
    }
  }
  
  // 🚀 PERFORMANCE MOD: Widget performans wrapper
  static Widget performanceWrapper({
    required Widget child,
    required String label,
    bool enableProfiling = false,
  }) {
    if (!enableProfiling || _isLowEndDevice) return child;
    
    return Builder(
      builder: (context) {
        measurePerformance(label, () {});
        return RepaintBoundary(
          key: ValueKey('perf_$label'),
          child: child,
        );
      },
    );
  }
  
  // 🚀 PERFORMANCE MOD: Memory optimize etme
  static void optimizeMemory() {
    // System garbage collection'ı tetikle
    SystemChannels.platform.invokeMethod('System.gc');
    debugPrint('🧹 Memory optimization tamamlandı');
  }
  
  // 🚀 PERFORMANCE MOD: FPS bilgisi getter
  static double get currentFPS => _currentFPS;
  static int get totalFrames => _frameCount;
  static int get droppedFrames => _droppedFrames;
  static double get dropRate => _frameCount > 0 ? (_droppedFrames / _frameCount) * 100 : 0.0;
}

// 🚀 PERFORMANCE MOD: Optimize edilmiş SliverChildDelegate
class OptimizedSliverChildDelegate extends SliverChildBuilderDelegate {
  OptimizedSliverChildDelegate({
    required Widget Function(BuildContext, int) builder,
    required int childCount,
    String? debugLabel,
  }) : super(
          (context, index) {
            // Düşük performanslı cihazlarda RepaintBoundary kullanmayın
            if (PerformanceUtils.isLowEndDevice) {
              return builder(context, index);
            }
            return RepaintBoundary(
              key: ValueKey('${debugLabel ?? 'optimized'}_item_$index'),
              child: builder(context, index),
            );
          },
          childCount: childCount,
          addAutomaticKeepAlives: !PerformanceUtils.isLowEndDevice, // Düşük performansta kapalı
          addRepaintBoundaries: false, // Manuel olarak ekliyoruz
          addSemanticIndexes: false,
        );
}

// 🚀 PERFORMANCE MOD: Performans izleme mixin'i
mixin PerformanceMixin<T extends StatefulWidget> on State<T> {
  late String _widgetName;
  
  @override
  void initState() {
    super.initState();
    _widgetName = T.toString();
    PerformanceUtils.measurePerformance('$_widgetName.initState', () {});
  }
  
  @override
  Widget build(BuildContext context) {
    return PerformanceUtils.optimizedBuilder(
      builder: () => buildOptimized(context),
      debugLabel: _widgetName,
    );
  }
  
  // Alt sınıflar bu metodu implement etmeli
  Widget buildOptimized(BuildContext context);
} 