import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/data/embedded_words.dart';
import 'package:kavaid/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // İlk kurulum yolu: sözlük veritabanı için bir kez çözülür, arama izolesi
  // fihristini aynı listeden kurar (kendisi ikinci kez çözmez).
  test('arama izolesi veritabanı için çözülen listeyle kurulur', () async {
    final port = await DatabaseService.searchWordsPort();
    expect(port, isNotNull);

    final words = await EmbeddedWords.load();
    expect(words.length, embeddedWordsCount);
    port!.send(words);

    final results = await DatabaseService.instance.searchWords('كتاب');
    expect(results.first.harekeliKelime, 'كِتَابٌ');
    expect(
      (await DatabaseService.instance.searchWords('kitap')).map((w) => w.harekeliKelime),
      contains('كِتَابٌ'),
    );
  });
}
