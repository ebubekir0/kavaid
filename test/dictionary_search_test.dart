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

    test('Türkçe karaktersiz yazım aynı sonuçları verir', () async {
      final withChars = await DatabaseService.instance.searchWords('güzel');
      final without = await DatabaseService.instance.searchWords('guzel');

      expect(without, isNotEmpty);
      expect(
        without.map((w) => w.harekeliKelime).take(10),
        withChars.map((w) => w.harekeliKelime).take(10),
      );
    });

    test('Arapça yazım farkları (hemze, ة/ه, uzatma çizgisi) sonucu bulur', () async {
      Future<String?> first(String q) async =>
          (await DatabaseService.instance.searchWords(q)).firstOrNull?.harekeliKelime;

      expect(await first('اسلام'), 'إِسْلَامٌ');
      expect(await first('مدرسه'), 'مَدْرَسَةٌ');
      expect(await first('كـتـاب'), await first('كتاب'));
    });

    test('kısa ve sık kelimelerde temel karşılık ilk sırada gelir', () async {
      Future<String?> first(String q) async =>
          (await DatabaseService.instance.searchWords(q)).firstOrNull?.harekeliKelime;

      expect(await first('su'), 'مَاءٍ');
      expect(await first('ev'), 'بَيْتٌ');
      expect(await first('kitap'), 'كِتَابٌ');
      expect(await first('كتب'), 'كَتَبَ');
    });
  });
}
