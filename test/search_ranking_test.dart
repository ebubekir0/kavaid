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

EntryRank? rankTurkish(
  String query,
  String meaning, {
  String harekeli = 'كلمة',
}) {
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
      final exact = rankTurkish(
        'kitap',
        'mektup, belge, yazı, eser, not, kitap',
      )!;
      final prefix = rankTurkish('kitap', 'kitapçı, kitabevi')!;
      expect(exact.rank, lessThan(prefix.rank));
    });

    test('iki harfli sorgu yalnızca tam kelime olarak eşleşir', () {
      expect(rankTurkish('su', 'temiz su'), isNotNull);
      expect(rankTurkish('su', 'susamak'), isNull);
      expect(rankTurkish('su', 'uzun süre'), isNull);
    });

    test(
      'Türkçe karakter katlamasıyla oluşan kelime ortası eşleşme sayılmaz',
      () {
        // "döküldü" katlanınca "dokuldu" olur ve içinde "okul" geçer.
        expect(rankTurkish('okul', 'döküldü, akıtıldı'), isNull);
        // Kelime başındaki çekimler ise bulunur: "ağaca" → "ağaç".
        expect(rankTurkish('ağaç', 'ağaca tırmanma'), isNotNull);
      },
    );
  });

  group('groupSearchResults', () {
    WordModel word(String w, {String tur = ''}) => WordModel(
      kelime: w,
      harekeliKelime: w,
      dilbilgiselOzellikler: tur.isEmpty ? null : {'tur': tur},
    );

    test(
      'tam, önek, başlık ve kök sırasını kurar; kısmi eşleşmeleri gizler',
      () {
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

        final grouped = groupSearchResults([
          rootVerb,
          partial,
          prefix,
          rootNoun,
          exact,
        ], (w) => types[w]);

        expect(grouped[0], exact);
        expect(grouped[1], prefix);
        expect(grouped[2], isA<SearchGroupHeader>());
        expect(grouped.sublist(3), [rootNoun, rootVerb]);
      },
    );

    test('türü bilinmeyen kelime (AI sonucu) gösterilir', () {
      final ai = word('x');
      expect(groupSearchResults([ai], (_) => null), [ai]);
    });
  });

  group('mastar araması', () {
    test('mastar geçmiş zamana çevrilir (ünlü uyumu, sert ünsüz)', () {
      String past(String q) => pastTenseOfInfinitive(foldLatin(q));
      expect(past('yazmak'), 'yazdi');
      expect(past('gitmek'), 'gitti');
      expect(past('okumak'), 'okudu');
      expect(past('görmek'), 'gordu');
      expect(past('içmek'), 'icti');
      expect(past('açmak'), 'acti');
      expect(past('söylemek'), 'soyledi');
      expect(past('yardım etmek'), 'yardim etti');
      expect(past('kitap'), '');
      expect(past('mak'), '');
    });

    test(
      'mastarla arayınca "yazdı" anlamlı temel fiil, "yazmak suretiyle"den önce gelir',
      () {
        final base = rankTurkish('yazmak', 'yazdı, kaydetti')!;
        final noise = rankTurkish('yazmak', 'bir yazıyla, yazmak suretiyle')!;
        expect(base.type, WordMatchType.exact);
        expect(base.rank, lessThan(noise.rank));
      },
    );
  });

  group('kopyaları birleştirme', () {
    WordModel w(
      String harekeli,
      String tur, {
      String koku = '',
      String anlam = '',
    }) => WordModel(
      kelime: harekeli,
      harekeliKelime: harekeli,
      koku: koku,
      anlam: anlam,
      dilbilgiselOzellikler: {'tur': tur},
    );

    test('isimde hal eki ve "el-" takısı aynı anahtara iner', () {
      final keys = [
        'بَيْتٌ',
        'بَيْتٍ',
        'الْبَيْتِ',
        'اَلْبَيْتُ',
      ].map((h) => nounLemmaKey(w(h, 'İsim'))).toSet();
      expect(keys, hasLength(1));
      // Güneş harfi: الشُّكْرُ ile شُكْرٌ aynı kelime
      expect(
        nounLemmaKey(w('الشُّكْرُ', 'İsim')),
        nounLemmaKey(w('شُكْرٌ', 'İsim')),
      );
      // İki harfli isimler de: الْأُمُّ ile أُمٌّ
      expect(
        nounLemmaKey(w('الْأُمُّ', 'İsim')),
        nounLemmaKey(w('أُمٌّ', 'İsim')),
      );
    });

    test('fiil ve zamir birleştirilmez, "الله"nin ال harfleri silinmez', () {
      expect(nounLemmaKey(w('كَتَبْتُ', 'Mazî Fiil')), isNull);
      expect(nounLemmaKey(w('لَهُ', 'Zamir')), isNull);
      expect(nounLemmaKey(w('اللَّهُ', 'Özel İsim')), 'اللَّه');
    });

    test('Türkçe aramada kopyalar tek sonuç olur, yalın biçim gösterilir', () {
      final r = collapseVariants([
        RankedWord(w('الْبَيْتِ', 'İsim'), WordMatchType.exact),
        RankedWord(
          w('كَتَبَ', 'Mazî Fiil', koku: 'كتب', anlam: 'yazdı, kaydetti'),
          WordMatchType.exact,
        ),
        RankedWord(w('بَيْتٌ', 'İsim'), WordMatchType.prefix),
        RankedWord(
          w('كَتَبَتِ', 'Mazî Fiil', koku: 'كتب', anlam: 'yazdı, not etti'),
          WordMatchType.exact,
        ),
      ], turkishQuery: true);
      expect(r.map((x) => x.word.harekeliKelime), ['بَيْتٌ', 'كَتَبَ']);
      // Grup, en iyi üyesinin eşleşme türünü alır
      expect(r.first.matchType, WordMatchType.exact);
    });

    test('Arapça aramada yazılan biçim korunur, fiil kişileri ayrı kalır', () {
      final r = collapseVariants([
        RankedWord(w('الْبَيْتِ', 'İsim'), WordMatchType.exact),
        RankedWord(w('بَيْتٌ', 'İsim'), WordMatchType.prefix),
        RankedWord(
          w('كَتَبْتُ', 'Mazî Fiil', koku: 'كتب', anlam: 'yazdım'),
          WordMatchType.exact,
        ),
        RankedWord(
          w('كَتَبْتَ', 'Mazî Fiil', koku: 'كتب', anlam: 'yazdın'),
          WordMatchType.exact,
        ),
      ], turkishQuery: false);
      expect(r.map((x) => x.word.harekeliKelime), [
        'الْبَيْتِ',
        'كَتَبْتُ',
        'كَتَبْتَ',
      ]);
    });
  });
}
