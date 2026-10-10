import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/models/word_model.dart';
import 'package:kavaid/services/search_ranking.dart';

EntryRank? rankArabic(String query, String harekeli, {String koku = ''}) {
  final q = SearchQuery.parse(query);
  return rankEntry(
    query: q,
    kelime: '',
    harekeli: harekeli,
    koku: koku,
    nKelime: '',
    nHarekeli: normalizeArabic(harekeli),
    nKoku: normalizeArabic(koku),
    meanings: '',
  );
}

EntryRank? rankTurkish(String query, String meaning, {String harekeli = 'كلمة'}) {
  final q = SearchQuery.parse(query);
  return rankEntry(
    query: q,
    kelime: '',
    harekeli: harekeli,
    koku: '',
    nKelime: '',
    nHarekeli: normalizeArabic(harekeli),
    nKoku: '',
    meanings: foldLatin(meaning),
    rawMeaning: meaning,
  );
}

void main() {
  group('normalizeArabic', () {
    test('harekeleri ve uzatma çizgisini siler', () {
      expect(normalizeArabic('كِتَابٌ'), 'كتاب');
      expect(normalizeArabic('كـتـاب'), 'كتاب');
    });

    test('hemze, ta marbuta ve Farsça harfleri tek biçime indirir', () {
      expect(normalizeArabic('إسلام'), normalizeArabic('اسلام'));
      expect(normalizeArabic('مدرسة'), normalizeArabic('مدرسه'));
      expect(normalizeArabic('کتاب'), normalizeArabic('كتاب'));
      expect(normalizeArabic('علی'), normalizeArabic('علي'));
    });
  });

  group('foldLatin', () {
    test('Türkçe karakterleri ve büyük harfleri katlar', () {
      expect(foldLatin('Güzel'), 'guzel');
      expect(foldLatin('ÖĞRETMEN'), 'ogretmen');
      expect(foldLatin('İstanbul'), 'istanbul');
      expect(foldLatin('Işık'), 'isik');
    });

    test('foldTurkishChar uzunluğu korur', () {
      for (final ch in 'İIıÇçĞğÖöŞşÜüAz'.split('')) {
        expect(foldTurkishChar(ch).length, 1, reason: ch);
      }
    });
  });

  group('Arapça puanlama', () {
    test('harekeli yazım birebir aynıysa en üst puan', () {
      expect(rankArabic('كِتَابٌ', 'كِتَابٌ')!.rank, 0);
      expect(rankArabic('كتاب', 'كِتَابٌ')!.rank, 1);
    });

    test('hemzesiz ve ه ile yazılan sorgu tam eşleşme bulur', () {
      expect(rankArabic('اسلام', 'إِسْلَامٌ')!.type, WordMatchType.exact);
      expect(rankArabic('مدرسه', 'مَدْرَسَةٌ')!.type, WordMatchType.exact);
    });

    test('önek, kök ve kısmi eşleşmeleri ayırt eder', () {
      expect(rankArabic('كتا', 'كِتَابٌ')!.type, WordMatchType.prefix);
      expect(
        rankArabic('كتب', 'مَكْتَبَةٌ', koku: 'كتب')!.type,
        WordMatchType.root,
      );
      expect(rankArabic('تاب', 'كِتَابٌ')!.type, WordMatchType.partial);
      expect(rankArabic('قلم', 'كِتَابٌ'), isNull);
    });
  });

  group('Türkçe puanlama', () {
    test('Türkçe karaktersiz yazım da eşleşir', () {
      expect(rankTurkish('guzel', 'güzel, hoş')!.type, WordMatchType.exact);
      expect(rankTurkish('ogretmen', 'öğretmen, hoca'), isNotNull);
    });

    test('yazımı birebir uyan anlam öne geçer (su / şu)', () {
      final water = rankTurkish('su', 'su, sıvı')!;
      final that = rankTurkish('su', 'şu, o')!;
      expect(water.rank, lessThan(that.rank));

      final thatForSu = rankTurkish('şu', 'şu, o')!;
      final waterForSu = rankTurkish('şu', 'su, sıvı')!;
      expect(thatForSu.rank, lessThan(waterForSu.rank));
    });

    test('tam anlam eşleşmesi kelime başı eşleşmesinden önce gelir', () {
      final exact = rankTurkish('kitap', 'mektup, belge, yazı, eser, not, kitap')!;
      final prefix = rankTurkish('kitap', 'kitapçı, kitabevi')!;
      expect(exact.rank, lessThan(prefix.rank));
    });

    test('iki harfli sorgu yalnızca tam kelime olarak eşleşir', () {
      expect(rankTurkish('su', 'temiz su'), isNotNull);
      expect(rankTurkish('su', 'susamak'), isNull);
      expect(rankTurkish('su', 'uzun süre'), isNull);
    });

    test('Türkçe karakter katlamasıyla oluşan kelime ortası eşleşme sayılmaz', () {
      // "döküldü" katlanınca "dokuldu" olur ve içinde "okul" geçer.
      expect(rankTurkish('okul', 'döküldü, akıtıldı'), isNull);
      // Kelime başındaki çekimler ise bulunur: "ağaca" → "ağaç".
      expect(rankTurkish('ağaç', 'ağaca tırmanma'), isNotNull);
    });
  });

  group('groupSearchResults', () {
    WordModel word(String w, {String tur = ''}) => WordModel(
      kelime: w,
      harekeliKelime: w,
      dilbilgiselOzellikler: tur.isEmpty ? null : {'tur': tur},
    );

    test('tam, önek, başlık ve kök sırasını kurar; kısmi eşleşmeleri gizler', () {
      final exact = word('a');
      final prefix = word('b');
      final rootVerb = word('c', tur: 'Fiil');
      final rootNoun = word('d', tur: 'İsim');
      final partial = word('e');
      final types = {
        exact: WordMatchType.exact,
        prefix: WordMatchType.prefix,
        rootVerb: WordMatchType.root,
        rootNoun: WordMatchType.root,
        partial: WordMatchType.partial,
      };

      final grouped = groupSearchResults(
        [rootVerb, partial, prefix, rootNoun, exact],
        (w) => types[w],
      );

      expect(grouped[0], exact);
      expect(grouped[1], prefix);
      expect(grouped[2], isA<SearchGroupHeader>());
      expect(grouped.sublist(3), [rootNoun, rootVerb]);
    });

    test('türü bilinmeyen kelime (AI sonucu) gösterilir', () {
      final ai = word('x');
      expect(groupSearchResults([ai], (_) => null), [ai]);
    });
  });
}
