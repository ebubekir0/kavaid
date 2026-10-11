import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/services/daily_word.dart';
import 'package:kavaid/widgets/home_dashboard.dart';

const _word = DailyWord(
  arabic: 'تُفَّاحٌ',
  root: 'تفح',
  type: 'İsim',
  meaning: 'elma, elma ağacı',
  exampleArabic: 'أُحِبُّ أَكْلَ التُّفَّاحِ.',
  exampleTurkish: 'Elma yemeyi severim.',
);

Future<void> _loadAppFonts(WidgetTester tester) async {
  // Test ortamının varsayılan fontu her harfi kare çizer; taşma kontrolünün
  // anlamlı olması için uygulamanın gerçek fontları yüklenir.
  await tester.runAsync(() async {
    final scheherazade = FontLoader('ScheherazadeNew')
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Bold.ttf'));
    await scheherazade.load();
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf'));
    await inter.load();
  });
}

Widget _app({
  DailyWord? word = _word,
  bool dark = false,
  bool premium = true,
  void Function(String)? onSearch,
  void Function(String)? onSpeak,
  VoidCallback? onPremiumTap,
  Widget? banner,
  bool disableAnimations = true,
  bool animate = true,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        fontFamily: 'Inter',
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeDashboard(
            isDarkMode: dark,
            dailyWord: word,
            today: DateTime(2026, 10, 11),
            wordCount: 54971,
            onSearch: onSearch ?? (_) {},
            onSpeak: onSpeak ?? (_) {},
            showPremium: premium,
            onPremiumTap: onPremiumTap,
            campaignBanner: banner,
            animate: animate,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('biçimleme', () {
    test('formatCount binlik ayracı nokta koyar', () {
      expect(formatCount(54971), '54.971');
      expect(formatCount(999), '999');
      expect(formatCount(1000), '1.000');
      expect(formatCount(1234567), '1.234.567');
      expect(formatCount(0), '0');
    });

    test('formatTurkishDate ay adlarını Türkçe büyük harfle yazar', () {
      expect(formatTurkishDate(DateTime(2026, 10, 11)), '11 EKİM');
      expect(formatTurkishDate(DateTime(2026, 4, 1)), '1 NİSAN');
      expect(formatTurkishDate(DateTime(2026, 6, 30)), '30 HAZİRAN');
      expect(formatTurkishDate(DateTime(2026, 8, 9)), '9 AĞUSTOS');
      expect(formatTurkishDate(DateTime(2026, 12, 25)), '25 ARALIK');
    });
  });

  group('içerik', () {
    testWidgets('günün kelimesi, anlamı, tarihi ve örnek cümlesi gösterilir', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('daily-word')), findsOneWidget);
      expect(find.text('elma, elma ağacı'), findsOneWidget);
      expect(find.text('İsim'), findsOneWidget);
      expect(find.textContaining('GÜNÜN KELİMESİ', findRichText: true), findsOneWidget);
      expect(find.textContaining('11 EKİM', findRichText: true), findsOneWidget);
      expect(find.text('Elma yemeyi severim.'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('daily-root'))).data, 'تفح');
    });

    testWidgets('sözlükteki kelime sayısı noktalı yazılır', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('54.971'), findsOneWidget);
      expect(find.text('kelime'), findsOneWidget);
    });

    testWidgets('günün kelimesi yüklenmediyse o bölüm çizilmez, sayfa yine çalışır', (tester) async {
      await tester.pumpWidget(_app(word: null));
      await tester.pumpAndSettle();

      expect(find.textContaining('GÜNÜN KELİMESİ', findRichText: true), findsNothing);
      expect(find.text('Şunları dene'), findsOneWidget);
    });

    testWidgets('premium satırı yalnızca premium olmayanlara görünür', (tester) async {
      await tester.pumpWidget(_app(premium: true));
      await tester.pumpAndSettle();
      expect(find.text("Premium'a yükselt"), findsOneWidget);

      await tester.pumpWidget(_app(premium: false));
      await tester.pumpAndSettle();
      expect(find.text("Premium'a yükselt"), findsNothing);
    });

    testWidgets('kampanya banner\'ı verilirse en üstte gösterilir', (tester) async {
      await tester.pumpWidget(_app(banner: const Text('KAMPANYA')));
      await tester.pumpAndSettle();

      final banner = tester.getTopLeft(find.text('KAMPANYA')).dy;
      final brand = tester.getTopLeft(find.text('Kavaid')).dy;
      expect(banner, lessThan(brand));
    });
  });

  group('dokunmalar', () {
    testWidgets('günün kelimesi kartına dokunmak kelimeyi arar', (tester) async {
      final searched = <String>[];
      await tester.pumpWidget(_app(onSearch: searched.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('daily-word')));

      expect(searched, ['تُفَّاحٌ']);
    });

    testWidgets('hoparlör kelimeyi seslendirir, aramayı tetiklemez', (tester) async {
      final searched = <String>[];
      final spoken = <String>[];
      await tester.pumpWidget(_app(onSearch: searched.add, onSpeak: spoken.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.volume_up_rounded));

      expect(spoken, ['تُفَّاحٌ']);
      expect(searched, isEmpty);
    });

    testWidgets('öneri çipleri kendi metinleriyle arama yapar', (tester) async {
      final searched = <String>[];
      await tester.pumpWidget(_app(onSearch: searched.add));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('kitap'));
      await tester.tap(find.text('kitap'));
      await tester.ensureVisible(find.text('ذهب'));
      await tester.tap(find.text('ذهب'));

      expect(searched, ['kitap', 'ذهب']);
    });

    testWidgets('premium satırına dokunmak yönlendirir', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(onPremiumTap: () => taps++));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text("Premium'a yükselt"));
      await tester.tap(find.text("Premium'a yükselt"));

      expect(taps, 1);
    });

    testWidgets('günün kelimesi kartı ekran okuyucuya tek düğme olarak okunur', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Günün kelimesi: تُفَّاحٌ, elma, elma ağacı')),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('yerleşim', () {
    for (final width in [320.0, 360.0, 412.0]) {
      for (final dark in [false, true]) {
        testWidgets('${width.toInt()} px genişlikte ${dark ? "koyu" : "açık"} temada taşma yok', (tester) async {
          await _loadAppFonts(tester);
          await tester.binding.setSurfaceSize(Size(width, 1600));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(_app(dark: dark));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('çok uzun bir kelime ve anlam da taşmadan sığar', (tester) async {
      await _loadAppFonts(tester);
      await tester.binding.setSurfaceSize(const Size(320, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const long = DailyWord(
        arabic: 'اِسْتِخْدَامَاتٌ',
        root: 'خدم',
        type: 'Mazî Fiil',
        meaning: 'bir şeyi amacına uygun biçimde kullanmak, işe koşmak',
        exampleArabic: 'اِسْتَخْدَمَ الْمُعَلِّمُ الْقَلَمَ لِكِتَابَةِ الرِّسَالَةِ الطَّوِيلَةِ.',
        exampleTurkish: 'Öğretmen uzun mektubu yazmak için kalemi kullandı ve sonra postaya verdi.',
      );

      await tester.pumpWidget(_app(word: long));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('animate: false iken bölümler animasyonsuz, hemen görünür', (tester) async {
      await tester.pumpWidget(_app(disableAnimations: false, animate: false));

      expect(find.byType(Opacity), findsNothing);
      expect(find.byKey(const ValueKey('daily-word')), findsOneWidget);
    });

    testWidgets('bölümler açılışta kademeli belirir ve sonunda tam görünür', (tester) async {
      await tester.pumpWidget(_app(disableAnimations: false));
      await tester.pump(const Duration(milliseconds: 40));
      final early = tester.widget<Opacity>(find.byType(Opacity).first).opacity;

      await tester.pumpAndSettle();
      final late = tester.widget<Opacity>(find.byType(Opacity).first).opacity;

      expect(early, lessThan(1));
      expect(late, 1);
    });
  });
}
