# Native Ads Performans Optimizasyonları

Bu dokümantasyon, Kavaid uygulamasında yerel reklamların neden olduğu FPS düşüşü ve performans sorunlarının nasıl çözüldüğünü açıklar.

## 🚨 Tespit Edilen Sorunlar

1. **Yerel reklamlar arama sonuçları arasında çok sık gösteriliyordu** (Her 10 sonuçta 1)
2. **Ad widget'ları sürekli rebuild ediliyordu**
3. **Memory leak'ler ve yetersiz garbage collection**
4. **Lazy loading eksikliği**
5. **Optimize edilmemiş RepaintBoundary kullanımı**
6. **Background'da reklamların dispose edilmemesi**

## ⚡ Uygulanan Çözümler

### 1. Reklam Frekansı Optimizasyonu

**Öncesi:**
- Minimum 5 sonuçtan sonra reklam
- Her 10 sonuçta 1 reklam

**Sonrası:**
- Minimum 8 sonuçtan sonra reklam
- Her 15 sonuçta 1 reklam
- Her 20 sonuçta maksimum 1 reklam sınırı

```dart
// Eski versiyon
final int minCardsBeforeAd = 5;
final int adFrequency = 10;

// Yeni versiyon
final int minCardsBeforeAd = 8;
final int adFrequency = 15;
final int maxAdsPerPage = (_searchResults.length / 20).ceil();
```

### 2. Lazy Loading Implementasyonu

Native ad widget'larına viewport-based lazy loading eklendi:

```dart
void _checkVisibilityAndLoad() {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox) {
    final isVisible = position.dy < screen.height && 
                     position.dy + size.height > 0;
    
    if (isVisible && !_isVisible && !_nativeAdIsLoaded) {
      _loadNativeAd();
    }
  }
}
```

### 3. Memory Management Optimizasyonları

**App Lifecycle Monitoring:**
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _pauseAd(); // Arka planda reklamı dispose et
  } else if (state == AppLifecycleState.resumed) {
    _resumeAd(); // Geri döndüğünde yeniden yükle
  }
}
```

**Component Memory Management:**
```dart
static final Map<String, DateTime> _componentLastUsed = {};
static const Duration _componentTtl = Duration(minutes: 5);

static bool shouldDisposeComponent(String componentId) {
  final lastUsed = _componentLastUsed[componentId];
  return DateTime.now().difference(lastUsed) > _componentTtl;
}
```

### 4. Build Throttling

Widget rebuild'lerin sıklığını sınırlamak için throttling eklendi:

```dart
static const Duration _buildThrottle = Duration(milliseconds: 100);

bool _shouldThrottleBuild() {
  final now = DateTime.now();
  if (_lastBuildTime != null && 
      now.difference(_lastBuildTime!) < _buildThrottle) {
    return true;
  }
  return false;
}
```

### 5. Ad Widget Caching

AdWidget'ları önceden oluşturulup cache'lendi:

```dart
Widget? _cachedAdWidget;

void _preBuildAdWidget() {
  if (_nativeAd != null && _nativeAdIsLoaded) {
    _cachedAdWidget = AdWidget(ad: _nativeAd!);
  }
}

// Build sırasında
final adWidget = _cachedAdWidget ?? AdWidget(ad: _nativeAd!);
```

### 6. Performance Monitoring

Gerçek zamanlı performans takibi eklendi:

```dart
// FPS Monitoring
static void _onFrameTime(List<FrameTiming> timings) {
  for (final timing in timings) {
    final frameTime = timing.totalSpan.inMilliseconds;
    if (frameTime > 16) { // Above 60fps threshold
      debugPrint('🐌 Janky frame detected: ${frameTime}ms');
    }
  }
}

// Ad Load Time Tracking
static void trackAdLoad(String adId, Duration loadTime, bool success) {
  if (loadTime.inMilliseconds > 3000) {
    debugPrint('🐌 Slow ad load: $adId took ${loadTime.inMilliseconds}ms');
  }
}
```

### 7. RepaintBoundary Optimizasyonu

Sabit key'ler ve optimize edilmiş RepaintBoundary kullanımı:

```dart
return RepaintBoundary(
  key: ValueKey('native_ad_${widget.adUnitId}_${_nativeAdIsLoaded}'),
  child: _buildAdContent(isDarkMode),
);
```

## 📊 Performans İyileştirmeleri

### Beklenen Sonuçlar:

1. **FPS Stabilizasyonu:** 60 FPS'de daha kararlı performans
2. **Memory Kullanımı:** %30-40 azalma
3. **Ad Load Time:** Daha hızlı reklam yükleme
4. **Battery Life:** Daha az pil tüketimi
5. **UI Responsiveness:** Daha akıcı kullanıcı deneyimi

### Cihaz Spesifik Optimizasyonlar:

- **Düşük performanslı cihazlar:** Daha az reklam sıklığı
- **Orta seviye cihazlar:** Balanced approach
- **Yüksek performanslı cihazlar:** Normal sıklık

## 🔧 Debugging ve Monitoring

### Performance Counter Aktivasyonu:

```bash
# Debug build ile FPS counter'ı görmek için
flutter run --dart-define=SHOW_PERFORMANCE=true
```

### Log Monitoring:

```dart
// Performance summary
final summary = PerformanceUtils.getPerformanceSummary();
debugPrint('📊 Performance: $summary');
```

## 🚀 Gelecek Optimizasyonlar

1. **Adaptive Ad Loading:** Cihaz performansına göre dinamik reklam sıklığı
2. **Predictive Loading:** Kullanıcı davranışlarına göre önceden reklam yükleme
3. **Advanced Caching:** Reklam içeriklerinin daha akıllı cache'lenmesi
4. **Machine Learning:** Optimal reklam yerleşimi için ML algoritmaları

## 📝 Test Senaryoları

### Performans Testi:
1. 100+ arama sonucu ile scroll test
2. Arka plan/ön plan geçişleri
3. Düşük memory durumunda davranış
4. Network bağlantısı kayıplarında davranış

### Başarı Kriterleri:
- [ ] FPS 55'in altına düşmemeli
- [ ] Memory usage 200MB'ı geçmemeli
- [ ] Ad load time 3 saniyeyi geçmemeli
- [ ] UI lag'i 100ms'yi geçmemeli

## 🛠️ Uygulama Talimatları

Bu optimizasyonlar şu dosyalarda uygulandı:

1. `lib/widgets/native_ad_widget.dart` - Ana optimizasyonlar
2. `lib/widgets/banner_ad_widget.dart` - Banner ad optimizasyonları
3. `lib/screens/home_screen.dart` - Reklam yerleşimi optimizasyonları
4. `lib/utils/performance_utils.dart` - Performans monitoring utilities
5. `lib/main.dart` - Performance monitoring initialization

Tüm değişiklikler backward compatible'dır ve mevcut fonksiyonaliteyi bozmaz. 