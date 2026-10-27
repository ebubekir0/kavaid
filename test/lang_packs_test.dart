import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/data/embedded_words.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Map<String, dynamic>> kitapIn(String lang) async {
    SharedPreferences.setMockInitialValues({'flutter.meaning_lang': lang});
    final words = await EmbeddedWords.load();
    expect(words.length, embeddedWordsCount);
    return words.firstWhere((w) => w['harekeliKelime'] == 'كِتَابٌ');
  }

  test('Türkçe: temel veri değişmez', () async {
    final w = await kitapIn('tr');
    expect(w['anlam'] as String, contains('kitap'));
    expect((w['dilbilgiselOzellikler'] as Map).containsKey('arDef'), isFalse);
  });

  for (final (lang, expected) in [('en', 'book'), ('id', 'buku'), ('ms', 'buku'), ('ur', 'کتاب')]) {
    test('$lang: anlam ve örnek çevirileri o dilde', () async {
      final w = await kitapIn(lang);
      expect((w['anlam'] as String).toLowerCase(), contains(expected));
      final examples = (w['ornekCumleler'] as List).cast<Map>();
      expect(examples, isNotEmpty);
      expect(examples.first['turkceCeviri'], isNot(contains('kitap')));
      expect(examples.first['arapcaCumle'], isNotEmpty);
    });
  }

  test('ar: Arapça madde eklenir, anlam İngilizce kalır', () async {
    final w = await kitapIn('ar');
    final arDef = (w['dilbilgiselOzellikler'] as Map)['arDef'] as Map;
    expect(arDef['s'] as List, isNotEmpty);
    expect((w['anlam'] as String).toLowerCase(), contains('book'));
  });

  test('her dilin veri sürümü farklı', () async {
    final versions = <String>{};
    for (final lang in EmbeddedWords.availableLangs) {
      SharedPreferences.setMockInitialValues({'flutter.meaning_lang': lang});
      versions.add(await EmbeddedWords.currentVersion());
    }
    expect(versions.length, EmbeddedWords.availableLangs.length);
  });
}
