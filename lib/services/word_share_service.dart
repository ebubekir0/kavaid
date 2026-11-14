import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kavaid/l10n/l10n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/embedded_words.dart';
import '../models/word_model.dart';
import '../widgets/word_share_card.dart';
import 'arabic_definitions.dart';
import 'turkce_analytics_service.dart';

/// Kelime kartını paylaşır: önce önizleme (arka plan seçimi), sonra durum biçiminde bir görsel
/// (WordShareCard, 1080x1920) ve altında kelime, anlam ve kelimenin kavaid.app'teki sayfası.
///
/// Görsel üretilemezse (eski cihaz, bellek) yalnız metin paylaşılır; paylaşım hiçbir
/// durumda görsel yüzünden başarısız olmaz.
class WordShareService {
  WordShareService._();

  static const String siteOrigin = 'https://kavaid.app';
  static const String _backgroundPref = 'share_card_background';

  // Sitedeki slugOf ile aynı kurallar (site/src/lib/arabic.js): harekeler ve uzatma
  // çizgisi silinir, Farsça ک/ی Arapçaya çevrilir, harf olmayanlar boşluk sayılır.
  static final RegExp _marks = RegExp(r'[ً-ٰٟـ]');
  static final RegExp _notArabicLetter =
      RegExp(r'[^ء-يٮ-ۓ\s]');
  static final RegExp _arabic = RegExp(r'[؀-ۿ]');
  static final RegExp _spaces = RegExp(r'\s+');

  /// Kartın başlığı: varsa harekeli yazılış.
  static String headwordOf(WordModel word) =>
      word.harekeliKelime?.trim().isNotEmpty == true
          ? word.harekeliKelime!.trim()
          : word.kelime.trim();

  /// Sitedeki kelime sayfasının adres parçası: harekesiz yazılış, boşluklar tire.
  static String slugOf(String word) => word
      .replaceAll(_marks, '')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ک', 'ك')
      .replaceAll('ی', 'ي')
      .replaceAll(_notArabicLetter, ' ')
      .trim()
      .replaceAll(_spaces, '-');

  /// Kelimenin sitedeki sayfası. Sözlük dili sitenin dil yoluyla aynıdır
  /// (tr, en, ar, id, ms, ur). `ref=app` sitede iki işe yarar: uygulamadan gelen
  /// ziyaret ayırt edilir ve sayfası olmayan kelimede arama sonucuna yönlendirilir.
  static String urlOf(WordModel word) {
    final lang = EmbeddedWords.currentLang;
    final headword = headwordOf(word);
    final slug = slugOf(_arabic.hasMatch(headword) ? headword : word.kelime);
    if (slug.isEmpty) return '$siteOrigin/$lang';
    return '$siteOrigin/$lang/word/${Uri.encodeComponent(slug)}?ref=app';
  }

  /// Paylaşılacak anlam: Arapça sözlükte ilk tanım, diğer dillerde sade anlam.
  static String meaningOf(WordModel word) {
    final entry = ArabicDefinitions.instance.of(word);
    final senses = entry?['senses'];
    if (senses is List && senses.isNotEmpty) {
      final first = senses.first;
      if (first is Map) {
        final definition = first['d']?.toString().trim() ?? '';
        if (definition.isNotEmpty) return definition;
      }
    }
    return word.sadeAnlam?.trim() ?? '';
  }

  static Future<ShareBackground> _savedBackground() async {
    final name = (await SharedPreferences.getInstance()).getString(_backgroundPref);
    return ShareBackground.values.firstWhere(
      (b) => b.name == name,
      orElse: () => ShareBackground.dusk,
    );
  }

  /// Önizleme sayfasını açar; kullanıcı arka plan seçip "Paylaş"a basınca paylaşır.
  static Future<void> share(BuildContext context, WordModel word) async {
    final background = await _savedBackground();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SharePreviewSheet(word: word, initialBackground: background),
    );
  }

  /// Görseli seçilen arka planla üretip sistem paylaşım penceresini açar. [context] paylaşım
  /// düğmesinin bağlamı olmalı: iPad'de pencere o düğmeye bağlanır.
  static Future<void> shareAsImage(
    BuildContext context,
    WordModel word,
    ShareBackground background,
  ) async {
    final headword = headwordOf(word);
    final meaning = meaningOf(word);
    final url = urlOf(word);
    final text =
        meaning.isEmpty ? '$headword\n$url' : '$headword: $meaning\n$url';

    final renderObject = context.findRenderObject();
    final Rect? origin = renderObject is RenderBox && renderObject.hasSize
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    TurkceAnalyticsService.kelimePaylasildi(word.kelime);
    (await SharedPreferences.getInstance()).setString(_backgroundPref, background.name);

    XFile? image;
    try {
      // Arka plan görseli yakalamadan önce çözülmüş olmalı; yoksa görsel boş çıkar.
      if (context.mounted) await precacheImage(AssetImage(background.asset), context);
      // 3x çözünürlük: 1080x1920. Boyut açıkça verilir: verilmezse ekran boyutuyla sınırlanır
      // ve küçük ekranlı telefonlarda kart sıkışır.
      final bytes = await ScreenshotController().captureFromWidget(
        WordShareCard(
          word: word,
          meaning: meaning,
          meaningLang: EmbeddedWords.currentLang,
          background: background,
        ),
        context: context.mounted ? context : null,
        pixelRatio: 3,
        targetSize: const Size(WordShareCard.width, WordShareCard.height),
        delay: const Duration(milliseconds: 150),
      );
      // Ad her seferinde değişir: bazı uygulamalar aynı adlı dosyanın eski önizlemesini gösterir.
      final directory = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/kavaid_$stamp.png');
      await file.writeAsBytes(bytes, flush: true);
      image = XFile(file.path, mimeType: 'image/png');
    } catch (e) {
      debugPrint('⚠️ [WordShare] Görsel üretilemedi, yalnız metin paylaşılıyor: $e');
    }

    if (image != null) {
      await Share.shareXFiles([image], text: text, sharePositionOrigin: origin);
    } else {
      await Share.share(text, sharePositionOrigin: origin);
    }
  }
}

/// Paylaşmadan önce kartın önizlemesi ve arka plan seçimi.
class _SharePreviewSheet extends StatefulWidget {
  const _SharePreviewSheet({required this.word, required this.initialBackground});

  final WordModel word;
  final ShareBackground initialBackground;

  @override
  State<_SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<_SharePreviewSheet> {
  late ShareBackground _background = widget.initialBackground;
  bool _busy = false;

  Future<void> _share(BuildContext buttonContext) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await WordShareService.shareAsImage(buttonContext, widget.word, _background);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ [WordShare] Paylaşım hatası: $e');
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paylasimSirasindaBirHataOlustu)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final maxPreviewHeight = MediaQuery.sizeOf(context).height * 0.56;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.kelimeyiPaylas,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          // Önizleme: paylaşılacak görselin aynısı, küçültülmüş
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxPreviewHeight),
            child: AspectRatio(
              aspectRatio: WordShareCard.width / WordShareCard.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 14, offset: Offset(0, 3))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: FittedBox(
                    child: WordShareCard(
                      key: ValueKey(_background),
                      word: widget.word,
                      meaning: WordShareService.meaningOf(widget.word),
                      meaningLang: EmbeddedWords.currentLang,
                      background: _background,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Arka plan seçimi: küçük dikey resimler
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: ShareBackground.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final background = ShareBackground.values[index];
                return _BackgroundThumb(
                  background: background,
                  selected: background == _background,
                  onTap: () => setState(() => _background = background),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Builder(
              builder: (buttonContext) => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  key: const ValueKey('share-confirm'),
                  onPressed: _busy ? null : () => _share(buttonContext),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share_rounded, size: 20),
                  label: Text(l10n.paylas),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    // styleFrom'daki textStyle temanın fontunu devralmaz; açıkça verilir.
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontFamilyFallback: ['ScheherazadeNew'],
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundThumb extends StatelessWidget {
  const _BackgroundThumb({required this.background, required this.selected, required this.onTap});

  final ShareBackground background;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('bg-${background.name}'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 50,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF007AFF) : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(background.asset, fit: BoxFit.cover, cacheWidth: 150),
        ),
      ),
    );
  }
}
