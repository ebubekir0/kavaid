import '../l10n/l10n.dart';
import '../services/language_service.dart';

// Levanten uygulamasından adapte edilmiştir.

enum DialectLanguageType {
  standard, // Temel diller (Türkçe, İngilizce vb.)
  arabic, // Arapça lehçeleri
}

class DialectLanguage {
  final String code;
  final String sttCode;
  final String name;
  final String nativeName;
  final DialectLanguageType type;

  const DialectLanguage({
    required this.code,
    required this.sttCode,
    required this.name,
    required this.nativeName,
    required this.type,
  });

  /// Arayüz dilinde görünen ad. `name` yapay zekâ istemlerinde kullanıldığı için Türkçe kalır.
  String get displayName => switch (code) {
        'tr' => l10n.dialectTr,
        'en' => l10n.dialectEn,
        'de' => l10n.dialectDe,
        'fr' => l10n.dialectFr,
        'ru' => l10n.dialectRu,
        'es' => l10n.dialectEs,
        'it' => l10n.dialectIt,
        'pt' => l10n.dialectPt,
        'nl' => l10n.dialectNl,
        'fa' => l10n.dialectFa,
        'ur' => l10n.dialectUr,
        'id' => l10n.dialectId,
        'ms' => l10n.dialectMs,
        'bn' => l10n.dialectBn,
        'uz' => l10n.dialectUz,
        'az' => l10n.dialectAz,
        'ar_standard' => l10n.dialectArStandard,
        'ar_syrian' => l10n.dialectArSyrian,
        'ar_lebanese' => l10n.dialectArLebanese,
        'ar_jordanian' => l10n.dialectArJordanian,
        'ar_palestinian' => l10n.dialectArPalestinian,
        'ar_egyptian' => l10n.dialectArEgyptian,
        'ar_iraqi' => l10n.dialectArIraqi,
        'ar_sudanese' => l10n.dialectArSudanese,
        'ar_saudi' => l10n.dialectArSaudi,
        'ar_emirati' => l10n.dialectArEmirati,
        'ar_kuwaiti' => l10n.dialectArKuwaiti,
        'ar_qatari' => l10n.dialectArQatari,
        'ar_omani' => l10n.dialectArOmani,
        'ar_yemeni' => l10n.dialectArYemeni,
        'ar_moroccan' => l10n.dialectArMoroccan,
        'ar_algerian' => l10n.dialectArAlgerian,
        'ar_tunisian' => l10n.dialectArTunisian,
        'ar_libyan' => l10n.dialectArLibyan,
        _ => name,
      };

  String get flagEmoji {
    const flags = {
      'tr': '🇹🇷',
      'ms': '🇲🇾',
      'bn': '🇧🇩',
      'uz': '🇺🇿',
      'az': '🇦🇿',
      'en': '🇺🇸',
      'ar_standard': '🇸🇦',
      'ar_syrian': '🇸🇾',
      'ar_lebanese': '🇱🇧',
      'ar_jordanian': '🇯🇴',
      'ar_palestinian': '🇵🇸',
      'ar_egyptian': '🇪🇬',
      'ar_iraqi': '🇮🇶',
      'ar_sudanese': '🇸🇩',
      'ar_saudi': '🇸🇦',
      'ar_emirati': '🇦🇪',
      'ar_kuwaiti': '🇰🇼',
      'ar_qatari': '🇶🇦',
      'ar_omani': '🇴🇲',
      'ar_yemeni': '🇾🇪',
      'ar_moroccan': '🇲🇦',
      'ar_algerian': '🇩🇿',
      'ar_tunisian': '🇹🇳',
      'ar_libyan': '🇱🇾',
    };
    return flags[code] ?? '🌐';
  }

  /// Kaynak dil: Türkçe, İngilizce, Arapça çeşitleri ve kullanıcının arayüz dili.
  static bool isAllowedSource(DialectLanguage language) {
    return language.code == 'tr' ||
        language.code == 'en' ||
        language.code == LanguageService().uiLocale.languageCode ||
        language.type == DialectLanguageType.arabic;
  }

  static const List<DialectLanguage> supportedLanguages = [
    // ══ STANDART DİLLER ══
    DialectLanguage(
      code: 'tr',
      sttCode: 'tr-TR',
      name: 'Türkçe',
      nativeName: 'Türkçe',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'en',
      sttCode: 'en-US',
      name: 'İngilizce',
      nativeName: 'English',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'de',
      sttCode: 'de-DE',
      name: 'Almanca',
      nativeName: 'Deutsch',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'fr',
      sttCode: 'fr-FR',
      name: 'Fransızca',
      nativeName: 'Français',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'ru',
      sttCode: 'ru-RU',
      name: 'Rusça',
      nativeName: 'Русский',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'es',
      sttCode: 'es-ES',
      name: 'İspanyolca',
      nativeName: 'Español',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'it',
      sttCode: 'it-IT',
      name: 'İtalyanca',
      nativeName: 'Italiano',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'pt',
      sttCode: 'pt-BR',
      name: 'Portekizce',
      nativeName: 'Português',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'nl',
      sttCode: 'nl-NL',
      name: 'Hollandaca',
      nativeName: 'Nederlands',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'fa',
      sttCode: 'fa-IR',
      name: 'Farsça',
      nativeName: 'فارسی',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'ur',
      sttCode: 'ur-PK',
      name: 'Urduca',
      nativeName: 'اردو',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'id',
      sttCode: 'id-ID',
      name: 'Endonezce',
      nativeName: 'Bahasa Indonesia',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'ms',
      sttCode: 'ms-MY',
      name: 'Malayca',
      nativeName: 'Bahasa Melayu',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'bn',
      sttCode: 'bn-BD',
      name: 'Bengalce',
      nativeName: 'বাংলা',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'uz',
      sttCode: 'uz-UZ',
      name: 'Özbekçe',
      nativeName: 'Oʻzbekcha',
      type: DialectLanguageType.standard,
    ),
    DialectLanguage(
      code: 'az',
      sttCode: 'az-AZ',
      name: 'Azerice',
      nativeName: 'Azərbaycanca',
      type: DialectLanguageType.standard,
    ),

    // ══ STANDART ARAPÇA ══
    DialectLanguage(
      code: 'ar_standard',
      sttCode: 'ar-SA',
      name: 'Standart Arapça',
      nativeName: 'العربية الفصحى',
      type: DialectLanguageType.arabic,
    ),

    // ══ LEVANTEN LEHÇELERİ ══
    DialectLanguage(
      code: 'ar_syrian',
      sttCode: 'ar-JO',
      name: 'Suriye Arapçası',
      nativeName: 'سوري',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_lebanese',
      sttCode: 'ar-LB',
      name: 'Lübnan Arapçası',
      nativeName: 'لبناني',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_jordanian',
      sttCode: 'ar-JO',
      name: 'Ürdün Arapçası',
      nativeName: 'أردني',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_palestinian',
      sttCode: 'ar-PS',
      name: 'Filistin Arapçası',
      nativeName: 'فلسطيني',
      type: DialectLanguageType.arabic,
    ),

    // ══ MISIR & IRAK & SUDAN ══
    DialectLanguage(
      code: 'ar_egyptian',
      sttCode: 'ar-EG',
      name: 'Mısır Arapçası',
      nativeName: 'مصري',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_iraqi',
      sttCode: 'ar-IQ',
      name: 'Irak Arapçası',
      nativeName: 'عراقي',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_sudanese',
      sttCode: 'ar-EG',
      name: 'Sudan Arapçası',
      nativeName: 'سوداني',
      type: DialectLanguageType.arabic,
    ),

    // ══ KÖRFEZ ══
    DialectLanguage(
      code: 'ar_saudi',
      sttCode: 'ar-SA',
      name: 'Suudi Arapçası',
      nativeName: 'سعودي',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_emirati',
      sttCode: 'ar-AE',
      name: 'Emirlik Arapçası',
      nativeName: 'إماراتي',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_kuwaiti',
      sttCode: 'ar-KW',
      name: 'Kuveyt Arapçası',
      nativeName: 'كويتي',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_qatari',
      sttCode: 'ar-QA',
      name: 'Katar Arapçası',
      nativeName: 'قطري',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_omani',
      sttCode: 'ar-OM',
      name: 'Umman Arapçası',
      nativeName: 'عماني',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_yemeni',
      sttCode: 'ar-YE',
      name: 'Yemen Arapçası',
      nativeName: 'يمني',
      type: DialectLanguageType.arabic,
    ),

    // ══ MAĞRİP ══
    DialectLanguage(
      code: 'ar_moroccan',
      sttCode: 'ar-MA',
      name: 'Fas Arapçası',
      nativeName: 'مغربي',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_algerian',
      sttCode: 'ar-DZ',
      name: 'Cezayir Arapçası',
      nativeName: 'جزائري',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_tunisian',
      sttCode: 'ar-TN',
      name: 'Tunus Arapçası',
      nativeName: 'تونسي',
      type: DialectLanguageType.arabic,
    ),
    DialectLanguage(
      code: 'ar_libyan',
      sttCode: 'ar-TN',
      name: 'Libya Arapçası',
      nativeName: 'ليبي',
      type: DialectLanguageType.arabic,
    ),
  ];
}
