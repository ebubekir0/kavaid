import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'dart:io' show Platform;
import 'services/connectivity_service.dart';
import 'screens/home_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_console_screen.dart';
import 'services/admin_service.dart';
import 'services/admob_service.dart';
import 'widgets/banner_ad_widget.dart';
import 'services/credits_service.dart';
import 'utils/performance_utils.dart';
import 'utils/image_cache_manager.dart';
import 'utils/database_cleanup_utility.dart';
import 'widgets/fps_counter_widget.dart';
// import 'services/firebase_service.dart'; // PERFORMANCE: kullanılmıyor, kaldırıldı
import 'services/firebase_options.dart';
import 'services/turkce_analytics_service.dart';
// import 'models/word_model.dart'; // PERFORMANCE: kullanılmıyor, kaldırıldı
import 'services/app_usage_service.dart';
import 'services/language_service.dart';
import 'services/app_startup_service.dart';
// import 'services/sync_service.dart'; // PERFORMANCE: kullanılmıyor, kaldırıldı
import 'services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'utils/migrate_usernames.dart';
import 'models/custom_word_list.dart';
import 'screens/custom_words_screen.dart';
import 'screens/translation_screen.dart';

import 'package:provider/provider.dart';
import 'services/purchase_manager.dart';

// Fontları arka planda yükle (UI'ı engellemez)
Future<void> _preloadFonts() async {
  try {
    // ScheherazadeNew (Tüm kalınlıkları yükle)
    final arabicLoader = FontLoader('ScheherazadeNew')
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Bold.ttf'));

    await arabicLoader.load().timeout(const Duration(seconds: 1));

    debugPrint(
      '✅ Tüm fontlar yüklendi (FontLoader): ScheherazadeNew (Tüm Kalınlıklar)',
    );
  } catch (e) {
    debugPrint('⚠️ Font preload başarısız (devam ediliyor): $e');
  }
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
  final bool isDarkMode;
  final VoidCallback? onThemeToggle;

  const StartupScreen({
    super.key,
    required this.isDarkMode,
    this.onThemeToggle,
  });

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  final AppStartupService _startup = AppStartupService.instance;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _startup.start(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _startup,
      builder: (context, _) {
        if (_startup.isReady) {
          return MainScreen(
            key: MainScreen.globalKey,
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          );
        }

        final hasError = _startup.phase == StartupPhase.recoverableError;
        final progress = _startup.progress.clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.library_books,
                        size: 80,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kavaid Sözlük',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2E),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _startup.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8E8E93),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!hasError) ...[
                    SizedBox(
                      width: 220,
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE5E5EA),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF007AFF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFFF3B30),
                      size: 36,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _startup.retry(context: context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
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
      debugPrint(
        '🚀 En yüksek yenileme hızı ayarlandı: ${bestMode.refreshRate}Hz',
      );
    } else {
      // Fallback
      await FlutterDisplayMode.setHighRefreshRate();
      debugPrint(
        '🚀 Fallback: Yüksek yenileme hızı (setHighRefreshRate) ayarlandı.',
      );
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

Future<void> _enableFullscreenSystemUi() async {
  if (kIsWeb) return;
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 🚀 ÖNCELİK 1: Fontları arka planda yükle — runApp'i bloke etme (ANR önleme)
      // await KALDIRILDI: ilk frame gecikmesin, font flash kabul edilebilir
      _preloadFonts().catchError((e) => debugPrint('⚠️ Font preload: $e'));

      // 🎨 Tema tercihini de önceden yükle - splash ekranı olmadan başlatmak için
      bool initialDarkMode = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        initialDarkMode = prefs.getBool('is_dark_mode') ?? false;
      } catch (_) {}

      // LanguageService ve diger agir servisler AppStartupService tarafindan
      // kontrollu sirayla hazirlanir.

      // 🚀 ÖNCELİK 1b: Uygulama motorunu ve temel UI ayarlarını hazırla
      if (!kIsWeb) {
        // Frame scheduler'ı ve shader'ları erken optimize et
        SchedulerBinding.instance.scheduleWarmUpFrame();

        if (Platform.isAndroid) {
          // 🔧 ANR DÜZELTMESİ: SystemChannels.platform.setMethodCallHandler(null) KALDIRILDI!
          // Bu satır platform kanalı mesaj işleyicisini silerek input dispatch'i bozuyordu
          // → %78 ANR'ının doğrudan nedeni buydu.
          // Gürültülü loglar için sadece FlutterError.onError filtreleme yeterli.
          FlutterError.onError = (details) {
            final message = details.toString();
            if (message.contains('gralloc4') ||
                message.contains('Surface') ||
                message.contains('FrameEvents') ||
                message.contains('SMPTE 2094-40') ||
                message.contains('lockHardwareCanvas') ||
                message.contains('updateAcquireFence')) {
              return; // Gürültülü logları yut
            }
            // Crashlytics'e bildir, ardından varsayılan sunumu yap (web'de desteklenmiyor)
            if (!kIsWeb) {
              try {
                FirebaseCrashlytics.instance.recordFlutterError(details);
              } catch (_) {}
            }
            FlutterError.presentError(details);
          };
        }

        await _enableFullscreenSystemUi();
      }

      // 🚀 ÖNCELİK 2: Firebase'i önce başlat (diğer servisler için gerekli)
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(const Duration(seconds: 5));
          debugPrint(
            '✅ Firebase (Dart) initialize edildi: DefaultFirebaseOptions',
          );
        } else {
          debugPrint('✅ Firebase zaten initialize: native/AppDelegate');
        }
        debugPrint('✅ Firebase kritik başlatma tamamlandı');
      } catch (e) {
        debugPrint('❌ Firebase başlatma hatası: $e');
      }

      // 🔒 Crashlytics toplamasını aç ve global hata yakalayıcıları kur (web'de desteklenmiyor)
      if (!kIsWeb) {
        try {
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
            true,
          );
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
              FirebaseCrashlytics.instance.recordError(
                error,
                stack,
                fatal: true,
              );
            } catch (_) {}
            return true; // Hata ele alındı
          };
        } catch (e) {
          debugPrint('⚠️ Crashlytics başlatma/handler kurulum hatası: $e');
        }
      }

      // 🚀 ÖNCELİK 3: Uygulamayı çalıştır! (Fontlar ve tema hazır, UI anında görünür)
      runApp(KavaidApp(initialDarkMode: initialDarkMode));

      // 🚀 ÖNCELİK 4: Diğer servisleri arka planda başlat
      _setupPerformanceModes();

      // 🧹 Veritabanı durumu kontrol et (DEBUG)
      if (kDebugMode) {
        Future.delayed(const Duration(seconds: 3), () async {
          print('\n🔍 Veritabanı durumu kontrol ediliyor...');
          await DatabaseCleanupUtility.printDatabaseStatus();
        });
      }
    },
    (error, stack) {
      // En yakalanmayan hataları Crashlytics'e gönder (web'de desteklenmiyor)
      if (!kIsWeb) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (_) {}
      }
    },
  );
}

class KavaidApp extends StatefulWidget {
  final bool initialDarkMode;
  const KavaidApp({super.key, this.initialDarkMode = false});

  @override
  State<KavaidApp> createState() => _KavaidAppState();
}

class _KavaidAppState extends State<KavaidApp> with WidgetsBindingObserver {
  static const String _themeKey = 'is_dark_mode';
  late bool _isDarkMode;
  bool _isAppInForeground = true;
  final CreditsService _creditsService = CreditsService();
  final AppUsageService _appUsageService = AppUsageService();
  Timer? _usageTimer;

  @override
  void initState() {
    super.initState();
    // Tema zaten main()'de yüklendi, direkt kullan - splash gecikmesi yok
    _isDarkMode = widget.initialDarkMode;
    WidgetsBinding.instance.addObserver(this);
    _enableFullscreenSystemUi();

    // Credits service'i başlat ve dinle
    _initializeCreditsService();

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
    // Premium state AppStartupService/PurchaseManager tarafindan yonetilir;
    // burada sadece degisimleri dinliyoruz.
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
      });
    } catch (e) {
      debugPrint('❌ Tema yükleme hatası: $e');
      // Hata durumunda varsayılan değerle devam et
      setState(() {
        _isDarkMode = false;
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

    // 🚀 PERFORMANCE MOD: Lifecycle'a göre cache optimizasyonu
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        _enableFullscreenSystemUi();
        ImageCacheManager.restoreForForeground();

        // Uygulama aktif olduğunda kullanım süresini güncelle
        _appUsageService.updateUsage();
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
    // Provider entegrasyonu: PurchaseManager'ı tüm ağaca enjekte et
    return MultiProvider(
      providers: [
        // 🔧 ANR DÜZELTMESİ: ..initialize() KALDIRILDI!
        // PurchaseManager singleton olarak agaca verilir; init akisi
        // AppStartupService tarafindan kontrol edilir.
        ChangeNotifierProvider.value(value: PurchaseManager()),
      ],
      child: MaterialApp(
        title: 'Kavaid - Arapça Sözlük',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: StartupScreen(
          isDarkMode: _isDarkMode,
          onThemeToggle: _toggleTheme,
        ),
        builder: (context, child) {
          // 🚀 PERFORMANCE MOD: Yüksek FPS için optimize edilmiş MediaQuery
          final mediaQuery = MediaQuery.of(context);

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // Her dokunuşta klavyeyi kapat (sistem + Arapça)
              FocusManager.instance.primaryFocus?.unfocus();
              SystemChannels.textInput.invokeMethod('TextInput.hide');
              Future.delayed(
                const Duration(milliseconds: 250),
                _enableFullscreenSystemUi,
              );
            },
            child: MediaQuery(
              data: mediaQuery.copyWith(
                // Performans için optimize edilmiş değerler
                devicePixelRatio: mediaQuery.devicePixelRatio,
                // Text scaling'i stabil tut (PERFORMANCE: deprecated textScaleFactor tamamen kaldırıldı)
                textScaler: TextScaler.linear(
                  mediaQuery.textScaler.scale(1.0).clamp(0.8, 1.2),
                ),
              ),
              child: ScrollConfiguration(
                // Overscroll glow efektini kaldır - performans artışı sağlar
                behavior: NoGlowScrollBehavior(),
                child: RepaintBoundary(
                  // 🚀 PERFORMANCE MOD: Ana uygulama RepaintBoundary ile sarılı
                  child: FPSOverlay(
                    showFPS:
                        false, // Debug mesajlarını önlemek için tamamen kapalı
                    detailedFPS: false,
                    child: SafeArea(
                      // 🔧 Status bar ve Nav bar ayarları (kamera çentiği arkasına kadar boyama vs.)
                      top: false,
                      bottom: false,
                      child: child!,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
      scaffoldBackgroundColor: const Color(
        0xFFF5F7FB,
      ), // Daha mavimsi arka plan
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
        color: const Color(
          0xFFFFFFFF,
        ), // Tam beyaz kartlar daha belirgin olması için
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD1D1D6), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD1D1D6), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xCCFFFFFF), // white @ 0.8
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: const Color(0xFF8E8E93),
        backgroundColor: const Color(0xF2FFFFFF), // white @ 0.95
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
        ), // Font ailesini uygula
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
        ), // Font ailesini uygula
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF007AFF),
        unselectedItemColor: Color(0xFF8E8E93),
        backgroundColor: Color(
          0xFF1C1C1E,
        ), // Karanlık tema için siyah navigation bar
        selectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
        ), // Font ailesini uygula
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
        ), // Font ailesini uygula
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onThemeToggle;

  const MainScreen({super.key, required this.isDarkMode, this.onThemeToggle});

  /// Global key for accessing MainScreen state from anywhere
  static final GlobalKey<_MainScreenState> globalKey =
      GlobalKey<_MainScreenState>();

  /// Navigate to Learning tab (index 1)
  static void navigateToLearning() {
    globalKey.currentState?._navigateToTab(1);
  }

  /// Push a route to the Learning tab's navigator
  static void pushToLearningTab(Route route) {
    // Önce tab'a geç
    navigateToLearning();

    // Sonra route'u pushla (biraz gecikmeli ki tab değişsin)
    Future.delayed(const Duration(milliseconds: 100), () {
      globalKey.currentState?._learningTabNavKey.currentState?.push(route);
    });
  }

  /// Open specific list detail in Learning tab (clears stack first)
  static void openListDetailInLearningTab(CustomWordList list, bool isDark) {
    // 1. Öğren sekmesine geç
    navigateToLearning();

    Future.delayed(const Duration(milliseconds: 100), () {
      final nav = globalKey.currentState?._learningTabNavKey.currentState;
      if (nav != null) {
        // Önce stack'i temizle (LearningScreen'e dön)
        nav.popUntil((route) => route.isFirst);

        // Sonra CustomWordsScreen (Listelerim) aç
        nav.push(
          MaterialPageRoute(
            builder: (_) => CustomWordsScreen(isDarkMode: isDark),
          ),
        );

        // Sonra WordListDetailScreen (Kelimeler) aç
        Future.delayed(const Duration(milliseconds: 150), () {
          nav.push(
            MaterialPageRoute(
              builder: (_) =>
                  WordListDetailScreen(list: list, isDarkMode: isDark),
            ),
          );
        });
      }
    });
  }

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
  final GlobalKey<NavigatorState> _learningTabNavKey =
      GlobalKey<NavigatorState>();

  // Public getter for navigation key
  GlobalKey<NavigatorState> get learningTabNavKey => _learningTabNavKey;

  // Admin servis
  final AdminService _adminService = AdminService();
  // Subscriptionlar
  StreamSubscription<User?>? _authSubscription;

  // Öğren sekmesi bildirim badge'i
  bool _showLearningBadge = false;

  @override
  void initState() {
    super.initState();
    _checkLearningBadgeStatus();

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
          // Açık SnackBar varsa kapat
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          // İnternet geldi — premium durumunu güncel verilerle yenile
          unawaited(PurchaseManager().refreshEntitlements());
        }
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _connectivityService.stopListening();
    super.dispose();
  }

  /// Navigate to a specific tab by index
  void _navigateToTab(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Yerel veritabanı hazır mı? Hazırsa internetsiz kullanım mümkün => engelleyici dialog gerekmez
  Future<bool> _shouldBlockForNoInternet() async {
    try {
      final db = await DatabaseService.instance.database;
      if (db == null) return true; // Web platformu - internet gerekli

      final tableInfo = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='words'",
      );
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

  Future<void> _checkLearningBadgeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // true ise daha önce açılmış demektir, badge gösterme
      final hasOpened = prefs.getBool('has_opened_learning_tab') ?? false;
      if (mounted) {
        setState(() {
          _showLearningBadge = !hasOpened;
        });
      }
    } catch (e) {
      debugPrint('❌ Badge durumu kontrol hatası: $e');
    }
  }

  // Görünür sekmelerin IndexedStack index'lerini döndür
  List<int> _getVisibleStackIndices() {
    return [
      0, // Sözlük
      2, // Ceviri
      if (!LanguageService().isEnglish && !LanguageService().isArabic)
        1, // Öğren
      3, // Profil
      if (_adminService.isAdmin()) 4, // Admin Console
    ];
  }

  // Navigation bar index'ini IndexedStack index'ine çevir
  int _mapNavigationToStackIndex(int navIndex) {
    final indices = _getVisibleStackIndices();
    if (navIndex < indices.length) {
      return indices[navIndex];
    }
    return 0;
  }

  // IndexedStack index'ini Navigation bar index'ine çevir
  int _mapStackToNavigationIndex(int stackIndex) {
    final indices = _getVisibleStackIndices();
    final navIndex = indices.indexOf(stackIndex);
    return navIndex >= 0 ? navIndex : 0;
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

    // Öğren sekmesine tıklandıysa badge'i kaldır ve kaydet (index 1 = Öğren)
    if (realIndex == 1 && _showLearningBadge) {
      setState(() {
        _showLearningBadge = false;
      });
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('has_opened_learning_tab', true);
      });
    }

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
    const navBarHeight = 64.0;
    const navBarBottomGap = 0.0;
    const systemNavBarHeight = 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // STATUS BAR: Tema uyumlu renk ayarları
        statusBarColor: widget.isDarkMode
            ? const Color(0xFF1C1C1E) // Dark tema için siyah
            : const Color(0xFF007AFF), // Light tema için ana mavi
        statusBarIconBrightness: widget.isDarkMode
            ? Brightness
                  .light // Dark tema için beyaz iconlar
            : Brightness
                  .light, // Light tema için beyaz iconlar (mavi arka planda)
        statusBarBrightness: widget.isDarkMode
            ? Brightness
                  .dark // iOS için - dark tema
            : Brightness.dark, // iOS için - light tema
        // System navigation bar ayarları
        systemNavigationBarColor: widget.isDarkMode
            ? const Color(0xFF1C1C1E) // Dark tema için siyah
            : Colors.white, // Light tema için beyaz
        systemNavigationBarIconBrightness: widget.isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
      child: PopScope(
        canPop: false, // Geri tuşunu manuel yönetiyoruz
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          // Klavye açıksa önce klavyeyi kapat, hiçbir sayfayı pop etme
          if (hasSystemKeyboard) {
            FocusScope.of(context).unfocus();
            return;
          }
          // Öğren sekmesindeki iç Navigator geri gidebiliyorsa önce onu pop et
          if (_currentIndex == 1) {
            if (_learningTabNavKey.currentState?.canPop() == true) {
              _learningTabNavKey.currentState!.pop();
              return; // Uygulamadan çıkma
            }
            // Öğren sekmesinin ana sayfasındayken geri tuşu uygulamayı kapatmasın, Ana sekmeye dön
            setState(() => _currentIndex = 0);
            return;
          }
          // Diğer sekmelerde: eğer kök navigator bir sayfa/diğer route gösterebiliyorsa önce onu kapat
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
          // Diğer sekmelerdeyken geri tuşu uygulamayı kapatmak yerine Ana sekmeye dönsün
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
            return;
          }
          // Ana sekmede, sistemin geri tuşu davranışını uygula
          Navigator.of(context).maybePop();
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
                      final totalBottomPadding =
                          _bannerHeight +
                          navBarHeight +
                          navBarBottomGap +
                          systemNavBarHeight;

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
                            onArabicKeyboardStateChanged:
                                _setArabicKeyboardState,
                            isFirstOpen: _isFirstOpen,
                            onKeyboardOpened: () {
                              if (_isFirstOpen)
                                setState(() => _isFirstOpen = false);
                            },
                          ),

                          // 1: Öğren (iç Navigator) - state korunur
                          Padding(
                            key: const ValueKey('learning_screen'),
                            padding: EdgeInsets.only(
                              bottom: totalBottomPadding,
                            ),
                            child: Navigator(
                              key: _learningTabNavKey,
                              onGenerateRoute: (settings) {
                                return MaterialPageRoute(
                                  builder: (_) => LearningScreen(
                                    // bottomPadding parametresini KALDIRDIM (LearningScreen constuctor'ında yok)
                                  ),
                                  settings: settings,
                                );
                              },
                            ),
                          ),

                          // 2: Profil - her zaman ağaçta, state korunur
                          TranslationScreen(
                            key: const ValueKey('translation_screen'),
                            bottomPadding: totalBottomPadding,
                            isDarkMode: widget.isDarkMode,
                            isEmbedded: false,
                          ),

                          ProfileScreen(
                            key: const ValueKey('profile_screen'),
                            bottomPadding: totalBottomPadding,
                            isDarkMode: widget.isDarkMode,
                            onThemeToggle: widget.onThemeToggle,
                          ),

                          // 3: Admin Console - sadece aktifken ve adminse oluştur
                          _adminService.isAdmin() && _currentIndex == 4
                              ? AdminConsoleScreen(
                                  key: const ValueKey('admin_screen'),
                                  topPadding: _bannerHeight,
                                  bottomPadding:
                                      navBarHeight +
                                      navBarBottomGap +
                                      systemNavBarHeight,
                                )
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
                // Admin Console ekranında banner üstte, diğerlerinde altta
                top: (_adminService.isAdmin() && _currentIndex == 4)
                    ? MediaQuery.of(context).viewPadding.top
                    : null,
                bottom: (_adminService.isAdmin() && _currentIndex == 4)
                    ? null
                    : (hasSystemKeyboard
                          ? keyboardHeight // Klavye açıkken direkt klavyenin üstünde - nav bar hesaplama
                          : (_showArabicKeyboard &&
                                _currentIndex ==
                                    0) // Sadece Home Screen'de klavye
                          ? 280.0 +
                                navBarHeight +
                                navBarBottomGap +
                                systemNavBarHeight // Klavye + nav bar üstünde
                          : navBarHeight +
                                navBarBottomGap +
                                systemNavBarHeight),
                left: 0,
                right: 0,
                height: _bannerHeight,
                child: RepaintBoundary(
                  child: BannerAdWidget(
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
                  // Admin Console ekranında üstte, diğerlerinde altta
                  top: (_adminService.isAdmin() && _currentIndex == 4)
                      ? MediaQuery.of(context).viewPadding.top +
                            _bannerHeight -
                            10
                      : null,
                  bottom: (_adminService.isAdmin() && _currentIndex == 4)
                      ? null
                      : (hasSystemKeyboard
                            ? keyboardHeight +
                                  _bannerHeight -
                                  10 // Klavye açıkken banner'ın 10px üstünde
                            : (_showArabicKeyboard &&
                                  _currentIndex ==
                                      0) // Sadece Home Screen'de klavye
                            ? 280.0 +
                                  navBarHeight +
                                  navBarBottomGap +
                                  systemNavBarHeight +
                                  _bannerHeight -
                                  10
                            : navBarHeight +
                                  navBarBottomGap +
                                  systemNavBarHeight +
                                  _bannerHeight -
                                  10),
                  right: -8, // Daha sağa
                  child: GestureDetector(
                    onTap: () {
                      // AdMob kaldırıldığı için işlem yapmıyoruz
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

              // 3. Bottom Navigation Bar - klasik alta yapışık bar
              Positioned(
                bottom: navBarBottomGap,
                left: 0,
                right: 0,
                height: navBarHeight,
                child: RepaintBoundary(
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? const Color(0xFF1C1C1E)
                          : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: widget.isDarkMode
                              ? const Color(0x1FFFFFFF)
                              : const Color(0x14000000),
                          width: 0.7,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isDarkMode
                              ? const Color(0x66000000)
                              : const Color(0x16000000),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: MediaQuery.removePadding(
                      context: context,
                      removeBottom: true,
                      child: MediaQuery.removeViewPadding(
                        context: context,
                        removeBottom: true,
                        child: BottomNavigationBar(
                          currentIndex: _mapStackToNavigationIndex(
                            _currentIndex,
                          ),
                          onTap: _onTabTapped,
                          type: BottomNavigationBarType.fixed,
                          backgroundColor: widget.isDarkMode
                              ? const Color(0xFF1C1C1E)
                              : Colors.white,
                          selectedItemColor: const Color(0xFF007AFF),
                          unselectedItemColor: const Color(0xFF8E8E93),
                          selectedLabelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                          ),
                          elevation: 0,
                          iconSize: 26,
                          items: [
                            BottomNavigationBarItem(
                              icon: const Icon(Icons.menu_book_outlined),
                              activeIcon: const Icon(Icons.menu_book),
                              label: LanguageService().isEnglish
                                  ? 'Dictionary'
                                  : (LanguageService().isArabic
                                        ? 'قاموس'
                                        : 'Sözlük'),
                            ),
                            const BottomNavigationBarItem(
                              icon: Icon(Icons.translate_outlined),
                              activeIcon: Icon(Icons.translate),
                              label: 'Çeviri',
                            ),
                            if (!LanguageService().isEnglish &&
                                !LanguageService().isArabic)
                              BottomNavigationBarItem(
                                icon: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.school_outlined),
                                    if (_showLearningBadge)
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: widget.isDarkMode
                                                  ? const Color(0xFF1C1C1E)
                                                  : Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                activeIcon: const Icon(Icons.school),
                                label: 'Öğren',
                              ),
                            BottomNavigationBarItem(
                              icon: const Icon(Icons.person_outline),
                              activeIcon: const Icon(Icons.person),
                              label: LanguageService().isEnglish
                                  ? 'Profile'
                                  : (LanguageService().isArabic
                                        ? 'الملف الشخصي'
                                        : 'Profil'),
                            ),
                            if (_adminService.isAdmin())
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
      debugPrint(
        '🔄 [MIGRATION] Kullanıcı adı migration kontrolü başlatılıyor...',
      );

      // SharedPreferences'ta migration'ın daha önce çalışıp çalışmadığını kontrol et
      final prefs = await SharedPreferences.getInstance();
      final migrationCompleted =
          prefs.getBool('username_migration_completed_v2') ?? false;

      if (!migrationCompleted) {
        debugPrint('📋 [MIGRATION] Migration gerekli, başlatılıyor...');

        // Migration'ı çalıştır
        await MigrateUsernames.migrateAllUsers();

        // Migration'ın tamamlandığını işaretle
        await prefs.setBool('username_migration_completed_v2', true);
        debugPrint(
          '✅ [MIGRATION] Migration başarıyla tamamlandı ve işaretlendi',
        );
      } else {
        debugPrint('ℹ️ [MIGRATION] Migration zaten tamamlanmış, atlanıyor');
      }
    } catch (e) {
      debugPrint('❌ [MIGRATION] Migration hatası: $e');
    }
  });
}
