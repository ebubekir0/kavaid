// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get searchPlaceholder => 'Kelime ara';

  @override
  String get profile => 'Profil';

  @override
  String get appName => 'Kavaid';

  @override
  String get rateApp => 'Uygulamayı Değerlendir';

  @override
  String get tryAgain => 'Tekrar Dene';

  @override
  String get notFound => 'Bulunamadı';

  @override
  String get searchWithAI => 'AI ile Ara';

  @override
  String get noResults => 'Sonuç bulunamadı';

  @override
  String get language => 'Dil';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageArabic => 'العربية';

  @override
  String get selectLanguage => 'Dil Seçin';

  @override
  String get settings => 'Ayarlar';

  @override
  String get premium => 'Premium';

  @override
  String get removeAds => 'Reklamları Kaldır';

  @override
  String get restorePurchases => 'Satın Alımları Geri Yükle';

  @override
  String get share => 'Paylaş';

  @override
  String get contact => 'İletişim';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String credits(Object count) {
    return 'Hak: $count';
  }

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get searching => 'Aranıyor...';

  @override
  String get wordMeaning => 'Kelime Anlamı';

  @override
  String get exampleSentence => 'Örnek Cümle';

  @override
  String get saved => 'Kaydedildi';

  @override
  String get save => 'Kaydet';

  @override
  String get savedWords => 'Kaydedilen Kelimeler';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get darkMode => 'Koyu Tema';

  @override
  String get lightMode => 'Açık Tema';
}
