import 'package:flutter/material.dart';
import '../utils/dictionary_mode_notifier.dart';
import '../models/word_model.dart';
import '../services/credits_service.dart';
import '../services/admob_service.dart';
import '../utils/performance_utils.dart';
import '../services/tts_service.dart';
import '../services/turkce_analytics_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:async';
import '../services/custom_word_service.dart'; // Import for custom lists
import '../services/emsile_database_service.dart';
import 'ai_chat_sheet.dart';
import 'search_result_card_parts.dart';

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
  final CustomWordService _customWordService =
      CustomWordService(); // Service instance
  final CreditsService _creditsService = CreditsService();
  final TTSService _ttsService = TTSService();
  final AdMobService _adMobService = AdMobService();
  // PERFORMANCE: ScreenshotController lazy oluşturulacak — sadece paylaşım yapıldığında
  ScreenshotController? _screenshotController;
  bool _isExpanded = false;
  bool _hasEverExpanded = false; // İlk defa açılma durumu için

  // Kayıt durumu
  bool _isSaved = false;
  List<String> _savedListIds = []; // Hangi listelerde kayıtlı

  // PERFORMANCE: Animasyon controller'ı lazy-loading ile optimize et
  AnimationController? _animationController;
  Animation<double>? _expandAnimation;
  Future<Map<String, dynamic>?>? _emsileLookupFuture;
  String? _emsileLookupMazi;
  Timer? _savedStatusTimer;

  StreamSubscription<void>? _wordChangeSubscription;

  // AI asistanı: kelime kartından bağımsız. Önceden kaydet/çıkar butonlarına
  // bağlıydı, bu yüzden kitap metinleri ve özel kelime listelerinde hiç
  // görünmüyordu.
  bool get _shouldShowAiTeacherButton =>
      _aiTeacherFeatureEnabled && widget.showAiTeacherButton;

  @override
  void initState() {
    super.initState();
    // Animasyonu hemen başlatma - sadece gerektiğinde init et
    // Sadece sözlük görünümündeyse (showRemoveButton false ise) kayıt durumunu kontrol et
    if (!widget.showRemoveButton) {
      final savedStatusDelay = 700 + (widget.word.kelime.hashCode & 0x7f);
      _savedStatusTimer = Timer(Duration(milliseconds: savedStatusDelay), () {
        if (mounted) _checkSavedStatus();
      });
      // Değişiklikleri dinle
      _wordChangeSubscription = _customWordService.onWordsChanged.listen((_) {
        if (mounted) _checkSavedStatus();
      });
    }
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

  Future<void> _checkSavedStatus() async {
    if (!mounted) return;
    final listIds = await _customWordService.getListsWithWord(
      widget.word.kelime,
    );
    if (!mounted) return;
    setState(() {
      _savedListIds = listIds;
      _isSaved = listIds.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _savedStatusTimer?.cancel();
    _wordChangeSubscription?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  // PERFORMANCE: Animasyon controller'ı lazy initialize et
  void _initializeAnimation() {
    if (_animationController == null) {
      _animationController = AnimationController(
        duration: const Duration(
          milliseconds: 100,
        ), // PERFORMANCE: 150ms'den 100ms'ye düşürdüm
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
    _emsileLookupFuture = maziForm == null
        ? null
        : EmsileDatabaseService.instance.searchByMazi(maziForm);
  }

  void _toggleExpanded() {
    if (!mounted) return;

    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    // Arapça klavyeyi kapatmak için callback'i çağır
    widget.onExpand?.call();

    if (!_isExpanded) {
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
        padding: const EdgeInsets.all(12),
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

            // Türkçe anlam ve harfi cerler (tam genişlikte)
            if (widget.word.sadeAnlam?.isNotEmpty == true ||
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

  /// Genişlet, AI asistanı, seslendir ve kaydet butonları.
  Widget _buildActionButtons(bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showExpandButton) _buildExpandButton(isDarkMode),
        if (_shouldShowAiTeacherButton) _buildAiTeacherButton(isDarkMode),
        _buildSpeakButton(isDarkMode),
        if (widget.showAddButton || widget.showRemoveButton)
          _buildActionButton(isDarkMode),
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

  /// Header'daki AI asistanı ikonu: diğer ikonlarla aynı boyutta, yalnızca
  /// yumuşak mavi bir zemin ve mavi simgeyle ayrışır.
  Widget _buildAiTeacherButton(bool isDarkMode) {
    return Tooltip(
      message: 'Asistana sor',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAiChatSheet,
          customBorder: const CircleBorder(),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF).withValues(
                  alpha: isDarkMode ? 0.22 : 0.10,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF007AFF),
                size: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kelimeye bağlı AI sohbeti açar.
  void _showAiChatSheet({String? openingMessage}) {
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

  Widget _buildExpandedContent(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1.0,
            color: isDarkMode
                ? const Color(0xFF48484A)
                : const Color(0xFFD1D1D6),
          ),
          const SizedBox(height: 8),

          // Kök ana kartta kelimenin yanında; çoğul alt kartta
          PluralBox(word: widget.word, isDarkMode: isDarkMode),

          // Fiil çekimleri (yan yana, sadece varsa göster)
          ConjugationRow(word: widget.word, isDarkMode: isDarkMode),

          // Emsile (fiil çekimleri tablosu) butonu - Arapça için gösterme
          if (!LanguageService().isArabic) _buildEmsileButton(isDarkMode),

          // Örnek cümleler - Arapça için gösterme
          if (!LanguageService().isArabic)
            ExampleSentences(
              word: widget.word,
              isDarkMode: isDarkMode,
            ),

          // AI asistanı: tek satır, sade
          if (_shouldShowAiTeacherButton)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AiAssistPills(
                isDarkMode: isDarkMode,
                showMoreExamples:
                    !LanguageService().isArabic &&
                    widget.word.ornekCumleler?.isNotEmpty == true,
                onAsk: () => _showAiChatSheet(),
                onMoreExamples: () => _showAiChatSheet(
                  openingMessage:
                      'Bu kelimeyle seviyeme uygun 5 yeni örnek ver: kolaydan zora doğru.',
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
                      'Tüm Fiil Çekimleri',
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

  Widget _buildActionButton(bool isDarkMode) {
    final isRemove = widget.showRemoveButton;

    // Her iki durumda da aynı bookmark butonu
    // Listelerim ekranında (isRemove=true) kelime zaten kayıtlı olduğu için dolu görünecek
    final isSavedState = isRemove ? true : _isSaved;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isRemove ? widget.onRemove : _handleBookmarkTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(
            isSavedState ? Icons.bookmark : Icons.bookmark_border,
            color: isSavedState
                ? const Color(0xFF007AFF)
                : (isDarkMode
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70)),
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showLoginRequiredSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LanguageService().isEnglish
              ? 'Please log in or sign up first'
              : 'Lütfen önce kayıt olup giriş yapın.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  /// Bookmark butonuna tıklandığında: tek liste varsa toggle, birden fazla varsa dialog aç
  Future<void> _handleBookmarkTap() async {
    if (!mounted) return;

    // Giriş kontrolü
    final auth = AuthService();
    if (!auth.isSignedIn) {
      _showLoginRequiredSnackBar();
      return;
    }

    // Varsayılan liste her zaman var olsun
    await _customWordService.getOrCreateDefaultList();
    var lists = await _customWordService.getLists();

    if (lists.length == 1) {
      // Tek liste varsa: direkt toggle
      await _toggleSingleList(lists.first.id);
    } else {
      // Birden fazla liste varsa: dialog aç
      await _showAddToListDialog();
    }
  }

  /// Tek listede toggle işlemi
  Future<void> _toggleSingleList(String listId) async {
    if (!mounted) return;

    if (_isSaved) {
      // Listeden çıkar
      await _customWordService.removeWordFromList(widget.word.kelime, listId);
    } else {
      // Listeye ekle
      await _customWordService.addWordFromModel(widget.word, listId);
    }

    // Durumu güncelle
    if (mounted) {
      await _checkSavedStatus();
    }
  }

  Future<void> _showAddToListDialog() async {
    if (!mounted) return;

    var lists = await _customWordService.getLists();
    // Mevcut kelimenin hangi listelerde olduğunu tekrar kontrol et
    final currentSavedLists = await _customWordService.getListsWithWord(
      widget.word.kelime,
    );

    if (!mounted) return;

    if (lists.isEmpty) {
      final defaultList = await _customWordService.getOrCreateDefaultList();
      lists.add(defaultList);
    }

    // Her liste için kelime sayısını al ve sırala (çoktan aza)
    final wordCounts = <String, int>{};
    for (final list in lists) {
      final words = await _customWordService.getWordsByList(list.id);
      wordCounts[list.id] = words.length;
    }

    lists.sort((a, b) {
      final countA = wordCounts[a.id] ?? 0;
      final countB = wordCounts[b.id] ?? 0;
      if (countA != countB) {
        return countB.compareTo(countA); // Çok olan üstte
      }
      return a.createdAt.compareTo(b.createdAt); // Aynıysa eski üstte
    });

    if (!mounted) return;

    // Geçici seçim durumu (UI anlık güncellensin diye)
    // Dialog içinde setState kullanabilmek için StatefulBuilder gerekiyor

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDarkMode = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Listeye Ekle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: lists.length,
                      itemBuilder: (context, index) {
                        final list = lists[index];
                        final isSelected = currentSavedLists.contains(list.id);

                        return ListTile(
                          title: Text(
                            list.name,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          leading: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? const Color(0xFF007AFF)
                                : (isDarkMode ? Colors.grey : Colors.black54),
                          ),
                          onTap: () async {
                            if (isSelected) {
                              // Listeden çıkar
                              await _customWordService.removeWordFromList(
                                widget.word.kelime,
                                list.id,
                              );
                              currentSavedLists.remove(list.id);
                            } else {
                              // Listeye ekle
                              await _customWordService.addWordFromModel(
                                widget.word,
                                list.id,
                              );
                              currentSavedLists.add(list.id);
                            }

                            // Sheet UI güncelle
                            setSheetState(() {});

                            // Ana ekran durumu güncelle
                            if (mounted) {
                              await _checkSavedStatus();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    // Dialog kapandığında son durumu kontrol et
    if (mounted) {
      await _checkSavedStatus();
    }
  }
}
