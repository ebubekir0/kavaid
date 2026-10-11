import 'package:flutter/material.dart';

/// Ana sayfanın arama yapılmadan önceki sade karşılama ekranı: günün kelimesi,
/// birkaç arama önerisi ve (premium değilse) sessiz bir premium bağlantısı.
class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({
    super.key,
    required this.isDarkMode,
    required this.onSearch,
    this.onPremiumTap,
    DateTime? today,
  }) : _today = today;

  final bool isDarkMode;

  /// Öneriye veya günün kelimesine dokunulunca arama kutusuna yazılacak metin.
  final ValueChanged<String> onSearch;

  /// Null ise (kullanıcı zaten premium) premium bağlantısı gösterilmez.
  final VoidCallback? onPremiumTap;
  final DateTime? _today;

  static const _blue = Color(0xFF007AFF);

  /// Günün kelimesi için sık kullanılan, kısa kelimeler: (Arapça, Türkçe).
  static const dailyWords = <(String, String)>[
    ('كِتَابٌ', 'kitap'),
    ('مَاءٌ', 'su'),
    ('بَيْتٌ', 'ev'),
    ('عِلْمٌ', 'ilim, bilgi'),
    ('قَلْبٌ', 'kalp'),
    ('نُورٌ', 'nur, ışık'),
    ('صَبْرٌ', 'sabır'),
    ('سَلَامٌ', 'barış, selam'),
    ('حُبٌّ', 'sevgi'),
    ('وَقْتٌ', 'zaman, vakit'),
    ('طَرِيقٌ', 'yol'),
    ('شَمْسٌ', 'güneş'),
    ('بَابٌ', 'kapı'),
    ('يَدٌ', 'el'),
  ];

  /// Gün numarasına göre değişen kelime (aynı gün içinde sabit).
  static (String, String) wordOfDay(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2024))
        .inDays;
    return dailyWords[day % dailyWords.length];
  }

  @override
  Widget build(BuildContext context) {
    final (arabic, turkish) = wordOfDay(_today ?? DateTime.now());
    final primary = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final secondary = isDarkMode
        ? const Color(0xFF8E8E93)
        : const Color(0xFF8A8A8E);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      child: Column(
        children: [
          Text(
            'GÜNÜN KELİMESİ',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
              color: secondary,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            key: const ValueKey('word-of-day'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSearch(arabic),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                children: [
                  Text(
                    arabic,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      fontSize: 52,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  Text(
                    turkish,
                    style: TextStyle(fontSize: 16, color: secondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 44),
          Text(
            'Arapça ya da Türkçe bir kelime yazın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: secondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in const ['كتب', 'güzel', 'okul', 'gitmek'])
                _chip(s),
            ],
          ),
          if (onPremiumTap != null) ...[
            const SizedBox(height: 40),
            TextButton(
              key: const ValueKey('premium-link'),
              onPressed: onPremiumTap,
              style: TextButton.styleFrom(foregroundColor: _blue),
              child: const Text(
                'Sınırsız arama için Premium',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text) {
    final isArabic = RegExp('[؀-ۿ]').hasMatch(text);
    return Material(
      color: isDarkMode
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onSearch(text),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: isArabic ? 'ScheherazadeNew' : null,
              fontSize: isArabic ? 18 : 14,
              color: isDarkMode ? Colors.white70 : const Color(0xFF3A3A3C),
            ),
          ),
        ),
      ),
    );
  }
}
