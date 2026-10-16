import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/models/custom_word.dart';
import 'package:kavaid/models/quran_word_model.dart';
import 'package:kavaid/models/word_model.dart';

CustomWord saved(SaveTarget t) => CustomWord(
  id: 'x',
  arabic: t.arabic,
  turkish: t.turkish,
  harekeliKelime: t.harekeli,
  wordData: t.wordData,
  createdAt: DateTime(2026),
  listId: 'l1',
);

void main() {
  // Veride "kelime" alanı ortak, harekeli yazımı farklı iki kelime
  const yazdi = WordModel(kelime: 'كتب', harekeliKelime: 'كَتَبَ', anlam: 'yazdı');
  const yazsin = WordModel(kelime: 'كتب', harekeliKelime: 'لِيَكْتُبْ', anlam: 'yazsın');

  group('sözlük kelimesi eşleştirme', () {
    test('aynı kelime alanını paylaşan farklı kelimeler karışmaz', () {
      final record = saved(SaveTarget.fromWordModel(yazdi));

      expect(record.isSameItem('كتب', 'كَتَبَ'), isTrue);
      expect(record.isSameItem('كتب', 'لِيَكْتُبْ'), isFalse);
    });

    test('harekeli yazımı olmayan eski kayıtlar kelime alanıyla eşleşir', () {
      final legacy = CustomWord(
        id: 'o',
        arabic: 'كتاب',
        turkish: 'kitap',
        createdAt: DateTime(2025),
        listId: 'l1',
      );

      expect(legacy.isSameItem('كتاب', 'كِتَابٌ'), isTrue);
      expect(legacy.isSameItem('قلم', null), isFalse);
    });

    test('toWordModel kaydedilen veriyi geri verir', () {
      final back = saved(SaveTarget.fromWordModel(yazsin)).toWordModel();

      expect(back.harekeliKelime, 'لِيَكْتُبْ');
      expect(back.anlam, 'yazsın');
    });
  });

  group("Kur'an kelimesi", () {
    final quran = QuranWordModel.fromCsvRow([
      'كَتَبَ',
      'كتب',
      'yazdı, farz kıldı',
      '[Bakara:183] كُتِبَ عَلَيْكُمُ الصِّيَامُ - Oruç size farz kılındı',
    ]);

    test('kayıt anahtarı önekli; sözlük kelimesiyle çakışmaz', () {
      final record = saved(SaveTarget.fromQuran(quran));

      expect(record.kind, 'quran');
      expect(record.isSameItem('quran:كَتَبَ', null), isTrue);
      expect(record.isSameItem('كَتَبَ', 'كَتَبَ'), isFalse);
    });

    test('veri kayıttan eksiksiz geri yüklenir', () {
      final back = saved(SaveTarget.fromQuran(quran)).toQuranWord()!;

      expect(back.kelime, 'كَتَبَ');
      expect(back.kok, 'كتب');
      expect(back.anlamListesi, ['yazdı', 'farz kıldı']);
      expect(back.ayetOrnekleri.single.sureAyet, 'Bakara:183');
      expect(back.ayetOrnekleri.single.meal, 'Oruç size farz kılındı');
      expect(back.normalizedKelime, 'كتب');
    });

    test('kart modunda çökmemesi için WordModel de üretilir', () {
      final word = saved(SaveTarget.fromQuran(quran)).toWordModel();

      expect(word.harekeliKelime, 'كَتَبَ');
      expect(word.anlam, 'yazdı, farz kıldı');
    });
  });

  group('emsile fiili', () {
    final verb = {
      'id': 42,
      'anlamlar': ['yazmak', 'kaydetmek'],
      'emsile_24': [
        {'sira': 1, 'arapca': 'كَتَبَ'},
        {'sira': 2, 'arapca': 'يَكْتُبُ'},
      ],
      'cekimler': {'mazi': [], 'muzari': [], 'emir': []},
    };

    test('yalnızca kimlik ve özet saklanır', () {
      final t = SaveTarget.fromEmsile(verb);

      expect(t.arabic, 'emsile:42');
      expect(t.wordData['id'], 42);
      expect(t.wordData['mazi'], 'كَتَبَ');
      expect(t.wordData['muzari'], 'يَكْتُبُ');
      expect(t.wordData.containsKey('cekimler'), isFalse);
    });

    test('farklı fiiller birbirine karışmaz', () {
      final record = saved(SaveTarget.fromEmsile(verb));

      expect(record.kind, 'emsile');
      expect(record.isSameItem('emsile:42', null), isTrue);
      expect(record.isSameItem('emsile:43', null), isFalse);
    });

    test('kart modu için fiil çekimli WordModel üretilir', () {
      final word = saved(SaveTarget.fromEmsile(verb)).toWordModel();

      expect(word.kelime, 'كَتَبَ');
      expect(word.anlam, 'yazmak');
      expect(word.fiilCekimler?['muzariForm'], 'يَكْتُبُ');
    });
  });
}
