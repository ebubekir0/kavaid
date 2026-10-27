import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/data/embedded_words.dart';
import 'package:kavaid/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Her sözlük dilinde arama: o dilde yazılan yaygın kelimeler doğru Arapça
/// karşılığı ilk sıralarda bulmalı. Süreler bilgi için yazdırılır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('telefon dili → varsayılan sözlük dili', () {
    expect(EmbeddedWords.defaultFor('tr'), 'tr');
    for (final lang in ['en', 'ar', 'id', 'ms', 'ur']) {
      expect(EmbeddedWords.defaultFor(lang), lang);
    }
    // Kendi sözlüğü olmayan arayüz dilleri İngilizce sözlükle açılır
    for (final lang in ['de', 'fr', 'ru', 'az', 'uz', 'bn']) {
      expect(EmbeddedWords.defaultFor(lang), 'en');
    }
  });

  // dil -> (sorgu -> ilk 5 sonuçta beklenen başlık)
  const cases = {
    'tr': {'kitap': 'كِتَابٌ', 'su': 'مَاءٍ', 'yazmak': 'كَتَبَ'},
    'en': {'book': 'كِتَابٌ', 'water': 'مَاءٍ', 'write': 'كَتَبَ'},
    'id': {'buku': 'كِتَابٌ', 'air': 'مَاءٍ', 'menulis': 'كَتَبَ'},
    'ms': {'buku': 'كِتَابٌ', 'air': 'مَاءٍ', 'menulis': 'كَتَبَ'},
    // Urduca klavye ک/ی yazar; Arapça başlıkta da aranır
    'ur': {'کتاب': 'كِتَابٌ', 'پانی': 'مَاءٍ', 'لکھنا': 'كَتَبَ'},
    'ar': {'كتاب': 'كِتَابٌ', 'ماء': 'مَاءٍ', 'كتب': 'كَتَبَ'},
  };

  for (final MapEntry(key: lang, value: queries) in cases.entries) {
    test('$lang: yaygın kelimeler doğru karşılığı bulur', () async {
      SharedPreferences.setMockInitialValues({'flutter.meaning_lang': lang});
      DatabaseService.restartSearch();
      await DatabaseService.ensureSearchCacheReady();

      final times = <String>[];
      for (final MapEntry(key: query, value: expected) in queries.entries) {
        final sw = Stopwatch()..start();
        final results = await DatabaseService.instance.searchWords(query);
        times.add('$query ${sw.elapsedMilliseconds}ms');
        final top = results.take(5).map((w) => w.harekeliKelime).toList();
        expect(top, contains(expected), reason: '$lang "$query" → $top');
        // Temel karşılık ilk sırada (emir kipi ya da mastar önüne geçmesin)
        expect(top.first, expected, reason: '$lang "$query" → $top');
      }
      // ignore: avoid_print
      print('$lang: ${times.join(', ')}');
    });
  }
}
