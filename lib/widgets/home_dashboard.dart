// Sözlük ana sayfası (arama yapılmadığında görünen ekran).
//
// Eskiden burada sabit bir başlık, bir slogan ve üç satırlık özellik listesi
// vardı: her açılışta aynı yazılar, üstelik Kur'an modunun zeytin yeşili
// renkleriyle. Yerine uygulamanın mavi temasıyla uyumlu, her gün değişen ve
// dokununca işe yarayan bir ana sayfa var: günün kelimesi, tek dokunuşla
// denenebilen aramalar ve sözlüğün büyüklüğünü gösteren bir özet.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/daily_word.dart';
import '../utils/arabic_text.dart';
import 'search_result_card_parts.dart' show AiMark, ArabicTextStyles;

const _blue = Color(0xFF007AFF);

Color _primaryText(bool dark) => dark ? Colors.white : const Color(0xFF1C1C1E);
Color _secondaryText(bool dark) =>
    dark ? const Color(0xFF9A9AA0) : const Color(0xFF6D6D70);
Color _surface(bool dark) => dark ? const Color(0xFF2C2C2E) : Colors.white;
Color _border(bool dark) =>
    dark ? const Color(0xFF48484A) : const Color(0xFFD0D8E4);

const _monthsUpper = [
  'OCAK',
  'ŞUBAT',
  'MART',
  'NİSAN',
  'MAYIS',
  'HAZİRAN',
  'TEMMUZ',
  'AĞUSTOS',
  'EYLÜL',
  'EKİM',
  'KASIM',
  'ARALIK',
];

/// "11 EKİM" biçiminde gün ve ay. (Dart'ın toUpperCase'i Türkçe harfleri
/// bilmediği için "Ekim" -> "EKIM" olurdu; bu yüzden ay adları hazır.)
String formatTurkishDate(DateTime date) =>
    '${date.day} ${_monthsUpper[date.month - 1]}';

/// 54971 -> "54.971".
String formatCount(int n) {
  final digits = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Ana sayfa. Kaydırılabilir bir alanın içine (örn. SliverToBoxAdapter)
/// konur; kendi kenar boşluklarını taşır.
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.isDarkMode,
    required this.dailyWord,
    required this.today,
    required this.wordCount,
    required this.onSearch,
    required this.onSpeak,
    this.campaignBanner,
    this.showPremium = false,
    this.onPremiumTap,
    this.bottomPadding = 0,
    this.useShadows = true,
    this.animate = true,
  });

  final bool isDarkMode;

  /// Henüz yüklenmediyse ya da okunamadıysa null: o bölüm çizilmez.
  final DailyWord? dailyWord;

  /// Günün kelimesinin hangi güne ait olduğu (kartta tarih olarak yazar).
  final DateTime today;

  /// Sözlükteki toplam kelime sayısı.
  final int wordCount;

  /// Bir öneriye ya da günün kelimesine dokunulunca o metinle arama yapılır.
  final void Function(String query) onSearch;

  /// Günün kelimesini seslendirir.
  final void Function(String arabic) onSpeak;

  /// Varsa en üstte gösterilir (kampanya duyurusu).
  final Widget? campaignBanner;

  final bool showPremium;
  final VoidCallback? onPremiumTap;

  /// Alt gezinme çubuğunun kapladığı yükseklik.
  final double bottomPadding;

  /// Düşük performanslı cihazlarda gölge kapatılır.
  final bool useShadows;

  /// Bölümler açılışta kademeli belirsin mi? Düşük performanslı cihazlarda
  /// kapatılır; sistem animasyonları kapalıysa zaten hiçbir zaman çalışmaz.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final word = dailyWord;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?campaignBanner,
          _Reveal(animate: animate, order: 0, child: _BrandHeader(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),
          if (word != null) ...[
            _Reveal(
              animate: animate,
              order: 1,
              child: DailyWordCard(
                word: word,
                date: today,
                isDarkMode: isDarkMode,
                useShadows: useShadows,
                onOpen: () => onSearch(word.arabic),
                onSpeak: () => onSpeak(word.arabic),
              ),
            ),
            const SizedBox(height: 24),
          ],
          _Reveal(
            animate: animate,
            order: 2,
            child: _SuggestionSection(isDarkMode: isDarkMode, onSearch: onSearch),
          ),
          const SizedBox(height: 24),
          _Reveal(
            animate: animate,
            order: 3,
            child: _StatsStrip(isDarkMode: isDarkMode, wordCount: wordCount),
          ),
          if (showPremium) ...[
            const SizedBox(height: 14),
            _Reveal(
              animate: animate,
              order: 4,
              child: _PremiumTile(isDarkMode: isDarkMode, onTap: onPremiumTap),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bölümlerin sırayla, hafifçe yukarı kayarak belirmesi. Sonraki bölümlerin
/// süresi biraz daha uzun olduğu için art arda gelirler. Sistemde animasyonlar
/// kapalıysa doğrudan gösterilir.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animate,
    required this.order,
    required this.child,
  });

  final bool animate;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + order * 90),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
      ),
      child: child,
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: 44,
            height: 44,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 44,
              height: 44,
              color: _blue,
              child: const Icon(Icons.menu_book_rounded, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kavaid',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.1,
                  color: _primaryText(isDarkMode),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Arapça sözlük · yapay zekâ destekli',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _secondaryText(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Günün kelimesi: büyük harekeli kelime, yanında soluk kökü, Türkçe karşılığı
/// ve bir örnek cümle. Kartın tamamına dokunmak kelimeyi sözlükte arar.
class DailyWordCard extends StatelessWidget {
  const DailyWordCard({
    super.key,
    required this.word,
    required this.date,
    required this.isDarkMode,
    required this.onOpen,
    required this.onSpeak,
    this.useShadows = true,
  });

  final DailyWord word;
  final DateTime date;
  final bool isDarkMode;
  final VoidCallback onOpen;
  final VoidCallback onSpeak;
  final bool useShadows;

  @override
  Widget build(BuildContext context) {
    final root = formatRoot(word.root);
    final gradient = isDarkMode
        ? const [Color(0xFF0F4C99), Color(0xFF082B57)]
        : const [Color(0xFF0A6CF0), Color(0xFF0047B8)];

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Günün kelimesi: ${word.arabic}, ${word.meaning}. Sözlükte aç',
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(22),
          border: isDarkMode
              ? Border.all(color: Colors.white.withValues(alpha: 0.10))
              : null,
          boxShadow: useShadows && !isDarkMode
              ? [
                  BoxShadow(
                    color: const Color(0xFF0A6CF0).withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Süs: İslam sanatındaki sekiz köşeli yıldız, çok soluk çizgilerle
            Positioned(
              right: -72,
              top: -72,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size.square(250),
                  painter: _StarPatternPainter(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -56,
              bottom: -64,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size.square(170),
                  painter: _StarPatternPainter(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'GÜNÜN KELİMESİ',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  TextSpan(
                                    text: '  ·  ${formatTurkishDate(date)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.2,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                          _RoundIconButton(
                            icon: Icons.volume_up_rounded,
                            label: 'Seslendir',
                            onTap: onSpeak,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                word.arabic,
                                key: const ValueKey('daily-word'),
                                style: ArabicTextStyles.word.copyWith(
                                  fontSize: 46,
                                  height: 1.35,
                                  color: Colors.white,
                                ),
                                textDirection: TextDirection.rtl,
                                softWrap: false,
                              ),
                              if (root.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Text(
                                  root,
                                  key: const ValueKey('daily-root'),
                                  style: ArabicTextStyles.root.copyWith(
                                    fontSize: 24,
                                    color: Colors.white.withValues(alpha: 0.62),
                                  ),
                                  textDirection: TextDirection.rtl,
                                  softWrap: false,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (word.type.isNotEmpty)
                        Center(child: _HeroChip(label: word.type)),
                      const SizedBox(height: 8),
                      Text(
                        word.meaning,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              word.exampleArabic,
                              style: ArabicTextStyles.example.copyWith(
                                fontSize: 19,
                                color: Colors.white,
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.start,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              word.exampleTurkish,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sözlükte aç',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 21, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Sekiz köşeli yıldız (iç içe iki kare, aralarında 45°) ve içe doğru küçülen
/// kopyaları.
class _StarPatternPainter extends CustomPainter {
  const _StarPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color;

    for (var i = 0; i < 5; i++) {
      final radius = size.shortestSide / 2 * (1 - i * 0.17);
      canvas.drawPath(_square(center, radius, 0), paint);
      canvas.drawPath(_square(center, radius, math.pi / 4), paint);
    }
  }

  Path _square(Offset center, double radius, double rotation) {
    final path = Path();
    for (var k = 0; k < 4; k++) {
      final angle = rotation + math.pi / 4 + k * math.pi / 2;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (k == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_StarPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// "Şunları dene": dokununca aranan örnek kelimeler. Türkçe karaktersiz yazıp
/// Arapça kelimeyle ya da kökle aramanın mümkün olduğunu gösterir.
class _SuggestionSection extends StatelessWidget {
  const _SuggestionSection({required this.isDarkMode, required this.onSearch});

  final bool isDarkMode;
  final void Function(String query) onSearch;

  static const suggestions = ['kitap', 'gitmek', 'güzel', 'okul', 'ذهب', 'علم', 'كتب'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Şunları dene',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _primaryText(isDarkMode),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Türkçe, Arapça ya da kök yazarak ara',
          style: TextStyle(fontSize: 12.5, color: _secondaryText(isDarkMode)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in suggestions)
              _SuggestionChip(
                label: s,
                isDarkMode: isDarkMode,
                onTap: () => onSearch(s),
              ),
          ],
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.isDarkMode,
    required this.onTap,
  });

  final String label;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final arabic = RegExp(r'[؀-ۿ]').hasMatch(label);
    return Material(
      color: _surface(isDarkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _border(isDarkMode)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: arabic ? 5 : 9),
          child: Text(
            label,
            style: arabic
                ? ArabicTextStyles.word.copyWith(
                    fontSize: 19,
                    height: 1.3,
                    color: _primaryText(isDarkMode),
                  )
                : TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryText(isDarkMode),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Sözlüğün büyüklüğünü sayılarla gösteren tek satırlık özet.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.isDarkMode, required this.wordCount});

  final bool isDarkMode;
  final int wordCount;

  @override
  Widget build(BuildContext context) {
    Widget divider() => Container(width: 1, height: 30, color: _border(isDarkMode));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: _surface(isDarkMode),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border(isDarkMode)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              value: formatCount(wordCount),
              label: 'kelime',
              isDarkMode: isDarkMode,
            ),
          ),
          divider(),
          Expanded(
            child: _Stat(
              value: '25.000+',
              label: "Kur'an kelimesi",
              isDarkMode: isDarkMode,
            ),
          ),
          divider(),
          Expanded(
            child: _Stat(
              valueWidget: AiMark(isDarkMode: isDarkMode, size: 26),
              label: 'AI asistan',
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    this.value,
    this.valueWidget,
    required this.label,
    required this.isDarkMode,
  }) : assert(value != null || valueWidget != null);

  final String? value;
  final Widget? valueWidget;
  final String label;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 26,
          child: Center(
            child:
                valueWidget ??
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: _primaryText(isDarkMode),
                  ),
                ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.5, color: _secondaryText(isDarkMode)),
        ),
      ],
    );
  }
}

/// Premium'a geçiş satırı. Eskiden ikinci bir mavi gradyan bloktu ve günün
/// kelimesi kartıyla yarışıyordu; artık sakin, kenarlıklı bir satır.
class _PremiumTile extends StatelessWidget {
  const _PremiumTile({required this.isDarkMode, required this.onTap});

  final bool isDarkMode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFF5A623);
    return Material(
      color: _surface(isDarkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: gold.withValues(alpha: isDarkMode ? 0.45 : 0.55)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: gold,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Premium'a yükselt",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _primaryText(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Sınırsız erişim',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _secondaryText(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _secondaryText(isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
