// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get kavaidSozluk => 'Kavaid অভিধান';

  @override
  String get markaAdi => 'Kavaid';

  @override
  String get tanitimDevam => 'চালিয়ে যান';

  @override
  String get tanitimBasla => 'শুরু করুন';

  @override
  String get tekrarDene => 'পুনরায় চেষ্টা করুন';

  @override
  String get kavaidArapcaSozluk => 'Kavaid - আরবি অভিধান';

  @override
  String get sozluk => 'অভিধান';

  @override
  String get ceviri => 'অনুবাদ';

  @override
  String get ogren => 'শিখুন';

  @override
  String get profil => 'প্রোফাইল';

  @override
  String get kelimeBulunamadi => 'শব্দটি পাওয়া যায়নি';

  @override
  String get baglantiAcilamadi => 'লিঙ্কটি খোলা যাচ্ছে না';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'অভিনন্দন! আপনার অ্যাকাউন্টে ১ মাসের প্রিমিয়াম যুক্ত হয়েছে 🌟';

  @override
  String get gecersizVeyaKullanilmisKod =>
      'কোডটি অবৈধ বা ইতিমধ্যে ব্যবহৃত হয়েছে।';

  @override
  String get buKoduDahaOnceKullandiniz => 'আপনি এই কোডটি আগে ব্যবহার করেছেন।';

  @override
  String get buKodunSuresiDolmus => 'এই কোডের মেয়াদ শেষ হয়ে গেছে।';

  @override
  String get buKodunKullanimLimitiDolmus =>
      'এই কোড ব্যবহারের সীমা শেষ হয়ে গেছে।';

  @override
  String get lutfenOnceGirisYapin => 'অনুগ্রহ করে আগে লগইন করুন।';

  @override
  String get m1AyUcretsizPremiumKazan => '১ মাস ফ্রি প্রিমিয়াম জিতুন';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'অ্যাপ সম্পর্কে আপনার মতামত উল্লেখ করে টুইটটি কোট করুন এবং Twitter (X)-এ শেয়ার করে ১ মাস ফ্রি প্রিমিয়াম পান!';

  @override
  String get nasilKatilirim => 'কিভাবে অংশগ্রহণ করবেন?';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'অ্যাপ সম্পর্কে আপনার মতামত উল্লেখ করে টুইটটি কোট করুন এবং Twitter (X)-এ শেয়ার করুন।';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'আপনার শেয়ার করা টুইটটি Twitter-এ @ebubekr53 অ্যাকাউন্টে ডিরেক্ট মেসেজ (DM) করুন এবং আপনার কোডটি নিন।';

  @override
  String get koduAsagiyaGirin => 'নিচে কোডটি লিখুন।';

  @override
  String get tweetiAlintila => 'টুইট কোট করুন';

  @override
  String get promosyonKodu => 'প্রমোশন কোড';

  @override
  String get kullan => 'ব্যবহার করুন';

  @override
  String get dahaFazlaOzellik => 'আরও ফিচার';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'আরও তালিকা তৈরি করতে\nপ্রিমিয়ামে আপগ্রেড করুন';

  @override
  String get kapat => 'বন্ধ করুন';

  @override
  String get premiumAl => 'প্রিমিয়াম কিনুন';

  @override
  String get yeniListe => 'নতুন তালিকা';

  @override
  String get listeAdi => 'তালিকার নাম';

  @override
  String get iptal => 'বাতিল';

  @override
  String get olustur => 'তৈরি করুন';

  @override
  String get listeyiYenidenAdlandir => 'তালিকার নাম পরিবর্তন করুন';

  @override
  String get kaydet => 'সংরক্ষণ করুন';

  @override
  String get kelimeListelerim => 'আমার শব্দ তালিকা';

  @override
  String get yeniListeOlustur => 'নতুন তালিকা তৈরি করুন';

  @override
  String get henuzListeYok => 'এখনও কোনো তালিকা নেই';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'আপনার শব্দগুলোকে সাজাতে\nএকটি তালিকা তৈরি করুন';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCountটি শব্দ',
      one: '১টি শব্দ',
      zero: 'কোনো শব্দ নেই',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'নাম পরিবর্তন করুন';

  @override
  String get sil => 'মুছে ফেলুন';

  @override
  String get listeyiSil => 'তালিকাটি মুছে ফেলুন';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return '\"$name\" মুছে ফেলতে চান?\nএর ভেতরের সব শব্দও মুছে যাবে।';
  }

  @override
  String get buListedeHenuzKelimeYok => 'এই তালিকায় এখনও কোনো শব্দ নেই';

  @override
  String get liste => 'তালিকা';

  @override
  String get kart => 'কার্ড';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'আরও শব্দ কার্ডের জন্য প্রিমিয়ামে আপগ্রেড করুন';

  @override
  String get premiumAYukselt => 'প্রিমিয়ামে আপগ্রেড করুন';

  @override
  String get dinle => 'শুনুন';

  @override
  String get oyun => 'খেলা';

  @override
  String get kullanimSiniriDoldu => 'ব্যবহারের সীমা শেষ হয়েছে';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'কুরআন অভিধানটি আনলিমিটেড ব্যবহার করতে অনুগ্রহ করে লগইন করুন এবং প্রিমিয়ামে আপগ্রেড করুন।';

  @override
  String get tamam => 'ঠিক আছে';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'সব বই আনলক হয়েছে এবং বিজ্ঞাপন সরিয়ে দেওয়া হয়েছে।';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'সব বই আনলক হয়েছে। বিজ্ঞাপন স্থায়ীভাবে সরাতে অনুগ্রহ করে লগইন করুন।';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'গোপন কোডটি প্রয়োগ করা যায়নি: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'অভিধান আপডেট হচ্ছে... অনুগ্রহ করে অপেক্ষা করুন।';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    return 'অভিধান সফলভাবে আপডেট হয়েছে! $p1 টি শব্দ লোড হয়েছে।';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu =>
      'অভিধান আপডেট করার সময় ত্রুটি হয়েছে!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'ডেটাবেস রিলোড ত্রুটি: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris =>
      'অনুগ্রহ করে আগে রেজিস্টার করুন বা লগ ইন করুন।';

  @override
  String get kelimeAra => 'শব্দ খুঁজুন';

  @override
  String get emsile => 'তাসরীফ';

  @override
  String get kuranSozlugu => 'কুরআন অভিধান';

  @override
  String get kavaidIDegerlendir => 'Kavaid-কে রেট করুন';

  @override
  String get gorusunBizimIcinCokDegerli =>
      'আপনার মতামত আমাদের কাছে অত্যন্ত মূল্যবান।';

  @override
  String get kuranSozluguYukleniyor => 'কুরআন অভিধান লোড হচ্ছে...';

  @override
  String get kuranSozlugundeAraniyor => 'কুরআন অভিধানে অনুসন্ধান করা হচ্ছে...';

  @override
  String get araniyor => 'অনুসন্ধান করা হচ্ছে...';

  @override
  String get kuranSozlugundeBulunamadi => 'কুরআন অভিধানে পাওয়া যায়নি';

  @override
  String get farkliBirKelimeVeyaKok =>
      'অন্য কোনো শব্দ বা মূল (root) দিয়ে অনুসন্ধান করুন';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'কুরআন অভিধানের আরও বেশি ব্যবহারের জন্য প্রিমিয়ামে আপগ্রেড করুন।';

  @override
  String get kurAnIKerimSozlugu => 'পবিত্র কুরআন অভিধান';

  @override
  String get kurAnDaGecenTum =>
      'কুরআনে ব্যবহৃত সকল শব্দের ব্যবহার এবং কুরআনিক অর্থ আয়াতসহ শিখুন।';

  @override
  String get kurAnDakiBenzersizTum => 'কুরআনের সকল অনন্য শব্দ।';

  @override
  String get kuraniAnlamlar => 'কুরআনিক অর্থ';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'কুরআনের আয়াতসমূহে শব্দের অর্থ কীভাবে পরিবর্তিত হয় তা জানুন।';

  @override
  String get kurAnAyetleri => 'কুরআনের আয়াত';

  @override
  String get onBinlerceKurAnAyeti =>
      'কুরআনের হাজার হাজার আয়াতের মাধ্যমে শব্দের ব্যবহার দেখুন।';

  @override
  String get kavaidArapcaSozluk2 => 'Kavaid আরবি অভিধান';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'নতুন প্রজন্মের এআই (AI) সমর্থিত প্রথম আরবি অভিধান';

  @override
  String get premiumAGec => 'প্রিমিয়ামে যান';

  @override
  String get sinirsizErisim => 'আনলিমিটেড অ্যাক্সেস';

  @override
  String get profilResmiGuncellendi => '✅ প্রোফাইল ছবি আপডেট করা হয়েছে!';

  @override
  String get birHataOlustu => 'একটি ত্রুটি হয়েছে';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'ফায়ারবেস স্টোরেজ কনফিগার করা হয়নি। অনুগ্রহ করে ফায়ারবেস কনসোল থেকে স্টোরেজ সক্রিয় করুন।';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'অনুমতি ত্রুটি। স্টোরেজ রুলস চেক করুন।';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'অথরাইজেশন ত্রুটি। অনুগ্রহ করে লগ ইন করুন।';

  @override
  String get internetBaglantisiHatasi => 'ইন্টারনেট সংযোগ ত্রুটি।';

  @override
  String get detay => 'বিস্তারিত';

  @override
  String get hataDetayi => 'ত্রুটির বিবরণ';

  @override
  String get kullanici => 'ব্যবহারকারী';

  @override
  String get kurucu => 'প্রতিষ্ঠাতা';

  @override
  String get moderator => 'মডারেটর';

  @override
  String get emailYok => 'ইমেইল নেই';

  @override
  String get cikisYapilsinMi => 'লগ আউট করবেন?';

  @override
  String get oturumunuzKapatilacak => 'আপনার সেশন বন্ধ হয়ে যাবে।';

  @override
  String get cikis => 'লগ আউট';

  @override
  String get aboneligiYonet => 'সাবস্ক্রিপশন ম্যানেজ করুন';

  @override
  String get satinAlmalarKontrolEdiliyor => 'কেনাকাটা যাচাই করা হচ্ছে...';

  @override
  String get geriYukle => 'রিস্টোর করুন';

  @override
  String get girisYapinVeyaKayitOlun => 'লগ ইন বা রেজিস্টার করুন';

  @override
  String get girisYap => 'লগ ইন';

  @override
  String get kayitOl => 'রেজিস্টার করুন';

  @override
  String get premiumUyesiniz => 'আপনি একজন প্রিমিয়াম সদস্য';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'আনলিমিটেড কন্টেন্ট, বিজ্ঞাপনমুক্ত ব্যবহার।';

  @override
  String get tumOzelliklereErisin => 'সকল ফিচারে অ্যাক্সেস পান।';

  @override
  String get reklamsizKullanim => 'বিজ্ঞাপনমুক্ত ব্যবহার';

  @override
  String get uygulamayiPaylas => 'অ্যাপটি শেয়ার করুন';

  @override
  String get iletisim => 'যোগাযোগ';

  @override
  String get kavaidUygulamasiHakkinda => 'Kavaid অ্যাপ সম্পর্কে';

  @override
  String get hesabimiSil => 'আমার অ্যাকাউন্ট মুছে ফেলুন';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'আপনি কি নিশ্চিত যে আপনি আপনার অ্যাকাউন্ট এবং এর সাথে সম্পর্কিত সমস্ত ডেটা স্থায়ীভাবে মুছে ফেলতে চান? এটি আর ফেরানো যাবে না।';

  @override
  String get vazgec => 'বাতিল করুন';

  @override
  String get hesabinizBasariylaSilindi =>
      'আপনার অ্যাকাউন্ট সফলভাবে মুছে ফেলা হয়েছে।';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'অ্যাকাউন্ট মুছে ফেলা সম্ভব হয়নি: $e। নিরাপত্তার প্রয়োজনে আপনাকে পুনরায় লগ ইন করতে হতে পারে।';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi => 'Kavaid - আরবি অভিধান অ্যাপ';

  @override
  String get paylasimSirasindaBirHataOlustu =>
      'শেয়ার করার সময় একটি ত্রুটি হয়েছে';

  @override
  String get internetGerekli => 'ইন্টারনেট প্রয়োজন';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'এই কাজের জন্য ইন্টারনেট সংযোগ প্রয়োজন।';

  @override
  String get kullaniciAdiDegistir => 'ব্যবহারকারীর নাম পরিবর্তন করুন';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'বর্তমান: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'নতুন ব্যবহারকারীর নাম';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'kullaniciadi123 (ছোট হাতের অক্ষর, স্পেস ছাড়া)';

  @override
  String get enAz3KarakterSadece =>
      '• কমপক্ষে ৩ অক্ষর\n• শুধুমাত্র ছোট হাতের অক্ষর, সংখ্যা এবং ইংরেজি অক্ষর';

  @override
  String get kullaniciAdiEnAz3 => 'ব্যবহারকারীর নাম কমপক্ষে ৩ অক্ষরের হতে হবে';

  @override
  String get sadeceKucukHarfRakamVe =>
      'শুধুমাত্র ছোট হাতের অক্ষর, সংখ্যা এবং ইংরেজি অক্ষর ব্যবহার করুন';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'আপনার ব্যবহারকারীর নাম \"$newUsername\" হিসেবে আপডেট হয়েছে!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'এই ব্যবহারকারীর নাম ব্যবহার করা সম্ভব নয় বা ইতিমধ্যে ব্যবহৃত হয়েছে';

  @override
  String get degistir => 'পরিবর্তন করুন';

  @override
  String get premiumUyelikAktif => '🎉 প্রিমিয়াম মেম্বারশিপ সক্রিয় হয়েছে!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'সংযোগ করা যায়নি: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'প্রিমিয়াম কিনতে দয়া করে আগে লগইন করুন।';

  @override
  String hataE(Object e) {
    return 'ত্রুটি: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid প্রিমিয়াম';

  @override
  String get aiAsistanASinirsizErisim =>
      'AI অ্যাসিস্ট্যান্ট-এ আনলিমিটেড অ্যাক্সেস';

  @override
  String get ceviriyeSinirsizErisim => 'অনুবাদে আনলিমিটেড অ্যাক্সেস';

  @override
  String get m5500Fiilin24Siga => '৫,৫০০+ ক্রিয়ার ২৪টি রূপের তাসরীফ তালিকা';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'শেখার অংশের সব উপকরণের অ্যাক্সেস';

  @override
  String get kuranSozluguneSinirsizErisim =>
      'কুরআন অভিধানে আনলিমিটেড অ্যাক্সেস';

  @override
  String get sinirsizKelimeKartiVeListe =>
      'আনলিমিটেড ফ্ল্যাশকার্ড এবং তালিকা তৈরি';

  @override
  String get reklamsizDeneyim => 'বিজ্ঞাপনমুক্ত অভিজ্ঞতা';

  @override
  String get aylikAbonelik => 'মাসিক সাবস্ক্রিপশন';

  @override
  String get m1AyBoyuncaSinirsizErisim => '১ মাসের জন্য আনলিমিটেড অ্যাক্সেস';

  @override
  String get yillikAbonelik => 'বার্ষিক সাবস্ক্রিপশন';

  @override
  String get m1YilBoyuncaSinirsizErisim => '১ বছরের জন্য আনলিমিটেড অ্যাক্সেস';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return '১ বছরের জন্য আনলিমিটেড অ্যাক্সেস ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return '$yearlyDiscount% সাশ্রয়';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'মাসিক সাবস্ক্রাইব করুন$buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'বার্ষিক সাবস্ক্রাইব করুন$buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'পেমেন্ট আপনার Apple ID অ্যাকাউন্ট থেকে কাটা হবে। সাবস্ক্রিপশন সময়সীমা শেষ হওয়ার অন্তত ২৪ ঘণ্টা আগে বাতিল না করলে এটি স্বয়ংক্রিয়ভাবে নবায়ন হবে। আপনি যেকোনো সময় অ্যাপ স্টোর অ্যাকাউন্ট সেটিংসে গিয়ে এটি বাতিল করতে পারবেন।';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'পেমেন্ট Google Play-এর মাধ্যমে সম্পন্ন হবে। সাবস্ক্রিপশন সময়সীমা শেষ হওয়ার অন্তত ২৪ ঘণ্টা আগে বাতিল না করলে এটি স্বয়ংক্রিয়ভাবে নবায়ন হবে। আপনি যেকোনো সময় Google Play অ্যাকাউন্ট সেটিংসে গিয়ে এটি বাতিল করতে পারবেন।';

  @override
  String get satinAlmalariGeriYukle => 'ক্রয় পুনরুদ্ধার করুন';

  @override
  String get kullanimKosullariEula => 'ব্যবহারের শর্তাবলী (EULA)';

  @override
  String get gizlilikPolitikasi => 'গোপনীয়তা নীতি';

  @override
  String get metinGirin => 'টেক্সট লিখুন';

  @override
  String get harekeAc => 'হারাকাত চালু';

  @override
  String get kopyala => 'কপি করুন';

  @override
  String get kopyalandi => 'কপি করা হয়েছে';

  @override
  String get cevir => 'অনুবাদ করুন';

  @override
  String get suDileCevir => 'এই ভাষায় অনুবাদ করুন';

  @override
  String get premiumAGecin => 'প্রিমিয়ামে আপগ্রেড করুন';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'আরও অনুবাদের জন্য প্রিমিয়ামে আপগ্রেড করুন।';

  @override
  String get lutfenOnceKayitOlupGiris =>
      'দয়া করে প্রথমে সাইন আপ করে লগইন করুন।';

  @override
  String get diller => 'ভাষা';

  @override
  String get lehceler => 'উপভাষা';

  @override
  String get internetBaglantisiGerekiyor => 'ইন্টারনেট সংযোগ প্রয়োজন।';

  @override
  String get aiAsistanSuAnKullanilamiyor =>
      'AI অ্যাসিস্ট্যান্ট বর্তমানে কাজ করছে না।';

  @override
  String get yanitGelmedi => 'কোনো উত্তর পাওয়া যায়নি।';

  @override
  String get suAndaCevapAlinamadi => 'এখন উত্তর পাওয়া সম্ভব হয়নি।';

  @override
  String get hazir => 'প্রস্তুত।';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'AI শব্দ অ্যাসিস্ট্যান্টের জন্য ইন্টারনেট প্রয়োজন।';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'আজকের জন্য আপনার ফ্রি AI শব্দ অ্যাসিস্ট্যান্ট ব্যবহারের সীমা শেষ হয়েছে।';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'AI শিক্ষকের API কি (API key) ভুল। Firebase gemini_api মান চেক করুন।';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'AI শব্দ অ্যাসিস্ট্যান্ট এখন উত্তর দিতে পারছে না। পুনরায় চেষ্টা করুন।';

  @override
  String get yukleniyor => 'লোড হচ্ছে...';

  @override
  String get sozlukHazir => 'অভিধান প্রস্তুত।';

  @override
  String get sozlukYuklenemedi => 'অভিধান লোড করা যায়নি।';

  @override
  String get ekranHazirlaniyor => 'স্ক্রিন প্রস্তুত হচ্ছে...';

  @override
  String get sozlukKontrolEdiliyor => 'অভিধান যাচাই করা হচ্ছে...';

  @override
  String get sozlukAyarlaniyor => 'অভিধান প্রস্তুত হচ্ছে...';

  @override
  String get aramaHazirlaniyor => 'অনুসন্ধান প্রস্তুত করা হচ্ছে...';

  @override
  String get aramaHazir => 'অনুসন্ধান প্রস্তুত।';

  @override
  String get internetBaglantisiYok => 'ইন্টারনেট সংযোগ নেই';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'এই অ্যাপটি ব্যবহার করার জন্য ইন্টারনেট সংযোগ প্রয়োজন। অনুগ্রহ করে আপনার ওয়াইফাই (WiFi) বা মোবাইল ডেটা সংযোগ পরীক্ষা করুন।';

  @override
  String get sozlukHazirlaniyor => 'অভিধান প্রস্তুত হচ্ছে...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    return 'অভিধান প্রস্তুত। $existingCount টি শব্দ বিদ্যমান।';
  }

  @override
  String get kelimelerYukleniyor => 'শব্দগুলো লোড হচ্ছে...';

  @override
  String get sozlukHazir2 => 'অভিধান প্রস্তুত!';

  @override
  String get mevcutVeritabaniKullanilacak =>
      'বিদ্যমান ডেটাবেস ব্যবহার করা হবে।';

  @override
  String get hicGuncellenmedi => 'কখনো আপডেট করা হয়নি';

  @override
  String get girisYapmalisiniz => 'আপনাকে লগইন করতে হবে।';

  @override
  String get paketBulunamadiLifetime => 'প্যাকেজ খুঁজে পাওয়া যায়নি (লাইফটাইম)।';

  @override
  String get hataOlustu => 'একটি ত্রুটি হয়েছে';

  @override
  String beklenmedikHataE(Object e) {
    return 'অপ্রত্যাশিত ত্রুটি: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'RevenueCat চালু করা যায়নি: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris => 'কেনার জন্য আগে লগইন করুন।';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'কেনাকাটায় ত্রুটি: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'সাবস্ক্রিপশন প্যাকেজ লোড করা যায়নি। অনুগ্রহ করে ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'কেনাকাটা যাচাইয়ের জন্য ইন্টারনেট সংযোগ প্রয়োজন।';

  @override
  String get aktifBirAbonelikBulunamadi =>
      'কোনো সক্রিয় সাবস্ক্রিপশন পাওয়া যায়নি।';

  @override
  String restoreHatasiE(Object e) {
    return 'রিস্টোর করতে ত্রুটি: $e';
  }

  @override
  String get hataOlustu2 => 'একটি ত্রুটি হয়েছে।';

  @override
  String get ceviriIcinGirisYapmanGerekiyor =>
      'অনুবাদের জন্য আপনাকে লগইন করতে হবে।';

  @override
  String get premiumKullanici => 'প্রিমিয়াম ব্যবহারকারী।';

  @override
  String get ceviriHakkiKullanildi => 'অনুবাদ করার সীমা শেষ।';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'অনুবাদের সীমা যাচাই করা যায়নি। সংযোগ পরীক্ষা করুন।';

  @override
  String get yeniSohbet => 'নতুন চ্যাট';

  @override
  String get buSohbetinGecmisiSilinsinMi => 'এই চ্যাটের ইতিহাস মুছে ফেলা হবে?';

  @override
  String get aiAsistan => 'AI অ্যাসিস্ট্যান্ট';

  @override
  String get hakkinda => ' সম্পর্কে';

  @override
  String get arapcaSozlukYardimcin => 'আপনার আরবি অভিধান সহযোগী';

  @override
  String get bugunkuUcretsizSoruHakkin => 'আজকের বিনামূল্যে প্রশ্ন করার সুযোগ';

  @override
  String get arapcasiniDinle => 'আরবি উচ্চারণ শুনুন';

  @override
  String get tekrarDene2 => 'আবার চেষ্টা করুন';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    return 'আজকের $freeDailyLimit টি বিনামূল্যে প্রশ্ন করার সুযোগ শেষ';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'সুযোগ আগামীকাল রিনিউ হবে। প্রিমিয়াম ব্যবহার করে আনলিমিটেড প্রশ্ন করুন।';

  @override
  String get premiumAGec2 => 'প্রিমিয়াম-এ আপগ্রেড করুন';

  @override
  String get kisacaAnlat => 'সংক্ষেপে ব্যাখ্যা করুন';

  @override
  String get m3OrnekCumleVer => '৩টি উদাহরণ বাক্য দিন';

  @override
  String get benzerKelimelerdenFarkiNe => 'সমার্থক শব্দ থেকে পার্থক্য কী?';

  @override
  String get okunusunuLatinHarfleriyleYaz => 'লাতিন হরফে উচ্চারণ লিখুন';

  @override
  String get gecmisZamanNasilKurulur => 'অতীত কাল (মাজি) কীভাবে তৈরি হয়?';

  @override
  String get harfICerNedir => 'হরফ-ই যার (Harf-i cer) কী?';

  @override
  String get isimCumlesiNasilKurulur => 'ইসমী জুমলা কীভাবে গঠন করা যায়?';

  @override
  String get enSikKullanilan10Fiil => 'সর্বাধিক ব্যবহৃত ১০টি ক্রিয়া';

  @override
  String get sonSorduklarim => 'আমার সাম্প্রতিক প্রশ্নসমূহ';

  @override
  String get ornekSorular => 'নমুনা প্রশ্ন';

  @override
  String get buKelimeHakkindaKisaVe =>
      'এই শব্দটি সম্পর্কে সংক্ষিপ্ত ও সঠিক উত্তর পাবেন।';

  @override
  String get arapcaSorunuYaz => 'আপনার আরবি প্রশ্নটি লিখুন';

  @override
  String get kisaVeNetCevapVerir =>
      'সংক্ষিপ্ত ও সঠিক উত্তর দেয়, ভুল তথ্য দেয় না।';

  @override
  String get ornekVer => 'উদাহরণ দিন';

  @override
  String get dahaBasitAnlat => 'সহজভাবে বুঝিয়ে বলুন';

  @override
  String get derinles => 'বিস্তারিত বলুন';

  @override
  String get cekiminiGoster => 'কনজুগেশন (রূপান্তর) দেখান';

  @override
  String get aiAsistanASor => 'AI অ্যাসিস্ট্যান্টকে জিজ্ঞেস করুন...';

  @override
  String get yeniAiAsistan => 'নতুন: AI অ্যাসিস্ট্যান্ট';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'শব্দ কার্ডের বামদিকের এই আইকনে ট্যাপ করুন: এর অর্থ, সমার্থক শব্দ থেকে পার্থক্য এবং উদাহরণ বাক্য সম্পর্কে প্রশ্ন করুন।';

  @override
  String get anladim => 'বুঝতে পেরেছি';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'এই শব্দটি দিয়ে পর্যায়ক্রমে আরও উদাহরণ দিন: সহজ, মাঝারি, দৈনন্দিন ব্যবহার, ব্যাকরণ ভিত্তিক এবং প্রশ্নবোধক বাক্য।';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'আজকের ফ্রি এআই শব্দ সহায়ক ব্যবহারের সীমা শেষ। চালিয়ে যেতে প্রিমিয়াম ব্যবহার করুন।';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'এই মুহূর্তে উত্তর পাওয়া যায়নি। ইন্টারনেট সংযোগ চেক করে আবার চেষ্টা করুন।';

  @override
  String get aiKelimeAsistani => 'এআই শব্দ সহায়ক';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    return 'এআই শব্দ সহায়ক · $remaining ফ্রি সুযোগ বাকি';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi =>
      'এআই শব্দ সহায়ক প্রস্তুত করা যায়নি।';

  @override
  String get premiumAGec3 => 'প্রিমিয়াম নিন';

  @override
  String get kisacaAnlat2 => 'সংক্ষেপে ব্যাখ্যা';

  @override
  String get gramerNotlari => 'ব্যাকরণ নোট';

  @override
  String get kullanimNotlari => 'ব্যবহারের নিয়ম';

  @override
  String get buKelimeNeredeKullanilir => 'এই শব্দটি কোথায় ব্যবহৃত হয়?';

  @override
  String get m5YeniOrnekVer => '৫টি নতুন উদাহরণ দিন';

  @override
  String get kolayCumlelerleAnlat => 'সহজ বাক্যে বুঝিয়ে দিন';

  @override
  String get cekimleOrnekVer => 'রূপান্তরসহ উদাহরণ দিন';

  @override
  String get harfICerFarkiniAnlat => 'হারফে জার (Preposition) এর পার্থক্য';

  @override
  String get ornekleOgren => 'উদাহরণ দিয়ে শিখুন';

  @override
  String get miniAlistirma => 'ছোট অনুশীলন';

  @override
  String get hazirSorular => 'সাধারণ প্রশ্নাবলী';

  @override
  String get sor => 'প্রশ্ন করুন';

  @override
  String get buKelimeyleIlgiliSoruSor => 'এই শব্দ সম্পর্কে প্রশ্ন করুন';

  @override
  String get arapcaTurkceSozluk => 'আরবি-ইংরেজি অভিধান';

  @override
  String get arapcaYaDaTurkceYaz =>
      'আরবি বা ইংরেজিতে লিখুন, সব এক কার্ডে পাবেন।';

  @override
  String get sesleYaDaArapcaKlavyeyle => 'ভয়েস বা আরবি কিবোর্ডে খুঁজুন';

  @override
  String get kokCogulVeOrnekCumleler => 'মূল শব্দ, বহুবচন ও উদাহরণ';

  @override
  String get fiilKarti => 'ক্রিয়া কার্ড';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'ক্রিয়ার রূপান্তর কার্ডের ভেতরেই আছে।';

  @override
  String get maziMuzariMastarVeEmir => 'মাজি, মুজারি, মাসদার ও আমর';

  @override
  String get tumCekimlerIcinEmsileyeGec => 'সব রূপের জন্য তাসরীফ দেখুন';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'শব্দ কার্ডের বাম দিকের আইকনে ট্যাপ করুন।';

  @override
  String get sorunuYazYaDaHazir => 'প্রশ্ন লিখুন বা বেছে নিন';

  @override
  String get kisaVeNetCevap => 'সংক্ষিপ্ত ও স্পষ্ট উত্তর';

  @override
  String get m5500DenFazlaFiilin => '৫,৫০০+ ক্রিয়ার রূপান্তর টেবিল।';

  @override
  String get fiileDokunKartiAcilsin => 'ক্রিয়ায় ট্যাপ করুন, কার্ড খুলবে';

  @override
  String get anlamlariVe24SigaCekimi => 'অর্থ ও ২৪টি সিগা রূপান্তর';

  @override
  String get kurAnSozlugu => 'কুরআন অভিধান';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren => 'কুরআনের শব্দ আয়াতসহ শিখুন।';

  @override
  String get kelimeVeKurAniAnlamlari => 'শব্দ ও কুরআনিক অর্থ';

  @override
  String get gectigiAyetVeMeali => 'আয়াত ও এর অনুবাদ';

  @override
  String get lehceCeviri => 'উপভাষা অনুবাদ';

  @override
  String get turkceYazYaDaKonus =>
      'বাংলা লিখুন বা বলুন, ১৭টি উপভাষায় অনুবাদ হবে।';

  @override
  String get karsiligiVeOkunusu => 'অর্থ ও উচ্চারণ';

  @override
  String get lehceyiSecYaDaSesle => 'উপভাষা বেছে নিন বা বলে খুঁজুন';

  @override
  String get listelerVeKartlar => 'তালিকা ও কার্ড';

  @override
  String get kaydettiginHerSeyTekYerde => 'সব সেভ করা জিনিস এক জায়গায়।';

  @override
  String get listeYaDaKartlarlaTekrar => 'তালিকা বা কার্ড দিয়ে রিভিশন';

  @override
  String get sozlukKurAnVeEmsile => 'অভিধান, কুরআন ও তাসরীফ রেকর্ড';

  @override
  String get a1DenC1EResimli => 'A1 থেকে C1 লেভেলের সচিত্র আরবি গল্প।';

  @override
  String get kelimeyeDokunAnlamiCiksin => 'শব্দে ট্যাপ করুন, অর্থ দেখুন';

  @override
  String get metniSesliDinle => 'অডিও শুনুন';

  @override
  String get gec => 'এড়িয়ে যান';

  @override
  String get yeni => 'নতুন';

  @override
  String get ara => 'খুঁজুন';

  @override
  String get bosluk => 'স্পেস';

  @override
  String get hesabinizYoksaOnceKayitOlun =>
      'অ্যাকাউন্ট না থাকলে আগে সাইন আপ করুন';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'রেজিস্ট্রেশন শেষ করে লগইন করতে হবে।';

  @override
  String get ePosta => 'ইমেইল';

  @override
  String get gecersizEPostaAdresi => 'ভুল ইমেইল ঠিকানা';

  @override
  String get sifre => 'পাসওয়ার্ড';

  @override
  String get sifreGerekli => 'পাসওয়ার্ড প্রয়োজন';

  @override
  String get sifremiUnuttum => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get sifreTekrar => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get sifreTekrariGerekli => 'পাসওয়ার্ড পুনরায় দেওয়া আবশ্যক';

  @override
  String get sifrelerEslesmiyor => 'পাসওয়ার্ড মিলছে না';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'পাসওয়ার্ড রিসেট করতে প্রথমে আপনার ইমেইল ঠিকানা লিখুন।';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return '$email ঠিকানায় কোনো অ্যাকাউন্ট থাকলে, পাসওয়ার্ড রিসেট করার লিংক পাঠানো হয়েছে। আপনার ইনবক্স এবং স্প্যাম ফোল্ডার চেক করুন।';
  }

  @override
  String get gecerliBirEPostaAdresi => 'একটি সঠিক ইমেইল ঠিকানা লিখুন।';

  @override
  String get buEPostaIleKayit => 'এই ইমেইলে কোনো অ্যাকাউন্ট পাওয়া যায়নি।';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'নেটওয়ার্ক সমস্যা। আপনার ইন্টারনেট সংযোগ চেক করুন।';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'লিংক পাঠানো যায়নি। দয়া করে আবার চেষ্টা করুন।';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 স্বাগতম! আপনার অ্যাকাউন্ট সফলভাবে তৈরি হয়েছে।';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'অপারেশন ব্যর্থ হয়েছে। দয়া করে আবার চেষ্টা করুন।';

  @override
  String get ePostaVeyaSifreHatali =>
      'ইমেইল বা পাসওয়ার্ড ভুল। দয়া করে চেক করুন।';

  @override
  String get sifreHatali => 'পাসওয়ার্ড ভুল।';

  @override
  String get buEPostaZatenKayitli => 'এই ইমেইলটি ইতিমধ্যে নিবন্ধিত।';

  @override
  String get sifreCokZayifDahaGuclu =>
      'পাসওয়ার্ড খুব দুর্বল। আরও শক্তিশালী পাসওয়ার্ড ব্যবহার করুন।';

  @override
  String get buGirisYontemiProjeIcin => 'এই লগইন পদ্ধতিটি সক্রিয় নয়।';

  @override
  String get oDisil => 'সে (স্ত্রীলিঙ্গ)';

  @override
  String get ikisi => 'তারা দুইজন';

  @override
  String get ikisiEril => 'দুজন (পুং)';

  @override
  String get ikisiDisil => 'দুজন (স্ত্রী)';

  @override
  String get onlarDisil => 'তারা (স্ত্রীলিঙ্গ)';

  @override
  String get senDisil => 'তুমি (স্ত্রীলিঙ্গ)';

  @override
  String get ikiniz => 'তোমরা দুইজন';

  @override
  String get sizDisil => 'তোমরা (স্ত্রী)';

  @override
  String get m3Sahis => 'গায়ের (নামপুরুষ)';

  @override
  String get m2Sahis => 'মুখাতাব (মধ্যমপুরুষ)';

  @override
  String get m1Sahis => 'মুতাকাল্লিম (উত্তমপুরুষ)';

  @override
  String get muzari => 'মুজারি';

  @override
  String get emsileCekimleri => 'ক্রিয়ার তাসরীফ';

  @override
  String get maziGecmis => 'মাজি (অতীতকাল)';

  @override
  String get muzariGenis => 'বর্তমান';

  @override
  String get emir => 'আমির (আদেশ)';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return '$tabTitle রূপান্তর পাওয়া যায়নি';
  }

  @override
  String get kok => 'মূল (Root)';

  @override
  String get ismIFail => 'ইসমে ফায়েল';

  @override
  String get ismIMefUl => 'ইসমে মাফউল';

  @override
  String get fiilCekimleriKavaidSozluk => 'ক্রিয়া রূপান্তর • Kavaid অভিধান';

  @override
  String get m5500DenFazlaFiilin2 =>
      '৫,৫০০-এর বেশি ক্রিয়ার ২৪টি সিগার তাসরীফ শিখুন।';

  @override
  String get tumFiilleriAc => 'সব ক্রিয়া দেখুন';

  @override
  String get dahaFazlaFiilYukle => 'আরও ক্রিয়া লোড করুন';

  @override
  String get arananKelimeBulunamadi => 'শব্দটি পাওয়া যায়নি';

  @override
  String get fiilIMaziMuttasilCekimler => 'ফেল-ই মাজি — মুত্তাসিল রূপান্তর';

  @override
  String get fiilIMuzariMuttasilCekimler => 'ফেল-ই মুজারি — মুত্তাসিল রূপান্তর';

  @override
  String get emrIHazirMuttasilCekimler => 'আমর-ই হাযির — মুত্তাসিল রূপান্তর';

  @override
  String get cekimler => 'রূপান্তর';

  @override
  String get premiumIcerik => 'Premium কনটেন্ট';

  @override
  String get m5500DenFazlaFiilin3 =>
      '৫,৫০০-এর বেশি ক্রিয়ার ২৪টি সিগার তাসরীফ আনলক করুন';

  @override
  String get ucretsizFiiller => 'ফ্রি ক্রিয়া';

  @override
  String get listeyeEkle => 'তালিকায় যোগ করুন';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'AI অ্যাসিস্ট্যান্ট ব্যবহার করতে লগইন করুন।';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'এই শব্দ দিয়ে আমার লেভেলের উপযোগী ৫টি উদাহরণ দিন: সহজ থেকে কঠিন ক্রমানুসারে।';

  @override
  String get tumFiilCekimleri => 'সব ক্রিয়া রূপান্তর';

  @override
  String kokRoot(Object root) {
    return 'মূল (Root) $root';
  }

  @override
  String get cogul => 'বহুবচন';

  @override
  String get ornekCumleler => 'উদাহরণ বাক্য';

  @override
  String get cumleyiDinle => 'বাক্যটি শুনুন';

  @override
  String get aiAsistanASor2 => 'AI অ্যাসিস্ট্যান্টকে জিজ্ঞাসা করুন';

  @override
  String get dahaFazlaOrnek => 'আরও উদাহরণ';

  @override
  String get kelimeKaydetmekIcinOnceGiris => 'শব্দ সংরক্ষণ করতে আগে লগ ইন করুন';

  @override
  String get oyna => 'খেলুন';

  @override
  String get verbFormPast => 'মাজি (অতীত)';

  @override
  String get verbFormPresent => 'মুদারি';

  @override
  String get verbFormInfinitive => 'মাসদার';

  @override
  String get verbFormImperative => 'আমর (আদেশ)';

  @override
  String get zamirOEril => 'সে (পুং)';

  @override
  String get zamirOnlarEril => 'তারা (পুং)';

  @override
  String get zamirSenEril => 'তুমি (পুং)';

  @override
  String get zamirSizEril => 'তোমরা (পুং)';

  @override
  String get zamirBen => 'আমি';

  @override
  String get zamirBiz => 'আমরা';

  @override
  String get dialectTr => 'তুর্কি';

  @override
  String get dialectEn => 'ইংরেজি';

  @override
  String get dialectDe => 'জার্মান';

  @override
  String get dialectFr => 'ফরাসি';

  @override
  String get dialectRu => 'রুশ';

  @override
  String get dialectEs => 'স্প্যানিশ';

  @override
  String get dialectIt => 'ইতালীয়';

  @override
  String get dialectPt => 'পর্তুগিজ';

  @override
  String get dialectNl => 'ডাচ';

  @override
  String get dialectFa => 'ফার্সি';

  @override
  String get dialectUr => 'উর্দু';

  @override
  String get dialectId => 'ইন্দোনেশীয়';

  @override
  String get dialectArStandard => 'স্ট্যান্ডার্ড আরবি';

  @override
  String get dialectArSyrian => 'সিরীয় আরবি';

  @override
  String get dialectArLebanese => 'লেবানিজ আরবি';

  @override
  String get dialectArJordanian => 'জর্ডানীয় আরবি';

  @override
  String get dialectArPalestinian => 'ফিলিস্তিনি আরবি';

  @override
  String get dialectArEgyptian => 'মিশরীয় আরবি';

  @override
  String get dialectArIraqi => 'ইরাকি আরবি';

  @override
  String get dialectArSudanese => 'সুদানি আরবি';

  @override
  String get dialectArSaudi => 'সৌদি আরবি';

  @override
  String get dialectArEmirati => 'আমিরাতি আরবি';

  @override
  String get dialectArKuwaiti => 'কুয়েতি আরবি';

  @override
  String get dialectArQatari => 'কাতারি আরবি';

  @override
  String get dialectArOmani => 'ওমানি আরবি';

  @override
  String get dialectArYemeni => 'ইয়েমেনি আরবি';

  @override
  String get dialectArMoroccan => 'মরক্কান আরবি';

  @override
  String get dialectArAlgerian => 'আলজেরীয় আরবি';

  @override
  String get dialectArTunisian => 'তিউনিসীয় আরবি';

  @override
  String get dialectArLibyan => 'লিবিয়ান আরবি';

  @override
  String get appLanguage => 'অ্যাপের ভাষা';

  @override
  String get typeNoun => 'বিশেষ্য';

  @override
  String get typeProperNoun => 'বিশেষ নাম';

  @override
  String get typeVerb => 'ক্রিয়া';

  @override
  String get typeVerbPast => 'অতীত ক্রিয়া';

  @override
  String get typeVerbPresent => 'বর্তমান ক্রিয়া';

  @override
  String get typeVerbImperative => 'আদেশসূচক';

  @override
  String get typeVerbProhibitive => 'নিষেধসূচক';

  @override
  String get typeVerbPastPassive => 'কর্মবাচ্য অতীত';

  @override
  String get typeVerbPresentPassive => 'মুদারি মাজহুল';

  @override
  String get typeVerbDefective => 'নাকিস ক্রিয়া';

  @override
  String get typeMasdar => 'মাসদার';

  @override
  String get typeActiveParticiple => 'ইসম ফায়েল';

  @override
  String get typePassiveParticiple => 'ইসম মাফঊল';

  @override
  String get typeElative => 'ইসম তাফদিল';

  @override
  String get typeAdjective => 'বিশেষণ';

  @override
  String get typeAdverb => 'ক্রিয়া বিশেষণ';

  @override
  String get typeHal => 'হাল';

  @override
  String get typePronoun => 'সর্বনাম';

  @override
  String get typeDemonstrative => 'ইশারা';

  @override
  String get typeRelative => 'ইসম মাওসুল';

  @override
  String get typeInterrogative => 'প্রশ্নবাচক';

  @override
  String get typePreposition => 'হরফে যার';

  @override
  String get typeParticle => 'অব্যয়';

  @override
  String get typeNumber => 'সংখ্যা';

  @override
  String get typePhrase => 'বাক্যাংশ';

  @override
  String get typeExpression => 'প্রকাশ';

  @override
  String get typeIdiom => 'বাগধারা';

  @override
  String get siga01 => 'ফেল-ই মাজি';

  @override
  String get siga02 => 'ফেল-ই মুজারি';

  @override
  String get siga03 => 'মাসদার';

  @override
  String get siga04 => 'ইসমে ফায়েল';

  @override
  String get siga05 => 'ইসমে মাফউল';

  @override
  String get siga06 => 'নফি মুতলাক';

  @override
  String get siga07 => 'নফি মুস্তাকবিল';

  @override
  String get siga08 => 'নফি হাল';

  @override
  String get siga09 => 'নফি ইস্তিকবাল';

  @override
  String get siga10 => 'তাকীদ নফি';

  @override
  String get siga11 => 'আমরে গায়েব';

  @override
  String get siga12 => 'নাহি গায়েব';

  @override
  String get siga13 => 'আমরে হাজের';

  @override
  String get siga14 => 'নাহি হাজের';

  @override
  String get siga15 => 'ইসমে যরফ';

  @override
  String get siga16 => 'ইসমে আলা';

  @override
  String get siga17 => 'ইসমে মাররাহ';

  @override
  String get siga18 => 'ইসমে হাইআহ';

  @override
  String get siga19 => 'ইসমে তাসগির';

  @override
  String get siga20 => 'ইসমে মানসুব';

  @override
  String get siga21 => 'সিগায়ে মুবালাগা';

  @override
  String get siga22 => 'ইসমে তাফদিল';

  @override
  String get siga23 => 'তাআজ্জুব ১';

  @override
  String get siga24 => 'তাআজ্জুব ২';

  @override
  String get dialectMs => 'মালয়';

  @override
  String get dialectBn => 'বাংলা';

  @override
  String get dialectUz => 'উজবেক';

  @override
  String get dialectAz => 'আজারবাইজানি';

  @override
  String get prepositionsLabel => 'হরফে জারসহ';

  @override
  String get tashkeelToggle => 'হরকত';

  @override
  String get tashkeelSettingHint => 'সংজ্ঞা ও উদাহরণে হরকত দেখান';

  @override
  String get rootMatches => 'একই মূল';

  @override
  String get dictionaryLanguage => 'অভিধানের ভাষা';

  @override
  String get dictionaryLanguageHint => 'শব্দের অর্থের ভাষা';

  @override
  String get arabicArabicDictionary => 'আরবি–আরবি অভিধান';
}
