import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'purchase_manager.dart'; // PurchaseManager eklendi
import 'gemini_service.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal() {
    _appStartTime = DateTime.now();
    _initializePurchaseListener();
  }

  final PurchaseManager _purchaseManager = PurchaseManager(); // CreditsService yerine PurchaseManager
  final GeminiService _geminiService = GeminiService();

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitialAd = false;
  bool _isShowingAd = false;
  
  DateTime? _lastAdShowTime;
  DateTime? _appStartTime;
  bool _didEnterBackground = false;
  
  AppLifecycleState? _previousState;
  bool _purchaseServiceInitialized = false;
  bool _isInAppAction = false;
  
  static Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('🕸️ [AdMob] Web ortamı - MobileAds.initialize atlandı');
      return;
    }
    // Debug modda test cihazı ID'lerini ayarla (kendi cihaz ID'ni ekleyebilirsin)
    if (kDebugMode) {
      try {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: _debugTestDeviceIds,
          ),
        );
        debugPrint('🧪 [AdMob] Debug testDeviceIds set: ' + _debugTestDeviceIds.toString());
      } catch (e) {
        debugPrint('⚠️ [AdMob] testDeviceIds ayarlanamadı: $e');
      }
    }

    final status = await MobileAds.instance.initialize();

    // Adapter durumlarını logla (Mediation doğrulaması için yararlı)
    try {
      debugPrint('🧩 [AdMob] InitializationStatus: adapter count=${status.adapterStatuses.length}');
      status.adapterStatuses.forEach((name, adapterStatus) {
        debugPrint('  • [$name] state=${adapterStatus.state} | desc=${adapterStatus.description} | latencyMs=${adapterStatus.latency}');
      });
    } catch (e) {
      debugPrint('⚠️ [AdMob] Adapter durumları okunamadı: $e');
    }
  }

  // --- Gerekli Üyeler ---
  bool get mounted => _interstitialAd != null;
  bool get isInterstitialAdAvailable => _interstitialAd != null;

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3375249639458473/4451476746'
        : 'ca-app-pub-3375249639458473/9975572999';
  }

  static String get nativeAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110'
          : 'ca-app-pub-3940256099942544/3986624511';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3375249639458473/8521867085'
        : 'ca-app-pub-3375249639458473/8521867085';
  }
  // --- Bitiş ---

  Duration get _cooldownDuration => Duration(seconds: _geminiService.adCooldownSeconds);
  Duration get _initialDelay => Duration(seconds: _geminiService.firstAdDelaySeconds);

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3375249639458473/4972153248'
        : 'ca-app-pub-3375249639458473/1762041055';
  }

  void _initializePurchaseListener() {
    debugPrint('🔗 [AdMob] PurchaseManager listener ekleniyor...');
    _purchaseManager.addListener(_handlePurchaseStatusChange);
    _purchaseServiceInitialized = true;
    _handlePurchaseStatusChange();
  }

  void dispose() {
    _purchaseManager.removeListener(_handlePurchaseStatusChange);
    _interstitialAd?.dispose();
  }

  void _handlePurchaseStatusChange() {
    // PurchaseManager'dan en güncel durumu al
    debugPrint('🔄 [AdMob] Purchase durumu kontrol - Premium: ${_purchaseManager.isPremium}, NoAds: ${_purchaseManager.isLifetimeNoAds}');
    
    // Eğer kullanıcı premium ise veya reklamsız paket varsa
    if (_purchaseManager.isPremium || _purchaseManager.isLifetimeNoAds) {
      debugPrint('✨ [AdMob] Premium/NoAds aktif! Reklamlar tamamen kapatılıyor...');
      _interstitialAd?.dispose();
      _interstitialAd = null;
    } else {
      // Değilse ve reklam yüklenmemişse yükle
      if (_interstitialAd == null && !_isLoadingInterstitialAd) {
         debugPrint('📢 [AdMob] Free kullanıcı, reklam hazırlanıyor...');
         loadInterstitialAd();
      }
    }
  }

  void loadInterstitialAd() {
    if (kIsWeb) {
      debugPrint('🕸️ [AdMob] Web ortamı - interstitial yükleme atlandı');
      return;
    }
    
    if (_isLoadingInterstitialAd || _interstitialAd != null) {
      debugPrint('⚠️ [AdMob] Interstitial ad yükleme atlandı - Loading: $_isLoadingInterstitialAd, Available: ${_interstitialAd != null}');
      return;
    }
    
    debugPrint('🚀 [AdMob] Interstitial ad yükleme başlatılıyor...');
    debugPrint('📱 [AdMob] Ad Unit ID: $interstitialAdUnitId');
    
    _isLoadingInterstitialAd = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ [AdMob] Interstitial ad başarıyla yüklendi!');
          _interstitialAd = ad;
          _isLoadingInterstitialAd = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ [AdMob] Interstitial ad yüklenemedi: ${error.message} (Code: ${error.code})');
          _isLoadingInterstitialAd = false;
        },
      ),
    );
  }

  Future<void> _tryShowAd({required VoidCallback onAdDismissed}) async {
    if (kIsWeb) {
      debugPrint('🕸️ [AdMob] Web ortamı - reklam gösterimi atlandı');
      onAdDismissed();
      return;
    }
    
    // Debug modda reklam gösterme
    if (kDebugMode) {
      debugPrint('🧪 [AdMob] Debug modu - reklam gösterilmiyor');
      onAdDismissed();
      return;
    }
    
    // Premium kontrol ekle (PurchaseManager üzerinden)
    if (_purchaseManager.isPremium || _purchaseManager.isLifetimeNoAds) {
      debugPrint('✨ [AdMob] Premium kullanıcı, interstitial ad engellendi.');
      onAdDismissed();
      return;
    }
    
    if (_interstitialAd == null || _isShowingAd) {
      debugPrint('⚠️ [AdMob] Interstitial ad gösterilemedi - Ad null: ${_interstitialAd == null}, Showing: $_isShowingAd');
      onAdDismissed();
      return;
    }
    
    debugPrint('🎬 [AdMob] Interstitial ad gösteriliyor...');
    _isShowingAd = true;
    _lastAdShowTime = DateTime.now();

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('🔚 [AdMob] Interstitial ad kapatıldı');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ [AdMob] Interstitial ad gösterilemedi: $error');
        _isShowingAd = false;
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdDismissed();
      },
    );
    await _interstitialAd!.show();
  }
  
  void forceShowInterstitialAd() {
    debugPrint('🎬 [AdLogic] Reklam gösterimi zorlanıyor (zaman kontrolü atlandı).');
    _tryShowAd(onAdDismissed: () {});
  }

  Future<void> onSearchAdRequest({required VoidCallback onAdDismissed}) async {
    final now = DateTime.now();
    
    if (_lastAdShowTime == null) {
      // İlk reklam, uygulama açılışından belirlenen gecikmeden sonra uygun hale gelir.
      if (now.difference(_appStartTime!) > _initialDelay) {
        debugPrint('🎬 [AdLogic] İlk ${_initialDelay.inSeconds}s doldu ve arama yapıldı. Reklam denemesi yapılıyor...');
        await _tryShowAd(onAdDismissed: onAdDismissed);
      } else {
        final remaining = _initialDelay - now.difference(_appStartTime!);
        debugPrint('⏳ [AdLogic] İlk ${_initialDelay.inSeconds}s dolmadan arama reklamı gösterilmez. Kalan: ${remaining.inSeconds}s');
        onAdDismissed();
      }
      return;
    }

    if (now.difference(_lastAdShowTime!) > _cooldownDuration) {
      debugPrint('🎬 [AdLogic] Sayaç bitti ve arama yapıldı, reklam denemesi yapılıyor...');
      await _tryShowAd(onAdDismissed: onAdDismissed);
    } else {
      final timeSince = now.difference(_lastAdShowTime!);
      debugPrint('⏳ [AdLogic] Arama reklamı atlandı. Kalan süre: ${(_cooldownDuration - timeSince).inSeconds}s');
      onAdDismissed();
    }
  }

  // KELİME KARTI AÇILDIĞINDA ÇAĞRILACAK METOT
  Future<void> onWordCardOpenedAdRequest() async {
    final now = DateTime.now();
    
    // Faz 1: Başlangıç periyodu
    if (_lastAdShowTime == null) {
      // İlk reklam, uygulama açılışından belirlenen gecikmeden sonra uygun hale gelir.
      if (now.difference(_appStartTime!) > _initialDelay) {
        debugPrint('🎬 [AdLogic] İlk ${_initialDelay.inSeconds}s doldu ve bir kelime kartı açıldı, reklam denemesi yapılıyor...');
        await _tryShowAd(onAdDismissed: () {});
      } else {
        final remaining = _initialDelay - now.difference(_appStartTime!);
        debugPrint('🤫 [AdLogic] Kelime kartı reklamı atlandı: İlk ${_initialDelay.inSeconds}s henüz dolmadı. Kalan: ${remaining.inSeconds}s');
      }
      return;
    }

    // Faz 2: Normal döngü
    if (now.difference(_lastAdShowTime!) > _cooldownDuration) {
      debugPrint('🎬 [AdLogic] Sayaç bitti ve bir kelime kartı açıldı, reklam denemesi yapılıyor...');
      await _tryShowAd(onAdDismissed: () {});
    } else {
      final remaining = _cooldownDuration - now.difference(_lastAdShowTime!);
      debugPrint('⏳ [AdLogic] Kelime kartı reklamı atlandı. Kalan süre: ${remaining.inSeconds}s');
    }
  }

  void onAppStateChanged(AppLifecycleState state) {
    debugPrint('📱 [Lifecycle] App state changed to: $state.');

    if (state == AppLifecycleState.paused) {
      debugPrint('🛑 [Lifecycle] App has been paused. Ad will be eligible on next resume.');
      _didEnterBackground = true;
    }

    if (state == AppLifecycleState.resumed) {
      debugPrint('▶️ [Lifecycle] App Resumed. Checking if it was truly in background...');
      
      if (_didEnterBackground) {
        debugPrint('✅ [AdLogic] App resumed from background. Proceeding with ad checks...');
        _didEnterBackground = false;

        if (_isShowingAd) {
          debugPrint('🤫 [AdLogic] Ad skipped: Another ad is already showing.');
          _previousState = state;
          return;
        }
        
        if (_isInAppAction) {
          debugPrint('🤫 [AdLogic] Ad skipped: An in-app action is in progress.');
          _previousState = state;
          return;
        }

        final now = DateTime.now();
        if (_lastAdShowTime == null) {
           if (now.difference(_appStartTime!) > _initialDelay) {
             debugPrint('🎬 [AdLogic] İlk ${_initialDelay.inSeconds}s doldu ve uygulamaya dönüldü, reklam denemesi yapılıyor...');
             _tryShowAd(onAdDismissed: () {});
           } else {
             final remaining = _initialDelay - now.difference(_appStartTime!);
             debugPrint('🤫 [AdLogic] Ad skipped: İlk ${_initialDelay.inSeconds}s henüz dolmadı. Kalan: ${remaining.inSeconds}s');
           }
           _previousState = state;
           return;
        }

        if (now.difference(_lastAdShowTime!) > _cooldownDuration) {
          debugPrint('🎬 [AdLogic] Sayaç bitti ve uygulamaya dönüldü, reklam denemesi yapılıyor...');
          _tryShowAd(onAdDismissed: () {});
        } else {
           final remaining = _cooldownDuration - now.difference(_lastAdShowTime!);
           debugPrint('⏳ [AdLogic] Ad skipped: Cooldown not finished. Time remaining: ${remaining.inSeconds}s');
        }
      } else {
        debugPrint('🤫 [AdLogic] Ad skipped: App resumed from a minor interruption, not from background.');
      }
    }
    _previousState = state;
  }

  void setInAppActionFlag(String actionType) {
    debugPrint('🔒 [AdMob] In-app action flag SET: $actionType');
    _isInAppAction = true;
  }

  void clearInAppActionFlag() {
    debugPrint('🔓 [AdMob] In-app action flag CLEARED');
    _isInAppAction = false;
  }

  void debugAdStatus() {
    debugPrint('--- AdMob Debug Status ---');
    debugPrint('Premium: ${_purchaseManager.isPremium}');
    debugPrint('Lifetime Ads Free: ${_purchaseManager.isLifetimeNoAds}');
    debugPrint('Interstitial Ad Loaded: $isInterstitialAdAvailable');
    debugPrint('Is In-App Action: $_isInAppAction');
    debugPrint('Last Interstitial Show Time: $_lastAdShowTime');
    debugPrint('Cooldown Duration: ${_cooldownDuration.inSeconds}s');
    debugPrint('--------------------------');
  }

  // --- DEBUG YARDIMCILAR ---
  static List<String> _debugTestDeviceIds = const <String>[
    // Cihazını test cihazı yapmak için buraya kendi "Test Device ID" değerini ekle.
    // Örn: 'ABCDEF012345'
  ];

  static Future<void> setTestDeviceIds(List<String> ids) async {
    _debugTestDeviceIds = ids;
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _debugTestDeviceIds),
      );
      debugPrint('🧪 [AdMob] setTestDeviceIds applied: ' + _debugTestDeviceIds.toString());
    } catch (e) {
      debugPrint('⚠️ [AdMob] setTestDeviceIds failed: $e');
    }
  }

  static Future<String?> openAdInspector() async {
    if (kIsWeb) return 'Web ortamı';
    final completer = Completer<String?>();
    try {
      MobileAds.instance.openAdInspector((error) {
        if (error != null) {
          completer.complete('Hata: ${error.message} (code: ${error.code})');
        } else {
          completer.complete(null);
        }
      });
    } catch (e) {
      return 'Exception: $e';
    }
    return completer.future; // null ise başarı
  }
}