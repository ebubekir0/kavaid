import 'dart:async';
// PERFORMANCE: dart:isolate importı kaldırıldı (kullanılmıyordu)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/word_model.dart';
import '../models/quran_word_model.dart';
import '../services/gemini_service.dart';
import '../services/database_service.dart'; // YEREL VERİTABANI SERVİSİ
import '../services/database_initialization_service.dart';
import '../services/credits_service.dart';
import '../services/book_store_service.dart';
import '../services/turkce_analytics_service.dart';
import '../services/quran_dictionary_service.dart';
import '../services/emsile_database_service.dart';
import '../widgets/word_card.dart';
import '../widgets/search_result_card.dart';
import '../widgets/quran_word_card.dart';
import '../widgets/arabic_keyboard.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/performance_utils.dart';
import '../utils/quran_mode_notifier.dart';
import '../services/admob_service.dart';
import 'package:kavaid/services/connectivity_service.dart';
import 'package:kavaid/services/review_service.dart';
import 'package:kavaid/services/sync_service.dart';
import 'package:kavaid/services/app_usage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'log_screen.dart';
import 'custom_words_screen.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart'; // Kuran modu Arapça metin için hala gerekli
import '../widgets/quran_onboarding.dart';
import '../widgets/emsile_view.dart';
import '../utils/dictionary_mode_notifier.dart';
import 'subscription_screen.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/language_service.dart';
import '../widgets/campaign_banner.dart';
import '../services/global_config_service.dart';
import '../services/purchase_manager.dart';
import '../services/promo_code_service.dart';
import 'package:provider/provider.dart';

// Arka planda arama sonuçlarını sıralama fonksiyonu kaldırıldı
// Artık DatabaseService.searchWords() zaten doğru sıralamayı yapıyor

class HomeScreen extends StatefulWidget {
  final double bottomPadding;
  final bool isDarkMode;
  final VoidCallback? onThemeToggle;
  final Function(bool)? onArabicKeyboardStateChanged;
  final bool isFirstOpen;
  final VoidCallback? onKeyboardOpened;
  final bool isActive; // Sekmenin aktif olup olmadığını kontrol eder

  const HomeScreen({
    super.key,
    required this.bottomPadding,
    required this.isDarkMode,
    this.onThemeToggle,
    this.onArabicKeyboardStateChanged,
    this.isFirstOpen = false,
    this.onKeyboardOpened,
    required this.isActive,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GeminiService _geminiService = GeminiService();
  final DatabaseService _dbService =
      DatabaseService.instance; // YEREL DB SERVİSİ
  final CreditsService _creditsService = CreditsService();

  WordModel? _selectedWord;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _showAIButton = false; // AI butonu tamamen devre dışı bırakıldı
  bool _showNotFound = false;
  bool _showArabicKeyboard = false; // Arapça klavye durumu
  bool _isSearchInProgress = false; // Arama işlemi devam ediyor mu
  int _searchGeneration = 0;
  List<WordModel> _searchResults = []; // Arama sonuçları
  Timer? _debounceTimer;
  Timer? _interstitialTimer;
  StreamSubscription? _searchSubscription;
  Timer? _tapHintTimer;
  OverlayEntry? _tapHintOverlay;
  bool _didAutoOpenKeyboard = false; // Bir kez klavye açıldı mı?
  String _lastSearchText = ''; // Son arama metnini takip et
  String _normalSearchText = ''; // Normal sözlükteki son arama
  String _quranSearchText = ''; // Kuran sözlüğündeki son arama
  bool _hasInternet = true; // İnternet bağlantısı var mı?
  bool _scrollDebounce = false; // Scroll başlangıcını throttle et
  bool _prewarmPending =
      false; // İlk detay açılış jank'ını önlemek için prewarm

  // Kuran sözlüğü state
  bool _isQuranMode = false;
  bool _isQuranDictionaryLoading = false;
  bool _isEmsileMode = false; // Emsile (fiil çekimleri) modu
  final QuranDictionaryService _quranService = QuranDictionaryService.instance;
  List<QuranWordModel> _quranSearchResults = [];
  QuranWordModel? _selectedQuranWord;
  List<Map<String, dynamic>> _emsileSearchResults = [];
  final int _emsileRandomSeed = DateTime.now().millisecondsSinceEpoch % 1000000;

  // Sesli arama state
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  int _aiSearchClickCount = 0;
  final AdMobService _adMobService = AdMobService();
  final ReviewService _reviewService = ReviewService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();
  final AppUsageService _appUsageService = AppUsageService();

  // Kuran kullanım süresi takibi
  int _quranUsageSeconds = 0;
  Timer? _quranUsageTimer;
  static const int _quranTimeLimit = 1800; // 30 dakika (30 * 60)
  static const String _quranUsageKey = 'quran_dictionary_usage_seconds';

  // İPUCU: Sonuç kartına dokun ipucu overlay'i
  static const String _tapHintKey = 'has_shown_tap_result_hint';
  bool _hasShownTapHint = false;
  bool get _debugAlwaysShowHint => kDebugMode;

  bool get wantKeepAlive =>
      true; // Keep alive açık: sekmeler arası geçişte state korunsun

  bool _containsArabic(String s) => RegExp(r'[\u0600-\u06FF]').hasMatch(s);

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    // Kuran modunu dinle
    _isQuranMode = quranModeNotifier.value;
    quranModeNotifier.addListener(_onQuranModeChanged);

    // Global mod dinleyicisi (Sözlük/Kuran/Emsile)
    _isEmsileMode = dictionaryModeNotifier.value == DictionaryMode.emsile;
    dictionaryModeNotifier.addListener(_onDictionaryModeChanged);

    // Emsile araması dışarıdan (Sözlük kartından vb) tetiklenmesi
    emsileSearchNotifier.addListener(_onEmsileSearchTriggered);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isQuranMode) {
          _quranService.initialize();
        }
      });

      if (_isEmsileMode) {
        Future.microtask(_loadRandomEmsile);
      }
    });

    _creditsService.addListener(_onCreditsChanged);
    _appUsageService.addListener(_onAppUsageChanged);

    // İnternet bağlantısını kontrol et
    _checkInternetConnection();

    // Kuran kullanım süresini yükle
    _loadQuranUsage();

    // Reklam yüklemelerini arka planda yap - ana thread'i bloke etme
    Future.microtask(() {
      _loadNativeAd();
      _adMobService.loadInterstitialAd();
    });

    // İpucu flag'ini yükle
    _loadTapHintFlag();

    // Focus listener - artık Arapça klavyeyi KAPATMA
    // Sekme geçişlerinde vs. klavye kapanmasın diye bu kısım kaldırıldı

    // İlk açılışta otomatik klavye açma - EN HIZLI ŞEKİLDE
    if (widget.isActive && widget.isFirstOpen && !_didAutoOpenKeyboard) {
      _didAutoOpenKeyboard = true;

      // İlk frame render edilir edilmez hemen klavyeyi aç
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // TextField'a focus ver ve klavyeyi kesinlikle aç
        _openKeyboardWithFocus();

        // Dışarıya haber ver
        widget.onKeyboardOpened?.call();
      });
    }
    // İlk açılışta prewarm başlat (Shader compilation jank önleme)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _prewarmPending = true);
        // 2 saniye sonra warm-up widget'ını kaldır
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _prewarmPending = false);
        });

        // Emsile modu aktifse ve kart yoksa yükle
        if (_isEmsileMode && _emsileSearchResults.isEmpty) {
          _loadRandomEmsile();
        }
      }
    });
  }

  void _onEmsileSearchTriggered() {
    if (!mounted) return;
    final value = emsileSearchNotifier.value;
    if (value.isEmpty) return;

    final query = value.split('|').first;
    if (query.isNotEmpty) {
      // Önce lastSearchText'i güncelle ki debouncer tetiklenmesin
      _lastSearchText = query;
      _searchController.text = query;

      // Emsile moduna geç
      if (dictionaryModeNotifier.value != DictionaryMode.emsile) {
        dictionaryModeNotifier.value = DictionaryMode.emsile;
      }

      // Aramayı başlat
      _isEmsileMode = true;
      _isSearching = true;
      _isLoading = true;
      _performSearch(query.trim());
    }
  }

  void _startListening() async {
    if (_searchFocusNode.hasFocus) _searchFocusNode.unfocus();
    if (_showArabicKeyboard) {
      setState(() => _showArabicKeyboard = false);
      widget.onArabicKeyboardStateChanged?.call(false);
    }

    // Geçen metni seçmek yerine temizle
    _searchController.clear();

    // Yalnızca kullanıcı mikrofona basınca izin istenecek
    if (!_speechEnabled) {
      try {
        _speechEnabled = await _speechToText.initialize();
      } catch (_) {}

      // İzin verilmediyse dur
      if (!_speechEnabled) return;
    }

    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _searchController.text = result.recognizedWords;
          });
        }
      },
      localeId: 'ar_SA', // Arapça olarak algıla
      cancelOnError: true,
      partialResults: true,
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  // İnternet bağlantısını kontrol et
  Future<void> _checkInternetConnection() async {
    final hasConnection = await _connectivityService.hasInternetConnection();
    if (mounted) {
      setState(() {
        _hasInternet = hasConnection;
      });
    }

    // 🔧 ANR DÜZELTMESİ: startListening() KALDIRILDI
    // MainScreen zaten global connectivity listener çalıştırıyor.
    // HomeScreen'de ikinci bir listener başlatmak ConnectivityService'in
    // önceki subscription'ı iptal etmesine neden oluyordu (race condition).
    // Sadece başlangıçta tek seferlik kontrol yeterli.
  }

  // Klavyeyi doğal şekilde açmak için yardımcı metod
  bool get _shouldShowReviewPrompt =>
      !_isQuranMode &&
      !_isEmsileMode &&
      _hasInternet &&
      _appUsageService.shouldShowRating;
  bool get _showLegacyFloatingReviewButton => false;

  Future<void> _openReviewPrompt() async {
    await _appUsageService.markRatingPromptClicked();
    if (mounted) {
      setState(() {});
    }
    await _reviewService.requestReview();
  }

  void _forceOpenKeyboard() {
    if (!mounted) return;
    // Sadece focus ver, sistem klavyeyi kendisi açar
    // SystemChannels kullanımı kaldırıldı - klavye dilini sıfırlıyordu
  }

  // Focus ile klavye açma - Doğal yöntem
  void _openKeyboardWithFocus() {
    if (!mounted) return;

    // Sadece focus ver, sistem klavyeyi doğal şekilde açar
    _searchFocusNode.requestFocus();
  }

  // Credits değiştiğinde çağrılacak metod
  void _onCreditsChanged() {
    if (mounted) {
      setState(() {
        // UI'yi güncelle
      });
    }
  }

  // SharedPreferences'tan ipucu bayrağını yükle
  void _onAppUsageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTapHintFlag() async {
    try {
      if (_debugAlwaysShowHint) {
        // Debug modunda her seferinde gösterim serbest
        _hasShownTapHint = false;
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      _hasShownTapHint = prefs.getBool(_tapHintKey) ?? false;
    } catch (_) {}
  }

  Future<void> _markTapHintShown() async {
    if (_debugAlwaysShowHint) {
      // Debug modunda kalıcı işaretleme yapma ki her aramada gösterilebilsin
      return;
    }
    _hasShownTapHint = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tapHintKey, true);
    } catch (_) {}
  }

  void _removeTapHintOverlay() {
    _tapHintTimer?.cancel();
    _tapHintOverlay?.remove();
    _tapHintOverlay = null;
  }

  void _showTapHintOverlayIfNeeded() {
    // Debug modda ipucu overlay kapalı, release modda açık
    if (kDebugMode) return;

    if (!mounted) return;
    if (!_debugAlwaysShowHint && _hasShownTapHint) return;
    // Sadece sözlük (arama listesi) görünümünde göster
    if (!_isSearching) return;
    if (_selectedWord != null) return;
    if (_searchResults.isEmpty) return;
    if (_tapHintOverlay != null) return;

    // Post-frame'de ekle ki Overlay boyutları hazır olsun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          ((!_debugAlwaysShowHint && _hasShownTapHint) ||
              _tapHintOverlay != null))
        return;

      final isDark = widget.isDarkMode;
      _tapHintOverlay = OverlayEntry(
        builder: (context) {
          final double topOffset = MediaQuery.of(context).padding.top + 56;
          return Positioned(
            top: topOffset + 8,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                _removeTapHintOverlay();
              },
              child: Material(
                color: Colors.transparent,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x1A000000), // black @ 0.1
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      LanguageService().isEnglish
                          ? 'Tap on a word to see more details'
                          : (LanguageService().isArabic
                                ? 'انقر على الكلمة لرؤية المزيد من التفاصيل'
                                : 'Kelimeye dokunarak daha fazla detay görebilirsin'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      Overlay.of(context).insert(_tapHintOverlay!);
      _markTapHintShown();
    });
  }

  @override
  void _onQuranModeChanged() {
    if (!mounted) return;
    final newMode = quranModeNotifier.value;
    if (_isQuranMode != newMode) {
      setState(() {
        _isQuranMode = newMode;

        // Kullanıcı talebi: Kuran moduna geçildiğinde limit aşılmışsa inputu temizle
        if (_isQuranMode && _isQuranUsageExceeded) {
          _searchController.clear();
          _lastSearchText = '';
        }

        final cleanText = _searchController.text.trim();

        // Önemli: Mod değiştiğinde eğer kutuda yazı varsa hemen aramayı tetikle
        if (cleanText.isNotEmpty) {
          _performSearch(cleanText);
        } else {
          _isSearching = false;
          _searchResults = [];
          _quranSearchResults = [];
        }

        // Eğer Kuran modu açıldıysa ve ilk defa geliniyorsa tanıtımı göster
        if (_isQuranMode) {
          _checkAndShowQuranOnboarding();
          _startQuranUsageTimer();
        } else {
          _stopQuranUsageTimer();
        }
      });
    }
  }

  void _onDictionaryModeChanged() {
    if (!mounted) return;
    final mode = dictionaryModeNotifier.value;

    // Yalnızca mod gerçekten değiştiyse işlem yap
    if ((_isEmsileMode && mode == DictionaryMode.emsile) ||
        (_isQuranMode && mode == DictionaryMode.kuranSozluk) ||
        (!_isEmsileMode && !_isQuranMode && mode == DictionaryMode.sozluk)) {
      return;
    }

    final cleanText = _searchController.text.trim();
    var shouldSearchAfterModeChange = false;
    var shouldLoadRandomEmsile = false;
    var shouldLoadQuranDictionary = false;

    setState(() {
      _isEmsileMode = mode == DictionaryMode.emsile;
      _isQuranMode = mode == DictionaryMode.kuranSozluk;
      if (!_isQuranMode) {
        _isQuranDictionaryLoading = false;
      }
      quranModeNotifier.value = _isQuranMode;
      _searchGeneration++;

      if (cleanText.isEmpty) {
        _isSearching = false;
        _isLoading = false;
        _isSearchInProgress = false;
        if (_isQuranMode && !_quranService.isLoaded) {
          shouldLoadQuranDictionary = true;
          _isLoading = true;
          _isQuranDictionaryLoading = true;
          _isSearchInProgress = true;
        }
        if (_isEmsileMode) {
          shouldLoadRandomEmsile = true;
        }
      } else if (_isQuranMode) {
        shouldLoadQuranDictionary = !_quranService.isLoaded;
        shouldSearchAfterModeChange = _quranService.isLoaded;
        _isSearching = true;
        _isLoading = !_quranService.isLoaded;
        _isQuranDictionaryLoading = !_quranService.isLoaded;
        _isSearchInProgress = !_quranService.isLoaded;
        _showAIButton = false;
        _showNotFound = false;
        _quranSearchResults = [];
        _selectedQuranWord = null;
      } else {
        // Metin varsa, sekmeler arası geçişte her zaman arama yapılmalı
        if (_isEmsileMode) {
          // Eğer Emsile moduna geçiyorsak ve bu geçiş butondan tetiklendiyse
          // aynı aramayı iki kere yapmamak için notifier'ı kontrol et
          final notifierQuery = emsileSearchNotifier.value.isNotEmpty
              ? emsileSearchNotifier.value.split('|').first
              : '';

          if (notifierQuery != cleanText) {
            shouldSearchAfterModeChange = true;
          }
        } else {
          // Sözlük veya Kuran Sözlüğü moduna Emsile'den geçiş yapıldıysa, doğrudan bu sekmede aynısını ara
          shouldSearchAfterModeChange = true;
        }
      }
    });

    if (shouldLoadQuranDictionary) {
      _ensureQuranDictionaryLoaded(pendingQuery: cleanText);
    } else if (shouldLoadRandomEmsile) {
      _loadRandomEmsile();
    } else if (shouldSearchAfterModeChange) {
      _performSearch(cleanText);
    }
  }

  Future<void> _ensureQuranDictionaryLoaded({String? pendingQuery}) async {
    if (_quranService.isLoaded) return;
    if (mounted) {
      setState(() {
        _isQuranDictionaryLoading = true;
        _isLoading = true;
        _isSearching = pendingQuery != null && pendingQuery.trim().isNotEmpty;
        _isSearchInProgress = true;
        _showNotFound = false;
      });
    }

    await _quranService.initialize();

    if (!mounted || !_isQuranMode) return;
    setState(() {
      _isQuranDictionaryLoading = false;
      _isLoading = false;
      _isSearchInProgress = false;
    });

    final cleanQuery = pendingQuery?.trim() ?? _searchController.text.trim();
    if (cleanQuery.isNotEmpty && cleanQuery == _searchController.text.trim()) {
      _performSearch(cleanQuery);
    }
  }

  bool _emsileHasMore = true;
  bool _emsileIsSearchMode = false;

  Future<void> _loadRandomEmsile() async {
    try {
      // \u0130lk y\u00fckleme zaten initState'te yap\u0131ld\u0131; arama modundan d\u00f6n\u00fcyorsak yeniden y\u00fckle
      if (_emsileSearchResults.isNotEmpty && !_emsileIsSearchMode) return;
      await EmsileDatabaseService.instance.preInit();
      final isPremium =
          _creditsService.isPremium || _creditsService.isLifetimeAdsFree;
      final results = await EmsileDatabaseService.instance.getEmsilePagedAsc(
        offset: 0,
        limit: 200,
        isPremium: isPremium,
        seed: isPremium ? _emsileRandomSeed : null,
      );
      if (mounted) {
        setState(() {
          _emsileSearchResults = results;
          _emsileHasMore = results.length >= 200;
          _emsileIsSearchMode = false;
          _showNotFound = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading emsile: $e');
    }
  }

  Future<void> _loadMoreEmsile() async {
    try {
      final currentCount = _emsileSearchResults.length;
      final isPremium =
          _creditsService.isPremium || _creditsService.isLifetimeAdsFree;
      final results = await EmsileDatabaseService.instance.getEmsilePagedAsc(
        offset: currentCount,
        limit: 200,
        isPremium: isPremium,
        seed: isPremium ? _emsileRandomSeed : null,
      );
      if (mounted) {
        setState(() {
          _emsileSearchResults.addAll(results);
          _emsileHasMore = results.length >= 200;
        });
      }
    } catch (e) {
      debugPrint('Error loading more emsile: $e');
    }
  }

  void _loadQuranUsage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _quranUsageSeconds = prefs.getInt(_quranUsageKey) ?? 0;
    });
    // Eğer zaten Kuran modundaysak ve limit dolmadıysa timer'ı başlat
    if (_isQuranMode && _quranUsageSeconds < _quranTimeLimit) {
      _startQuranUsageTimer();
    }
  }

  void _saveQuranUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quranUsageKey, _quranUsageSeconds);
  }

  void _startQuranUsageTimer() {
    _quranUsageTimer?.cancel();
    // Premium ise süre takibi yapma
    if (_creditsService.isPremium || _creditsService.isLifetimeAdsFree) return;

    // PERFORMANCE: Her saniye setState() yerine sadece sayaçı artır,
    // setState'i sadece limit dolduğunda veya kaydetme zamanında çağır.
    _quranUsageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // PERFORMANCE: setState olmadan sayaçı artır
      _quranUsageSeconds++;

      if (_quranUsageSeconds % 30 == 0) {
        _saveQuranUsage();
      }

      if (_quranUsageSeconds >= _quranTimeLimit) {
        _stopQuranUsageTimer();
        // Limit dolunca UI'ı güncellemek için - sadece bu durumda setState çağrılır
        setState(() {});
      }
    });
  }

  void _stopQuranUsageTimer() {
    _quranUsageTimer?.cancel();
    _quranUsageTimer = null;
    _saveQuranUsage();
  }

  bool get _isQuranUsageExceeded {
    // Kullanıcı talebi: 20 dakika dolunca devam etmek için HEM giriş yapmış olmalı HEM Premium olmalı.
    final bool hasUnlimitedAccess =
        AuthService().isSignedIn &&
        (_creditsService.isPremium || _creditsService.isLifetimeAdsFree);

    if (hasUnlimitedAccess) return false;

    return _quranUsageSeconds >= _quranTimeLimit;
  }

  void _showQuranLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDarkMode = widget.isDarkMode;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.timer_off_rounded,
                size: 48,
                color: Color(0xFF4A5729),
              ),
              const SizedBox(height: 16),
              Text(
                'Kullanım Sınırı Doldu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
            ],
          ),
          content: const Text(
            'Kuran sözlüğünü sınırsız kullanmaya devam etmek için lütfen giriş yapın ve Premium\'a yükseltin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A5729),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndShowQuranOnboarding() async {
    final shouldShow = await QuranOnboarding.shouldShow();
    if (shouldShow && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => QuranOnboarding(isDarkMode: widget.isDarkMode),
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _removeTapHintOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _creditsService.removeListener(_onCreditsChanged);
    _appUsageService.removeListener(_onAppUsageChanged);
    quranModeNotifier.removeListener(_onQuranModeChanged);
    dictionaryModeNotifier.removeListener(_onDictionaryModeChanged);
    emsileSearchNotifier.removeListener(_onEmsileSearchTriggered);
    _searchSubscription?.cancel();
    _debounceTimer?.cancel();
    _tapHintTimer?.cancel();
    _interstitialTimer?.cancel();
    _quranUsageTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Surface yokken çizim hatalarını önlemek için
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _stopQuranUsageTimer();
    } else if (state == AppLifecycleState.resumed) {
      if (_isQuranMode) {
        _startQuranUsageTimer();
      }
    }
  }

  void _loadNativeAd() {
    // AdMob kaldırıldı - no-op
  }

  void _onSearchChanged() {
    final text = _searchController.text;
    final cleanText = text.trim();
    final lastCleanText = _lastSearchText.trim();

    // Eğer temizlenmiş metin değişmediyse (sadece focus değişikliği, boşluk ekleme vs.) işlem yapma
    if (cleanText == lastCleanText) {
      return;
    }

    // Sadece boşluk karakteri varsa arama yapma
    if (cleanText.isEmpty && text.isNotEmpty) {
      return;
    }

    // Son arama metnini güncelle
    _lastSearchText = text;

    // Gizli kod kontrolü - DEBUG
    if (cleanText.toLowerCase() == 'hxpruatksj7v') {
      _handleSecretUnlock();
      return;
    }

    // Gizli kod kontrolü - FORCE RELOAD EMBEDDED DATA
    if (cleanText.toLowerCase() == 'reloaddb') {
      _handleForceReloadDatabase();
      return;
    }

    // Ana sözlükte Türkçe aramalarda ilk 2 harfte aramayı engelle.
    final isArabic = _containsArabic(cleanText);
    final isShortTurkishInMain =
        !_isQuranMode &&
        !_isEmsileMode &&
        !isArabic &&
        cleanText.isNotEmpty &&
        cleanText.length <= 2;

    if (cleanText.isEmpty || isShortTurkishInMain) {
      // Timer varsa iptal et — bir önceki arama gelmeden temizlendi
      _debounceTimer?.cancel();
      setState(() {
        if (_isQuranMode) {
          _quranSearchResults = [];
          _selectedQuranWord = null;
        } else if (_isEmsileMode) {
          _emsileIsSearchMode = false;
          _emsileSearchResults = [];
          _emsileHasMore = true;
          _loadRandomEmsile();
        } else {
          _searchResults = [];
          _selectedWord = null;
        }
        _isSearching = false;
        _isLoading = false; // ← EKLENDİ: yükleme sembolü takılmasın
        _showAIButton = false;
        _showNotFound = false;
        _isSearchInProgress = false;
      });
      return;
    }

    // Önceki timer'ı iptal et (birden fazla aramanın paralel çalışmasını engelle)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 80), () {
      if (mounted) {
        _performSearch(cleanText);
      }
    });
  }

  Future<void> _handleSecretUnlock() async {
    try {
      // Klavyeyi kapat ve inputu temizle
      _searchFocusNode.unfocus();
      _searchController.clear();
      _lastSearchText = ''; // Son arama metnini de sıfırla

      // Tüm kitapları satın alınmış gibi işaretle
      final store = BookStoreService();
      await store.initialize();
      for (final b in BookStoreService.books) {
        await store.mockPurchase(b.id);
      }

      // Reklamları kaldır (hesap gerektirir)
      await _creditsService.activatePremiumForever();

      if (!mounted) return;
      // Kullanıcı giriş yapmadıysa CreditsService no-op olabilir; kullanıcıyı bilgilendir
      final isAdFreeNow =
          _creditsService.isLifetimeAdsFree || _creditsService.isPremium;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAdFreeNow
                ? 'Tüm kitaplar açıldı ve reklamlar kaldırıldı.'
                : 'Tüm kitaplar açıldı. Reklamları kalıcı kaldırmak için lütfen giriş yapın.',
          ),
        ),
      );

      // UI durumlarını sıfırla
      setState(() {
        _searchResults = [];
        _selectedWord = null;
        _isSearching = false;
        _showAIButton = false;
        _showNotFound = false;
        _isSearchInProgress = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gizli kod uygulanamadı: $e')));
    }
  }

  Future<void> _handleForceReloadDatabase() async {
    try {
      // Klavyeyi kapat ve inputu temizle
      _searchFocusNode.unfocus();
      _searchController.clear();
      _lastSearchText = '';

      // Loading göster
      setState(() {
        _searchResults = [];
        _selectedWord = null;
        _isSearching = false;
        _showAIButton = false;
        _showNotFound = false;
        _isSearchInProgress = false;
        _isLoading = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sözlük güncelleniyor... Lütfen bekleyin.'),
          duration: Duration(seconds: 3),
        ),
      );

      // DatabaseInitializationService'i import et
      final dbInitService = DatabaseInitializationService.instance;
      final success = await dbInitService.forceReloadEmbeddedData();

      if (!mounted) return;

      if (success) {
        // Database bilgilerini al
        final info = await dbInitService.getDatabaseInfo();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sözlük başarıyla güncellendi! ${info['wordCount']} kelime yüklendi.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sözlük güncellenirken hata oluştu!'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Loading'i kapat
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Database reload hatası: $e')));
    }
  }

  Future<void> _performSearch(String query) async {
    // Query'yi temizle - başındaki ve sonundaki boşlukları kaldır
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    final searchGeneration = ++_searchGeneration;
    final searchMode = dictionaryModeNotifier.value;

    // Ana sözlükte Türkçe aramalarda ilk 2 harfte aramayı engelle.
    final isArabic = _containsArabic(cleanQuery);
    final isShortTurkishInMain =
        !_isQuranMode && !_isEmsileMode && !isArabic && cleanQuery.length <= 2;

    if (isShortTurkishInMain) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _isLoading = false;
          _showAIButton = false;
          _showNotFound = false;
          _isSearchInProgress = false;
        });
      }
      return;
    }

    // Kuran sözlüğü limit kontrolü
    if (_isQuranMode && _isQuranUsageExceeded) {
      _showQuranLimitDialog();
      return;
    }

    // Arama başlarken yükleme state'ini sadece Kuran sözlüğü ilk kez yükleniyorsa göster
    // Diğer durumlarda eski sonuçları koruyarak flicker önle
    final bool needsDictionaryLoad = _isQuranMode && !_quranService.isLoaded;
    if (needsDictionaryLoad) {
      setState(() {
        _isSearchInProgress = true;
        _isSearching = true;
        _isQuranDictionaryLoading = true;
        _isLoading = true;
        _showAIButton = false;
        _showNotFound = false;
      });
    } else {
      // Sadece progress flag'lerini güncelle, eski sonuçları KORUYARAK göster
      _isSearchInProgress = true;
      _isSearching = true;
      _showNotFound = false;
    }

    try {
      if (_isQuranMode) {
        final quranResults = await _quranService.searchWords(cleanQuery);

        if (mounted) {
          final currentText = _searchController.text.trim();
          if (currentText != cleanQuery ||
              searchGeneration != _searchGeneration ||
              searchMode != dictionaryModeNotifier.value) {
            return;
          }
          // Tek bir setState ile hem sonucu hem state'i güncelle
          setState(() {
            _quranSearchResults = quranResults;
            _isLoading = false;
            _isQuranDictionaryLoading = false;
            _isSearchInProgress = false;
            _showAIButton = false;
            _showNotFound = quranResults.isEmpty;
          });
        }
      } else if (_isEmsileMode) {
        final emsileResults = await EmsileDatabaseService.instance.searchEmsile(
          cleanQuery,
        );

        if (mounted) {
          final currentText = _searchController.text.trim();
          if (currentText != cleanQuery ||
              searchGeneration != _searchGeneration ||
              searchMode != dictionaryModeNotifier.value) {
            return;
          }
          setState(() {
            _emsileSearchResults = emsileResults;
            _emsileIsSearchMode = true;
            _emsileHasMore = false;
            _isLoading = false;
            _isSearchInProgress = false;
            _showAIButton = false;
            _showNotFound = emsileResults.isEmpty;
          });
        }
      } else {
        final results = await _dbService.searchWords(cleanQuery);

        if (mounted) {
          final currentText = _searchController.text.trim();
          if (currentText != cleanQuery ||
              searchGeneration != _searchGeneration ||
              searchMode != dictionaryModeNotifier.value) {
            return;
          }
          setState(() {
            _searchResults = results;
            _isLoading = false;
            _isSearchInProgress = false;
            _showAIButton = true;
            _showNotFound = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final currentText = _searchController.text.trim();
        if (currentText != cleanQuery ||
            searchGeneration != _searchGeneration ||
            searchMode != dictionaryModeNotifier.value) {
          return;
        }

        setState(() {
          if (_isQuranMode) {
            _quranSearchResults = [];
          } else if (_isEmsileMode) {
            _emsileSearchResults = [];
          } else {
            _searchResults = [];
          }
          _isLoading = false;
          _isQuranDictionaryLoading = false;
          _showAIButton = !_isQuranMode;
          _showNotFound = false;
          _isSearchInProgress = false;
        });
      }
    }
  }

  void _selectWord(WordModel word) {
    // Arapça klavye açıksa kapat
    if (_showArabicKeyboard) {
      setState(() {
        _showArabicKeyboard = false;
      });
      widget.onArabicKeyboardStateChanged?.call(false);
    }
    // İpucu overlay açıksa kapat
    _removeTapHintOverlay();

    // Analytics event'leri gönder (arka planda çalışsın, UI'ı bloklamasın)
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      // Arama analytics'i sadece kelime seçildiğinde gönder (performans için)
      TurkceAnalyticsService.kelimeArandiNormal(
        searchQuery,
        _searchResults.length,
      );
    }
    TurkceAnalyticsService.kelimeDetayiGoruntulendi(word.kelime);

    // Artık hak kontrolü yok, direkt kelimeyi göster
    setState(() {
      _selectedWord = word;
      _searchResults = [];
      _isSearching = false;
      _showAIButton = false;
      _showNotFound = false;
      _searchController.text = word.kelime;
      _lastSearchText = word.kelime; // Son arama metnini güncelle
    });
    _searchFocusNode.unfocus();
  }

  Future<void> _searchWithAI() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // İnternet kontrolü: Offline ise tetikleme ve diyalog göster
    final hasConnection = await _connectivityService.hasInternetConnection();
    if (!hasConnection) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          final isDarkMode = widget.isDarkMode;
          return AlertDialog(
            backgroundColor: isDarkMode
                ? const Color(0xFF2C2C2E)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: isDarkMode
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF007AFF),
                ),
                const SizedBox(height: 12),
                Text(
                  'İnternet Gerekli',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: const Text(
              'arama yapmak için internete bağlanın',
              style: TextStyle(fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF007AFF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
      return; // Tetikleme
    }

    // Arama işlemini arka planda hazırla
    final searchFuture = _performActualAISearch(query, showLoading: false);

    // AdMob servisine bir arama isteği olduğunu bildir.
    // Kararı servis verecek.
    await _adMobService.onSearchAdRequest(
      onAdDismissed: () async {
        // Bu blok, reklam gösterilsin veya gösterilmesin her zaman çalışır.
        setState(() => _isLoading = true);
        await searchFuture;
        setState(() => _isLoading = false);
      },
    );
  }

  Future<void> _performActualAISearch(
    String query, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _selectedWord = null;
        _searchResults = [];
        _showAIButton = false;
        _showNotFound = false;
      });
    }

    try {
      // Yerel veritabanı kontrolü kaldırıldı - direkt AI'ya git
      // İnternet kontrolü: AI araması için internet gerekir
      final hasConnection = await _connectivityService.hasInternetConnection();
      if (!hasConnection) {
        if (mounted) {
          // Dialog uyarısı
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (ctx) {
              final isDarkMode = widget.isDarkMode;
              return AlertDialog(
                backgroundColor: isDarkMode
                    ? const Color(0xFF2C2C2E)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Column(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: isDarkMode
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF007AFF),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'İnternet Gerekli',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF1C1C1E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                content: const Text(
                  'arama yapmak için internete bağlanın',
                  style: TextStyle(fontSize: 14, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            },
          );
          setState(() {
            _isLoading = false;
            _showAIButton = true;
            _showNotFound = false;
          });
        }
        return;
      }

      final aiResult = await _geminiService.searchWord(query);

      // AI arama analytics event'i gönder
      await TurkceAnalyticsService.kelimeArandiAI(query, aiResult.bulunduMu);

      if (aiResult.bulunduMu) {
        // Eğer kelime yeni ise SyncService'e gönder
        // GeminiService zaten duplikasyon kontrolü yaptı ve gerekirse pending tablosuna ekledi
        // Bu yüzden burada tekrar handleAiFoundWord çağırmaya gerek yok

        // Sadece AI sonucunu göster

        setState(() {
          _searchResults = [aiResult]; // Sadece AI sonucu
          _isLoading = false;
          _isSearching = true;
          _showNotFound = false;
          _prewarmPending = true; // İlk kez kartı ısıt
        });
      } else {
        // AI sonucu bulunamadı
        setState(() {
          _isLoading = false;
          _showAIButton = true;
          _showNotFound = true; // AI sonucu yoksa "bulunamadı" göster
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showAIButton = true;
        _showNotFound = true;
      });
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _dismissKeyboard() {
    // Normal klavye açıksa kapat
    if (_searchFocusNode.hasFocus && !_showArabicKeyboard) {
      _searchFocusNode.unfocus();
    }
    // Arapça klavye açıksa kapat
    if (_showArabicKeyboard) {
      setState(() {
        _showArabicKeyboard = false;
      });
      widget.onArabicKeyboardStateChanged?.call(false);
    }
  }

  // Scroll başladığında tüm klavyeleri kapat (normal + Arapça)
  void _dismissForScroll() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
    if (_showArabicKeyboard) {
      setState(() {
        _showArabicKeyboard = false;
      });
      widget.onArabicKeyboardStateChanged?.call(false);
    }
  }

  void _onScrollStart() {
    if (_scrollDebounce) return;
    _scrollDebounce = true;
    _dismissForScroll();
    Future.delayed(const Duration(milliseconds: 120), () {
      _scrollDebounce = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli

    // Klavye durumunu kontrol et
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final hasKeyboard = keyboardHeight > 0;
    // Sözlük görünümü dışında overlay kalmışsa kaldır (başka sekmeye geçildiğinde vs.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Sözlük sekmesi aktif değilse veya uygun koşullar yoksa overlay'i kaldır
      final bool isInDictionaryView =
          _isSearching && _selectedWord == null && _searchResults.isNotEmpty;
      if ((!isInDictionaryView || !widget.isActive) &&
          _tapHintOverlay != null) {
        _removeTapHintOverlay();
      }
    });

    return PopScope(
      canPop: !_showArabicKeyboard, // Arapça klavye açıkken çıkışı engelle
      onPopInvoked: (didPop) {
        if (_showArabicKeyboard && !didPop) {
          // Arapça klavye açıkken geri tuşuna basıldığında klavyeyi kapat
          setState(() {
            _showArabicKeyboard = false;
          });
          widget.onArabicKeyboardStateChanged?.call(false);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: _isEmsileMode
            ? (widget.isDarkMode
                  ? const Color(0xFF141926)
                  : const Color(0xFFE8EDF8))
            : _isQuranMode
            ? (widget.isDarkMode
                  ? const Color(0xFF151C12)
                  : const Color(0xFFF9FBF7))
            : (widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white),
        body: Stack(
          children: [
            // Kuran Modu Arka Plan Degrade (Göz yormayan hafif tasarım)
            if (_isQuranMode)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: widget.isDarkMode
                          ? [
                              const Color(0xFF1E2E15), // Koyu yeşil
                              const Color(0xFF151C12), // Çok koyu zeytin
                            ]
                          : [
                              const Color(
                                0xFFF1F4ED,
                              ), // Çok daha hafif yeşilimsi başlangıç
                              const Color(
                                0xFFF9FBF7,
                              ), // Beyaza çok yakın hafif krem bitiş
                            ],
                    ),
                  ),
                ),
              ),
            // Normal Sözlük Modu Arka Plan Degrade
            if (!_isQuranMode)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: widget.isDarkMode
                          ? [
                              const Color(
                                0xFF0A141F,
                              ), // Üstte derin mavi/lacivert
                              const Color(0xFF1C1C1E), // Altta ana koyu renk
                            ]
                          : [
                              const Color(0xFFD6E9FF), // Üstte belirgin mavi
                              const Color(
                                0xFFEBF4FF,
                              ), // Altta daha hafif bir mavi (beyaz değil)
                            ],
                    ),
                  ),
                ),
              ),
            // Ana içerik
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _dismissKeyboard,
                onVerticalDragStart: (_) {
                  // Scroll hareketi başlarken de (liste kısa olsa bile) klavyeleri kapat
                  if (_showArabicKeyboard || _searchFocusNode.hasFocus) {
                    _dismissForScroll();
                  }
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      _onScrollStart();
                    }
                    return false;
                  },
                  child: RepaintBoundary(
                    child: CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      cacheExtent:
                          (_isSearching &&
                              !_isQuranMode &&
                              _searchResults.isNotEmpty)
                          ? 80.0
                          : hasKeyboard
                          ? 220.0
                          : PerformanceUtils.listCacheExtent,
                      key: const PageStorageKey<String>('home_scroll'),
                      slivers: <Widget>[
                        SliverAppBar(
                          backgroundColor: _isEmsileMode
                              ? (widget.isDarkMode
                                    ? const Color(0xFF1C1C1E)
                                    : const Color(0xFF384D75))
                              : _isQuranMode
                              ? const Color(0xFF2D4720)
                              : (widget.isDarkMode
                                    ? const Color(0xFF1C1C1E)
                                    : const Color(0xFF007AFF)),
                          elevation: 0,
                          pinned: true,
                          floating: true,
                          snap: true,
                          toolbarHeight: 0,
                          expandedHeight: 0,
                          bottom: PreferredSize(
                            preferredSize: Size.fromHeight(
                              (LanguageService().isEnglish ||
                                      LanguageService().isArabic)
                                  ? 58
                                  : 108,
                            ),
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: double.infinity,
                                color: _isEmsileMode
                                    ? (widget.isDarkMode
                                          ? const Color(0xFF1C1C1E)
                                          : const Color(0xFF384D75))
                                    : _isQuranMode
                                    ? const Color(0xFF2D4720)
                                    : (widget.isDarkMode
                                          ? const Color(0xFF1C1C1E)
                                          : const Color(0xFF007AFF)),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    8,
                                    8,
                                    8,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        textDirection:
                                            LanguageService().isArabic
                                            ? TextDirection.rtl
                                            : TextDirection.ltr,
                                        children: [
                                          // Kelime Listelerim Butonu
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                // Giriş kontrolü
                                                final auth = AuthService();
                                                if (!auth.isSignedIn) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        LanguageService()
                                                                .isEnglish
                                                            ? 'Please log in or sign up first'
                                                            : (LanguageService()
                                                                      .isArabic
                                                                  ? 'يرجى تسجيل الدخول أو الاشتراك أولاً'
                                                                  : 'Lütfen önce kayıt olun, giriş yapın.'),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          Colors.black87,
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .fixed,
                                                    ),
                                                  );
                                                  return;
                                                }
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        CustomWordsScreen(
                                                          isDarkMode:
                                                              widget.isDarkMode,
                                                        ),
                                                  ),
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: widget.isDarkMode
                                                      ? const Color(0xFF2C2C2E)
                                                      : const Color(0xFFE5E5EA),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.bookmark_rounded,
                                                  color: _isEmsileMode
                                                      ? const Color(0xFF384D75)
                                                      : _isQuranMode
                                                      ? const Color(0xFF4A5729)
                                                      : const Color(0xFF007AFF),
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Ana arama alanı
                                          Expanded(
                                            child: Container(
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: widget.isDarkMode
                                                    ? const Color(0xFF2C2C2E)
                                                    : const Color(0xFFE5E5EA),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.transparent,
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  // Büyüteç (Arama) İkonu - En solda
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 4,
                                                          right: 0,
                                                        ),
                                                    child: GestureDetector(
                                                      onLongPress: () {
                                                        Navigator.of(
                                                          context,
                                                        ).push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                const LogScreen(),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        width: 36,
                                                        height: 36,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Icon(
                                                          Icons.search_rounded,
                                                          color:
                                                              widget.isDarkMode
                                                              ? const Color(
                                                                  0xFF8E8E93,
                                                                )
                                                              : const Color(
                                                                  0xFF8E8E93,
                                                                ),
                                                          size: 22,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Arapça dil modunda Klavye Butonu (solda gösteriliyor)
                                                  if (LanguageService()
                                                      .isArabic) ...[
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 4,
                                                            right: 0,
                                                          ),
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          onTap: () {
                                                            // Kuran modunda limit aşılmışsa girişi engelle
                                                            if (_isQuranMode &&
                                                                _isQuranUsageExceeded) {
                                                              return;
                                                            }
                                                            setState(() {
                                                              _showArabicKeyboard =
                                                                  !_showArabicKeyboard;
                                                              if (_showArabicKeyboard) {
                                                                _searchFocusNode
                                                                    .unfocus();
                                                                TurkceAnalyticsService.arapcaKlavyeKullanildi();
                                                              }
                                                            });
                                                            widget
                                                                .onArabicKeyboardStateChanged
                                                                ?.call(
                                                                  _showArabicKeyboard,
                                                                );
                                                          },
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          child: Container(
                                                            width: 36,
                                                            height: 36,
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  (_isQuranMode &&
                                                                      _isQuranUsageExceeded)
                                                                  ? (widget.isDarkMode
                                                                        ? Colors
                                                                              .white10
                                                                        : Colors
                                                                              .black12)
                                                                  : (_showArabicKeyboard
                                                                        ? (_isQuranMode
                                                                              ? const Color(
                                                                                  0xFF4A5729,
                                                                                )
                                                                              : const Color(
                                                                                  0xFF007AFF,
                                                                                ))
                                                                        : (widget.isDarkMode
                                                                              ? const Color(
                                                                                  0x803A3A3C,
                                                                                ) // 0.5 opacity
                                                                              : const Color(0x80E5E5EA))), // 0.5 opacity
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .keyboard_alt_outlined,
                                                              color:
                                                                  (_isQuranMode &&
                                                                      _isQuranUsageExceeded)
                                                                  ? (widget.isDarkMode
                                                                        ? Colors
                                                                              .white24
                                                                        : Colors
                                                                              .black26)
                                                                  : (_showArabicKeyboard
                                                                        ? Colors
                                                                              .white
                                                                        : (widget.isDarkMode
                                                                              ? const Color(
                                                                                  0xFF8E8E93,
                                                                                )
                                                                              : const Color(0xFF636366))),
                                                              size: 22,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                  Expanded(
                                                    child: GestureDetector(
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      onTap: () {
                                                        // Kuran modunda limit aşılmışsa girişi engelle
                                                        if (_isQuranMode &&
                                                            _isQuranUsageExceeded) {
                                                          return;
                                                        }
                                                        // Tıklama boşluğa gelse bile focus ver
                                                        if (!_searchFocusNode
                                                            .hasFocus) {
                                                          _searchFocusNode
                                                              .requestFocus();
                                                        }
                                                      },
                                                      child: Container(
                                                        alignment:
                                                            Alignment.center,
                                                        child: TextField(
                                                          controller:
                                                              _searchController,
                                                          focusNode:
                                                              _searchFocusNode,
                                                          enabled:
                                                              !(_isQuranMode &&
                                                                  _isQuranUsageExceeded),
                                                          autofocus: false,
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .center,
                                                          textDirection:
                                                              (LanguageService()
                                                                      .isArabic ||
                                                                  _containsArabic(
                                                                    _searchController
                                                                        .text,
                                                                  ))
                                                              ? TextDirection
                                                                    .rtl
                                                              : TextDirection
                                                                    .ltr,
                                                          textAlign:
                                                              (LanguageService()
                                                                      .isArabic ||
                                                                  _containsArabic(
                                                                    _searchController
                                                                        .text,
                                                                  ))
                                                              ? TextAlign.right
                                                              : TextAlign.left,
                                                          keyboardType:
                                                              TextInputType
                                                                  .text,
                                                          keyboardAppearance:
                                                              widget.isDarkMode
                                                              ? Brightness.dark
                                                              : Brightness
                                                                    .light,
                                                          cursorColor:
                                                              _isEmsileMode
                                                              ? const Color(
                                                                  0xFF384D75,
                                                                )
                                                              : _isQuranMode
                                                              ? const Color(
                                                                  0xFF8BC34A,
                                                                )
                                                              : const Color(
                                                                  0xFF007AFF,
                                                                ),
                                                          showCursor: true,
                                                          enableInteractiveSelection:
                                                              true,
                                                          enableIMEPersonalizedLearning:
                                                              true,
                                                          autofillHints: null,
                                                          style: TextStyle(
                                                            fontSize:
                                                                _containsArabic(
                                                                  _searchController
                                                                      .text,
                                                                )
                                                                ? 19
                                                                : 15,
                                                            height: 1.15,
                                                            letterSpacing: 0.0,
                                                            color:
                                                                widget
                                                                    .isDarkMode
                                                                ? Colors.white
                                                                : const Color(
                                                                    0xFF1C1C1E,
                                                                  ),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            decoration:
                                                                TextDecoration
                                                                    .none,
                                                          ),
                                                          decoration: InputDecoration(
                                                            hintText:
                                                                LanguageService()
                                                                    .isEnglish
                                                                ? 'Search Word'
                                                                : (LanguageService()
                                                                          .isArabic
                                                                      ? 'ابحث عن كلمة'
                                                                      : 'Kelime ara'),
                                                            hintStyle: TextStyle(
                                                              color:
                                                                  widget
                                                                      .isDarkMode
                                                                  ? const Color(
                                                                      0xCC8E8E93,
                                                                    ) // 0.8 opacity
                                                                  : const Color(
                                                                      0xFF8E8E93,
                                                                    ),
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                            border: InputBorder
                                                                .none,
                                                            enabledBorder:
                                                                InputBorder
                                                                    .none,
                                                            focusedBorder:
                                                                InputBorder
                                                                    .none,
                                                            isDense: true,
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                            fillColor: Colors
                                                                .transparent, // Beyazlık hatasını engellemek için
                                                            filled: false,
                                                          ),
                                                          textInputAction:
                                                              TextInputAction
                                                                  .search,
                                                          onSubmitted: (_) {
                                                            // Sadece klavyeyi kapat, normal arama zaten debouncer ile yapılıyor
                                                            _dismissKeyboard();
                                                          },
                                                          readOnly:
                                                              _showArabicKeyboard,
                                                          onTap: () {
                                                            // Arapça klavye açıkken inputa dokununca kapatma (Kullanıcı talebi)
                                                            if (_showArabicKeyboard) {
                                                              // Sadece focus'u yönet, klavyeyi kapatma
                                                              return;
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Mikrofon Butonu (Sesli Arama) - Klavye ikonunun solunda
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 0,
                                                        ),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () {
                                                          if (_isQuranMode &&
                                                              _isQuranUsageExceeded)
                                                            return;

                                                          if (_isListening) {
                                                            _stopListening();
                                                          } else {
                                                            _startListening();
                                                          }
                                                        },
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        child: Container(
                                                          width: 36,
                                                          height: 36,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                (_isQuranMode &&
                                                                    _isQuranUsageExceeded)
                                                                ? (widget.isDarkMode
                                                                      ? Colors
                                                                            .white10
                                                                      : Colors
                                                                            .black12)
                                                                : (_isListening
                                                                      ? Colors
                                                                            .red
                                                                      : (widget.isDarkMode
                                                                            ? const Color(
                                                                                0x803A3A3C,
                                                                              ) // 0.5 opacity
                                                                            : const Color(
                                                                                0x80E5E5EA,
                                                                              ))), // 0.5 opacity
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            _isListening
                                                                ? Icons.mic
                                                                : Icons
                                                                      .mic_none_outlined,
                                                            color:
                                                                (_isQuranMode &&
                                                                    _isQuranUsageExceeded)
                                                                ? (widget.isDarkMode
                                                                      ? Colors
                                                                            .white24
                                                                      : Colors
                                                                            .black26)
                                                                : (_isListening
                                                                      ? Colors
                                                                            .white
                                                                      : (widget.isDarkMode
                                                                            ? const Color(
                                                                                0xFF8E8E93,
                                                                              )
                                                                            : const Color(
                                                                                0xFF636366,
                                                                              ))),
                                                            size: 22,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Arapça Klavye Butonu - Arapça dil dışında sağda gösteriliyor
                                                  if (!LanguageService()
                                                      .isArabic)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 4,
                                                          ),
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          onTap: () {
                                                            // Kuran modunda limit aşılmışsa girişi engelle
                                                            if (_isQuranMode &&
                                                                _isQuranUsageExceeded) {
                                                              return;
                                                            }
                                                            setState(() {
                                                              _showArabicKeyboard =
                                                                  !_showArabicKeyboard;
                                                              if (_showArabicKeyboard) {
                                                                _searchFocusNode
                                                                    .unfocus();
                                                                TurkceAnalyticsService.arapcaKlavyeKullanildi();
                                                              }
                                                            });
                                                            widget
                                                                .onArabicKeyboardStateChanged
                                                                ?.call(
                                                                  _showArabicKeyboard,
                                                                );
                                                          },
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          child: Container(
                                                            width: 36,
                                                            height: 36,
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  (_isQuranMode &&
                                                                      _isQuranUsageExceeded)
                                                                  ? (widget.isDarkMode
                                                                        ? Colors
                                                                              .white10
                                                                        : Colors
                                                                              .black12)
                                                                  : (_showArabicKeyboard
                                                                        ? (_isQuranMode
                                                                              ? const Color(
                                                                                  0xFF4A5729,
                                                                                )
                                                                              : const Color(
                                                                                  0xFF007AFF,
                                                                                ))
                                                                        : (widget.isDarkMode
                                                                              ? const Color(
                                                                                  0x803A3A3C,
                                                                                ) // 0.5 opacity
                                                                              : const Color(0x80E5E5EA))), // 0.5 opacity
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .keyboard_alt_outlined,
                                                              color:
                                                                  (_isQuranMode &&
                                                                      _isQuranUsageExceeded)
                                                                  ? (widget.isDarkMode
                                                                        ? Colors
                                                                              .white24
                                                                        : Colors
                                                                              .black26)
                                                                  : (_showArabicKeyboard
                                                                        ? Colors
                                                                              .white
                                                                        : (widget.isDarkMode
                                                                              ? const Color(
                                                                                  0xFF8E8E93,
                                                                                )
                                                                              : const Color(0xFF636366))),
                                                              size: 22,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (_searchController
                                                      .text
                                                      .isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 6,
                                                          ),
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          onTap: () {
                                                            _searchController
                                                                .clear();
                                                            _lastSearchText =
                                                                '';
                                                            setState(() {
                                                              _searchResults =
                                                                  [];
                                                              _quranSearchResults =
                                                                  [];
                                                              _selectedWord =
                                                                  null;
                                                              _selectedQuranWord =
                                                                  null;
                                                              _isSearching =
                                                                  false;
                                                              _showAIButton =
                                                                  false;
                                                              _showNotFound =
                                                                  false;
                                                            });
                                                          },
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                          child: Container(
                                                            width: 28,
                                                            height: 28,
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  widget
                                                                      .isDarkMode
                                                                  ? const Color(
                                                                      0x14FFFFFF,
                                                                    ) // white @ 0.08
                                                                  : const Color(
                                                                      0x148E8E93,
                                                                    ), // grey @ 0.08
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Icon(
                                                              Icons.clear,
                                                              color:
                                                                  widget
                                                                      .isDarkMode
                                                                  ? const Color(
                                                                      0xCC8E8E93,
                                                                    ) // 0.8 opacity
                                                                  : const Color(
                                                                      0xFF8E8E93,
                                                                    ),
                                                              size: 14,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!LanguageService().isEnglish &&
                                          !LanguageService().isArabic)
                                        const SizedBox(height: 10),
                                      // Genişletilmiş Segmented Control - Sözlük / Kuran / Emsile Geçişi (KAYMA ANİMASYONLU)
                                      if (!LanguageService().isEnglish &&
                                          !LanguageService().isArabic)
                                        Container(
                                          height: 40,
                                          padding: const EdgeInsets.all(3),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.isDarkMode
                                                ? const Color(0xFF1C1C1E)
                                                : const Color(0xFFEBEBEB),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: widget.isDarkMode
                                                ? Border.all(
                                                    color: const Color(
                                                      0xFF38383A,
                                                    ),
                                                    width: 1,
                                                  )
                                                : null,
                                          ),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final double tabWidth =
                                                  constraints.maxWidth / 3;
                                              // Sıra: Emsile(0) Sözlük(1) Kuran(2)
                                              final int selectedIdx =
                                                  _isEmsileMode
                                                  ? 0
                                                  : (_isQuranMode ? 2 : 1);

                                              Color activeColor;
                                              if (_isEmsileMode) {
                                                activeColor = widget.isDarkMode
                                                    ? const Color(0xFF1E3562)
                                                    : const Color(0xFF384D75);
                                              } else if (_isQuranMode) {
                                                activeColor = widget.isDarkMode
                                                    ? const Color(0xFF2C3E18)
                                                    : const Color(0xFF4A5729);
                                              } else {
                                                activeColor = widget.isDarkMode
                                                    ? const Color(
                                                        0xFF007AFF,
                                                      ).withOpacity(0.8)
                                                    : const Color(0xFF007AFF);
                                              }

                                              return Stack(
                                                children: [
                                                  // Kayan arka plan göstergesi
                                                  AnimatedPositioned(
                                                    duration: const Duration(
                                                      milliseconds: 250,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    left:
                                                        selectedIdx * tabWidth,
                                                    top: 0,
                                                    bottom: 0,
                                                    width: tabWidth,
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 250,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: activeColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              9,
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: activeColor
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  1,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  // Tab butonları
                                                  Row(
                                                    children: [
                                                      // Emsile tab
                                                      Expanded(
                                                        child: GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap: () {
                                                            if (dictionaryModeNotifier
                                                                    .value !=
                                                                DictionaryMode
                                                                    .emsile) {
                                                              dictionaryModeNotifier
                                                                      .value =
                                                                  DictionaryMode
                                                                      .emsile;
                                                            }
                                                          },
                                                          child: Center(
                                                            child: AnimatedDefaultTextStyle(
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        200,
                                                                  ),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontFamily:
                                                                    GoogleFonts.inter()
                                                                        .fontFamily,
                                                                fontWeight:
                                                                    _isEmsileMode
                                                                    ? FontWeight
                                                                          .w600
                                                                    : FontWeight
                                                                          .w500,
                                                                color:
                                                                    _isEmsileMode
                                                                    ? Colors
                                                                          .white
                                                                    : const Color(
                                                                        0xFF8E8E93,
                                                                      ),
                                                              ),
                                                              child: const Text(
                                                                'Emsile',
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      // Sözlük tab
                                                      Expanded(
                                                        child: GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap: () {
                                                            if (dictionaryModeNotifier
                                                                    .value !=
                                                                DictionaryMode
                                                                    .sozluk) {
                                                              dictionaryModeNotifier
                                                                      .value =
                                                                  DictionaryMode
                                                                      .sozluk;
                                                            }
                                                          },
                                                          child: Center(
                                                            child: AnimatedDefaultTextStyle(
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        200,
                                                                  ),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontFamily:
                                                                    GoogleFonts.inter()
                                                                        .fontFamily,
                                                                fontWeight:
                                                                    (!_isQuranMode &&
                                                                        !_isEmsileMode)
                                                                    ? FontWeight
                                                                          .w600
                                                                    : FontWeight
                                                                          .w500,
                                                                color:
                                                                    (!_isQuranMode &&
                                                                        !_isEmsileMode)
                                                                    ? Colors
                                                                          .white
                                                                    : const Color(
                                                                        0xFF8E8E93,
                                                                      ),
                                                              ),
                                                              child: const Text(
                                                                'Sözlük',
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      // Kuran Sözlüğü tab
                                                      Expanded(
                                                        child: GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap: () {
                                                            if (dictionaryModeNotifier
                                                                    .value !=
                                                                DictionaryMode
                                                                    .kuranSozluk) {
                                                              dictionaryModeNotifier
                                                                      .value =
                                                                  DictionaryMode
                                                                      .kuranSozluk;
                                                            }
                                                          },
                                                          child: Center(
                                                            child: AnimatedDefaultTextStyle(
                                                              duration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        200,
                                                                  ),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontFamily:
                                                                    GoogleFonts.inter()
                                                                        .fontFamily,
                                                                fontWeight:
                                                                    (_isQuranMode &&
                                                                        !_isEmsileMode)
                                                                    ? FontWeight
                                                                          .w600
                                                                    : FontWeight
                                                                          .w500,
                                                                color:
                                                                    (_isQuranMode &&
                                                                        !_isEmsileMode)
                                                                    ? Colors
                                                                          .white
                                                                    : const Color(
                                                                        0xFF8E8E93,
                                                                      ),
                                                              ),
                                                              child: const Text(
                                                                'Kuran Sözlüğü',
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ..._buildMainContentSlivers(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Değerlendirme butonu - kelime kartlarının üstünde katman olarak
            if (_showLegacyFloatingReviewButton &&
                (_appUsageService.shouldShowRating && _hasInternet ||
                    kDebugMode))
              Positioned(
                top: 60, // Yukarı kaydırıldı
                right: 6, // Daha sağa kaydırıldı
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      // Google Play değerlendirme aç
                      await _reviewService.requestReview();
                      // Butonu kalıcı olarak kaldır
                      if (mounted) {
                        setState(() {
                          // hasRated true olduğu için buton bir daha gösterilmez
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD700), // Altın
                            Color(0xFFFFA500), // Turuncu
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 24, // Yıldız büyütüldü
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            // Arapça klavye
            if (_showArabicKeyboard)
              Positioned(
                bottom: 0, // Ekranın en altından başla
                left: 0,
                right: 0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Arapça klavye açıkken banner yukarıda olduğu için
                    // sadece nav bar + system nav bar kadar padding yeterli
                    // widget.bottomPadding banner yüksekliğini de içeriyor, onu çıkar
                    const navBarHeight = 56.0;
                    const navBarBottomGap = 18.0;
                    final systemNavBarHeight = MediaQuery.of(
                      context,
                    ).viewPadding.bottom;
                    final keyboardPadding =
                        navBarHeight + navBarBottomGap + systemNavBarHeight;

                    return Container(
                      color: widget.isDarkMode
                          ? const Color(0xFF1C1C1E)
                          : const Color(0xFFF5F7FB), // Arka plan rengi
                      padding: EdgeInsets.only(
                        bottom: keyboardPadding,
                      ), // Navigation bar üstünde
                      child: SizedBox(
                        height: 280,
                        child: ArabicKeyboard(
                          controller: _searchController,
                          onSearch: _searchWithAI,
                          onClose: () {
                            setState(() {
                              _showArabicKeyboard = false;
                            });
                            // Main ekrana klavye durumunu bildir
                            widget.onArabicKeyboardStateChanged?.call(false);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Warm-up Widget (Performans için görünmez kart)
            // İlk açılışta shader compilation jank'ı önler
            if (_prewarmPending &&
                !_isSearching &&
                !_isLoading &&
                _searchController.text.trim().isEmpty)
              Positioned(
                left: 0,
                top: 0,
                child: Offstage(
                  offstage: true,
                  child: SizedBox(
                    width: 300,
                    height: 200,
                    child: WordCard(
                      key: const ValueKey('warmup_card'),
                      word: WordModel(
                        kelime: 'warmup',
                        anlam: 'warmup',
                        koku: 'warm',
                        harekeliKelime: 'warmup',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewPromptCard() {
    final isDarkMode = widget.isDarkMode;
    final backgroundColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor = isDarkMode
        ? const Color(0xFF48484A)
        : const Color(0xFFD0D0D0);
    final primaryText = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final secondaryText = isDarkMode
        ? const Color(0xFFB0B0B5)
        : const Color(0xFF6D6D70);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _openReviewPrompt,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 0.8),
              boxShadow: (isDarkMode || !PerformanceUtils.enableShadows)
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF007AFF,
                    ).withOpacity(isDarkMode ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFF007AFF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Uygulamayı değerlendirin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Uygulamanın gelişmesine yardımcı olun',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                          height: 1.25,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Değerlendir',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMainContentSlivers() {
    List<Widget> slivers = [];

    // Emsile modu - arama yerine doğrudan emsile içeriğini göster
    if (_isEmsileMode) {
      slivers.add(
        EmsileView(
          isDarkMode: widget.isDarkMode,
          bottomPadding: widget.bottomPadding,
          verbs: _emsileSearchResults,
          isPremium: _creditsService.isPremium,
          hasMore: _emsileHasMore,
          isSearchMode: _emsileIsSearchMode,
          onLoadMore: _loadMoreEmsile,
          onPremiumTap: () {
            // Premium sayfasına yönlendir
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionScreen(),
              ),
            );
          },
          onLoadFreeTap: () {
            // Arama kutusunu temizle ve ücretsiz rastgele listeye dön
            _searchController.clear();
            _lastSearchText = '';
            setState(() {
              _emsileIsSearchMode = false;
              _isSearching = false;
            });
            _loadRandomEmsile();
          },
        ),
      );
      return slivers;
    }

    final hasNoResults = _searchResults.isEmpty &&
        _quranSearchResults.isEmpty &&
        (!_isEmsileMode || _emsileSearchResults.isEmpty);

    if (_isLoading && (_isQuranDictionaryLoading || hasNoResults)) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 180),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isQuranMode
                          ? const Color(0xFF8BC34A)
                          : const Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isQuranDictionaryLoading
                        ? (LanguageService().isEnglish
                              ? 'Loading Quran dictionary...'
                              : (LanguageService().isArabic
                                    ? 'جاري تحميل قاموس القرآن...'
                                    : 'Kuran sözlüğü yükleniyor...'))
                        : _isQuranMode
                        ? (LanguageService().isEnglish
                              ? 'Searching Quran dictionary...'
                              : (LanguageService().isArabic
                                    ? 'جارٍ البحث في قاموس القرآن...'
                                    : 'Kuran sözlüğünde aranıyor...'))
                        : (LanguageService().isEnglish
                              ? 'Searching...'
                              : (LanguageService().isArabic
                                    ? 'جارٍ البحث...'
                                    : 'Aranıyor...')),
                    style: TextStyle(
                      fontSize: 16,
                      color: _isQuranMode
                          ? const Color(0xFFB8D4A0)
                          : const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return slivers;
    }

    if (_isSearching) {
      // ===== KURAN MODU ARAMA SONUÇLARI =====
      if (_isQuranMode) {
        if (_quranSearchResults.isNotEmpty) {
          slivers.add(
            SliverPadding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, widget.bottomPadding + 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _quranSearchResults.length) {
                      return const SizedBox.shrink();
                    }
                    final quranWord = _quranSearchResults[index];
                    return QuranSearchResultCard(
                      key: ValueKey('quran_result_${quranWord.kelime}_$index'),
                      word: quranWord,
                      searchQuery: _searchController.text.trim(),
                      onTap: () {
                        _dismissKeyboard();
                      },
                    );
                  },
                  childCount: _quranSearchResults.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  addSemanticIndexes: false,
                ),
              ),
            ),
          );
        }

        // Kuran modunda bulunamadı
        if (_showNotFound && _quranSearchResults.isEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  8,
                  60,
                  8,
                  widget.bottomPadding + 8,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: const Color(0xFFB8D4A0).withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Kuran sözlüğünde bulunamadı',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFB8D4A0).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Farklı bir kelime veya kök ile aramayı deneyin',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFFB8D4A0).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return slivers;
      }

      // ===== NORMAL SÖZLÜK ARAMA SONUÇLARI =====
      if (_searchResults.isNotEmpty) {
        // Eşleşme tipine göre gruplanmış sonuç listesi oluştur
        final groupedResults = _buildGroupedSearchResults(
          _searchResults,
          _searchController.text.trim(),
        );
        if (_shouldShowReviewPrompt) {
          slivers.add(SliverToBoxAdapter(child: _buildReviewPromptCard()));
        }
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, widget.bottomPadding + 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= groupedResults.length)
                    return const SizedBox.shrink();
                  final item = groupedResults[index];
                  if (item is _MatchHeaderItem) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),

                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              height: 1,
                              color: const Color(0xFFE5E5EA),
                            ),
                          ),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              height: 1,
                              color: const Color(0xFFE5E5EA),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final word = item as WordModel;
                  return SearchResultCard(
                    key: ValueKey('result_${word.kelime}_$index'),
                    word: word,
                    // Karta dokunulduğunda klavyeleri kapat + kelimeyi seç
                    onTap: () {
                      _dismissKeyboard();
                      _selectWord(word);
                    },
                    searchQuery: _searchController.text.trim(),
                    onExpand: () {
                      _removeTapHintOverlay();
                      // Kart genişlerken de klavyeleri kapat (normal + Arapça)
                      _dismissKeyboard();
                    },
                  );
                },
                childCount: groupedResults.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                addSemanticIndexes: false,
              ),
            ),
          ),
        );
      }
      if (_showNotFound && _searchResults.isEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 60, 8, widget.bottomPadding + 8),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: widget.isDarkMode
                          ? Colors.white24
                          : const Color(0xFF8E8E93).withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      LanguageService().isArabic
                          ? 'كلمة غير موجودة'
                          : 'Kelime bulunamadı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.isDarkMode
                            ? Colors.white70
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return slivers;
    }

    if (_selectedWord != null) {
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(8, 12, 8, widget.bottomPadding),
          sliver: SliverToBoxAdapter(
            child: RepaintBoundary(
              child: WordCard(
                key: ValueKey('selected_word_${_selectedWord!.kelime}'),
                word: _selectedWord!,
              ),
            ),
          ),
        ),
      );
      return slivers;
    }

    // Boş durum - Kuran Sözlüğü Bilgilendirme
    if (_isQuranMode) {
      final bool isLimitExceeded = _isQuranUsageExceeded;

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
            child: Column(
              children: [
                isLimitExceeded
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? const Color(0xFF2D4720).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFF4A5729).withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A5729).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.timer_off_rounded,
                                size: 48,
                                color: Color(0xFF4A5729),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Premium\'a Yükselt',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF1C1C1E),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Kuran sözlüğünü daha fazla kullanabilmek için Premium\'a yükseltin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? const Color(0xFF2D4720).withOpacity(0.12)
                              : const Color(0xFF4A5729).withOpacity(0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: widget.isDarkMode
                                ? const Color(0xFF4A5729).withOpacity(0.25)
                                : const Color(0xFF4A5729).withOpacity(0.08),
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (kDebugMode)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Text(
                                  'DEBUG: ${_quranTimeLimit - _quranUsageSeconds}s',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            Column(
                              children: [
                                Text(
                                  'Kur\'an-ı Kerim Sözlüğü',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF1C1C1E),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Kur\'an\'da geçen tüm kelimelerin kullanımlarını ve Kur\'ani anlamlarını ayetlerle birlikte öğrenin.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    color: widget.isDarkMode
                                        ? const Color(0xFFBBBBBB)
                                        : const Color(0xFF444446),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _buildInfoRow(
                                  Icons.collections_bookmark_rounded,
                                  '25.000+ Kelime',
                                  'Kur\'an\'daki benzersiz tüm kelimeler.',
                                  widget.isDarkMode,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1, thickness: 0.5),
                                ),
                                _buildInfoRow(
                                  Icons.psychology_alt_rounded,
                                  'Kurani Anlamlar',
                                  'Kelimelerin Kur\'an ayetlerinde kazandığı anlamları öğrenin.',
                                  widget.isDarkMode,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1, thickness: 0.5),
                                ),
                                _buildInfoRow(
                                  Icons.auto_awesome_motion_rounded,
                                  'Kur\'an Ayetleri',
                                  'On binlerce Kur\'an ayeti ile kelimelerin Kur\'andaki kullanımlarını görün.',
                                  widget.isDarkMode,
                                ),
                              ], // Closes inner Column children
                            ), // Closes inner Column
                          ], // Closes Stack children
                        ), // Closes Stack
                      ), // Closes normal state Container
                if (!(_creditsService.isPremium ||
                    _creditsService.isLifetimeAdsFree))
                  const SizedBox(height: 20),
                if (!(_creditsService.isPremium ||
                    _creditsService.isLifetimeAdsFree))
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isDarkMode
                              ? [
                                  const Color(0xFF2D4720),
                                  const Color(0xFF1A2E12),
                                ]
                              : [
                                  const Color(0xFF4A5729),
                                  const Color(0xFF2D3818),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Sınırsız erişim için Premium\'a yükselt',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Boş durum - Normal Sözlük Bilgilendirme
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
            child: Column(
              children: [
                // 🎁 KAMPANYA BANNER'I - Hesap bazlı: kampanya aktif + promo kullanmamış hesaplar
                if (LanguageService().isTurkish)
                  ListenableBuilder(
                    listenable: GlobalConfigService(),
                    builder: (context, _) {
                      final globalConfig = GlobalConfigService();
                      if (!globalConfig.campaignEnabled)
                        return const SizedBox.shrink();

                      // PurchaseManager'daki hazır state'i kullan (Gecikmesiz/Flashsız)
                      if (_creditsService.hasUsedPromo)
                        return const SizedBox.shrink();

                      return CampaignBanner(isDarkMode: widget.isDarkMode);
                    },
                  ),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.03)
                        : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (LanguageService().isTurkish)
                        Text(
                          'Kavaid Arapça Sözlük',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: widget.isDarkMode
                                ? Colors.white
                                : const Color(0xFF1C1C1E),
                            letterSpacing: -0.5,
                            fontFamily: 'Inter', // Uygulamanın ana fontu
                          ),
                        ),
                      if (LanguageService().isTurkish)
                        const SizedBox(height: 12),
                      if (LanguageService().isTurkish)
                        Text(
                          'Yeni nesil yapay zeka destekli ilk Arapça sözlük',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: widget.isDarkMode
                                ? const Color(0xFFBBBBBB)
                                : const Color(0xFF444446),
                          ),
                        ),
                      if (LanguageService().isEnglish)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'The first AI-powered Arabic dictionary',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                              color: widget.isDarkMode
                                  ? const Color(0xFFBBBBBB)
                                  : const Color(0xFF444446),
                            ),
                          ),
                        ),
                      if (LanguageService().isArabic)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'أول قاموس عربي مدعوم بالذكاء الاصطناعي',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                              color: widget.isDarkMode
                                  ? const Color(0xFFBBBBBB)
                                  : const Color(0xFF444446),
                            ),
                          ),
                        ),
                      if (LanguageService().isEnglish ||
                          LanguageService().isArabic)
                        const SizedBox(height: 12),
                      if (LanguageService().isTurkish)
                        const SizedBox(height: 28),
                      if (LanguageService().isTurkish)
                        _buildInfoRow(
                          Icons.search_rounded,
                          'Sınırsız Kelime',
                          'Yapay zeka ile sınırsız kelime arayın.',
                          widget.isDarkMode,
                        ),
                      if (LanguageService().isTurkish)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                      if (LanguageService().isTurkish)
                        _buildInfoRow(
                          Icons.menu_book_rounded,
                          'Gramer Yapıları',
                          'Kelimelerin gramer yapılarını öğrenin.',
                          widget.isDarkMode,
                        ),
                      if (LanguageService().isTurkish)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                      if (LanguageService().isTurkish)
                        _buildInfoRow(
                          Icons.style_rounded,
                          'Kişisel Listeler',
                          'Kendi kelime listelerinizi ve kartlarınızı oluşturun.',
                          widget.isDarkMode,
                        ),
                    ],
                  ),
                ),
                if (LanguageService().isTurkish &&
                    !(_creditsService.isPremium ||
                        _creditsService.isLifetimeAdsFree))
                  const SizedBox(height: 20),
                if (LanguageService().isTurkish &&
                    !(_creditsService.isPremium ||
                        _creditsService.isLifetimeAdsFree))
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D47A1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Sınırsız erişim için Premium\'a yükselt',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return slivers;
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String subtitle,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF8BC34A).withOpacity(0.1)
                : const Color(0xFF4A5729).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDarkMode
                ? const Color(0xFF8BC34A)
                : const Color(0xFF4A5729),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiSearchButtonContent() {
    return const SizedBox.shrink(); // AI butonu tamamen kaldırıldı
  }
}

class _MatchHeaderItem {
  final String title;
  const _MatchHeaderItem(this.title);
}

class _AiButtonItem {
  const _AiButtonItem();
}

List<Object> _buildGroupedSearchResults(List<WordModel> words, String query) {
  if (words.isEmpty || query.trim().isEmpty) {
    return words.cast<Object>();
  }

  final trimmedQuery = query.trim();
  final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(trimmedQuery);
  final normalizedQuery = hasArabic
      ? _removeArabicDiacriticsForUi(trimmedQuery)
      : trimmedQuery.toLowerCase();

  final exact = <WordModel>[];
  final root = <WordModel>[];
  final prefix = <WordModel>[];
  final others = <WordModel>[];

  for (final w in words) {
    if (hasArabic) {
      final normKelime = _removeArabicDiacriticsForUi(w.kelime);
      final normHar = _removeArabicDiacriticsForUi(w.harekeliKelime ?? '');

      if (normKelime == normalizedQuery || normHar == normalizedQuery) {
        exact.add(w);
        continue;
      }
      final bool prefixMatch =
          normKelime.startsWith(normalizedQuery) ||
          normHar.startsWith(normalizedQuery);
      if (prefixMatch) {
        prefix.add(w);
        continue;
      }

      final koku = (w.koku ?? '').trim();
      final normKoku = _removeArabicDiacriticsForUi(koku);
      final bool rootMatch =
          normalizedQuery.length >= 2 && normKoku == normalizedQuery;
      if (rootMatch) {
        root.add(w);
      } else {
        others.add(w);
      }
    } else {
      // TÜRKÇE/LATİN SORGU: anlamın TÜMÜNDE eşleşme kontrolü
      final anlam = (w.sadeAnlam ?? '').toLowerCase();

      if (anlam == normalizedQuery) {
        // Tam anlam eşleşmesi
        exact.add(w);
      } else if (anlam.startsWith(normalizedQuery) ||
          anlam.contains(',$normalizedQuery') ||
          anlam.contains(', $normalizedQuery') ||
          anlam.contains(' $normalizedQuery') ||
          anlam.contains('$normalizedQuery ') ||
          anlam.contains(normalizedQuery)) {
        // Başta veya anlamın herhangi bir yerinde geçen tüm eşleşmeleri prefix grubunda göster
        prefix.add(w);
      } else {
        // Eşleşmeyenler (Türkçe aramada ekranda gösterilmeyecek)
        others.add(w);
      }
    }
  }

  final result = <Object>[];
  if (exact.isNotEmpty) {
    result.addAll(exact);
  }

  if (prefix.isNotEmpty) {
    result.addAll(prefix);
  }

  // AI butonu kaldırıldı

  root.sort((a, b) => _rootTypeRank(a).compareTo(_rootTypeRank(b)));
  if (root.isNotEmpty) {
    result.add(const _MatchHeaderItem('Kök eşleşme'));
    result.addAll(root);
  }

  return result;
}

String _removeArabicDiacriticsForUi(String text) {
  return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0653-\u0655]'), '');
}

int _rootTypeRank(WordModel word) {
  String? typeText;
  if (word.dilbilgiselOzellikler?.containsKey('tur') == true) {
    typeText = word.dilbilgiselOzellikler!['tur']?.toString();
  } else if (word.tip?.isNotEmpty == true) {
    typeText = word.tip;
  }

  final t = (typeText ?? '').toLowerCase().trim();
  if (t.contains('isim')) return 0;
  if (t.contains('fiil')) return 2;
  return 1;
}
