import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Ana sayfadaki "Günün Kelimesi".
///
/// Veri `assets/data/gunun_kelimeleri.json` dosyasındadır ve
/// `tool/build_daily_words.py` ile üretilir: sözlükteki kayıtlardan gündelik,
/// temel biçimli, örnek cümlesi olan kelimeler elle seçilmiştir.
class DailyWord {
  const DailyWord({
    required this.arabic,
    required this.root,
    required this.type,
    required this.meaning,
    required this.exampleArabic,
    required this.exampleTurkish,
  });

  factory DailyWord.fromJson(Map<String, dynamic> json) {
    final example = json['ornek'] as Map<String, dynamic>? ?? const {};
    return DailyWord(
      arabic: json['ar'] as String,
      root: json['kok'] as String? ?? '',
      type: json['tur'] as String? ?? '',
      meaning: json['anlam'] as String? ?? '',
      exampleArabic: example['ar'] as String? ?? '',
      exampleTurkish: example['tr'] as String? ?? '',
    );
  }

  /// Harekeli yazım ("كِتَابٌ"). Aramada da bu yazım kullanılır.
  final String arabic;

  /// Kök, sözlükteki yazımıyla (göstermeden önce `formatRoot` ile düzeltilir).
  final String root;

  /// "İsim", "Sıfat", "Mazî Fiil"...
  final String type;

  /// Kısa Türkçe karşılık ("kitap, mektup").
  final String meaning;

  final String exampleArabic;
  final String exampleTurkish;
}

/// Günün kelimesini seçer ve yükler.
class DailyWords {
  DailyWords._();

  static const asset = 'assets/data/gunun_kelimeleri.json';

  /// Seçimin başladığı gün; gün sayısı buradan hesaplanır.
  static final DateTime _epoch = DateTime.utc(2026, 1, 1);

  static List<DailyWord>? _cache;

  /// Kelime listesini yükler (bir kez okunur, sonra bellekten gelir).
  static Future<List<DailyWord>> load({AssetBundle? bundle}) async {
    final cached = _cache;
    if (cached != null) return cached;
    final text = await (bundle ?? rootBundle).loadString(asset);
    final words = [
      for (final item in jsonDecode(text) as List)
        DailyWord.fromJson(item as Map<String, dynamic>),
    ];
    return _cache = words;
  }

  /// [date] gününün kelimesi. Liste gün gün sırayla ilerler, bittiğinde başa
  /// döner; saat bilgisi önemsizdir (aynı gün içinde hep aynı kelime gelir).
  /// Liste sabit bir tohumla karıştırılmış olduğu için ardışık günlerin
  /// kelimeleri birbirinden bağımsız görünür.
  static DailyWord forDate(List<DailyWord> words, DateTime date) {
    final day = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(_epoch).inDays;
    return words[day % words.length];
  }

  /// Bugünün kelimesi; veri okunamazsa null (ana sayfa o bölümü gizler).
  static Future<DailyWord?> today({AssetBundle? bundle, DateTime? now}) async {
    try {
      final words = await load(bundle: bundle);
      if (words.isEmpty) return null;
      return forDate(words, now ?? DateTime.now());
    } catch (_) {
      return null;
    }
  }
}
