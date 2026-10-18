import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/models/quran_word_model.dart';
import 'package:kavaid/services/search_ranking.dart';

void main() {
  group('Kuran sözlüğü araması yazım farklarına duyarsız', () {
    final word = QuranWordModel.fromCsvRow(['أَكَلَ', 'أكل', 'Yemek, Çok yemek']);

    test('hemzeli elif düz elifle aranabilir', () {
      expect(word.normalizedKelime, normalizeArabic('اكل'));
      expect(word.normalizedKok, normalizeArabic('اكل'));
    });

    test('Türkçe karakter olmadan aranabilir', () {
      expect(word.normalizedAnlamlar.contains(foldLatin('cok')), isTrue);
    });

    test('kayıtlı listeden yüklenen kelime de aynı biçimde', () {
      final fromMap = QuranWordModel.fromMap(word.toMap());
      expect(fromMap.normalizedKelime, word.normalizedKelime);
      expect(fromMap.normalizedAnlamlar, word.normalizedAnlamlar);
    });
  });
}
