import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kavaid/l10n/l10n.dart';

import '../models/word_model.dart';
import '../utils/word_type_label.dart';
import 'search_result_card_parts.dart' show cleanRoot;

const _arabicFeatures = [
  ui.FontFeature.enable('liga'),
  ui.FontFeature.enable('calt'),
];

/// Paylaşım kartının arka planları (assets/share_backgrounds). Görseller Cloudflare Workers AI
/// (FLUX.2 klein, 768x1344) ile üretildi; üretim istemleri store_listing/PAYLASIM_KARTI.md'de.
///
/// [lightText]: arka plan koyu, yazı beyaz. [textY]: yazı bloğunun dikey yeri (-1 üst, 1 alt);
/// sahnenin boş kısmına (gökyüzü, kâğıdın ortası) denk gelecek şekilde ayarlandı.
/// [brandBottom]: kavaid.app imzasının alttan uzaklığı; sahnede altta bir şey varsa (cami) yukarıda.
enum ShareBackground {
  dusk('dusk', lightText: true, accent: Color(0xFFF4CF96), textY: -0.16, brandBottom: 104),
  night('night', lightText: true, accent: Color(0xFFE9C46A), textY: -0.02),
  emerald('emerald', lightText: true, accent: Color(0xFFE9C46A), textY: 0.0),
  desert('desert', lightText: false, accent: Color(0xFF9A5B34), textY: -0.18),
  sea('sea', lightText: false, accent: Color(0xFF6E5FA8), textY: -0.2),
  flowers('flowers', lightText: false, accent: Color(0xFFB4626F), textY: 0.0),
  parchment('parchment', lightText: false, accent: Color(0xFF8C6A2E), textY: 0.0),
  olive('olive', lightText: false, accent: Color(0xFF5F6F3A), textY: 0.05);

  const ShareBackground(
    this.file, {
    required this.lightText,
    required this.accent,
    required this.textY,
    this.brandBottom = 26,
  });

  final String file;
  final bool lightText;
  final Color accent;
  final double textY;
  final double brandBottom;

  String get asset => 'assets/share_backgrounds/$file.jpg';
}

/// Paylaşılan kelime görseli: WhatsApp durumu ve Instagram hikâyesi biçiminde (9:16, 360x640
/// mantıksal piksel; 3x çözünürlükte 1080x1920). Bilgi kartı değil, paylaşmak istenecek bir
/// görsel olarak tasarlandı: tam ekran sahne, ortada hat ile kelime, altında anlam ve bir örnek
/// cümle; en altta küçük bir kavaid.app imzası.
///
/// WordShareService görüntüye çevirir; önizleme ekranı küçültüp gösterir.
class WordShareCard extends StatelessWidget {
  const WordShareCard({
    super.key,
    required this.word,
    required this.meaning,
    required this.meaningLang,
    this.background = ShareBackground.dusk,
  });

  final WordModel word;

  /// Gösterilecek anlam (sözlük dilinde; Arapça sözlükte ilk tanım).
  final String meaning;

  /// Sözlük dili: tr, en, ar, id, ms, ur. Anlamın yazı yönünü ve fontunu belirler.
  final String meaningLang;

  final ShareBackground background;

  static const double width = 360;
  static const double height = 640;

  String get _headword => word.harekeliKelime?.trim().isNotEmpty == true
      ? word.harekeliKelime!.trim()
      : word.kelime.trim();

  bool get _rtlMeaning => meaningLang == 'ar' || meaningLang == 'ur';

  // Fontlar: başlık kelime rika hattıyla (ArefRuqaa); örnek cümle, kök ve Arap harfli anlamlar
  // okunaklı nesih ile (ScheherazadeNew, Urduca harfleri de var). Amiri denendi: Flutter'da
  // harekeleri harfin üstüne yerleştirmiyor, havada bırakıyor.
  static const _naskh = 'ScheherazadeNew';

  String? get _typeLabel {
    String? rawType;
    if (word.dilbilgiselOzellikler?.containsKey('tur') == true) {
      rawType = word.dilbilgiselOzellikler!['tur']?.toString();
    } else if (word.tip?.isNotEmpty == true) {
      rawType = word.tip;
    }
    return rawType == null ? null : wordTypeLabel(rawType);
  }

  /// Kök harfleri aralıklı ("ك ت ب"); çok uzun ya da tek harfse boş.
  String get _rootText {
    final letters = cleanRoot(word.koku).replaceAll(' ', '').characters.toList();
    return letters.length >= 2 && letters.length <= 5 ? letters.join('  ') : '';
  }

  /// İlk örnek cümle ve çevirisi. Arapça sözlükte çeviri gösterilmez (o dilde değil).
  (String, String)? get _example {
    for (final example in word.ornekCumleler ?? const <Map<String, dynamic>>[]) {
      final arabic = (example['arapcaCumle'] ?? example['arapcaCümle'] ?? example['arapca'] ?? '')
          .toString()
          .trim();
      if (arabic.isEmpty) continue;
      final translation = meaningLang == 'ar'
          ? ''
          : (example['turkceCeviri'] ?? example['turkceAnlam'] ?? example['turkce'] ?? '')
              .toString()
              .trim();
      return (arabic, translation);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bg = background;
    final ink = bg.lightText ? Colors.white : const Color(0xFF2A1D0E);
    final muted = bg.lightText ? const Color(0xD9FFFFFF) : const Color(0xFF6B5A44);
    final shadows = [
      Shadow(
        color: bg.lightText ? const Color(0x80000000) : const Color(0x99FFFFFF),
        blurRadius: 16,
        offset: bg.lightText ? const Offset(0, 2) : Offset.zero,
      ),
    ];
    final typeLabel = _typeLabel;
    final root = _rootText;
    final example = _example;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        // Inter'de Arap harfi yok: Urduca/Arapça arayüz metinleri yedek fonttan çizilir.
        style: TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: const ['ScheherazadeNew'],
          color: ink,
          decoration: TextDecoration.none,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(bg.asset, fit: BoxFit.cover, filterQuality: FilterQuality.high, gaplessPlayback: true),
              // Yazının okunması için arkasında yumuşak bir ışık/gölge (sahneyi kapatmadan)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, bg.textY),
                    radius: 0.85,
                    colors: bg.lightText
                        ? const [Color(0x66000000), Color(0x00000000)]
                        : const [Color(0xB3FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
              if (typeLabel != null)
                Positioned(
                  top: 46,
                  left: 24,
                  right: 24,
                  child: Text(
                    typeLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2.2, color: muted, shadows: shadows),
                  ),
                ),
              Align(
                alignment: Alignment(0, bg.textY),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _headword,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontFamily: 'ArefRuqaa',
                            fontFamilyFallback: const [_naskh],
                            fontSize: 80,
                            fontWeight: FontWeight.w700,
                            height: 1.55,
                            color: ink,
                            fontFeatures: _arabicFeatures,
                            shadows: shadows,
                          ),
                        ),
                      ),
                      if (root.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.kok,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: muted, shadows: shadows),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              root,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: _naskh,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: bg.accent,
                                shadows: shadows,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      _Ornament(color: bg.accent),
                      if (meaning.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          meaning,
                          textAlign: TextAlign.center,
                          textDirection: _rtlMeaning ? TextDirection.rtl : TextDirection.ltr,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _rtlMeaning ? _naskh : 'PlayfairDisplay',
                            fontFamilyFallback: const [_naskh],
                            fontStyle: _rtlMeaning ? FontStyle.normal : FontStyle.italic,
                            fontSize: _rtlMeaning ? 25 : 24,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: ink,
                            shadows: shadows,
                          ),
                        ),
                      ],
                      if (example != null) ...[
                        const SizedBox(height: 26),
                        Text(
                          example.$1,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _naskh,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            height: 1.65,
                            color: ink,
                            fontFeatures: _arabicFeatures,
                            shadows: shadows,
                          ),
                        ),
                        if (example.$2.isNotEmpty)
                          Text(
                            example.$2,
                            textAlign: TextAlign.center,
                            textDirection: _rtlMeaning ? TextDirection.rtl : TextDirection.ltr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _rtlMeaning ? _naskh : 'PlayfairDisplay',
                              fontFamilyFallback: const [_naskh],
                              fontStyle: _rtlMeaning ? FontStyle.normal : FontStyle.italic,
                              fontSize: _rtlMeaning ? 16 : 14.5,
                              height: 1.4,
                              color: muted,
                              shadows: shadows,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              // İmza: yarı saydam hap içinde, her zeminde okunur
              Positioned(
                left: 0,
                right: 0,
                bottom: bg.brandBottom,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
                    decoration: BoxDecoration(
                      color: bg.lightText ? const Color(0x33000000) : const Color(0xB3FFFFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(color: bg.accent, borderRadius: BorderRadius.circular(6)),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 12,
                            color: bg.lightText ? const Color(0xFF1B1B2F) : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'kavaid.app',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İnce süs çizgisi: iki yanda incelen çizgi, ortada küçük bir baklava.
class _Ornament extends StatelessWidget {
  const _Ornament({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget line(bool leftSide) => Container(
          width: 46,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: leftSide ? [color.withValues(alpha: 0), color] : [color, color.withValues(alpha: 0)],
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(true),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(width: 6, height: 6, color: color),
        ),
        const SizedBox(width: 8),
        line(false),
      ],
    );
  }
}
