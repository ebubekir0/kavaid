import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/data/embedded_words.dart';
import 'package:kavaid/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sözlük asset\'i çözülüyor ve kelime sayısı meta ile tutarlı', () async {
    final words = await EmbeddedWords.load();

    expect(words.length, embeddedWordsCount);
    expect(words.every((w) => w.containsKey('kelime')), isTrue);
  });

  group('bellek içi arama', () {
    setUpAll(DatabaseService.ensureSearchCacheReady);

    test('Arapça sorguda tam eşleşme ilk sırada gelir', () async {
      final results = await DatabaseService.instance.searchWords('كتاب');

      expect(results, isNotEmpty);
      expect(results.first.harekeliKelime, 'كِتَابٌ');
    });

    test('Türkçe anlamla arama Arapça karşılığı bulur', () async {
      final results = await DatabaseService.instance.searchWords('kitap');

      expect(results.map((w) => w.harekeliKelime), contains('كِتَابٌ'));
    });

    test('eşleşmeyen sorgu boş liste döner', () async {
      expect(await DatabaseService.instance.searchWords('xyzxyz'), isEmpty);
    });
  });
}
