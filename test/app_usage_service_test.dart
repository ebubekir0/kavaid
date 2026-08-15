import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/services/app_usage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppUsageService().resetUsageStats();
  });

  test('rating prompt is shown only after more than five minutes', () async {
    final service = AppUsageService();

    await service.setUsageTimeForTest(5);
    expect(service.shouldShowRatingForTest, isFalse);

    await service.setUsageTimeForTest(6);
    expect(service.shouldShowRatingForTest, isTrue);
  });

  test('rating prompt is hidden after it is clicked', () async {
    final service = AppUsageService();

    await service.setUsageTimeForTest(6);
    expect(service.shouldShowRatingForTest, isTrue);

    await service.markRatingPromptClicked();
    expect(service.shouldShowRatingForTest, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('has_clicked_rating_prompt_after_update_v1'), isTrue);
  });
}
