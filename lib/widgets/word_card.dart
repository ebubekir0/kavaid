import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../models/word_model.dart';
import '../services/saved_words_service.dart';
import '../utils/performance_utils.dart';
import '../services/tts_service.dart';
import '../services/turkce_analytics_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

const TextStyle _exampleArabicTextStyle = TextStyle(
  fontFamily: 'ScheherazadeNew',
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.6,
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
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
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
                LanguageService().isEnglish 
                    ? 'Log in first to save words' 
                    : (LanguageService().isArabic ? 'سجل الدخول أولاً لحفظ الكلمات' : 'Kelime kaydetmek için önce giriş yapın'),
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
      print('Toggle saved error: $e');
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
  
  Future<void> _shareWordCard() async {
    try {
      // Analytics event gönder
      await TurkceAnalyticsService.kelimePaylasildi(widget.word.kelime);
      
      // Tüm detayları göster
      if (!_isExpanded) {
        setState(() {
          _isExpanded = true;
        });
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
      
      String shareText = 'Kavaid - Arapça-Türkçe Sözlük\n\n'
          '${widget.word.harekeliKelime ?? widget.word.kelime}\n';
      
      final sade = widget.word.sadeAnlam ?? '';
      if (sade.isNotEmpty) {
        shareText += '$sade\n';
      } else if (widget.word.localizedAnlam != null) {
        shareText += '${widget.word.localizedAnlam}\n';
      }
      
      for (final hc in widget.word.harfiCerler) {
        final h = hc['harf'] ?? '';
        final a = hc['anlamlar'] ?? '';
        if (h.isNotEmpty) {
          shareText += '($h) $a\n';
        }
      }

      // Paylaş
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareText.trim(),
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

  // 🚀 PERFORMANCE: Örnek cümle bölümünü ayrı widget olarak optimize et
  Widget _buildExampleSection(bool isDarkMode) {
    // Debug: Örnek cümle içeriğini kontrol et
    debugPrint('📚 WordCard Örnek Cümle Kontrolü:');
    debugPrint('  - Örnek sayısı: ${widget.word.ornekler.length}');
    if (widget.word.ornekler.isNotEmpty) {
      debugPrint('  - arapcaCumle: "${widget.word.ornekler.first.arapcaCumle}"');
      debugPrint('  - turkceCeviri: "${widget.word.ornekler.first.turkceCeviri}"');
    }
    
    // Örnek cümle yoksa veya Arapça cümle boşsa gösterme
    if (widget.word.ornekler.isEmpty || 
        widget.word.ornekler.first.arapcaCumle.trim().isEmpty) {
      debugPrint('⚠️ WordCard: Arapça örnek cümle boş veya yok');
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        
        // Örnek cümle başlığı - 🚀 PERFORMANCE: const widget kullan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF007AFF).withOpacity(0.1)
                : const Color(0xFF007AFF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            LanguageService().isEnglish 
                ? 'Example Sentence' 
                : (LanguageService().isArabic ? 'جملة مثال' : 'Örnek Cümle'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF007AFF),
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 🚀 PERFORMANCE: RepaintBoundary ile örnek cümle container'ını izole et
        RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF1C1C1E).withOpacity(0.5)
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode 
                    ? const Color(0xFF3A3A3C).withOpacity(0.5)
                    : const Color(0xFFE5E5EA).withOpacity(0.5),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Arapça örnek cümle - 🚀 PERFORMANCE: Sabit font stili kullan
                Text(
                  widget.word.ornekler.first.arapcaCumle,
                  textDirection: TextDirection.rtl,
                  style: _exampleArabicTextStyle.copyWith(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF1C1C1E),
                  ),
                ),
                
                // Türkçe veya İngilizce çeviri
                if (widget.word.ornekler.first.localizedCeviri.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.word.ornekler.first.localizedCeviri,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode 
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}

// Özellik chip'leri
class _FeatureChips extends StatelessWidget {
  final Map<String, dynamic> features;
  final bool isDarkMode;

  const _FeatureChips({
    required this.features,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.entries
          .where((entry) => entry.key != 'cogulForm')
          .map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF3A3A3C).withOpacity(0.8)
                : const Color(0xFFE8F0FF), // Daha mavi tonlu chip arka planı
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode 
                  ? const Color(0xFF48484A)
                  : const Color(0xFFB8D4F5), // Daha mavi tonlu kenar
              width: 0.7,
            ),
            boxShadow: [
              if (!isDarkMode) ...[
                BoxShadow(
                  color: const Color(0xFF007AFF).withOpacity(0.05), // Mavi gölge
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 1,
                  offset: const Offset(0, -0.5),
                ),
              ],
            ],
          ),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(
              fontSize: 14, // 13'ten 14'e büyüttüm
              color: isDarkMode 
                  ? const Color(0xFFE5E5EA)
                  : const Color(0xFF2C5AA0), // Daha belirgin mavi metin
              fontWeight: FontWeight.w600, // w500'den w600'e
              letterSpacing: 0.3,
            ),
          ),
        );
      }).toList(),
    );
  }
} 