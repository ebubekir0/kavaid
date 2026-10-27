import '../l10n/l10n.dart';
import '../services/language_service.dart';

/// Sözlük verisindeki kelime türleri 500'den fazla farklı Türkçe yazımla geliyor
/// ("Muzari Fiil (Nasb Edatıyla)", "İsim Fail Cemi Müzekker Salim"…). Kartta bunlar
/// ~25 ortak türe indirilip arayüz dilinde kısa bir etiketle gösterilir.
enum WordType {
  noun, properNoun, verb, verbPast, verbPresent, verbImperative, verbProhibitive,
  verbPastPassive, verbPresentPassive, verbDefective, masdar, activeParticiple,
  passiveParticiple, elative, adjective, adverb, hal, pronoun, demonstrative,
  relative, interrogative, preposition, particle, number, phrase, expression, idiom,
}

/// Türkçe arayüzde bu uzunluğa kadar olan özgün yazım olduğu gibi gösterilir.
const _maxOriginalLength = 16;

String _fold(String s) => s
    .toLowerCase()
    .replaceAll('i̇', 'i')
    .replaceAll('ı', 'i')
    .replaceAll('İ', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .replaceAll('â', 'a')
    .replaceAll('î', 'i')
    .replaceAll('û', 'u')
    .replaceAll(RegExp(r"['’`]"), '');

/// Verideki Türkçe tür yazımını ortak türe çevirir; tanınmazsa null.
WordType? wordTypeOf(String turkishType) {
  final s = _fold(turkishType);
  bool has(String w) => s.contains(w);
  final words = s.split(RegExp(r'[^a-z0-9-]+'));

  if (has('deyim')) return WordType.idiom;
  if (has('cumle') || has('ifade') || has('obeg')) return WordType.expression;
  if (has('mechul') && has('mazi')) return WordType.verbPastPassive;
  if (has('mechul') && has('muzari')) return WordType.verbPresentPassive;
  if (has('nehiy') || has('nehy')) return WordType.verbProhibitive;
  if (has('nakis')) return WordType.verbDefective;
  if (has('mazi')) return WordType.verbPast;
  if (has('muzari')) return WordType.verbPresent;
  if (has('emir') && has('fiil')) return WordType.verbImperative;
  if (has('mastar') || has('masdar')) return WordType.masdar;
  if (has('tafdil')) return WordType.elative;
  if (has('fail')) return WordType.activeParticiple;
  if (has('meful') || has('mefool')) return WordType.passiveParticiple;
  if (has('ozel isim')) return WordType.properNoun;
  if (has('mevsul')) return WordType.relative;
  if (has('isaret')) return WordType.demonstrative;
  if (has('soru')) return WordType.interrogative;
  if (has('tamlama')) return WordType.phrase;
  if (has('zamir')) {
    return has('harf') || has('edat') ? WordType.preposition : WordType.pronoun;
  }
  // "İsim, Sıfat" gibi listelerde ilk tür esas alınır
  final first = s.split(',').first;
  if (first.contains('sifat')) return WordType.adjective;
  if (first.contains('zarf')) return WordType.adverb;
  if (words.contains('hal')) return WordType.hal;
  if (has('sayi')) return WordType.number;
  if (first.contains('isim')) return WordType.noun;
  if ((has('harf-i cer') || has('harfi cer')) && !has('cerli')) return WordType.preposition;
  if (has('edat') || has('harf') || has('unlem') || has('nida') || has('baglac')) {
    return WordType.particle;
  }
  if (has('isim')) return WordType.noun;
  if (has('fiil')) return WordType.verb;
  return null;
}

String _label(WordType type) => switch (type) {
      WordType.noun => l10n.typeNoun,
      WordType.properNoun => l10n.typeProperNoun,
      WordType.verb => l10n.typeVerb,
      WordType.verbPast => l10n.typeVerbPast,
      WordType.verbPresent => l10n.typeVerbPresent,
      WordType.verbImperative => l10n.typeVerbImperative,
      WordType.verbProhibitive => l10n.typeVerbProhibitive,
      WordType.verbPastPassive => l10n.typeVerbPastPassive,
      WordType.verbPresentPassive => l10n.typeVerbPresentPassive,
      WordType.verbDefective => l10n.typeVerbDefective,
      WordType.masdar => l10n.typeMasdar,
      WordType.activeParticiple => l10n.typeActiveParticiple,
      WordType.passiveParticiple => l10n.typePassiveParticiple,
      WordType.elative => l10n.typeElative,
      WordType.adjective => l10n.typeAdjective,
      WordType.adverb => l10n.typeAdverb,
      WordType.hal => l10n.typeHal,
      WordType.pronoun => l10n.typePronoun,
      WordType.demonstrative => l10n.typeDemonstrative,
      WordType.relative => l10n.typeRelative,
      WordType.interrogative => l10n.typeInterrogative,
      WordType.preposition => l10n.typePreposition,
      WordType.particle => l10n.typeParticle,
      WordType.number => l10n.typeNumber,
      WordType.phrase => l10n.typePhrase,
      WordType.expression => l10n.typeExpression,
      WordType.idiom => l10n.typeIdiom,
    };

/// Kelime kartındaki tür etiketi. Türkçe arayüzde kısa özgün yazım korunur;
/// uzun yazımlar ve diğer diller ortak türün kısa etiketini alır. Tanınmayan
/// tür diğer dillerde gösterilmez (Türkçe metin sızmasın).
String? wordTypeLabel(String turkishType) {
  final original = turkishType.trim();
  if (original.isEmpty) return null;
  final turkishUi = LanguageService().isTurkishUi;
  if (turkishUi && original.length <= _maxOriginalLength) return original;
  final type = wordTypeOf(original);
  if (type == null) return turkishUi ? original : null;
  return _label(type);
}
