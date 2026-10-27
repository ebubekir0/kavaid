import 'package:flutter/material.dart';
import '../utils/dictionary_mode_notifier.dart';
import '../models/word_model.dart';
import '../services/credits_service.dart';
import '../services/admob_service.dart';
import '../utils/performance_utils.dart';
import '../services/tts_service.dart';
import '../services/turkce_analytics_service.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import '../models/custom_word.dart';
import '../services/emsile_database_service.dart';
import 'ai_chat_sheet.dart';
import 'save_button.dart';
import 'search_result_card_parts.dart';
import '../services/arabic_definitions.dart';
import 'package:kavaid/l10n/l10n.dart';

// Global expanded card controller sınıfı ve ilgili mantık kaldırıldı.
// Artık bir kart açıldığında diğeri kapanmayacak.

class SearchResultCard extends StatefulWidget {
  final WordModel word;
  final VoidCallback onTap;
  final VoidCallback? onExpand;
  // Optional controls for consumers
  final bool showExpandButton;
  final bool enableExpand; // controls tap-to-expand behavior
  final String? searchQuery; // Arama kelimesi vurgulamak için
  final bool showAddButton;
  final bool showRemoveButton;
  final VoidCallback? onRemove;
  final bool showAiTeacherButton;

  const SearchResultCard({
    super.key,
    required this.word,
    required this.onTap,
    this.onExpand,
    this.showExpandButton = true,
    this.enableExpand = true,
    this.searchQuery, // Arama kelimesi parametresi
    this.showAddButton = true,
    this.showRemoveButton = false,
    this.onRemove,
    this.showAiTeacherButton = true,
  });

  @override
  State<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<SearchResultCard>
    with SingleTickerProviderStateMixin {
  static const bool _aiTeacherFeatureEnabled = true;

  // PERFORMANCE: Single ticker
  final CreditsService _creditsService = CreditsService();
  final TTSService _ttsService = TTSService();
  final AdMobService _adMobService = AdMobService();
  // PERFORMANCE: ScreenshotController lazy oluşturulacak — sadece paylaşım yapıldığında
  ScreenshotController? _screenshotController;
  bool _isExpanded = false;
  bool _hasEverExpanded = false; // İlk defa açılma durumu için

  // PERFORMANCE: Animasyon controller'ı lazy-loading ile optimize et
  AnimationController? _animationController;
  Animation<double>? _expandAnimation;
  Future<Map<String, dynamic>?>? _emsileLookupFuture;
  String? _emsileLookupMazi;

  // Aynı fiil için sorgu bir kez yapılır; tekrar açılışta sonuç anında gelir.
  static final Map<String, Map<String, dynamic>?> _emsileCache = {};

  // AI asistanı: kelime kartından bağımsız. Önceden kaydet/çıkar butonlarına
  // bağlıydı, bu yüzden kitap metinleri ve özel kelime listelerinde hiç
  // görünmüyordu.
  bool get _shouldShowAiTeacherButton =>
      _aiTeacherFeatureEnabled && widget.showAiTeacherButton;

  @override
  void initState() {
    super.initState();
    if (!ArabicDefinitions.instance.loaded.value) {
      ArabicDefinitions.instance.loaded.addListener(_onArabicLoaded);
    }
  }

  void _onArabicLoaded() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant SearchResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word.kelime != widget.word.kelime ||
        oldWidget.word.fiilCekimler != widget.word.fiilCekimler) {
      _emsileLookupMazi = null;
      _emsileLookupFuture = null;
    }
  }

  @override
  void dispose() {
    ArabicDefinitions.instance.loaded.removeListener(_onArabicLoaded);
    _animationController?.dispose();
    super.dispose();
  }

  // PERFORMANCE: Animasyon controller'ı lazy initialize et
  void _initializeAnimation() {
    if (_animationController == null) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );

      _expandAnimation = CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic, // PERFORMANCE: Daha smooth curve
        reverseCurve: Curves.easeInCubic,
      );
    }
  }

  String? _maziFormForEmsile() {
    if (LanguageService().isEnglish) return null;
    if (widget.word.fiilCekimler?.isNotEmpty != true) return null;

    final fiilCekimler = widget.word.fiilCekimler!;
    final hasMazi =
        fiilCekimler.containsKey('maziForm') &&
        fiilCekimler['maziForm']?.toString().trim().isNotEmpty == true;
    final hasMuzari =
        fiilCekimler.containsKey('muzariForm') &&
        fiilCekimler['muzariForm']?.toString().trim().isNotEmpty == true;

    if (!hasMazi && !hasMuzari) return null;
    if (!hasMazi) return null;
    return fiilCekimler['maziForm'].toString().trim();
  }

  void _ensureEmsileLookup({bool force = false}) {
    final maziForm = _maziFormForEmsile();
    if (!force && _emsileLookupMazi == maziForm) return;
    _emsileLookupMazi = maziForm;
    final known = maziForm == null
        ? null
        : EmsileDatabaseService.instance.hasMazi(maziForm);
    if (maziForm == null) {
      _emsileLookupFuture = null;
    } else if (known != null) {
      // Bellekteki dizinden anında: veritabanı beklenmez.
      _emsileLookupFuture = SynchronousFuture(
        known ? const <String, dynamic>{'mazi': true} : null,
      );
    } else if (_emsileCache.containsKey(maziForm)) {
      _emsileLookupFuture = SynchronousFuture(_emsileCache[maziForm]);
    } else {
      _emsileLookupFuture = EmsileDatabaseService.instance
          .searchByMazi(maziForm)
          .then((r) {
            if (_emsileCache.length > 300) _emsileCache.clear();
            return _emsileCache[maziForm] = r;
          });
    }
  }

  void _toggleExpanded() {
    if (!mounted) return;

    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    // Arapça klavyeyi kapatmak için callback'i çağır
    widget.onExpand?.call();

    if (!_isExpanded) {
      // Düğme kararı bellekteki dizinden anında verilir; kart beklemeden açılır.
      _ensureEmsileLookup();

      // PERFORMANCE: Animasyonu lazy initialize et ama anında başlat
      _initializeAnimation();

      // İlk defa açılıyorsa işaretle
      setState(() {
        _isExpanded = true;
        if (!_hasEverExpanded) {
          _hasEverExpanded = true;
        }
      });

      // Animasyonu anında başlat
      _animationController!.forward();

      // Arka plan işlemleri (reklam, analytics vb.) kullanıcıyı bekletmeden yapılır
      Future.microtask(() {
        _adMobService.onWordCardOpenedAdRequest();
        TurkceAnalyticsService.kelimeDetayiAcildi(widget.word.kelime);
      });
    } else {
      _collapseCard();
    }
  }

  void _collapseCard() {
    if (!mounted || _animationController == null) return;

    if (_isExpanded) {
      _animationController!.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isExpanded = false;
          });
        }
      });
    }
  }

  Future<void> _speakArabic() async {
    // Analytics event gönder
    await TurkceAnalyticsService.kelimeTelaffuzEdildi(widget.word.kelime);

    // Harekeli kelime varsa onu kullan, yoksa normal kelimeyi kullan
    final textToSpeak = widget.word.harekeliKelime?.isNotEmpty == true
        ? widget.word.harekeliKelime!
        : widget.word.kelime;

    // Sessizce telaffuz et, hiç bildirim gösterme
    await _ttsService.speak(textToSpeak);
  }

  Widget _maybeWrapForScreenshot(Widget child) {
    final controller = _screenshotController;
    if (controller == null) return child;
    return Screenshot(controller: controller, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // PERFORMANCE: RepaintBoundary ve key optimizasyonu
    return RepaintBoundary(
      key: ValueKey('search_card_${widget.word.kelime}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: _maybeWrapForScreenshot(
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF48484A)
                    : const Color(0xFFD0D0D0),
                width: 0.8,
              ),
              // PERFORMANCE: Shadow optimizasyonu
              boxShadow: (isDarkMode || !PerformanceUtils.enableShadows)
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0x0D000000), // Colors.black @ 0.05
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // PERFORMANCE: Column boyutunu minimize et
              children: [
                // Ana kart içeriği
                _buildMainContent(isDarkMode),

                // PERFORMANCE: Genişleyebilir detay alanını optimize et
                if (_isExpanded && _expandAnimation != null)
                  SizeTransition(
                    sizeFactor: _expandAnimation!,
                    child: _buildExpandedContent(isDarkMode),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // PERFORMANCE: Ana içeriği ayrı widget'a al
  Widget _buildMainContent(bool isDarkMode) {
    return InkWell(
      onTap: widget.enableExpand ? _toggleExpanded : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        // Arapça madde açıkken ١ ile ٢ arası diğer anlamlar arasıyla aynı kalsın
        padding: EdgeInsets.fromLTRB(12, 12, 12, _isExpanded && _arabicEntry != null ? 4 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Üst satır: kelime, yanında kök ve tür; kenarda butonlar
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Arapça arayüzde butonlar solda, kelime sağda
                if (LanguageService().isArabic) ...[
                  _buildActionButtons(isDarkMode),
                  Expanded(
                    child: WordHeadline(
                      word: widget.word,
                      isDarkMode: isDarkMode,
                      rightToLeft: true,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: WordHeadline(
                      word: widget.word,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  _buildActionButtons(isDarkMode),
                ],
              ],
            ),

            // Arapça anlam dilinde ilk anlamın şerhi (١)
            if (_arabicEntry case final entry?) ...[
              // İlk anlamın şerhi; açılınca yerinde kalır, altına örneği gelir
              const SizedBox(height: 6),
              ArabicQuickLine(
                word: widget.word,
                entry: entry,
                isDarkMode: isDarkMode,
                expanded: _isExpanded,
              ),
            ]
            // Türkçe anlam ve harfi cerler (tam genişlikte)
            else if (widget.word.sadeAnlam?.isNotEmpty == true ||
                widget.word.harfiCerler.isNotEmpty) ...[
              const SizedBox(height: 6),
              MeaningText(
                word: widget.word,
                isDarkMode: isDarkMode,
                expanded: _isExpanded,
                searchQuery: widget.searchQuery,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// AI asistanı (en solda), genişlet, seslendir ve kaydet butonları.
  Widget _buildActionButtons(bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_shouldShowAiTeacherButton) ...[
          _buildAiTeacherButton(isDarkMode),
          const SizedBox(width: 4),
        ],
        if (widget.showExpandButton) _buildExpandButton(isDarkMode),
        _buildSpeakButton(isDarkMode),
        if (widget.showAddButton || widget.showRemoveButton)
          SaveButton(
            target: SaveTarget.fromWordModel(widget.word),
            isDarkMode: isDarkMode,
            onRemove: widget.showRemoveButton ? widget.onRemove : null,
            // Uzun listelerde ilk çizimi yavaşlatmamak için kayıt sorgusu
            // kelimeye göre hafifçe dağıtılır.
            checkDelay: Duration(
              milliseconds: 700 + (widget.word.kelime.hashCode & 0x7f),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandButton(bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: isDarkMode
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakButton(bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _speakArabic,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(
            Icons.volume_up,
            color: isDarkMode
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6D6D70),
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Header'daki AI asistanı düğmesi: ikonların en solunda, yumuşak mavi
  /// yuvarlatılmış kare zeminde sade bir simge.
  Widget _buildAiTeacherButton(bool isDarkMode) {
    return Tooltip(
      message: l10n.aiAsistan,
      child: Material(
        color: const Color(0xFF007AFF).withValues(alpha: isDarkMode ? 0.18 : 0.09),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          key: const ValueKey('ai-button'),
          onTap: _showAiChatSheet,
          borderRadius: BorderRadius.circular(9),
          child: const SizedBox(
            width: 32,
            height: 28,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF007AFF),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  /// Kelimeye bağlı AI sohbeti açar.
  void _showAiChatSheet({String? openingMessage}) {
    // AI asistanı için giriş şart: sohbet açılmadan alttan uyarı çıkar.
    if (!AuthService().isSignedIn) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10n.aiAsistaniKullanmakIcinLutfen,
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AiChatSheet(
        word: widget.word,
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
        openingMessage: openingMessage,
      ),
    );
  }

  /// Anlam dili Arapçaysa kelimenin Arapça maddesi (yoksa null).
  Map<String, dynamic>? get _arabicEntry => ArabicDefinitions.instance.of(widget.word);

  Widget _buildExpandedContent(bool isDarkMode) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arapça madde: ١ ve örneği üst satırda yerinde kalır (açılınca kaymasın);
          // ardından ٢ ve sonrası, harf-i cerler; çoğul ve çekim kutuları en altta.
          if (_arabicEntry case final entry?) ...[
            ArabicDefinitionView(word: widget.word, entry: entry, isDarkMode: isDarkMode),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              height: 1.0,
              color: isDarkMode
                  ? const Color(0xFF48484A)
                  : const Color(0xFFD1D1D6),
            ),
            const SizedBox(height: 8),
          ],

          // Kök ana kartta kelimenin yanında; çoğul alt kartta
          PluralBox(word: widget.word, isDarkMode: isDarkMode),

          // Fiil çekimleri (yan yana, sadece varsa göster)
          ConjugationRow(word: widget.word, isDarkMode: isDarkMode),

          // Emsile (fiil çekimleri tablosu) butonu. Arapça anlam dilinde emsile
          // anlamları Arapça maddeden gelir (EmsileView).
          if (!LanguageService().isArabic) _buildEmsileButton(isDarkMode),

          // Örnek cümleler - Arapça için gösterme (Arapça maddede anlamların altında)
          if (!LanguageService().isArabic && _arabicEntry == null)
            ExampleSentences(
              word: widget.word,
              isDarkMode: isDarkMode,
              onSpeak: _ttsService.speak,
            ),

          // AI asistanı: tek satır, sade
          if (_shouldShowAiTeacherButton)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AiAssistPills(
                isDarkMode: isDarkMode,
                showMoreExamples:
                    !LanguageService().isArabic &&
                    _arabicEntry == null &&
                    widget.word.ornekCumleler?.isNotEmpty == true,
                onAsk: () => _showAiChatSheet(),
                onMoreExamples: () => _showAiChatSheet(
                  openingMessage:
                      l10n.buKelimeyleSeviyemeUygun5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmsileButton(bool isDarkMode) {
    _ensureEmsileLookup();
    final cachedMaziForm = _emsileLookupMazi;
    final cachedLookupFuture = _emsileLookupFuture;
    if (cachedMaziForm == null || cachedLookupFuture == null) {
      return const SizedBox.shrink();
    }
    // Sadece fiil çekimi olan kelimelerde göster. İngilizcede gizle
    if (LanguageService().isEnglish) return const SizedBox.shrink();
    if (widget.word.fiilCekimler?.isNotEmpty != true) {
      return const SizedBox.shrink();
    }

    // En az mazi veya müzari form olmalı
    final hasMazi =
        widget.word.fiilCekimler!.containsKey('maziForm') &&
        widget.word.fiilCekimler!['maziForm']?.toString().trim().isNotEmpty ==
            true;
    final hasMuzari =
        widget.word.fiilCekimler!.containsKey('muzariForm') &&
        widget.word.fiilCekimler!['muzariForm']?.toString().trim().isNotEmpty ==
            true;

    if (!hasMazi && !hasMuzari) return const SizedBox.shrink();

    final maziForm = hasMazi
        ? widget.word.fiilCekimler!['maziForm'].toString().trim()
        : '';

    return FutureBuilder<Map<String, dynamic>?>(
      future: cachedLookupFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        const emsileBlue = Color(0xFF1558D6);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                emsileSearchNotifier.value =
                    "$maziForm|${DateTime.now().millisecondsSinceEpoch}";
                dictionaryModeNotifier.value = DictionaryMode.emsile;
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: emsileBlue.withValues(alpha: isDarkMode ? 0.12 : 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode
                        ? emsileBlue.withValues(alpha: 0.4)
                        : emsileBlue.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 16, color: emsileBlue),
                    const SizedBox(width: 8),
                    Text(
                      l10n.tumFiilCekimleri,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: emsileBlue,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: emsileBlue.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}
