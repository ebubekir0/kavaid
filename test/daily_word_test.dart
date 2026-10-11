import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/services/daily_word.dart';
import 'package:kavaid/utils/arabic_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<DailyWord> words;

  setUpAll(() async {
    words = await DailyWords.load();
  });

  group('günün kelimeleri verisi', () {
    test('en az bir yıl boyunca tekrar etmeyecek kadar kelime var', () {
      expect(words.length, greaterThanOrEqualTo(300));
    });

    test('her kaydın alanları dolu ve kök düzgün biçimlenir', () {
      for (final w in words) {
        expect(w.arabic, isNotEmpty);
        expect(w.meaning, isNotEmpty, reason: w.arabic);
        expect(w.exampleArabic, isNotEmpty, reason: w.arabic);
        expect(w.exampleTurkish, isNotEmpty, reason: w.arabic);
        expect(formatRoot(w.root), isNotEmpty, reason: w.arabic);
        expect(
          ['İsim', 'Sıfat', 'Mastar', 'Mazî Fiil', 'Fiil'],
          contains(w.type),
          reason: w.arabic,
        );
      }
    });

    test('aynı kelime iki kez yer almaz', () {
      final plain = words.map((w) => stripArabicMarks(w.arabic)).toList();
      expect(plain.toSet().length, plain.length);
    });

    test('kelime harekeli Arapça harflerden oluşur', () {
      final arabicOnly = RegExp(r'^[ء-يً-ْٰ]+$');
      for (final w in words) {
        expect(arabicOnly.hasMatch(w.arabic), isTrue, reason: w.arabic);
      }
    });
  });

  group('günün kelimesi seçimi', () {
    test('aynı gün içinde saat fark etmeksizin aynı kelime gelir', () {
      final morning = DailyWords.forDate(words, DateTime(2026, 10, 11, 0, 5));
      final night = DailyWords.forDate(words, DateTime(2026, 10, 11, 23, 59));

      expect(morning.arabic, night.arabic);
    });

    test('ardışık günlerde farklı kelime gelir', () {
      final seen = <String>{};
      for (var i = 0; i < 300; i++) {
        seen.add(DailyWords.forDate(words, DateTime(2026, 1, 1 + i)).arabic);
      }

      expect(seen.length, 300);
    });

    test('liste bitince başa döner', () {
      final first = DailyWords.forDate(words, DateTime(2026, 1, 1));
      final wrapped = DailyWords.forDate(
        words,
        DateTime(2026, 1, 1).add(Duration(days: words.length)),
      );

      expect(wrapped.arabic, first.arabic);
    });

    test('başlangıç tarihinden önceki günlerde de bir kelime gelir', () {
      expect(() => DailyWords.forDate(words, DateTime(2025, 6, 1)), returnsNormally);
    });

    test('today() kelime döndürür', () async {
      final word = await DailyWords.today(now: DateTime(2026, 3, 15));

      expect(word, isNotNull);
      expect(word!.arabic, DailyWords.forDate(words, DateTime(2026, 3, 15)).arabic);
    });
  });
}
