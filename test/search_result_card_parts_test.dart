import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      expect(root.style!.color!.a, lessThan(word.style!.color!.a));
      expect(find.text('İsim'), findsOneWidget);
    });

    testWidgets('harfleri boşluklu kök bitişik gösterilir', (tester) async {
      const word = WordModel(
        kelime: 'ضب',
        harekeliKelime: 'ضَبٌّ',
        koku: 'ض ب ب',
        dilbilgiselOzellikler: {'tur': 'İsim'},
      );
      await tester.pumpWidget(_wrap(const WordHeadline(word: word, isDarkMode: false)));

      expect(tester.widget<Text>(find.byKey(const ValueKey('word-root'))).data, 'ضبب');
    });

    testWidgets('kök kelimeyle aynı satırda, kendi boyutunda durur', (tester) async {
      await tester.pumpWidget(_wrap(const WordHeadline(word: _kitap, isDarkMode: false)));

      final root = tester.widget<Text>(find.byKey(const ValueKey('word-root')));
      expect(root.style!.fontSize, 18);
      final wordRect = tester.getRect(find.text('كِتَابٌ'));
      final rootRect = tester.getRect(find.byKey(const ValueKey('word-root')));
      // aynı satırda, kelimenin hemen yanında
      expect((wordRect.center.dy - rootRect.center.dy).abs(), lessThan(wordRect.height));
      expect(rootRect.left, greaterThanOrEqualTo(wordRect.right));
      expect(rootRect.left - wordRect.right, lessThan(20));
    });

    testWidgets('dar ekranda tür etiketi küçülmez, alt satıra iner', (tester) async {
      const word = WordModel(
        kelime: 'قوس المطر',
        harekeliKelime: 'قَوْسُ الْمَطَرِ',
        koku: 'قوس مطر',
        dilbilgiselOzellikler: {'tur': 'İsim Tamlaması'},
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 210,
              child: WordHeadline(word: word, isDarkMode: false),
            ),
          ),
        ),
      );

      final chip = tester.widget<Text>(find.text('İsim Tamlaması'));
      expect(chip.style!.fontSize, 10); // küçülmedi
      expect(chip.overflow, isNot(TextOverflow.ellipsis)); // kesilmedi
      final wordRect = tester.getRect(find.text('قَوْسُ الْمَطَرِ'));
      final chipRect = tester.getRect(find.text('İsim Tamlaması'));
      expect(chipRect.top, greaterThanOrEqualTo(wordRect.bottom - 1)); // alt satırda
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

  testWidgets('örnek cümleler sağdan sola: Arapça ve Türkçe sağa yaslı', (tester) async {
    await tester.pumpWidget(
      _wrap(const ExampleSentences(word: _kitap, isDarkMode: false)),
    );

    final arabic = tester.widget<Text>(find.textContaining('قَرَأْتُ'));
    final turkish = tester.widget<Text>(find.textContaining('Dün büyük'));

    expect(arabic.textDirection, TextDirection.rtl);
    expect(arabic.textAlign, TextAlign.start); // rtl'de start = sağ
    expect(turkish.textAlign, TextAlign.right);

    // İkisi de kutunun sağ kenarında biter
    final box = tester.getRect(find.byType(ExampleSentences));
    final arabicRect = tester.getRect(find.textContaining('قَرَأْتُ'));
    final turkishRect = tester.getRect(find.textContaining('Dün büyük'));
    expect(arabicRect.right, closeTo(turkishRect.right, 0.5));
    expect(box.right - arabicRect.right, lessThan(30));
  });

  testWidgets('örnek cümlede Arapça yazı, Türkçeden belirgin büyüktür', (tester) async {
    await tester.pumpWidget(
      _wrap(const ExampleSentences(word: _kitap, isDarkMode: false)),
    );

    final arabic = tester.widget<Text>(find.textContaining('قَرَأْتُ'));
    final turkish = tester.widget<Text>(find.textContaining('Dün büyük'));

    expect(arabic.style!.fontSize, 20);
    expect(turkish.style!.fontSize, 14);
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

  group('AiAssistStrip', () {
    testWidgets('serbest soru satırı boş sohbet açar', (tester) async {
      final asked = <String?>[];
      await tester.pumpWidget(
        _wrap(AiAssistStrip(word: _kitap, isDarkMode: false, onAsk: asked.add)),
      );

      await tester.tap(find.text('Asistana sor'));

      expect(asked, [null]);
    });

    testWidgets('hazır sorular kendi mesajlarıyla sohbet açar', (tester) async {
      final asked = <String?>[];
      await tester.pumpWidget(
        _wrap(AiAssistStrip(word: _kitap, isDarkMode: false, onAsk: asked.add)),
      );

      await tester.tap(find.text('Daha fazla örnek'));
      await tester.tap(find.text('Benzer kelimeler'));

      expect(asked, hasLength(2));
      expect(asked[0], contains('5 yeni örnek'));
      expect(asked[1], contains('benzeyen kelimeler'));
    });

    testWidgets('kelime hakkında olduğunu gösterir', (tester) async {
      await tester.pumpWidget(
        _wrap(AiAssistStrip(word: _kitap, isDarkMode: false, onAsk: (_) {})),
      );

      expect(find.textContaining('hakkında soru sor', findRichText: true), findsOneWidget);
    });

    testWidgets('360 px genişlikte iki hazır soru tek satıra sığar', (tester) async {
      // Test ortamının varsayılan fontu her harfi kare çizer; gerçek yazı
      // genişliği için uygulamanın fontu yüklenir.
      await tester.runAsync(() async {
        final loader = FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf'));
        await loader.load();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter'),
          home: Scaffold(
            body: SizedBox(
              width: 296,
              child: AiAssistStrip(word: _kitap, isDarkMode: false, onAsk: (_) {}),
            ),
          ),
        ),
      );

      final first = tester.getRect(find.text('Daha fazla örnek'));
      final second = tester.getRect(find.text('Benzer kelimeler'));
      expect((first.center.dy - second.center.dy).abs(), lessThan(2));
    });
  });

  group('kart butonları', () {
    testWidgets('AiTileButton dokunmayı iletir ve ekran okuyucuya adını söyler', (tester) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(AiTileButton(onTap: () => taps++, isDarkMode: false)),
      );

      await tester.tap(find.byType(AiTileButton));

      expect(taps, 1);
      expect(find.bySemanticsLabel('Asistana sor'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('CardIconButton 32 px dokunma alanı sunar ve adı okunur', (tester) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          Center(
            child: CardIconButton(
              icon: Icons.volume_up_rounded,
              label: 'Seslendir',
              onTap: () => taps++,
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CardIconButton));

      expect(taps, 1);
      expect(tester.getSize(find.byType(CardIconButton)), const Size(32, 32));
      expect(find.bySemanticsLabel('Seslendir'), findsOneWidget);
      semantics.dispose();
    });
  });
}
