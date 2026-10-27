// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get kavaidSozluk => 'Kavaid Lüğət';

  @override
  String get markaAdi => 'Kavaid';

  @override
  String get tanitimDevam => 'Davam et';

  @override
  String get tanitimBasla => 'Başla';

  @override
  String get tekrarDene => 'Yenidən cəhd et';

  @override
  String get kavaidArapcaSozluk => 'Kavaid - Ərəb dili lüğəti';

  @override
  String get sozluk => 'Lüğət';

  @override
  String get ceviri => 'Tərcümə';

  @override
  String get ogren => 'Öyrən';

  @override
  String get profil => 'Profil';

  @override
  String get kelimeBulunamadi => 'Söz tapılmadı';

  @override
  String get baglantiAcilamadi => 'Bağlantı açılmadı';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'Təbriklər! 1 aylıq Premium hesabınıza əlavə edildi 🌟';

  @override
  String get gecersizVeyaKullanilmisKod =>
      'Kod keçərsizdir və ya artıq istifadə olunub.';

  @override
  String get buKoduDahaOnceKullandiniz =>
      'Bu kodu daha əvvəl istifadə etmisiniz.';

  @override
  String get buKodunSuresiDolmus => 'Bu kodun vaxtı bitib.';

  @override
  String get buKodunKullanimLimitiDolmus => 'Bu kodun istifadə limiti dolub.';

  @override
  String get lutfenOnceGirisYapin => 'Zəhmət olmasa, əvvəlcə giriş edin.';

  @override
  String get m1AyUcretsizPremiumKazan => '1 ay pulsuz Premium qazan';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'Tətbiq haqqında fikirlərinizi qeyd olunan tviti alıntılamaqla Twitter-də (X) paylaşın və 1 ay pulsuz Premium qazanın!';

  @override
  String get nasilKatilirim => 'Necə qoşulum?';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'Tətbiq ilə bağlı fikirlərinizi qeyd olunan tviti alıntılamaqla Twitter-də (X) paylaşın.';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'Paylaşımınızı Twitter-də @ebubekr53 hesabına birbaşa mesaj (DM) olaraq göndərin və kodunuzu alın.';

  @override
  String get koduAsagiyaGirin => 'Kodu aşağıya daxil edin.';

  @override
  String get tweetiAlintila => 'Tviti alıntıla';

  @override
  String get promosyonKodu => 'Promosyon kodu';

  @override
  String get kullan => 'İstifadə et';

  @override
  String get dahaFazlaOzellik => 'Daha çox funksiya';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'Daha çox siyahı yaratmaq üçün\nPremium-a yüksəldin';

  @override
  String get kapat => 'Bağla';

  @override
  String get premiumAl => 'Premium al';

  @override
  String get yeniListe => 'Yeni siyahı';

  @override
  String get listeAdi => 'Siyahı adı';

  @override
  String get iptal => 'Ləğv et';

  @override
  String get olustur => 'Yarat';

  @override
  String get listeyiYenidenAdlandir => 'Siyahının adını dəyiş';

  @override
  String get kaydet => 'Yadda saxla';

  @override
  String get kelimeListelerim => 'Söz siyahılarım';

  @override
  String get yeniListeOlustur => 'Yeni siyahı yarat';

  @override
  String get henuzListeYok => 'Hələlik siyahı yoxdur';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'Sözlərinizi nizamlamaq üçün\nbir siyahı yaradın';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCount söz',
      one: '1 söz',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'Adını dəyiş';

  @override
  String get sil => 'Sil';

  @override
  String get listeyiSil => 'Siyahını sil';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return '\"$name\" silinsin? Siyahıdakı bütün sözlər də silinəcək.';
  }

  @override
  String get buListedeHenuzKelimeYok => 'Bu siyahıda hələ söz yoxdur';

  @override
  String get liste => 'Siyahı';

  @override
  String get kart => 'Kart';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'Daha çox söz kartı üçün Premium-a keçin';

  @override
  String get premiumAYukselt => 'Premium-a keç';

  @override
  String get dinle => 'Dinlə';

  @override
  String get oyun => 'Oyun';

  @override
  String get kullanimSiniriDoldu => 'İstifadə limiti doldu';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'Quran lüğətini limitsiz istifadə etmək üçün zəhmət olmasa giriş edin və Premium-a keçin.';

  @override
  String get tamam => 'Tamam';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'Bütün kitablar açıldı və reklamlar ləğv edildi.';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'Bütün kitablar açıldı. Reklamları daimi bağlamaq üçün zəhmət olmasa giriş edin.';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'Gizli kod tətbiq edilə bilmədi: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'Lüğət yenilənir... Zəhmət olmasa gözləyin.';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    return 'Lüğət uğurla yeniləndi! $p1 söz yükləndi.';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu =>
      'Lüğət yenilənərkən xəta baş verdi!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'Məlumat bazasının yenilənmə xətası: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris =>
      'Zəhmət olmasa, əvvəlcə qeydiyyatdan keçin və ya giriş edin.';

  @override
  String get kelimeAra => 'Söz axtar';

  @override
  String get emsile => 'Təsrif';

  @override
  String get kuranSozlugu => 'Quran Lüğəti';

  @override
  String get kavaidIDegerlendir => 'Kavaid-i dəyərləndirin';

  @override
  String get gorusunBizimIcinCokDegerli => 'Rəyiniz bizim üçün çox dəyərlidir.';

  @override
  String get kuranSozluguYukleniyor => 'Quran lüğəti yüklənir...';

  @override
  String get kuranSozlugundeAraniyor => 'Quran lüğətində axtarılır...';

  @override
  String get araniyor => 'Axtarılır...';

  @override
  String get kuranSozlugundeBulunamadi => 'Quran lüğətində tapılmadı';

  @override
  String get farkliBirKelimeVeyaKok =>
      'Fərqli bir söz və ya kök ilə axtarmağı sınayın';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'Quran lüğətindən daha çox istifadə etmək üçün Premium-a keçin.';

  @override
  String get kurAnIKerimSozlugu => 'Qurani-Kərim Lüğəti';

  @override
  String get kurAnDaGecenTum =>
      'Quranda keçən bütün sözlərin istifadəsini və Qurani mənalarını ayələrlə birlikdə öyrənin.';

  @override
  String get kurAnDakiBenzersizTum => 'Qurandakı bütün unikal sözlər.';

  @override
  String get kuraniAnlamlar => 'Qurani Mənalar';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'Sözlərin Quran ayələrində qazandığı mənaları öyrənin.';

  @override
  String get kurAnAyetleri => 'Quran Ayələri';

  @override
  String get onBinlerceKurAnAyeti =>
      'On minlərlə Quran ayəsi ilə sözlərin Qurandakı istifadəsini görün.';

  @override
  String get kavaidArapcaSozluk2 => 'Kavaid Ərəb dili lüğəti';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'Yeni nəsil süni intellekt dəstəkli ilk ərəb dili lüğəti';

  @override
  String get premiumAGec => 'Premium-a keç';

  @override
  String get sinirsizErisim => 'Limitsiz giriş';

  @override
  String get profilResmiGuncellendi => '✅ Profil şəkli yeniləndi!';

  @override
  String get birHataOlustu => 'Xəta baş verdi';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'Firebase Storage konfiqurasiya edilməyib. Zəhmət olmasa, Firebase Console-dan Storage-ı aktivləşdirin.';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'İcazə xətası. Storage qaydalarını yoxlayın.';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'İcazə xətası. Zəhmət olmasa, giriş edin.';

  @override
  String get internetBaglantisiHatasi => 'İnternet bağlantısı xətası.';

  @override
  String get detay => 'Ətraflı';

  @override
  String get hataDetayi => 'Xəta təfərrüatı';

  @override
  String get kullanici => 'İstifadəçi';

  @override
  String get kurucu => 'QURUCU';

  @override
  String get moderator => 'MODERATOR';

  @override
  String get emailYok => 'E-poçt yoxdur';

  @override
  String get cikisYapilsinMi => 'Çıxış edilsin?';

  @override
  String get oturumunuzKapatilacak => 'Hesabınızdan çıxış ediləcək.';

  @override
  String get cikis => 'Çıxış';

  @override
  String get aboneligiYonet => 'Abunəliyi idarə et';

  @override
  String get satinAlmalarKontrolEdiliyor => 'Satınalmalar yoxlanılır...';

  @override
  String get geriYukle => 'Geri yüklə';

  @override
  String get girisYapinVeyaKayitOlun => 'Giriş edin və ya qeydiyyatdan keçin';

  @override
  String get girisYap => 'Giriş et';

  @override
  String get kayitOl => 'Qeydiyyatdan keç';

  @override
  String get premiumUyesiniz => 'Premium üzvüsünüz';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'Limitsiz məzmun, reklamsız istifadə.';

  @override
  String get tumOzelliklereErisin => 'Bütün funksiyalara giriş əldə edin.';

  @override
  String get reklamsizKullanim => 'Reklamsız istifadə';

  @override
  String get uygulamayiPaylas => 'Tətbiqi paylaş';

  @override
  String get iletisim => 'Əlaqə';

  @override
  String get kavaidUygulamasiHakkinda => 'Kavaid Tətbiqi haqqında';

  @override
  String get hesabimiSil => 'Hesabımı sil';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'Hesabınızı və ona bağlı bütün məlumatları qalıcı olaraq silməyə əminsinizmi? Bu əməliyyat geri qaytarıla bilməz.';

  @override
  String get vazgec => 'Ləğv et';

  @override
  String get hesabinizBasariylaSilindi => 'Hesabınız uğurla silindi.';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'Hesab silinə bilmədi: $e. Təhlükəsizlik səbəbi ilə yenidən giriş etməyiniz lazım ola bilər.';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi =>
      'Kavaid - Ərəb dili lüğəti tətbiqi';

  @override
  String get paylasimSirasindaBirHataOlustu => 'Paylaşım zamanı xəta baş verdi';

  @override
  String get internetGerekli => 'İnternet tələb olunur';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'Bu əməliyyat üçün internet bağlantısı tələb olunur.';

  @override
  String get kullaniciAdiDegistir => 'İstifadəçi Adını Dəyiş';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'Hazırkı: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'Yeni istifadəçi adı';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'istifadeciadi123 (kiçik hərflə, boşluqsuz)';

  @override
  String get enAz3KarakterSadece =>
      '• Ən az 3 simvol\n• Yalnız kiçik hərflər, rəqəmlər və azərbaycan hərfləri';

  @override
  String get kullaniciAdiEnAz3 =>
      'İstifadəçi adı ən az 3 simvoldan ibarət olmalıdır';

  @override
  String get sadeceKucukHarfRakamVe =>
      'Yalnız kiçik hərflər, rəqəmlər və azərbaycan hərfləri';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'İstifadəçi adınız \"$newUsername\" olaraq yeniləndi!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'Bu istifadəçi adı yararsızdır və ya artıq götürülüb';

  @override
  String get degistir => 'Dəyiş';

  @override
  String get premiumUyelikAktif => '🎉 Premium üzvlük aktivdir!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'Bağlantı açılmadı: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'Premium almaq üçün əvvəlcə daxil olun.';

  @override
  String hataE(Object e) {
    return 'Xəta: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid Premium';

  @override
  String get aiAsistanASinirsizErisim => 'AI Köməkçiyə limitsiz giriş';

  @override
  String get ceviriyeSinirsizErisim => 'Tərcüməyə limitsiz giriş';

  @override
  String get m5500Fiilin24Siga => '5.500+ feilin 24 sığa təsrifini aç';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'Öyrən bölməsindəki bütün materiallara giriş';

  @override
  String get kuranSozluguneSinirsizErisim => 'Quran Lüğətinə Limitsiz Giriş';

  @override
  String get sinirsizKelimeKartiVeListe => 'Limitsiz söz kartı və siyahı yarat';

  @override
  String get reklamsizDeneyim => 'Reklamsız təcrübə';

  @override
  String get aylikAbonelik => 'Aylıq Abunəlik';

  @override
  String get m1AyBoyuncaSinirsizErisim => '1 Ay boyunca limitsiz giriş';

  @override
  String get yillikAbonelik => 'İllik Abunəlik';

  @override
  String get m1YilBoyuncaSinirsizErisim => '1 İl boyunca limitsiz giriş';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return '1 İl boyunca limitsiz giriş ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return '%$yearlyDiscount ENDİRİM';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Aylıq Abunə Ol$buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'İllik Abunə Ol$buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'Ödəniş Apple ID hesabınızdan tutulur. Abunəlik, dövrün sonuna ən azı 24 saat qalmış ləğv edilmədikdə avtomatik yenilənir. İstənilən vaxt App Store Hesab Ayarlarından ləğv edə bilərsiniz.';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'Ödəniş Google Play vasitəsilə tutulur. Abunəlik, dövrün sonuna ən azı 24 saat qalmış ləğv edilmədikdə avtomatik yenilənir. İstənilən vaxt Google Play Hesab Ayarlarından ləğv edə bilərsiniz.';

  @override
  String get satinAlmalariGeriYukle => 'Satınalmaları Bərpa Et';

  @override
  String get kullanimKosullariEula => 'İstifadə Şərtləri (EULA)';

  @override
  String get gizlilikPolitikasi => 'Məxfilik Siyasəti';

  @override
  String get metinGirin => 'Mətn daxil edin';

  @override
  String get harekeAc => 'Hərəkələri aç';

  @override
  String get kopyala => 'Kopyala';

  @override
  String get kopyalandi => 'Kopyalandı';

  @override
  String get cevir => 'Tərcümə et';

  @override
  String get suDileCevir => 'Bu Dilə Tərcümə Et';

  @override
  String get premiumAGecin => 'Premium-a keçin';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'Daha çox tərcümə etmək üçün Premium-a keçin.';

  @override
  String get lutfenOnceKayitOlupGiris =>
      'Zəhmət olmasa, əvvəlcə qeydiyyatdan keçib daxil olun.';

  @override
  String get diller => 'Dillər';

  @override
  String get lehceler => 'Ləhcələr';

  @override
  String get internetBaglantisiGerekiyor => 'İnternet bağlantısı lazımdır.';

  @override
  String get aiAsistanSuAnKullanilamiyor =>
      'AI köməkçi hazırda istifadə edilə bilmir.';

  @override
  String get yanitGelmedi => 'Cavab gəlmədi.';

  @override
  String get suAndaCevapAlinamadi => 'Hazırda cavab almaq mümkün olmadı.';

  @override
  String get hazir => 'Hazırdır.';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'AI Söz Köməkçisi üçün internet bağlantısı lazımdır.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'Bugünkü pulsuz AI Söz Köməkçisi limitiniz bitdi.';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'AI Müəllim API açarı keçərsizdir. Firebase gemini_api dəyərini yoxlayın.';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'AI Söz Köməkçisi hazırda cavab verə bilmədi. Yenidən cəhd edin.';

  @override
  String get yukleniyor => 'Yüklənir...';

  @override
  String get sozlukHazir => 'Lüğət hazırdır.';

  @override
  String get sozlukYuklenemedi => 'Lüğət yüklənə bilmədi.';

  @override
  String get ekranHazirlaniyor => 'Ekran hazırlanır...';

  @override
  String get sozlukKontrolEdiliyor => 'Lüğət yoxlanılır...';

  @override
  String get sozlukAyarlaniyor => 'Lüğət tənzimlənir...';

  @override
  String get aramaHazirlaniyor => 'Axtarış hazırlanır...';

  @override
  String get aramaHazir => 'Axtarış hazırdır.';

  @override
  String get internetBaglantisiYok => 'İnternet Bağlantısı Yoxdur';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'Tətbiqdən istifadə etmək üçün internet bağlantısına ehtiyacınız var. Zəhmət olmasa, WiFi və ya mobil data bağlantınızı yoxlayın.';

  @override
  String get sozlukHazirlaniyor => 'Lüğət hazırlanır...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    return 'Lüğət hazırdır. $existingCount söz mövcuddur.';
  }

  @override
  String get kelimelerYukleniyor => 'Sözlər yüklənir...';

  @override
  String get sozlukHazir2 => 'Lüğət hazırdır!';

  @override
  String get mevcutVeritabaniKullanilacak =>
      'Mövcud verilənlər bazası istifadə olunacaq.';

  @override
  String get hicGuncellenmedi => 'Heç yenilənməyib';

  @override
  String get girisYapmalisiniz => 'Daxil olmalısınız.';

  @override
  String get paketBulunamadiLifetime => 'Paket tapılmadı (Lifetime).';

  @override
  String get hataOlustu => 'Xəta baş verdi';

  @override
  String beklenmedikHataE(Object e) {
    return 'Gözlənilməz xəta: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'RevenueCat başladılmadı: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris => 'Satın almaq üçün əvvəlcə daxil olun.';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'Satın alma xətası: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'Abunəlik paketi yüklənmədi. Zəhmət olmasa, internet bağlantınızı yoxlayıb yenidən cəhd edin.';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'Satın alma yoxlanışı üçün internet bağlantısı lazımdır.';

  @override
  String get aktifBirAbonelikBulunamadi => 'Aktiv abunəlik tapılmadı.';

  @override
  String restoreHatasiE(Object e) {
    return 'Bərpa xətası: $e';
  }

  @override
  String get hataOlustu2 => 'Xəta baş verdi.';

  @override
  String get ceviriIcinGirisYapmanGerekiyor => 'Tərcümə üçün daxil olmalısan.';

  @override
  String get premiumKullanici => 'Premium istifadəçi.';

  @override
  String get ceviriHakkiKullanildi => 'Tərcümə hüququ istifadə olundu.';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'Tərcümə hüququ yoxlanıla bilmədi. Bağlantını yoxla.';

  @override
  String get yeniSohbet => 'Yeni söhbət';

  @override
  String get buSohbetinGecmisiSilinsinMi => 'Bu söhbətin tarixçəsi silinsinmi?';

  @override
  String get aiAsistan => 'AI Köməkçisi';

  @override
  String get hakkinda => ' haqqında';

  @override
  String get arapcaSozlukYardimcin => 'Ərəbcə lüğət köməkçin';

  @override
  String get bugunkuUcretsizSoruHakkin => 'Bugünkü pulsuz sual haqqın';

  @override
  String get arapcasiniDinle => 'Ərəbcəsini dinlə';

  @override
  String get tekrarDene2 => 'Yenidən cəhd et';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    return 'Bugünkü $freeDailyLimit pulsuz sual haqqın bitdi';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'Haqqların sabah yenilənəcək. Premium ilə limitsiz sual verə bilərsən.';

  @override
  String get premiumAGec2 => 'Premium-a keç';

  @override
  String get kisacaAnlat => 'Qısaca izah et';

  @override
  String get m3OrnekCumleVer => '3 nümunə cümlə ver';

  @override
  String get benzerKelimelerdenFarkiNe => 'Oxşar sözlərdən fərqi nədir?';

  @override
  String get okunusunuLatinHarfleriyleYaz => 'Oxunuşunu latın hərfləri ilə yaz';

  @override
  String get gecmisZamanNasilKurulur => 'Keçmiş zaman necə qurulur?';

  @override
  String get harfICerNedir => 'Harf-i cər nədir?';

  @override
  String get isimCumlesiNasilKurulur => 'İsim cümləsi necə qurulur?';

  @override
  String get enSikKullanilan10Fiil => 'Ən çox işlənən 10 fel';

  @override
  String get sonSorduklarim => 'Son soruşduqlarım';

  @override
  String get ornekSorular => 'Nümunə suallar';

  @override
  String get buKelimeHakkindaKisaVe =>
      'Bu söz haqqında qısa və dəqiq cavab alacaqsan.';

  @override
  String get arapcaSorunuYaz => 'Ərəbcə sualını yaz';

  @override
  String get kisaVeNetCevapVerir =>
      'Qısa və dəqiq cavab verər, bilmədiyini uydurmaz.';

  @override
  String get ornekVer => 'Nümunə ver';

  @override
  String get dahaBasitAnlat => 'Daha sadə izah et';

  @override
  String get derinles => 'Dərinləş';

  @override
  String get cekiminiGoster => 'Çəkimini (təsrifini) göstər';

  @override
  String get aiAsistanASor => 'AI Köməkçisinə sor...';

  @override
  String get yeniAiAsistan => 'Yeni: AI Köməkçisi';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'Söz kartındakı ikonların ən solundakı bu işarəyə toxun: mənasını, oxşarlarından fərqini və nümunə cümlələri soruş.';

  @override
  String get anladim => 'Anladım';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'Bu sözlə səviyyə-səviyyə daha çox nümunə ver: asan, orta, gündəlik istifadə, qrammatika yönümlü və sual cümləsi.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'Bugünkü pulsuz AI Söz Asistanı haqqın bitib. Davam etmək üçün Premium-a keçə bilərsən.';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'Hazırda cavab almaq mümkün olmadı. İnternet bağlantını yoxlayıb yenidən cəhd edə bilərsən.';

  @override
  String get aiKelimeAsistani => 'AI Söz Asistanı';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    return 'AI Söz Asistanı · $remaining pulsuz istifadə';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi => 'AI Söz Asistanı hazırlanmadı.';

  @override
  String get premiumAGec3 => 'Premium-a keç';

  @override
  String get kisacaAnlat2 => 'Qısaca izah et';

  @override
  String get gramerNotlari => 'Qrammatika Qeydləri';

  @override
  String get kullanimNotlari => 'İstifadə Qeydləri';

  @override
  String get buKelimeNeredeKullanilir => 'Bu söz harada istifadə olunur?';

  @override
  String get m5YeniOrnekVer => '5 yeni nümunə ver';

  @override
  String get kolayCumlelerleAnlat => 'Asan cümlələrlə izah et';

  @override
  String get cekimleOrnekVer => 'Çəkimlə nümunə ver';

  @override
  String get harfICerFarkiniAnlat => 'Harfi-cər fərqini izah et';

  @override
  String get ornekleOgren => 'Nümunə ilə öyrən';

  @override
  String get miniAlistirma => 'Mini Çalışma';

  @override
  String get hazirSorular => 'Hazır Suallar';

  @override
  String get sor => 'Soruş';

  @override
  String get buKelimeyleIlgiliSoruSor => 'Bu sözlə bağlı sual ver';

  @override
  String get arapcaTurkceSozluk => 'Ərəbcə–İngiliscə lüğət';

  @override
  String get arapcaYaDaTurkceYaz =>
      'Ərəbcə ya da İngiliscə yaz, hər şey bir kartda.';

  @override
  String get sesleYaDaArapcaKlavyeyle =>
      'Səslə və ya ərəb klaviaturası ilə axtar';

  @override
  String get kokCogulVeOrnekCumleler => 'Kök, cəm və nümunə cümlələr';

  @override
  String get fiilKarti => 'Feil kartı';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'Feillərin çəkimləri kartın içindədir.';

  @override
  String get maziMuzariMastarVeEmir => 'Mazi, müzari, məsdər və əmr';

  @override
  String get tumCekimlerIcinEmsileyeGec => 'Bütün çəkimlər üçün Emsilə-yə keç';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'Söz kartının ən solundakı işarəyə toxun.';

  @override
  String get sorunuYazYaDaHazir => 'Sualını yaz və ya hazır sual seç';

  @override
  String get kisaVeNetCevap => 'Qısa və aydın cavab';

  @override
  String get m5500DenFazlaFiilin => '5.500-dən çox feilin çəkim cədvəli.';

  @override
  String get fiileDokunKartiAcilsin => 'Feilə toxun, kartı açılsın';

  @override
  String get anlamlariVe24SigaCekimi => 'Mənaları və 24 sığa çəkimi';

  @override
  String get kurAnSozlugu => 'Qurani-Kərim lüğəti';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'Quran sözlərini ayələri ilə öyrən.';

  @override
  String get kelimeVeKurAniAnlamlari => 'Söz və Qurani mənaları';

  @override
  String get gectigiAyetVeMeali => 'Keçdiyi ayə və mənası';

  @override
  String get lehceCeviri => 'Dialekt tərcüməsi';

  @override
  String get turkceYazYaDaKonus =>
      'Azərbaycanca yaz və ya danış, 17 dialektə tərcümə et.';

  @override
  String get karsiligiVeOkunusu => 'Qarşılığı və oxunuşu';

  @override
  String get lehceyiSecYaDaSesle => 'Dialekti seç və ya səslə söylə';

  @override
  String get listelerVeKartlar => 'Siyahılar və kartlar';

  @override
  String get kaydettiginHerSeyTekYerde => 'Qeyd etdiyin hər şey bir yerdə.';

  @override
  String get listeYaDaKartlarlaTekrar => 'Siyahı və ya kartlarla təkrar et';

  @override
  String get sozlukKurAnVeEmsile => 'Lüğət, Quran və Emsilə qeydləri';

  @override
  String get a1DenC1EResimli => 'A1-dən C1-ə rəsmli Ərəb dili hekayələri.';

  @override
  String get kelimeyeDokunAnlamiCiksin => 'Sözə toxun, mənası çıxsın';

  @override
  String get metniSesliDinle => 'Mətni səslə dinlə';

  @override
  String get gec => 'Keç';

  @override
  String get yeni => 'YENİ';

  @override
  String get ara => 'Axtar';

  @override
  String get bosluk => 'Boşluq';

  @override
  String get hesabinizYoksaOnceKayitOlun =>
      'Hesabınız yoxdursa, əvvəlcə qeydiyyatdan keçin';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'Qeydiyyat tamamlandıqdan sonra giriş etməlisiniz.';

  @override
  String get ePosta => 'E-poçt';

  @override
  String get gecersizEPostaAdresi => 'Yanlış e-poçt ünvanı';

  @override
  String get sifre => 'Şifrə';

  @override
  String get sifreGerekli => 'Şifrə tələb olunur';

  @override
  String get sifremiUnuttum => 'Şifrəmi unutdum';

  @override
  String get sifreTekrar => 'Şifrə təkrarı';

  @override
  String get sifreTekrariGerekli => 'Şifrə təkrarı gərəklidir';

  @override
  String get sifrelerEslesmiyor => 'Şifrələr uyğun deyil';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'Şifrəni sıfırlamaq üçün əvvəlcə e-poçt ünvanını yaz.';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return '$email ünvanına qeydiyyatdan keçmiş bir hesab varsa, şifrə sıfırlama keçidi göndərildi. Gələn qutunu və spam qovluğunu yoxla.';
  }

  @override
  String get gecerliBirEPostaAdresi => 'Etibarlı bir e-poçt ünvanı daxil edin.';

  @override
  String get buEPostaIleKayit => 'Bu e-poçt ilə qeydiyyat tapılmadı.';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'Çox cəhd edildi. Bir müddət sonra yenidən cəhd edin.';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'Şəbəkə xətası. İnternet bağlantını yoxla.';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'Keçid göndərilə bilmədi. Zəhmət olmasa yenidən cəhd edin.';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 Xoş gəlmisiniz! Hesabınız uğurla yaradıldı.';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'Əməliyyat uğursuz oldu. Zəhmət olmasa yenidən cəhd edin.';

  @override
  String get ePostaVeyaSifreHatali =>
      'E-poçt və ya şifrə yanlışdır. Zəhmət olmasa yoxlayın.';

  @override
  String get sifreHatali => 'Şifrə yanlışdır.';

  @override
  String get buEPostaZatenKayitli => 'Bu e-poçt artıq qeydiyyatdan keçib.';

  @override
  String get sifreCokZayifDahaGuclu =>
      'Şifrə çox zəifdir. Daha güclü bir şifrə seçin.';

  @override
  String get buGirisYontemiProjeIcin =>
      'Bu giriş üsulu layihə üçün aktiv deyil.';

  @override
  String get oDisil => 'O (qadın cinsi)';

  @override
  String get ikisi => 'İkisi';

  @override
  String get ikisiEril => 'İkisi (kişi cinsi)';

  @override
  String get ikisiDisil => 'İkisi (dişi)';

  @override
  String get onlarDisil => 'Onlar (dişi)';

  @override
  String get senDisil => 'Sən (qadın cinsi)';

  @override
  String get ikiniz => 'İkiniz';

  @override
  String get sizDisil => 'Siz (qadın cinsi)';

  @override
  String get m3Sahis => 'غَائِب (3-cü şəxs)';

  @override
  String get m2Sahis => 'مُخَاطَب (2-ci şəxs)';

  @override
  String get m1Sahis => 'مُتَكَلِّم (1-ci şəxs)';

  @override
  String get muzari => 'Müzari';

  @override
  String get emsileCekimleri => 'Emsilə çəkilmələri';

  @override
  String get maziGecmis => 'Mazi (Keçmiş)';

  @override
  String get muzariGenis => 'Müzari (Geniş)';

  @override
  String get emir => 'Əmr';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return '$tabTitle çəkilməsi tapılmadı';
  }

  @override
  String get kok => 'Kök';

  @override
  String get ismIFail => 'İsm-i Fail';

  @override
  String get ismIMefUl => 'İsm-i Məful';

  @override
  String get fiilCekimleriKavaidSozluk => 'Feil çəkilmələri • Kavaid Lüğət';

  @override
  String get m5500DenFazlaFiilin2 =>
      '5.500-dən çox feilin 24 sığa Emsilə-i Müxtəlifə çəkilmələrini öyrənin.';

  @override
  String get tumFiilleriAc => 'Bütün feilləri aç';

  @override
  String get dahaFazlaFiilYukle => 'Daha çox feil yüklə';

  @override
  String get arananKelimeBulunamadi => 'Axtarılan söz tapılmadı';

  @override
  String get fiilIMaziMuttasilCekimler => 'Feil-i Mazi — Muttasıl çəkilmələri';

  @override
  String get fiilIMuzariMuttasilCekimler =>
      'Feil-i Müzari — Muttasıl çəkilmələri';

  @override
  String get emrIHazirMuttasilCekimler => 'Əmr-i Hazır — Muttasıl çəkilmələri';

  @override
  String get cekimler => 'Çəkilmələr';

  @override
  String get premiumIcerik => 'Premium Məzmun';

  @override
  String get m5500DenFazlaFiilin3 =>
      '5.500-dən çox feilin 24 sığa Emsilə-i Müxtəlifə çəkilmələrini açın';

  @override
  String get ucretsizFiiller => 'Ödənişsiz Feillər';

  @override
  String get listeyeEkle => 'Siyahıya əlavə et';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'AI köməkçisindən istifadə etmək üçün daxil olun.';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'Bu sözlə səviyyəmə uyğun 5 yeni nümunə ver: asandan çətinə doğru.';

  @override
  String get tumFiilCekimleri => 'Bütün Feil Çəkilmələri';

  @override
  String kokRoot(Object root) {
    return 'kök $root';
  }

  @override
  String get cogul => 'Cəm';

  @override
  String get ornekCumleler => 'Nümunə cümlələr';

  @override
  String get cumleyiDinle => 'Cümləni dinlə';

  @override
  String get aiAsistanASor2 => 'AI Köməkçisinə soruş';

  @override
  String get dahaFazlaOrnek => 'Daha çox nümunə';

  @override
  String get kelimeKaydetmekIcinOnceGiris =>
      'Sözü yadda saxlamaq üçün əvvəlcə daxil olun';

  @override
  String get oyna => 'Oyna';

  @override
  String get verbFormPast => 'Mazi';

  @override
  String get verbFormPresent => 'Müzari';

  @override
  String get verbFormInfinitive => 'Məsdər';

  @override
  String get verbFormImperative => 'Əmr';

  @override
  String get zamirOEril => 'O (kişi)';

  @override
  String get zamirOnlarEril => 'Onlar (kişi)';

  @override
  String get zamirSenEril => 'Sən (kişi)';

  @override
  String get zamirSizEril => 'Siz (kişi)';

  @override
  String get zamirBen => 'Mən';

  @override
  String get zamirBiz => 'Biz';

  @override
  String get dialectTr => 'Türk dili';

  @override
  String get dialectEn => 'İngilis dili';

  @override
  String get dialectDe => 'Alman dili';

  @override
  String get dialectFr => 'Fransız dili';

  @override
  String get dialectRu => 'Rus dili';

  @override
  String get dialectEs => 'İspan dili';

  @override
  String get dialectIt => 'İtalyan dili';

  @override
  String get dialectPt => 'Portuqal dili';

  @override
  String get dialectNl => 'Niderland dili';

  @override
  String get dialectFa => 'Fars dili';

  @override
  String get dialectUr => 'Urdu dili';

  @override
  String get dialectId => 'İndoneziya dili';

  @override
  String get dialectArStandard => 'Standart Ərəb dili';

  @override
  String get dialectArSyrian => 'Suriya ərəb dili';

  @override
  String get dialectArLebanese => 'Livan ərəb dili';

  @override
  String get dialectArJordanian => 'İordaniya ərəb dili';

  @override
  String get dialectArPalestinian => 'Fələstin ərəb dili';

  @override
  String get dialectArEgyptian => 'Misir ərəb dili';

  @override
  String get dialectArIraqi => 'İraq ərəb dili';

  @override
  String get dialectArSudanese => 'Sudan ərəb dili';

  @override
  String get dialectArSaudi => 'Səudiyyə ərəb dili';

  @override
  String get dialectArEmirati => 'Əmirlik ərəb dili';

  @override
  String get dialectArKuwaiti => 'Küveyt ərəb dili';

  @override
  String get dialectArQatari => 'Qətər ərəb dili';

  @override
  String get dialectArOmani => 'Oman ərəb dili';

  @override
  String get dialectArYemeni => 'Yəmən ərəb dili';

  @override
  String get dialectArMoroccan => 'Mərakeş ərəb dili';

  @override
  String get dialectArAlgerian => 'Əlcəzair ərəb dili';

  @override
  String get dialectArTunisian => 'Tunis ərəb dili';

  @override
  String get dialectArLibyan => 'Liviya ərəb dili';

  @override
  String get appLanguage => 'Tətbiq dili';

  @override
  String get typeNoun => 'İsim';

  @override
  String get typeProperNoun => 'Xüsusi isim';

  @override
  String get typeVerb => 'Feil';

  @override
  String get typeVerbPast => 'Mazi feil';

  @override
  String get typeVerbPresent => 'Muzari feil';

  @override
  String get typeVerbImperative => 'Əmr feili';

  @override
  String get typeVerbProhibitive => 'Nəhy feili';

  @override
  String get typeVerbPastPassive => 'Məchul mazi';

  @override
  String get typeVerbPresentPassive => 'Məchul muzari';

  @override
  String get typeVerbDefective => 'Naqis feil';

  @override
  String get typeMasdar => 'Məsdər';

  @override
  String get typeActiveParticiple => 'İsmi-fail';

  @override
  String get typePassiveParticiple => 'İsmi-məful';

  @override
  String get typeElative => 'İsmi-təfdil';

  @override
  String get typeAdjective => 'Sifət';

  @override
  String get typeAdverb => 'Zərf';

  @override
  String get typeHal => 'Hal';

  @override
  String get typePronoun => 'Əvəzlik';

  @override
  String get typeDemonstrative => 'İşarə ismi';

  @override
  String get typeRelative => 'İsmi-mövsul';

  @override
  String get typeInterrogative => 'Sual ədatı';

  @override
  String get typePreposition => 'Hərfi-cər';

  @override
  String get typeParticle => 'Ədat';

  @override
  String get typeNumber => 'Say';

  @override
  String get typePhrase => 'Tamlam';

  @override
  String get typeExpression => 'İfadə';

  @override
  String get typeIdiom => 'Deyim';

  @override
  String get siga01 => 'Mazi';

  @override
  String get siga02 => 'Müzari';

  @override
  String get siga03 => 'Məsdər';

  @override
  String get siga04 => 'İsmi-Fail';

  @override
  String get siga05 => 'İsmi-Mef\'ul';

  @override
  String get siga06 => 'C. Mütləq';

  @override
  String get siga07 => 'C. Müstağraq';

  @override
  String get siga08 => 'Nefyi-Hal';

  @override
  String get siga09 => 'Nefyi-İstiq.';

  @override
  String get siga10 => 'Tək. N. İstiq.';

  @override
  String get siga11 => 'Əmri-Qaib';

  @override
  String get siga12 => 'Nəhyi-Qaib';

  @override
  String get siga13 => 'Əmri-Hazır';

  @override
  String get siga14 => 'Nəhyi-Hazır';

  @override
  String get siga15 => 'Zaman/Məkan';

  @override
  String get siga16 => 'İsmi-Alət';

  @override
  String get siga17 => 'Binayi-Mərrə';

  @override
  String get siga18 => 'Binayi-Növ\'i';

  @override
  String get siga19 => 'İsmi-Təsğir';

  @override
  String get siga20 => 'İsmi-Mənsub';

  @override
  String get siga21 => 'Müb. İ. Fail';

  @override
  String get siga22 => 'İsmi-Təfdil';

  @override
  String get siga23 => 'Təəccüb 1';

  @override
  String get siga24 => 'Təəccüb 2';

  @override
  String get dialectMs => 'Malay';

  @override
  String get dialectBn => 'Benqal';

  @override
  String get dialectUz => 'Özbək';

  @override
  String get dialectAz => 'Azərbaycan';

  @override
  String get prepositionsLabel => 'Hərfi-cərlə';

  @override
  String get tashkeelToggle => 'Hərəkə';

  @override
  String get tashkeelSettingHint => 'Tərif və nümunələrdə hərəkələri göstər';

  @override
  String get rootMatches => 'Eyni kök';

  @override
  String get dictionaryLanguage => 'Lüğət dili';

  @override
  String get dictionaryLanguageHint => 'Söz mənalarının dili';

  @override
  String get arabicArabicDictionary => 'Ərəbcə–ərəbcə lüğət';
}
