import 'package:flutter/material.dart';

/// Boş Sözlük ekranının mavi zemini üzerinde çok hafif İslami geometrik
/// (sekiz köşeli yıldız) desen; aşağıya doğru silinir.
///
/// Desen uygulamayla gelen hazır bir görseldir (beyaz çizgiler, saydam zemin; tool/make_arabic_pattern.py üretir)
/// ve temaya göre renklendirilir. Çalışırken harf çizilmediği için ana
/// ekranın açılışını ve kaydırmayı yavaşlatmaz.
class ArabicLettersBackground extends StatelessWidget {
  const ArabicLettersBackground({super.key, required this.isDarkMode});

  final bool isDarkMode;

  static const _pattern = AssetImage(
    'assets/images/arabic_letters_pattern.webp',
  );

  /// Açılış ekranı dururken görseli arka planda çözer; ana ekran açıldığında
  /// desen hazırdır.
  static Future<void> precache(BuildContext context) =>
      precacheImage(_pattern, context);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Image(
          image: _pattern,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFF007AFF).withValues(alpha: 0.12),
          colorBlendMode: BlendMode.srcIn,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
