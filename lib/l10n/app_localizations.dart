import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_az.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('az'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('id'),
    Locale('ms'),
    Locale('ru'),
    Locale('tr'),
    Locale('ur'),
    Locale('uz'),
  ];

  /// lib/main.dart:125
  ///
  /// In tr, this message translates to:
  /// **'Kavaid Sözlük'**
  String get kavaidSozluk;

  /// Uygulamanın marka adı (Arap yazılı dillerde onaylı karşılığı)
  ///
  /// In tr, this message translates to:
  /// **'Kavaid'**
  String get markaAdi;

  /// Tanıtım ekranında sonraki sayfa düğmesi
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get tanitimDevam;

  /// Tanıtım ekranının son sayfasında uygulamaya geçiş düğmesi
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get tanitimBasla;

  /// lib/main.dart:182
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get tekrarDene;

  /// lib/main.dart:516
  ///
  /// In tr, this message translates to:
  /// **'Kavaid - Arapça Sözlük'**
  String get kavaidArapcaSozluk;

  /// lib/main.dart:1482
  ///
  /// In tr, this message translates to:
  /// **'Sözlük'**
  String get sozluk;

  /// lib/main.dart:1490
  ///
  /// In tr, this message translates to:
  /// **'Çeviri'**
  String get ceviri;

  /// lib/main.dart:1497
  ///
  /// In tr, this message translates to:
  /// **'Öğren'**
  String get ogren;

  /// lib/main.dart:1502
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profil;

  /// lib/models/word_model.dart:45
  ///
  /// In tr, this message translates to:
  /// **'Kelime bulunamadı'**
  String get kelimeBulunamadi;

  /// lib/screens/campaign_screen.dart:31
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı açılamadı'**
  String get baglantiAcilamadi;

  /// lib/screens/campaign_screen.dart:52
  ///
  /// In tr, this message translates to:
  /// **'Tebrikler! 1 Ay Premium hesabınıza tanımlandı 🌟'**
  String get tebrikler1AyPremiumHesabiniza;

  /// lib/screens/campaign_screen.dart:59
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz veya kullanılmış kod.'**
  String get gecersizVeyaKullanilmisKod;

  /// lib/screens/campaign_screen.dart:61
  ///
  /// In tr, this message translates to:
  /// **'Bu kodu daha önce kullandınız.'**
  String get buKoduDahaOnceKullandiniz;

  /// lib/screens/campaign_screen.dart:63
  ///
  /// In tr, this message translates to:
  /// **'Bu kodun süresi dolmuş.'**
  String get buKodunSuresiDolmus;

  /// lib/screens/campaign_screen.dart:65
  ///
  /// In tr, this message translates to:
  /// **'Bu kodun kullanım limiti dolmuş.'**
  String get buKodunKullanimLimitiDolmus;

  /// lib/screens/campaign_screen.dart:67
  ///
  /// In tr, this message translates to:
  /// **'Lütfen önce giriş yapın.'**
  String get lutfenOnceGirisYapin;

  /// lib/screens/campaign_screen.dart:130
  ///
  /// In tr, this message translates to:
  /// **'1 Ay Ücretsiz Premium Kazan'**
  String get m1AyUcretsizPremiumKazan;

  /// lib/screens/campaign_screen.dart:142
  ///
  /// In tr, this message translates to:
  /// **'Uygulama hakkında görüşlerinizi belirtilen tweeti alıntılayarak Twitter (X)\'te paylaşın, 1 ay ücretsiz premium kazanın!'**
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti;

  /// lib/screens/campaign_screen.dart:169
  ///
  /// In tr, this message translates to:
  /// **'Nasıl Katılırım?'**
  String get nasilKatilirim;

  /// lib/screens/campaign_screen.dart:180
  ///
  /// In tr, this message translates to:
  /// **'Uygulama ile ilgili görüşlerinizi belirtilen tweeti alıntılayarak Twitter (X)\'te paylaşın.'**
  String get uygulamaIleIlgiliGorusleriniziBelirtilen;

  /// lib/screens/campaign_screen.dart:192
  ///
  /// In tr, this message translates to:
  /// **'Paylaşımınızı Twitter\'da @ebubekr53 hesabına direkt mesaj atın, kodunuzu alın.'**
  String get paylasiminiziTwitterDaEbubekr53Hesabina;

  /// lib/screens/campaign_screen.dart:204
  ///
  /// In tr, this message translates to:
  /// **'Kodu aşağıya girin.'**
  String get koduAsagiyaGirin;

  /// lib/screens/campaign_screen.dart:218
  ///
  /// In tr, this message translates to:
  /// **'Tweeti Alıntıla'**
  String get tweetiAlintila;

  /// lib/screens/campaign_screen.dart:252
  ///
  /// In tr, this message translates to:
  /// **'Promosyon Kodu'**
  String get promosyonKodu;

  /// lib/screens/campaign_screen.dart:308
  ///
  /// In tr, this message translates to:
  /// **'Kullan'**
  String get kullan;

  /// lib/screens/custom_words_screen.dart:140
  ///
  /// In tr, this message translates to:
  /// **'Daha Fazla Özellik'**
  String get dahaFazlaOzellik;

  /// lib/screens/custom_words_screen.dart:149
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla liste oluşturmak için\nPremium\'a yükselt'**
  String get dahaFazlaListeOlusturmakIcin;

  /// lib/screens/custom_words_screen.dart:171
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get kapat;

  /// lib/screens/custom_words_screen.dart:197
  ///
  /// In tr, this message translates to:
  /// **'Premium Al'**
  String get premiumAl;

  /// lib/screens/custom_words_screen.dart:219
  ///
  /// In tr, this message translates to:
  /// **'Yeni Liste'**
  String get yeniListe;

  /// lib/screens/custom_words_screen.dart:228
  ///
  /// In tr, this message translates to:
  /// **'Liste adı'**
  String get listeAdi;

  /// lib/screens/custom_words_screen.dart:254
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get iptal;

  /// lib/screens/custom_words_screen.dart:267
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get olustur;

  /// lib/screens/custom_words_screen.dart:286
  ///
  /// In tr, this message translates to:
  /// **'Listeyi Yeniden Adlandır'**
  String get listeyiYenidenAdlandir;

  /// lib/screens/custom_words_screen.dart:322
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get kaydet;

  /// lib/screens/custom_words_screen.dart:367
  ///
  /// In tr, this message translates to:
  /// **'Kelime Listelerim'**
  String get kelimeListelerim;

  /// lib/screens/custom_words_screen.dart:409
  ///
  /// In tr, this message translates to:
  /// **'Yeni Liste Oluştur'**
  String get yeniListeOlustur;

  /// lib/screens/custom_words_screen.dart:449
  ///
  /// In tr, this message translates to:
  /// **'Henüz liste yok'**
  String get henuzListeYok;

  /// lib/screens/custom_words_screen.dart:458
  ///
  /// In tr, this message translates to:
  /// **'Kelimelerinizi düzenlemek için\nbir liste oluşturun'**
  String get kelimeleriniziDuzenlemekIcinBirListe;

  /// lib/screens/custom_words_screen.dart:563
  ///
  /// In tr, this message translates to:
  /// **'{wordCount} kelime'**
  String wordcountKelime(int wordCount);

  /// lib/screens/custom_words_screen.dart:608
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Adlandır'**
  String get yenidenAdlandir;

  /// lib/screens/custom_words_screen.dart:623
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get sil;

  /// lib/screens/custom_words_screen.dart:646
  ///
  /// In tr, this message translates to:
  /// **'Listeyi Sil'**
  String get listeyiSil;

  /// lib/screens/custom_words_screen.dart:652
  ///
  /// In tr, this message translates to:
  /// **'\"{name}\" silinsin mi?\nİçindeki tüm kelimeler de silinecek.'**
  String nameSilinsinMiIcindekiTum(Object name);

  /// lib/screens/custom_words_screen.dart:776
  ///
  /// In tr, this message translates to:
  /// **'Bu listede henüz kelime yok'**
  String get buListedeHenuzKelimeYok;

  /// lib/screens/custom_words_screen.dart:835
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get liste;

  /// lib/screens/custom_words_screen.dart:865
  ///
  /// In tr, this message translates to:
  /// **'Kart'**
  String get kart;

  /// lib/screens/custom_words_screen.dart:1088
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla kelime kartı için Premium\'a yükselt'**
  String get dahaFazlaKelimeKartiIcin;

  /// lib/screens/custom_words_screen.dart:1128
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a Yükselt'**
  String get premiumAYukselt;

  /// lib/screens/custom_words_screen.dart:1190
  ///
  /// In tr, this message translates to:
  /// **'Dinle'**
  String get dinle;

  /// lib/screens/game/game_screen.dart:20
  ///
  /// In tr, this message translates to:
  /// **'Oyun'**
  String get oyun;

  /// lib/screens/home_screen.dart:697
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Sınırı Doldu'**
  String get kullanimSiniriDoldu;

  /// lib/screens/home_screen.dart:707
  ///
  /// In tr, this message translates to:
  /// **'Kuran sözlüğünü sınırsız kullanmaya devam etmek için lütfen giriş yapın ve Premium\'a yükseltin.'**
  String get kuranSozlugunuSinirsizKullanmayaDevam;

  /// lib/screens/home_screen.dart:729
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get tamam;

  /// lib/screens/home_screen.dart:886
  ///
  /// In tr, this message translates to:
  /// **'Tüm kitaplar açıldı ve reklamlar kaldırıldı.'**
  String get tumKitaplarAcildiVeReklamlar;

  /// lib/screens/home_screen.dart:887
  ///
  /// In tr, this message translates to:
  /// **'Tüm kitaplar açıldı. Reklamları kalıcı kaldırmak için lütfen giriş yapın.'**
  String get tumKitaplarAcildiReklamlariKalici;

  /// lib/screens/home_screen.dart:904
  ///
  /// In tr, this message translates to:
  /// **'Gizli kod uygulanamadı: {e}'**
  String gizliKodUygulanamadiE(Object e);

  /// lib/screens/home_screen.dart:928
  ///
  /// In tr, this message translates to:
  /// **'Sözlük güncelleniyor... Lütfen bekleyin.'**
  String get sozlukGuncelleniyorLutfenBekleyin;

  /// lib/screens/home_screen.dart:946
  ///
  /// In tr, this message translates to:
  /// **'Sözlük başarıyla güncellendi! {p1} kelime yüklendi.'**
  String sozlukBasariylaGuncellendiP1Kelime(int p1);

  /// lib/screens/home_screen.dart:955
  ///
  /// In tr, this message translates to:
  /// **'Sözlük güncellenirken hata oluştu!'**
  String get sozlukGuncellenirkenHataOlustu;

  /// lib/screens/home_screen.dart:973
  ///
  /// In tr, this message translates to:
  /// **'Database reload hatası: {e}'**
  String databaseReloadHatasiE(Object e);

  /// lib/screens/home_screen.dart:1374
  ///
  /// In tr, this message translates to:
  /// **'Lütfen önce kayıt olun, giriş yapın.'**
  String get lutfenOnceKayitOlunGiris;

  /// lib/screens/home_screen.dart:1678
  ///
  /// In tr, this message translates to:
  /// **'Kelime ara'**
  String get kelimeAra;

  /// lib/screens/home_screen.dart:2113
  ///
  /// In tr, this message translates to:
  /// **'Emsile'**
  String get emsile;

  /// lib/screens/home_screen.dart:2215
  ///
  /// In tr, this message translates to:
  /// **'Kuran Sözlüğü'**
  String get kuranSozlugu;

  /// lib/screens/home_screen.dart:2339
  ///
  /// In tr, this message translates to:
  /// **'Kavaid’i değerlendir'**
  String get kavaidIDegerlendir;

  /// lib/screens/home_screen.dart:2349
  ///
  /// In tr, this message translates to:
  /// **'Görüşün bizim için çok değerli.'**
  String get gorusunBizimIcinCokDegerli;

  /// lib/screens/home_screen.dart:2434
  ///
  /// In tr, this message translates to:
  /// **'Kuran sözlüğü yükleniyor...'**
  String get kuranSozluguYukleniyor;

  /// lib/screens/home_screen.dart:2436
  ///
  /// In tr, this message translates to:
  /// **'Kuran sözlüğünde aranıyor...'**
  String get kuranSozlugundeAraniyor;

  /// lib/screens/home_screen.dart:2437
  ///
  /// In tr, this message translates to:
  /// **'Aranıyor...'**
  String get araniyor;

  /// lib/screens/home_screen.dart:2508
  ///
  /// In tr, this message translates to:
  /// **'Kuran sözlüğünde bulunamadı'**
  String get kuranSozlugundeBulunamadi;

  /// lib/screens/home_screen.dart:2517
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir kelime veya kök ile aramayı deneyin'**
  String get farkliBirKelimeVeyaKok;

  /// lib/screens/home_screen.dart:2739
  ///
  /// In tr, this message translates to:
  /// **'Kuran sözlüğünü daha fazla kullanabilmek için Premium\'a yükseltin.'**
  String get kuranSozlugunuDahaFazlaKullanabilmek;

  /// lib/screens/home_screen.dart:2787
  ///
  /// In tr, this message translates to:
  /// **'Kur\'an-ı Kerim Sözlüğü'**
  String get kurAnIKerimSozlugu;

  /// lib/screens/home_screen.dart:2793
  ///
  /// In tr, this message translates to:
  /// **'Kur\'an\'da geçen tüm kelimelerin kullanımlarını ve Kur\'ani anlamlarını ayetlerle birlikte öğrenin.'**
  String get kurAnDaGecenTum;

  /// lib/screens/home_screen.dart:2801
  ///
  /// In tr, this message translates to:
  /// **'Kur\'an\'daki benzersiz tüm kelimeler.'**
  String get kurAnDakiBenzersizTum;

  /// lib/screens/home_screen.dart:2810
  ///
  /// In tr, this message translates to:
  /// **'Kurani Anlamlar'**
  String get kuraniAnlamlar;

  /// lib/screens/home_screen.dart:2811
  ///
  /// In tr, this message translates to:
  /// **'Kelimelerin Kur\'an ayetlerinde kazandığı anlamları öğrenin.'**
  String get kelimelerinKurAnAyetlerindeKazandigi;

  /// lib/screens/home_screen.dart:2820
  ///
  /// In tr, this message translates to:
  /// **'Kur\'an Ayetleri'**
  String get kurAnAyetleri;

  /// lib/screens/home_screen.dart:2821
  ///
  /// In tr, this message translates to:
  /// **'On binlerce Kur\'an ayeti ile kelimelerin Kur\'andaki kullanımlarını görün.'**
  String get onBinlerceKurAnAyeti;

  /// lib/screens/home_screen.dart:2889
  ///
  /// In tr, this message translates to:
  /// **'Kavaid Arapça Sözlük'**
  String get kavaidArapcaSozluk2;

  /// lib/screens/home_screen.dart:2895
  ///
  /// In tr, this message translates to:
  /// **'Yeni nesil yapay zeka destekli ilk Arapça sözlük'**
  String get yeniNesilYapayZekaDestekli;

  /// lib/screens/home_screen.dart:3007
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a Geç'**
  String get premiumAGec;

  /// lib/screens/home_screen.dart:3016
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız erişim'**
  String get sinirsizErisim;

  /// lib/screens/profile_screen.dart:321
  ///
  /// In tr, this message translates to:
  /// **'✅ Profil resmi güncellendi!'**
  String get profilResmiGuncellendi;

  /// lib/screens/profile_screen.dart:331
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu'**
  String get birHataOlustu;

  /// lib/screens/profile_screen.dart:334
  ///
  /// In tr, this message translates to:
  /// **'Firebase Storage yapılandırılmamış. Lütfen Firebase Console\'dan Storage\'ı aktifleştirin.'**
  String get firebaseStorageYapilandirilmamisLutfenFirebase;

  /// lib/screens/profile_screen.dart:336
  ///
  /// In tr, this message translates to:
  /// **'İzin hatası. Storage kurallarını kontrol edin.'**
  String get izinHatasiStorageKurallariniKontrol;

  /// lib/screens/profile_screen.dart:338
  ///
  /// In tr, this message translates to:
  /// **'Yetkilendirme hatası. Lütfen giriş yapın.'**
  String get yetkilendirmeHatasiLutfenGirisYapin;

  /// lib/screens/profile_screen.dart:340
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı hatası.'**
  String get internetBaglantisiHatasi;

  /// lib/screens/profile_screen.dart:356
  ///
  /// In tr, this message translates to:
  /// **'Detay'**
  String get detay;

  /// lib/screens/profile_screen.dart:362
  ///
  /// In tr, this message translates to:
  /// **'Hata Detayı'**
  String get hataDetayi;

  /// lib/screens/profile_screen.dart:515
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get kullanici;

  /// lib/screens/profile_screen.dart:616
  ///
  /// In tr, this message translates to:
  /// **'KURUCU'**
  String get kurucu;

  /// lib/screens/profile_screen.dart:617
  ///
  /// In tr, this message translates to:
  /// **'MODERATÖR'**
  String get moderator;

  /// lib/screens/profile_screen.dart:663
  ///
  /// In tr, this message translates to:
  /// **'Email yok'**
  String get emailYok;

  /// lib/screens/profile_screen.dart:679
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yapılsın mı?'**
  String get cikisYapilsinMi;

  /// lib/screens/profile_screen.dart:680
  ///
  /// In tr, this message translates to:
  /// **'Oturumunuz kapatılacak.'**
  String get oturumunuzKapatilacak;

  /// lib/screens/profile_screen.dart:688
  ///
  /// In tr, this message translates to:
  /// **'Çıkış'**
  String get cikis;

  /// lib/screens/profile_screen.dart:729
  ///
  /// In tr, this message translates to:
  /// **'Aboneliği Yönet'**
  String get aboneligiYonet;

  /// lib/screens/profile_screen.dart:743
  ///
  /// In tr, this message translates to:
  /// **'Satın almalar kontrol ediliyor...'**
  String get satinAlmalarKontrolEdiliyor;

  /// lib/screens/profile_screen.dart:752
  ///
  /// In tr, this message translates to:
  /// **'Geri Yükle'**
  String get geriYukle;

  /// lib/screens/profile_screen.dart:773
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapın veya kayıt olun'**
  String get girisYapinVeyaKayitOlun;

  /// lib/screens/profile_screen.dart:802
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get girisYap;

  /// lib/screens/profile_screen.dart:824
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get kayitOl;

  /// lib/screens/profile_screen.dart:873
  ///
  /// In tr, this message translates to:
  /// **'Premium Üyesiniz'**
  String get premiumUyesiniz;

  /// lib/screens/profile_screen.dart:881
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız içerik, reklamsız kullanım.'**
  String get sinirsizIcerikReklamsizKullanim;

  /// lib/screens/profile_screen.dart:942
  ///
  /// In tr, this message translates to:
  /// **'Tüm özelliklere erişin.'**
  String get tumOzelliklereErisin;

  /// lib/screens/profile_screen.dart:985
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız Kullanım'**
  String get reklamsizKullanim;

  /// lib/screens/profile_screen.dart:1120
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Paylaş'**
  String get uygulamayiPaylas;

  /// lib/screens/profile_screen.dart:1173
  ///
  /// In tr, this message translates to:
  /// **'İletişim'**
  String get iletisim;

  /// lib/screens/profile_screen.dart:1187
  ///
  /// In tr, this message translates to:
  /// **'Kavaid Uygulaması Hakkında'**
  String get kavaidUygulamasiHakkinda;

  /// lib/screens/profile_screen.dart:1332
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı Sil'**
  String get hesabimiSil;

  /// lib/screens/profile_screen.dart:1373
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı ve hesabınıza bağlı tüm verileri kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'**
  String get hesabiniziVeHesabinizaBagliTum;

  /// lib/screens/profile_screen.dart:1379
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get vazgec;

  /// lib/screens/profile_screen.dart:1389
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız başarıyla silindi.'**
  String get hesabinizBasariylaSilindi;

  /// lib/screens/profile_screen.dart:1399
  ///
  /// In tr, this message translates to:
  /// **'Hesap silinemedi: {e}. Güvenlik gereği yeniden giriş yapmanız gerekebilir.'**
  String hesapSilinemediEGuvenlikGeregi(Object e);

  /// lib/screens/profile_screen.dart:1430
  ///
  /// In tr, this message translates to:
  /// **'Kavaid - Arapça Sözlük Uygulaması'**
  String get kavaidArapcaSozlukUygulamasi;

  /// lib/screens/profile_screen.dart:1449
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım sırasında bir hata oluştu'**
  String get paylasimSirasindaBirHataOlustu;

  /// lib/screens/profile_screen.dart:1476
  ///
  /// In tr, this message translates to:
  /// **'İnternet Gerekli'**
  String get internetGerekli;

  /// lib/screens/profile_screen.dart:1477
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için internet bağlantısı gereklidir.'**
  String get buIslemIcinInternetBaglantisi;

  /// lib/screens/profile_screen.dart:1518
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Adı Değiştir'**
  String get kullaniciAdiDegistir;

  /// lib/screens/profile_screen.dart:1524
  ///
  /// In tr, this message translates to:
  /// **'Mevcut: {currentUsername}'**
  String mevcutCurrentusername(Object currentUsername);

  /// lib/screens/profile_screen.dart:1549
  ///
  /// In tr, this message translates to:
  /// **'Yeni Kullanıcı Adı'**
  String get yeniKullaniciAdi;

  /// lib/screens/profile_screen.dart:1550
  ///
  /// In tr, this message translates to:
  /// **'kullaniciadi123 (küçük harf, boşluksuz)'**
  String get kullaniciadi123KucukHarfBosluksuz;

  /// lib/screens/profile_screen.dart:1564
  ///
  /// In tr, this message translates to:
  /// **'• En az 3 karakter\n• Sadece küçük harf, rakam ve Türkçe karakterler'**
  String get enAz3KarakterSadece;

  /// lib/screens/profile_screen.dart:1586
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı en az 3 karakter olmalı'**
  String get kullaniciAdiEnAz3;

  /// lib/screens/profile_screen.dart:1593
  ///
  /// In tr, this message translates to:
  /// **'Sadece küçük harf, rakam ve Türkçe karakterler'**
  String get sadeceKucukHarfRakamVe;

  /// lib/screens/profile_screen.dart:1611
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adınız \"{newUsername}\" olarak güncellendi!'**
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername);

  /// lib/screens/profile_screen.dart:1619
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcı adı kullanılamıyor veya zaten alınmış'**
  String get buKullaniciAdiKullanilamiyorVeya;

  /// lib/screens/profile_screen.dart:1640
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get degistir;

  /// lib/screens/subscription_screen.dart:54
  ///
  /// In tr, this message translates to:
  /// **'🎉 Premium üyelik aktif!'**
  String get premiumUyelikAktif;

  /// lib/screens/subscription_screen.dart:72
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı açılamadı: {e}'**
  String baglantiAcilamadiE(Object e);

  /// lib/screens/subscription_screen.dart:87
  ///
  /// In tr, this message translates to:
  /// **'Premium satın almak için lütfen önce giriş yapın.'**
  String get premiumSatinAlmakIcinLutfen;

  /// lib/screens/subscription_screen.dart:135
  ///
  /// In tr, this message translates to:
  /// **'Hata: {e}'**
  String hataE(Object e);

  /// lib/screens/subscription_screen.dart:221
  ///
  /// In tr, this message translates to:
  /// **'Kavaid Premium'**
  String get kavaidPremium;

  /// lib/screens/subscription_screen.dart:229
  ///
  /// In tr, this message translates to:
  /// **'AI Asistan\'a sınırsız erişim'**
  String get aiAsistanASinirsizErisim;

  /// lib/screens/subscription_screen.dart:231
  ///
  /// In tr, this message translates to:
  /// **'Çeviriye sınırsız erişim'**
  String get ceviriyeSinirsizErisim;

  /// lib/screens/subscription_screen.dart:233
  ///
  /// In tr, this message translates to:
  /// **'5.500+ fiilin 24 sığa emsile çekimlerini aç'**
  String get m5500Fiilin24Siga;

  /// lib/screens/subscription_screen.dart:235
  ///
  /// In tr, this message translates to:
  /// **'Öğren kısmındaki tüm materyallere erişim'**
  String get ogrenKismindakiTumMateryallereErisim;

  /// lib/screens/subscription_screen.dart:237
  ///
  /// In tr, this message translates to:
  /// **'Kuran Sözlüğüne Sınırsız Erişim'**
  String get kuranSozluguneSinirsizErisim;

  /// lib/screens/subscription_screen.dart:239
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız kelime kartı ve liste oluştur'**
  String get sinirsizKelimeKartiVeListe;

  /// lib/screens/subscription_screen.dart:241
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız deneyim'**
  String get reklamsizDeneyim;

  /// lib/screens/subscription_screen.dart:248
  ///
  /// In tr, this message translates to:
  /// **'Aylık Abonelik'**
  String get aylikAbonelik;

  /// lib/screens/subscription_screen.dart:249
  ///
  /// In tr, this message translates to:
  /// **'1 Ay boyunca sınırsız erişim'**
  String get m1AyBoyuncaSinirsizErisim;

  /// lib/screens/subscription_screen.dart:256
  ///
  /// In tr, this message translates to:
  /// **'Yıllık Abonelik'**
  String get yillikAbonelik;

  /// lib/screens/subscription_screen.dart:258
  ///
  /// In tr, this message translates to:
  /// **'1 Yıl boyunca sınırsız erişim'**
  String get m1YilBoyuncaSinirsizErisim;

  /// lib/screens/subscription_screen.dart:259
  ///
  /// In tr, this message translates to:
  /// **'1 Yıl boyunca sınırsız erişim ({yearlyMonthlyCost})'**
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost);

  /// lib/screens/subscription_screen.dart:263
  ///
  /// In tr, this message translates to:
  /// **'%{yearlyDiscount} İNDİRİM'**
  String yearlydiscountIndirim(Object yearlyDiscount);

  /// lib/screens/subscription_screen.dart:289
  ///
  /// In tr, this message translates to:
  /// **'Aylık Abone Ol{buttonPriceText}'**
  String aylikAboneOlButtonpricetext(Object buttonPriceText);

  /// lib/screens/subscription_screen.dart:290
  ///
  /// In tr, this message translates to:
  /// **'Yıllık Abone Ol{buttonPriceText}'**
  String yillikAboneOlButtonpricetext(Object buttonPriceText);

  /// lib/screens/subscription_screen.dart:304
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Apple ID hesabınızdan tahsil edilir. Abonelik, dönem sonundan en az 24 saat önce iptal edilmediği sürece otomatik yenilenir. İstediğiniz zaman App Store Hesap Ayarları\'ndan iptal edebilirsiniz.'**
  String get odemeAppleIdHesabinizdanTahsil;

  /// lib/screens/subscription_screen.dart:305
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Google Play üzerinden tahsil edilir. Abonelik, dönem sonundan en az 24 saat önce iptal edilmediği sürece otomatik yenilenir. İstediğiniz zaman Google Play Hesap Ayarları\'ndan iptal edebilirsiniz.'**
  String get odemeGooglePlayUzerindenTahsil;

  /// lib/screens/subscription_screen.dart:335
  ///
  /// In tr, this message translates to:
  /// **'Satın Almaları Geri Yükle'**
  String get satinAlmalariGeriYukle;

  /// lib/screens/subscription_screen.dart:349
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları (EULA)'**
  String get kullanimKosullariEula;

  /// lib/screens/subscription_screen.dart:363
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get gizlilikPolitikasi;

  /// lib/screens/translation_screen.dart:474
  ///
  /// In tr, this message translates to:
  /// **'Metin girin'**
  String get metinGirin;

  /// lib/screens/translation_screen.dart:601
  ///
  /// In tr, this message translates to:
  /// **'Hareke aç'**
  String get harekeAc;

  /// lib/screens/translation_screen.dart:610
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get kopyala;

  /// lib/screens/translation_screen.dart:615
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı'**
  String get kopyalandi;

  /// lib/screens/translation_screen.dart:711
  ///
  /// In tr, this message translates to:
  /// **'Çevir'**
  String get cevir;

  /// lib/screens/translation_screen.dart:747
  ///
  /// In tr, this message translates to:
  /// **'Şu Dile Çevir'**
  String get suDileCevir;

  /// lib/screens/translation_screen.dart:868
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a geçin'**
  String get premiumAGecin;

  /// lib/screens/translation_screen.dart:880
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla çeviri yapabilmek için Premium\'a geçin.'**
  String get dahaFazlaCeviriYapabilmekIcin;

  /// lib/screens/translation_screen.dart:943
  ///
  /// In tr, this message translates to:
  /// **'Lütfen önce kayıt olup giriş yapın.'**
  String get lutfenOnceKayitOlupGiris;

  /// lib/screens/translation_screen.dart:1072
  ///
  /// In tr, this message translates to:
  /// **'Diller'**
  String get diller;

  /// lib/screens/translation_screen.dart:1073
  ///
  /// In tr, this message translates to:
  /// **'Lehçeler'**
  String get lehceler;

  /// lib/services/ai_chat_service.dart:138
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı gerekiyor.'**
  String get internetBaglantisiGerekiyor;

  /// lib/services/ai_chat_service.dart:165
  ///
  /// In tr, this message translates to:
  /// **'AI asistan şu an kullanılamıyor.'**
  String get aiAsistanSuAnKullanilamiyor;

  /// lib/services/ai_chat_service.dart:167
  ///
  /// In tr, this message translates to:
  /// **'Yanıt gelmedi.'**
  String get yanitGelmedi;

  /// lib/services/ai_chat_service.dart:170
  ///
  /// In tr, this message translates to:
  /// **'Şu anda cevap alınamadı.'**
  String get suAndaCevapAlinamadi;

  /// lib/services/ai_teacher_service.dart:52
  ///
  /// In tr, this message translates to:
  /// **'Hazir.'**
  String get hazir;

  /// lib/services/ai_teacher_service.dart:60
  ///
  /// In tr, this message translates to:
  /// **'AI Kelime Asistani icin internet baglantisi gerekiyor.'**
  String get aiKelimeAsistaniIcinInternet;

  /// lib/services/ai_teacher_service.dart:67
  ///
  /// In tr, this message translates to:
  /// **'Bugunku ucretsiz AI Kelime Asistani hakkin doldu.'**
  String get bugunkuUcretsizAiKelimeAsistani;

  /// lib/services/ai_teacher_service.dart:87
  ///
  /// In tr, this message translates to:
  /// **'AI Öğretmen API anahtarı geçersiz. Firebase gemini_api değerini kontrol edin.'**
  String get aiOgretmenApiAnahtariGecersiz;

  /// lib/services/ai_teacher_service.dart:93
  ///
  /// In tr, this message translates to:
  /// **'AI Kelime Asistani su anda yanit veremedi. Tekrar deneyin.'**
  String get aiKelimeAsistaniSuAnda;

  /// lib/services/app_startup_service.dart:40
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get yukleniyor;

  /// lib/services/app_startup_service.dart:79
  ///
  /// In tr, this message translates to:
  /// **'Sözlük hazır.'**
  String get sozlukHazir;

  /// lib/services/app_startup_service.dart:90
  ///
  /// In tr, this message translates to:
  /// **'Sözlük yüklenemedi.'**
  String get sozlukYuklenemedi;

  /// lib/services/app_startup_service.dart:100
  ///
  /// In tr, this message translates to:
  /// **'Ekran hazırlanıyor...'**
  String get ekranHazirlaniyor;

  /// lib/services/app_startup_service.dart:140
  ///
  /// In tr, this message translates to:
  /// **'Sözlük kontrol ediliyor...'**
  String get sozlukKontrolEdiliyor;

  /// lib/services/app_startup_service.dart:160
  ///
  /// In tr, this message translates to:
  /// **'Sözlük ayarlanıyor...'**
  String get sozlukAyarlaniyor;

  /// lib/services/app_startup_service.dart:200
  ///
  /// In tr, this message translates to:
  /// **'Arama hazırlanıyor...'**
  String get aramaHazirlaniyor;

  /// lib/services/app_startup_service.dart:222
  ///
  /// In tr, this message translates to:
  /// **'Arama hazır.'**
  String get aramaHazir;

  /// lib/services/connectivity_service.dart:107
  ///
  /// In tr, this message translates to:
  /// **'İnternet Bağlantısı Yok'**
  String get internetBaglantisiYok;

  /// lib/services/connectivity_service.dart:121
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı kullanabilmek için internet bağlantısına ihtiyacınız var. Lütfen WiFi veya mobil veri bağlantınızı kontrol edin.'**
  String get uygulamayiKullanabilmekIcinInternetBaglantisina;

  /// lib/services/database_initialization_service.dart:36
  ///
  /// In tr, this message translates to:
  /// **'Sözlük hazırlanıyor...'**
  String get sozlukHazirlaniyor;

  /// lib/services/database_initialization_service.dart:45
  ///
  /// In tr, this message translates to:
  /// **'Sözlük hazır. {existingCount} kelime mevcut.'**
  String sozlukHazirExistingcountKelimeMevcut(int existingCount);

  /// lib/services/database_initialization_service.dart:54
  ///
  /// In tr, this message translates to:
  /// **'Kelimeler yükleniyor...'**
  String get kelimelerYukleniyor;

  /// lib/services/database_initialization_service.dart:77
  ///
  /// In tr, this message translates to:
  /// **'Sözlük hazır!'**
  String get sozlukHazir2;

  /// lib/services/database_initialization_service.dart:89
  ///
  /// In tr, this message translates to:
  /// **'Mevcut veritabanı kullanılacak.'**
  String get mevcutVeritabaniKullanilacak;

  /// lib/services/database_initialization_service.dart:104
  ///
  /// In tr, this message translates to:
  /// **'Hiç güncellenmedi'**
  String get hicGuncellenmedi;

  /// lib/services/one_time_purchase_service.dart:67
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapmalısınız.'**
  String get girisYapmalisiniz;

  /// lib/services/one_time_purchase_service.dart:90
  ///
  /// In tr, this message translates to:
  /// **'Paket bulunamadı (Lifetime).'**
  String get paketBulunamadiLifetime;

  /// lib/services/one_time_purchase_service.dart:95
  ///
  /// In tr, this message translates to:
  /// **'Hata oluştu'**
  String get hataOlustu;

  /// lib/services/one_time_purchase_service.dart:98
  ///
  /// In tr, this message translates to:
  /// **'Beklenmedik hata: {e}'**
  String beklenmedikHataE(Object e);

  /// lib/services/purchase_manager.dart:262
  ///
  /// In tr, this message translates to:
  /// **'RevenueCat baslatilamadi: {e}'**
  String revenuecatBaslatilamadiE(Object e);

  /// lib/services/purchase_manager.dart:1121
  ///
  /// In tr, this message translates to:
  /// **'Satın almak için önce giriş yapın.'**
  String get satinAlmakIcinOnceGiris;

  /// lib/services/purchase_manager.dart:1137
  ///
  /// In tr, this message translates to:
  /// **'Satın alma hatası: {p1}'**
  String satinAlmaHatasiP1(Object p1);

  /// lib/services/purchase_manager.dart:1215
  ///
  /// In tr, this message translates to:
  /// **'Abonelik paketi yüklenemedi. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.'**
  String get abonelikPaketiYuklenemediLutfenInternet;

  /// lib/services/purchase_manager.dart:1273
  ///
  /// In tr, this message translates to:
  /// **'Satın alma kontrolü için internet bağlantısı gerekiyor.'**
  String get satinAlmaKontroluIcinInternet;

  /// lib/services/purchase_manager.dart:1288
  ///
  /// In tr, this message translates to:
  /// **'Aktif bir abonelik bulunamadi.'**
  String get aktifBirAbonelikBulunamadi;

  /// lib/services/purchase_manager.dart:1292
  ///
  /// In tr, this message translates to:
  /// **'Restore hatasi: {e}'**
  String restoreHatasiE(Object e);

  /// lib/services/translation_notifier.dart:137
  ///
  /// In tr, this message translates to:
  /// **'Hata oluştu.'**
  String get hataOlustu2;

  /// lib/services/translation_quota_service.dart:85
  ///
  /// In tr, this message translates to:
  /// **'Çeviri için giriş yapman gerekiyor.'**
  String get ceviriIcinGirisYapmanGerekiyor;

  /// lib/services/translation_quota_service.dart:93
  ///
  /// In tr, this message translates to:
  /// **'Premium kullanıcı.'**
  String get premiumKullanici;

  /// lib/services/translation_quota_service.dart:142
  ///
  /// In tr, this message translates to:
  /// **'Çeviri hakkı kullanıldı.'**
  String get ceviriHakkiKullanildi;

  /// lib/services/translation_quota_service.dart:150
  ///
  /// In tr, this message translates to:
  /// **'Çeviri hakkı kontrol edilemedi. Bağlantını kontrol et.'**
  String get ceviriHakkiKontrolEdilemediBaglantini;

  /// lib/widgets/ai_chat_sheet.dart:167
  ///
  /// In tr, this message translates to:
  /// **'Yeni sohbet'**
  String get yeniSohbet;

  /// lib/widgets/ai_chat_sheet.dart:168
  ///
  /// In tr, this message translates to:
  /// **'Bu sohbetin geçmişi silinsin mi?'**
  String get buSohbetinGecmisiSilinsinMi;

  /// lib/widgets/ai_chat_sheet.dart:263
  ///
  /// In tr, this message translates to:
  /// **'AI Asistan'**
  String get aiAsistan;

  /// lib/widgets/ai_chat_sheet.dart:288
  ///
  /// In tr, this message translates to:
  /// **' hakkında'**
  String get hakkinda;

  /// lib/widgets/ai_chat_sheet.dart:300
  ///
  /// In tr, this message translates to:
  /// **'Arapça sözlük yardımcın'**
  String get arapcaSozlukYardimcin;

  /// lib/widgets/ai_chat_sheet.dart:332
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü ücretsiz soru hakkın'**
  String get bugunkuUcretsizSoruHakkin;

  /// lib/widgets/ai_chat_sheet.dart:458
  ///
  /// In tr, this message translates to:
  /// **'Arapçasını dinle'**
  String get arapcasiniDinle;

  /// lib/widgets/ai_chat_sheet.dart:529
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get tekrarDene2;

  /// lib/widgets/ai_chat_sheet.dart:577
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü {freeDailyLimit} ücretsiz soru hakkın bitti'**
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit);

  /// lib/widgets/ai_chat_sheet.dart:590
  ///
  /// In tr, this message translates to:
  /// **'Hakların yarın yenilenir. Premium ile sınırsız sorabilirsin.'**
  String get haklarinYarinYenilenirPremiumIle;

  /// lib/widgets/ai_chat_sheet.dart:608
  ///
  /// In tr, this message translates to:
  /// **'Premium\'a geç'**
  String get premiumAGec2;

  /// lib/widgets/ai_chat_sheet.dart:619
  ///
  /// In tr, this message translates to:
  /// **'Kısaca anlat'**
  String get kisacaAnlat;

  /// lib/widgets/ai_chat_sheet.dart:620
  ///
  /// In tr, this message translates to:
  /// **'3 örnek cümle ver'**
  String get m3OrnekCumleVer;

  /// lib/widgets/ai_chat_sheet.dart:621
  ///
  /// In tr, this message translates to:
  /// **'Benzer kelimelerden farkı ne?'**
  String get benzerKelimelerdenFarkiNe;

  /// lib/widgets/ai_chat_sheet.dart:622
  ///
  /// In tr, this message translates to:
  /// **'Okunuşunu Latin harfleriyle yaz'**
  String get okunusunuLatinHarfleriyleYaz;

  /// lib/widgets/ai_chat_sheet.dart:625
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş zaman nasıl kurulur?'**
  String get gecmisZamanNasilKurulur;

  /// lib/widgets/ai_chat_sheet.dart:626
  ///
  /// In tr, this message translates to:
  /// **'Harf-i cer nedir?'**
  String get harfICerNedir;

  /// lib/widgets/ai_chat_sheet.dart:627
  ///
  /// In tr, this message translates to:
  /// **'İsim cümlesi nasıl kurulur?'**
  String get isimCumlesiNasilKurulur;

  /// lib/widgets/ai_chat_sheet.dart:628
  ///
  /// In tr, this message translates to:
  /// **'En sık kullanılan 10 fiil'**
  String get enSikKullanilan10Fiil;

  /// lib/widgets/ai_chat_sheet.dart:650
  ///
  /// In tr, this message translates to:
  /// **'Son sorduklarım'**
  String get sonSorduklarim;

  /// lib/widgets/ai_chat_sheet.dart:658
  ///
  /// In tr, this message translates to:
  /// **'Örnek sorular'**
  String get ornekSorular;

  /// lib/widgets/ai_chat_sheet.dart:705
  ///
  /// In tr, this message translates to:
  /// **'Bu kelime hakkında kısa ve net cevap alırsın.'**
  String get buKelimeHakkindaKisaVe;

  /// lib/widgets/ai_chat_sheet.dart:728
  ///
  /// In tr, this message translates to:
  /// **'Arapça sorunu yaz'**
  String get arapcaSorunuYaz;

  /// lib/widgets/ai_chat_sheet.dart:738
  ///
  /// In tr, this message translates to:
  /// **'Kısa ve net cevap verir, bilmediğini uydurmaz.'**
  String get kisaVeNetCevapVerir;

  /// lib/widgets/ai_chat_sheet.dart:815
  ///
  /// In tr, this message translates to:
  /// **'Örnek ver'**
  String get ornekVer;

  /// lib/widgets/ai_chat_sheet.dart:816
  ///
  /// In tr, this message translates to:
  /// **'Daha basit anlat'**
  String get dahaBasitAnlat;

  /// lib/widgets/ai_chat_sheet.dart:817
  ///
  /// In tr, this message translates to:
  /// **'Derinleş'**
  String get derinles;

  /// lib/widgets/ai_chat_sheet.dart:818
  ///
  /// In tr, this message translates to:
  /// **'Çekimini göster'**
  String get cekiminiGoster;

  /// lib/widgets/ai_chat_sheet.dart:887
  ///
  /// In tr, this message translates to:
  /// **'AI Asistan\'a sor...'**
  String get aiAsistanASor;

  /// lib/widgets/ai_intro_banner.dart:58
  ///
  /// In tr, this message translates to:
  /// **'Yeni: AI Asistan'**
  String get yeniAiAsistan;

  /// lib/widgets/ai_intro_banner.dart:67
  ///
  /// In tr, this message translates to:
  /// **'Kelime kartındaki ikonların en solundaki bu simgeye dokun: anlamını, benzerlerinden farkını ve örnek cümleleri sor.'**
  String get kelimeKartindakiIkonlarinEnSolundaki;

  /// lib/widgets/ai_intro_banner.dart:85
  ///
  /// In tr, this message translates to:
  /// **'Anladım'**
  String get anladim;

  /// lib/widgets/ai_teacher_sheet.dart:64
  ///
  /// In tr, this message translates to:
  /// **'Bu kelimeyle seviye seviye daha fazla örnek ver: kolay, orta, günlük kullanım, gramer odaklı ve soru cümlesi.'**
  String get buKelimeyleSeviyeSeviyeDaha;

  /// lib/widgets/ai_teacher_sheet.dart:105
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü ücretsiz AI Kelime Asistanı hakkın doldu. Devam etmek için premiuma geçebilirsin.'**
  String get bugunkuUcretsizAiKelimeAsistani2;

  /// lib/widgets/ai_teacher_sheet.dart:116
  ///
  /// In tr, this message translates to:
  /// **'Şu anda cevap alınamadı. İnternet bağlantını kontrol edip tekrar deneyebilirsin.'**
  String get suAndaCevapAlinamadiInternet;

  /// lib/widgets/ai_teacher_sheet.dart:194
  ///
  /// In tr, this message translates to:
  /// **'AI Kelime Asistanı'**
  String get aiKelimeAsistani;

  /// lib/widgets/ai_teacher_sheet.dart:195
  ///
  /// In tr, this message translates to:
  /// **'AI Kelime Asistanı · {remaining} ücretsiz hak'**
  String aiKelimeAsistaniRemainingUcretsiz(int remaining);

  /// lib/widgets/ai_teacher_sheet.dart:233
  ///
  /// In tr, this message translates to:
  /// **'AI Kelime Asistanı hazırlanamadı.'**
  String get aiKelimeAsistaniHazirlanamadi;

  /// lib/widgets/ai_teacher_sheet.dart:244
  ///
  /// In tr, this message translates to:
  /// **'Premium’a geç'**
  String get premiumAGec3;

  /// lib/widgets/ai_teacher_sheet.dart:263
  ///
  /// In tr, this message translates to:
  /// **'Kısaca Anlat'**
  String get kisacaAnlat2;

  /// lib/widgets/ai_teacher_sheet.dart:268
  ///
  /// In tr, this message translates to:
  /// **'Gramer Notları'**
  String get gramerNotlari;

  /// lib/widgets/ai_teacher_sheet.dart:273
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Notları'**
  String get kullanimNotlari;

  /// lib/widgets/ai_teacher_sheet.dart:324
  ///
  /// In tr, this message translates to:
  /// **'Bu kelime nerede kullanılır?'**
  String get buKelimeNeredeKullanilir;

  /// lib/widgets/ai_teacher_sheet.dart:326
  ///
  /// In tr, this message translates to:
  /// **'5 yeni örnek ver'**
  String get m5YeniOrnekVer;

  /// lib/widgets/ai_teacher_sheet.dart:327
  ///
  /// In tr, this message translates to:
  /// **'Kolay cümlelerle anlat'**
  String get kolayCumlelerleAnlat;

  /// lib/widgets/ai_teacher_sheet.dart:330
  ///
  /// In tr, this message translates to:
  /// **'Çekimle örnek ver'**
  String get cekimleOrnekVer;

  /// lib/widgets/ai_teacher_sheet.dart:333
  ///
  /// In tr, this message translates to:
  /// **'Harf-i cer farkını anlat'**
  String get harfICerFarkiniAnlat;

  /// lib/widgets/ai_teacher_sheet.dart:445
  ///
  /// In tr, this message translates to:
  /// **'Örnekle Öğren'**
  String get ornekleOgren;

  /// lib/widgets/ai_teacher_sheet.dart:497
  ///
  /// In tr, this message translates to:
  /// **'Mini Alıştırma'**
  String get miniAlistirma;

  /// lib/widgets/ai_teacher_sheet.dart:593
  ///
  /// In tr, this message translates to:
  /// **'Hazır Sorular'**
  String get hazirSorular;

  /// lib/widgets/ai_teacher_sheet.dart:648
  ///
  /// In tr, this message translates to:
  /// **'Sor'**
  String get sor;

  /// lib/widgets/ai_teacher_sheet.dart:688
  ///
  /// In tr, this message translates to:
  /// **'Bu kelimeyle ilgili soru sor'**
  String get buKelimeyleIlgiliSoruSor;

  /// lib/widgets/app_intro_screen.dart:73
  ///
  /// In tr, this message translates to:
  /// **'Arapça–Türkçe sözlük'**
  String get arapcaTurkceSozluk;

  /// lib/widgets/app_intro_screen.dart:74
  ///
  /// In tr, this message translates to:
  /// **'Arapça ya da Türkçe yaz, her şey tek kartta.'**
  String get arapcaYaDaTurkceYaz;

  /// lib/widgets/app_intro_screen.dart:78
  ///
  /// In tr, this message translates to:
  /// **'Sesle ya da Arapça klavyeyle ara'**
  String get sesleYaDaArapcaKlavyeyle;

  /// lib/widgets/app_intro_screen.dart:79
  ///
  /// In tr, this message translates to:
  /// **'Kök, çoğul ve örnek cümleler'**
  String get kokCogulVeOrnekCumleler;

  /// lib/widgets/app_intro_screen.dart:83
  ///
  /// In tr, this message translates to:
  /// **'Fiil kartı'**
  String get fiilKarti;

  /// lib/widgets/app_intro_screen.dart:84
  ///
  /// In tr, this message translates to:
  /// **'Fiillerin çekimleri kartın içinde.'**
  String get fiillerinCekimleriKartinIcinde;

  /// lib/widgets/app_intro_screen.dart:88
  ///
  /// In tr, this message translates to:
  /// **'Mazi, müzari, mastar ve emir'**
  String get maziMuzariMastarVeEmir;

  /// lib/widgets/app_intro_screen.dart:89
  ///
  /// In tr, this message translates to:
  /// **'Tüm çekimler için emsileye geç'**
  String get tumCekimlerIcinEmsileyeGec;

  /// lib/widgets/app_intro_screen.dart:94
  ///
  /// In tr, this message translates to:
  /// **'Kelime kartının en solundaki simgeye dokun.'**
  String get kelimeKartininEnSolundakiSimgeye;

  /// lib/widgets/app_intro_screen.dart:99
  ///
  /// In tr, this message translates to:
  /// **'Sorunu yaz ya da hazır soru seç'**
  String get sorunuYazYaDaHazir;

  /// lib/widgets/app_intro_screen.dart:100
  ///
  /// In tr, this message translates to:
  /// **'Kısa ve net cevap'**
  String get kisaVeNetCevap;

  /// lib/widgets/app_intro_screen.dart:105
  ///
  /// In tr, this message translates to:
  /// **'5.500’den fazla fiilin çekim tablosu.'**
  String get m5500DenFazlaFiilin;

  /// lib/widgets/app_intro_screen.dart:109
  ///
  /// In tr, this message translates to:
  /// **'Fiile dokun, kartı açılsın'**
  String get fiileDokunKartiAcilsin;

  /// lib/widgets/app_intro_screen.dart:110
  ///
  /// In tr, this message translates to:
  /// **'Anlamları ve 24 sığa çekimi'**
  String get anlamlariVe24SigaCekimi;

  /// lib/widgets/app_intro_screen.dart:114
  ///
  /// In tr, this message translates to:
  /// **'Kur’an sözlüğü'**
  String get kurAnSozlugu;

  /// lib/widgets/app_intro_screen.dart:115
  ///
  /// In tr, this message translates to:
  /// **'Kur’an kelimelerini ayetleriyle öğren.'**
  String get kurAnKelimeleriniAyetleriyleOgren;

  /// lib/widgets/app_intro_screen.dart:119
  ///
  /// In tr, this message translates to:
  /// **'Kelime ve Kur’ani anlamları'**
  String get kelimeVeKurAniAnlamlari;

  /// lib/widgets/app_intro_screen.dart:120
  ///
  /// In tr, this message translates to:
  /// **'Geçtiği ayet ve meali'**
  String get gectigiAyetVeMeali;

  /// lib/widgets/app_intro_screen.dart:124
  ///
  /// In tr, this message translates to:
  /// **'Lehçe çeviri'**
  String get lehceCeviri;

  /// lib/widgets/app_intro_screen.dart:125
  ///
  /// In tr, this message translates to:
  /// **'Türkçe yaz ya da konuş, 17 lehçeye çevir.'**
  String get turkceYazYaDaKonus;

  /// lib/widgets/app_intro_screen.dart:129
  ///
  /// In tr, this message translates to:
  /// **'Karşılığı ve okunuşu'**
  String get karsiligiVeOkunusu;

  /// lib/widgets/app_intro_screen.dart:130
  ///
  /// In tr, this message translates to:
  /// **'Lehçeyi seç ya da sesle söyle'**
  String get lehceyiSecYaDaSesle;

  /// lib/widgets/app_intro_screen.dart:134
  ///
  /// In tr, this message translates to:
  /// **'Listeler ve kartlar'**
  String get listelerVeKartlar;

  /// lib/widgets/app_intro_screen.dart:135
  ///
  /// In tr, this message translates to:
  /// **'Kaydettiğin her şey tek yerde.'**
  String get kaydettiginHerSeyTekYerde;

  /// lib/widgets/app_intro_screen.dart:139
  ///
  /// In tr, this message translates to:
  /// **'Liste ya da kartlarla tekrar et'**
  String get listeYaDaKartlarlaTekrar;

  /// lib/widgets/app_intro_screen.dart:140
  ///
  /// In tr, this message translates to:
  /// **'Sözlük, Kur’an ve emsile kayıtları'**
  String get sozlukKurAnVeEmsile;

  /// lib/widgets/app_intro_screen.dart:145
  ///
  /// In tr, this message translates to:
  /// **'A1’den C1’e resimli Arapça hikâyeler.'**
  String get a1DenC1EResimli;

  /// lib/widgets/app_intro_screen.dart:149
  ///
  /// In tr, this message translates to:
  /// **'Kelimeye dokun, anlamı çıksın'**
  String get kelimeyeDokunAnlamiCiksin;

  /// lib/widgets/app_intro_screen.dart:150
  ///
  /// In tr, this message translates to:
  /// **'Metni sesli dinle'**
  String get metniSesliDinle;

  /// lib/widgets/app_intro_screen.dart:256
  ///
  /// In tr, this message translates to:
  /// **'Geç'**
  String get gec;

  /// lib/widgets/app_intro_screen.dart:395
  ///
  /// In tr, this message translates to:
  /// **'YENİ'**
  String get yeni;

  /// lib/widgets/arabic_keyboard.dart:202
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get ara;

  /// lib/widgets/arabic_keyboard.dart:216
  ///
  /// In tr, this message translates to:
  /// **'Boşluk'**
  String get bosluk;

  /// lib/widgets/email_auth_sheet.dart:153
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız yoksa önce kayıt olun'**
  String get hesabinizYoksaOnceKayitOlun;

  /// lib/widgets/email_auth_sheet.dart:168
  ///
  /// In tr, this message translates to:
  /// **'Kayıt tamamlandıktan sonra giriş yapmanız gerekir.'**
  String get kayitTamamlandiktanSonraGirisYapmaniz;

  /// lib/widgets/email_auth_sheet.dart:213
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get ePosta;

  /// lib/widgets/email_auth_sheet.dart:215
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz e-posta adresi'**
  String get gecersizEPostaAdresi;

  /// lib/widgets/email_auth_sheet.dart:222
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get sifre;

  /// lib/widgets/email_auth_sheet.dart:224
  ///
  /// In tr, this message translates to:
  /// **'Şifre gerekli'**
  String get sifreGerekli;

  /// lib/widgets/email_auth_sheet.dart:242
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum'**
  String get sifremiUnuttum;

  /// lib/widgets/email_auth_sheet.dart:253
  ///
  /// In tr, this message translates to:
  /// **'Şifre Tekrar'**
  String get sifreTekrar;

  /// lib/widgets/email_auth_sheet.dart:257
  ///
  /// In tr, this message translates to:
  /// **'Şifre tekrarı gerekli'**
  String get sifreTekrariGerekli;

  /// lib/widgets/email_auth_sheet.dart:258
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get sifrelerEslesmiyor;

  /// lib/widgets/email_auth_sheet.dart:306
  ///
  /// In tr, this message translates to:
  /// **'Şifreni sıfırlamak için önce e-posta adresini yaz.'**
  String get sifreniSifirlamakIcinOnceE;

  /// lib/widgets/email_auth_sheet.dart:324
  ///
  /// In tr, this message translates to:
  /// **'{email} adresine kayıtlı bir hesap varsa şifre sıfırlama bağlantısı gönderildi. Gelen kutunu ve gereksiz (spam) klasörünü kontrol et.'**
  String emailAdresineKayitliBirHesap(Object email);

  /// lib/widgets/email_auth_sheet.dart:330
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e‑posta adresi giriniz.'**
  String get gecerliBirEPostaAdresi;

  /// lib/widgets/email_auth_sheet.dart:331
  ///
  /// In tr, this message translates to:
  /// **'Bu e‑posta ile kayıt bulunamadı.'**
  String get buEPostaIleKayit;

  /// lib/widgets/email_auth_sheet.dart:333
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme yapıldı. Bir süre sonra tekrar deneyin.'**
  String get cokFazlaDenemeYapildiBir;

  /// lib/widgets/email_auth_sheet.dart:335
  ///
  /// In tr, this message translates to:
  /// **'Ağ hatası. İnternet bağlantınızı kontrol edin.'**
  String get agHatasiInternetBaglantiniziKontrol;

  /// lib/widgets/email_auth_sheet.dart:336
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı gönderilemedi. Lütfen tekrar deneyin.'**
  String get baglantiGonderilemediLutfenTekrarDeneyin;

  /// lib/widgets/email_auth_sheet.dart:390
  ///
  /// In tr, this message translates to:
  /// **'🎉 Hoş geldiniz! Hesabınız başarıyla oluşturuldu.'**
  String get hosGeldinizHesabinizBasariylaOlusturuldu;

  /// lib/widgets/email_auth_sheet.dart:400
  ///
  /// In tr, this message translates to:
  /// **'İşlem başarısız. Lütfen tekrar deneyin.'**
  String get islemBasarisizLutfenTekrarDeneyin;

  /// lib/widgets/email_auth_sheet.dart:406
  ///
  /// In tr, this message translates to:
  /// **'E‑posta veya şifre hatalı. Lütfen kontrol ediniz.'**
  String get ePostaVeyaSifreHatali;

  /// lib/widgets/email_auth_sheet.dart:410
  ///
  /// In tr, this message translates to:
  /// **'Şifre hatalı.'**
  String get sifreHatali;

  /// lib/widgets/email_auth_sheet.dart:412
  ///
  /// In tr, this message translates to:
  /// **'Bu e‑posta zaten kayıtlı.'**
  String get buEPostaZatenKayitli;

  /// lib/widgets/email_auth_sheet.dart:414
  ///
  /// In tr, this message translates to:
  /// **'Şifre çok zayıf. Daha güçlü bir şifre seçin.'**
  String get sifreCokZayifDahaGuclu;

  /// lib/widgets/email_auth_sheet.dart:416
  ///
  /// In tr, this message translates to:
  /// **'Bu giriş yöntemi proje için etkin değil.'**
  String get buGirisYontemiProjeIcin;

  /// lib/widgets/emsile_bottom_sheet.dart:130
  ///
  /// In tr, this message translates to:
  /// **'O (dişil)'**
  String get oDisil;

  /// lib/widgets/emsile_bottom_sheet.dart:131
  ///
  /// In tr, this message translates to:
  /// **'İkisi'**
  String get ikisi;

  /// lib/widgets/emsile_bottom_sheet.dart:132
  ///
  /// In tr, this message translates to:
  /// **'İkisi (eril)'**
  String get ikisiEril;

  /// lib/widgets/emsile_bottom_sheet.dart:133
  ///
  /// In tr, this message translates to:
  /// **'İkisi (dişil)'**
  String get ikisiDisil;

  /// lib/widgets/emsile_bottom_sheet.dart:135
  ///
  /// In tr, this message translates to:
  /// **'Onlar (dişil)'**
  String get onlarDisil;

  /// lib/widgets/emsile_bottom_sheet.dart:137
  ///
  /// In tr, this message translates to:
  /// **'Sen (dişil)'**
  String get senDisil;

  /// lib/widgets/emsile_bottom_sheet.dart:138
  ///
  /// In tr, this message translates to:
  /// **'İkiniz'**
  String get ikiniz;

  /// lib/widgets/emsile_bottom_sheet.dart:140
  ///
  /// In tr, this message translates to:
  /// **'Siz (dişil)'**
  String get sizDisil;

  /// lib/widgets/emsile_bottom_sheet.dart:147
  ///
  /// In tr, this message translates to:
  /// **'غَائِب (3. Şahıs)'**
  String get m3Sahis;

  /// lib/widgets/emsile_bottom_sheet.dart:148
  ///
  /// In tr, this message translates to:
  /// **'مُخَاطَب (2. Şahıs)'**
  String get m2Sahis;

  /// lib/widgets/emsile_bottom_sheet.dart:149
  ///
  /// In tr, this message translates to:
  /// **'مُتَكَلِّم (1. Şahıs)'**
  String get m1Sahis;

  /// lib/widgets/emsile_bottom_sheet.dart:204
  ///
  /// In tr, this message translates to:
  /// **'Müzari'**
  String get muzari;

  /// lib/widgets/emsile_bottom_sheet.dart:251
  ///
  /// In tr, this message translates to:
  /// **'Emsile Çekimleri'**
  String get emsileCekimleri;

  /// lib/widgets/emsile_bottom_sheet.dart:359
  ///
  /// In tr, this message translates to:
  /// **'Mazi (Geçmiş)'**
  String get maziGecmis;

  /// lib/widgets/emsile_bottom_sheet.dart:360
  ///
  /// In tr, this message translates to:
  /// **'Müzari (Geniş)'**
  String get muzariGenis;

  /// lib/widgets/emsile_bottom_sheet.dart:361
  ///
  /// In tr, this message translates to:
  /// **'Emir'**
  String get emir;

  /// lib/widgets/emsile_bottom_sheet.dart:389
  ///
  /// In tr, this message translates to:
  /// **'{tabTitle} çekimi bulunamadı'**
  String tabtitleCekimiBulunamadi(Object tabTitle);

  /// lib/widgets/emsile_bottom_sheet.dart:598
  ///
  /// In tr, this message translates to:
  /// **'Kök'**
  String get kok;

  /// lib/widgets/emsile_bottom_sheet.dart:603
  ///
  /// In tr, this message translates to:
  /// **'İsm-i Fail'**
  String get ismIFail;

  /// lib/widgets/emsile_bottom_sheet.dart:608
  ///
  /// In tr, this message translates to:
  /// **'İsm-i Mef\'ul'**
  String get ismIMefUl;

  /// lib/widgets/emsile_bottom_sheet.dart:611
  ///
  /// In tr, this message translates to:
  /// **'Fiil çekimleri • Kavaid Sözlük'**
  String get fiilCekimleriKavaidSozluk;

  /// lib/widgets/emsile_view.dart:169
  ///
  /// In tr, this message translates to:
  /// **'5.500\'den fazla fiilin 24 sığa Emsile-i Muhtelife çekimlerini öğrenin.'**
  String get m5500DenFazlaFiilin2;

  /// lib/widgets/emsile_view.dart:213
  ///
  /// In tr, this message translates to:
  /// **'Tüm fiilleri aç'**
  String get tumFiilleriAc;

  /// lib/widgets/emsile_view.dart:259
  ///
  /// In tr, this message translates to:
  /// **'Daha Fazla Fiil Yükle'**
  String get dahaFazlaFiilYukle;

  /// lib/widgets/emsile_view.dart:285
  ///
  /// In tr, this message translates to:
  /// **'Aranan kelime bulunamadı'**
  String get arananKelimeBulunamadi;

  /// lib/widgets/emsile_view.dart:705
  ///
  /// In tr, this message translates to:
  /// **'Fiil-i Mâzi — Muttasıl Çekimler'**
  String get fiilIMaziMuttasilCekimler;

  /// lib/widgets/emsile_view.dart:706
  ///
  /// In tr, this message translates to:
  /// **'Fiil-i Muzâri — Muttasıl Çekimler'**
  String get fiilIMuzariMuttasilCekimler;

  /// lib/widgets/emsile_view.dart:707
  ///
  /// In tr, this message translates to:
  /// **'Emr-i Hâzır — Muttasıl Çekimler'**
  String get emrIHazirMuttasilCekimler;

  /// lib/widgets/emsile_view.dart:736
  ///
  /// In tr, this message translates to:
  /// **'Çekimler'**
  String get cekimler;

  /// lib/widgets/emsile_view.dart:889
  ///
  /// In tr, this message translates to:
  /// **'Premium İçerik'**
  String get premiumIcerik;

  /// lib/widgets/emsile_view.dart:899
  ///
  /// In tr, this message translates to:
  /// **'5.500\'den fazla fiilin 24 sığa Emsile-i Muhtelife çekimlerini açın'**
  String get m5500DenFazlaFiilin3;

  /// lib/widgets/emsile_view.dart:934
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz Fiiller'**
  String get ucretsizFiiller;

  /// lib/widgets/save_button.dart:157
  ///
  /// In tr, this message translates to:
  /// **'Listeye Ekle'**
  String get listeyeEkle;

  /// lib/widgets/search_result_card.dart:442
  ///
  /// In tr, this message translates to:
  /// **'AI asistanı kullanmak için lütfen giriş yapın.'**
  String get aiAsistaniKullanmakIcinLutfen;

  /// lib/widgets/search_result_card.dart:510
  ///
  /// In tr, this message translates to:
  /// **'Bu kelimeyle seviyeme uygun 5 yeni örnek ver: kolaydan zora doğru.'**
  String get buKelimeyleSeviyemeUygun5;

  /// lib/widgets/search_result_card.dart:590
  ///
  /// In tr, this message translates to:
  /// **'Tüm Fiil Çekimleri'**
  String get tumFiilCekimleri;

  /// lib/widgets/search_result_card_parts.dart:156
  ///
  /// In tr, this message translates to:
  /// **'kök {root}'**
  String kokRoot(Object root);

  /// lib/widgets/search_result_card_parts.dart:386
  ///
  /// In tr, this message translates to:
  /// **'Çoğul'**
  String get cogul;

  /// lib/widgets/search_result_card_parts.dart:527
  ///
  /// In tr, this message translates to:
  /// **'Örnek Cümleler'**
  String get ornekCumleler;

  /// lib/widgets/search_result_card_parts.dart:587
  ///
  /// In tr, this message translates to:
  /// **'Cümleyi dinle'**
  String get cumleyiDinle;

  /// lib/widgets/search_result_card_parts.dart:634
  ///
  /// In tr, this message translates to:
  /// **'AI Asistan\'a sor'**
  String get aiAsistanASor2;

  /// lib/widgets/search_result_card_parts.dart:635
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla örnek'**
  String get dahaFazlaOrnek;

  /// lib/widgets/word_card.dart:103
  ///
  /// In tr, this message translates to:
  /// **'Kelime kaydetmek için önce giriş yapın'**
  String get kelimeKaydetmekIcinOnceGiris;

  /// lib/widgets/wow_guru_mini_game.dart:237
  ///
  /// In tr, this message translates to:
  /// **'Oyna'**
  String get oyna;

  /// Fiil çekim etiketi: geçmiş zaman (mazi). Kelime kartında kısa etiket.
  ///
  /// In tr, this message translates to:
  /// **'Mazi'**
  String get verbFormPast;

  /// Fiil çekim etiketi: şimdiki/geniş zaman (müzari). Kelime kartında kısa etiket.
  ///
  /// In tr, this message translates to:
  /// **'Müzari'**
  String get verbFormPresent;

  /// Fiil çekim etiketi: mastar (masdar). Kelime kartında kısa etiket.
  ///
  /// In tr, this message translates to:
  /// **'Mastar'**
  String get verbFormInfinitive;

  /// Fiil çekim etiketi: emir kipi. Kelime kartında kısa etiket.
  ///
  /// In tr, this message translates to:
  /// **'Emir'**
  String get verbFormImperative;

  /// Emsile tablosunda Arapça zamirin karşılığı (şahıs etiketi).
  ///
  /// In tr, this message translates to:
  /// **'O (eril)'**
  String get zamirOEril;

  /// Emsile tablosunda Arapça zamirin karşılığı (şahıs etiketi).
  ///
  /// In tr, this message translates to:
  /// **'Onlar (eril)'**
  String get zamirOnlarEril;

  /// Emsile tablosunda Arapça zamirin karşılığı (şahıs etiketi).
  ///
  /// In tr, this message translates to:
  /// **'Sen (eril)'**
  String get zamirSenEril;

  /// Emsile tablosunda Arapça zamirin karşılığı (şahıs etiketi).
  ///
  /// In tr, this message translates to:
  /// **'Siz (eril)'**
  String get zamirSizEril;

  /// Emsile tablosunda Arapça zamirin karşılığı (şahıs etiketi).
  ///
  /// In tr, this message translates to:
  /// **'Ben'**
  String get zamirBen;

  /// Emsile tablosunda Arapça zamirin karşılığı (şahıs etiketi).
  ///
  /// In tr, this message translates to:
  /// **'Biz'**
  String get zamirBiz;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get dialectTr;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get dialectEn;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Almanca'**
  String get dialectDe;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Fransızca'**
  String get dialectFr;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Rusça'**
  String get dialectRu;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'İspanyolca'**
  String get dialectEs;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'İtalyanca'**
  String get dialectIt;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Portekizce'**
  String get dialectPt;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Hollandaca'**
  String get dialectNl;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Farsça'**
  String get dialectFa;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Urduca'**
  String get dialectUr;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Endonezce'**
  String get dialectId;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Standart Arapça'**
  String get dialectArStandard;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Suriye Arapçası'**
  String get dialectArSyrian;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Lübnan Arapçası'**
  String get dialectArLebanese;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Ürdün Arapçası'**
  String get dialectArJordanian;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Filistin Arapçası'**
  String get dialectArPalestinian;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Mısır Arapçası'**
  String get dialectArEgyptian;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Irak Arapçası'**
  String get dialectArIraqi;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Sudan Arapçası'**
  String get dialectArSudanese;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Suudi Arapçası'**
  String get dialectArSaudi;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Emirlik Arapçası'**
  String get dialectArEmirati;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Kuveyt Arapçası'**
  String get dialectArKuwaiti;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Katar Arapçası'**
  String get dialectArQatari;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Umman Arapçası'**
  String get dialectArOmani;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Yemen Arapçası'**
  String get dialectArYemeni;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Fas Arapçası'**
  String get dialectArMoroccan;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Cezayir Arapçası'**
  String get dialectArAlgerian;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Tunus Arapçası'**
  String get dialectArTunisian;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Libya Arapçası'**
  String get dialectArLibyan;

  /// Profil ekranında arayüz dilini seçme satırının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dili'**
  String get appLanguage;

  /// Kelime kartındaki küçük tür rozeti: noun. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get typeNoun;

  /// Kelime kartındaki küçük tür rozeti: proper noun. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Özel isim'**
  String get typeProperNoun;

  /// Kelime kartındaki küçük tür rozeti: verb. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Fiil'**
  String get typeVerb;

  /// Kelime kartındaki küçük tür rozeti: verb, past tense (māḍī). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Mazi fiil'**
  String get typeVerbPast;

  /// Kelime kartındaki küçük tür rozeti: verb, present tense (muḍāriʿ). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Muzari fiil'**
  String get typeVerbPresent;

  /// Kelime kartındaki küçük tür rozeti: verb, imperative (amr). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Emir fiil'**
  String get typeVerbImperative;

  /// Kelime kartındaki küçük tür rozeti: verb, prohibitive (lā + jussive). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Nehiy fiil'**
  String get typeVerbProhibitive;

  /// Kelime kartındaki küçük tür rozeti: verb, past passive. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Meçhul mazi'**
  String get typeVerbPastPassive;

  /// Kelime kartındaki küçük tür rozeti: verb, present passive. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Meçhul muzari'**
  String get typeVerbPresentPassive;

  /// Kelime kartındaki küçük tür rozeti: defective verb (kāna and its sisters). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Nakıs fiil'**
  String get typeVerbDefective;

  /// Kelime kartındaki küçük tür rozeti: verbal noun (maṣdar). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Mastar'**
  String get typeMasdar;

  /// Kelime kartındaki küçük tür rozeti: active participle (ism fāʿil). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsm-i fail'**
  String get typeActiveParticiple;

  /// Kelime kartındaki küçük tür rozeti: passive participle (ism mafʿūl). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsm-i mef\'ul'**
  String get typePassiveParticiple;

  /// Kelime kartındaki küçük tür rozeti: elative / comparative (ism tafḍīl). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsm-i tafdil'**
  String get typeElative;

  /// Kelime kartındaki küçük tür rozeti: adjective. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Sıfat'**
  String get typeAdjective;

  /// Kelime kartındaki küçük tür rozeti: adverb. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Zarf'**
  String get typeAdverb;

  /// Kelime kartındaki küçük tür rozeti: circumstantial accusative (ḥāl). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Hal'**
  String get typeHal;

  /// Kelime kartındaki küçük tür rozeti: pronoun. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Zamir'**
  String get typePronoun;

  /// Kelime kartındaki küçük tür rozeti: demonstrative. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'İşaret ismi'**
  String get typeDemonstrative;

  /// Kelime kartındaki küçük tür rozeti: relative pronoun. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsm-i mevsul'**
  String get typeRelative;

  /// Kelime kartındaki küçük tür rozeti: interrogative particle. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Soru edatı'**
  String get typeInterrogative;

  /// Kelime kartındaki küçük tür rozeti: preposition (ḥarf jarr). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Harf-i cer'**
  String get typePreposition;

  /// Kelime kartındaki küçük tür rozeti: particle. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Edat'**
  String get typeParticle;

  /// Kelime kartındaki küçük tür rozeti: number. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Sayı'**
  String get typeNumber;

  /// Kelime kartındaki küçük tür rozeti: phrase / construct (iḍāfa). Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Tamlama'**
  String get typePhrase;

  /// Kelime kartındaki küçük tür rozeti: expression. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'İfade'**
  String get typeExpression;

  /// Kelime kartındaki küçük tür rozeti: idiom. Çok kısa olmalı.
  ///
  /// In tr, this message translates to:
  /// **'Deyim'**
  String get typeIdiom;

  /// Emsile tablosunda 24 sığadan 1. sığanın kısa adı: الماضي — past tense. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Fiil-i Mâzi'**
  String get siga01;

  /// Emsile tablosunda 24 sığadan 2. sığanın kısa adı: المضارع — present tense. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Fiil-i Muzâri'**
  String get siga02;

  /// Emsile tablosunda 24 sığadan 3. sığanın kısa adı: المصدر — verbal noun. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Masdar'**
  String get siga03;

  /// Emsile tablosunda 24 sığadan 4. sığanın kısa adı: اسم الفاعل — active participle. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsm-i Fâil'**
  String get siga04;

  /// Emsile tablosunda 24 sığadan 5. sığanın kısa adı: اسم المفعول — passive participle. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsm-i Mef’ûl'**
  String get siga05;

  /// Emsile tablosunda 24 sığadan 6. sığanın kısa adı: الجحد المطلق (لم يفعل) — negated past. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'C. Mutlak'**
  String get siga06;

  /// Emsile tablosunda 24 sığadan 7. sığanın kısa adı: الجحد المستغرق (لمّا يفعل) — "not yet". Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'C. Müstağrak'**
  String get siga07;

  /// Emsile tablosunda 24 sığadan 8. sığanın kısa adı: نفي الحال (ما يفعل) — negated present. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Nefy-i Hâl'**
  String get siga08;

  /// Emsile tablosunda 24 sığadan 9. sığanın kısa adı: نفي الاستقبال (لا يفعل) — negated future. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Nef. İstik.'**
  String get siga09;

  /// Emsile tablosunda 24 sığadan 10. sığanın kısa adı: تأكيد نفي الاستقبال (لن يفعل) — emphatic negated future. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Tek. N. İstik.'**
  String get siga10;

  /// Emsile tablosunda 24 sığadan 11. sığanın kısa adı: أمر الغائب (ليفعل) — 3rd-person command. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Emr-i Gâib'**
  String get siga11;

  /// Emsile tablosunda 24 sığadan 12. sığanın kısa adı: نهي الغائب (لا يفعل) — 3rd-person prohibition. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Nehy-i Gâib'**
  String get siga12;

  /// Emsile tablosunda 24 sığadan 13. sığanın kısa adı: أمر الحاضر (افعل) — imperative. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Emr-i Hâzır'**
  String get siga13;

  /// Emsile tablosunda 24 sığadan 14. sığanın kısa adı: نهي الحاضر (لا تفعل) — prohibition. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Nehy-i Hâzır'**
  String get siga14;

  /// Emsile tablosunda 24 sığadan 15. sığanın kısa adı: اسم الزمان والمكان — noun of time/place. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Zaman/Mekân'**
  String get siga15;

  /// Emsile tablosunda 24 sığadan 16. sığanın kısa adı: اسم الآلة — noun of instrument. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsm-i Âlet'**
  String get siga16;

  /// Emsile tablosunda 24 sığadan 17. sığanın kısa adı: اسم المرة — noun of once. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Bina-i Merre'**
  String get siga17;

  /// Emsile tablosunda 24 sığadan 18. sığanın kısa adı: اسم الهيئة — noun of manner. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Bina-i Nev\'î'**
  String get siga18;

  /// Emsile tablosunda 24 sığadan 19. sığanın kısa adı: التصغير — diminutive. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsm-i Tasğîr'**
  String get siga19;

  /// Emsile tablosunda 24 sığadan 20. sığanın kısa adı: الاسم المنسوب — relative adjective (nisba). Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsm-i Mensûb'**
  String get siga20;

  /// Emsile tablosunda 24 sığadan 21. sığanın kısa adı: صيغة المبالغة — intensive active participle. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Müb. İ. Fâil'**
  String get siga21;

  /// Emsile tablosunda 24 sığadan 22. sığanın kısa adı: اسم التفضيل — elative. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'İsm-i Tafdîl'**
  String get siga22;

  /// Emsile tablosunda 24 sığadan 23. sığanın kısa adı: التعجب الأول (ما أفعله) — exclamation 1. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Taaccüb 1'**
  String get siga23;

  /// Emsile tablosunda 24 sığadan 24. sığanın kısa adı: التعجب الثاني (أفعل به) — exclamation 2. Kartın başlık şeridine sığmalı.
  ///
  /// In tr, this message translates to:
  /// **'Taaccüb 2'**
  String get siga24;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Malayca'**
  String get dialectMs;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Bengalce'**
  String get dialectBn;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Özbekçe'**
  String get dialectUz;

  /// Çeviri ekranında dil/lehçe adı (dil seçici listesi).
  ///
  /// In tr, this message translates to:
  /// **'Azerice'**
  String get dialectAz;

  /// Arapça kelime kartında harf-i cerli (edatlı) kullanımlar bölümünün kısa başlığı; Arapçada "مع حروف الجر".
  ///
  /// In tr, this message translates to:
  /// **'Harf-i cerle'**
  String get prepositionsLabel;

  /// Arapça kelime kartında tanım ve örneklerde harekeyi açıp kapatan düğme; Arapçada "التشكيل".
  ///
  /// In tr, this message translates to:
  /// **'Hareke'**
  String get tashkeelToggle;

  /// Profildeki hareke ayarının açıklaması (yalnız Arapça anlam dilinde görünür).
  ///
  /// In tr, this message translates to:
  /// **'Tanım ve örneklerde harekeleri göster'**
  String get tashkeelSettingHint;

  /// Arama sonuçlarında aynı kökten gelen kelimelerin bölüm başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Kök eşleşme'**
  String get rootMatches;

  /// Profildeki sözlük (anlam) dili ayarının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Sözlük dili'**
  String get dictionaryLanguage;

  /// Sözlük dili ayarının açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Kelime anlamlarının dili'**
  String get dictionaryLanguageHint;

  /// Sözlük dili listesinde Arapça seçeneğinin altındaki açıklama.
  ///
  /// In tr, this message translates to:
  /// **'Arapça–Arapça sözlük'**
  String get arabicArabicDictionary;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'az',
    'bn',
    'de',
    'en',
    'fr',
    'id',
    'ms',
    'ru',
    'tr',
    'ur',
    'uz',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'az':
      return AppLocalizationsAz();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'ms':
      return AppLocalizationsMs();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
