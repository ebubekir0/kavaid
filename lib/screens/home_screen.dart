import 'dart:async';
import 'dart:isolate';
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
import '../widgets/word_card.dart';
import '../widgets/search_result_card.dart';
import '../widgets/quran_word_card.dart';
import '../widgets/arabic_keyboard.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/performance_utils.dart';
import '../utils/quran_mode_notifier.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import 'package:kavaid/services/connectivity_service.dart';
import 'package:kavaid/services/review_service.dart';
import 'package:kavaid/services/sync_service.dart';
import 'package:kavaid/services/app_usage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'log_screen.dart';
import 'custom_words_screen.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/quran_onboarding.dart';
import 'subscription_screen.dart';


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

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GeminiService _geminiService = GeminiService();
  final DatabaseService _dbService = DatabaseService.instance; // YEREL DB SERVİSİ
  final CreditsService _creditsService = CreditsService();
  
  WordModel? _selectedWord;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _showAIButton = false;
  bool _showNotFound = false;
  bool _showArabicKeyboard = false; // Arapça klavye durumu
  bool _isSearchInProgress = false; // Arama işlemi devam ediyor mu
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
  bool _prewarmPending = false; // İlk detay açılış jank'ını önlemek için prewarm

  // Kuran sözlüğü state
  bool _isQuranMode = false;
  final QuranDictionaryService _quranService = QuranDictionaryService.instance;
  List<QuranWordModel> _quranSearchResults = [];
  QuranWordModel? _selectedQuranWord;

  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
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

  bool get wantKeepAlive => true; // Keep alive açık: sekmeler arası geçişte state korunsun

  bool _containsArabic(String s) => RegExp(r'[\u0600-\u06FF]').hasMatch(s);

  @override
  void initState() {
    super.initState();
    
    _searchController.addListener(_onSearchChanged);
    
    // Kuran modunu dinle
    _isQuranMode = quranModeNotifier.value;
    quranModeNotifier.addListener(_onQuranModeChanged);
    
    // Kuran sözlüğünü arka planda başlat
    Future.microtask(() => _quranService.initialize());
    
    _creditsService.addListener(_onCreditsChanged);
    
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

    // Focus listener - Arapça klavye durumunu takip et
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && mounted && _showArabicKeyboard) {
        // Normal klavye focus aldıysa Arapça klavyeyi kapat
        setState(() {
          _showArabicKeyboard = false;
        });
        widget.onArabicKeyboardStateChanged?.call(false);
      }
    });

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
      }
    });
  }
  
  // İnternet bağlantısını kontrol et
  Future<void> _checkInternetConnection() async {
    final hasConnection = await _connectivityService.hasInternetConnection();
    if (mounted) {
      setState(() {
        _hasInternet = hasConnection;
      });
    }
    
    // Her 30 saniyede bir kontrol et
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _checkInternetConnection();
      }
    });
  }
  
  // Klavyeyi doğal şekilde açmak için yardımcı metod  
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
      if (!mounted || ((!_debugAlwaysShowHint && _hasShownTapHint) || _tapHintOverlay != null)) return;

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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: const Text(
                      'Kelimeye dokunarak daha fazla detay görebilirsin',
                      style: TextStyle(
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
    
    _quranUsageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _quranUsageSeconds++;
      });
      
      if (_quranUsageSeconds % 30 == 0) {
        _saveQuranUsage();
      }
      
      if (_quranUsageSeconds >= _quranTimeLimit) {
        _stopQuranUsageTimer();
        // Limit dolunca UI'ı güncellemek için
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
    final bool hasUnlimitedAccess = AuthService().isSignedIn && (_creditsService.isPremium || _creditsService.isLifetimeAdsFree);
    
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              const Icon(Icons.timer_off_rounded, size: 48, color: Color(0xFF4A5729)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold)),
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
    _removeTapHintOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _creditsService.removeListener(_onCreditsChanged);
    quranModeNotifier.removeListener(_onQuranModeChanged);
    _searchSubscription?.cancel();
    _debounceTimer?.cancel();
    _nativeAd?.dispose();
    _tapHintTimer?.cancel();
    _interstitialTimer?.cancel();
    _quranUsageTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App lifecycle değişikliklerini dinle
    _adMobService.onAppStateChanged(state);
    // Surface yokken çizim hatalarını önlemek ve kaynakları serbest bırakmak için
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _stopQuranUsageTimer();
      _nativeAd?.dispose();
      _nativeAd = null;
      if (mounted) {
        setState(() {
          _isAdLoaded = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isQuranMode) {
        _startQuranUsageTimer();
      }
      // Öne gelindiğinde native reklamı yeniden yükle
      if (_nativeAd == null && !_creditsService.isPremium && !_creditsService.isLifetimeAdsFree) {
        _loadNativeAd();
      }
    }
  }

  void _loadNativeAd() {
    // PREMIUM KONTROLÜ: Premium kullanıcılar için reklam yükleme.
    if (_creditsService.isPremium || _creditsService.isLifetimeAdsFree) {
      return;
    }
  
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: AdMobService.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
            // Yenileme fonksiyonu kaldırıldı.
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
    )..load();
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
    
    if (cleanText.isEmpty) {
      setState(() {
        // Sadece aktif kısımdaki sonuçları temizle
        if (_isQuranMode) {
          _quranSearchResults = [];
          _selectedQuranWord = null;
        } else {
          _searchResults = [];
          _selectedWord = null;
        }
        _isSearching = false;
        _showAIButton = false;
        _showNotFound = false;
        _isSearchInProgress = false;
      });
      return;
    }

    // 350ms -> 150ms: Daha seri tepki için süreyi kısalttık
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
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
      final isAdFreeNow = _creditsService.isLifetimeAdsFree || _creditsService.isPremium;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdFreeNow
              ? 'Tüm kitaplar açıldı ve reklamlar kaldırıldı.'
              : 'Tüm kitaplar açıldı. Reklamları kalıcı kaldırmak için lütfen giriş yapın.'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gizli kod uygulanamadı: $e')),
      );
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
            content: Text('Sözlük başarıyla güncellendi! ${info['wordCount']} kelime yüklendi.'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database reload hatası: $e')),
      );
    }
  }

  Future<void> _performSearch(String query) async {
    // Query'yi temizle - başındaki ve sonundaki boşlukları kaldır
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    
    // Kuran sözlüğü limit kontrolü
    if (_isQuranMode && _isQuranUsageExceeded) {
      _showQuranLimitDialog();
      return;
    }
    
    setState(() {
      _isSearchInProgress = true;
      _isSearching = true;
      _isLoading = true;
      _showAIButton = !_isQuranMode; // Kuran modunda AI butonu gösterme
      _showNotFound = false;
    });

    try {
      if (_isQuranMode) {
        // Kuran sözlüğünde ara
        final quranResults = await _quranService.searchWords(cleanQuery);

        if (mounted) {
          final currentText = _searchController.text.trim();
          if (currentText != cleanQuery) return;

          setState(() {
            _quranSearchResults = quranResults;
            // Normal sonuçları silme!
            _isLoading = false;
            _selectedWord = null;
            _selectedQuranWord = null;
            _showAIButton = false;
            _showNotFound = quranResults.isEmpty;
            _isSearchInProgress = false;
          });
        }
      } else {
        // Normal sözlükte ara
        final results = await _dbService.searchWords(cleanQuery);

        if (mounted) {
          final currentText = _searchController.text.trim();
          if (currentText != cleanQuery) return;

          setState(() {
            _searchResults = results;
            // Kuran sonuçlarını silme!
            _isLoading = false;
            _selectedWord = null;
            _showAIButton = true;
            _showNotFound = false;
            _isSearchInProgress = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
         final currentText = _searchController.text.trim();
         if (currentText != cleanQuery) return;

        setState(() {
          if (_isQuranMode) {
            _quranSearchResults = [];
          } else {
            _searchResults = [];
          }
          _isLoading = false;
          _showAIButton = !_isQuranMode;
          _showNotFound = false;
          _isSearchInProgress = false;
        });
      }
    }
  }

  Future<void> _selectWord(WordModel word) async {
    // Arapça klavye açıksa kapat
    if (_showArabicKeyboard) {
      setState(() {
        _showArabicKeyboard = false;
      });
      widget.onArabicKeyboardStateChanged?.call(false);
    }
    // İpucu overlay açıksa kapat
    _removeTapHintOverlay();
    
    // Analytics event'leri gönder
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      // Arama analytics'i sadece kelime seçildiğinde gönder (performans için)
      await TurkceAnalyticsService.kelimeArandiNormal(searchQuery, _searchResults.length);
    }
    await TurkceAnalyticsService.kelimeDetayiGoruntulendi(word.kelime);
    
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
            backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF007AFF),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Future<void> _performActualAISearch(String query, {bool showLoading = true}) async {
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
                backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Column(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF007AFF),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w600)),
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
      final bool isInDictionaryView = _isSearching && _selectedWord == null && _searchResults.isNotEmpty;
      if ((!isInDictionaryView || !widget.isActive) && _tapHintOverlay != null) {
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
        backgroundColor: _isQuranMode
            ? (widget.isDarkMode ? const Color(0xFF151C12) : const Color(0xFFF9FBF7))
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
                              const Color(0xFFF1F4ED), // Çok daha hafif yeşilimsi başlangıç
                              const Color(0xFFF9FBF7), // Beyaza çok yakın hafif krem bitiş
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
                              const Color(0xFF0A141F), // Üstte derin mavi/lacivert
                              const Color(0xFF1C1C1E), // Altta ana koyu renk
                            ]
                          : [
                              const Color(0xFFD6E9FF), // Üstte belirgin mavi
                              const Color(0xFFEBF4FF), // Altta daha hafif bir mavi (beyaz değil)
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
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      cacheExtent: hasKeyboard ? 300.0 : PerformanceUtils.listCacheExtent,
                      key: const PageStorageKey<String>('home_scroll'),
                      slivers: <Widget>[
                        SliverAppBar(
                          backgroundColor: _isQuranMode
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
                            preferredSize: const Size.fromHeight(108),
                            child: Container(
                              width: double.infinity,
                              color: _isQuranMode
                                  ? const Color(0xFF2D4720)
                                  : (widget.isDarkMode
                                      ? const Color(0xFF1C1C1E)
                                      : const Color(0xFF007AFF)),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                      // Kelime Listelerim Butonu - SOLDA
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            // Giriş kontrolü
                                            final auth = AuthService();
                                            if (!auth.isSignedIn) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Lütfen önce kayıt olup giriş yapın.',
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                  backgroundColor: Colors.black87,
                                                  duration: Duration(seconds: 2),
                                                  behavior: SnackBarBehavior.fixed,
                                                ),
                                              );
                                              return;
                                            }
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CustomWordsScreen(
                                                  isDarkMode: widget.isDarkMode,
                                                ),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: widget.isDarkMode
                                                  ? const Color(0xFF2C2C2E)
                                                  : const Color(0xFFE5E5EA),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.bookmark_rounded,
                                              color: _isQuranMode
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
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.transparent,
                                              width: 0.5,
                                            ),
                                          ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: GestureDetector(
                                                onLongPress: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(builder: (_) => const LogScreen()),
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.search_rounded,
                                                  color: widget.isDarkMode
                                                      ? const Color(0xFF8E8E93)
                                                      : const Color(0xFF8E8E93),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: () {
                                                  // Kuran modunda limit aşılmışsa girişi engelle
                                                  if (_isQuranMode && _isQuranUsageExceeded) {
                                                    return;
                                                  }
                                                  // Tıklama boşluğa gelse bile focus ver
                                                  if (!_searchFocusNode.hasFocus) {
                                                    _searchFocusNode.requestFocus();
                                                  }
                                                },
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  child: TextField(
                                                    controller: _searchController,
                                                    focusNode: _searchFocusNode,
                                                    enabled: !(_isQuranMode && _isQuranUsageExceeded),
                                                    autofocus: false,
                                                    textAlignVertical: TextAlignVertical.center,
                                                    textDirection: _containsArabic(_searchController.text)
                                                        ? TextDirection.rtl
                                                        : TextDirection.ltr,
                                                    textAlign: _containsArabic(_searchController.text)
                                                        ? TextAlign.right
                                                        : TextAlign.left,
                                                    keyboardType: TextInputType.text,
                                                    keyboardAppearance: widget.isDarkMode
                                                        ? Brightness.dark
                                                        : Brightness.light,
                                                    cursorColor: _isQuranMode
                                                        ? const Color(0xFF8BC34A)
                                                        : const Color(0xFF007AFF),
                                                    showCursor: true,
                                                    enableInteractiveSelection: true,
                                                    enableIMEPersonalizedLearning: true,
                                                    autofillHints: null,
                                                    style: TextStyle(
                                                      fontSize: _containsArabic(_searchController.text) ? 19 : 15,
                                                      height: 1.15,
                                                      letterSpacing: 0.0,
                                                      color: widget.isDarkMode
                                                          ? Colors.white
                                                          : const Color(0xFF1C1C1E),
                                                      fontWeight: FontWeight.w500,
                                                      decoration: TextDecoration.none,
                                                    ),
                                                      decoration: InputDecoration(
                                                        hintText: 'Kelime ara',
                                                        hintStyle: TextStyle(
                                                          color: widget.isDarkMode
                                                              ? const Color(0xFF8E8E93).withOpacity(0.8)
                                                              : const Color(0xFF8E8E93),
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                        border: InputBorder.none,
                                                        enabledBorder: InputBorder.none,
                                                        focusedBorder: InputBorder.none,
                                                        isDense: true,
                                                        contentPadding: EdgeInsets.zero,
                                                        fillColor: Colors.transparent, // Beyazlık hatasını engellemek için
                                                        filled: false,
                                                      ),
                                                    textInputAction: TextInputAction.search,
                                                    onSubmitted: (_) => _searchWithAI(),
                                                    readOnly: _showArabicKeyboard,
                                                    onTap: () {
                                                      // Arapça klavye açıksa kapat ve sistem klavyesini aç
                                                      if (_showArabicKeyboard) {
                                                        setState(() {
                                                          _showArabicKeyboard = false;
                                                        });
                                                        widget.onArabicKeyboardStateChanged?.call(false);
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Arapça Klavye Butonu
                                            Padding(
                                              padding: const EdgeInsets.only(right: 4, left: 4),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    // Kuran modunda limit aşılmışsa girişi engelle
                                                    if (_isQuranMode && _isQuranUsageExceeded) {
                                                      return;
                                                    }
                                                    setState(() {
                                                      _showArabicKeyboard = !_showArabicKeyboard;
                                                      if (_showArabicKeyboard) {
                                                        _searchFocusNode.unfocus();
                                                        TurkceAnalyticsService.arapcaKlavyeKullanildi();
                                                      }
                                                    });
                                                    widget.onArabicKeyboardStateChanged?.call(_showArabicKeyboard);
                                                  },
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: (_isQuranMode && _isQuranUsageExceeded)
                                                          ? (widget.isDarkMode ? Colors.white10 : Colors.black12)
                                                          : (_showArabicKeyboard
                                                              ? (_isQuranMode
                                                                  ? const Color(0xFF4A5729)
                                                                  : const Color(0xFF007AFF))
                                                              : (widget.isDarkMode
                                                                  ? const Color(0xFF3A3A3C).withOpacity(0.5)
                                                                  : const Color(0xFFE5E5EA).withOpacity(0.5))),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.keyboard_alt_outlined,
                                                      color: (_isQuranMode && _isQuranUsageExceeded)
                                                          ? (widget.isDarkMode ? Colors.white24 : Colors.black26)
                                                          : (_showArabicKeyboard
                                                              ? Colors.white
                                                              : (widget.isDarkMode
                                                                  ? const Color(0xFF8E8E93)
                                                                  : const Color(0xFF636366))),
                                                      size: 22,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (_searchController.text.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 6),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      _searchController.clear();
                                                      _lastSearchText = '';
                                                      setState(() {
                                                        _searchResults = [];
                                                        _quranSearchResults = [];
                                                        _selectedWord = null;
                                                        _selectedQuranWord = null;
                                                        _isSearching = false;
                                                        _showAIButton = false;
                                                        _showNotFound = false;
                                                      });
                                                    },
                                                    borderRadius: BorderRadius.circular(14),
                                                    child: Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: BoxDecoration(
                                                        color: widget.isDarkMode
                                                            ? Colors.white.withOpacity(0.08)
                                                            : const Color(0xFF8E8E93).withOpacity(0.08),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.clear,
                                                        color: widget.isDarkMode
                                                            ? const Color(0xFF8E8E93).withOpacity(0.8)
                                                            : const Color(0xFF8E8E93),
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
                                const SizedBox(height: 10),
                                // Genişletilmiş Segmented Control - Kuran / Sözlük Geçişi
                                Container(
                                  height: 40, // Küçültüldü
                                  padding: const EdgeInsets.all(3),
                                  margin: const EdgeInsets.symmetric(horizontal: 0),
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFEBEBEB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: widget.isDarkMode ? Border.all(
                                      color: const Color(0xFF38383A),
                                      width: 1,
                                    ) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (_isQuranMode) quranModeNotifier.value = false;
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            curve: Curves.easeOutCubic,
                                            decoration: BoxDecoration(
                                              color: !_isQuranMode
                                                  ? (widget.isDarkMode ? const Color(0xFF007AFF).withOpacity(0.8) : const Color(0xFF007AFF))
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(9),
                                              boxShadow: !_isQuranMode
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.12),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 1),
                                                      )
                                                    ]
                                                  : [],
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Sözlük',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: !_isQuranMode ? FontWeight.w600 : FontWeight.w500,
                                                  color: !_isQuranMode ? Colors.white : const Color(0xFF8E8E93),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!_isQuranMode) quranModeNotifier.value = true;
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            curve: Curves.easeOutCubic,
                                            decoration: BoxDecoration(
                                              color: _isQuranMode
                                                  ? (widget.isDarkMode ? const Color(0xFF2C3E18) : const Color(0xFF4A5729))
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(9),
                                              boxShadow: _isQuranMode
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.12),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 1),
                                                      )
                                                    ]
                                                  : [],
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Kuran Sözlüğü',
                                                style: TextStyle(
                                                  fontSize: 13, // Küçültüldü
                                                  fontWeight: _isQuranMode ? FontWeight.w600 : FontWeight.w500,
                                                  color: _isQuranMode
                                                      ? Colors.white
                                                      : const Color(0xFF8E8E93),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ],
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
            if (!_reviewService.hasRated &&
                (_appUsageService.shouldShowRating && _hasInternet || kDebugMode))
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
                    final navBarHeight = 56.0;
                    final systemNavBarHeight = MediaQuery.of(context).viewPadding.bottom;
                    final keyboardPadding = navBarHeight + systemNavBarHeight;
                    
                    return Container(
                      color: widget.isDarkMode 
                          ? const Color(0xFF1C1C1E) 
                          : const Color(0xFFF5F7FB), // Arka plan rengi
                      padding: EdgeInsets.only(bottom: keyboardPadding), // Navigation bar üstünde
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
          if (_prewarmPending)
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

  List<Widget> _buildMainContentSlivers() {
    List<Widget> slivers = [];
    
    if (_isLoading) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 180),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: _isQuranMode
                        ? const Color(0xFF8BC34A)
                        : const Color(0xFF007AFF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isQuranMode ? 'Kuran sözlüğünde aranıyor...' : 'Aranıyor...',
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
                padding: EdgeInsets.fromLTRB(8, 60, 8, widget.bottomPadding + 8),
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
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, widget.bottomPadding + 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= groupedResults.length) return const SizedBox.shrink();
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

                  if (item is _AiButtonItem && _showAIButton) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                      child: _buildAiSearchButtonContent(),
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

      // AI ile kelime ara butonu
      if (_showAIButton && _searchResults.isEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 12, 8, widget.bottomPadding + 8),
              child: Column(
                children: [
                  _buildAiSearchButtonContent(),

                  // AI ile arama sonucu bulunamadıysa mesajı göster
                  if (_showNotFound)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Kelime bulunamadı',
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.isDarkMode ? Colors.white70 : const Color(0xFF8E8E93),
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
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
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
                            child: const Icon(Icons.timer_off_rounded, size: 48, color: Color(0xFF4A5729)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Premium\'a Yükselt',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Kuran sözlüğünü daha fazla kullanabilmek için Premium\'a yükseltin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
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
                          color: widget.isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
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
                          color: widget.isDarkMode ? const Color(0xFFBBBBBB) : const Color(0xFF444446),
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
                if (!(_creditsService.isPremium || _creditsService.isLifetimeAdsFree))
                  const SizedBox(height: 20),
                if (!(_creditsService.isPremium || _creditsService.isLifetimeAdsFree))
                  InkWell(
                    onTap: () {
                      final auth = AuthService();
                      if (!auth.isSignedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lütfen önce kayıt olup giriş yapın.',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.black87,
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.fixed,
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isDarkMode 
                            ? [const Color(0xFF2D4720), const Color(0xFF1A2E12)]
                            : [const Color(0xFF4A5729), const Color(0xFF2D3818)],
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
                          const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                          if (defaultTargetPlatform != TargetPlatform.iOS && _creditsService.isPremium) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.verified, color: Colors.blue, size: 16),
                          ],
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
                          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.7)),
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
                      Text(
                        'Kavaid Arapça Sözlük',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: widget.isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Yeni nesil yapay zeka destekli ilk Arapça sözlük',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: widget.isDarkMode ? const Color(0xFFBBBBBB) : const Color(0xFF444446),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildInfoRow(
                        Icons.search_rounded,
                        'Sınırsız Kelime',
                        'Yapay zeka ile sınırsız kelime arayın.',
                        widget.isDarkMode,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      _buildInfoRow(
                        Icons.menu_book_rounded,
                        'Gramer Yapıları',
                        'Kelimelerin gramer yapılarını öğrenin.',
                        widget.isDarkMode,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      _buildInfoRow(
                        Icons.style_rounded,
                        'Kişisel Listeler',
                        'Kendi kelime listelerinizi ve kartlarınızı oluşturun.',
                        widget.isDarkMode,
                      ),
                    ],
                  ),
                ),
                if (!(_creditsService.isPremium || _creditsService.isLifetimeAdsFree))
                  const SizedBox(height: 20),
                if (!(_creditsService.isPremium || _creditsService.isLifetimeAdsFree))
                  InkWell(
                    onTap: () {
                      final auth = AuthService();
                      if (!auth.isSignedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lütfen önce kayıt olup giriş yapın.',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.black87,
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.fixed,
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                          ),
                          if (defaultTargetPlatform != TargetPlatform.iOS && _creditsService.isPremium) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.verified, color: Colors.blue, size: 16),
                          ],
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
                          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
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

  Widget _buildInfoRow(IconData icon, String title, String subtitle, bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF8BC34A).withOpacity(0.1) : const Color(0xFF4A5729).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: isDarkMode ? const Color(0xFF8BC34A) : const Color(0xFF4A5729)),
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
                  color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiSearchButtonContent() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF007AFF),
              Color(0xFF0051D5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _searchWithAI,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Kelimeyi Ara',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
      final bool prefixMatch = normKelime.startsWith(normalizedQuery) ||
          normHar.startsWith(normalizedQuery);
      if (prefixMatch) {
        prefix.add(w);
        continue;
      }

      final koku = (w.koku ?? '').trim();
      final normKoku = _removeArabicDiacriticsForUi(koku);
      final bool rootMatch = normalizedQuery.length >= 2 && normKoku == normalizedQuery;
      if (rootMatch) {
        root.add(w);
      } else {
        others.add(w);
      }
    } else {
      // TÜRKÇE/LATİN SORGU: anlamın TÜMÜNDE eşleşme kontrolü
      final anlam = (w.anlam ?? '').toLowerCase();

      if (anlam == normalizedQuery) {
        // Tam anlam eşleşmesi
        exact.add(w);
      } else if (
          anlam.startsWith(normalizedQuery) ||
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

  if (exact.isNotEmpty || prefix.isNotEmpty) {
    result.add(const _AiButtonItem());
  }

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