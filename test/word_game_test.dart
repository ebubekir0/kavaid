import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/l10n/l10n.dart';
import 'package:kavaid/screens/game/game_screen.dart';
import 'package:kavaid/services/word_game_service.dart';
import 'package:kavaid/widgets/game/letter_wheel.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<List<GameWord>> _levelsOf(String lang) =>
    WordGameService.parseLevels(File('assets/data/oyun/$lang.json').readAsStringSync());

void _phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Oyunu açar. Bölüm dosyası gerçek dosya okuması istediği için önce runAsync ile yüklenir.
Future<List<List<GameWord>>> _open(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
  DateTime Function()? now,
}) async {
  SharedPreferences.setMockInitialValues(saved);
  _phoneView(tester);
  final levels = (await tester.runAsync(() => WordGameService.loadLevels('tr')))!;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: GameScreen(isDarkMode: false, lang: 'tr', bottomPadding: 110, now: now),
    ),
  ));
  await tester.pump();
  await tester.pump();
  return levels;
}

/// Çarkta [letters] harflerini sırayla sürükler (aynı harf iki kez varsa ayrı taşlar kullanılır).
Future<void> _swipe(WidgetTester tester, List<String> letters) async {
  final wheel = tester.widget<LetterWheel>(find.byType(LetterWheel));
  final origin = tester.getTopLeft(find.byType(LetterWheel));
  final used = <int>{};
  final path = <Offset>[];
  for (final letter in letters) {
    final i = List.generate(wheel.letters.length, (k) => k)
        .firstWhere((k) => wheel.letters[k] == letter && !used.contains(k));
    used.add(i);
    path.add(origin + LetterWheel.centerOf(i, wheel.letters.length, wheel.size));
  }
  final gesture = await tester.startGesture(path.first);
  for (final p in path.skip(1)) {
    await gesture.moveTo(p);
  }
  await gesture.up();
  await tester.pump();
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

void main() {
  group('bölüm verisi', () {
    final tr = _levelsOf('tr');

    test('300 bölüm, her bölümde 5 kelime; kelimeler 3-6 harf, ipucu dolu', () {
      expect(tr, hasLength(300));
      for (final level in tr) {
        expect(level, hasLength(5));
        for (final w in level) {
          expect(w.letters.length, inInclusiveRange(3, 6), reason: w.display);
          expect(RegExp(r'^[ء-ي]+$').hasMatch(w.answer), isTrue, reason: w.display);
          expect(w.display, isNot(w.answer), reason: 'harekeli olmalı: ${w.display}');
          expect(w.clue.trim(), isNotEmpty, reason: w.display);
        }
      }
    });

    test('her dilde aynı kelimeler, o dilde ipucu', () {
      for (final lang in WordGameService.supportedLangs.where((l) => l != 'tr')) {
        final other = _levelsOf(lang);
        expect(other, hasLength(tr.length), reason: lang);
        for (var i = 0; i < tr.length; i++) {
          expect([for (final w in other[i]) w.display], [for (final w in tr[i]) w.display],
              reason: '$lang bölüm ${i + 1}');
          for (final w in other[i]) {
            expect(w.clue.trim(), isNotEmpty, reason: '$lang ${w.display}');
          }
        }
      }
    });

    test('bir kelime oyunda bir kez geçer', () {
      final all = [for (final level in tr) for (final w in level) w.answer];
      expect(all.toSet(), hasLength(all.length));
    });

    test('Arapça ipucu cevabın kendisini içermez', () {
      for (final level in _levelsOf('ar')) {
        for (final w in level) {
          final plain = GameWord(w.clue, '').answer.split(RegExp(r'\s+'));
          expect(plain, isNot(contains(w.answer)), reason: w.display);
        }
      }
    });
  });

  group('çark', () {
    final word = GameWord('مَدْرَسَةٌ', 'okul');

    test('kelimenin bütün harfleri çarktadır; ilk bölümlerde fazladan harf yok', () {
      final wheel = WordGameService.wheelLetters(word, level: 0, question: 0);
      expect(wheel..sort(), [...word.letters]..sort());
    });

    test('ileri bölümlerde şaşırtmaca harf eklenir, çark 7 harfi geçmez', () {
      expect(WordGameService.wheelLetters(word, level: 20, question: 0), hasLength(6));
      expect(WordGameService.wheelLetters(word, level: 100, question: 0), hasLength(7));
      final six = GameWord('مَجْمُوعَةٌ', 'grup');
      expect(WordGameService.wheelLetters(six, level: 150, question: 0), hasLength(7));
    });

    test('aynı soru için dizilim sabittir; karıştırınca değişir, harfler aynı kalır', () {
      final a = WordGameService.wheelLetters(word, level: 150, question: 2);
      final b = WordGameService.wheelLetters(word, level: 150, question: 2);
      final c = WordGameService.wheelLetters(word, level: 150, question: 2, shuffle: 1);
      expect(a, b);
      expect(c, isNot(a));
      expect([...c]..sort(), [...a]..sort());
    });

    test('çark cevabı hazır sırada vermez', () {
      for (var q = 0; q < 50; q++) {
        final wheel = WordGameService.wheelLetters(GameWord('بَيْتٌ', 'ev'), level: 0, question: q);
        expect(wheel.join(), isNot('بيت'));
      }
    });
  });

  group('günlük seri', () {
    test('ilk gün 1 olur ve ödül verir; aynı gün ikinci kez sayılmaz', () {
      final p = GameProgress();
      expect(WordGameService.registerDay(p, DateTime(2026, 11, 13, 9)), isTrue);
      expect(p.streak, 1);
      expect(p.points, WordGameService.startPoints + WordGameService.dailyBonus);
      expect(WordGameService.registerDay(p, DateTime(2026, 11, 13, 23)), isFalse);
      expect(p.streak, 1);
    });

    test('ertesi gün uzar, ay sonunda da; bir gün atlanırsa 1e döner', () {
      final p = GameProgress(streak: 4, lastDay: '2026-11-30');
      WordGameService.registerDay(p, DateTime(2026, 12, 1));
      expect(p.streak, 5);
      WordGameService.registerDay(p, DateTime(2026, 12, 3));
      expect(p.streak, 1);
    });
  });

  testWidgets('ipucu ve boş kutular görünür; doğru kelime sürüklenince çözülür ve sıradaki soru gelir',
      (tester) async {
    final levels = await _open(tester, now: () => DateTime(2026, 11, 13));
    final first = levels[0][0];
    expect(_text(tester, 'game-clue'), first.clue);
    expect(find.text(l10n.oyunBolum(1)), findsOneWidget);
    expect(find.text(l10n.oyunNasil), findsOneWidget);
    expect(_text(tester, 'game-points'), '${WordGameService.startPoints}');

    await _swipe(tester, first.letters);
    expect(find.text(first.display), findsOneWidget);
    // Kelime puanı + günün ilk doğru cevabı ödülü; seri 1 oldu.
    expect(_text(tester, 'game-points'),
        '${WordGameService.startPoints + WordGameService.wordPoints + WordGameService.dailyBonus}');
    expect(_text(tester, 'game-streak'), '1');
    expect(_text(tester, 'game-toast'), l10n.oyunGunlukSeri(1, WordGameService.dailyBonus));

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_text(tester, 'game-clue'), levels[0][1].clue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('word_game_question'), 1);
    expect(prefs.getString('word_game_last_day'), '2026-11-13');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('yanlış kelime çözmez, seçim temizlenir, puan değişmez', (tester) async {
    final levels = await _open(tester);
    final first = levels[0][0];
    await _swipe(tester, first.letters.reversed.toList());
    expect(find.byKey(const ValueKey('game-solved-word')), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byKey(const ValueKey('game-preview')), findsNothing);
    expect(_text(tester, 'game-points'), '${WordGameService.startPoints}');
    expect(_text(tester, 'game-clue'), first.clue);
  });

  testWidgets('harflere tek tek dokunarak da kurulur; son harfe yeniden dokunmak geri alır',
      (tester) async {
    final levels = await _open(tester);
    final first = levels[0][0];
    final wheel = tester.widget<LetterWheel>(find.byType(LetterWheel));
    final origin = tester.getTopLeft(find.byType(LetterWheel));
    Offset at(String letter, Set<int> used) {
      final i = List.generate(wheel.letters.length, (k) => k)
          .firstWhere((k) => wheel.letters[k] == letter && !used.contains(k));
      used.add(i);
      return origin + LetterWheel.centerOf(i, wheel.letters.length, wheel.size);
    }

    final used = <int>{};
    final firstTile = at(first.letters[0], used);
    await tester.tapAt(firstTile);
    await tester.pump();
    expect(_text(tester, 'game-preview'), first.letters[0]);
    await tester.tapAt(firstTile);
    await tester.pump();
    expect(find.byKey(const ValueKey('game-preview')), findsNothing);

    await tester.tapAt(firstTile);
    for (final letter in first.letters.skip(1)) {
      await tester.tapAt(at(letter, used));
    }
    await tester.pump();
    expect(find.text(first.display), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('harf aç ilk harfi gösterir ve puan düşer; puan yetmezse açmaz', (tester) async {
    final levels = await _open(tester, saved: {'word_game_points': 30});
    final first = levels[0][0];
    await tester.tap(find.byKey(const ValueKey('game-hint')));
    await tester.pump();
    expect(_text(tester, 'game-points'), '5');
    expect(
      find.descendant(of: find.byKey(const ValueKey('game-box-0')), matching: find.text(first.letters[0])),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('game-hint')));
    await tester.pump();
    expect(_text(tester, 'game-points'), '5');
    expect(_text(tester, 'game-toast'), l10n.oyunPuanYetmiyor(WordGameService.hintCost));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('word_game_revealed'), 1);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('karıştır harfleri değiştirmeden yerlerini değiştirir', (tester) async {
    await _open(tester);
    final before = tester.widget<LetterWheel>(find.byType(LetterWheel)).letters;
    await tester.tap(find.byKey(const ValueKey('game-shuffle')));
    await tester.pump();
    final after = tester.widget<LetterWheel>(find.byType(LetterWheel)).letters;
    expect([...after]..sort(), [...before]..sort());
  });

  testWidgets('5 kelime bitince bölüm sonu kartı açılır; sonraki bölüme geçilir ve kaydedilir',
      (tester) async {
    final levels = await _open(tester, now: () => DateTime(2026, 11, 13));
    for (final word in levels[0]) {
      await _swipe(tester, word.letters);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text(l10n.oyunBolumTamam), findsOneWidget);
    expect(_text(tester, 'game-level-bonus'), l10n.oyunArtiPuan(30));
    for (final word in levels[0]) {
      expect(find.text(word.display), findsWidgets);
    }
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('word_game_level'), 1);
    expect(prefs.getInt('word_game_question'), 0);
    expect(prefs.getInt('word_game_points'), 100 + 5 * 5 + 20 + 30);

    await tester.tap(find.byKey(const ValueKey('game-next-level')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.oyunBolum(2)), findsOneWidget);
    expect(_text(tester, 'game-clue'), levels[1][0].clue);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('kaldığı yerden devam eder: bölüm, soru, açılmış harf ve puan', (tester) async {
    final levels = await _open(tester, saved: {
      'word_game_level': 42,
      'word_game_question': 3,
      'word_game_revealed': 2,
      'word_game_points': 75,
      'word_game_streak': 6,
      'word_game_last_day': '2026-11-12',
    });
    final word = levels[42][3];
    expect(find.text(l10n.oyunBolum(43)), findsOneWidget);
    expect(_text(tester, 'game-clue'), word.clue);
    expect(_text(tester, 'game-points'), '75');
    expect(_text(tester, 'game-streak'), '6');
    for (var i = 0; i < 2; i++) {
      expect(
        find.descendant(of: find.byKey(ValueKey('game-box-$i')), matching: find.text(word.letters[i])),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('en uzun kelimeler ve küçük ekranda taşma olmaz', (tester) async {
    SharedPreferences.setMockInitialValues({'word_game_level': 299, 'word_game_question': 4});
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final lang in ['ar', 'ur', 'en']) {
      await tester.runAsync(() => WordGameService.loadLevels(lang));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GameScreen(key: ValueKey(lang), isDarkMode: true, lang: lang, bottomPadding: 120),
        ),
      ));
      await tester.pump();
      await tester.pump();
      expect(find.byType(LetterWheel), findsOneWidget, reason: lang);
      expect(tester.takeException(), isNull, reason: lang);
    }
  });
}
