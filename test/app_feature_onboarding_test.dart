import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/widgets/app_feature_onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tracks whether onboarding was shown', () async {
    expect(await AppFeatureOnboarding.shouldShow(), isTrue);
    await AppFeatureOnboarding.markAsShown();
    expect(await AppFeatureOnboarding.shouldShow(), isFalse);
  });

  testWidgets('shows feature pages and finish button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppFeatureOnboarding(isDarkMode: false)),
      ),
    );

    expect(find.text('Kavaid’e hoş geldin'), findsOneWidget);
    expect(find.text('Arapça sözlük'), findsOneWidget);
    expect(find.text('Devam'), findsOneWidget);
  });
}
