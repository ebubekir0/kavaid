import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'dart:io' show Platform;
import 'services/connectivity_service.dart';
import 'screens/home_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/community_chat_screen.dart';
import 'screens/admin_console_screen.dart';
import 'services/admin_service.dart';
import 'services/saved_words_service.dart';
import 'services/admob_service.dart';
import 'widgets/banner_ad_widget.dart';
import 'services/credits_service.dart';
import 'services/one_time_purchase_service.dart';
import 'services/book_purchase_service.dart';
import 'services/global_config_service.dart';
import 'utils/performance_utils.dart';
import 'utils/image_cache_manager.dart';
import 'utils/safe_purchase_wrapper.dart';
import 'utils/database_cleanup_utility.dart';
import 'widgets/fps_counter_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/firebase_service.dart';
import 'services/firebase_options.dart';
import 'services/turkce_analytics_service.dart';
import 'models/word_model.dart';
import 'services/app_usage_service.dart';
import 'services/gemini_service.dart';
import 'services/tts_service.dart';
import 'services/review_service.dart';
import 'services/sync_service.dart';
import 'screens/database_loading_screen.dart';
import 'services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'utils/migrate_usernames.dart';

// Fontları arka planda yükle (UI'ı engellemez)
void _preloadFonts() {
  Future.microtask(() async {
  try {
    // ScheherazadeNew (Tüm kalınlıkları yükle)
    final arabicLoader = FontLoader('ScheherazadeNew')
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Bold.ttf'));

    await arabicLoader.load().timeout(const Duration(seconds: 3));

    debugPrint('✅ Tüm fontlar yüklendi (FontLoader): ScheherazadeNew (Tüm Kalınlıklar)');
  } catch (e) {
    debugPrint('⚠️ Font preload başarısız (devam ediliyor): $e');
  }
  });
}

// Custom ScrollBehavior - overscroll glow efektini kaldırmak için
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Glow efektini gösterme
  }
}

// Uygulama açılışında sözlük veritabanı hazır olana kadar yükleme ekranı gösteren sarmalayıcı
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _dbReady = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _decideFlow();
  }

  Future<void> _decideFlow() async {
    try {
      final db = await DatabaseService.instance.database;
      if (db == null) {
        // Web platformu veya database yok
        setState(() {
          _dbReady = false;
          _checking = false;
        });
        return;
      }
      
      final tableInfo = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='words'");
      bool tableExists = tableInfo.isNotEmpty;
      int wordCount = 0;
      if (tableExists) {
        final countResult = await db.rawQuery('SELECT COUNT(*) FROM words');
        wordCount = Sqflite.firstIntValue(countResult) ?? 0;
      }
      setState(() {
        _dbReady = tableExists && wordCount > 0;
        _checking = false;
      });
    } catch (e) {
      // Hata durumunda güvenli tarafta kal: yükleme ekranını göster
      setState(() {
        _dbReady = false;
        _checking = false;
      });
    }
  }

  void _onDbReady() {
    if (!mounted) return;
    setState(() {
      _dbReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      // Kısa bir geçiş için boş/sade bir arka plan göster
      return Container(color: const Color(0xFFF5F7FB));
    }
    if (!_dbReady) {
      return DatabaseLoadingScreen(
        onLoadingComplete: _onDbReady,
      );
    }
    return MainScreen(
      isDarkMode: false,
      onThemeToggle: null,
    );
  }
}

// 🚀 PERFORMANCE MOD: Kritik servisleri arka planda hızlı başlat (Firebase zaten başlatıldı)
void _initializeCriticalServicesBackground() {
  Future.microtask(() async {
  try {
    // CreditsService'i hemen başlat (AdMob için gerekli)
    final creditsService = CreditsService();
    await creditsService.initialize().timeout(
      const Duration(seconds: 3),
    ).catchError((e) {
      debugPrint('⚠️ CreditsService timeout/error - varsayılan değerlerle devam: $e');
    });
    debugPrint('✅ CreditsService kritik aşamada başlatıldı: Premium: ${creditsService.isPremium}');
    
    // Kullanıcı adı migration'ı arka planda çalıştır
    // _runUsernameMigration();

    // Kritik servisleri paralel başlat - hiçbiri ana thread'i bloke etmesin
    final criticalFutures = [
      // GlobalConfig hızlı başlat
      GlobalConfigService().init().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⚠️ GlobalConfigService timeout - varsayılan değerlerle devam');
          return null;
        },
      ).catchError((e) {
        debugPrint('❌ GlobalConfigService başlatılamadı: $e');
      }),
      
      // KRİTİK: Restore Purchase mekanizması - uygulama açılışında otomatik çalışacak
      Future.microtask(() async {
        try {
          debugPrint('🔄 [RESTORE] Satın alma durumları restore ediliyor...');
          
          // OneTimePurchaseService restore
          final oneTimeService = OneTimePurchaseService();
          await oneTimeService.initialize().timeout(const Duration(seconds: 3));
          await oneTimeService.restorePurchases().timeout(const Duration(seconds: 5));
          debugPrint('✅ [RESTORE] OneTimePurchase restore tamamlandı');
          
          // BookPurchaseService restore  
          final bookService = BookPurchaseService();
          await bookService.initialize().timeout(const Duration(seconds: 3));
          debugPrint('✅ [RESTORE] BookPurchase restore tamamlandı');
          
        } catch (e) {
          debugPrint('⚠️ [RESTORE] Purchase restore hatası (devam ediyor): $e');
        }
      }),
      
      // TTS motorunu arka planda ısıt
      Future.microtask(() async {
        try {
          await TTSService().warmUp().timeout(const Duration(seconds: 3));
          debugPrint('✅ TTS warm-up tamamlandı');
        } catch (e) {
          debugPrint('⚠️ TTS warm-up timeout/hata: $e');
        }
      }),
    ];
    
    // Tüm kritik servisleri paralel bekle ama timeout ile
    await Future.wait(criticalFutures).timeout(
      const Duration(seconds: 5),
    ).catchError((e) {
      debugPrint('⚠️ Kritik servisler timeout/error - uygulama devam ediyor: $e');
      return <void>[]; // Return empty list for onError handler
    });
    debugPrint('✅ Kritik servisler hızlı başlatıldı');

  } catch (e) {
    debugPrint('❌ Kritik servis hatası (uygulama devam ediyor): $e');
    // Hata durumunda da uygulama çalışmaya devam etsin
  }
  });
}

// 🚀 PERFORMANCE MOD: Cihaz performans modlarını ayarla (runApp'i engellemez)
void _setupPerformanceModes() {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    // Android yüksek FPS desteği
    if (!kIsWeb && Platform.isAndroid) {
      _enableAndroidHighPerformanceMode();
    }
    
    // iOS ProMotion bilgisi
    if (!kIsWeb && Platform.isIOS) {
      debugPrint('🍎 iOS ProMotion aktif - Sistem otomatik adaptasyonu');
    }
    
    // Memory ve GC optimizasyonları
    if (!kIsWeb) {
      ImageCacheManager.initialize();
      PerformanceUtils.detectDevicePerformance();
    }
  });
}

// Android yüksek performans modunu etkinleştirme mantığı
Future<void> _enableAndroidHighPerformanceMode() async {
  try {
    final modes = await FlutterDisplayMode.supported;
    if (modes.isEmpty) {
      debugPrint('⚠️ Cihazda desteklenen ekran modu bulunamadı.');
      await FlutterDisplayMode.setHighRefreshRate();
      return;
    }

    DisplayMode? bestMode;
    double maxRefreshRate = 0.0;

    // En yüksek refresh rate'e sahip modu bul
    for (final mode in modes) {
      if (mode.refreshRate > maxRefreshRate) {
        maxRefreshRate = mode.refreshRate;
        bestMode = mode;
      }
    }
    
    if (bestMode != null) {
      await FlutterDisplayMode.setPreferredMode(bestMode);
      debugPrint('🚀 En yüksek yenileme hızı ayarlandı: ${bestMode.refreshRate}Hz');
    } else {
      // Fallback
      await FlutterDisplayMode.setHighRefreshRate();
      debugPrint('🚀 Fallback: Yüksek yenileme hızı (setHighRefreshRate) ayarlandı.');
    }
  } catch (e) {
    debugPrint('❌ Display mode ayarlanamadı: $e');
    try {
      await FlutterDisplayMode.setHighRefreshRate();
      debugPrint('🔄 Fallback: setHighRefreshRate denendi.');
    } catch (fallbackError) {
      debugPrint('❌ Fallback da başarısız: $fallbackError');
    }
  }
}


Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 🚀 ÖNCELİK 1: Uygulama motorunu ve temel UI ayarlarını hazırla
    // Bu işlemler hızlı ve senkron olmalı
    if (!kIsWeb) {
      // Frame scheduler'ı ve shader'ları erken optimize et
      SchedulerBinding.instance.scheduleWarmUpFrame();
      
      if (Platform.isAndroid) {
        // Gralloc4 ve Surface debug mesajlarını engelle
        SystemChannels.platform.setMethodCallHandler(null);
        FlutterError.onError = (details) {
          final message = details.toString();
          if (message.contains('gralloc4') || message.contains('Surface') || message.contains('FrameEvents') ||
              message.contains('SMPTE 2094-40') || message.contains('lockHardwareCanvas') || message.contains('updateAcquireFence')) {
            return; // Gürültülü logları yut
          }
          // Crashlytics'e bildir, ardından varsayılan sunumu yap
          try {
            FirebaseCrashlytics.instance.recordFlutterError(details);
          } catch (_) {}
          FlutterError.presentError(details);
        };
      }

      // Status bar'ı başlangıçta şeffaf yap
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }

    // 🚀 ÖNCELİK 2: Firebase'i önce başlat (diğer servisler için gerekli)
    // Not: iOS simülatör/CI ortamında native init atlanırsa [core/no-app] olur.
    // Bunu önlemek için, eğer henüz bir Firebase app yoksa Dart tarafında
    // DefaultFirebaseOptions ile initialize ediyoruz.
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 5));
        debugPrint('✅ Firebase (Dart) initialize edildi: DefaultFirebaseOptions');
      } else {
        // Native tarafta başarıyla initialize edilmiş.
        debugPrint('✅ Firebase zaten initialize: native/AppDelegate');
      }
      debugPrint('✅ Firebase kritik başlatma tamamlandı');
    } catch (e) {
      debugPrint('❌ Firebase başlatma hatası: $e');
    }

    // 🔒 Crashlytics toplamasını aç ve global hata yakalayıcıları kur (Firebase init sonrasında)
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      // Flutter framework hataları
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        try {
          FirebaseCrashlytics.instance.recordFlutterError(details);
        } catch (_) {}
        previousOnError?.call(details);
      };
      // Framework dışı (async) hatalar
      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (_) {}
        return true; // Hata ele alındı
      };
    } catch (e) {
      debugPrint('⚠️ Crashlytics başlatma/handler kurulum hatası: $e');
    }

    // 🚀 ÖNCELİK 3: Uygulamayı hemen çalıştır! (UI gösterilir)
    runApp(const KavaidApp());

    // 🚀 ÖNCELİK 4: Diğer servisleri arka planda başlat
    _preloadFonts();
    _initializeCriticalServicesBackground();
    _initializeServicesInBackground();
    _setupPerformanceModes();
    
    // 🧹 Veritabanı durumu kontrol et (DEBUG)
    if (kDebugMode) {
      Future.delayed(const Duration(seconds: 3), () async {
        print('\n🔍 Veritabanı durumu kontrol ediliyor...');
        await DatabaseCleanupUtility.printDatabaseStatus();
      });
    }
  }, (error, stack) {
    // En yakalanmayan hataları Crashlytics'e gönder
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {}
  });
}


// Servisleri arka planda hızlı ve ANR-free başlat
void _initializeServicesInBackground() {
  // Fontlar artık main() fonksiyonunda önceden yüklendiği için burada tekrar yüklemeye gerek yok

  // Analitik servisini hızlı başlat
  Future.microtask(() {
    TurkceAnalyticsService.uygulamaBaslatildi().timeout(
      const Duration(seconds: 2),
      onTimeout: () => debugPrint('⚠️ Analytics timeout'),
    ).catchError((e) {
      debugPrint('❌ Analytics Service hatası: $e');
    });
  });

  // Diğer servisleri tamamen arka planda başlat
  Future.microtask(_initializeChainOfServices);
}

// Servis zincirini hızlı ve ANR-free başlat
Future<void> _initializeChainOfServices() async {
  try {
    // CreditsService zaten kritik servislerde başlatıldı, sadece referansını al
    final creditsService = CreditsService();
    debugPrint('✅ CreditsService referansı alındı: ${creditsService.credits} hak, Premium: ${creditsService.isPremium}');

    // AdMob'u arka planda başlat - ana thread'i bloke etme
    if (!creditsService.isPremium && !creditsService.isLifetimeAdsFree) {
      Future.microtask(() async {
        try {
          await AdMobService.initialize().timeout(const Duration(seconds: 5)); // 15'ten 5'e düşürüldü
          debugPrint('✅ AdMob arka planda başlatıldı');

          RequestConfiguration configuration = RequestConfiguration(
            testDeviceIds: ['bbffd4ef-bbec-48dd-9123-fac2b36aa283'],
          );
          MobileAds.instance.updateRequestConfiguration(configuration);

          // Reklam yüklemesini daha da arka planda yap
          Future.delayed(const Duration(seconds: 2), () {
            AdMobService().loadInterstitialAd();
            debugPrint('🚀 Interstitial reklam arka planda yüklendi');
          });
        } catch (e) {
          debugPrint('❌ AdMob arka plan hatası: $e');
        }
      });
    } else {
      debugPrint('✨ Premium kullanıcı, AdMob atlandı');
    }
  } catch (e) {
    debugPrint('❌ Servis zinciri hatası (devam ediyor): $e');
  }

  // Diğer tüm servisleri tamamen paralel ve hızlı başlat
  final otherServices = [
    SavedWordsService().initialize().timeout(
      const Duration(seconds: 2),
    ).then((_) => debugPrint('✅ SavedWordsService hızlı başlatıldı')).catchError((e) {
      debugPrint('⚠️ SavedWordsService timeout/error: $e');
    }),
    
    SafePurchaseWrapper.initializeService().timeout(
      const Duration(seconds: 2),
    ).then((_) => debugPrint('✅ OneTimePurchaseService hızlı başlatıldı')).catchError((e) {
      debugPrint('⚠️ OneTimePurchaseService timeout/error: $e');
    }),
    
    BookPurchaseService().initialize().timeout(
      const Duration(seconds: 2),
    ).then((_) => debugPrint('✅ BookPurchaseService hızlı başlatıldı')).catchError((e) {
      debugPrint('⚠️ BookPurchaseService timeout/error: $e');
    }),
    
    AppUsageService().startSession().timeout(
      const Duration(seconds: 1),
    ).then((_) => debugPrint('✅ AppUsageService hızlı başlatıldı')).catchError((e) {
      debugPrint('⚠️ AppUsageService timeout/error: $e');
    }),
    
    // TTS zaten warmUp() içinde başlatılıyor, tekrar başlatmaya gerek yok
    
    // GeminiService'i arka planda başlat (konfigürasyonu da yükler)
    Future.microtask(() async {
      try {
        await GeminiService().initialize().timeout(const Duration(seconds: 5));
        debugPrint('✅ GeminiService initialize edildi (config yüklendi)');
      } catch (e) {
        debugPrint('❌ GeminiService initialize hatası: $e');
      }
    }),
    
    ReviewService().initialize().timeout(
      const Duration(seconds: 1),
    ).then((_) => debugPrint('✅ ReviewService hızlı başlatıldı')).catchError((e) {
      debugPrint('⚠️ ReviewService timeout/error: $e');
    }),
  ];

  // Tüm servisleri paralel başlat - hataları yakala ama durma
  Future.wait(otherServices.map((future) => future.catchError((e) {
    debugPrint('❌ Arka plan servisi hatası (devam ediyor): $e');
    return null;
  }))).timeout(
    const Duration(seconds: 5), // Tüm servisler için maksimum bekleme
    onTimeout: () {
      debugPrint('⚠️ Bazı servisler timeout - uygulama çalışıyor');
      return <void>[];
    },
  );
}

class KavaidApp extends StatefulWidget {
  const KavaidApp({super.key});

  @override
  State<KavaidApp> createState() => _KavaidAppState();
}

class _KavaidAppState extends State<KavaidApp> with WidgetsBindingObserver {
  static const String _themeKey = 'is_dark_mode';
  bool _isDarkMode = false;
  bool _isAppInForeground = true;
  bool _themeLoaded = false;
  final CreditsService _creditsService = CreditsService();
  final AppUsageService _appUsageService = AppUsageService();
  Timer? _usageTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemePreference();
    
    // Credits service'i başlat ve dinle
    _initializeCreditsService();
    
    // İlk açılışta app open ad gösterme - sadece resume'da göster
    
    // Kullanım süresini periyodik olarak güncelle
    _startUsageTimer();
  }
  
  void _startUsageTimer() {
    // Her dakika kullanım süresini güncelle
    _usageTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isAppInForeground) {
        _appUsageService.updateUsage();
        debugPrint('⏱️ [AppUsage] Kullanım süresi güncellendi');
      }
    });
  }
  
  Future<void> _initializeCreditsService() async {
    await _creditsService.initialize();
    // Premium durumu değiştiğinde rebuild için dinle
    _creditsService.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _creditsService.removeListener(() {});
    _usageTimer?.cancel();
    _appUsageService.endSession();
    
    super.dispose();
  }

  // Tema tercihi yükle
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool(_themeKey) ?? false;
        _themeLoaded = true;
      });
    } catch (e) {
      debugPrint('❌ Tema yükleme hatası: $e');
      // Hata durumunda varsayılan değerle devam et
      setState(() {
        _isDarkMode = false;
        _themeLoaded = true;
      });
    }
  }

  // Tema tercihi kaydet
  Future<void> _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    debugPrint('🔄 [MAIN] App lifecycle state değişti: $state');
    
    // AdMobService'e lifecycle state'i gönder
    try {
      AdMobService().onAppStateChanged(state);
      debugPrint('✅ [MAIN] AdMobService.onAppStateChanged() başarıyla çağırıldı');
    } catch (e) {
      debugPrint('❌ [MAIN] AdMobService.onAppStateChanged() hatası: $e');
    }
    
    // 🚀 PERFORMANCE MOD: Lifecycle'a göre cache optimizasyonu
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        ImageCacheManager.restoreForForeground();
        
        // Uygulama aktif olduğunda kullanım süresini güncelle
        _appUsageService.updateUsage();
        
        // TEST: 2 saniye sonra debug durumunu göster
        Future.delayed(const Duration(seconds: 2), () {
          debugPrint('🧪 [TEST] 2 saniye sonra debug durumu:');
          AdMobService().debugAdStatus();
        });
        break;
      case AppLifecycleState.paused:
        _isAppInForeground = false;
        ImageCacheManager.optimizeForBackground();
        
        // Uygulama arka plana alındığında oturumu sonlandır
        _appUsageService.endSession();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        break;
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveThemePreference(_isDarkMode);
    
    // Analytics event'i gönder
    TurkceAnalyticsService.temaDegistirildi(_isDarkMode ? 'koyu' : 'acik');
  }

  @override
  Widget build(BuildContext context) {
      // Tema yüklenene kadar hızlı loading göster
    if (!_themeLoaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(
          color: const Color(0xFFF5F7FB),
          child: const SizedBox.shrink(),
        ),
      );
    }

    return MaterialApp(
      title: 'Kavaid - Arapça Sözlük',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.light,
      home: const StartupScreen(),
      builder: (context, child) {
        // 🚀 PERFORMANCE MOD: Yüksek FPS için optimize edilmiş MediaQuery
        final mediaQuery = MediaQuery.of(context);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // Her dokunuşta klavyeyi kapat (sistem + Arapça)
            FocusManager.instance.primaryFocus?.unfocus();
            SystemChannels.textInput.invokeMethod('TextInput.hide');
          },
          onPanDown: (_) {
            // Scroll gerekmeksizin ilk temasla kapat
            FocusManager.instance.primaryFocus?.unfocus();
            SystemChannels.textInput.invokeMethod('TextInput.hide');
          },
          child: MediaQuery(
            data: mediaQuery.copyWith(
              // Performans için optimize edilmiş değerler
              devicePixelRatio: mediaQuery.devicePixelRatio,
              // Text scaling'i stabil tut
              textScaleFactor: mediaQuery.textScaleFactor.clamp(0.8, 1.2),
            ),
            child: ScrollConfiguration(
              // Overscroll glow efektini kaldır - performans artışı sağlar
              behavior: NoGlowScrollBehavior(),
              child: RepaintBoundary(
                // 🚀 PERFORMANCE MOD: Ana uygulama RepaintBoundary ile sarılı
                child: FPSOverlay(
                  showFPS: false, // Debug mesajlarını önlemek için tamamen kapalı
                  detailedFPS: false,
                  child: SafeArea(
                    // 🔧 ANDROID 15 FIX: Global SafeArea - Navigation bar overlap fix
                    bottom: true,
                    child: child!,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      fontFamily: 'Inter', // Varsayılan font ailesi
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007AFF),
        brightness: Brightness.light,
        surface: const Color(0xFFF5F7FB), // Daha mavimsi arka plan
        onSurface: const Color(0xFF2C2C2E),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB), // Daha mavimsi arka plan
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFFF5F7FB), // Daha mavimsi arka plan
        foregroundColor: Color(0xFF2C2C2E),
        titleTextStyle: TextStyle(
          color: Color(0xFF2C2C2E),
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFFFFFFFF), // Tam beyaz kartlar daha belirgin olması için
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: Color(0xFFD1D1D6),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: Color(0xFFD1D1D6),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: Color(0xFF007AFF),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFFFFFFF).withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: Color(0xFF8E8E93),
          fontSize: 16,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: const Color(0xFF8E8E93),
        backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.95),
        selectedLabelStyle: const TextStyle(fontFamily: 'Inter'), // Font ailesini uygula
        unselectedLabelStyle: const TextStyle(fontFamily: 'Inter'), // Font ailesini uygula
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      fontFamily: 'Inter', // Varsayılan font ailesi
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007AFF),
        brightness: Brightness.dark,
        surface: const Color(0xFF2C2C2E),
        onSurface: const Color(0xFFE5E5EA),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF1C1C1E),
        foregroundColor: Color(0xFFE5E5EA),
        titleTextStyle: TextStyle(
          color: Color(0xFFE5E5EA),
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: Color(0xFF3A3A3C),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: Color(0xFF3A3A3C),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: Color(0xFF007AFF),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: Color(0xFF8E8E93),
          fontSize: 16,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF007AFF),
        unselectedItemColor: Color(0xFF8E8E93),
        backgroundColor: Color(0xFF1C1C1E), // Karanlık tema için siyah navigation bar
        selectedLabelStyle: TextStyle(fontFamily: 'Inter'), // Font ailesini uygula
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter'), // Font ailesini uygula
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onThemeToggle;

  const MainScreen({
    super.key,
    required this.isDarkMode,
    this.onThemeToggle,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _showArabicKeyboard = false;
  bool _isFirstOpen = true;
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isNoInternetDialogOpen = false;
  double _bannerHeight = 0; // Dinamik banner yüksekliği için state
  // Öğren sekmesi için iç içe Navigator anahtarı (bottom bar'ı korumak için)
  final GlobalKey<NavigatorState> _learningTabNavKey = GlobalKey<NavigatorState>();
  // Banner reklam widget anahtarı (çarpı ikonu için)
  final GlobalKey<BannerAdWidgetState> _bannerKey = GlobalKey<BannerAdWidgetState>();
  // Admin servis
  final AdminService _adminService = AdminService();
  // Topluluk görünürlüğü kontrolü
  bool _communityEnabled = true;

  @override
  void initState() {
    super.initState();
    
    // Topluluk tercihini yükle
    _loadCommunityPreference();
    
    // İnternet kontrolünü arka planda yap (başlangıcı yavaşlatmasın)
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkInitialConnectivity();
      
      // Bağlantı değişikliklerini dinle
      _connectivityService.startListening((hasConnection) {
        debugPrint('📶 Bağlantı durumu değişti: $hasConnection');
        if (!mounted) return;
        if (!hasConnection) {
          debugPrint('❌ Bağlantı kesildi! (Engelleyici dialog)');
          // Dialog'u sadece yerel DB hazır DEĞİLSE göster
          () async {
            if (!mounted) return;
            final shouldBlock = await _shouldBlockForNoInternet();
            if (!shouldBlock) return; // DB hazır, dialog gösterme
            if (_isNoInternetDialogOpen) return;
            _isNoInternetDialogOpen = true;
            await ConnectivityService.showNoInternetDialog(
              context,
              onRetry: () async {
                final ok = await _connectivityService.hasInternetConnection();
                if (ok && mounted) {
                  Navigator.of(context, rootNavigator: true).maybePop();
                }
              },
            );
            if (mounted) _isNoInternetDialogOpen = false;
          }();
        } else {
          debugPrint('✅ Bağlantı geri geldi!');
          // Bağlantı geldiğinde varsa açık dialog'u kapat
          if (_isNoInternetDialogOpen) {
            Navigator.of(context, rootNavigator: true).maybePop();
            _isNoInternetDialogOpen = false;
          }
          // Açık SnackBar varsa kapat (bir önceki tasarımdan kalmış olabilir)
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      });
    });
  }
  
  // Yerel veritabanı hazır mı? Hazırsa internetsiz kullanım mümkün => engelleyici dialog gerekmez
  Future<bool> _shouldBlockForNoInternet() async {
    try {
      final db = await DatabaseService.instance.database;
      if (db == null) return true; // Web platformu - internet gerekli
      
      final tableInfo = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='words'");
      final tableExists = tableInfo.isNotEmpty;
      int wordCount = 0;
      if (tableExists) {
        final countResult = await db.rawQuery('SELECT COUNT(*) FROM words');
        wordCount = Sqflite.firstIntValue(countResult) ?? 0;
      }
      // true => dialog göster; false => gösterme
      return !(tableExists && wordCount > 0);
    } catch (_) {
      // Hata durumunda tedbiren engelleyici davranışta kal
      return true;
    }
  }
  
  Future<void> _checkInitialConnectivity() async {
    debugPrint('🔍 İlk bağlantı kontrolü başlatılıyor...');
    final hasConnection = await _connectivityService.hasInternetConnection();
    debugPrint('📱 İlk kontrol sonucu - İnternet var mı: $hasConnection');
    
    if (!mounted) return;
    if (!hasConnection) {
      debugPrint('❌ İnternet bağlantısı yok! (Başlangıçta engelleyici dialog)');
      final shouldBlock = await _shouldBlockForNoInternet();
      if (!shouldBlock) return; // DB hazır, dialog gösterme
      if (_isNoInternetDialogOpen) return;
      _isNoInternetDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await ConnectivityService.showNoInternetDialog(
          context,
          onRetry: () async {
            final ok = await _connectivityService.hasInternetConnection();
            if (ok && mounted) {
              Navigator.of(context, rootNavigator: true).maybePop();
            }
          },
        );
        if (mounted) _isNoInternetDialogOpen = false;
      });
    } else {
      debugPrint('✅ İnternet bağlantısı mevcut');
    }
  }

  @override
  void dispose() {
    _connectivityService.stopListening();
    super.dispose();
  }
  
  // Topluluk tercihini yükle
  Future<void> _loadCommunityPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _communityEnabled = prefs.getBool('community_enabled') ?? true;
        });
      }
    } catch (e) {
      debugPrint('❌ Topluluk tercihi yüklenirken hata: $e');
    }
  }
  
  // Topluluk toggle değişikliğini işle - Sadece gerektiğinde index değiştir
  void _onCommunityToggleChanged(bool enabled) {
    if (mounted) {
      setState(() {
        _communityEnabled = enabled;
        
        // Sadece zorunlu durum: Topluluk sekmesindeyken kapatlırsa profil'e git
        if (!enabled && _currentIndex == 2) {
          _currentIndex = 3; // Profil sekmesi (IndexedStack'te)
        }
        // Diğer durumlarda _currentIndex'i değiştirme!
        // Kullanıcı hangi sekmede ise orada kalsın
      });
    }
  }
  
  // Navigation bar index'ini IndexedStack index'ine çevir
  int _mapNavigationToStackIndex(int navIndex) {
    if (_communityEnabled) {
      // Topluluk açık: direk mapping
      return navIndex;
    } else {
      // Topluluk kapalı: index 2+ için +1 ekle (Topluluk index 2 olduğu için)
      if (navIndex >= 2) {
        return navIndex + 1; // Profil 2->3, Console 3->4
      }
      return navIndex;
    }
  }
  
  // IndexedStack index'ini Navigation bar index'ine çevir
  int _mapStackToNavigationIndex(int stackIndex) {
    if (_communityEnabled) {
      // Topluluk açık: direk mapping
      return stackIndex;
    } else {
      // Topluluk kapalı: index 3+ için -1 çıkar
      if (stackIndex >= 3) {
        return stackIndex - 1; // Profil 3->2, Console 4->3
      }
      return stackIndex;
    }
  }

  void _onTabTapped(int index) {
    // Navigation bar index'ini IndexedStack index'ine çevir
    final realIndex = _mapNavigationToStackIndex(index);
    
    // Aynı sekmeye tıklanırsa: özel davranış
    if (realIndex == _currentIndex) {
      // Öğren sekmesi zaten açıkken tekrar tıklanırsa köke dön
      if (realIndex == 1) {
        final nav = _learningTabNavKey.currentState;
        nav?.popUntil((route) => route.isFirst);
      }
      return; // Seçili sekmeye tekrar tıklamada state değiştirme
    }

    // Farklı bir sekmeye geçiliyorsa yalnızca index'i değiştir
    setState(() => _currentIndex = realIndex);

    // Sekme değişiminde (navigasyon bar geçişi) interstitial reklam tetikle
    // Premium / reklamsız kullanıcılar ve cooldown kontrolleri AdMobService içinde yapılır
    try {
      AdMobService().onWordCardOpenedAdRequest();
    } catch (_) {}

    // İlk açılış durumunu sıfırla (sekme değişiminde)
    if (_isFirstOpen && index != 0) {
      _isFirstOpen = false;
    }
  }

  void _setArabicKeyboardState(bool show) {
    setState(() {
      _showArabicKeyboard = show;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final hasSystemKeyboard = keyboardHeight > 0;
    const navBarHeight = 56.0;
    // ANDROID 15 FIX: System navigation bar yüksekliğini hesapla
    final systemNavBarHeight = MediaQuery.of(context).viewPadding.bottom;
    

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // STATUS BAR: Tema uyumlu renk ayarları
        statusBarColor: widget.isDarkMode 
            ? const Color(0xFF1C1C1E)  // Dark tema için siyah
            : const Color(0xFF007AFF), // Light tema için ana mavi
        statusBarIconBrightness: widget.isDarkMode 
            ? Brightness.light       // Dark tema için beyaz iconlar
            : Brightness.light,      // Light tema için beyaz iconlar (mavi arka planda)
        statusBarBrightness: widget.isDarkMode 
            ? Brightness.dark        // iOS için - dark tema
            : Brightness.dark,       // iOS için - light tema
        // System navigation bar ayarları
        systemNavigationBarColor: widget.isDarkMode 
            ? const Color(0xFF1C1C1E)  // Dark tema için siyah
            : Colors.white,            // Light tema için beyaz
        systemNavigationBarIconBrightness: widget.isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: WillPopScope(
        onWillPop: () async {
          // Klavye açıksa önce klavyeyi kapat, hiçbir sayfayı pop etme
          if (hasSystemKeyboard) {
            FocusScope.of(context).unfocus();
            return false;
          }
          // Öğren sekmesindeki iç Navigator geri gidebiliyorsa önce onu pop et
          if (_currentIndex == 1) {
            if (_learningTabNavKey.currentState?.canPop() == true) {
              _learningTabNavKey.currentState!.pop();
              return false; // Uygulamadan çıkma
            }
            // Öğren sekmesinin ana sayfasındayken geri tuşu uygulamayı kapatmasın, Ana sekmeye dön
            setState(() => _currentIndex = 0);
            return false;
          }
          // Diğer sekmelerde: eğer kök navigator bir sayfa/diğer route gösterebiliyorsa önce onu kapat
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return false;
          }
          // Diğer sekmelerdeyken geri tuşu uygulamayı kapatmak yerine Ana sekmeye dönsün
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
            return false;
          }
          return true; // Ana sekmede varsayılan davranış
        },
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Ana İçerik - IndexedStack ile sekmelerin state'ini koru
          Positioned.fill(
            child: RepaintBoundary(
              child: Builder(
                builder: (context) {
                  const navBarHeight = 56.0;
                  final systemNavBarHeight = MediaQuery.of(context).viewPadding.bottom;
                  final totalBottomPadding = _bannerHeight + navBarHeight + systemNavBarHeight;

                  return IndexedStack(
                    index: _currentIndex,
                    children: [
                      // 0: Sözlük (Home) - her zaman ağaçta, state korunur
                      HomeScreen(
                        key: const ValueKey('home_screen'),
                        isActive: _currentIndex == 0,
                        bottomPadding: totalBottomPadding,
                        isDarkMode: widget.isDarkMode,
                        onThemeToggle: widget.onThemeToggle,
                        onArabicKeyboardStateChanged: _setArabicKeyboardState,
                        isFirstOpen: _isFirstOpen,
                        onKeyboardOpened: () {
                          if (_isFirstOpen) setState(() => _isFirstOpen = false);
                        },
                      ),

                      // 1: Öğren (iç Navigator) - state korunur
                      Padding(
                        key: const ValueKey('learning_screen'),
                        padding: EdgeInsets.only(bottom: totalBottomPadding),
                        child: Navigator(
                          key: _learningTabNavKey,
                          onGenerateRoute: (settings) {
                            return MaterialPageRoute(
                              builder: (_) => LearningScreen(
                                bottomPadding: 0,
                                isDarkMode: widget.isDarkMode,
                                onThemeToggle: widget.onThemeToggle,
                              ),
                              settings: settings,
                            );
                          },
                        ),
                      ),

                      // 2: Topluluk - sadece aktifken oluştur
                      _currentIndex == 2
                          ? (_communityEnabled
                              ? CommunityChatScreen(
                                  key: const ValueKey('community_screen'),
                                  topPadding: _bannerHeight,
                                  bottomPadding: navBarHeight + systemNavBarHeight,
                                )
                              : _buildErrorScreen('Topluluk sekmesi devre dışı'))
                          : const SizedBox.shrink(),

                      // 3: Profil - sadece aktifken oluştur
                      _currentIndex == 3
                          ? ProfileScreen(
                              key: const ValueKey('profile_screen'),
                              bottomPadding: totalBottomPadding,
                              isDarkMode: widget.isDarkMode,
                              onThemeToggle: widget.onThemeToggle,
                              onCommunityToggle: _onCommunityToggleChanged,
                            )
                          : const SizedBox.shrink(),

                      // 4: Admin Console - sadece aktifken oluştur
                      _currentIndex == 4
                          ? (_adminService.isAdmin()
                              ? AdminConsoleScreen(
                                  key: const ValueKey('admin_screen'),
                                  topPadding: _bannerHeight,
                                  bottomPadding: navBarHeight + systemNavBarHeight,
                                )
                              : _buildErrorScreen('Admin yetkisi gerekli'))
                          : const SizedBox.shrink(),
                    ],
                  );
                },
              ),
            ),
          ),

          // 2. Banner Reklam - RepaintBoundary ile performans optimizasyonu
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            // Topluluk ekranında veya Admin Console'da banner üstte, diğerlerinde altta
            top: (_communityEnabled && _currentIndex == 2) || (_adminService.isAdmin() && _currentIndex == 4)
                ? MediaQuery.of(context).viewPadding.top 
                : null,
            bottom: ((_communityEnabled && _currentIndex == 2) || (_adminService.isAdmin() && _currentIndex == 4)) 
                ? null 
                : (hasSystemKeyboard
                    ? keyboardHeight  // Klavye açıkken direkt klavyenin üstünde - nav bar hesaplama
                    : (_showArabicKeyboard && _currentIndex == 0)  // Sadece Home Screen'de klavye
                        ? 280.0 + navBarHeight + MediaQuery.of(context).viewPadding.bottom  // Klavye + nav bar üstünde
                        : navBarHeight + MediaQuery.of(context).viewPadding.bottom),
            left: 0,
            right: 0,
            height: _bannerHeight,
            child: RepaintBoundary(
              child: BannerAdWidget(
                key: _bannerKey,
                onAdHeightChanged: (height) {
                  if (mounted && _bannerHeight != height) {
                    setState(() => _bannerHeight = height);
                  }
                },
                stableKey: 'main_banner_stable',
              ),
            ),
          ),

          // 2b. Banner Çarpı İkonu - Banner'ın üstünde ayrı olarak
          if (_bannerHeight > 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              // Topluluk veya Admin Console ekranında üstte, diğerlerinde altta
              top: ((_communityEnabled && _currentIndex == 2) || (_adminService.isAdmin() && _currentIndex == 4))
                  ? MediaQuery.of(context).viewPadding.top + _bannerHeight - 10
                  : null,
              bottom: ((_communityEnabled && _currentIndex == 2) || (_adminService.isAdmin() && _currentIndex == 4))
                  ? null 
                  : (hasSystemKeyboard
                      ? keyboardHeight + _bannerHeight - 10  // Klavye açıkken banner'ın 10px üstünde
                      : (_showArabicKeyboard && _currentIndex == 0)  // Sadece Home Screen'de klavye
                          ? 280.0 + navBarHeight + MediaQuery.of(context).viewPadding.bottom + _bannerHeight - 10
                          : navBarHeight + MediaQuery.of(context).viewPadding.bottom + _bannerHeight - 10),
              right: -8, // Daha sağa
              child: GestureDetector(
                onTap: () {
                  // BannerAdWidget'ın showRemoveAdsDialog metodunu çağır
                  _bannerKey.currentState?.showRemoveAdsDialog();
                },
                behavior: HitTestBehavior.translucent,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

          // 3. Bottom Navigation Bar - Sabit Pozisyon (Hareket Etmez)
          Positioned(
            bottom: 0, // Her zaman sabit pozisyonda
            left: 0,
            right: 0,
            height: navBarHeight + MediaQuery.of(context).viewPadding.bottom,
            child: RepaintBoundary(
              child: Container(
                // ANDROID 15 FIX: System navigation bar padding eklendi
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: _mapStackToNavigationIndex(_currentIndex),
                  onTap: _onTabTapped,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent, // Arka planı parent container'dan alır
                  selectedItemColor: const Color(0xFF007AFF),
                  unselectedItemColor: widget.isDarkMode
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF8E8E93),
                  selectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  elevation: 0,
                  iconSize: 24,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.menu_book_outlined),
                      activeIcon: const Icon(Icons.menu_book),
                      label: 'Sözlük',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.school_outlined),
                      activeIcon: const Icon(Icons.school),
                      label: 'Öğren',
                    ),
                    // Topluluk sekmesi - tercihe göre göster
                    if (_communityEnabled)
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.forum_outlined),
                        activeIcon: Icon(Icons.forum),
                        label: 'Topluluk',
                      ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outline),
                      activeIcon: const Icon(Icons.person),
                      label: 'Profil',
                    ),
                    // Admin Console (sadece kurucu için)
                    if (_adminService.isFounder())
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.admin_panel_settings_outlined),
                        activeIcon: Icon(Icons.admin_panel_settings),
                        label: 'Console',
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildErrorScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: widget.isDarkMode ? Colors.red[300] : Colors.red[600],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Kullanıcı adı migration'ı - arka planda çalışır
void _runUsernameMigration() {
  Future.microtask(() async {
    try {
      debugPrint('🔄 [MIGRATION] Kullanıcı adı migration kontrolü başlatılıyor...');
      
      // SharedPreferences'ta migration'ın daha önce çalışıp çalışmadığını kontrol et
      final prefs = await SharedPreferences.getInstance();
      final migrationCompleted = prefs.getBool('username_migration_completed_v2') ?? false;
      
      if (!migrationCompleted) {
        debugPrint('📋 [MIGRATION] Migration gerekli, başlatılıyor...');
        
        // Migration'ı çalıştır
        await MigrateUsernames.migrateAllUsers();
        
        // Migration'ın tamamlandığını işaretle
        await prefs.setBool('username_migration_completed_v2', true);
        debugPrint('✅ [MIGRATION] Migration başarıyla tamamlandı ve işaretlendi');
      } else {
        debugPrint('ℹ️ [MIGRATION] Migration zaten tamamlanmış, atlanıyor');
      }
    } catch (e) {
      debugPrint('❌ [MIGRATION] Migration hatası: $e');
    }
  });
}


