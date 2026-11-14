import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Kelime oyunundaki bir kelime: harekeli yazılış ve ipucu (sözlük dilindeki kısa anlam).
class GameWord {
  GameWord(this.display, this.clue) : letters = display.replaceAll(_marks, '').split('');

  /// Çözülünce gösterilen harekeli yazılış: كِتَابٌ
  final String display;

  /// İpucu: sözlük dilinde kısa anlam; Arapça sözlükte tanım.
  final String clue;

  /// Çarka dizilen harfler (harekesiz), yazım sırasıyla.
  final List<String> letters;

  String get answer => letters.join();

  static final _marks = RegExp(r'[ً-ٰٟـۖ-ۭ]');
}

/// Oyuncunun kayıtlı durumu.
class GameProgress {
  GameProgress({
    this.level = 0,
    this.question = 0,
    this.revealed = 0,
    this.points = WordGameService.startPoints,
    this.streak = 0,
    this.lastDay = '',
  });

  /// Sıradaki bölüm (0 tabanlı) = bitirilen bölüm sayısı.
  int level;

  /// Bölüm içinde sıradaki kelime.
  int question;

  /// O kelimede ipucuyla açılmış harf sayısı (ödenmiş ipucu uygulama kapanınca kaybolmasın).
  int revealed;

  int points;

  /// Art arda oynanan gün sayısı ve son oynanan gün (yyyy-aa-gg).
  int streak;
  String lastDay;
}

/// Kelime oyunu: bölüm verisi, puan kuralları ve kayıt.
///
/// Bölümler `assets/data/oyun/<dil>.json` içindedir (`tool/oyun/build_levels.dart` üretir):
/// her bölüm 5 kelime, her kelime `[harekeli yazılış, ipucu]`. Bütün dillerde aynı bölümde aynı
/// kelimeler vardır; yalnız ipucu dili değişir.
class WordGameService {
  WordGameService._();

  static const supportedLangs = ['tr', 'en', 'ar', 'id', 'ms', 'ur'];

  static const startPoints = 100;
  static const wordPoints = 5;
  static const hintCost = 25;
  static const dailyBonus = 20;

  /// Bölüm sonu ödülü: yıldız başına 10 puan.
  static int levelBonus(int stars) => stars * 10;

  /// Yıldız: hatasız ve ipucusuz 3, bir iki aksamayla 2, daha fazlasıyla 1.
  static int starsFor(int slips) => slips == 0 ? 3 : (slips <= 2 ? 2 : 1);

  static final _cache = <String, List<List<GameWord>>>{};

  /// [lang] sözlük dili; oyunu olmayan dillerde İngilizce ipuçları kullanılır.
  static Future<List<List<GameWord>>> loadLevels(String lang) async {
    final l = supportedLangs.contains(lang) ? lang : 'en';
    final cached = _cache[l];
    if (cached != null) return cached;
    // loadString büyük dosyada ayrı izole açar; 75-200 KB için doğrudan çözmek daha hızlı.
    final data = await rootBundle.load('assets/data/oyun/$l.json');
    return _cache[l] = parseLevels(
      utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)),
    );
  }

  static List<List<GameWord>> parseLevels(String json) => [
    for (final level in jsonDecode(json) as List)
      [for (final w in level as List) GameWord(w[0] as String, w[1] as String)],
  ];

  static const _alphabet = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي';

  /// İleri bölümlerde çarka eklenen şaşırtmaca harf sayısı.
  static int extraLetters(int level) => level >= 100 ? 2 : (level >= 20 ? 1 : 0);

  /// Çarkta en çok bu kadar harf olur: daha fazlasında bir harfi atlayıp ötekine sürüklerken
  /// aradaki harfe değmemek zorlaşır.
  static const maxWheelLetters = 7;

  /// Çarktaki harfler: kelimenin harfleri ve şaşırtmaca harfler, karışık. Aynı bölüm ve soru
  /// için hep aynı dizilir; [shuffle] "Karıştır" düğmesine her basışta artar.
  static List<String> wheelLetters(
    GameWord word, {
    required int level,
    required int question,
    int shuffle = 0,
  }) {
    final letters = [...word.letters];
    final pool = _alphabet.split('').where((c) => !letters.contains(c)).toList();
    final pick = Random(level * 131 + question * 17);
    for (var i = 0; i < extraLetters(level) && letters.length < maxWheelLetters; i++) {
      letters.add(pool.removeAt(pick.nextInt(pool.length)));
    }
    // Çark cevabın sırasıyla dizilmesin (birkaç denemede olmazsa öyle kalır: ممم gibi kelimeler).
    final order = Random(level * 131 + question * 17 + shuffle * 7919);
    for (var attempt = 0; attempt < 8; attempt++) {
      letters.shuffle(order);
      if (!letters.join().startsWith(word.answer)) break;
    }
    return letters;
  }

  static const _kLevel = 'word_game_level';
  static const _kQuestion = 'word_game_question';
  static const _kRevealed = 'word_game_revealed';
  static const _kPoints = 'word_game_points';
  static const _kStreak = 'word_game_streak';
  static const _kLastDay = 'word_game_last_day';

  static Future<GameProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return GameProgress(
      level: prefs.getInt(_kLevel) ?? 0,
      question: prefs.getInt(_kQuestion) ?? 0,
      revealed: prefs.getInt(_kRevealed) ?? 0,
      points: prefs.getInt(_kPoints) ?? startPoints,
      streak: prefs.getInt(_kStreak) ?? 0,
      lastDay: prefs.getString(_kLastDay) ?? '',
    );
  }

  static Future<void> saveProgress(GameProgress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLevel, p.level);
    await prefs.setInt(_kQuestion, p.question);
    await prefs.setInt(_kRevealed, p.revealed);
    await prefs.setInt(_kPoints, p.points);
    await prefs.setInt(_kStreak, p.streak);
    await prefs.setString(_kLastDay, p.lastDay);
  }

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Günün ilk doğru cevabında çağrılır: dün de oynandıysa seri uzar, ara verildiyse 1'e döner
  /// ve günlük ödül eklenir. O gün zaten işlendiyse false döner.
  static bool registerDay(GameProgress p, DateTime now) {
    final today = dayKey(now);
    if (p.lastDay == today) return false;
    final yesterday = dayKey(DateTime(now.year, now.month, now.day - 1));
    p.streak = p.lastDay == yesterday ? p.streak + 1 : 1;
    p.lastDay = today;
    p.points += dailyBonus;
    return true;
  }
}
