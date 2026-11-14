import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/data/embedded_words.dart';
import 'package:kavaid/models/word_model.dart';
import 'package:kavaid/services/app_usage_service.dart';
import 'package:kavaid/services/word_share_service.dart';
import 'package:kavaid/widgets/word_share_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kataba = WordModel(
  kelime: 'كتب',
  harekeliKelime: 'كَتَبَ',
  anlam: 'yazdı, yazmak||HARFI_CER:عَلَى=farz kıldı',
  koku: 'ك ت ب',
  fiilCekimler: {
    'maziForm': 'كَتَبَ',
    'muzariForm': 'يَكْتُبُ',
    'mastarForm': 'كِتَابَةً',
  },
);

const _katabaWithExample = WordModel(
  kelime: 'كتب',
  harekeliKelime: 'كَتَبَ',
  koku: 'ك ت ب',
  ornekCumleler: [
    {'arapcaCumle': 'كَتَبَ الطَّالِبُ الدَّرْسَ', 'turkceCeviri': 'Öğrenci dersi yazdı.'},
  ],
);

/// Kart 360x640; varsayılan test ekranı (800x600) onu sıkıştırır. Telefon boyutunda ekran.
void _phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  // Sitedeki slugOf (site/src/lib/arabic.js) ile aynı sonucu vermeli; yoksa paylaşılan bağlantı
  // yönlendirmeyle ya da 404 ile açılır.
  group('WordShareService.slugOf', () {
    test('harekeler silinir', () {
      expect(WordShareService.slugOf('كَتَبَ'), 'كتب');
      expect(WordShareService.slugOf('مَدْرَسَةٌ'), 'مدرسة');
    });

    test('boşluklar tire olur', () {
      expect(WordShareService.slugOf('كُرَةُ الْقَدَمِ'), 'كرة-القدم');
      expect(WordShareService.slugOf('  شُكْرًا   لَكَ '), 'شكرا-لك');
    });

    test('vasl elifi ve Farsça harfler Arapçaya çevrilir', () {
      expect(WordShareService.slugOf('ٱلْحَمْدُ'), 'الحمد');
      expect(WordShareService.slugOf('کتاب'), 'كتاب');
      expect(WordShareService.slugOf('علی'), 'علي');
    });

    test('noktalama ve Latin harfler atılır', () {
      expect(WordShareService.slugOf('شُكْرًا!'), 'شكرا');
      expect(WordShareService.slugOf('abc'), '');
    });
  });

  test('bağlantı sözlük diline ve kelimenin sayfasına gider', () {
    final lang = EmbeddedWords.currentLang;
    expect(
      WordShareService.urlOf(_kataba),
      'https://kavaid.app/$lang/word/${Uri.encodeComponent('كتب')}?ref=app',
    );
  });

  test('paylaşılan anlam harf-i cerleri içermez', () {
    expect(WordShareService.meaningOf(_kataba), 'yazdı, yazmak');
  });

  group('Pakistan: İngilizce arayüzde sözlük Urduca açılır', () {
    test('cihaz ülkesi Pakistan', () {
      expect(EmbeddedWords.defaultFor('en', deviceCountry: 'PK'), 'ur');
    });

    test('başka ülke ya da başka arayüz dili etkilenmez', () {
      expect(EmbeddedWords.defaultFor('en', deviceCountry: 'US'), 'en');
      expect(EmbeddedWords.defaultFor('tr', deviceCountry: 'PK'), 'tr');
      expect(EmbeddedWords.defaultFor('id', deviceCountry: 'PK'), 'id');
      expect(EmbeddedWords.defaultFor('fr', deviceCountry: 'PK'), 'en');
    });
  });

  testWidgets('durum görseli 9:16; kelimeyi, kökü, anlamı, örneği ve site adresini gösterir', (tester) async {
    _phoneView(tester);
    await tester.pumpWidget(
      const Center(
        child: WordShareCard(word: _katabaWithExample, meaning: 'yazdı, yazmak', meaningLang: 'tr'),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(WordShareCard)), const Size(WordShareCard.width, WordShareCard.height));
    expect(find.text('كَتَبَ'), findsOneWidget);
    expect(find.text('ك  ت  ب'), findsOneWidget);
    expect(find.text('yazdı, yazmak'), findsOneWidget);
    expect(find.text('كَتَبَ الطَّالِبُ الدَّرْسَ'), findsOneWidget);
    expect(find.text('Öğrenci dersi yazdı.'), findsOneWidget);
    expect(find.text('kavaid.app'), findsOneWidget);
  });

  testWidgets('bütün arka planlar taşmadan çizilir, görselleri pakette var', (tester) async {
    _phoneView(tester);
    for (final background in ShareBackground.values) {
      await tester.pumpWidget(
        Center(child: WordShareCard(word: _kataba, meaning: 'yazdı, yazmak', meaningLang: 'tr', background: background)),
      );
      expect(tester.takeException(), isNull, reason: background.name);
      final bytes = await tester.runAsync(() => rootBundle.load(background.asset));
      expect(bytes!.lengthInBytes, greaterThan(10000), reason: background.asset);
    }
  });

  testWidgets('uzun anlam, uzun örnek ve Urduca da taşmaz', (tester) async {
    const long = WordModel(
      kelime: 'استقبل',
      harekeliKelime: 'اِسْتَقْبَلَ',
      koku: 'ق ب ل',
      ornekCumleler: [
        {
          'arapcaCumle': 'اِسْتَقْبَلَتِ الْعَائِلَةُ الضُّيُوفَ بِحَفَاوَةٍ كَبِيرَةٍ فِي بَيْتِهِمِ الْجَدِيدِ بَعْدَ الظُّهْرِ',
          'turkceCeviri': 'The family warmly welcomed the guests in their new house in the afternoon after lunch.',
        },
      ],
    );
    _phoneView(tester);
    for (final lang in ['en', 'ur', 'ar']) {
      await tester.pumpWidget(Center(
        child: WordShareCard(
          word: long,
          meaning: 'to receive, to welcome, to meet, to face the qibla, to greet someone arriving from a journey',
          meaningLang: lang,
        ),
      ));
      expect(tester.takeException(), isNull, reason: lang);
    }
  });

  testWidgets('paylaş önce önizleme açar; arka plan seçilir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => WordShareService.share(context, _kataba),
            child: const Text('aç'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('share-confirm')), findsOneWidget);
    expect(find.byType(WordShareCard), findsOneWidget);
    expect(find.byKey(const ValueKey('bg-dusk')), findsOneWidget);
    // Varsayılan arka plan akşam; ilk küçük resim seçilince önizleme değişir.
    expect(tester.widget<WordShareCard>(find.byType(WordShareCard)).background, ShareBackground.dusk);
    await tester.tap(find.byKey(const ValueKey('bg-night')));
    await tester.pumpAndSettle();
    expect(tester.widget<WordShareCard>(find.byType(WordShareCard)).background, ShareBackground.night);
    expect(tester.takeException(), isNull);
  });

  test('promosyon kodundan sonra değerlendirme kartı beklemeden açılır, bir kez', () async {
    SharedPreferences.setMockInitialValues({});
    final usage = AppUsageService();
    await usage.loadSaved();
    expect(usage.shouldShowRating, isFalse);

    await usage.unlockRatingPrompt();
    expect(usage.shouldShowRating, isTrue);

    // Karta dokunulduktan sonra yeni bir kod kartı geri getirmez.
    await usage.markRatingPromptClicked();
    await usage.unlockRatingPrompt();
    expect(usage.shouldShowRating, isFalse);
  });
}
