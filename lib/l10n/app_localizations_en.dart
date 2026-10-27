// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get kavaidSozluk => 'Kavaid Dictionary';

  @override
  String get tekrarDene => 'Try Again';

  @override
  String get kavaidArapcaSozluk => 'Kavaid - Arabic Dictionary';

  @override
  String get sozluk => 'Dictionary';

  @override
  String get ceviri => 'Translate';

  @override
  String get ogren => 'Learn';

  @override
  String get profil => 'Profile';

  @override
  String get kelimeBulunamadi => 'Word not found';

  @override
  String get baglantiAcilamadi => 'Could not open link';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'Congratulations! 1 month of Premium has been added to your account 🌟';

  @override
  String get gecersizVeyaKullanilmisKod => 'Invalid or used code.';

  @override
  String get buKoduDahaOnceKullandiniz => 'You have already used this code.';

  @override
  String get buKodunSuresiDolmus => 'This code has expired.';

  @override
  String get buKodunKullanimLimitiDolmus =>
      'This code has reached its usage limit.';

  @override
  String get lutfenOnceGirisYapin => 'Please log in first.';

  @override
  String get m1AyUcretsizPremiumKazan => 'Get 1 Month Free Premium';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'Quote-tweet your feedback about the app on Twitter (X) and get 1 month of free Premium!';

  @override
  String get nasilKatilirim => 'How to Participate?';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'Quote-tweet the specified tweet with your feedback about the app on Twitter (X).';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'Direct message your post to @ebubekr53 on Twitter to get your code.';

  @override
  String get koduAsagiyaGirin => 'Enter the code below.';

  @override
  String get tweetiAlintila => 'Quote Tweet';

  @override
  String get promosyonKodu => 'Promo Code';

  @override
  String get kullan => 'Apply';

  @override
  String get dahaFazlaOzellik => 'More Features';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'Upgrade to Premium\nto create more lists';

  @override
  String get kapat => 'Close';

  @override
  String get premiumAl => 'Get Premium';

  @override
  String get yeniListe => 'New List';

  @override
  String get listeAdi => 'List name';

  @override
  String get iptal => 'Cancel';

  @override
  String get olustur => 'Create';

  @override
  String get listeyiYenidenAdlandir => 'Rename List';

  @override
  String get kaydet => 'Save';

  @override
  String get kelimeListelerim => 'My Word Lists';

  @override
  String get yeniListeOlustur => 'Create New List';

  @override
  String get henuzListeYok => 'No lists yet';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'Create a list to organize\nyour words';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCount words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'Rename';

  @override
  String get sil => 'Delete';

  @override
  String get listeyiSil => 'Delete List';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return 'Delete \"$name\"?\nAll words inside will be deleted.';
  }

  @override
  String get buListedeHenuzKelimeYok => 'There are no words in this list yet.';

  @override
  String get liste => 'List';

  @override
  String get kart => 'Card';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'Upgrade to Premium for more word cards';

  @override
  String get premiumAYukselt => 'Upgrade to Premium';

  @override
  String get dinle => 'Listen';

  @override
  String get oyun => 'Game';

  @override
  String get kullanimSiniriDoldu => 'Usage Limit Reached';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'Please log in and upgrade to Premium to continue using the Quran dictionary without limits.';

  @override
  String get tamam => 'OK';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'All books have been unlocked and ads removed.';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'All books have been unlocked. Please log in to permanently remove ads.';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'Could not apply secret code: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'Updating dictionary... Please wait.';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 words',
      one: '1 word',
    );
    return 'Dictionary updated successfully! $_temp0 loaded.';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu =>
      'An error occurred while updating the dictionary!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'Database reload error: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris => 'Please log in or sign up first.';

  @override
  String get kelimeAra => 'Search word';

  @override
  String get emsile => 'Emsile';

  @override
  String get kuranSozlugu => 'Quran Dictionary';

  @override
  String get kavaidIDegerlendir => 'Rate Kavaid';

  @override
  String get gorusunBizimIcinCokDegerli =>
      'Your feedback is very valuable to us.';

  @override
  String get kuranSozluguYukleniyor => 'Loading Quran dictionary...';

  @override
  String get kuranSozlugundeAraniyor => 'Searching Quran dictionary...';

  @override
  String get araniyor => 'Searching...';

  @override
  String get kuranSozlugundeBulunamadi => 'Not found in the Quran dictionary';

  @override
  String get farkliBirKelimeVeyaKok =>
      'Try searching with a different word or root';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'Upgrade to Premium to use the Quran dictionary more.';

  @override
  String get kurAnIKerimSozlugu => 'Holy Quran Dictionary';

  @override
  String get kurAnDaGecenTum =>
      'Learn the usage and Quranic meanings of all words in the Quran, along with their verses.';

  @override
  String get kurAnDakiBenzersizTum => 'All unique words in the Quran.';

  @override
  String get kuraniAnlamlar => 'Quranic Meanings';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'Learn the meanings words take on in Quranic verses.';

  @override
  String get kurAnAyetleri => 'Quranic Verses';

  @override
  String get onBinlerceKurAnAyeti =>
      'See how words are used in the Quran with tens of thousands of verses.';

  @override
  String get kavaidArapcaSozluk2 => 'Kavaid Arabic Dictionary';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'The first next-generation AI-powered Arabic dictionary';

  @override
  String get premiumAGec => 'Upgrade to Premium';

  @override
  String get sinirsizErisim => 'Unlimited access';

  @override
  String get profilResmiGuncellendi => '✅ Profile picture updated!';

  @override
  String get birHataOlustu => 'An error occurred';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'Firebase Storage is not configured. Please enable Storage in the Firebase Console.';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'Permission error. Check Storage rules.';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'Authentication error. Please log in.';

  @override
  String get internetBaglantisiHatasi => 'Internet connection error.';

  @override
  String get detay => 'Detail';

  @override
  String get hataDetayi => 'Error Detail';

  @override
  String get kullanici => 'User';

  @override
  String get kurucu => 'FOUNDER';

  @override
  String get moderator => 'MODERATOR';

  @override
  String get emailYok => 'No email';

  @override
  String get cikisYapilsinMi => 'Log out?';

  @override
  String get oturumunuzKapatilacak => 'Your session will be closed.';

  @override
  String get cikis => 'Log out';

  @override
  String get aboneligiYonet => 'Manage Subscription';

  @override
  String get satinAlmalarKontrolEdiliyor => 'Checking purchases...';

  @override
  String get geriYukle => 'Restore';

  @override
  String get girisYapinVeyaKayitOlun => 'Log in or sign up';

  @override
  String get girisYap => 'Log In';

  @override
  String get kayitOl => 'Sign Up';

  @override
  String get premiumUyesiniz => 'You are a Premium member';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'Unlimited content, ad-free experience.';

  @override
  String get tumOzelliklereErisin => 'Access all features.';

  @override
  String get reklamsizKullanim => 'Ad-free experience';

  @override
  String get uygulamayiPaylas => 'Share App';

  @override
  String get iletisim => 'Contact';

  @override
  String get kavaidUygulamasiHakkinda => 'About Kavaid App';

  @override
  String get hesabimiSil => 'Delete Account';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.';

  @override
  String get vazgec => 'Cancel';

  @override
  String get hesabinizBasariylaSilindi =>
      'Your account has been deleted successfully.';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'Failed to delete account: $e. You may need to log in again for security reasons.';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi => 'Kavaid - Arabic Dictionary App';

  @override
  String get paylasimSirasindaBirHataOlustu =>
      'An error occurred while sharing';

  @override
  String get internetGerekli => 'Internet Required';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'An internet connection is required for this action.';

  @override
  String get kullaniciAdiDegistir => 'Change Username';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'Current: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'New Username';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'username123 (lowercase, no spaces)';

  @override
  String get enAz3KarakterSadece =>
      '• At least 3 characters\n• Lowercase letters, numbers, and Latin characters only';

  @override
  String get kullaniciAdiEnAz3 => 'Username must be at least 3 characters';

  @override
  String get sadeceKucukHarfRakamVe =>
      'Only lowercase letters, numbers, and Latin characters allowed';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'Your username has been updated to \"$newUsername\"!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'This username is unavailable or already taken';

  @override
  String get degistir => 'Change';

  @override
  String get premiumUyelikAktif => '🎉 Premium subscription active!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'Could not open link: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'Please log in first to purchase Premium.';

  @override
  String hataE(Object e) {
    return 'Error: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid Premium';

  @override
  String get aiAsistanASinirsizErisim => 'Unlimited access to AI Assistant';

  @override
  String get ceviriyeSinirsizErisim => 'Unlimited access to translation';

  @override
  String get m5500Fiilin24Siga =>
      'Unlock 24-form Emsile conjugations for 5,500+ verbs';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'Access to all study materials';

  @override
  String get kuranSozluguneSinirsizErisim =>
      'Unlimited access to Quran Dictionary';

  @override
  String get sinirsizKelimeKartiVeListe =>
      'Create unlimited flashcards and lists';

  @override
  String get reklamsizDeneyim => 'Ad-free experience';

  @override
  String get aylikAbonelik => 'Monthly Subscription';

  @override
  String get m1AyBoyuncaSinirsizErisim => 'Unlimited access for 1 month';

  @override
  String get yillikAbonelik => 'Yearly Subscription';

  @override
  String get m1YilBoyuncaSinirsizErisim => 'Unlimited access for 1 year';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return 'Unlimited access for 1 year ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return '$yearlyDiscount% OFF';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Subscribe Monthly$buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Subscribe Yearly$buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'Payment will be charged to your Apple ID account. The subscription will automatically renew unless canceled at least 24 hours before the end of the period. You can manage and cancel in your App Store Account Settings.';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'Payment will be charged via Google Play. The subscription will automatically renew unless canceled at least 24 hours before the end of the period. You can manage and cancel in your Google Play Account Settings.';

  @override
  String get satinAlmalariGeriYukle => 'Restore Purchases';

  @override
  String get kullanimKosullariEula => 'Terms of Use (EULA)';

  @override
  String get gizlilikPolitikasi => 'Privacy Policy';

  @override
  String get metinGirin => 'Enter text';

  @override
  String get harekeAc => 'Show diacritics';

  @override
  String get kopyala => 'Copy';

  @override
  String get kopyalandi => 'Copied';

  @override
  String get cevir => 'Translate';

  @override
  String get suDileCevir => 'Translate to';

  @override
  String get premiumAGecin => 'Go Premium';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'Upgrade to Premium for more translations.';

  @override
  String get lutfenOnceKayitOlupGiris => 'Please log in or sign up first';

  @override
  String get diller => 'Languages';

  @override
  String get lehceler => 'Dialects';

  @override
  String get internetBaglantisiGerekiyor => 'Internet connection required.';

  @override
  String get aiAsistanSuAnKullanilamiyor =>
      'AI assistant is currently unavailable.';

  @override
  String get yanitGelmedi => 'No response received.';

  @override
  String get suAndaCevapAlinamadi => 'Could not get an answer right now.';

  @override
  String get hazir => 'Ready.';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'Internet connection required for AI Word Assistant.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'You have reached your daily limit for the free AI Word Assistant.';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'AI Teacher API key is invalid. Check Firebase gemini_api value.';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'AI Word Assistant could not respond right now. Please try again.';

  @override
  String get yukleniyor => 'Loading...';

  @override
  String get sozlukHazir => 'Dictionary ready.';

  @override
  String get sozlukYuklenemedi => 'Dictionary could not be loaded.';

  @override
  String get ekranHazirlaniyor => 'Preparing screen...';

  @override
  String get sozlukKontrolEdiliyor => 'Checking dictionary...';

  @override
  String get sozlukAyarlaniyor => 'Setting up dictionary...';

  @override
  String get aramaHazirlaniyor => 'Preparing search...';

  @override
  String get aramaHazir => 'Search is ready.';

  @override
  String get internetBaglantisiYok => 'No Internet Connection';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'You need an internet connection to use the app. Please check your WiFi or mobile data connection.';

  @override
  String get sozlukHazirlaniyor => 'Preparing dictionary...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    String _temp0 = intl.Intl.pluralLogic(
      existingCount,
      locale: localeName,
      other: '$existingCount words available',
      one: '1 word available',
    );
    return 'Dictionary ready. $_temp0.';
  }

  @override
  String get kelimelerYukleniyor => 'Loading words...';

  @override
  String get sozlukHazir2 => 'Dictionary ready!';

  @override
  String get mevcutVeritabaniKullanilacak => 'Using existing database.';

  @override
  String get hicGuncellenmedi => 'Never updated';

  @override
  String get girisYapmalisiniz => 'You must be signed in.';

  @override
  String get paketBulunamadiLifetime => 'Package not found (Lifetime).';

  @override
  String get hataOlustu => 'An error occurred';

  @override
  String beklenmedikHataE(Object e) {
    return 'Unexpected error: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'Could not initialize RevenueCat: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris => 'Please sign in to make a purchase.';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'Purchase error: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'Subscription package could not be loaded. Please check your internet connection and try again.';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'Internet connection required to verify purchase.';

  @override
  String get aktifBirAbonelikBulunamadi => 'No active subscription found.';

  @override
  String restoreHatasiE(Object e) {
    return 'Restore error: $e';
  }

  @override
  String get hataOlustu2 => 'An error occurred.';

  @override
  String get ceviriIcinGirisYapmanGerekiyor =>
      'You need to sign in to translate.';

  @override
  String get premiumKullanici => 'Premium user.';

  @override
  String get ceviriHakkiKullanildi => 'Translation credit used.';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'Could not check translation limit. Check your connection.';

  @override
  String get yeniSohbet => 'New chat';

  @override
  String get buSohbetinGecmisiSilinsinMi => 'Delete this chat history?';

  @override
  String get aiAsistan => 'AI Assistant';

  @override
  String get hakkinda => ' about';

  @override
  String get arapcaSozlukYardimcin => 'Your Arabic dictionary assistant';

  @override
  String get bugunkuUcretsizSoruHakkin => 'Your daily free questions';

  @override
  String get arapcasiniDinle => 'Listen to Arabic';

  @override
  String get tekrarDene2 => 'Try again';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    String _temp0 = intl.Intl.pluralLogic(
      freeDailyLimit,
      locale: localeName,
      other: 'daily free question limit of $freeDailyLimit',
      one: 'daily free question limit of 1',
    );
    return 'Your $_temp0 has been reached.';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'Your limit resets tomorrow. Get Premium for unlimited questions.';

  @override
  String get premiumAGec2 => 'Go Premium';

  @override
  String get kisacaAnlat => 'Explain briefly';

  @override
  String get m3OrnekCumleVer => 'Give 3 example sentences';

  @override
  String get benzerKelimelerdenFarkiNe =>
      'How does it differ from similar words?';

  @override
  String get okunusunuLatinHarfleriyleYaz =>
      'Write pronunciation in Latin letters';

  @override
  String get gecmisZamanNasilKurulur => 'How to form the past tense?';

  @override
  String get harfICerNedir => 'What is a preposition?';

  @override
  String get isimCumlesiNasilKurulur => 'How to form a nominal sentence?';

  @override
  String get enSikKullanilan10Fiil => '10 most common verbs';

  @override
  String get sonSorduklarim => 'Recent questions';

  @override
  String get ornekSorular => 'Example questions';

  @override
  String get buKelimeHakkindaKisaVe =>
      'Get a short and clear answer about this word.';

  @override
  String get arapcaSorunuYaz => 'Ask your Arabic question';

  @override
  String get kisaVeNetCevapVerir =>
      'Gives short, clear answers; doesn\'t make things up.';

  @override
  String get ornekVer => 'Give an example';

  @override
  String get dahaBasitAnlat => 'Explain more simply';

  @override
  String get derinles => 'Go deeper';

  @override
  String get cekiminiGoster => 'Show conjugation';

  @override
  String get aiAsistanASor => 'Ask AI Assistant...';

  @override
  String get yeniAiAsistan => 'New: AI Assistant';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'Tap the icon on the far left of the word card to ask about its meaning, compare it to synonyms, or get example sentences.';

  @override
  String get anladim => 'Got it';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'Give more examples for this word by level: easy, medium, everyday usage, grammar-focused, and question sentences.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'You\'ve used up your free AI Word Assistant quota for today. Upgrade to Premium to continue.';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'Could not get a response right now. Please check your internet connection and try again.';

  @override
  String get aiKelimeAsistani => 'AI Word Assistant';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining free credits',
      one: '1 free credit',
    );
    return 'AI Word Assistant · $_temp0';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi =>
      'AI Word Assistant could not be initialized.';

  @override
  String get premiumAGec3 => 'Upgrade to Premium';

  @override
  String get kisacaAnlat2 => 'Explain Briefly';

  @override
  String get gramerNotlari => 'Grammar Notes';

  @override
  String get kullanimNotlari => 'Usage Notes';

  @override
  String get buKelimeNeredeKullanilir => 'How is this word used?';

  @override
  String get m5YeniOrnekVer => 'Give 5 new examples';

  @override
  String get kolayCumlelerleAnlat => 'Explain with simple sentences';

  @override
  String get cekimleOrnekVer => 'Give example with conjugation';

  @override
  String get harfICerFarkiniAnlat => 'Explain preposition differences';

  @override
  String get ornekleOgren => 'Learn with Examples';

  @override
  String get miniAlistirma => 'Mini Exercise';

  @override
  String get hazirSorular => 'Suggested Questions';

  @override
  String get sor => 'Ask';

  @override
  String get buKelimeyleIlgiliSoruSor => 'Ask a question about this word';

  @override
  String get arapcaTurkceSozluk => 'Arabic–English Dictionary';

  @override
  String get arapcaYaDaTurkceYaz =>
      'Type in Arabic or English; everything is on one card.';

  @override
  String get sesleYaDaArapcaKlavyeyle => 'Search by voice or Arabic keyboard';

  @override
  String get kokCogulVeOrnekCumleler => 'Root, plural, and example sentences';

  @override
  String get fiilKarti => 'Verb Card';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'Verb conjugations are inside the card.';

  @override
  String get maziMuzariMastarVeEmir =>
      'Past, present, verbal noun, and imperative';

  @override
  String get tumCekimlerIcinEmsileyeGec => 'See Emsile for all conjugations';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'Tap the icon on the far left of the word card.';

  @override
  String get sorunuYazYaDaHazir => 'Write your question or select one';

  @override
  String get kisaVeNetCevap => 'Short and clear answer';

  @override
  String get m5500DenFazlaFiilin => 'Conjugation tables for over 5,500 verbs.';

  @override
  String get fiileDokunKartiAcilsin => 'Tap a verb to open its card';

  @override
  String get anlamlariVe24SigaCekimi => 'Meanings and 24-form conjugation';

  @override
  String get kurAnSozlugu => 'Quran Dictionary';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'Learn Quranic vocabulary through verses.';

  @override
  String get kelimeVeKurAniAnlamlari => 'Word and Quranic meanings';

  @override
  String get gectigiAyetVeMeali => 'Verse and translation';

  @override
  String get lehceCeviri => 'Dialect Translation';

  @override
  String get turkceYazYaDaKonus =>
      'Type or speak in English, translate to 17 dialects.';

  @override
  String get karsiligiVeOkunusu => 'Translation and pronunciation';

  @override
  String get lehceyiSecYaDaSesle => 'Select dialect or use voice';

  @override
  String get listelerVeKartlar => 'Lists and Cards';

  @override
  String get kaydettiginHerSeyTekYerde =>
      'Everything you save is in one place.';

  @override
  String get listeYaDaKartlarlaTekrar => 'Review with lists or cards';

  @override
  String get sozlukKurAnVeEmsile => 'Dictionary, Quran, and Emsile entries';

  @override
  String get a1DenC1EResimli => 'Illustrated Arabic stories from A1 to C1.';

  @override
  String get kelimeyeDokunAnlamiCiksin => 'Tap a word to see its meaning';

  @override
  String get metniSesliDinle => 'Listen to the text';

  @override
  String get gec => 'Skip';

  @override
  String get yeni => 'NEW';

  @override
  String get ara => 'Search';

  @override
  String get bosluk => 'Space';

  @override
  String get hesabinizYoksaOnceKayitOlun =>
      'Sign up first if you don\'t have an account';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'You need to log in after signing up.';

  @override
  String get ePosta => 'Email';

  @override
  String get gecersizEPostaAdresi => 'Invalid email address';

  @override
  String get sifre => 'Password';

  @override
  String get sifreGerekli => 'Password required';

  @override
  String get sifremiUnuttum => 'Forgot password?';

  @override
  String get sifreTekrar => 'Confirm Password';

  @override
  String get sifreTekrariGerekli => 'Confirm password required';

  @override
  String get sifrelerEslesmiyor => 'Passwords do not match';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'Enter your email address to reset your password.';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return 'If an account exists for $email, a password reset link has been sent. Please check your inbox and spam folder.';
  }

  @override
  String get gecerliBirEPostaAdresi => 'Enter a valid email address.';

  @override
  String get buEPostaIleKayit => 'No account found with this email.';

  @override
  String get cokFazlaDenemeYapildiBir => 'Too many attempts. Try again later.';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'Network error. Please check your connection.';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'Could not send the link. Please try again.';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 Welcome! Your account has been successfully created.';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'Something went wrong. Please try again.';

  @override
  String get ePostaVeyaSifreHatali =>
      'Incorrect email or password. Please check.';

  @override
  String get sifreHatali => 'Incorrect password.';

  @override
  String get buEPostaZatenKayitli => 'This email is already registered.';

  @override
  String get sifreCokZayifDahaGuclu =>
      'Password is too weak. Choose a stronger one.';

  @override
  String get buGirisYontemiProjeIcin => 'This login method is not enabled.';

  @override
  String get oDisil => 'She';

  @override
  String get ikisi => 'They (dual)';

  @override
  String get ikisiEril => 'They (dual, masc.)';

  @override
  String get ikisiDisil => 'They (dual, fem.)';

  @override
  String get onlarDisil => 'They (fem.)';

  @override
  String get senDisil => 'You (fem.)';

  @override
  String get ikiniz => 'You (dual)';

  @override
  String get sizDisil => 'You (fem. pl.)';

  @override
  String get m3Sahis => 'غَائِب (3rd person)';

  @override
  String get m2Sahis => 'مُخَاطَب (2nd person)';

  @override
  String get m1Sahis => 'مُتَكَلِّم (1st person)';

  @override
  String get muzari => 'Present';

  @override
  String get emsileCekimleri => 'Emsile Conjugations';

  @override
  String get maziGecmis => 'Past';

  @override
  String get muzariGenis => 'Present';

  @override
  String get emir => 'Imperative';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return '$tabTitle conjugation not found';
  }

  @override
  String get kok => 'Root';

  @override
  String get ismIFail => 'Act. Part.';

  @override
  String get ismIMefUl => 'Pass. Part.';

  @override
  String get fiilCekimleriKavaidSozluk =>
      'Verb Conjugations • Kavaid Dictionary';

  @override
  String get m5500DenFazlaFiilin2 =>
      'Learn Emsile conjugations for over 5,500 verbs across 24 forms.';

  @override
  String get tumFiilleriAc => 'Unlock all verbs';

  @override
  String get dahaFazlaFiilYukle => 'Load more verbs';

  @override
  String get arananKelimeBulunamadi => 'Word not found';

  @override
  String get fiilIMaziMuttasilCekimler => 'Past Tense — Connected Conjugations';

  @override
  String get fiilIMuzariMuttasilCekimler =>
      'Present Tense — Connected Conjugations';

  @override
  String get emrIHazirMuttasilCekimler => 'Imperative — Connected Conjugations';

  @override
  String get cekimler => 'Conjugations';

  @override
  String get premiumIcerik => 'Premium Content';

  @override
  String get m5500DenFazlaFiilin3 =>
      'Unlock Emsile conjugations for over 5,500 verbs across 24 forms';

  @override
  String get ucretsizFiiller => 'Free Verbs';

  @override
  String get listeyeEkle => 'Add to List';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'Please log in to use the AI assistant.';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'Give me 5 examples with this word suitable for my level, from easiest to hardest.';

  @override
  String get tumFiilCekimleri => 'Full Verb Conjugations';

  @override
  String kokRoot(Object root) {
    return 'root $root';
  }

  @override
  String get cogul => 'Plural';

  @override
  String get ornekCumleler => 'Example Sentences';

  @override
  String get cumleyiDinle => 'Listen to sentence';

  @override
  String get aiAsistanASor2 => 'Ask AI assistant';

  @override
  String get dahaFazlaOrnek => 'More examples';

  @override
  String get kelimeKaydetmekIcinOnceGiris => 'Log in to save words';

  @override
  String get oyna => 'Play';

  @override
  String get verbFormPast => 'Past';

  @override
  String get verbFormPresent => 'Present';

  @override
  String get verbFormInfinitive => 'Infinitive';

  @override
  String get verbFormImperative => 'Imperative';

  @override
  String get zamirOEril => 'He';

  @override
  String get zamirOnlarEril => 'They (masc.)';

  @override
  String get zamirSenEril => 'You (masc.)';

  @override
  String get zamirSizEril => 'You (masc. pl.)';

  @override
  String get zamirBen => 'I';

  @override
  String get zamirBiz => 'We';

  @override
  String get dialectTr => 'Turkish';

  @override
  String get dialectEn => 'English';

  @override
  String get dialectDe => 'German';

  @override
  String get dialectFr => 'French';

  @override
  String get dialectRu => 'Russian';

  @override
  String get dialectEs => 'Spanish';

  @override
  String get dialectIt => 'Italian';

  @override
  String get dialectPt => 'Portuguese';

  @override
  String get dialectNl => 'Dutch';

  @override
  String get dialectFa => 'Persian';

  @override
  String get dialectUr => 'Urdu';

  @override
  String get dialectId => 'Indonesian';

  @override
  String get dialectArStandard => 'Modern Standard Arabic';

  @override
  String get dialectArSyrian => 'Syrian Arabic';

  @override
  String get dialectArLebanese => 'Lebanese Arabic';

  @override
  String get dialectArJordanian => 'Jordanian Arabic';

  @override
  String get dialectArPalestinian => 'Palestinian Arabic';

  @override
  String get dialectArEgyptian => 'Egyptian Arabic';

  @override
  String get dialectArIraqi => 'Iraqi Arabic';

  @override
  String get dialectArSudanese => 'Sudanese Arabic';

  @override
  String get dialectArSaudi => 'Saudi Arabic';

  @override
  String get dialectArEmirati => 'Emirati Arabic';

  @override
  String get dialectArKuwaiti => 'Kuwaiti Arabic';

  @override
  String get dialectArQatari => 'Qatari Arabic';

  @override
  String get dialectArOmani => 'Omani Arabic';

  @override
  String get dialectArYemeni => 'Yemeni Arabic';

  @override
  String get dialectArMoroccan => 'Moroccan Arabic';

  @override
  String get dialectArAlgerian => 'Algerian Arabic';

  @override
  String get dialectArTunisian => 'Tunisian Arabic';

  @override
  String get dialectArLibyan => 'Libyan Arabic';

  @override
  String get appLanguage => 'App language';

  @override
  String get typeNoun => 'noun';

  @override
  String get typeProperNoun => 'proper noun';

  @override
  String get typeVerb => 'verb';

  @override
  String get typeVerbPast => 'past verb';

  @override
  String get typeVerbPresent => 'present verb';

  @override
  String get typeVerbImperative => 'imperative';

  @override
  String get typeVerbProhibitive => 'prohibitive';

  @override
  String get typeVerbPastPassive => 'past passive';

  @override
  String get typeVerbPresentPassive => 'pres. passive';

  @override
  String get typeVerbDefective => 'defective verb';

  @override
  String get typeMasdar => 'verbal noun';

  @override
  String get typeActiveParticiple => 'act. part.';

  @override
  String get typePassiveParticiple => 'pass. part.';

  @override
  String get typeElative => 'elative';

  @override
  String get typeAdjective => 'adjective';

  @override
  String get typeAdverb => 'adverb';

  @override
  String get typeHal => 'ḥāl';

  @override
  String get typePronoun => 'pronoun';

  @override
  String get typeDemonstrative => 'demonstrative';

  @override
  String get typeRelative => 'relative';

  @override
  String get typeInterrogative => 'interrogative';

  @override
  String get typePreposition => 'preposition';

  @override
  String get typeParticle => 'particle';

  @override
  String get typeNumber => 'number';

  @override
  String get typePhrase => 'phrase';

  @override
  String get typeExpression => 'expression';

  @override
  String get typeIdiom => 'idiom';

  @override
  String get siga01 => 'Past Tense';

  @override
  String get siga02 => 'Present Tense';

  @override
  String get siga03 => 'Verbal Noun';

  @override
  String get siga04 => 'Active Part.';

  @override
  String get siga05 => 'Passive Part.';

  @override
  String get siga06 => 'Neg. Past';

  @override
  String get siga07 => 'Neg. Perfect';

  @override
  String get siga08 => 'Neg. Present';

  @override
  String get siga09 => 'Neg. Future';

  @override
  String get siga10 => 'Emph. Neg. Fut.';

  @override
  String get siga11 => '3rd-Per. Command';

  @override
  String get siga12 => '3rd-Per. Prohib.';

  @override
  String get siga13 => 'Imperative';

  @override
  String get siga14 => 'Prohibition';

  @override
  String get siga15 => 'Noun of Time/Pl.';

  @override
  String get siga16 => 'Noun of Instr.';

  @override
  String get siga17 => 'Noun of Once';

  @override
  String get siga18 => 'Noun of Manner';

  @override
  String get siga19 => 'Diminutive';

  @override
  String get siga20 => 'Relative Adj.';

  @override
  String get siga21 => 'Int. Act. Part.';

  @override
  String get siga22 => 'Elative';

  @override
  String get siga23 => 'Exclamation 1';

  @override
  String get siga24 => 'Exclamation 2';

  @override
  String get dialectMs => 'Malay';

  @override
  String get dialectBn => 'Bengali';

  @override
  String get dialectUz => 'Uzbek';

  @override
  String get dialectAz => 'Azerbaijani';

  @override
  String get prepositionsLabel => 'With Prepositions';

  @override
  String get tashkeelToggle => 'Vowel marks';

  @override
  String get tashkeelSettingHint =>
      'Show vowel marks in definitions and examples';

  @override
  String get rootMatches => 'Same root';

  @override
  String get dictionaryLanguage => 'Dictionary language';

  @override
  String get dictionaryLanguageHint => 'Language of word meanings';

  @override
  String get arabicArabicDictionary => 'Arabic–Arabic dictionary';
}
