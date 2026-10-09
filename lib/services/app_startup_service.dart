import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/safe_purchase_wrapper.dart';
import 'app_usage_service.dart';
import 'database_initialization_service.dart';
import 'database_service.dart';
import 'emsile_database_service.dart';
import 'gemini_service.dart';
import 'global_config_service.dart';
import 'language_service.dart';
import 'purchase_manager.dart';
import 'quran_dictionary_service.dart';
import 'review_service.dart';
import 'saved_words_service.dart';
import 'tts_service.dart';
import 'turkce_analytics_service.dart';

enum StartupPhase {
  visualPrep,
  checking,
  installingDictionary,
  warmingSearch,
  ready,
  recoverableError,
}

class AppStartupService extends ChangeNotifier {
  AppStartupService._();

  static final AppStartupService instance = AppStartupService._();

  StartupPhase _phase = StartupPhase.visualPrep;
  double _progress = 0.0;
  String _message = 'Yükleniyor...';
  bool _isMainDictionaryReady = false;
  bool _isWarmupRunning = false;
  String? _errorMessage;

  Future<void>? _startupFuture;
  Future<void>? _warmupFuture;
  bool _deferredStarted = false;

  StartupPhase get phase => _phase;
  double get progress => _progress;
  String get message => _message;
  bool get isMainDictionaryReady => _isMainDictionaryReady;
  bool get isWarmupRunning => _isWarmupRunning;
  String? get errorMessage => _errorMessage;
  bool get isReady => _phase == StartupPhase.ready;

  Future<void> start({BuildContext? context}) {
    _startupFuture ??= _runStartup(context);
    return _startupFuture!;
  }

  Future<void> retry({BuildContext? context}) {
    _startupFuture = null;
    _warmupFuture = null;
    _deferredStarted = false;
    _errorMessage = null;
    return start(context: context);
  }

  Future<void> _runStartup(BuildContext? context) async {
    try {
      await _prepareVisuals(context);
      await _prepareMainDictionary();
      await _prepareMainSearchCache();

      _setState(
        phase: StartupPhase.ready,
        progress: 1.0,
        message: 'Sözlük hazır.',
        isMainDictionaryReady: true,
      );

      _startWarmups();
      _startDeferredTasks();
    } catch (e) {
      _errorMessage = e.toString();
      _setState(
        phase: StartupPhase.recoverableError,
        progress: 0.0,
        message: 'Sözlük yüklenemedi.',
        isMainDictionaryReady: false,
      );
    }
  }

  Future<void> _prepareVisuals(BuildContext? context) async {
    _setState(
      phase: StartupPhase.visualPrep,
      progress: 0.03,
      message: 'Ekran hazırlanıyor...',
      isMainDictionaryReady: false,
    );

    final tasks = <Future<void>>[
      _loadStartupFonts(),
      LanguageService().initialize(),
    ];

    if (context != null) {
      tasks.add(_precacheStartupAssets(context));
    }

    await Future.wait(
      tasks.map(
        (task) => task.catchError((e) {
          debugPrint('Visual startup task error: $e');
        }),
      ),
    ).timeout(const Duration(seconds: 4), onTimeout: () => <void>[]);
  }

  Future<void> _loadStartupFonts() async {
    final interLoader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(
        rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf'),
      );

    final arabicLoader = FontLoader('ScheherazadeNew')
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Bold.ttf'));

    // ANR: fontları paralel yükle, tek tek 2sn bekleme (toplam 4sn blok).
    await Future.wait([
      interLoader.load().timeout(const Duration(seconds: 2)).catchError((e) {
        debugPrint('Inter font load error: $e');
      }),
      arabicLoader.load().timeout(const Duration(seconds: 2)).catchError((e) {
        debugPrint('Arabic font load error: $e');
      }),
    ]);
  }

  Future<void> _precacheStartupAssets(BuildContext context) async {
    await precacheImage(
      const AssetImage('assets/images/app_icon.png'),
      context,
    ).timeout(const Duration(seconds: 2));
  }

  Future<void> _prepareMainDictionary() async {
    _setState(
      phase: StartupPhase.checking,
      progress: 0.12,
      message: 'Sözlük kontrol ediliyor...',
      isMainDictionaryReady: false,
    );

    // Sözlük dolu ve uygulamayla gelen veri sürümüyle aynıysa kurulumu atla.
    // Sürüm farklıysa (veri güncellendiyse) aşağıda yeniden kurulur.
    if (await _hasUsableMainDictionary(requireCurrentData: true)) {
      _isMainDictionaryReady = true;
      _setState(
        phase: StartupPhase.checking,
        progress: 0.72,
        message: 'Sözlük hazır.',
        isMainDictionaryReady: true,
      );
      return;
    }

    _setState(
      phase: StartupPhase.installingDictionary,
      progress: 0.18,
      message: 'Sözlük ayarlanıyor...',
    );

    final initService = DatabaseInitializationService.instance;
    initService.onProgress = (progress, message) {
      _setState(
        phase: StartupPhase.installingDictionary,
        progress: (0.18 + progress.clamp(0.0, 1.0) * 0.54).clamp(0.18, 0.72),
        message: message,
      );
    };

    final bool success;
    try {
      success = await initService.initializeDatabase();
    } finally {
      initService.onProgress = null;
    }

    // Yeniden kurulum yarıda kalsa bile eldeki sözlükle devam edilir;
    // sürüm işaretlenmediği için bir sonraki açılışta tekrar denenir.
    if (!success || !await _hasUsableMainDictionary()) {
      throw StateError('Ana sözlük veritabanı hazırlanamadı.');
    }

    _isMainDictionaryReady = true;
    _setState(
      phase: StartupPhase.installingDictionary,
      progress: 0.72,
      message: 'Sözlük hazır.',
      isMainDictionaryReady: true,
    );
  }

  Future<void> _prepareMainSearchCache() async {
    if (kIsWeb || DatabaseService.isSearchCacheReady) return;

    _setState(
      phase: StartupPhase.warmingSearch,
      progress: 0.76,
      message: 'Arama hazırlanıyor...',
    );

    // ANR: arama cache'i kritik yol değil. Isolate düşük cihazda
    // takılırsa ready'yi bloklamasın — 3sn'de pes et, arkada devam etsin.
    try {
      await DatabaseService.ensureSearchCacheReady().timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Search cache warmup timeout (deferred): $e');
      // Arka planda tekrar dene, ready'yi engelleme.
      unawaited(
        DatabaseService.ensureSearchCacheReady().catchError((e) {
          debugPrint('Search cache deferred retry error: $e');
        }),
      );
    }

    _setState(
      phase: StartupPhase.warmingSearch,
      progress: 0.96,
      message: 'Arama hazır.',
    );
  }

  Future<bool> _hasUsableMainDictionary({
    bool requireCurrentData = false,
  }) async {
    if (kIsWeb) {
      return true;
    }

    // ANR: SQLite ilk açılış düşük cihazda saniyeler sürebilir.
    try {
      final count = await DatabaseService.instance
          .getWordsCount()
          .timeout(const Duration(seconds: 4));
      if (count == 0) return false;
      if (!requireCurrentData) return true;
      return await DatabaseInitializationService.instance
          .isInstalledDataCurrent();
    } catch (e) {
      debugPrint('_hasUsableMainDictionary timeout/error: $e');
      return false;
    }
  }

  void _startWarmups() {
    if (_warmupFuture != null) return;
    _isWarmupRunning = true;
    notifyListeners();

    _warmupFuture =
        Future(() async {
          await Future.wait([
            QuranDictionaryService.instance.initialize().catchError((e) {
              debugPrint('Quran dictionary warmup error: $e');
            }),
            TTSService()
                .warmUp()
                .timeout(const Duration(seconds: 3))
                .catchError((e) {
                  debugPrint('TTS warmup error: $e');
                }),
            EmsileDatabaseService.instance.preInit().catchError((e) {
              debugPrint('Emsile database warmup error: $e');
            }),
          ]);
        }).whenComplete(() {
          _isWarmupRunning = false;
          notifyListeners();
        });
  }

  void _startDeferredTasks() {
    if (_deferredStarted) return;
    _deferredStarted = true;

    // ANR: ready sonrası tüm ağır işleri aynı anda microtask'e yığma.
    // İlk frame + kullanıcı input'u ile yarışıp dispatch timeout'a
    // sokuyordu. Kademeli gecikmeyle yay.
    _runDeferredTask('purchase bootstrap', () {
      return PurchaseManager().bootstrapEntitlements().timeout(
        const Duration(seconds: 5),
      );
    }, delay: const Duration(milliseconds: 1500));
    _runDeferredTask('safe purchase wrapper', () {
      return SafePurchaseWrapper.initializeService().timeout(
        const Duration(seconds: 2),
      );
    }, delay: const Duration(seconds: 2));
    _runDeferredTask('saved words', () {
      return SavedWordsService().initialize().timeout(
        const Duration(seconds: 2),
      );
    }, delay: const Duration(seconds: 3));
    _runDeferredTask('usage session', () {
      return AppUsageService().startSession().timeout(
        const Duration(seconds: 1),
      );
    });
    _runDeferredTask('analytics', () {
      return TurkceAnalyticsService.uygulamaBaslatildi().timeout(
        const Duration(seconds: 2),
      );
    });
    _runDeferredTask('remote config', () {
      return GlobalConfigService().init().timeout(const Duration(seconds: 3));
    });
    _runDeferredTask('gemini config', () {
      return GeminiService().initialize().timeout(const Duration(seconds: 5));
    });
    _runDeferredTask('review service', () {
      return ReviewService().initialize().timeout(const Duration(seconds: 1));
    });
  }

  void _runDeferredTask(
    String name,
    Future<void> Function() task, {
    Duration delay = Duration.zero,
  }) {
    Future.delayed(delay, () async {
      // İlk frame çizilmeden ağır işe girme.
      try {
        await Future<void>.delayed(Duration.zero);
        await task();
      } catch (e) {
        debugPrint('Deferred startup task error ($name): $e');
      }
    });
  }

  void _setState({
    required StartupPhase phase,
    required double progress,
    required String message,
    bool? isMainDictionaryReady,
  }) {
    _phase = phase;
    _progress = progress.clamp(0.0, 1.0);
    _message = message;
    if (isMainDictionaryReady != null) {
      _isMainDictionaryReady = isMainDictionaryReady;
    }
    notifyListeners();
  }
}
