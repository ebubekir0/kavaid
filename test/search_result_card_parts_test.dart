import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/models/word_model.dart';
import 'package:kavaid/widgets/home_empty_state.dart';
import 'package:kavaid/widgets/search_result_card_parts.dart';

const _kitap = WordModel(
  kelime: 'كتاب',
  harekeliKelime: 'كِتَابٌ',
  koku: 'كتب',
  anlam: 'kitap, mektup',
  dilbilgiselOzellikler: {'tur': 'İsim', 'cogulForm': 'كُتُبٌ'},
  ornekCumleler: [
    {
      'arapcaCumle': 'قَرَأْتُ كِتَابًا مُفِيدًا جِدًّا فِي الْمَكْتَبَةِ الْكَبِيرَةِ أَمْسِ',
      'turkceCeviri': 'Dün büyük kütüphanede çok faydalı bir kitap okudum.',
    },
  ],
);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 360, child: child)),
);

void main() {
  group('WordHeadline', () {
    testWidgets('kök etiketsiz, kelimeden küçük ve soluk gösterilir', (tester) async {
      await tester.pumpWidget(
        _wrap(const WordHeadline(word: _kitap, isDarkMode: false)),
      );

      expect(find.text('kök'), findsNothing);
      final word = tester.widget<Text>(find.text('كِتَابٌ'));
      final root = tester.widget<Text>(find.byKey(const ValueKey('word-root')));
      expect(root.data, 'كتب');
      expect(root.style!.fontSize, lessThan(word.style!.fontSize!));
      expect(root.style!.color!.a, lessThan(word.style!.color!.a));
      expect(find.text('İsim'), findsOneWidget);
    });

    testWidgets('kökü olmayan kelimede kök alanı çizilmez', (tester) async {
      const word = WordModel(kelime: 'في', harekeliKelime: 'فِي');
      await tester.pumpWidget(_wrap(const WordHeadline(word: word, isDarkMode: false)));

      expect(find.byKey(const ValueKey('word-root')), findsNothing);
    });
  });

  group('highlightSegments', () {
    test('Türkçe karakterden ve büyük harften bağımsız vurgular', () {
      expect(highlightSegments('güzel, hoş', 'guzel'), [
        ('güzel', true),
        (', hoş', false),
      ]);
      expect(highlightSegments('Işık, nur', 'ışık'), [
        ('Işık', true),
        (', nur', false),
      ]);
    });

    test('sorgu yoksa metni olduğu gibi döner', () {
      expect(highlightSegments('kitap', null), [('kitap', false)]);
      expect(highlightSegments('kitap', ''), [('kitap', false)]);
    });
  });

  testWidgets('örnek cümle kesilmeden tam gösterilir', (tester) async {
    await tester.pumpWidget(
      _wrap(const ExampleSentences(word: _kitap, isDarkMode: false)),
    );

    final sentence = tester.widget<Text>(
      find.textContaining('قَرَأْتُ'),
    );
    expect(sentence.maxLines, isNull);
    expect(sentence.overflow, isNot(TextOverflow.ellipsis));
  });

  testWidgets('çoğul ve fiil çekimleri gösterilir', (tester) async {
    const verb = WordModel(
      kelime: 'كتب',
      harekeliKelime: 'كَتَبَ',
      fiilCekimler: {
        'maziForm': 'كَتَبَ',
        'muzariForm': 'يَكْتُبُ',
        'mastarForm': 'كِتَابَةٌ',
        'emirForm': 'اُكْتُبْ',
      },
    );
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            PluralBox(word: _kitap, isDarkMode: false),
            ConjugationRow(word: verb, isDarkMode: false),
          ],
        ),
      ),
    );

    expect(find.text('Çoğul'), findsOneWidget);
    expect(find.text('كُتُبٌ'), findsOneWidget);
    for (final label in ['Mazi', 'Müzari', 'Mastar', 'Emir']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  group('cleanRoot', () {
    test('harekeleri, noktalama ve Farsça harfleri temizler', () {
      expect(cleanRoot('كَتَب.'), 'كتب');
      expect(cleanRoot('فید'), 'فيد');
      expect(cleanRoot('قوس  مطر'), 'قوس مطر');
      expect(cleanRoot(null), '');
    });
  });

  testWidgets('AI hapları iki eylemi tetikler', (tester) async {
    var asked = 0;
    var more = 0;
    await tester.pumpWidget(
      _wrap(
        AiAssistPills(
          isDarkMode: false,
          onAsk: () => asked++,
          onMoreExamples: () => more++,
        ),
      ),
    );

    await tester.tap(find.text('Asistana sor'));
    await tester.tap(find.text('Daha fazla örnek'));

    expect([asked, more], [1, 1]);
  });

  testWidgets('örnek cümlenin Türkçesi de sağa yaslı', (tester) async {
    await tester.pumpWidget(
      _wrap(const ExampleSentences(word: _kitap, isDarkMode: false)),
    );

    final turkish = tester.widget<Text>(find.textContaining('Dün büyük'));
    expect(turkish.textAlign, TextAlign.right);
  });

  group('HomeEmptyState', () {
    testWidgets('günün kelimesine dokunmak aramayı tetikler', (tester) async {
      String? searched;
      await tester.pumpWidget(
        _wrap(
          HomeEmptyState(
            isDarkMode: false,
            onSearch: (t) => searched = t,
            today: DateTime(2026, 1, 1),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('word-of-day')));

      expect(searched, HomeEmptyState.wordOfDay(DateTime(2026, 1, 1)).$1);
      expect(find.byKey(const ValueKey('premium-link')), findsNothing);
    });

    test('günün kelimesi gün içinde sabit, günden güne değişir', () {
      final a = HomeEmptyState.wordOfDay(DateTime(2026, 3, 5, 8));
      final b = HomeEmptyState.wordOfDay(DateTime(2026, 3, 5, 23));
      final c = HomeEmptyState.wordOfDay(DateTime(2026, 3, 6));

      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
