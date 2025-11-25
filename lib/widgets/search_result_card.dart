import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/word_model.dart';
import '../services/credits_service.dart';
import '../services/admob_service.dart';
import '../utils/performance_utils.dart';
import '../services/tts_service.dart';
import '../services/turkce_analytics_service.dart';
import '../services/auth_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../services/custom_word_service.dart'; // Import for custom lists


// PERFORMANCE: Font'ları cache'le
class _FontCache {
  static TextStyle? _arabicStyle;
  static TextStyle? _exampleArabicStyle;
  
  static TextStyle getArabicStyle() {
    _arabicStyle ??= GoogleFonts.scheherazadeNew(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.4,
      fontFeatures: const [
        ui.FontFeature.enable('liga'),
        ui.FontFeature.enable('calt'),
      ],
    );
    return _arabicStyle!;
  }
  
  static TextStyle getExampleArabicStyle() {
    _exampleArabicStyle ??= GoogleFonts.scheherazadeNew(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black,
      height: 1.4,
      fontFeatures: const [
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
  });

  @override
  State<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<SearchResultCard> with SingleTickerProviderStateMixin { // PERFORMANCE: Single ticker
  final CustomWordService _customWordService = CustomWordService(); // Service instance
  final CreditsService _creditsService = CreditsService();
  final TTSService _ttsService = TTSService();
  final AdMobService _adMobService = AdMobService();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExpanded = false;
  bool _hasEverExpanded = false; // İlk defa açılma durumu için
  
  // Kayıt durumu
  bool _isSaved = false;
  List<String> _savedListIds = []; // Hangi listelerde kayıtlı

  // PERFORMANCE: Animasyon controller'ı lazy-loading ile optimize et
  AnimationController? _animationController;
  Animation<double>? _expandAnimation;
  bool _animationInitialized = false;

  @override
  void initState() {
    super.initState();
    // Animasyonu hemen başlatma - sadece gerektiğinde init et
    // Sadece sözlük görünümündeyse (showRemoveButton false ise) kayıt durumunu kontrol et
    if (!widget.showRemoveButton) {
      _checkSavedStatus();
    }
  }

  Future<void> _checkSavedStatus() async {
    if (!mounted) return;
    final listIds = await _customWordService.getListsWithWord(widget.word.kelime);
    if (!mounted) return;
    setState(() {
      _savedListIds = listIds;
      _isSaved = listIds.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
  
  // PERFORMANCE: Animasyon controller'ı lazy initialize et
  void _initializeAnimation() {
    if (_animationController == null) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 100), // PERFORMANCE: 150ms'den 100ms'ye düşürdüm
        vsync: this,
      );
      
      _expandAnimation = CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic, // PERFORMANCE: Daha smooth curve
        reverseCurve: Curves.easeInCubic,
      );
    }
  }

  void _toggleExpanded() async {
    if (!mounted) return;
    
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();
    
    // Arapça klavyeyi kapatmak için callback'i çağır
    widget.onExpand?.call();
    
    if (!_isExpanded) {
      // Önce hak kontrolü yap - animasyon başlatmadan önce
      final canOpen = await _creditsService.canOpenWord(widget.word.kelime);
      if (!canOpen) {
        // Hak yoksa hiç açılmasın
        if (mounted) {
          // Hak bitti uyarısı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Kelime detayları görüntüleme hakkınız bitti. Premium üyelik alarak sınırsız erişim sağlayabilirsiniz.',
                style: TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Premium Al',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Premium satın alma sayfasına yönlendir
                },
              ),
            ),
          );
        }
        return; // Kartı açma
      }

      // REKLAM TETİKLEYİCİSİ BURAYA EKLENDİ
      _adMobService.onWordCardOpenedAdRequest();
      
      // Hak tüket
      final consumed = await _creditsService.consumeCredit(widget.word.kelime);
      if (!consumed) {
        // Hak tüketilemezse kartı açma
        return;
      }
      
      // İlk defa açılıyorsa işaretle ve analytics event gönder
      if (!_hasEverExpanded) {
        setState(() {
          _hasEverExpanded = true;
        });
        // Analytics event gönder
        await TurkceAnalyticsService.kelimeDetayiAcildi(widget.word.kelime);
      }
      
      // PERFORMANCE: Animasyonu lazy initialize et
      _initializeAnimation();
      
      // Hak var ve tüketildi, şimdi animasyonu başlat
      setState(() {
        _isExpanded = true;
      });
      _animationController!.forward();
      
      // Diğer açık kartları kapatma ve ekranı kaydırma işlevleri kaldırıldı.
      
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
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      // Arama kelimesi yoksa normal text döndür
      return Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDarkMode 
              ? const Color(0xFF8E8E93) 
              : const Color(0xFF6D6D70),
          height: 1.3,
          fontWeight: FontWeight.w400,
        ),
        maxLines: _isExpanded ? null : 2,
        overflow: _isExpanded ? null : TextOverflow.ellipsis,
      );
    }

    // Arama kelimesini case-insensitive bulup vurgula
    final searchTerm = widget.searchQuery!.toLowerCase().trim();
    final lowerText = text.toLowerCase();
    
    List<TextSpan> spans = [];
    int start = 0;
    
    while (start < text.length) {
      int index = lowerText.indexOf(searchTerm, start);
      
      if (index == -1) {
        // Kalan kısmı normal stil ile ekle
        spans.add(TextSpan(
          text: text.substring(start),
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode 
                ? const Color(0xFF8E8E93) 
                : const Color(0xFF6D6D70),
            height: 1.3,
            fontWeight: FontWeight.w400,
          ),
        ));
        break;
      }
      
      // Eşleşmeden önceki kısmı normal stil ile ekle
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode 
                ? const Color(0xFF8E8E93) 
                : const Color(0xFF6D6D70),
            height: 1.3,
            fontWeight: FontWeight.w400,
          ),
        ));
      }
      
      // Eşleşen kısmı vurgulu stil ile ekle
      spans.add(TextSpan(
        text: text.substring(index, index + searchTerm.length),
        style: TextStyle(
          fontSize: 13,
          color: isDarkMode 
              ? Colors.white  // Koyu temada beyaz
              : const Color(0xFF1C1C1E),  // Açık temada siyah
          height: 1.3,
          fontWeight: FontWeight.w700,  // Kalın
          backgroundColor: isDarkMode
              ? const Color(0xFF007AFF).withOpacity(0.25)  // Koyu temada hafif mavi
              : const Color(0xFF007AFF).withOpacity(0.10), // Açık temada çok hafif mavi
        ),
      ));
      
      start = index + searchTerm.length;
    }
    
    return RichText(
      text: TextSpan(children: spans),
      maxLines: _isExpanded ? null : 2,
      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  Future<void> _shareWordCard() async {
    try {
      // Analytics event gönder
      await TurkceAnalyticsService.kelimePaylasildi(widget.word.kelime);
      
      // Kartı genişlet (detayları göster)
      if (!_isExpanded) {
        setState(() {
          _isExpanded = true;
        });
        if (_animationController != null) {
          await _animationController!.forward();
        }
        // UI'nin güncellenmesi için bekle
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // Screenshot al
      final image = await _screenshotController.capture();
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
        text: 'Kavaid - Arapça-Türkçe Sözlük\n\n'
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // PERFORMANCE: RepaintBoundary ve key optimizasyonu
    return RepaintBoundary(
      key: ValueKey('search_card_${widget.word.kelime}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Screenshot(
          controller: _screenshotController,
          child: Container(
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
              boxShadow: (isDarkMode || !PerformanceUtils.enableShadows) ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // PERFORMANCE: Column boyutunu minimize et
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                      Row(
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
                                    color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                                  ),
                                  textDirection: TextDirection.rtl,
                                  // FittedBox ile otomatik ölçeklensin; tek satır görseli korunur
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
                      const SizedBox(height: 4),
                      // Türkçe anlam - arama terimleri vurgulanır
                      if (widget.word.anlam?.isNotEmpty == true) ...[
                        _buildHighlightedText(widget.word.anlam!, isDarkMode),
                      ],
                    ],
                  ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showExpandButton) _buildExpandButton(isDarkMode),
                if (widget.showAddButton || widget.showRemoveButton) _buildActionButton(isDarkMode), // Genel action butonu
                _buildSpeakButton(isDarkMode),
              ],
            ),
          ],
        ),
      ),
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
              color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
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
            color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            size: 20,
          ),
        ),
      ),
    );
  }

  // PERFORMANCE: Genişletilmiş içeriği optimize et
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
          
          // Örnek cümleler
          _buildExampleSentences(isDarkMode),
        ],
      ),
    );
  }

  List<Widget> _buildWordInfoChips(bool isDarkMode) {
    final chips = <Widget>[];

    // Kelime türü chip'i: önce dilbilgiselOzellikler['tur'], yoksa WordModel.tip
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

  Widget _buildRootAndPluralRow(bool isDarkMode) {
    final hasRoot = widget.word.koku?.isNotEmpty == true;
    final hasPlural = widget.word.dilbilgiselOzellikler?.containsKey('cogulForm') == true &&
        widget.word.dilbilgiselOzellikler!['cogulForm']?.toString().trim().isNotEmpty == true;

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
                        : [
                            const Color(0xFFF8F9FA),
                            const Color(0xFFF2F3F5),
                          ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          'Kök',
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
                          style: GoogleFonts.scheherazadeNew(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
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
                        : [
                            const Color(0xFFF8F9FA),
                            const Color(0xFFF2F3F5),
                          ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          'Çoğul',
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
                          widget.word.dilbilgiselOzellikler!['cogulForm'].toString(),
                          style: GoogleFonts.scheherazadeNew(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
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
                    colors: [
                      Color(0xFFF8F9FA),
                      Color(0xFFF2F2F7),
                    ],
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF007AFF).withOpacity(0.15)
                      : const Color(0xFF007AFF).withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: const Text(
                  'Örnek Cümleler',
                  style: TextStyle(
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
                  children: widget.word.ornekCumleler!.take(2).map((example) {
                    final examples = widget.word.ornekCumleler!.take(2).toList();
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
                              style: _FontCache.getExampleArabicStyle().copyWith(
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
                                      ? const Color(0xFF48484A).withOpacity(0.3)
                                      : const Color(0xFFE5E5EA).withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConjugationRow(bool isDarkMode) {
    if (widget.word.fiilCekimler?.isNotEmpty != true) return const SizedBox.shrink();

    final conjugations = <String, String>{};
    final fiilCekimler = widget.word.fiilCekimler!;

    if (fiilCekimler.containsKey('maziForm') &&
        fiilCekimler['maziForm']?.toString().trim().isNotEmpty == true) {
      conjugations['Mazi'] = fiilCekimler['maziForm'].toString();
    }
    if (fiilCekimler.containsKey('muzariForm') &&
        fiilCekimler['muzariForm']?.toString().trim().isNotEmpty == true) {
      conjugations['Müzari'] = fiilCekimler['muzariForm'].toString();
    }
    if (fiilCekimler.containsKey('mastarForm') &&
        fiilCekimler['mastarForm']?.toString().trim().isNotEmpty == true) {
      conjugations['Mastar'] = fiilCekimler['mastarForm'].toString();
    }
    if (fiilCekimler.containsKey('emirForm') &&
        fiilCekimler['emirForm']?.toString().trim().isNotEmpty == true) {
      conjugations['Emir'] = fiilCekimler['emirForm'].toString();
    }

    if (conjugations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: conjugations.entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildConjugationChip(entry.key, entry.value, isDarkMode),
            ),
          );
        }).toList(),
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
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF007AFF),
              letterSpacing: 0.5,
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
                    colors: [
                      Color(0xFFF8F9FA),
                      Color(0xFFF2F2F7),
                    ],
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
              style: GoogleFonts.scheherazadeNew(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? const Color(0xFFE5E5EA) : const Color(0xFF1C1C1E),
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
                colors: [
                  Color(0xFFF8F9FA),
                  Color(0xFFF2F2F7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        color: isDarkMode 
            ? const Color(0xFF2C2C2E)
            : null,
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
            style: GoogleFonts.scheherazadeNew(
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
            style: GoogleFonts.scheherazadeNew(
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
    
    // İkon ve Renkler
    IconData iconData;
    Color iconColor;
    
    if (isRemove) {
      // Listelerim ekranı - Çıkarma butonu (Sade kırmızı çöp kutusu veya eksi)
      iconData = Icons.remove_circle_outline;
      iconColor = const Color(0xFFFF3B30); // Kırmızı
    } else {
      // Sözlük ekranı - Kaydetme butonu (Bookmark)
      if (_isSaved) {
        // Kayıtlı ise dolu bookmark
        iconData = Icons.bookmark;
        iconColor = const Color(0xFF007AFF); // Mavi
      } else {
        // Kayıtlı değilse boş bookmark
        iconData = Icons.bookmark_border;
        iconColor = isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70); // Gri
      }
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isRemove ? widget.onRemove : _showAddToListDialog,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Dokunma alanını genişlet
          child: Icon(
            iconData,
            color: iconColor,
            size: 28, // Belirgin boyut
          ),
        ),
      ),
    );
  }

  Future<void> _showAddToListDialog() async {
    if (!mounted) return;
    
    final lists = await _customWordService.getLists();
    // Mevcut kelimenin hangi listelerde olduğunu tekrar kontrol et
    final currentSavedLists = await _customWordService.getListsWithWord(widget.word.kelime);
    
    if (!mounted) return;

    if (lists.isEmpty) {
        final defaultList = await _customWordService.createList('Kaydedilenler');
        lists.add(defaultList);
    }

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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                          color: isDarkMode ? Colors.white : Colors.black
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
                          title: Text(list.name, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? const Color(0xFF007AFF) : (isDarkMode ? Colors.grey : Colors.black54)
                          ),
                          onTap: () async {
                            if (isSelected) {
                              // Listeden çıkar
                              await _customWordService.removeWordFromList(widget.word.kelime, list.id);
                              currentSavedLists.remove(list.id);
                            } else {
                              // Listeye ekle
                              await _customWordService.addWordFromModel(widget.word, list.id);
                              currentSavedLists.add(list.id);
                            }
                            
                            // Sheet UI güncelle
                            setSheetState(() {});
                            
                            // Ana ekran durumu güncelle
                            if (mounted) {
                                _checkSavedStatus();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
    // Dialog kapandığında son durumu kontrol et
    if (mounted) {
      _checkSavedStatus();
    }
  }
}