import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/services/language_service.dart';
import 'package:kavaid/widgets/app_intro_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => AppIntroScreen.show(context, isDarkMode: false),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('aç'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('yeni kurulumda tanıtım bekler, güncelleme alanda beklemez', () async {
    SharedPreferences.setMockInitialValues({});
    await LanguageService().initialize();
    expect(await AppIntroScreen.shouldShow(), isTrue);

    SharedPreferences.setMockInitialValues({'is_first_launch': false});
    await LanguageService().initialize();
    expect(await AppIntroScreen.shouldShow(), isFalse);
  });

  testWidgets('tüm sayfalar gezilir, Başla ile kapanır ve bir daha çıkmaz', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      LanguageService.appIntroPendingKey: true,
    });
    // Metinler Türkçe arayüze göre; test ortamının dili İngilizce olabilir
    await LanguageService().changeLanguage('tr');
    await _open(tester);
    expect(find.text('Arapça–Türkçe sözlük'), findsOneWidget);

    var pages = 1;
    while (find.text('Devam').evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('intro-next')));
      await tester.pumpAndSettle();
      pages++;
    }
    expect(pages, 8);
    expect(find.text('Öğren'), findsOneWidget);

    await tester.tap(find.byKey(const Key('intro-next')));
    await tester.pumpAndSettle();
    expect(find.byType(AppIntroScreen), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(LanguageService.appIntroPendingKey), isFalse);
    // AI sayfası görüldü: ana ekrandaki AI tanıtım kartı tekrar çıkmaz.
    expect(prefs.getBool('ai_intro_seen_v1'), isTrue);
    expect(await AppIntroScreen.shouldShow(), isFalse);
  });

  testWidgets('Geç ile kapanır; AI sayfası görülmediyse AI kartı kalır', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      LanguageService.appIntroPendingKey: true,
    });
    await _open(tester);
    await tester.tap(find.byKey(const Key('intro-skip')));
    await tester.pumpAndSettle();
    expect(find.byType(AppIntroScreen), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(LanguageService.appIntroPendingKey), isFalse);
    expect(prefs.getBool('ai_intro_seen_v1'), isNull);
  });
}
