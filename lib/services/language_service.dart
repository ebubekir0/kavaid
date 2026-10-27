import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class LanguageService extends ChangeNotifier {
  static const String _isFirstLaunchKey = 'is_first_launch';

  /// Kullanıcının seçtiği (ya da ilk açılışta belirlenen) arayüz dili.
  static const String uiLocaleKey = 'ui_locale';

  /// Yeni kurulumda true yazılır; tanıtım ekranı gösterilince false olur.
  /// Güncelleme alan kullanıcılarda hiç yazılmaz, tanıtım onlara çıkmaz.
  static const String appIntroPendingKey = 'app_intro_pending_v1';

  /// Arayüz dilleri ve kendi dillerindeki adları (seçim listesinde bu adlar görünür).
  static const Map<String, String> languageNames = {
    'tr': 'Türkçe',
    'en': 'English',
    'ar': 'العربية',
    'id': 'Bahasa Indonesia',
    'ms': 'Bahasa Melayu',
    'ur': 'اردو',
    'fr': 'Français',
    'bn': 'বাংলা',
    'ru': 'Русский',
    'uz': 'Oʻzbekcha',
    'az': 'Azərbaycanca',
    'de': 'Deutsch',
  };

  /// Yapay zekâ istemlerinde kullanılan İngilizce dil adları.
  static const Map<String, String> englishNames = {
    'tr': 'Turkish',
    'en': 'English',
    'ar': 'Arabic',
    'id': 'Indonesian',
    'ms': 'Malay',
    'ur': 'Urdu',
    'fr': 'French',
    'bn': 'Bengali',
    'ru': 'Russian',
    'uz': 'Uzbek (Latin script)',
    'az': 'Azerbaijani (Latin script)',
    'de': 'German',
  };

  Locale _currentLocale = const Locale('tr');
  bool _isFirstLaunch = true;
  bool _initialized = false;

  Locale get currentLocale => _currentLocale;
  bool get isFirstLaunch => _isFirstLaunch;

  /// Arayüz dili (menü, buton, mesaj). Anlam dili ayrıdır (EmbeddedWords.meaningLang).
  Locale get uiLocale => _currentLocale;

  /// Arayüz Türkçe mi? Öğren sekmesi ve kampanya gibi Türkiye'ye özel bölümler buna bakar.
  bool get isTurkishUi => _currentLocale.languageCode == 'tr';

  /// Arayüz sağdan sola mı yazılıyor?
  bool get isRtl => const {'ar', 'ur', 'fa'}.contains(_currentLocale.languageCode);

  // Desteklenen arayüz dilleri (lib/l10n/app_*.arb)
  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  // Singleton pattern
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static bool _isSupported(String code) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == code);

  /// Yeni kurulumda cihaz dili; desteklenmiyorsa İngilizce.
  static String _deviceLanguage() {
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales) {
      if (_isSupported(locale.languageCode)) return locale.languageCode;
    }
    return 'en';
  }

  /// Servis başlatma. main() ilk kareden önce çağırır; tekrar çağrılması zararsızdır.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();

    // Güncelleme alan kullanıcıda (is_first_launch yazılmış) dil Türkçe sabitlenir;
    // yeni kurulumda cihaz dili kullanılır (docs/YERELLESTIRME_PLANI.md 3.1–3.2).
    final saved = prefs.getString(uiLocaleKey);
    final String code;
    if (saved != null && _isSupported(saved)) {
      code = saved;
    } else if (prefs.containsKey(_isFirstLaunchKey)) {
      code = 'tr';
    } else {
      code = _deviceLanguage();
    }
    _currentLocale = Locale(code);
    if (saved != code) await prefs.setString(uiLocaleKey, code);

    // İlk açılış flag'ini kaydet
    _isFirstLaunch = prefs.getBool(_isFirstLaunchKey) ?? true;
    if (_isFirstLaunch) {
      await prefs.setBool(_isFirstLaunchKey, false);
      await prefs.setBool(appIntroPendingKey, true);
      _isFirstLaunch = false;
    }

    notifyListeners();
  }

  /// Arayüz dilini değiştirir; uygulama ağacı yeni dille yeniden kurulur.
  Future<void> changeLanguage(String languageCode) async {
    if (!_isSupported(languageCode) || languageCode == _currentLocale.languageCode) return;
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(uiLocaleKey, languageCode);
    notifyListeners();
  }

  // Aşağıdaki üçü eski İngilizce/Arapça sürüm denemesinden kalma: sözlük verisi ve
  // kartlar hâlâ Türkçe akışla çalıştığı için sabit. Arayüz dili için isTurkishUi/isRtl.

  /// Eski sürüm bayrağı - her zaman false
  bool get isArabic => false;

  /// Eski sürüm bayrağı - her zaman true
  bool get isTurkish => true;

  /// Eski sürüm bayrağı - her zaman false
  bool get isEnglish => false;

  /// Eski sürüm bayrağı - her zaman ltr (arayüz yönünü MaterialApp locale'den alır)
  TextDirection get textDirection => TextDirection.ltr;

  /// Arayüz dilinin kendi dilindeki adı
  String get currentLanguageName =>
      languageNames[_currentLocale.languageCode] ?? _currentLocale.languageCode;

  /// Desteklenen arayüz dillerinin listesi
  List<Map<String, String>> get availableLanguages => [
        for (final locale in supportedLocales)
          {
            'code': locale.languageCode,
            'name': languageNames[locale.languageCode] ?? locale.languageCode,
          },
      ];
}
