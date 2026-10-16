import 'dart:convert';
import 'quran_word_model.dart';
import 'word_model.dart';

/// Listeye kaydedilebilen bir öğenin kimliği ve verisi: normal sözlük kelimesi,
/// Kur'an sözlüğü kelimesi veya emsile fiili. Üçü de aynı listelerde durur.
class SaveTarget {
  const SaveTarget({
    required this.arabic,
    this.harekeli,
    required this.turkish,
    required this.wordData,
  });

  /// Kayıt anahtarı. Sözlük kelimesinde kelimenin kendisi; diğerlerinde
  /// `quran:` / `emsile:` önekli (farklı türler birbirine karışmasın diye).
  final String arabic;
  final String? harekeli;
  final String turkish;
  final Map<String, dynamic> wordData;

  static const quranPrefix = 'quran:';
  static const emsilePrefix = 'emsile:';

  factory SaveTarget.fromWordModel(WordModel w) => SaveTarget(
    arabic: w.kelime,
    harekeli: w.harekeliKelime,
    turkish: w.anlam ?? '',
    wordData: w.toJson(),
  );

  factory SaveTarget.fromQuran(QuranWordModel w) => SaveTarget(
    arabic: '$quranPrefix${w.kelime}',
    turkish: w.anlamlar,
    wordData: {'kind': 'quran', ...w.toMap()},
  );

  /// [verb]: EmsileDatabaseService'in döndürdüğü fiil kaydı.
  factory SaveTarget.fromEmsile(Map<String, dynamic> verb) {
    String form(int sira) {
      final list = verb['emsile_24'] as List<dynamic>? ?? const [];
      for (final e in list) {
        if (e is Map && e['sira'] == sira) return e['arapca']?.toString() ?? '';
      }
      return '';
    }

    final anlamlar = verb['anlamlar'] as List<dynamic>? ?? const [];
    final meaning = anlamlar.isNotEmpty ? anlamlar.first.toString() : '';
    final id = verb['id'];
    return SaveTarget(
      arabic: '$emsilePrefix$id',
      turkish: meaning,
      wordData: {
        'kind': 'emsile',
        'id': id,
        'mazi': form(1),
        'muzari': form(2),
        'anlam': meaning,
      },
    );
  }
}

class CustomWord {
  final String id;
  final String arabic;
  final String turkish;
  final String? harekeliKelime; // Harekeli Arapça kelime
  final Map<String, dynamic>? wordData; // Tüm WordModel verileri
  final DateTime createdAt;
  final String? listId; // Hangi listeye ait olduğu

  CustomWord({
    required this.id,
    required this.arabic,
    required this.turkish,
    this.harekeliKelime,
    this.wordData,
    required this.createdAt,
    this.listId,
  });

  /// WordModel'den CustomWord oluştur
  factory CustomWord.fromWordModel(WordModel word, String id, String listId) {
    return CustomWord(
      id: id,
      arabic: word.kelime,
      turkish: word.anlam ?? '',
      harekeliKelime: word.harekeliKelime,
      wordData: word.toJson(),
      createdAt: DateTime.now(),
      listId: listId,
    );
  }

  /// Öğenin türü: 'word' (sözlük), 'quran' veya 'emsile'.
  String get kind {
    if (arabic.startsWith(SaveTarget.quranPrefix)) return 'quran';
    if (arabic.startsWith(SaveTarget.emsilePrefix)) return 'emsile';
    return 'word';
  }

  /// Bu kayıt, ([arabic], [harekeli]) ile belirtilen öğe mi?
  ///
  /// Eskiden yalnızca `kelime` karşılaştırılıyordu; sözlükte `kelime` alanı
  /// ortak olan farklı kelimeler (ör. "كتب" için كَتَبَ ve لِيَكْتُبْ) biri
  /// kaydedilince ötekini de "kayıtlı" gösteriyor, ikincisi eklenemiyordu.
  /// Artık sözlük kelimelerinde harekeli yazım da karşılaştırılıyor.
  bool isSameItem(String arabic, String? harekeli) {
    if (this.arabic != arabic) return false;
    if (kind != 'word') return true;
    final stored = harekeliKelime?.trim() ?? '';
    final wanted = harekeli?.trim() ?? '';
    if (stored.isEmpty || wanted.isEmpty) return true;
    return stored == wanted;
  }

  /// Kur'an sözlüğü kaydıysa modeli, değilse null.
  QuranWordModel? toQuranWord() {
    final data = wordData;
    if (kind != 'quran' || data == null) return null;
    return QuranWordModel.fromMap(data);
  }

  /// CustomWord'den WordModel oluştur
  WordModel toWordModel() {
    final data = wordData;
    if (kind == 'quran' && data != null) {
      final q = QuranWordModel.fromMap(data);
      return WordModel(
        kelime: q.kelime,
        harekeliKelime: q.kelime,
        koku: q.kok,
        anlam: q.anlamlar,
      );
    }
    if (kind == 'emsile' && data != null) {
      final mazi = data['mazi']?.toString() ?? '';
      return WordModel(
        kelime: mazi,
        harekeliKelime: mazi,
        anlam: data['anlam']?.toString() ?? turkish,
        fiilCekimler: {
          'maziForm': mazi,
          'muzariForm': data['muzari']?.toString() ?? '',
        },
      );
    }
    if (wordData != null) {
      return WordModel.fromJson(wordData!);
    }
    // Eski veriler için fallback
    return WordModel(
      kelime: arabic,
      harekeliKelime: harekeliKelime ?? arabic,
      anlam: turkish,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'arabic': arabic,
      'turkish': turkish,
      'harekeliKelime': harekeliKelime,
      'wordData': wordData,
      'createdAt': createdAt.toIso8601String(),
      'listId': listId,
    };
  }

  factory CustomWord.fromMap(Map<String, dynamic> map) {
    return CustomWord(
      id: map['id'] ?? '',
      arabic: map['arabic'] ?? '',
      turkish: map['turkish'] ?? '',
      harekeliKelime: map['harekeliKelime'],
      wordData: map['wordData'] != null 
          ? Map<String, dynamic>.from(map['wordData']) 
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      listId: map['listId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomWord.fromJson(String source) => CustomWord.fromMap(json.decode(source));
}
