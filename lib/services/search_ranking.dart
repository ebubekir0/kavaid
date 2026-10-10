// Sözlük aramasının saf (Flutter'dan bağımsız) parçaları: metin normalizasyonu,
// tek bir kaydın sorguya göre puanlanması ve sonuçların ekran için gruplanması.
// Arama izolesi ve ana izole aynı kuralları kullansın diye tek yerde tutulur.

import '../models/word_model.dart';

/// Sonucun sorguyla nasıl eşleştiği.
enum WordMatchType {
  /// Kelimenin kendisi (veya Türkçe aramada anlamlarından biri) sorguya eşit.
  exact,

  /// Kelime sorguyla başlıyor (Türkçe aramada: anlamda sorgu geçiyor).
  prefix,

  /// Kelimenin kökü sorguya eşit.
  root,

  /// Sorgu kelimenin içinde geçiyor. Gürültülü olduğu için ekranda gösterilmez.
  partial,

  /// Latin harfli yazımdan tahmin edilen Arapça eşleşme. Ekranda gösterilmez.
  latinGuess,
}

/// Arama sonucundaki bir kelime ve eşleşme türü.
class RankedWord {
  const RankedWord(this.word, this.matchType);

  final WordModel word;
  final WordMatchType matchType;
}

/// Gruplanmış sonuç listesinde kök eşleşmelerinden önce gelen başlık.
class SearchGroupHeader {
  const SearchGroupHeader(this.title);

  final String title;
}

final RegExp _arabicLetterRx = RegExp(r'[؀-ۿ]');
final RegExp _arabicMarksRx = RegExp(r'[ً-ٰٟـٓ-ٕ]');
final RegExp _hamzaAlifRx = RegExp('[أإآءٱ]');
final RegExp _nonLatinAlphanumericRx = RegExp(r'[^a-z0-9\s,;]');
final RegExp _whitespaceRx = RegExp(r'\s+');
final RegExp _meaningSplitRx = RegExp(r'[,،;]');

bool containsArabic(String text) => _arabicLetterRx.hasMatch(text);

/// Arapça metni aramaya uygun hale getirir: harekeler ve uzatma çizgisi (ـ)
/// silinir, yazımı farklı olabilen harfler tek biçime indirilir:
/// أ إ آ ء ٱ → ا, ؤ → و, ئ ى → ي, ة → ه ve Farsça klavye harfleri
/// (ک → ك, ی → ي, ۀ ھ → ه). Böylece "اسلام", "مدرسه", "كـتـاب" gibi
/// yazımlar da doğru kelimeyi bulur.
String normalizeArabic(String text) {
  if (text.isEmpty) return text;
  return text
      .replaceAll(_arabicMarksRx, '')
      .replaceAll(_hamzaAlifRx, 'ا')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ک', 'ك')
      .replaceAll('ی', 'ي')
      .replaceAll('ۀ', 'ه')
      .replaceAll('ھ', 'ه');
}

/// Tek bir karakteri Türkçe karakterlerden arındırıp küçük harfe çevirir
/// (Ç→c, Ğ→g, İ/I/ı→i, Ö→o, Ş→s, Ü→u). Uzunluğu korur; metin içinde
/// vurgulama gibi konum hesapları için kullanılır.
String foldTurkishChar(String ch) {
  switch (ch) {
    case 'İ':
    case 'I':
    case 'ı':
      return 'i';
    case 'Ç':
    case 'ç':
      return 'c';
    case 'Ğ':
    case 'ğ':
      return 'g';
    case 'Ö':
    case 'ö':
      return 'o';
    case 'Ş':
    case 'ş':
      return 's';
    case 'Ü':
    case 'ü':
      return 'u';
  }
  final lower = ch.toLowerCase();
  return lower.length == 1 ? lower : ch;
}

/// Türkçe/Latin metni aramaya uygun hale getirir: küçük harf, Türkçe
/// karakterler ASCII karşılıklarına, harf/rakam dışı karakterler boşluğa.
/// "Güzel", "guzel" ve "GÜZEL" aynı sonucu verir.
String foldLatin(String text) {
  if (text.isEmpty) return '';
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    buffer.write(foldTurkishChar(String.fromCharCode(rune)));
  }
  return buffer
      .toString()
      .replaceAll('̇', '')
      .replaceAll(_nonLatinAlphanumericRx, ' ')
      .replaceAll(_whitespaceRx, ' ')
      .trim();
}

/// Arama izolesine gönderilen, önceden hazırlanmış sorgu.
class SearchQuery {
  const SearchQuery({
    required this.raw,
    required this.isArabic,
    required this.arabic,
    required this.latin,
    required this.arabicGuess,
  });

  /// [arabicGuess], Latin harfli sorgudan tahmin edilen Arapça yazımdır
  /// (ör. "ketebe" → "كتب"); yalnızca kısa Latin sorgularda kullanılır.
  factory SearchQuery.parse(String input, {String arabicGuess = ''}) {
    final raw = input.trim();
    final isArabic = containsArabic(raw);
    return SearchQuery(
      raw: raw,
      isArabic: isArabic,
      arabic: isArabic ? normalizeArabic(raw) : '',
      latin: isArabic ? '' : foldLatin(raw),
      arabicGuess: !isArabic && raw.length <= 5 ? arabicGuess : '',
    );
  }

  factory SearchQuery.fromMap(Map<String, dynamic> map) => SearchQuery(
    raw: map['raw'] as String,
    isArabic: map['isArabic'] as bool,
    arabic: map['arabic'] as String,
    latin: map['latin'] as String,
    arabicGuess: map['arabicGuess'] as String,
  );

  final String raw;
  final bool isArabic;

  /// Normalize edilmiş Arapça sorgu (Arapça aramada).
  final String arabic;

  /// Normalize edilmiş Türkçe/Latin sorgu (Türkçe aramada).
  final String latin;
  final String arabicGuess;

  bool get isEmpty => isArabic ? arabic.isEmpty : latin.isEmpty;

  /// Çok kısa Türkçe sorgularda ("su", "ev") yalnızca tam kelime eşleşmeleri
  /// alınır; aksi halde "su" binlerce anlamın içinde geçer ("susmak", "uzun süre").
  bool get wholeWordOnly => !isArabic && latin.length <= 2;

  Map<String, dynamic> toMap() => {
    'raw': raw,
    'isArabic': isArabic,
    'arabic': arabic,
    'latin': latin,
    'arabicGuess': arabicGuess,
  };
}

/// Bir kaydın sıralama puanı: önce [rank], sonra [sec] küçük olan öne gelir.
typedef EntryRank = ({int rank, int sec, WordMatchType type});

/// Bir sözlük kaydını sorguya göre puanlar; eşleşmiyorsa null döner.
///
/// [kelime], [harekeli] ve [koku] ham alanlardır; `n` ile başlayanlar
/// [normalizeArabic] ile, [meanings] ise ana anlamın (|| öncesi)
/// [foldLatin] ile normalize edilmiş halidir. [rawMeaning] ana anlamın ham
/// hali; verilirse Türkçe karakterleri birebir uyan anlamlar öne alınır.
EntryRank? rankEntry({
  required SearchQuery query,
  required String kelime,
  required String harekeli,
  required String koku,
  required String nKelime,
  required String nHarekeli,
  required String nKoku,
  required String meanings,
  String rawMeaning = '',
}) {
  final wordLength = nHarekeli.isNotEmpty ? nHarekeli.length : nKelime.length;

  if (query.isArabic) {
    if (harekeli.isEmpty && kelime.isEmpty && koku.isEmpty) return null;
    final q = query.arabic;

    // Ekranda gösterilen harekeli yazım esas alınır. Veride "kelime" alanı
    // bazen yanlış/Latin harfli girilmiş (ör. kelime "كتب", harekeli
    // "لِيَكْتُبْ"); bu kayıtlar tam eşleşme sayılır ama sona alınır.
    if (harekeli == query.raw) {
      return (rank: 0, sec: wordLength, type: WordMatchType.exact);
    }
    if (nHarekeli == q || (nHarekeli.isEmpty && nKelime == q)) {
      return (rank: 1, sec: wordLength, type: WordMatchType.exact);
    }
    if (kelime == query.raw || nKelime == q) {
      return (rank: 1, sec: 1000 + wordLength, type: WordMatchType.exact);
    }
    final isPrefix = nHarekeli.startsWith(q) || nKelime.startsWith(q);
    final isRoot = nKoku.isNotEmpty && nKoku == q;
    if (isPrefix || isRoot) {
      // Sıralamada kök eşleşmeleri öne alınır (120 sonuç sınırında
      // kaybolmasınlar); ekranda ise önek eşleşmeleri önce gösterilir.
      final type = isPrefix
          ? WordMatchType.prefix
          : (q.length >= 2 ? WordMatchType.root : WordMatchType.partial);
      return (rank: isRoot ? 2 : 3, sec: wordLength, type: type);
    }
    if (_hasWholeToken(nHarekeli, q) || _hasWholeToken(nKelime, q)) {
      return (rank: 4, sec: wordLength, type: WordMatchType.partial);
    }
    if (_hasTokenStartingWith(nHarekeli, q) ||
        _hasTokenStartingWith(nKelime, q)) {
      return (rank: 5, sec: wordLength, type: WordMatchType.partial);
    }
    if (nHarekeli.contains(q) || nKelime.contains(q)) {
      return (rank: 6, sec: wordLength, type: WordMatchType.partial);
    }
    return null;
  }

  final q = query.latin;
  if (q.isEmpty) return null;

  if (meanings.isNotEmpty && meanings.contains(q)) {
    final best = _bestMeaningMatch(
      meanings.split(_meaningSplitRx),
      q,
      query.wholeWordOnly,
    );
    if (best != null) {
      // Türkçe karakterler dahil yazılanla birebir uyan anlam öne alınır:
      // "su" yazınca su (ماء), "şu" yazınca şu (تلك) önce gelir.
      final rawBest = rawMeaning.isEmpty
          ? null
          : _bestMeaningMatch(
              turkishLower(rawMeaning).split(_meaningSplitRx),
              turkishLower(query.raw),
              query.wholeWordOnly,
            );
      // Kelime ortası eşleşmeler yalnızca yazım birebir uyuyorsa sayılır;
      // aksi halde "okul" araması "döküldü"yü ("dokuldu") bulur.
      final insideWordOnlyByFolding =
          best.tier == 5 && rawMeaning.isNotEmpty && rawBest == null;
      if (!insideWordOnlyByFolding) {
        final accentPenalty = rawBest != null && rawBest.tier <= best.tier
            ? 0
            : 50;
        return (
          // Önce eşleşme kalitesi, sonra yazım birebirliği, sonra anlamın sırası.
          rank:
              100 +
              best.tier * 100 +
              accentPenalty +
              (best.index < 49 ? best.index : 49),
          // Aynı puanda temel biçim (daha kısa kelime; "ال" takısız, zamirsiz)
          // öne gelir; eşitse sözlük sırası korunur.
          sec: wordLength,
          type: best.tier == 0 ? WordMatchType.exact : WordMatchType.prefix,
        );
      }
    }
  }

  final guess = query.arabicGuess;
  if (guess.isNotEmpty) {
    if (nHarekeli.startsWith(guess) || nKelime.startsWith(guess)) {
      return (rank: 9000, sec: wordLength, type: WordMatchType.latinGuess);
    }
    if (nKoku == guess) {
      return (rank: 9001, sec: nKoku.length, type: WordMatchType.latinGuess);
    }
    if (nHarekeli.contains(guess) || nKelime.contains(guess)) {
      return (rank: 9002, sec: wordLength, type: WordMatchType.latinGuess);
    }
  }
  return null;
}

/// Anlam parçaları içinde sorgunun en iyi eşleştiği parçayı bulur.
/// [tier]: 0 parça tam olarak sorgu, 1 parça sorgu kelimesiyle başlıyor
/// ("su içmek"), 2 parça sorguyla başlıyor ("sulamak"), 3 sorgu parçada ayrı
/// bir kelime ("temiz su"), 4 parçadaki bir kelime sorguyla başlıyor
/// ("en güzeli"), 5 sorgu bir kelimenin ortasında. [wholeWordOnly] ise
/// yalnızca 0, 1 ve 3 sayılır.
({int tier, int index})? _bestMeaningMatch(
  List<String> parts,
  String q,
  bool wholeWordOnly,
) {
  if (q.isEmpty) return null;
  int? bestTier;
  var bestIndex = 0;
  for (var j = 0; j < parts.length; j++) {
    final m = parts[j].trim();
    if (m.isEmpty || !m.contains(q)) continue;

    final int tier;
    if (m == q) {
      tier = 0;
    } else if (m.startsWith('$q ')) {
      tier = 1;
    } else if (m.startsWith(q)) {
      tier = 2;
    } else if (m.endsWith(' $q') || m.contains(' $q ')) {
      tier = 3;
    } else if (m.contains(' $q')) {
      tier = 4;
    } else {
      tier = 5;
    }
    if (wholeWordOnly && tier != 0 && tier != 1 && tier != 3) continue;
    if (bestTier == null || tier < bestTier) {
      bestTier = tier;
      bestIndex = j;
    }
  }
  if (bestTier == null) return null;
  return (tier: bestTier, index: bestIndex);
}

/// Türkçe kurallarına göre küçük harfe çevirir (İ→i, I→ı).
String turkishLower(String text) =>
    text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase().trim();

bool _hasWholeToken(String text, String token) {
  if (text.isEmpty || token.isEmpty) return false;
  return text == token ||
      text.startsWith('$token ') ||
      text.endsWith(' $token') ||
      text.contains(' $token ');
}

bool _hasTokenStartingWith(String text, String token) {
  if (text.isEmpty || token.isEmpty) return false;
  return text.startsWith(token) || text.contains(' $token');
}

/// Arama sonuçlarını ekranda gösterilecek sıraya koyar: önce tam ve önek
/// eşleşmeleri, ardından "Kök eşleşme" başlığı altında kök eşleşmeleri
/// (isimler, diğerleri, fiiller sırasıyla). Kısmi ve Latin tahmini
/// eşleşmeler gösterilmez. Eşleşme türü bilinmeyen kelimeler (ör. AI
/// sonucu) tam eşleşme sayılır.
List<Object> groupSearchResults(
  List<WordModel> words,
  WordMatchType? Function(WordModel word) matchTypeOf,
) {
  final exact = <WordModel>[];
  final prefix = <WordModel>[];
  final root = <WordModel>[];

  for (final word in words) {
    switch (matchTypeOf(word) ?? WordMatchType.exact) {
      case WordMatchType.exact:
        exact.add(word);
      case WordMatchType.prefix:
        prefix.add(word);
      case WordMatchType.root:
        root.add(word);
      case WordMatchType.partial:
      case WordMatchType.latinGuess:
        break;
    }
  }

  // Kararlı sıralama: aynı türdeki kelimeler arama sırasını korur.
  final rootOrder = {for (var i = 0; i < root.length; i++) root[i]: i};
  root.sort((a, b) {
    final byType = _rootTypeRank(a).compareTo(_rootTypeRank(b));
    return byType != 0 ? byType : rootOrder[a]!.compareTo(rootOrder[b]!);
  });

  return [
    ...exact,
    ...prefix,
    if (root.isNotEmpty) const SearchGroupHeader('Kök eşleşme'),
    ...root,
  ];
}

int _rootTypeRank(WordModel word) {
  String? typeText;
  if (word.dilbilgiselOzellikler?.containsKey('tur') == true) {
    typeText = word.dilbilgiselOzellikler!['tur']?.toString();
  } else if (word.tip?.isNotEmpty == true) {
    typeText = word.tip;
  }

  // turkishLower: Dart'ın toLowerCase'i "İsim"i "i̇sim" (noktalı) yapar ve
  // "isim" ile eşleşmez; bu yüzden isimler eskiden öne alınmıyordu.
  final t = turkishLower(typeText ?? '');
  if (t.contains('isim')) return 0;
  if (t.contains('fiil')) return 2;
  return 1;
}
