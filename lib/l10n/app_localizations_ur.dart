// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get kavaidSozluk => 'Kavaid لغت';

  @override
  String get tekrarDene => 'دوبارہ کوشش کریں';

  @override
  String get kavaidArapcaSozluk => 'کواعد - عربی لغت';

  @override
  String get sozluk => 'لغت';

  @override
  String get ceviri => 'ترجمہ';

  @override
  String get ogren => 'سیکھیں';

  @override
  String get profil => 'پروفائل';

  @override
  String get kelimeBulunamadi => 'لفظ نہیں ملا';

  @override
  String get baglantiAcilamadi => 'لنک نہیں کھل سکا';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'مبارک ہو! 1 ماہ کا پریمیئم آپ کے اکاؤنٹ میں شامل کر دیا گیا ہے 🌟';

  @override
  String get gecersizVeyaKullanilmisKod => 'غلط یا پہلے سے استعمال شدہ کوڈ۔';

  @override
  String get buKoduDahaOnceKullandiniz =>
      'آپ یہ کوڈ پہلے ہی استعمال کر چکے ہیں۔';

  @override
  String get buKodunSuresiDolmus => 'اس کوڈ کی مدت ختم ہو چکی ہے۔';

  @override
  String get buKodunKullanimLimitiDolmus =>
      'اس کوڈ کے استعمال کی حد ختم ہو چکی ہے۔';

  @override
  String get lutfenOnceGirisYapin => 'براہ کرم پہلے لاگ ان کریں۔';

  @override
  String get m1AyUcretsizPremiumKazan => '1 ماہ کا مفت پریمیئم حاصل کریں';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'ایپ کے بارے میں اپنی رائے کا اظہار کرتے ہوئے دیے گئے ٹویٹ کو کوٹ ری ٹویٹ کریں اور ٹوئٹر (X) پر شیئر کرکے 1 ماہ کا مفت پریمیئم پائیں!';

  @override
  String get nasilKatilirim => 'کیسے شامل ہوں؟';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'ایپ کے بارے میں اپنی رائے کا اظہار کرتے ہوئے دیے گئے ٹویٹ کو کوٹ ری ٹویٹ کرکے ٹوئٹر (X) پر شیئر کریں۔';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'اپنی شیئر کی گئی پوسٹ کا سکرین شاٹ ٹوئٹر پر @ebubekr53 اکاؤنٹ کو ڈائریکٹ میسج کریں اور اپنا کوڈ حاصل کریں۔';

  @override
  String get koduAsagiyaGirin => 'کوڈ نیچے درج کریں۔';

  @override
  String get tweetiAlintila => 'ٹویٹ کوٹ کریں';

  @override
  String get promosyonKodu => 'پروموشن کوڈ';

  @override
  String get kullan => 'استعمال کریں';

  @override
  String get dahaFazlaOzellik => 'مزید خصوصیات';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'مزید فہرستیں بنانے کے لیے\nپریمیئم میں اپ گریڈ کریں';

  @override
  String get kapat => 'بند کریں';

  @override
  String get premiumAl => 'پریمیئم خریدیں';

  @override
  String get yeniListe => 'نئی فہرست';

  @override
  String get listeAdi => 'فہرست کا نام';

  @override
  String get iptal => 'منسوخ';

  @override
  String get olustur => 'بنائیں';

  @override
  String get listeyiYenidenAdlandir => 'فہرست کا نام تبدیل کریں';

  @override
  String get kaydet => 'محفوظ کریں';

  @override
  String get kelimeListelerim => 'میرے الفاظ کی فہرستیں';

  @override
  String get yeniListeOlustur => 'نئی فہرست بنائیں';

  @override
  String get henuzListeYok => 'ابھی کوئی فہرست نہیں ہے';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'اپنے الفاظ کو ترتیب دینے کے لیے\nایک فہرست بنائیں';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCount الفاظ',
      one: '1 لفظ',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'نام تبدیل کریں';

  @override
  String get sil => 'حذف کریں';

  @override
  String get listeyiSil => 'فہرست حذف کریں';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return '\"$name\" کو حذف کر دیا جائے؟\nاس میں موجود تمام الفاظ بھی حذف ہو جائیں گے۔';
  }

  @override
  String get buListedeHenuzKelimeYok => 'اس فہرست میں ابھی کوئی لفظ نہیں ہے';

  @override
  String get liste => 'فہرست';

  @override
  String get kart => 'کارڈ';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'مزید الفاظ کے کارڈز کے لیے پریمیئم میں اپ گریڈ کریں';

  @override
  String get premiumAYukselt => 'پریمیئم میں اپ گریڈ کریں';

  @override
  String get dinle => 'سنیں';

  @override
  String get oyun => 'گیم';

  @override
  String get kullanimSiniriDoldu => 'استعمال کی حد ختم ہو گئی';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'قرآن کی لغت کو لامحدود استعمال کرنے کے لیے براہ کرم لاگ ان کریں اور پریمیئم میں اپ گریڈ کریں۔';

  @override
  String get tamam => 'ٹھیک ہے';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'تمام کتابیں کھل گئی ہیں اور اشتہارات ہٹا دیے گئے ہیں۔';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'تمام کتابیں کھل گئی ہیں۔ اشتہارات کو مستقل طور پر ہٹانے کے لیے براہ کرم لاگ ان کریں۔';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'پوشیدہ کوڈ اپلائی نہیں ہو سکا: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'لغت اپ ڈیٹ ہو رہی ہے... براہ کرم انتظار کریں۔';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    return 'لغت کامیابی سے اپ ڈیٹ ہو گئی! $p1 الفاظ لوڈ ہو گئے۔';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu => 'لغت اپ ڈیٹ کرتے وقت غلطی ہوئی!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'ڈیٹا بیس ری لوڈ میں غلطی: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris =>
      'براہ کرم پہلے رجسٹر کریں یا لاگ ان کریں۔';

  @override
  String get kelimeAra => 'لفظ تلاش کریں';

  @override
  String get emsile => 'Emsile';

  @override
  String get kuranSozlugu => 'قرآنی لغت';

  @override
  String get kavaidIDegerlendir => 'Kavaid کی درجہ بندی کریں';

  @override
  String get gorusunBizimIcinCokDegerli => 'آپ کی رائے ہمارے لیے بہت قیمتی ہے۔';

  @override
  String get kuranSozluguYukleniyor => 'قرآنی لغت لوڈ ہو رہی ہے...';

  @override
  String get kuranSozlugundeAraniyor => 'قرآنی لغت میں تلاش جاری ہے...';

  @override
  String get araniyor => 'تلاش جاری ہے...';

  @override
  String get kuranSozlugundeBulunamadi => 'قرآنی لغت میں نہیں ملا';

  @override
  String get farkliBirKelimeVeyaKok =>
      'کسی اور لفظ یا مادہ (root) کے ساتھ تلاش کریں';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'قرآنی لغت کے مزید استعمال کے لیے Premium میں اپ گریڈ کریں۔';

  @override
  String get kurAnIKerimSozlugu => 'قرآن کریم کی لغت';

  @override
  String get kurAnDaGecenTum =>
      'قرآن میں آنے والے تمام الفاظ کے استعمال اور ان کے قرآنی مفہوم کو آیات کے ساتھ سیکھیں۔';

  @override
  String get kurAnDakiBenzersizTum => 'قرآن کے تمام منفرد الفاظ۔';

  @override
  String get kuraniAnlamlar => 'قرآنی مفہوم';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'الفاظ کے قرآنی آیات میں معنی سیکھیں۔';

  @override
  String get kurAnAyetleri => 'قرآنی آیات';

  @override
  String get onBinlerceKurAnAyeti =>
      'دسیوں ہزار قرآنی آیات کے ساتھ الفاظ کا استعمال دیکھیں۔';

  @override
  String get kavaidArapcaSozluk2 => 'Kavaid عربی لغت';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'نئی نسل کی مصنوعی ذہانت (AI) سے لیس پہلی عربی لغت';

  @override
  String get premiumAGec => 'Premium حاصل کریں';

  @override
  String get sinirsizErisim => 'لامحدود رسائی';

  @override
  String get profilResmiGuncellendi => '✅ پروفائل تصویر اپ ڈیٹ ہو گئی!';

  @override
  String get birHataOlustu => 'کوئی خرابی پیش آئی';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'Firebase اسٹوریج کنفیگر نہیں ہے۔ براہ کرم Firebase کنسول سے اسٹوریج کو فعال کریں۔';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'اجازت (Permission) کی خرابی۔ اسٹوریج کے قواعد چیک کریں۔';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'تصدیق (Authorization) کی خرابی۔ براہ کرم لاگ ان کریں۔';

  @override
  String get internetBaglantisiHatasi => 'انٹرنیٹ کنکشن کی خرابی۔';

  @override
  String get detay => 'تفصیل';

  @override
  String get hataDetayi => 'خرابی کی تفصیل';

  @override
  String get kullanici => 'صارف';

  @override
  String get kurucu => 'بانی';

  @override
  String get moderator => 'ماڈریٹر';

  @override
  String get emailYok => 'ای میل موجود نہیں';

  @override
  String get cikisYapilsinMi => 'کیا آپ لاگ آؤٹ کرنا چاہتے ہیں؟';

  @override
  String get oturumunuzKapatilacak => 'آپ کا سیشن ختم کر دیا جائے گا۔';

  @override
  String get cikis => 'لاگ آؤٹ';

  @override
  String get aboneligiYonet => 'سبسکرپشن کا انتظام کریں';

  @override
  String get satinAlmalarKontrolEdiliyor => 'خریداریاں چیک کی جا رہی ہیں...';

  @override
  String get geriYukle => 'بحال کریں';

  @override
  String get girisYapinVeyaKayitOlun => 'لاگ ان یا رجسٹر کریں';

  @override
  String get girisYap => 'لاگ ان کریں';

  @override
  String get kayitOl => 'رجسٹر کریں';

  @override
  String get premiumUyesiniz => 'آپ Premium ممبر ہیں';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'لامحدود مواد، اشتہارات سے پاک استعمال۔';

  @override
  String get tumOzelliklereErisin => 'تمام خصوصیات تک رسائی حاصل کریں۔';

  @override
  String get reklamsizKullanim => 'اشتہارات سے پاک استعمال';

  @override
  String get uygulamayiPaylas => 'ایپ شیئر کریں';

  @override
  String get iletisim => 'رابطہ';

  @override
  String get kavaidUygulamasiHakkinda => 'Kavaid ایپ کے بارے میں';

  @override
  String get hesabimiSil => 'میرا اکاؤنٹ ڈیلیٹ کریں';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'کیا آپ واقعی اپنا اکاؤنٹ اور اس سے منسلک تمام ڈیٹا مستقل طور پر حذف کرنا چاہتے ہیں؟ یہ عمل واپس نہیں کیا جا سکتا۔';

  @override
  String get vazgec => 'منسوخ کریں';

  @override
  String get hesabinizBasariylaSilindi =>
      'آپ کا اکاؤنٹ کامیابی سے ڈیلیٹ کر دیا گیا ہے۔';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'اکاؤنٹ ڈیلیٹ نہیں ہو سکا: $e۔ سیکیورٹی کی وجہ سے آپ کو دوبارہ لاگ ان کرنا پڑ سکتا ہے۔';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi => 'Kavaid - عربی لغت ایپ';

  @override
  String get paylasimSirasindaBirHataOlustu => 'شیئرنگ کے دوران خرابی پیش آئی';

  @override
  String get internetGerekli => 'انٹرنیٹ درکار ہے';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'اس عمل کے لیے انٹرنیٹ کنکشن ضروری ہے۔';

  @override
  String get kullaniciAdiDegistir => 'صارف نام تبدیل کریں';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'موجودہ: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'نیا صارف نام';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'username123 (چھوٹے حروف، بغیر وقفہ)';

  @override
  String get enAz3KarakterSadece =>
      '• کم از کم 3 حروف\n• صرف چھوٹے حروف، اعداد اور اردو حروف';

  @override
  String get kullaniciAdiEnAz3 => 'صارف نام کم از کم 3 حروف کا ہونا چاہیے';

  @override
  String get sadeceKucukHarfRakamVe => 'صرف چھوٹے حروف، اعداد اور اردو حروف';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'آپ کا صارف نام \"$newUsername\" کے طور پر اپ ڈیٹ ہو گیا ہے!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'یہ صارف نام دستیاب نہیں ہے یا پہلے سے لیا جا چکا ہے';

  @override
  String get degistir => 'تبدیل کریں';

  @override
  String get premiumUyelikAktif => '🎉 پریمیم رکنیت فعال ہے!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'کنکشن نہیں کھل سکا: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'پریمیم خریدنے کے لیے براہ کرم پہلے لاگ ان کریں۔';

  @override
  String hataE(Object e) {
    return 'غلطی: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid پریمیم';

  @override
  String get aiAsistanASinirsizErisim => 'AI اسسٹنٹ تک لامحدود رسائی';

  @override
  String get ceviriyeSinirsizErisim => 'ترجمہ تک لامحدود رسائی';

  @override
  String get m5500Fiilin24Siga =>
      '5500 سے زائد افعال کی 24 صیغوں والی امثلہ کھولیں';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'سیکھنے (Learn) کے تمام مواد تک رسائی';

  @override
  String get kuranSozluguneSinirsizErisim => 'قرآن ڈکشنری تک لامحدود رسائی';

  @override
  String get sinirsizKelimeKartiVeListe => 'لامحدود فلیش کارڈز اور لسٹ بنائیں';

  @override
  String get reklamsizDeneyim => 'اشتہار سے پاک تجربہ';

  @override
  String get aylikAbonelik => 'ماہانہ سبسکرپشن';

  @override
  String get m1AyBoyuncaSinirsizErisim => '1 ماہ کے لیے لامحدود رسائی';

  @override
  String get yillikAbonelik => 'سالانہ سبسکرپشن';

  @override
  String get m1YilBoyuncaSinirsizErisim => '1 سال کے لیے لامحدود رسائی';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return '1 سال کے لیے لامحدود رسائی ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return '$yearlyDiscount% رعایت';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'ماہانہ سبسکرائب کریں$buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'سالانہ سبسکرائب کریں$buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'ادائیگی آپ کے Apple ID اکاؤنٹ سے وصول کی جائے گی۔ سبسکرپشن خود بخود تجدید ہو جائے گی جب تک کہ اسے مدت کے اختتام سے کم از کم 24 گھنٹے قبل منسوخ نہ کیا جائے۔ آپ کسی بھی وقت ایپ اسٹور اکاؤنٹ سیٹنگز سے اسے منسوخ کر سکتے ہیں۔';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'ادائیگی گوگل پلے کے ذریعے وصول کی جائے گی۔ سبسکرپشن خود بخود تجدید ہو جائے گی جب تک کہ اسے مدت کے اختتام سے کم از کم 24 گھنٹے قبل منسوخ نہ کیا جائے۔ آپ کسی بھی وقت گوگل پلے اکاؤنٹ سیٹنگز سے اسے منسوخ کر سکتے ہیں۔';

  @override
  String get satinAlmalariGeriYukle => 'خریداری بحال کریں';

  @override
  String get kullanimKosullariEula => 'استعمال کی شرائط (EULA)';

  @override
  String get gizlilikPolitikasi => 'پرائیویسی پالیسی';

  @override
  String get metinGirin => 'متن درج کریں';

  @override
  String get harekeAc => 'اعراب آن';

  @override
  String get kopyala => 'کاپی کریں';

  @override
  String get kopyalandi => 'کاپی ہو گیا';

  @override
  String get cevir => 'ترجمہ کریں';

  @override
  String get suDileCevir => 'اس زبان میں ترجمہ کریں';

  @override
  String get premiumAGecin => 'پریمیم حاصل کریں';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'مزید ترجمہ کرنے کے لیے پریمیم حاصل کریں۔';

  @override
  String get lutfenOnceKayitOlupGiris =>
      'براہ کرم پہلے رجسٹر ہو کر لاگ ان کریں۔';

  @override
  String get diller => 'زبانیں';

  @override
  String get lehceler => 'لہجے';

  @override
  String get internetBaglantisiGerekiyor => 'انٹرنیٹ کنکشن درکار ہے۔';

  @override
  String get aiAsistanSuAnKullanilamiyor =>
      'AI اسسٹنٹ فی الحال دستیاب نہیں ہے۔';

  @override
  String get yanitGelmedi => 'کوئی جواب موصول نہیں ہوا۔';

  @override
  String get suAndaCevapAlinamadi => 'فی الحال جواب موصول نہیں ہو سکا۔';

  @override
  String get hazir => 'تیار۔';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'AI ورڈ اسسٹنٹ کے لیے انٹرنیٹ کنکشن درکار ہے۔';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'آپ کا آج کا مفت AI ورڈ اسسٹنٹ کا کوٹہ ختم ہو گیا ہے۔';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'AI ٹیچر API کی (key) غلط ہے۔ Firebase gemini_api ویلیو چیک کریں۔';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'AI ورڈ اسسٹنٹ فی الحال جواب نہیں دے سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get yukleniyor => 'لوڈ ہو رہا ہے...';

  @override
  String get sozlukHazir => 'لغت تیار ہے۔';

  @override
  String get sozlukYuklenemedi => 'لغت لوڈ نہیں ہو سکی۔';

  @override
  String get ekranHazirlaniyor => 'اسکرین تیار ہو رہی ہے...';

  @override
  String get sozlukKontrolEdiliyor => 'لغت چیک کی جا رہی ہے...';

  @override
  String get sozlukAyarlaniyor => 'لغت ترتیب دی جا رہی ہے...';

  @override
  String get aramaHazirlaniyor => 'تلاش کے لیے تیاری ہو رہی ہے...';

  @override
  String get aramaHazir => 'تلاش کے لیے تیار۔';

  @override
  String get internetBaglantisiYok => 'انٹرنیٹ کنکشن نہیں ہے';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'ایپ استعمال کرنے کے لیے آپ کو انٹرنیٹ کنکشن کی ضرورت ہے۔ براہ کرم اپنا وائی فائی یا موبائل ڈیٹا چیک کریں۔';

  @override
  String get sozlukHazirlaniyor => 'لغت تیار کی جا رہی ہے...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    String _temp0 = intl.Intl.pluralLogic(
      existingCount,
      locale: localeName,
      other: '$existingCount الفاظ موجود ہیں۔',
      one: '1 لفظ موجود ہے۔',
    );
    return 'لغت تیار ہے۔ $_temp0';
  }

  @override
  String get kelimelerYukleniyor => 'الفاظ لوڈ ہو رہے ہیں...';

  @override
  String get sozlukHazir2 => 'لغت تیار ہے!';

  @override
  String get mevcutVeritabaniKullanilacak =>
      'موجودہ ڈیٹا بیس استعمال کیا جائے گا۔';

  @override
  String get hicGuncellenmedi => 'کبھی اپ ڈیٹ نہیں ہوا';

  @override
  String get girisYapmalisiniz => 'آپ کو لاگ ان کرنا ہوگا۔';

  @override
  String get paketBulunamadiLifetime => 'پیکیج نہیں ملا (لائف ٹائم)۔';

  @override
  String get hataOlustu => 'غلطی پیش آئی';

  @override
  String beklenmedikHataE(Object e) {
    return 'غیر متوقع غلطی: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'RevenueCat شروع نہیں ہو سکا: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris => 'خریداری کے لیے پہلے لاگ ان کریں۔';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'خریداری میں غلطی: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'سبسکرپشن پیکیج لوڈ نہیں ہو سکا۔ براہ کرم اپنا انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'خریداری کی تصدیق کے لیے انٹرنیٹ کنکشن ضروری ہے۔';

  @override
  String get aktifBirAbonelikBulunamadi => 'کوئی فعال سبسکرپشن نہیں ملی۔';

  @override
  String restoreHatasiE(Object e) {
    return 'بحالی میں غلطی: $e';
  }

  @override
  String get hataOlustu2 => 'غلطی پیش آئی۔';

  @override
  String get ceviriIcinGirisYapmanGerekiyor =>
      'ترجمہ کے لیے لاگ ان کرنا ضروری ہے۔';

  @override
  String get premiumKullanici => 'پریمیم صارف۔';

  @override
  String get ceviriHakkiKullanildi => 'ترجمہ کا کوٹہ استعمال ہو چکا ہے۔';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'ترجمہ کا کوٹہ چیک نہیں ہو سکا۔ اپنا کنکشن چیک کریں۔';

  @override
  String get yeniSohbet => 'نئی بات چیت';

  @override
  String get buSohbetinGecmisiSilinsinMi => 'کیا اس چیٹ کی ہسٹری حذف کر دیں؟';

  @override
  String get aiAsistan => 'AI اسسٹنٹ';

  @override
  String get hakkinda => ' کے بارے میں';

  @override
  String get arapcaSozlukYardimcin => 'آپ کا عربی لغت کا ساتھی';

  @override
  String get bugunkuUcretsizSoruHakkin => 'آپ کے آج کے مفت سوالات';

  @override
  String get arapcasiniDinle => 'عربی سنیں';

  @override
  String get tekrarDene2 => 'دوبارہ کوشش کریں';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    return 'آج کے $freeDailyLimit مفت سوالات مکمل ہو چکے ہیں';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'آپ کے سوالات کل ری سیٹ ہوں گے۔ پریمیم کے ساتھ لامحدود پوچھیں۔';

  @override
  String get premiumAGec2 => 'پریمیم حاصل کریں';

  @override
  String get kisacaAnlat => 'مختصر وضاحت';

  @override
  String get m3OrnekCumleVer => '3 مثالیں دیں';

  @override
  String get benzerKelimelerdenFarkiNe => 'مشابہ الفاظ سے فرق کیا ہے؟';

  @override
  String get okunusunuLatinHarfleriyleYaz => 'تلفظ رومن (لیٹن) میں لکھیں';

  @override
  String get gecmisZamanNasilKurulur => 'ماضی کیسے بنتا ہے؟';

  @override
  String get harfICerNedir => 'حرف الجر کیا ہے؟';

  @override
  String get isimCumlesiNasilKurulur => 'جملہ اسمیہ کیسے بنتا ہے؟';

  @override
  String get enSikKullanilan10Fiil => '10 عام ترین افعال';

  @override
  String get sonSorduklarim => 'حال ہی میں پوچھے گئے';

  @override
  String get ornekSorular => 'نمونے کے سوالات';

  @override
  String get buKelimeHakkindaKisaVe =>
      'اس لفظ کے بارے میں مختصر اور واضح جواب حاصل کریں۔';

  @override
  String get arapcaSorunuYaz => 'اپنا عربی سوال لکھیں';

  @override
  String get kisaVeNetCevapVerir =>
      'مختصر اور درست جواب دیتا ہے، غلط معلومات نہیں دیتا۔';

  @override
  String get ornekVer => 'مثال دیں';

  @override
  String get dahaBasitAnlat => 'آسان الفاظ میں بتائیں';

  @override
  String get derinles => 'تفصیل میں جائیں';

  @override
  String get cekiminiGoster => 'گردان دکھائیں';

  @override
  String get aiAsistanASor => 'AI اسسٹنٹ سے پوچھیں...';

  @override
  String get yeniAiAsistan => 'نیا: AI اسسٹنٹ';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'لفظ کارڈ کے بائیں جانب والے اس آئیکن پر کلک کریں: مطلب، فرق اور مثالیں پوچھیں۔';

  @override
  String get anladim => 'سمجھ گیا';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'اس لفظ کے ساتھ مختلف سطحوں کی مثالیں دیں: آسان، درمیانہ، روزمرہ، گرامر، اور سوالیہ جملے۔';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'آج کا مفت AI ورڈ اسسٹنٹ کوٹہ ختم ہو چکا ہے۔ جاری رکھنے کے لیے Premium حاصل کریں۔';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'فی الحال جواب حاصل نہیں ہو سکا۔ انٹرنیٹ کنکشن چیک کر کے دوبارہ کوشش کریں۔';

  @override
  String get aiKelimeAsistani => 'AI ورڈ اسسٹنٹ';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining مفت مواقع',
      one: '1 مفت موقع',
    );
    return 'AI ورڈ اسسٹنٹ · $_temp0';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi => 'AI ورڈ اسسٹنٹ تیار نہیں ہو سکا۔';

  @override
  String get premiumAGec3 => 'Premium حاصل کریں';

  @override
  String get kisacaAnlat2 => 'مختصراً بتائیں';

  @override
  String get gramerNotlari => 'گرائمر نوٹس';

  @override
  String get kullanimNotlari => 'استعمال کے نوٹس';

  @override
  String get buKelimeNeredeKullanilir => 'یہ لفظ کہاں استعمال ہوتا ہے؟';

  @override
  String get m5YeniOrnekVer => '5 نئی مثالیں دیں';

  @override
  String get kolayCumlelerleAnlat => 'آسان جملوں میں سمجھائیں';

  @override
  String get cekimleOrnekVer => 'گردان کے ساتھ مثال دیں';

  @override
  String get harfICerFarkiniAnlat => 'حرفِ جر کا فرق بتائیں';

  @override
  String get ornekleOgren => 'مثالوں سے سیکھیں';

  @override
  String get miniAlistirma => 'مختصر مشق';

  @override
  String get hazirSorular => 'پہلے سے موجود سوالات';

  @override
  String get sor => 'پوچھیں';

  @override
  String get buKelimeyleIlgiliSoruSor => 'اس لفظ کے بارے میں کچھ پوچھیں';

  @override
  String get arapcaTurkceSozluk => 'عربی–اردو لغت';

  @override
  String get arapcaYaDaTurkceYaz => 'عربی یا اردو لکھیں، سب کچھ ایک کارڈ میں۔';

  @override
  String get sesleYaDaArapcaKlavyeyle => 'آواز یا عربی کی بورڈ سے تلاش کریں';

  @override
  String get kokCogulVeOrnekCumleler => 'مادہ، جمع اور مثالیں';

  @override
  String get fiilKarti => 'فعل کارڈ';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'افعال کی گردان کارڈ کے اندر ہے۔';

  @override
  String get maziMuzariMastarVeEmir => 'ماضی، مضارع، مصدر اور امر';

  @override
  String get tumCekimlerIcinEmsileyeGec => 'مکمل گردان کے لیے Emsile پر جائیں';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'لفظ کارڈ کے بائیں طرف موجود آئیکن کو دبائیں۔';

  @override
  String get sorunuYazYaDaHazir =>
      'اپنا سوال لکھیں یا پہلے سے موجود سوال منتخب کریں';

  @override
  String get kisaVeNetCevap => 'مختصر اور واضح جواب';

  @override
  String get m5500DenFazlaFiilin => '5,500 سے زیادہ افعال کی گردان۔';

  @override
  String get fiileDokunKartiAcilsin => 'فعل کو دبائیں، کارڈ کھل جائے گا';

  @override
  String get anlamlariVe24SigaCekimi => 'معانی اور 24 صیغوں کی گردان';

  @override
  String get kurAnSozlugu => 'قرآن لغت';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'قرآنی الفاظ کو آیات کے ساتھ سیکھیں۔';

  @override
  String get kelimeVeKurAniAnlamlari => 'لفظ اور اس کے قرآنی معانی';

  @override
  String get gectigiAyetVeMeali => 'آیت اور اس کا ترجمہ';

  @override
  String get lehceCeviri => 'لہجوں میں ترجمہ';

  @override
  String get turkceYazYaDaKonus =>
      'اردو لکھیں یا بولیں، 17 لہجوں میں ترجمہ کریں۔';

  @override
  String get karsiligiVeOkunusu => 'متبادل اور تلفظ';

  @override
  String get lehceyiSecYaDaSesle => 'لہجہ منتخب کریں یا بول کر بتائیں';

  @override
  String get listelerVeKartlar => 'فہرستیں اور کارڈز';

  @override
  String get kaydettiginHerSeyTekYerde => 'آپ کی محفوظ کردہ ہر چیز ایک جگہ۔';

  @override
  String get listeYaDaKartlarlaTekrar => 'فہرست یا کارڈز کے ساتھ دہرائیں';

  @override
  String get sozlukKurAnVeEmsile => 'لغت، قرآن اور Emsile ریکارڈز';

  @override
  String get a1DenC1EResimli => 'A1 سے C1 تک تصویری عربی کہانیاں۔';

  @override
  String get kelimeyeDokunAnlamiCiksin => 'لفظ کو چھوئیں، معنی سامنے آ جائے گا';

  @override
  String get metniSesliDinle => 'متن کو آڈیو میں سنیں';

  @override
  String get gec => 'آگے بڑھیں';

  @override
  String get yeni => 'نیا';

  @override
  String get ara => 'تلاش';

  @override
  String get bosluk => 'اسپیس';

  @override
  String get hesabinizYoksaOnceKayitOlun =>
      'اگر آپ کا اکاؤنٹ نہیں ہے تو پہلے سائن اپ کریں';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'رجسٹریشن مکمل ہونے کے بعد آپ کو لاگ ان کرنا ہوگا۔';

  @override
  String get ePosta => 'ای میل';

  @override
  String get gecersizEPostaAdresi => 'غلط ای میل پتہ';

  @override
  String get sifre => 'پاس ورڈ';

  @override
  String get sifreGerekli => 'پاس ورڈ درکار ہے';

  @override
  String get sifremiUnuttum => 'پاس ورڈ بھول گئے؟';

  @override
  String get sifreTekrar => 'پاس ورڈ دوبارہ لکھیں';

  @override
  String get sifreTekrariGerekli => 'پاس ورڈ کی دوبارہ تصدیق درکار ہے';

  @override
  String get sifrelerEslesmiyor => 'پاس ورڈز میل نہیں کھا رہے';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'پاس ورڈ ری سیٹ کرنے کے لیے پہلے اپنا ای میل درج کریں۔';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return 'اگر $email پر کوئی اکاؤنٹ رجسٹرڈ ہے تو پاس ورڈ ری سیٹ کرنے کا لنک بھیج دیا گیا ہے۔ اپنا ان باکس اور سپیم فولڈر چیک کریں۔';
  }

  @override
  String get gecerliBirEPostaAdresi => 'براہ کرم درست ای میل ایڈریس درج کریں۔';

  @override
  String get buEPostaIleKayit => 'اس ای میل سے کوئی اکاؤنٹ نہیں ملا۔';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'بہت زیادہ کوششیں کی گئیں۔ کچھ دیر بعد دوبارہ کوشش کریں۔';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'نیٹ ورک کی خرابی۔ اپنے انٹرنیٹ کنکشن کو چیک کریں۔';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'لنک نہیں بھیجا جا سکا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 خوش آمدید! آپ کا اکاؤنٹ کامیابی سے بن گیا ہے۔';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'عمل ناکام رہا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get ePostaVeyaSifreHatali =>
      'ای میل یا پاس ورڈ غلط ہے۔ براہ کرم چیک کریں۔';

  @override
  String get sifreHatali => 'غلط پاس ورڈ۔';

  @override
  String get buEPostaZatenKayitli => 'یہ ای میل پہلے سے رجسٹرڈ ہے۔';

  @override
  String get sifreCokZayifDahaGuclu =>
      'پاس ورڈ بہت کمزور ہے۔ زیادہ مضبوط پاس ورڈ چنیں۔';

  @override
  String get buGirisYontemiProjeIcin =>
      'یہ لاگ ان طریقہ اس پروجیکٹ کے لیے فعال نہیں ہے۔';

  @override
  String get oDisil => 'وہ (مونث)';

  @override
  String get ikisi => 'وہ دونوں';

  @override
  String get ikisiEril => 'وہ دونوں (مذکر)';

  @override
  String get ikisiDisil => 'وہ دونوں (مونث)';

  @override
  String get onlarDisil => 'وہ (مونث)';

  @override
  String get senDisil => 'تم (مونث)';

  @override
  String get ikiniz => 'تم دونوں';

  @override
  String get sizDisil => 'تم سب (مونث)';

  @override
  String get m3Sahis => 'غائب (تیسرا شخص)';

  @override
  String get m2Sahis => 'حاضر (دوسرا شخص)';

  @override
  String get m1Sahis => 'متکلم (پہلا شخص)';

  @override
  String get muzari => 'مضارع';

  @override
  String get emsileCekimleri => 'امثلہ گردان';

  @override
  String get maziGecmis => 'ماضی';

  @override
  String get muzariGenis => 'مضارع';

  @override
  String get emir => 'امر';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return '$tabTitle گردان نہیں ملی';
  }

  @override
  String get kok => 'مادہ';

  @override
  String get ismIFail => 'اسم فاعل';

  @override
  String get ismIMefUl => 'اسم مفعول';

  @override
  String get fiilCekimleriKavaidSozluk => 'افعال کی گردانیں • قواعد لغت';

  @override
  String get m5500DenFazlaFiilin2 =>
      '5500 سے زائد افعال کی 24 صیغوں کے ساتھ امثلہ کی گردانیں سیکھیں۔';

  @override
  String get tumFiilleriAc => 'تمام افعال دیکھیں';

  @override
  String get dahaFazlaFiilYukle => 'مزید افعال لوڈ کریں';

  @override
  String get arananKelimeBulunamadi => 'مطلوبہ لفظ نہیں ملا';

  @override
  String get fiilIMaziMuttasilCekimler => 'فعل ماضی - متصل گردانیں';

  @override
  String get fiilIMuzariMuttasilCekimler => 'فعل مضارع - متصل گردانیں';

  @override
  String get emrIHazirMuttasilCekimler => 'امر حاضر - متصل گردانیں';

  @override
  String get cekimler => 'گردانیں';

  @override
  String get premiumIcerik => 'پریمیم مواد';

  @override
  String get m5500DenFazlaFiilin3 =>
      '5500 سے زائد افعال کی 24 صیغوں والی امثلہ گردانیں کھولیں';

  @override
  String get ucretsizFiiller => 'مفت افعال';

  @override
  String get listeyeEkle => 'فہرست میں شامل کریں';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'AI اسسٹنٹ استعمال کرنے کے لیے براہ کرم لاگ ان کریں۔';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'اس لفظ کے ساتھ میری سطح کے مطابق 5 نئی مثالیں دیں: آسان سے مشکل کی ترتیب میں۔';

  @override
  String get tumFiilCekimleri => 'تمام افعال کی گردانیں';

  @override
  String kokRoot(Object root) {
    return 'مادہ $root';
  }

  @override
  String get cogul => 'جمع';

  @override
  String get ornekCumleler => 'مثالی جملے';

  @override
  String get cumleyiDinle => 'جملہ سنیں';

  @override
  String get aiAsistanASor2 => 'AI اسسٹنٹ سے پوچھیں';

  @override
  String get dahaFazlaOrnek => 'مزید مثالیں';

  @override
  String get kelimeKaydetmekIcinOnceGiris =>
      'الفاظ محفوظ کرنے کے لیے پہلے لاگ ان کریں';

  @override
  String get oyna => 'کھیلیں';

  @override
  String get verbFormPast => 'ماضی';

  @override
  String get verbFormPresent => 'مضارع';

  @override
  String get verbFormInfinitive => 'مصدر';

  @override
  String get verbFormImperative => 'امر';

  @override
  String get zamirOEril => 'وہ (مذکر)';

  @override
  String get zamirOnlarEril => 'وہ سب (مذکر)';

  @override
  String get zamirSenEril => 'تم (مذکر)';

  @override
  String get zamirSizEril => 'آپ سب (مذکر)';

  @override
  String get zamirBen => 'میں';

  @override
  String get zamirBiz => 'ہم';

  @override
  String get dialectTr => 'ترکی';

  @override
  String get dialectEn => 'انگریزی';

  @override
  String get dialectDe => 'جرمن';

  @override
  String get dialectFr => 'فرانسیسی';

  @override
  String get dialectRu => 'روسی';

  @override
  String get dialectEs => 'ہسپانوی';

  @override
  String get dialectIt => 'اطالوی';

  @override
  String get dialectPt => 'پرتگالی';

  @override
  String get dialectNl => 'ڈچ';

  @override
  String get dialectFa => 'فارسی';

  @override
  String get dialectUr => 'اردو';

  @override
  String get dialectId => 'انڈونیشی';

  @override
  String get dialectArStandard => 'عربی (معیاری)';

  @override
  String get dialectArSyrian => 'شامی لہجہ';

  @override
  String get dialectArLebanese => 'لبنانی لہجہ';

  @override
  String get dialectArJordanian => 'اردنی لہجہ';

  @override
  String get dialectArPalestinian => 'فلسطینی لہجہ';

  @override
  String get dialectArEgyptian => 'مصری لہجہ';

  @override
  String get dialectArIraqi => 'عراقی لہجہ';

  @override
  String get dialectArSudanese => 'سوڈانی لہجہ';

  @override
  String get dialectArSaudi => 'سعودی لہجہ';

  @override
  String get dialectArEmirati => 'اماراتی لہجہ';

  @override
  String get dialectArKuwaiti => 'کویتی لہجہ';

  @override
  String get dialectArQatari => 'قطری لہجہ';

  @override
  String get dialectArOmani => 'عُمانی لہجہ';

  @override
  String get dialectArYemeni => 'یمنی لہجہ';

  @override
  String get dialectArMoroccan => 'مراکشی لہجہ';

  @override
  String get dialectArAlgerian => 'الجزائری لہجہ';

  @override
  String get dialectArTunisian => 'تُونسی لہجہ';

  @override
  String get dialectArLibyan => 'لیبیائی لہجہ';

  @override
  String get appLanguage => 'ایپ کی زبان';

  @override
  String get typeNoun => 'اسم';

  @override
  String get typeProperNoun => 'اسم معرفہ';

  @override
  String get typeVerb => 'فعل';

  @override
  String get typeVerbPast => 'فعل ماضی';

  @override
  String get typeVerbPresent => 'فعل مضارع';

  @override
  String get typeVerbImperative => 'فعل امر';

  @override
  String get typeVerbProhibitive => 'فعل نہی';

  @override
  String get typeVerbPastPassive => 'ماضی مجہول';

  @override
  String get typeVerbPresentPassive => 'مضارع مجہول';

  @override
  String get typeVerbDefective => 'افعال ناقصہ';

  @override
  String get typeMasdar => 'مصدر';

  @override
  String get typeActiveParticiple => 'اسم فاعل';

  @override
  String get typePassiveParticiple => 'اسم مفعول';

  @override
  String get typeElative => 'اسم تفضیل';

  @override
  String get typeAdjective => 'صفت';

  @override
  String get typeAdverb => 'ظرف';

  @override
  String get typeHal => 'حال';

  @override
  String get typePronoun => 'ضمیر';

  @override
  String get typeDemonstrative => 'اسم اشارہ';

  @override
  String get typeRelative => 'اسم موصول';

  @override
  String get typeInterrogative => 'حرف استفہام';

  @override
  String get typePreposition => 'حرفِ جر';

  @override
  String get typeParticle => 'حرف';

  @override
  String get typeNumber => 'عدد';

  @override
  String get typePhrase => 'مرکب';

  @override
  String get typeExpression => 'مقولہ';

  @override
  String get typeIdiom => 'محاورہ';

  @override
  String get siga01 => 'ماضی';

  @override
  String get siga02 => 'مضارع';

  @override
  String get siga03 => 'مصدر';

  @override
  String get siga04 => 'اسم فاعل';

  @override
  String get siga05 => 'اسم مفعول';

  @override
  String get siga06 => 'نفی مطلق';

  @override
  String get siga07 => 'نفی مستغرق';

  @override
  String get siga08 => 'نفی حال';

  @override
  String get siga09 => 'نفی استقبال';

  @override
  String get siga10 => 'تاکیدی نفی است.';

  @override
  String get siga11 => 'امر غائب';

  @override
  String get siga12 => 'نہی غائب';

  @override
  String get siga13 => 'امر حاضر';

  @override
  String get siga14 => 'نہی حاضر';

  @override
  String get siga15 => 'اسم زمان و مکان';

  @override
  String get siga16 => 'اسم آلہ';

  @override
  String get siga17 => 'اسم مرّہ';

  @override
  String get siga18 => 'اسم ہیئت';

  @override
  String get siga19 => 'اسم تصغیر';

  @override
  String get siga20 => 'اسم منسوب';

  @override
  String get siga21 => 'صیغہ مبالغہ';

  @override
  String get siga22 => 'اسم تفضیل';

  @override
  String get siga23 => 'تعجب 1';

  @override
  String get siga24 => 'تعجب 2';

  @override
  String get dialectMs => 'ملائی';

  @override
  String get dialectBn => 'بنگالی';

  @override
  String get dialectUz => 'ازبک';

  @override
  String get dialectAz => 'آذری';

  @override
  String get prepositionsLabel => 'حروفِ جر کے ساتھ';

  @override
  String get tashkeelToggle => 'اعراب';

  @override
  String get tashkeelSettingHint => 'تعریفات اور مثالوں میں اعراب دکھائیں';

  @override
  String get rootMatches => 'ہم مادہ الفاظ';

  @override
  String get dictionaryLanguage => 'لغت کی زبان';

  @override
  String get dictionaryLanguageHint => 'الفاظ کے معانی کی زبان';

  @override
  String get arabicArabicDictionary => 'عربی–عربی لغت';
}
