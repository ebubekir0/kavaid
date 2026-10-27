import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/word_model.dart';
import '../services/saved_words_service.dart';
import '../utils/performance_utils.dart';
import '../services/tts_service.dart';
import '../services/turkce_analytics_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:kavaid/l10n/l10n.dart';

// 🚀 PERFORMANCE: Font stilleri artık doğrudan ve sabit olarak tanımlanıyor.
const TextStyle _arabicTextStyle = TextStyle(
  fontFamily: 'ScheherazadeNew',
  fontSize: 28,
  fontWeight: FontWeight.w700,
  height: 1.5,
  fontFeatures: [
    ui.FontFeature.enable('liga'),
    ui.FontFeature.enable('calt'),
  ],
);

// 🚀 PERFORMANCE: StatelessWidget'a dönüştür ve ValueListenableBuilder kullan
class WordCard extends StatefulWidget {
  final WordModel word;

  const WordCard({
    super.key,
    required this.word,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  final TTSService _ttsService = TTSService();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExpanded = false;
  bool _hasEverExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final savedWordsService = SavedWordsService();
    
    // 🚀 PERFORMANCE: RepaintBoundary ile sarmalama ve key kullanımı
    return RepaintBoundary(
      key: ValueKey('word_card_${widget.word.kelime}'),
      child: Screenshot(
        controller: _screenshotController,
        child: ValueListenableBuilder<bool>(
          valueListenable: savedWordsService.isWordSavedNotifier(widget.word),
          builder: (context, isSaved, child) {
            return GestureDetector(
              onTap: _toggleExpanded,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // 🚀 PERFORMANCE: Gradient kaldırıldı, solid renk kullanıldı
                  color: isDarkMode 
                      ? const Color(0xFF2C2C2E) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode 
                        ? const Color(0xFF3A3A3C)
                        : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                  // 🚀 PERFORMANCE: Shadow optimizasyonu
                  boxShadow: PerformanceUtils.enableShadows ? [
                    BoxShadow(
                      color: isDarkMode 
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                // 🚀 PERFORMANCE: Basitleştirilmiş widget tree
                child: _buildCardContent(isDarkMode, isSaved, savedWordsService),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Future<void> _toggleSaved(SavedWordsService service, bool isSaved) async {
    try {
      // Google hesabı ile giriş zorunluluğu
      if (AuthService().currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.kelimeKaydetmekIcinOnceGiris,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black87,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
        return;
      }
      if (isSaved) {
        await service.removeWord(widget.word);
      } else {
        await service.saveWord(widget.word);
      }
    } catch (e) {
      debugPrint('Toggle saved error: $e');
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
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_hasEverExpanded && _isExpanded) {
        _hasEverExpanded = true;
        // Analytics event gönder
        TurkceAnalyticsService.kelimeDetayiAcildi(widget.word.kelime);
      }
    });
  }
  
  // 🚀 PERFORMANCE: İçeriği ayrı method'a al
  Widget _buildCardContent(bool isDarkMode, bool isSaved, SavedWordsService savedWordsService) {
    final isArabic = LanguageService().isArabic;
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.start : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 🚀 PERFORMANCE: Column boyutunu minimize et
        children: [
          // Ana içerik satırı (Arapça kelime ve sağdaki butonlar)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Kelime ve Butonlar (Dile göre yön değiştirir)
              if (LanguageService().isArabic) ...[
                // Arapça modunda: Kelime sağda, simgeler solda (RTL'de kod sırası ters)
                Expanded(
                  child: Text(
                    widget.word.harekeliKelime ?? widget.word.kelime,
                    style: _arabicTextStyle.copyWith(
                      color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                _buildActions(isSaved, savedWordsService, isDarkMode),
              ] else ...[
                // Türkçe/İngilizce modunda: Kelime solda, simgeler sağda
                Expanded(
                  child: Text(
                    widget.word.harekeliKelime ?? widget.word.kelime,
                    style: _arabicTextStyle.copyWith(
                      color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                _buildActions(isSaved, savedWordsService, isDarkMode),
              ],
            ],
          ),
        
        // Türkçe anlam + harfi_cer bölümü (Tam Genişlikte) - Arapça için sadece anlam göster
        if (widget.word.localizedAnlam != null && widget.word.localizedAnlam!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAnlamWithHarfiCer(isDarkMode),
        ],
      ],
    ),
  );
  }

  Widget _buildActions(bool isSaved, SavedWordsService savedWordsService, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Telaffuz butonu
        IconButton(
          onPressed: _speakArabic,
          icon: Icon(
            Icons.volume_up,
            color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
          ),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),

        // Kaydetme butonu
        IconButton(
          onPressed: () => _toggleSaved(savedWordsService, isSaved),
          icon: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: isSaved
                ? const Color(0xFF007AFF)
                : (isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70)),
          ),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  // Anlam + harfi_cer bölümünü oluştur
  Widget _buildAnlamWithHarfiCer(bool isDarkMode) {
    final sadeAnlam = widget.word.sadeAnlam ?? '';
    final localizedAnlam = widget.word.localizedAnlam ?? '';
    final harfiCerler = widget.word.harfiCerler;

    final textColor = isDarkMode
        ? const Color(0xFF8E8E93)
        : const Color(0xFF6D6D70);
    const harfColor = Color(0xFF007AFF); // Mavi
    const fontSize = 16.5;

    // Arapça modda sadece localizedAnlam göster, harfi cer gösterme
    if (LanguageService().isArabic) {
      if (localizedAnlam.isEmpty) return const SizedBox.shrink();
      
      return RichText(
        text: TextSpan(
          text: localizedAnlam,
          style: TextStyle(fontSize: fontSize, color: textColor, height: 1.5),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        maxLines: _isExpanded ? null : 3,
        overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
      );
    }

    // Türkçe modda harfi cer gösterilir - karakter bozulmasiz
    if (LanguageService().isTurkish) {
      if (sadeAnlam.isEmpty && harfiCerler.isEmpty) return const SizedBox.shrink();
      
      final spans = <InlineSpan>[];
      
      // Sade anlam
      if (sadeAnlam.isNotEmpty) {
        spans.add(TextSpan(
          text: sadeAnlam,
          style: TextStyle(fontSize: fontSize, color: textColor, height: 1.5),
        ));
      }
      
      // Harf-i cerler (Türkçe modunda da göster)
      if (harfiCerler.isNotEmpty) {
        if (!_isExpanded) {
          // Kapaliysa harfler aralarinda boslukla
          final harfsStr = harfiCerler.map((hc) => hc['harf']).where((h) => h != null && h.isNotEmpty).join(' ');
          if (harfsStr.isNotEmpty) {
            spans.add(TextSpan(
              text: sadeAnlam.isEmpty ? harfsStr : ' $harfsStr',
              style: const TextStyle(
                fontSize: fontSize,
                color: harfColor,
                fontWeight: FontWeight.w700,
                fontFamily: 'ScheherazadeNew',
                height: 1.5,
              ),
            ));
          }
        } else {
          // Açiksa detayli gösterim
          for (int i = 0; i < harfiCerler.length; i++) {
            final hc = harfiCerler[i];
            final harf = hc['harf'] ?? '';
            final hcAnlam = hc['anlamlar'] ?? '';
            
            final isFirst = i == 0;
            final prefixText = (isFirst && sadeAnlam.isNotEmpty) ? ', ' : (isFirst ? '' : ', ');

            if (harf.isNotEmpty) {
               spans.add(TextSpan(
                 text: '$prefixText$harf ',
                 style: const TextStyle(fontSize: fontSize, color: harfColor, fontWeight: FontWeight.w700, fontFamily: 'ScheherazadeNew', height: 1.5),
               ));
            }
            if (hcAnlam.isNotEmpty) {
               spans.add(TextSpan(
                 text: hcAnlam,
                 style: TextStyle(fontSize: fontSize, color: textColor, height: 1.5),
               ));
            }
          }
        }
      }

      return RichText(
        text: TextSpan(children: spans),
        textDirection: TextDirection.ltr, // Türkçe için sol->sağ
        textAlign: TextAlign.left,
        maxLines: _isExpanded ? null : 3,
        overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
      );
    }

    // İngilizce modda sadece anlam göster, harfi cer gösterme
    final spans = <InlineSpan>[];

    // 1. Sade anlam
    if (sadeAnlam.isNotEmpty) {
      spans.add(TextSpan(
        text: sadeAnlam,
        style: TextStyle(fontSize: fontSize, color: textColor, height: 1.5),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: _isExpanded ? null : 3,
      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

}

