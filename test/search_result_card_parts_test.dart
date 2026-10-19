import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/models/word_model.dart';
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
      // Soluk ama opak (yarı saydam renk fontta koyu noktalar oluşturuyordu)
      expect(root.style!.color!.a, 1.0);
      expect(
        root.style!.color!.computeLuminance(),
        greaterThan(word.style!.color!.computeLuminance()),
      );
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

    test('kısa sorguda yalnızca kelime başları vurgulanır', () {
      expect(highlightSegments('kitap, yönelik', 'k'), [
        ('k', true),
        ('itap, yönelik', false),
      ]);
      expect(highlightSegments("Allah'a ait", 'a'), [
        ('A', true),
        ("llah'a ", false),
        ('a', true),
        ('it', false),
      ]);
    });

    test('sorgu yoksa metni olduğu gibi döner', () {
      expect(highlightSegments('kitap', null), [('kitap', false)]);
      expect(highlightSegments('kitap', ''), [('kitap', false)]);
    });
  });

  testWidgets('örnek cümlenin solundaki simge Arapçayı okutur', (tester) async {
    final spoken = <String>[];
    await tester.pumpWidget(
      _wrap(
        ExampleSentences(word: _kitap, isDarkMode: false, onSpeak: spoken.add),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('example-speak')).first);
    expect(spoken, hasLength(1));
    expect(spoken.first, contains('قَرَأْتُ'));
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

    await tester.tap(find.text("AI Asistan'a sor"));
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
}
