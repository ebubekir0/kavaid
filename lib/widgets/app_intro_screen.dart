import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/language_service.dart';

/// İlk açılışta uygulamanın tüm özelliklerini, uygulamadan alınmış gerçek
/// ekran görüntüleri üzerinde numaralı işaretlerle anlatan, yana kaydırmalı
/// tanıtım. Yalnızca yeni kurulumda bir kez gösterilir.
class AppIntroScreen extends StatefulWidget {
  final bool isDarkMode;

  const AppIntroScreen({super.key, required this.isDarkMode});

  static const _aiIntroSeenKey = 'ai_intro_seen_v1';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(LanguageService.appIntroPendingKey) == true;
  }

  static Future<void> show(BuildContext context, {required bool isDarkMode}) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => AppIntroScreen(isDarkMode: isDarkMode),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<AppIntroScreen> createState() => _AppIntroScreenState();
}

/// Ekran görüntüsünde vurgulanan alan. Koordinatlar telefonun orijinal
/// ekran görüntüsündeki pikseller (1080 genişlik); görsel y=105'ten
/// (durum çubuğunun altından) başlar.
class _Callout {
  final String label;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const _Callout(this.label, this.left, this.top, this.right, this.bottom);
}

class _IntroPage {
  final String title;
  final String text;
  final String image;
  final Color color;
  final List<_Callout> callouts;
  final bool isNew;

  const _IntroPage({
    required this.title,
    required this.text,
    required this.image,
    required this.color,
    required this.callouts,
    this.isNew = false,
  });
}

/// Görseller `assets/intro/` altında, uygulamanın gerçek ekran görüntüleri.
/// Her sayfada en fazla iki işaret: sade ve tek bakışta anlaşılır.
const _introPages = <_IntroPage>[
  _IntroPage(
    title: 'Arapça–Türkçe sözlük',
    text: 'Arapça ya da Türkçe yaz, her şey tek kartta.',
    image: 'assets/intro/dictionary.webp',
    color: Color(0xFF007AFF),
    callouts: [
      _Callout('Sesle ya da Arapça klavyeyle ara', 744, 142, 928, 238),
      _Callout('Kök, çoğul ve örnek cümleler', 24, 448, 1056, 1576),
    ],
  ),
  _IntroPage(
    title: 'Fiil kartı',
    text: 'Fiillerin çekimleri kartın içinde.',
    image: 'assets/intro/verb.webp',
    color: Color(0xFF007AFF),
    callouts: [
      _Callout('Mazi, müzari, mastar ve emir', 58, 834, 1022, 1014),
      _Callout('Tüm çekimler için emsileye geç', 58, 1038, 1022, 1164),
    ],
  ),
  _IntroPage(
    title: 'AI Asistan',
    text: 'Kelime kartının en solundaki simgeye dokun.',
    image: 'assets/intro/ai.webp',
    color: Color(0xFF007AFF),
    isNew: true,
    callouts: [
      _Callout('Sorunu yaz ya da hazır soru seç', 584, 662, 1042, 782),
      _Callout('Kısa ve net cevap', 138, 810, 982, 1396),
    ],
  ),
  _IntroPage(
    title: 'Emsile',
    text: '7000’den fazla fiilin çekim tablosu.',
    image: 'assets/intro/emsile.webp',
    color: Color(0xFF384D75),
    callouts: [
      _Callout('Fiile dokun, kartı açılsın', 4, 992, 1076, 1206),
      _Callout('Anlamları ve 24 sığa çekimi', 12, 1236, 1068, 2120),
    ],
  ),
  _IntroPage(
    title: 'Kur’an sözlüğü',
    text: 'Kur’an kelimelerini ayetleriyle öğren.',
    image: 'assets/intro/quran.webp',
    color: Color(0xFF4A5729),
    callouts: [
      _Callout('Kelime ve Kur’ani anlamları', 24, 746, 1056, 1014),
      _Callout('Geçtiği ayet ve meali', 62, 1130, 1018, 1654),
    ],
  ),
  _IntroPage(
    title: 'Lehçe çeviri',
    text: 'Türkçe yaz ya da konuş, 17 lehçeye çevir.',
    image: 'assets/intro/translate.webp',
    color: Color(0xFF1A73E8),
    callouts: [
      _Callout('Karşılığı ve okunuşu', 44, 530, 1032, 758),
      _Callout('Lehçeyi seç ya da sesle söyle', 44, 1566, 1034, 2030),
    ],
  ),
  _IntroPage(
    title: 'Listeler ve kartlar',
    text: 'Kaydettiğin her şey tek yerde.',
    image: 'assets/intro/lists.webp',
    color: Color(0xFFFF9500),
    callouts: [
      _Callout('Liste ya da kartlarla tekrar et', 46, 290, 1034, 432),
      _Callout('Sözlük, Kur’an ve emsile kayıtları', 24, 466, 1056, 968),
    ],
  ),
  _IntroPage(
    title: 'Öğren',
    text: 'A1’den C1’e resimli Arapça hikâyeler.',
    image: 'assets/intro/learn.webp',
    color: Color(0xFF34C759),
    callouts: [
      _Callout('Kelimeye dokun, anlamı çıksın', 900, 722, 1078, 976),
      _Callout('Metni sesli dinle', 300, 1944, 780, 2122),
    ],
  ),
];

TextStyle _inter({
  required double size,
  required FontWeight weight,
  required Color color,
  double? height,
  double? letterSpacing,
}) => TextStyle(
  fontFamily: 'Inter',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

class _AppIntroScreenState extends State<AppIntroScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _sawAiPage = false;

  static final int _aiPageIndex = _introPages.indexWhere((p) => p.isNew);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kaydırırken görsel gecikmesin diye hepsini önceden çöz.
    for (final page in _introPages) {
      precacheImage(AssetImage(page.image), context, onError: (_, _) {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(LanguageService.appIntroPendingKey, false);
      // AI sayfasını gördüyse ana ekrandaki AI tanıtım kartı tekrar çıkmasın.
      if (_sawAiPage) {
        await prefs.setBool(AppIntroScreen._aiIntroSeenKey, true);
      }
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_index == _introPages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final bg = dark ? const Color(0xFF1C1C1E) : Colors.white;
    final text = dark ? Colors.white : const Color(0xFF1C1C1E);
    final muted = dark ? const Color(0xFFB0B0B5) : const Color(0xFF6D6D70);
    final line = dark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final page = _introPages[_index];
    final isLast = _index == _introPages.length - 1;

    return PopScope(
      canPop: false,
      // Geri tuşu "Geç" gibi davranır.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 10, 0),
                child: Row(
                  children: [
                    Text(
                      'Kavaid',
                      style: _inter(
                        size: 17,
                        weight: FontWeight.w800,
                        color: text,
                      ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: isLast ? 0 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: TextButton(
                        key: const Key('intro-skip'),
                        onPressed: isLast ? null : _finish,
                        child: Text(
                          'Geç',
                          style: _inter(
                            size: 15,
                            weight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _introPages.length,
                  onPageChanged: (i) => setState(() {
                    _index = i;
                    if (i == _aiPageIndex) _sawAiPage = true;
                  }),
                  itemBuilder: (context, i) => _IntroPageView(
                    page: _introPages[i],
                    dark: dark,
                    textColor: text,
                    mutedColor: muted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_introPages.length, (i) {
                  final selected = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? 22 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: selected ? page.color : line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    key: const Key('intro-next'),
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: page.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isLast ? 'Başla' : 'Devam',
                      style: _inter(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

class _IntroPageView extends StatelessWidget {
  final _IntroPage page;
  final bool dark;
  final Color textColor;
  final Color mutedColor;

  const _IntroPageView({
    required this.page,
    required this.dark,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: _PhoneShowcase(page: page, dark: dark),
          ),
          const SizedBox(height: 16),
          // Sabit yükseklik: açıklama sayısı farklı olsa da başlık her
          // sayfada aynı yerde durur, kaydırırken zıplamaz.
          SizedBox(
            height: 148,
            // Büyük yazı tipi ayarında taşma hatası yerine kırpılır.
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: _inter(
                            size: 23,
                            weight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (page.isNew) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: page.color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'YENİ',
                            style: _inter(
                              size: 10.5,
                              weight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    page.text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _inter(
                      size: 14.5,
                      weight: FontWeight.w500,
                      color: mutedColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Görseldeki numaraların açıklaması
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < page.callouts.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _NumberBadge(
                                number: i + 1,
                                color: page.color,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  page.callouts[i].label,
                                  style: _inter(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;
  final Color color;
  final double size;

  const _NumberBadge({
    required this.number,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
      ),
      child: Text(
        '$number',
        style: _inter(
          size: size * 0.55,
          weight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// Renkli panel içinde telefon çerçevesi; görüntünün tamamı görünür, anlatılan
/// alanlar vurgulanır ve numaralanır.
class _PhoneShowcase extends StatelessWidget {
  /// Ekran görüntülerinin piksel ölçüsü (görsel dosyası bunun 2/3'ü).
  static const _shotWidth = 1080.0;
  static const _shotHeight = 2035.0;
  static const _shotTop = 105.0;

  final _IntroPage page;
  final bool dark;

  const _PhoneShowcase({required this.page, required this.dark});

  @override
  Widget build(BuildContext context) {
    final bezel = dark ? const Color(0xFF48484A) : const Color(0xFF1C1C1E);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: page.color.withValues(alpha: dark ? 0.18 : 0.1),
        child: LayoutBuilder(
          builder: (context, box) {
            const pad = 16.0;
            const bezelWidth = 5.0;
            final imageWidth = math.min(
              box.maxWidth * 0.86 - bezelWidth * 2,
              (box.maxHeight - pad * 2 - bezelWidth * 2) *
                  _shotWidth /
                  _shotHeight,
            );
            final scale = imageWidth / _shotWidth;
            final imageHeight = _shotHeight * scale;
            final rects = [
              for (final c in page.callouts)
                Rect.fromLTRB(
                  c.left * scale,
                  (c.top - _shotTop) * scale,
                  c.right * scale,
                  (c.bottom - _shotTop) * scale,
                ),
            ];

            return Center(
              child: Container(
                padding: const EdgeInsets.all(bezelWidth),
                decoration: BoxDecoration(
                  color: bezel,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            page.image,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.medium,
                            // Görsel eksikse çerçeve boş kalsın, ekran çökmesin.
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                        // Sayfa açılınca işaretler yumuşakça belirir.
                        Positioned.fill(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOut,
                            builder: (context, t, child) =>
                                Opacity(opacity: t, child: child),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _SpotlightPainter(
                                      rects: rects,
                                      color: page.color,
                                    ),
                                  ),
                                ),
                                for (var i = 0; i < rects.length; i++)
                                  Positioned(
                                    left: (rects[i].left - 9).clamp(
                                      2.0,
                                      imageWidth - 22,
                                    ),
                                    top: (rects[i].top - 9).clamp(
                                      2.0,
                                      imageHeight - 22,
                                    ),
                                    child: _NumberBadge(
                                      number: i + 1,
                                      color: page.color,
                                      size: 20,
                                    ),
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
            );
          },
        ),
      ),
    );
  }
}

/// Vurgulanan alanların dışını hafifçe karartır, alanları renkli çerçeveyle
/// çizer.
class _SpotlightPainter extends CustomPainter {
  final List<Rect> rects;
  final Color color;

  const _SpotlightPainter({required this.rects, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final holes = [
      for (final r in rects)
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
    ];
    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    for (final h in holes) {
      dim.addRRect(h);
    }
    canvas.drawPath(dim, Paint()..color = const Color(0x52000000));

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final h in holes) {
      canvas.drawRRect(h, stroke);
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.color != color || old.rects != rects;
}
