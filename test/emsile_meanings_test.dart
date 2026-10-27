import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/data/embedded_words.dart';
import 'package:kavaid/services/emsile_meanings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Emsile (çekim) bölümünde fiil anlamları sözlük dilinde; Türkçe kalmamalı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // emsile.db: 4819 = كَتَبَ (yazdı; sözlükte fiil maddesi var),
  // 1 = ءَامَنَ (iman etti; fiil maddesi yok, masdarı إِيمَانًا'nın anlamı gelir)
  const ketebe = 4819, amene = 1;

  for (final (lang, write) in [
    ('en', 'write'),
    ('id', 'menulis'),
    ('ms', 'menulis'),
    ('ur', 'لکھنا'),
  ]) {
    test('$lang: anlamlar o dilde, anlamla arama fiili bulur', () async {
      SharedPreferences.setMockInitialValues({'flutter.meaning_lang': lang});
      await EmbeddedWords.meaningLang();
      final meanings = EmsileMeanings.instance;
      expect(meanings.usesPack, isTrue);
      await meanings.ensureLoaded();

      final ketebeMeanings = meanings.of(ketebe)!;
      expect(ketebeMeanings.join(' ').toLowerCase(), contains(write));
      expect(ketebeMeanings.join(' '), isNot(contains('yazdı')));
      final ameneMeanings = meanings.of(amene)!;
      expect(ameneMeanings, isNotEmpty);
      expect(ameneMeanings.join(' '), isNot(contains('iman etti')));

      expect(meanings.search(write).take(10), contains(ketebe));
    });
  }

  test('tr ve ar paket kullanmaz', () async {
    for (final lang in ['tr', 'ar']) {
      SharedPreferences.setMockInitialValues({'flutter.meaning_lang': lang});
      await EmbeddedWords.meaningLang();
      expect(EmsileMeanings.instance.usesPack, isFalse);
    }
  });
}
