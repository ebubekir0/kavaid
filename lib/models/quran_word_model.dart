/// Kuran Sözlüğü için kelime modeli
/// CSV yapısı: Kelime, Kök, Anlamlar, Ayet1, Ayet2, Ayet3
class QuranWordModel {
  final String kelime;
  final String kok;
  final String anlamlar;
  final List<QuranAyetOrnek> ayetOrnekleri;

  const QuranWordModel({
    required this.kelime,
    required this.kok,
    required this.anlamlar,
    required this.ayetOrnekleri,
  });

  /// CSV satırından model oluştur
  factory QuranWordModel.fromCsvRow(List<String> fields) {
    final kelime = fields.isNotEmpty ? fields[0].trim() : '';
    final kok = fields.length > 1 ? fields[1].trim() : '';
    final anlamlar = fields.length > 2 ? fields[2].trim() : '';

    final ayetler = <QuranAyetOrnek>[];
    for (int i = 3; i < fields.length && i < 6; i++) {
      final ayetStr = fields[i].trim();
      if (ayetStr.isNotEmpty) {
        final parsed = QuranAyetOrnek.parse(ayetStr);
        if (parsed != null) {
          ayetler.add(parsed);
        }
      }
    }

    return QuranWordModel(
      kelime: kelime,
      kok: kok,
      anlamlar: anlamlar,
      ayetOrnekleri: ayetler,
    );
  }

  /// Anlamları virgülle ayrılmış liste olarak döndür
  List<String> get anlamListesi {
    return anlamlar
        .split(RegExp(r'[,،]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

/// Kuran ayeti örneği
class QuranAyetOrnek {
  final String sureAyet; // Ör: "En'âm:165"
  final String arapcaMetin;
  final String meal;

  const QuranAyetOrnek({
    required this.sureAyet,
    required this.arapcaMetin,
    required this.meal,
  });

  /// "[Sure:Ayet] Arapça - Meal" formatından ayrıştır
  static QuranAyetOrnek? parse(String raw) {
    if (raw.isEmpty) return null;

    try {
      // Format: [Sure:Ayet] ArapçaMetin - Meal
      String sureAyet = '';
      String arapcaMetin = '';
      String meal = '';

      // Sure:Ayet bilgisini al
      final bracketStart = raw.indexOf('[');
      final bracketEnd = raw.indexOf(']');
      if (bracketStart != -1 && bracketEnd != -1 && bracketEnd > bracketStart) {
        sureAyet = raw.substring(bracketStart + 1, bracketEnd).trim();
      }

      // Kalan kısmı al
      String remaining = '';
      if (bracketEnd != -1 && bracketEnd + 1 < raw.length) {
        remaining = raw.substring(bracketEnd + 1).trim();
      }

      // Arapça metin ve meal'i " - " ile ayır
      final dashIndex = remaining.indexOf(' - ');
      if (dashIndex != -1) {
        arapcaMetin = remaining.substring(0, dashIndex).trim();
        meal = remaining.substring(dashIndex + 3).trim();
      } else {
        arapcaMetin = remaining;
      }

      if (sureAyet.isEmpty && arapcaMetin.isEmpty) return null;

      return QuranAyetOrnek(
        sureAyet: sureAyet,
        arapcaMetin: arapcaMetin,
        meal: meal,
      );
    } catch (_) {
      return null;
    }
  }
}
