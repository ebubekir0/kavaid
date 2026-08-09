import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppFeatureOnboarding extends StatefulWidget {
  final bool isDarkMode;

  const AppFeatureOnboarding({super.key, required this.isDarkMode});

  static const _shownKey = 'app_feature_onboarding_shown_v1';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_shownKey) != true;
  }

  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shownKey, true);
  }

  @override
  State<AppFeatureOnboarding> createState() => _AppFeatureOnboardingState();
}

class _AppFeatureOnboardingState extends State<AppFeatureOnboarding> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const _items = <_FeaturePage>[
    _FeaturePage(
      icon: Icons.search_rounded,
      title: 'Arapça sözlük',
      text:
          'Kelime ara, anlamları gör, kök bilgisiyle gramer yapısını hızlıca kavra.',
      color: Color(0xFF007AFF),
    ),
    _FeaturePage(
      icon: Icons.account_tree_rounded,
      title: 'Gramer ve Emsile',
      text:
          'Sarf, nahiv ve Emsile desteğiyle 7000+ fiil çekimini düzenli şekilde incele.',
      color: Color(0xFF384D75),
    ),
    _FeaturePage(
      icon: Icons.menu_book_rounded,
      title: 'Kur’an sözlüğü',
      text:
          'Kur’an kelimelerini, ayetlerdeki kullanımlarını ve Kur’ani anlamlarını keşfet.',
      color: Color(0xFF4A5729),
    ),
    _FeaturePage(
      icon: Icons.record_voice_over_rounded,
      title: 'Canlı lehçe çeviri',
      text:
          '20’den fazla Arapça lehçede sesli ve yazılı çeviriyle günlük ifadeleri yakala.',
      color: Color(0xFF8E44AD),
    ),
    _FeaturePage(
      icon: Icons.style_rounded,
      title: 'Listeler ve kartlar',
      text:
          'Kendi kelime listelerini oluştur, kartlarla tekrar yap, öğrendiklerini düzenle.',
      color: Color(0xFFFF9500),
    ),
    _FeaturePage(
      icon: Icons.school_rounded,
      title: 'Öğren metinleri',
      text:
          'Sesli ve yazılı öğrenme metinleriyle Arapçayı bağlam içinde çalış.',
      color: Color(0xFF34C759),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppFeatureOnboarding.markAsShown();
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_index == _items.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final background = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF5B616E);
    final activeColor = _items[_index].color;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kavaid’e hoş geldin',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _finish,
                    icon: Icon(Icons.close_rounded, color: mutedColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 310,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _OnboardingPage(item: item, isDarkMode: isDark);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_items.length, (index) {
                  final selected = index == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 22 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: selected
                          ? activeColor
                          : (isDark ? Colors.white24 : const Color(0xFFD1D1D6)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: Text('Geç', style: TextStyle(color: mutedColor)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _index == _items.length - 1 ? 'Başla' : 'Devam',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _FeaturePage item;
  final bool isDarkMode;

  const _OnboardingPage({required this.item, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final mutedColor = isDarkMode ? Colors.white70 : const Color(0xFF5B616E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: isDarkMode ? 0.18 : 0.11),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(item.icon, color: item.color, size: 54),
          ),
          const SizedBox(height: 26),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedColor,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePage {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _FeaturePage({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });
}
