import 'package:flutter/material.dart';
import 'emsile_bottom_sheet.dart';
import '../utils/dictionary_mode_notifier.dart';
import 'dart:ui' as ui;
import '../models/word_model.dart';
import '../services/credits_service.dart';
import '../services/admob_service.dart';
import '../utils/performance_utils.dart';
import '../services/tts_service.dart';
import '../services/turkce_analytics_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../services/custom_word_service.dart'; // Import for custom lists
import '../services/emsile_database_service.dart';
import 'ai_teacher_sheet.dart';

// PERFORMANCE: Font'ları cache'le — GoogleFonts yerine yerleşik fontFamily kullan
// GoogleFonts.scheherazadeNew() internetten indirme deniyordu, yerel font zaten assets/fonts/ içinde
class _FontCache {
  static TextStyle? _arabicStyle;
  static TextStyle? _exampleArabicStyle;

  static TextStyle getArabicStyle() {
    _arabicStyle ??= const TextStyle(
      fontFamily: 'ScheherazadeNew',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.4,
      fontFeatures: [
        ui.FontFeature.enable('liga'),
        ui.FontFeature.enable('calt'),
      ],
    );
    return _arabicStyle!;
  }

  static TextStyle getExampleArabicStyle() {
    _exampleArabicStyle ??= const TextStyle(
      fontFamily: 'ScheherazadeNew',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black,
      height: 1.4,
      fontFeatures: [
        ui.FontFeature.enable('liga'),
        ui.FontFeature.enable('calt'),
      ],
    );
    return _exampleArabicStyle!;
  }
}

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
  static const bool _aiTeacherFeatureEnabled = false;

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
  bool _animationInitialized = false;
  Future<Map<String, dynamic>?>? _emsileLookupFuture;
  String? _emsileLookupMazi;
  Timer? _savedStatusTimer;

  StreamSubscription<void>? _wordChangeSubscription;

  bool get _shouldShowAiTeacherButton =>
      _aiTeacherFeatureEnabled &&
      widget.showAiTeacherButton &&
      widget.showAddButton &&
      !widget.showRemoveButton;

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

  // Arama kelimesini vurgulamak için RichText oluştur
  Widget _buildHighlightedText(String text, bool isDarkMode) {
    List<InlineSpan> spans = [];
    final textColor = isDarkMode
        ? const Color(0xFF8E8E93)
        : const Color(0xFF6D6D70);
    const fontSize = 14.5;

    // Eğer kelime aranmadıysa veya boş ise sadece ana anlam
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            color: textColor,
            height: 1.3,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    } else {
      // Vurgulama
      final searchTerm = widget.searchQuery!.toLowerCase().trim();
      final lowerText = text.toLowerCase();
      int start = 0;

      while (start < text.length) {
        int index = lowerText.indexOf(searchTerm, start);
        if (index == -1) {
          spans.add(
            TextSpan(
              text: text.substring(start),
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
          break;
        }
        if (index > start) {
          spans.add(
            TextSpan(
              text: text.substring(start, index),
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }
        spans.add(
          TextSpan(
            text: text.substring(index, index + searchTerm.length),
            style: TextStyle(
              fontSize: fontSize,
              color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
              height: 1.3,
              fontWeight: FontWeight.w700,
              backgroundColor: isDarkMode
                  ? const Color(0x40007AFF) // 0xFF007AFF @ 0.25
                  : const Color(0x1A007AFF), // 0xFF007AFF @ 0.10
            ),
          ),
        );
        start = index + searchTerm.length;
      }
    }

    // Harfi cerleri aynı büyüklükte satır içinden devam ettir - Arapça için gösterme
    if (widget.word.harfiCerler.isNotEmpty && !LanguageService().isArabic) {
      if (!_isExpanded) {
        // Kapalıysa sadece harfler aralarında boşlukla eklenecek (virgül yok)
        final harfsStr = widget.word.harfiCerler
            .map((hc) => hc['harf'])
            .where((h) => h != null && h.isNotEmpty)
            .join(' ');
        if (harfsStr.isNotEmpty) {
          spans.add(
            TextSpan(
              text: text.isEmpty ? harfsStr : ' $harfsStr',
              style: const TextStyle(
                fontSize: fontSize,
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w700,
                fontFamily: 'ScheherazadeNew',
                height: 1.3,
              ),
            ),
          );
        }
      } else {
        // Açıksa hepsi satır içi akacak, aralara virgül eklenecek
        for (int i = 0; i < widget.word.harfiCerler.length; i++) {
          final hc = widget.word.harfiCerler[i];
          final harf = hc['harf'] ?? '';
          final anlam = hc['anlamlar'] ?? '';

          final isFirst = i == 0;
          final prefixText = (isFirst && text.isNotEmpty)
              ? ', '
              : (isFirst ? '' : ', ');

          if (harf.isNotEmpty) {
            spans.add(
              TextSpan(
                text: '$prefixText$harf ',
                style: const TextStyle(
                  fontSize: fontSize,
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'ScheherazadeNew',
                  height: 1.3,
                ),
              ),
            );
          }
          if (anlam.isNotEmpty) {
            spans.add(
              TextSpan(
                text: anlam,
                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }
        }
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: _isExpanded ? null : 3,
      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  Future<void> _shareWordCard() async {
    try {
      // Analytics event gönder
      await TurkceAnalyticsService.kelimePaylasildi(widget.word.kelime);

      if (_screenshotController == null) {
        setState(() {
          _screenshotController = ScreenshotController();
        });
        await WidgetsBinding.instance.endOfFrame;
      }

      // Kartı genişlet (detayları göster)
      if (!_isExpanded) {
        _initializeAnimation();
        setState(() {
          _isExpanded = true;
        });
        await _animationController!.forward();
        // UI'nin güncellenmesi için bekle
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Screenshot al — controller build() sırasında lazy oluşturulmuş olacak
      final image = await _screenshotController!.capture();
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paylaşım için görüntü alınamadı'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Geçici dosya oluştur
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/kavaid_${widget.word.kelime}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      // Paylaş
      await Share.shareXFiles(
        [XFile(imagePath)],
        text:
            'Kavaid - Arapça-Türkçe Sözlük\n\n'
            '${widget.word.harekeliKelime ?? widget.word.kelime}\n'
            '${widget.word.anlam ?? ""}',
      );

      // Geçici dosyayı temizle
      try {
        await imageFile.delete();
      } catch (_) {}
    } catch (e) {
      debugPrint('Paylaşım hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paylaşım başarısız oldu'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
            // Üst Satır: Arapça Kelime, Tür Bilgisi (Chips) ve Sağda Butonlar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Arapça için: Simgeler solda, kelime sağda (en sağda)
                if (LanguageService().isArabic) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showExpandButton)
                        _buildExpandButton(isDarkMode),
                      if (_shouldShowAiTeacherButton)
                        _buildAiTeacherButton(isDarkMode),
                      _buildSpeakButton(isDarkMode),
                      if (widget.showAddButton || widget.showRemoveButton)
                        _buildActionButton(isDarkMode),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Kelime türü chip'i
                        Flexible(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _buildWordInfoChips(isDarkMode),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // PERFORMANCE: Cache'lenmiş font stili
                        Flexible(
                          child: Container(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                widget.word.harekeliKelime?.isNotEmpty == true
                                    ? widget.word.harekeliKelime!
                                    : widget.word.kelime,
                                style: _FontCache.getArabicStyle().copyWith(
                                  color: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1C1C1E),
                                ),
                                textDirection: TextDirection.rtl,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Türkçe/İngilizce için: Kelime solda, simgeler sağda
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // PERFORMANCE: Cache'lenmiş font stili
                        Flexible(
                          child: Container(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                widget.word.harekeliKelime?.isNotEmpty == true
                                    ? widget.word.harekeliKelime!
                                    : widget.word.kelime,
                                style: _FontCache.getArabicStyle().copyWith(
                                  color: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1C1C1E),
                                ),
                                textDirection: TextDirection.rtl,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Kelime türü chip'i
                        Flexible(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _buildWordInfoChips(isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showExpandButton)
                        _buildExpandButton(isDarkMode),
                      if (_shouldShowAiTeacherButton)
                        _buildAiTeacherButton(isDarkMode),
                      _buildSpeakButton(isDarkMode),
                      if (widget.showAddButton || widget.showRemoveButton)
                        _buildActionButton(isDarkMode),
                    ],
                  ),
                ],
              ],
            ),

            // Türkçe anlam ve Harficerler - Tam Genişlikte (Full Width)
            if (widget.word.sadeAnlam?.isNotEmpty == true ||
                widget.word.harfiCerler.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildHighlightedText(widget.word.sadeAnlam ?? '', isDarkMode),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHarfiCerList(bool isDarkMode) {
    final harfiCerler = widget.word.harfiCerler;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: harfiCerler.map((hc) {
        final harf = hc['harf'] ?? '';
        final hmAnlam = hc['anlamlar'] ?? '';
        if (harf.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: harf,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'ScheherazadeNew',
                  ),
                ),
                const TextSpan(text: ' '),
                if (hmAnlam.isNotEmpty)
                  TextSpan(
                    text: hmAnlam,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                      height: 1.3,
                    ),
                  ),
              ],
            ),
            maxLines: _isExpanded ? null : 1,
            overflow: _isExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
        );
      }).toList(),
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

  Widget _buildAiTeacherButton(bool isDarkMode) {
    return Tooltip(
      message: 'AI Kelime Asistanı',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAiTeacherSheet,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: const Color(0xFF007AFF),
              size: 19,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreAiExamplesButton(bool isDarkMode) {
    final fg = const Color(0xFF007AFF);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            _showAiTeacherSheet(initialMode: AiTeacherInitialMode.moreExamples),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDarkMode
                ? fg.withOpacity(0.12)
                : const Color(0xFF007AFF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? fg.withOpacity(0.35) : fg.withOpacity(0.22),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                'Daha fazla örnek',
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiTeacherSheet({
    AiTeacherInitialMode initialMode = AiTeacherInitialMode.overview,
  }) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AiTeacherSheet(
        word: widget.word,
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
        initialMode: initialMode,
      ),
    );
  }

  List<Widget> _buildWordInfoChips(bool isDarkMode) {
    final chips = <Widget>[];

    // Kelime türü chip'i: Sadece Türkçe için göster
    if (!LanguageService().isTurkish) return chips;

    String? typeText;
    if (widget.word.dilbilgiselOzellikler?.containsKey('tur') == true) {
      typeText = widget.word.dilbilgiselOzellikler!['tur']?.toString();
    } else if (widget.word.tip?.isNotEmpty == true) {
      typeText = widget.word.tip;
    }

    if (typeText != null && typeText!.trim().isNotEmpty) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF007AFF).withOpacity(0.2)
                : const Color(0xFF007AFF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF007AFF).withOpacity(0.3)
                  : const Color(0xFF007AFF).withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            typeText!,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? const Color(0xFF007AFF)
                  : const Color(0xFF007AFF).withOpacity(0.9),
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
    }

    return chips;
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

          // Kök ve çoğul bilgileri (yan yana, sadece varsa göster)
          _buildRootAndPluralRow(isDarkMode),

          // Fiil çekimleri (yan yana, sadece varsa göster)
          _buildConjugationRow(isDarkMode),

          // Emsile (fiil çekimleri tablosu) butonu - Arapça için gösterme
          if (!LanguageService().isArabic) _buildEmsileButton(isDarkMode),

          // Örnek cümleler - Arapça için gösterme
          if (!LanguageService().isArabic) _buildExampleSentences(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildRootAndPluralRow(bool isDarkMode) {
    final hasRoot = widget.word.koku?.isNotEmpty == true;
    final hasPlural =
        widget.word.dilbilgiselOzellikler?.containsKey('cogulForm') == true &&
        widget.word.dilbilgiselOzellikler!['cogulForm']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true;

    if (!hasRoot && !hasPlural) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (hasRoot) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            const Color(0xFF2C2C2E),
                            const Color(0xFF2C2C2E).withOpacity(0.8),
                          ]
                        : [const Color(0xFFF8F9FA), const Color(0xFFF2F3F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF48484A).withOpacity(0.5)
                        : const Color(0xFFD0D0D0),
                    width: 0.8,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF8E8E93).withOpacity(0.2)
                              : const Color(0xFF007AFF).withOpacity(0.08),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(9),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Text(
                          LanguageService().isEnglish
                              ? 'Root'
                              : (LanguageService().isArabic ? 'جذر' : 'Kök'),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF007AFF).withOpacity(0.8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 26, 8, 8),
                      child: Center(
                        child: Text(
                          widget.word.koku!,
                          style: TextStyle(
                            fontFamily: 'ScheherazadeNew',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1C1C1E),
                            height: 1.2,
                            fontFeatures: const [
                              ui.FontFeature.enable('liga'),
                              ui.FontFeature.enable('calt'),
                            ],
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (hasRoot && hasPlural) const SizedBox(width: 8),
          if (hasPlural) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            const Color(0xFF2C2C2E),
                            const Color(0xFF2C2C2E).withOpacity(0.8),
                          ]
                        : [const Color(0xFFF8F9FA), const Color(0xFFF2F3F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF48484A).withOpacity(0.5)
                        : const Color(0xFFD0D0D0),
                    width: 0.8,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF8E8E93).withOpacity(0.2)
                              : const Color(0xFF007AFF).withOpacity(0.08),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(9),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Text(
                          LanguageService().isEnglish
                              ? 'Plural'
                              : (LanguageService().isArabic ? 'جمع' : 'Çoğul'),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF007AFF).withOpacity(0.8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 26, 8, 8),
                      child: Center(
                        child: Text(
                          widget.word.dilbilgiselOzellikler!['cogulForm']
                              .toString(),
                          style: TextStyle(
                            fontFamily: 'ScheherazadeNew',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1C1C1E),
                            height: 1.2,
                            fontFeatures: const [
                              ui.FontFeature.enable('liga'),
                              ui.FontFeature.enable('calt'),
                            ],
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExampleSentences(bool isDarkMode) {
    if (widget.word.ornekCumleler?.isNotEmpty != true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFF8F9FA), Color(0xFFF2F2F7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            color: isDarkMode ? const Color(0xFF2C2C2E) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF48484A).withOpacity(0.5)
                  : const Color(0xFFD0D0D0),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isDarkMode ? 4 : 6,
                offset: Offset(0, isDarkMode ? 2 : 2),
                spreadRadius: isDarkMode ? 0 : 0.3,
              ),
              if (!isDarkMode) ...[
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                  spreadRadius: 0,
                ),
              ],
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF007AFF).withOpacity(0.15)
                      : const Color(0xFF007AFF).withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: Text(
                  LanguageService().isEnglish
                      ? 'Example Sentences'
                      : 'Örnek Cümleler',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF007AFF),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ...widget.word.ornekCumleler!.take(2).map((example) {
                      final examples = widget.word.ornekCumleler!
                          .take(2)
                          .toList();
                      final isLast = example == examples.last;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (example['arapcaCumle'] != null ||
                              example['arapcaCümle'] != null ||
                              example['arapca'] != null) ...[
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                (example['arapcaCumle'] ??
                                        example['arapcaCümle'] ??
                                        example['arapca'] ??
                                        '')
                                    .toString(),
                                style: _FontCache.getExampleArabicStyle()
                                    .copyWith(
                                      color: isDarkMode
                                          ? const Color(0xFFE5E5EA)
                                          : const Color(0xFF1C1C1E),
                                    ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            example['turkceAnlam']?.toString() ??
                                example['turkceCeviri']?.toString() ??
                                example['turkce']?.toString() ??
                                example.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6D6D70),
                              height: 1.4,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (!isLast) ...[
                            const SizedBox(height: 12),
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    isDarkMode
                                        ? const Color(
                                            0xFF48484A,
                                          ).withOpacity(0.3)
                                        : const Color(
                                            0xFFE5E5EA,
                                          ).withOpacity(0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }),
                    if (_shouldShowAiTeacherButton) ...[
                      const SizedBox(height: 12),
                      _buildMoreAiExamplesButton(isDarkMode),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
    if (widget.word.fiilCekimler?.isNotEmpty != true)
      return const SizedBox.shrink();

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
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            emsileBlue.withOpacity(0.15),
                            emsileBlue.withOpacity(0.08),
                          ]
                        : [
                            emsileBlue.withOpacity(0.10),
                            emsileBlue.withOpacity(0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDarkMode
                        ? emsileBlue.withOpacity(0.4)
                        : emsileBlue.withOpacity(0.3),
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
                      color: emsileBlue.withOpacity(0.6),
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

  Widget _buildConjugationRow(bool isDarkMode) {
    if (widget.word.fiilCekimler?.isNotEmpty != true)
      return const SizedBox.shrink();

    final conjugations = <String, String>{};
    final fiilCekimler = widget.word.fiilCekimler!;

    if (fiilCekimler.containsKey('maziForm') &&
        fiilCekimler['maziForm']?.toString().trim().isNotEmpty == true) {
      conjugations[LanguageService().isEnglish
              ? 'Past'
              : (LanguageService().isArabic ? 'ماضي' : 'Mazi')] =
          fiilCekimler['maziForm'].toString();
    }
    if (fiilCekimler.containsKey('muzariForm') &&
        fiilCekimler['muzariForm']?.toString().trim().isNotEmpty == true) {
      conjugations[LanguageService().isEnglish
              ? 'Present'
              : (LanguageService().isArabic ? 'مضارع' : 'Müzari')] =
          fiilCekimler['muzariForm'].toString();
    }
    if (fiilCekimler.containsKey('mastarForm') &&
        fiilCekimler['mastarForm']?.toString().trim().isNotEmpty == true) {
      conjugations[LanguageService().isEnglish
              ? 'Infinitive'
              : (LanguageService().isArabic ? 'مصدر' : 'Mastar')] =
          fiilCekimler['mastarForm'].toString();
    }
    if (fiilCekimler.containsKey('emirForm') &&
        fiilCekimler['emirForm']?.toString().trim().isNotEmpty == true) {
      conjugations[LanguageService().isEnglish
              ? 'Imperative'
              : (LanguageService().isArabic ? 'أمر' : 'Emir')] =
          fiilCekimler['emirForm'].toString();
    }

    if (conjugations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Directionality(
        textDirection: LanguageService().isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Row(
          children: conjugations.entries.map((entry) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildConjugationChip(
                  entry.key,
                  entry.value,
                  isDarkMode,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildConjugationChip(String title, String text, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Başlık
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF007AFF).withOpacity(0.15)
                : const Color(0xFF007AFF).withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF007AFF),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // Arapça metin için kutu
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFF8F9FA), Color(0xFFF2F2F7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            color: isDarkMode ? const Color(0xFF2C2C2E) : null,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF48484A).withOpacity(0.5)
                  : const Color(0xFFD0D0D0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'ScheherazadeNew',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? const Color(0xFFE5E5EA)
                    : const Color(0xFF1C1C1E),
                height: 1.4,
                fontFeatures: const [
                  ui.FontFeature.enable('liga'),
                  ui.FontFeature.enable('calt'),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String title, String content, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? null
            : const LinearGradient(
                colors: [Color(0xFFF8F9FA), Color(0xFFF2F2F7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        color: isDarkMode ? const Color(0xFF2C2C2E) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF48484A).withOpacity(0.3)
              : const Color(0xFFD0D0D0),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: isDarkMode ? 4 : 5,
            offset: Offset(0, isDarkMode ? 2 : 1),
            spreadRadius: isDarkMode ? 0 : 0.2,
          ),
          if (!isDarkMode) ...[
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 1,
              offset: const Offset(0, -0.5),
              spreadRadius: 0,
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'ScheherazadeNew',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? const Color(0xFF007AFF)
                  : const Color(0xFF6D6D70),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'ScheherazadeNew',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? const Color(0xFFE5E5EA)
                  : const Color(0xFF1C1C1E),
              fontFeatures: const [
                ui.FontFeature.enable('liga'),
                ui.FontFeature.enable('calt'),
              ],
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ],
      ),
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
