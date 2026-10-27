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

  /// Kök eşleşmeleri grubu; ekranda arayüz diliyle yazılır (l10n.rootMatches).
  static const root = 'root';

  final String title;
}

final RegExp _arabicLetterRx = RegExp(r'[؀-ۿ]');
final RegExp _arabicMarksRx = RegExp(r'[ً-ٰٟـٓ-ٕ]');
final RegExp _hamzaAlifRx = RegExp('[أإآءٱ]');
final RegExp _nonLatinAlphanumericRx = RegExp(r'[^a-z0-9\s,;]');
final RegExp _apostropheRx = RegExp("['’‘ʼ`´]");
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

final RegExp _latinLetterRx = RegExp('[A-Za-z]');

/// Bir kaydın ana anlamını aramaya uygun hale getirir: Arap yazılı anlamlar
/// (Urduca) [normalizeArabic] ile, diğerleri [foldLatin] ile.
String normalizeMeaning(String mainMeaning) {
  if (mainMeaning.isEmpty) return '';
  if (containsArabic(mainMeaning) && !_latinLetterRx.hasMatch(mainMeaning)) {
    return normalizeArabic(mainMeaning);
  }
  return foldLatin(mainMeaning);
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
      // Kesme işareti kelimeyi bölmez: "Allah'a" tek kelime kalır, yoksa
      // "a"/"ye" gibi kısa aramalar ekleri ayrı kelime sanıyordu; "Kur'an"
      // da "kuran" yazınca bulunur.
      .replaceAll(_apostropheRx, '')
      .replaceAll(_nonLatinAlphanumericRx, ' ')
      .replaceAll(_whitespaceRx, ' ')
      .trim();
}

final RegExp _foldedVowelRx = RegExp('[aeiou]');

/// [foldLatin] ile katlanmış bir Türkçe mastarı ("yazmak", "yardim etmek")
/// 3. tekil geçmiş zamana çevirir ("yazdi", "yardim etti"); mastar değilse
/// boş döner. Katlanmış metinde ı/i, o/ö, u/ü ayrımı kalmadığından ünlü
/// uyumu iki sınıfa iner: son ünlü o/u ise -du/-tu, değilse -di/-ti.
/// Sert ünsüzle (f s t k ç ş h p) biten köklerde -t- kullanılır.
String pastTenseOfInfinitive(String folded) {
  final words = folded.split(' ');
  final last = words.last;
  if (last.length < 5 || !(last.endsWith('mak') || last.endsWith('mek'))) {
    return '';
  }
  final stem = last.substring(0, last.length - 3);
  final vowels = _foldedVowelRx.allMatches(stem);
  if (vowels.isEmpty) return '';
  final lastVowel = vowels.last.group(0);
  final suffixVowel = (lastVowel == 'o' || lastVowel == 'u') ? 'u' : 'i';
  final voiceless = 'fstkchp'.contains(stem[stem.length - 1]);
  words[words.length - 1] = '$stem${voiceless ? 't' : 'd'}$suffixVowel';
  return words.join(' ');
}

/// Arama izolesine gönderilen, önceden hazırlanmış sorgu.
class SearchQuery {
  const SearchQuery({
    required this.raw,
    required this.isArabic,
    required this.arabic,
    required this.latin,
    required this.arabicGuess,
    this.latinAlt = '',
  });

  /// [arabicGuess], Latin harfli sorgudan tahmin edilen Arapça yazımdır
  /// (ör. "ketebe" → "كتب"); yalnızca kısa Latin sorgularda kullanılır.
  factory SearchQuery.parse(String input, {String arabicGuess = ''}) {
    final raw = input.trim();
    final isArabic = containsArabic(raw);
    final latin = isArabic ? '' : foldLatin(raw);
    return SearchQuery(
      raw: raw,
      isArabic: isArabic,
      arabic: isArabic ? normalizeArabic(raw) : '',
      latin: latin,
      // Latin tahmini sonuçları ekranda gösterilmez; 1-2 harfte neredeyse
    // her kaydı taradığı için hiç hesaplanmaz.
    arabicGuess: !isArabic && latin.length >= 3 && raw.length <= 5
        ? arabicGuess
        : '',
      latinAlt: isArabic ? '' : pastTenseOfInfinitive(latin),
    );
  }

  factory SearchQuery.fromMap(Map<String, dynamic> map) => SearchQuery(
    raw: map['raw'] as String,
    isArabic: map['isArabic'] as bool,
    arabic: map['arabic'] as String,
    latin: map['latin'] as String,
    arabicGuess: map['arabicGuess'] as String,
    latinAlt: map['latinAlt'] as String? ?? '',
  );

  final String raw;
  final bool isArabic;

  /// Normalize edilmiş Arapça sorgu (Arapça aramada).
  final String arabic;

  /// Normalize edilmiş Türkçe/Latin sorgu (Türkçe aramada).
  final String latin;
  final String arabicGuess;

  /// Türkçe mastar sorgusunun geçmiş zaman hali ("yazmak" → "yazdi").
  /// Sözlükte fiiller "yazdı" biçimiyle yazıldığı için mastarla arayan
  /// kullanıcı temel fiili (كَتَبَ) de bulur. Mastar değilse boş.
  final String latinAlt;

  bool get isEmpty => isArabic ? arabic.isEmpty : latin.isEmpty;

  /// Kısa Türkçe sorgu (1-2 harf): yalnızca kelime başında geçen eşleşmeler
  /// alınır, kelime başı eşleşmeleri de Türkçe karakterleri birebir uyuyorsa
  /// ("su" → sulamak, susamak; "süre" değil).
  bool get isShortLatin => !isArabic && latin.length <= 2;

  /// Alınan en zayıf anlam eşleşmesi ([_bestMeaningMatch] katmanları): tek
  /// harfte anlamın kendisi o harfle başlamalı ("k" → kitap, kalem), iki
  /// harfte herhangi bir kelime ("ki" → ki, kitap); kelime ortası eşleşmeler
  /// alınmaz. Daha uzun sorgularda hepsi.
  int get maxMeaningTier {
    if (!isShortLatin) return 5;
    return latin.length == 1 ? 2 : 4;
  }

  Map<String, dynamic> toMap() => {
    'raw': raw,
    'isArabic': isArabic,
    'arabic': arabic,
    'latin': latin,
    'arabicGuess': arabicGuess,
    'latinAlt': latinAlt,
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
  int popularity = 0,
  bool imperative = false,
}) {
  final wordLength = nHarekeli.isNotEmpty ? nHarekeli.length : nKelime.length;

  // Aynı puanda yaygın kelime öne gelir: kökünden sözlükte çok sayıda
  // kelime türemiş olan (كَبِيرٌ) nadir olandan (جَلَلٌ) önce. Sonra temel
  // biçim (daha kısa kelime; "ال" takısız, zamirsiz), sonra sözlük sırası.
  final sec =
      (9999 - popularity.clamp(0, 9999)) * 1000 + wordLength.clamp(0, 999);

  if (query.isArabic) {
    if (harekeli.isEmpty && kelime.isEmpty && koku.isEmpty) return null;
    final q = query.arabic;
    final headword = _rankArabicHeadword(
      query, q, kelime, harekeli, koku, nKelime, nHarekeli, nKoku, wordLength,
    );
    if (headword != null && headword.rank < 4) return headword;

    // Arap yazılı anlamlar (Urduca sözlük): "پانی" yazan kullanıcı ماء'yı
    // bulur. Anlamda tam eşleşme, başlıkta yalnız içinde geçmekten önce gelir.
    if (meanings.isNotEmpty && meanings.contains(q)) {
      final meaning = _rankMeaning(
        meanings,
        q,
        q.length <= 1 ? 2 : (q.length == 2 ? 4 : 5),
        sec,
      );
      if (meaning != null) return meaning;
    }
    return headword;
  }

  final q = query.latin;
  if (q.isEmpty) return null;

  EntryRank? best;
  if (meanings.isNotEmpty && meanings.contains(q)) {
    best = _rankMeaning(
      meanings,
      q,
      query.maxMeaningTier,
      sec,
      rawMeaning: rawMeaning,
      rawQuery: query.raw,
      exactSpellingForPrefix: query.isShortLatin,
    );
  }
  final alt = query.latinAlt;
  if (alt.isNotEmpty && meanings.contains(alt)) {
    final altRank = _rankMeaning(
      meanings,
      alt,
      5,
      sec,
      allowInsideWord: false,
    );
    if (altRank != null && (best == null || altRank.rank < best.rank)) {
      best = altRank;
    }
  }
  // Emir kipi temel biçimden sonra: "write" → كَتَبَ, اُكْتُبْ değil; "yaz" → صَيْفٌ.
  if (best != null) {
    return imperative ? (rank: best.rank + 40, sec: best.sec, type: best.type) : best;
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

/// Arapça sorguyu kaydın başlığına ve köküne göre puanlar.
EntryRank? _rankArabicHeadword(
  SearchQuery query,
  String q,
  String kelime,
  String harekeli,
  String koku,
  String nKelime,
  String nHarekeli,
  String nKoku,
  int wordLength,
) {
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

/// Türkçe sorguyu kaydın anlamlarına göre puanlar. [rawMeaning] ve
/// [rawQuery] verilirse Türkçe karakterleri birebir uyan anlam öne alınır;
/// [allowInsideWord] false ise kelime ortası eşleşmeler sayılmaz.
/// [exactSpellingForPrefix] ise kelime başı eşleşmeleri (sulamak) yalnızca
/// yazım birebir uyuyorsa sayılır (kısa sorgularda "su" → "süre" olmasın).
EntryRank? _rankMeaning(
  String meanings,
  String q,
  int maxTier,
  int sec, {
  String rawMeaning = '',
  String rawQuery = '',
  bool allowInsideWord = true,
  bool exactSpellingForPrefix = false,
}) {
  final best = _bestMeaningMatch(
    meanings.split(_meaningSplitRx),
    q,
    maxTier,
  );
  if (best == null) return null;
  if (!allowInsideWord && best.tier == 5) return null;

  // Türkçe karakterler dahil yazılanla birebir uyan anlam öne alınır:
  // "su" yazınca su (ماء), "şu" yazınca şu (تلك) önce gelir.
  final rawBest = rawMeaning.isEmpty || rawQuery.isEmpty
      ? null
      : _bestMeaningMatch(
          turkishLower(rawMeaning).split(_meaningSplitRx),
          turkishLower(rawQuery),
          maxTier,
        );
  // Kelime ortası eşleşmeler yalnızca yazım birebir uyuyorsa sayılır;
  // aksi halde "okul" araması "döküldü"yü ("dokuldu") bulur.
  if (best.tier == 5 && rawMeaning.isNotEmpty && rawBest == null) return null;
  if (exactSpellingForPrefix &&
      (best.tier == 2 || best.tier == 4) &&
      rawMeaning.isNotEmpty &&
      (rawBest == null || rawBest.tier > best.tier)) {
    return null;
  }

  final accentPenalty =
      rawQuery.isEmpty || (rawBest != null && rawBest.tier <= best.tier)
      ? 0
      : 50;
  return (
    // Önce eşleşme kalitesi, sonra yazım birebirliği, sonra anlamın sırası;
    // yalnız "to " atılınca uyan İngilizce mastar ("to water") biraz sonra.
    rank:
        100 +
        best.tier * 100 +
        accentPenalty +
        (best.infinitive ? 10 : 0) +
        (best.index < 49 ? best.index : 49),
    sec: sec,
    type: best.tier == 0 ? WordMatchType.exact : WordMatchType.prefix,
  );
}

/// Anlam parçaları içinde sorgunun en iyi eşleştiği parçayı bulur.
/// [tier]: 0 parça tam olarak sorgu, 1 parça sorgu kelimesiyle başlıyor
/// ("su içmek"), 2 parça sorguyla başlıyor ("sulamak"), 3 sorgu parçada ayrı
/// bir kelime ("temiz su"), 4 parçadaki bir kelime sorguyla başlıyor
/// ("en güzeli"), 5 sorgu bir kelimenin ortasında. [maxTier]'dan zayıf
/// eşleşmeler sayılmaz. İngilizce mastar eki ("to write") parçadan atılarak
/// bakılır, [infinitive] ile işaretlenir: "write" temel fiili (كَتَبَ) bulur,
/// "water" yine önce isme (مَاءٌ) gider.
({int tier, int index, bool infinitive})? _bestMeaningMatch(
  List<String> parts,
  String q,
  int maxTier,
) {
  if (q.isEmpty) return null;
  int? bestTier;
  var bestIndex = 0;
  var bestInfinitive = false;
  for (var j = 0; j < parts.length; j++) {
    var m = parts[j].trim();
    if (m.isEmpty || !m.contains(q)) continue;
    final infinitive = m.startsWith('to ') && !q.startsWith('to ');
    if (infinitive) m = m.substring(3);

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
    if (tier > maxTier) continue;
    if (bestTier == null ||
        tier < bestTier ||
        (tier == bestTier && bestInfinitive && !infinitive)) {
      bestTier = tier;
      bestIndex = j;
      bestInfinitive = infinitive;
    }
  }
  if (bestTier == null) return null;
  return (tier: bestTier, index: bestIndex, infinitive: bestInfinitive);
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
    if (root.isNotEmpty) const SearchGroupHeader(SearchGroupHeader.root),
    ...root,
  ];
}

String? _typeText(WordModel word) {
  if (word.dilbilgiselOzellikler?.containsKey('tur') == true) {
    return word.dilbilgiselOzellikler!['tur']?.toString();
  }
  return word.tip?.isNotEmpty == true ? word.tip : null;
}

int _rootTypeRank(WordModel word) {
  // turkishLower: Dart'ın toLowerCase'i "İsim"i "i̇sim" (noktalı) yapar ve
  // "isim" ile eşleşmez; bu yüzden isimler eskiden öne alınmıyordu.
  final t = turkishLower(_typeText(word) ?? '');
  if (t.contains('isim')) return 0;
  if (t.contains('fiil')) return 2;
  return 1;
}

// ─── İsim kopyalarını birleştirme ───────────────────────────────────────

final RegExp _articleRx = RegExp('^اَ?ل(ْ)?');
// Sondaki hareke kümesi; şedde de içinde olabilir (أُمٌّ: tenvin + şedde).
final RegExp _caseEndingRx = RegExp('[ًٌٍَُِّْ]+\$');
final RegExp _tanwinFathAlifRx = RegExp('(ًا|اً)\$');
const _articleIsPartOfWord = {
  'الله',
  'اللهم',
  'الذي',
  'التي',
  'الذين',
  'اللذان',
  'اللتان',
  'اللاتي',
  'اللواتي',
  'اللاي',
};
final RegExp _arabicBaseLetterRx = RegExp('[ء-ي]');

/// Sonuçlarda birleştirilebilecek türler: isim, sıfat, mastar, zarf. Fiil,
/// edat, harf ve zamirlerde son hareke anlam taşır (كَتَبْتُ "yazdım",
/// كَتَبْتَ "yazdın"); tür bilinmiyorsa da dokunulmaz.
bool _isCollapsibleType(WordModel word) {
  final t = turkishLower(_typeText(word) ?? '');
  if (t.isEmpty) return false;
  if (t.contains('fiil') ||
      t.contains('harf') ||
      t.contains('edat') ||
      t.contains('zamir')) {
    return false;
  }
  return t.contains('isim') ||
      t.contains('ism') ||
      t.contains('sıfat') ||
      t.contains('mastar') ||
      t.contains('zarf');
}

/// Aynı ismin hal eki ve "el-" takısı farkıyla tekrar eden kayıtları için
/// ortak anahtar: بَيْتٌ, بَيْتٍ, الْبَيْتُ → بَيْت. Birleştirilemeyen
/// türlerde ve çok kelimeli kayıtlarda null döner.
String? nounLemmaKey(WordModel word) {
  if (!_isCollapsibleType(word)) return null;
  var h = (word.harekeliKelime ?? '')
      .trim()
      .replaceAll('ـ', '')
      .replaceAll('ٱ', 'ا');
  if (h.startsWith('اَ')) h = 'ا${h.substring(2)}';
  if (h.isEmpty || h.contains(' ')) return null;

  final article = _articleRx.firstMatch(h);
  if (article != null) {
    final rest = h.substring(article.end);
    // "اللَّه" ve ilgi zamirlerinde ال kelimenin parçasıdır, silinmez.
    if (_arabicBaseLetterRx.allMatches(rest).length >= 2 &&
        !_articleIsPartOfWord.contains(normalizeArabic(h))) {
      h = rest;
      // Güneş harfinde lam okunmaz, ilk harf şeddelenir: الشُّكْرُ → شُكْر
      if (article.group(1) == null) {
        final shadda = h.indexOf('ّ');
        if (shadda >= 0 && shadda <= 2) {
          h = h.substring(0, shadda) + h.substring(shadda + 1);
        }
      }
    }
  }
  h = h.replaceFirst(_tanwinFathAlifRx, '');
  // Hal harekesi ve tenvin silinir, şedde kelimenin parçası olduğu için kalır.
  final ending = _caseEndingRx.firstMatch(h);
  if (ending != null) {
    final keepShadda = ending.group(0)!.contains('ّ');
    h = h.substring(0, ending.start) + (keepShadda ? 'ّ' : '');
  }
  return h.isEmpty ? null : h;
}

/// Yalın biçim: "el-" takısız ve ötreli tenvinle biten (بَيْتٌ).
bool _isCanonicalNounForm(WordModel word) {
  final h = (word.harekeliKelime ?? '').trim().replaceAll('ٱ', 'ا');
  return h.endsWith('ٌ') && !_articleRx.hasMatch(h);
}

/// Türkçe aramada aynı kökten, ilk anlamı aynı olan kayıtlar için anahtar:
/// كَتَبَ ve كَتَبَتِ ("yazdı"), رَاحَ ve رَاحَتْ ("gitti"). Türkçe arayan
/// kullanıcı için bunlar aynı sonuçtur. Kökü ya da anlamı yoksa null.
String? sameSenseKey(WordModel word) {
  final root = normalizeArabic(word.koku ?? '').replaceAll(' ', '');
  if (root.isEmpty) return null;
  final main = (word.anlam ?? '').split('||').first;
  final first = foldLatin(main.split(_meaningSplitRx).first);
  // Tür de aynı olmalı: Endonezcede كَتَبَ (fiil) ve كِتَابَةٌ (mastar) ikisi de
  // "menulis"; birleşince fiil yerine mastar görünüyordu.
  final type = word.dilbilgiselOzellikler?['tur'] ?? word.kelimeTuru ?? '';
  return first.isEmpty ? null : '$root|$type|$first';
}

/// Aynı kelimenin kopyalarını tek sonuçta toplar: isimlerde hal/takı farkı
/// (بَيْتٌ, بَيْتٍ, الْبَيْتُ); [turkishQuery] ise ayrıca aynı kökten aynı
/// anlamdaki varyantlar ([sameSenseKey]). Grup, en iyi sıralanan üyesinin
/// yerinde durur ve onun eşleşme türünü alır. Türkçe aramada gösterilen
/// kayıt varsa yalın biçimdir; Arapça aramada kullanıcının yazdığı biçim kalır.
List<RankedWord> collapseVariants(
  List<RankedWord> results, {
  required bool turkishQuery,
}) {
  final slotOfKey = <String, int>{};
  final groups = <int, List<RankedWord>>{};
  final out = <RankedWord>[];
  for (final r in results) {
    // Türkçe aramada iki anahtardan biri tutarsa aynı kelimedir: aynı isim
    // kalıbı (verideki kök yazımı farklı olsa bile) ya da aynı kök + anlam.
    final keys = [
      if (nounLemmaKey(r.word) case final k?) 'l:$k',
      if (turkishQuery)
        if (sameSenseKey(r.word) case final k?) 's:$k',
    ];
    if (keys.isEmpty) {
      out.add(r);
      continue;
    }
    int? slot;
    for (final k in keys) {
      slot ??= slotOfKey[k];
    }
    if (slot == null) {
      slot = out.length;
      groups[slot] = [r];
      out.add(r);
    } else {
      groups[slot]!.add(r);
    }
    for (final k in keys) {
      slotOfKey.putIfAbsent(k, () => slot!);
    }
  }
  if (turkishQuery) {
    for (final entry in groups.entries) {
      final members = entry.value;
      if (members.length < 2) continue;
      final best = members.first;
      // Grupta tekili olan çoğul yalın biçim sayılmaz: Malaycada مَاءٌ ve
      // مِيَاهٌ ikisi de "air"; "air" yazana çoğul gösterilmesin.
      final plurals = {
        for (final m in members)
          if (m.word.dilbilgiselOzellikler?['cogulForm'] case final String p
              when p.isNotEmpty)
            p.trim(),
      };
      final canonical = members.firstWhere(
        (m) =>
            _isCanonicalNounForm(m.word) &&
            !plurals.contains((m.word.harekeliKelime ?? '').trim()),
        orElse: () => best,
      );
      if (!identical(canonical, best)) {
        out[entry.key] = RankedWord(canonical.word, best.matchType);
      }
    }
  }
  return out;
}
