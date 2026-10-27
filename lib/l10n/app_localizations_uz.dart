// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get kavaidSozluk => 'Kavaid Lug\'ati';

  @override
  String get tekrarDene => 'Qayta urinish';

  @override
  String get kavaidArapcaSozluk => 'Kavaid - Arabcha lug\'at';

  @override
  String get sozluk => 'Lug\'at';

  @override
  String get ceviri => 'Tarjima';

  @override
  String get ogren => 'O\'rganish';

  @override
  String get profil => 'Profil';

  @override
  String get kelimeBulunamadi => 'So\'z topilmadi';

  @override
  String get baglantiAcilamadi => 'Havolani ochib bo\'lmadi';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'Tabriklaymiz! 1 oylik Premium hisobingizga qo\'shildi 🌟';

  @override
  String get gecersizVeyaKullanilmisKod =>
      'Kod noto\'g\'ri yoki allaqachon ishlatilgan.';

  @override
  String get buKoduDahaOnceKullandiniz => 'Siz bu kodni avval ishlatgansiz.';

  @override
  String get buKodunSuresiDolmus => 'Bu kodning muddati o\'tgan.';

  @override
  String get buKodunKullanimLimitiDolmus =>
      'Bu kodning foydalanish limiti tugagan.';

  @override
  String get lutfenOnceGirisYapin => 'Iltimos, avval kiring.';

  @override
  String get m1AyUcretsizPremiumKazan => '1 Oylik Bepul Premium Yutib Oling';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'Ilova haqidagi fikrlaringizni ko\'rsatilgan tvitni iqtibos qilib Twitter (X) da baham ko\'ring va 1 oylik bepul Premium yutib oling!';

  @override
  String get nasilKatilirim => 'Qanday qatnashaman?';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'Ilova haqidagi fikrlaringizni ko\'rsatilgan tvitni iqtibos qilib Twitter (X) da baham ko\'ring.';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'Ulashgan postingizni Twitter\'da @ebubekr53 hisobiga to\'g\'ridan-to\'g\'ri xabar (DM) qilib yuboring va kodingizni oling.';

  @override
  String get koduAsagiyaGirin => 'Kodini pastga kiriting.';

  @override
  String get tweetiAlintila => 'Tvitni iqtibos qilish';

  @override
  String get promosyonKodu => 'Promokod';

  @override
  String get kullan => 'Ishlatish';

  @override
  String get dahaFazlaOzellik => 'Ko\'proq funksiyalar';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'Ko\'proq ro\'yxat yaratish uchun\nPremium\'ga o\'ting';

  @override
  String get kapat => 'Yopish';

  @override
  String get premiumAl => 'Premium olish';

  @override
  String get yeniListe => 'Yangi ro\'yxat';

  @override
  String get listeAdi => 'Ro\'yxat nomi';

  @override
  String get iptal => 'Bekor qilish';

  @override
  String get olustur => 'Yaratish';

  @override
  String get listeyiYenidenAdlandir => 'Ro\'yxatni qayta nomlash';

  @override
  String get kaydet => 'Saqlash';

  @override
  String get kelimeListelerim => 'So\'z ro\'yxatlarim';

  @override
  String get yeniListeOlustur => 'Yangi ro\'yxat yaratish';

  @override
  String get henuzListeYok => 'Hali ro\'yxat yo\'q';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'So\'zlaringizni tartiblash uchun\nbir ro\'yxat yarating';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCount so\'z',
      one: '$wordCount so\'z',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'Qayta nomlash';

  @override
  String get sil => 'O\'chirish';

  @override
  String get listeyiSil => 'Ro\'yxatni o\'chirish';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return '\"$name\" o\'chirilsinmi?\nIchidagi barcha so\'zlar ham o\'chiriladi.';
  }

  @override
  String get buListedeHenuzKelimeYok => 'Bu ro\'yxatda hali so\'z yo\'q';

  @override
  String get liste => 'Ro\'yxat';

  @override
  String get kart => 'Karta';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'Ko\'proq so\'z kartalari uchun Premium\'ga o\'ting';

  @override
  String get premiumAYukselt => 'Premium\'ga o\'ting';

  @override
  String get dinle => 'Eshitish';

  @override
  String get oyun => 'O\'yin';

  @override
  String get kullanimSiniriDoldu => 'Foydalanish limiti tugadi';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'Qur\'on lug\'atidan cheksiz foydalanishni davom ettirish uchun iltimos kiring va Premium\'ga o\'ting.';

  @override
  String get tamam => 'OK';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'Barcha kitoblar ochildi va reklamalar olib tashlandi.';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'Barcha kitoblar ochildi. Reklamlarni doimiy o\'chirish uchun iltimos kiring.';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'Maxfiy kodni qo\'llab bo\'lmadi: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'Lug\'at yangilanmoqda... Iltimos kuting.';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    return 'Lug\'at muvaffaqiyatli yangilandi! $p1 ta so\'z yuklandi.';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu =>
      'Lug\'at yangilanayotganda xatolik yuz berdi!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'Ma\'lumotlar bazasini qayta yuklashda xatolik: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris =>
      'Iltimos, avval ro‘yxatdan o‘ting yoki kiring.';

  @override
  String get kelimeAra => 'So‘z qidirish';

  @override
  String get emsile => 'Emsile';

  @override
  String get kuranSozlugu => 'Qur’on lug‘ati';

  @override
  String get kavaidIDegerlendir => 'Kavaid’ni baholang';

  @override
  String get gorusunBizimIcinCokDegerli => 'Fikringiz biz uchun juda qadrli.';

  @override
  String get kuranSozluguYukleniyor => 'Qur’on lug‘ati yuklanmoqda...';

  @override
  String get kuranSozlugundeAraniyor => 'Qur’on lug‘atidan qidirilmoqda...';

  @override
  String get araniyor => 'Qidirilmoqda...';

  @override
  String get kuranSozlugundeBulunamadi => 'Qur’on lug‘atidan topilmadi';

  @override
  String get farkliBirKelimeVeyaKok =>
      'Boshqa so‘z yoki o‘zak bilan qidirib ko‘ring';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'Qur’on lug‘atidan ko‘proq foydalanish uchun Premium’ga o‘ting.';

  @override
  String get kurAnIKerimSozlugu => 'Qur’oni Karim lug‘ati';

  @override
  String get kurAnDaGecenTum =>
      'Qur’onda o‘tgan barcha so‘zlarning qo‘llanilishi va Qur’oniy ma’nolarini oyatlar bilan birga o‘rganing.';

  @override
  String get kurAnDakiBenzersizTum => 'Qur’ondagi barcha noyob so‘zlar.';

  @override
  String get kuraniAnlamlar => 'Qur’oniy ma’nolar';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'So‘zlarning Qur’on oyatlarida kasb etgan ma’nolarini o‘rganing.';

  @override
  String get kurAnAyetleri => 'Qur’on oyatlari';

  @override
  String get onBinlerceKurAnAyeti =>
      'O‘n minglab Qur’on oyatlari bilan so‘zlarning Qur’ondagi ishlatilishini ko‘ring.';

  @override
  String get kavaidArapcaSozluk2 => 'Kavaid Arab tili lug‘ati';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'Yangi avlod sun’iy intellekt yordamchi birinchi arab tili lug‘ati';

  @override
  String get premiumAGec => 'Premium’ga o‘tish';

  @override
  String get sinirsizErisim => 'Cheksiz kirish';

  @override
  String get profilResmiGuncellendi => '✅ Profil rasmi yangilandi!';

  @override
  String get birHataOlustu => 'Xatolik yuz berdi';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'Firebase Storage sozlanmagan. Iltimos, Firebase Console\'dan Storage\'ni faollashtiring.';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'Ruxsat xatosi. Storage qoidalarini tekshiring.';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'Autentifikatsiya xatosi. Iltimos, kiring.';

  @override
  String get internetBaglantisiHatasi => 'Internet aloqasi xatosi.';

  @override
  String get detay => 'Tafsilot';

  @override
  String get hataDetayi => 'Xato tafsiloti';

  @override
  String get kullanici => 'Foydalanuvchi';

  @override
  String get kurucu => 'ASISCHILAR';

  @override
  String get moderator => 'MODERATOR';

  @override
  String get emailYok => 'Email mavjud emas';

  @override
  String get cikisYapilsinMi => 'Chiqib ketilsinmi?';

  @override
  String get oturumunuzKapatilacak => 'Sessiyangiz yopiladi.';

  @override
  String get cikis => 'Chiqish';

  @override
  String get aboneligiYonet => 'Obunani boshqarish';

  @override
  String get satinAlmalarKontrolEdiliyor => 'Xaridlar tekshirilmoqda...';

  @override
  String get geriYukle => 'Qayta tiklash';

  @override
  String get girisYapinVeyaKayitOlun => 'Kiring yoki ro‘yxatdan o‘ting';

  @override
  String get girisYap => 'Kirish';

  @override
  String get kayitOl => 'Ro‘yxatdan o‘tish';

  @override
  String get premiumUyesiniz => 'Premium a’zosiz';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'Cheksiz kontent, reklamasiz foydalanish.';

  @override
  String get tumOzelliklereErisin => 'Barcha imkoniyatlardan foydalaning.';

  @override
  String get reklamsizKullanim => 'Reklamasiz foydalanish';

  @override
  String get uygulamayiPaylas => 'Ilovani ulashish';

  @override
  String get iletisim => 'Bog‘lanish';

  @override
  String get kavaidUygulamasiHakkinda => 'Kavaid ilovasi haqida';

  @override
  String get hesabimiSil => 'Hisobni o‘chirish';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'Hisobingizni va u bilan bog‘liq barcha ma’lumotlarni butunlay o‘chirib tashlamoqchimisiz? Bu amalni bekor qilib bo‘lmaydi.';

  @override
  String get vazgec => 'Bekor qilish';

  @override
  String get hesabinizBasariylaSilindi =>
      'Hisobingiz muvaffaqiyatli o‘chirildi.';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'Hisob o‘chirilmadi: $e. Xavfsizlik nuqtai nazaridan qayta kirishingiz kerak bo‘lishi mumkin.';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi =>
      'Kavaid - Arab tili lug‘ati ilovasi';

  @override
  String get paylasimSirasindaBirHataOlustu =>
      'Ulashish jarayonida xatolik yuz berdi';

  @override
  String get internetGerekli => 'Internet zarur';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'Ushbu amal uchun internet aloqasi zarur.';

  @override
  String get kullaniciAdiDegistir => 'Foydalanuvchi nomini o‘zgartirish';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'Joriy: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'Yangi foydalanuvchi nomi';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'foydalanuvchi123 (kichik harflar, bo‘shliqsiz)';

  @override
  String get enAz3KarakterSadece =>
      '• Kamida 3 ta belgi\n• Faqat kichik harflar, raqamlar va belgilangan belgilar';

  @override
  String get kullaniciAdiEnAz3 =>
      'Foydalanuvchi nomi kamida 3 ta belgidan iborat bo‘lishi kerak';

  @override
  String get sadeceKucukHarfRakamVe =>
      'Faqat kichik harflar va raqamlardan foydalaning';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'Foydalanuvchi nomingiz \"$newUsername\" deb yangilandi!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'Bu foydalanuvchi nomi band yoki foydalanib bo‘lmaydi';

  @override
  String get degistir => 'O‘zgartirish';

  @override
  String get premiumUyelikAktif => '🎉 Premium a’zolik faol!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'Ulanishda xatolik: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'Premium sotib olish uchun avval tizimga kiring.';

  @override
  String hataE(Object e) {
    return 'Xatolik: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid Premium';

  @override
  String get aiAsistanASinirsizErisim => 'AI yordamchisiga cheksiz kirish';

  @override
  String get ceviriyeSinirsizErisim => 'Tarjimalarga cheksiz kirish';

  @override
  String get m5500Fiilin24Siga => '5500+ fe’lning 24 ta Emsile shaklini ochish';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'O‘rganish bo‘limidagi barcha materiallarga kirish';

  @override
  String get kuranSozluguneSinirsizErisim => 'Qur’on lug‘atiga cheksiz kirish';

  @override
  String get sinirsizKelimeKartiVeListe =>
      'Cheksiz so‘z kartalari va ro‘yxatlari';

  @override
  String get reklamsizDeneyim => 'Reklamsiz foydalanish';

  @override
  String get aylikAbonelik => 'Oylik obuna';

  @override
  String get m1AyBoyuncaSinirsizErisim => '1 oy davomida cheksiz kirish';

  @override
  String get yillikAbonelik => 'Yillik obuna';

  @override
  String get m1YilBoyuncaSinirsizErisim => '1 yil davomida cheksiz kirish';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return '1 yil davomida cheksiz kirish ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return '$yearlyDiscount% ARZONROQ';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Oylik obuna bo‘lish $buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Yillik obuna bo‘lish $buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'To‘lov Apple ID hisobingizdan olinadi. Obuna muddati tugashidan kamida 24 soat oldin bekor qilinmasa, u avtomatik tarzda uzaytiriladi. App Store hisob sozlamalaridan istalgan vaqtda bekor qilishingiz mumkin.';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'To‘lov Google Play orqali olinadi. Obuna muddati tugashidan kamida 24 soat oldin bekor qilinmasa, u avtomatik tarzda uzaytiriladi. Google Play hisob sozlamalaridan istalgan vaqtda bekor qilishingiz mumkin.';

  @override
  String get satinAlmalariGeriYukle => 'Xaridlarni tiklash';

  @override
  String get kullanimKosullariEula => 'Foydalanish shartlari (EULA)';

  @override
  String get gizlilikPolitikasi => 'Maxfiylik siyosati';

  @override
  String get metinGirin => 'Matn kiriting';

  @override
  String get harekeAc => 'Harakatlarni yoqish';

  @override
  String get kopyala => 'Nusxalash';

  @override
  String get kopyalandi => 'Nusxalandi';

  @override
  String get cevir => 'Tarjima';

  @override
  String get suDileCevir => 'Tilga tarjima';

  @override
  String get premiumAGecin => 'Premium’ga o‘tish';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'Ko‘proq tarjima qilish uchun Premium’ga o‘ting.';

  @override
  String get lutfenOnceKayitOlupGiris =>
      'Iltimos, avval ro‘yxatdan o‘tib, tizimga kiring.';

  @override
  String get diller => 'Tillar';

  @override
  String get lehceler => 'Lahjalar';

  @override
  String get internetBaglantisiGerekiyor => 'Internet aloqasi talab qilinadi.';

  @override
  String get aiAsistanSuAnKullanilamiyor =>
      'AI yordamchisi hozir ishlamayapti.';

  @override
  String get yanitGelmedi => 'Javob kelmadi.';

  @override
  String get suAndaCevapAlinamadi =>
      'Hozircha javob olishning imkoni bo‘lmadi.';

  @override
  String get hazir => 'Tayyor.';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'AI so‘z yordamchisi uchun internet aloqasi kerak.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'Bugungi bepul AI so‘z yordamchisi limitiga yetdingiz.';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'AI o‘qituvchi API kaliti yaroqsiz.';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'AI so‘z yordamchisi hozir javob bera olmayapti. Qayta urinib ko‘ring.';

  @override
  String get yukleniyor => 'Yuklanmoqda...';

  @override
  String get sozlukHazir => 'Lug‘at tayyor.';

  @override
  String get sozlukYuklenemedi => 'Lug‘atni yuklab bo‘lmadi.';

  @override
  String get ekranHazirlaniyor => 'Ekran tayyorlanmoqda...';

  @override
  String get sozlukKontrolEdiliyor => 'Lug‘at tekshirilmoqda...';

  @override
  String get sozlukAyarlaniyor => 'Lug\'at sozlanmoqda...';

  @override
  String get aramaHazirlaniyor => 'Qidiruv tayyorlanmoqda...';

  @override
  String get aramaHazir => 'Qidiruv tayyor.';

  @override
  String get internetBaglantisiYok => 'Internet ulanmagan';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'Ilovadan foydalanish uchun internet kerak. Iltimos, WiFi yoki mobil internetingizni tekshiring.';

  @override
  String get sozlukHazirlaniyor => 'Lug\'at tayyorlanmoqda...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    return 'Lug\'at tayyor. $existingCount ta so\'z mavjud.';
  }

  @override
  String get kelimelerYukleniyor => 'So\'zlar yuklanmoqda...';

  @override
  String get sozlukHazir2 => 'Lug\'at tayyor!';

  @override
  String get mevcutVeritabaniKullanilacak =>
      'Mavjud ma\'lumotlar bazasi ishlatiladi.';

  @override
  String get hicGuncellenmedi => 'Yangilanmagan';

  @override
  String get girisYapmalisiniz => 'Tizimga kirishingiz kerak.';

  @override
  String get paketBulunamadiLifetime => 'Paket topilmadi (Lifetime).';

  @override
  String get hataOlustu => 'Xatolik yuz berdi';

  @override
  String beklenmedikHataE(Object e) {
    return 'Kutilmagan xatolik: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'RevenueCat ishga tushirilmadi: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris =>
      'Sotib olish uchun oldin tizimga kiring.';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'Sotib olishda xatolik: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'Obuna paketi yuklanmadi. Iltimos, internetni tekshirib qaytadan urinib ko\'ring.';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'Sotib olishni tekshirish uchun internet kerak.';

  @override
  String get aktifBirAbonelikBulunamadi => 'Faol obuna topilmadi.';

  @override
  String restoreHatasiE(Object e) {
    return 'Tiklashda xatolik: $e';
  }

  @override
  String get hataOlustu2 => 'Xatolik yuz berdi.';

  @override
  String get ceviriIcinGirisYapmanGerekiyor =>
      'Tarjima qilish uchun tizimga kirishingiz kerak.';

  @override
  String get premiumKullanici => 'Premium foydalanuvchi.';

  @override
  String get ceviriHakkiKullanildi => 'Tarjima limiti tugadi.';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'Tarjima limiti tekshirilmadi. Internetni tekshiring.';

  @override
  String get yeniSohbet => 'Yangi suhbat';

  @override
  String get buSohbetinGecmisiSilinsinMi =>
      'Ushbu suhbat tarixi o\'chirilsinmi?';

  @override
  String get aiAsistan => 'AI Yordamchi';

  @override
  String get hakkinda => ' haqida';

  @override
  String get arapcaSozlukYardimcin => 'Arab tili lug\'at yordamchingiz';

  @override
  String get bugunkuUcretsizSoruHakkin => 'Bugungi bepul savol huquqingiz';

  @override
  String get arapcasiniDinle => 'Arabchasini eshitish';

  @override
  String get tekrarDene2 => 'Qaytadan urinib ko\'rish';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    return 'Bugungi $freeDailyLimit ta bepul savol huquqingiz tugadi';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'Huquqingiz ertaga yangilanadi. Premium bilan cheksiz savol berishingiz mumkin.';

  @override
  String get premiumAGec2 => 'Premiumga o\'tish';

  @override
  String get kisacaAnlat => 'Qisqacha tushuntir';

  @override
  String get m3OrnekCumleVer => '3 ta misol keltir';

  @override
  String get benzerKelimelerdenFarkiNe => 'O\'xshash so\'zlardan farqi nimada?';

  @override
  String get okunusunuLatinHarfleriyleYaz =>
      'O\'qilishini lotin harflarida yoz';

  @override
  String get gecmisZamanNasilKurulur => 'O\'tgan zamon qanday yasaladi?';

  @override
  String get harfICerNedir => 'Harf-i jar nima?';

  @override
  String get isimCumlesiNasilKurulur => 'Ism gap qanday yasaladi?';

  @override
  String get enSikKullanilan10Fiil => 'Eng ko\'p ishlatiladigan 10 ta fe\'l';

  @override
  String get sonSorduklarim => 'Oxirgi so\'raganlarim';

  @override
  String get ornekSorular => 'Savollar namunasi';

  @override
  String get buKelimeHakkindaKisaVe =>
      'Bu so\'z haqida qisqa va aniq javob olasiz.';

  @override
  String get arapcaSorunuYaz => 'Arab tili bo\'yicha savolingizni yozing';

  @override
  String get kisaVeNetCevapVerir =>
      'Qisqa va aniq javob beradi, bilmaganini uydirmaydi.';

  @override
  String get ornekVer => 'Misol keltir';

  @override
  String get dahaBasitAnlat => 'Oddiyroq tushuntir';

  @override
  String get derinles => 'Chuqurroq tushuntir';

  @override
  String get cekiminiGoster => 'Turlanishini ko\'rsat';

  @override
  String get aiAsistanASor => 'AI Yordamchidan so\'rang...';

  @override
  String get yeniAiAsistan => 'Yangi: AI Yordamchi';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'So\'z kartasidagi belgilarning eng chapdagisiga bosing: ma\'nosini, o\'xshashlaridan farqini va misol gaplarni so\'rang.';

  @override
  String get anladim => 'Tushundim';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'Bu so\'z bilan bosqichma-bosqich ko\'proq misollar keltir: oson, o\'rta, kundalik, grammatik va so\'roq gaplar.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'Bugungi bepul AI So\'z Yordamchisi limitiga yetdingiz. Davom etish uchun Premium\'ga o\'ting.';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'Hozircha javob olib bo\'lmadi. Internet aloqangizni tekshirib qaytadan urinib ko\'ring.';

  @override
  String get aiKelimeAsistani => 'AI So\'z Yordamchisi';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    return 'AI So\'z Yordamchisi · $remaining ta bepul imkoniyat';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi =>
      'AI So\'z Yordamchisi tayyorlanmadi.';

  @override
  String get premiumAGec3 => 'Premium\'ga o\'tish';

  @override
  String get kisacaAnlat2 => 'Qisqacha tushuntir';

  @override
  String get gramerNotlari => 'Grammatika qaydlari';

  @override
  String get kullanimNotlari => 'Foydalanish qaydlari';

  @override
  String get buKelimeNeredeKullanilir => 'Bu so\'z qayerda ishlatiladi?';

  @override
  String get m5YeniOrnekVer => '5 ta yangi misol keltir';

  @override
  String get kolayCumlelerleAnlat => 'Oson gaplar bilan tushuntir';

  @override
  String get cekimleOrnekVer => 'Turlanishi bilan misol keltir';

  @override
  String get harfICerFarkiniAnlat => 'Harf-i jar farqini tushuntir';

  @override
  String get ornekleOgren => 'Misollar bilan o\'rgan';

  @override
  String get miniAlistirma => 'Mini mashq';

  @override
  String get hazirSorular => 'Tayyor savollar';

  @override
  String get sor => 'So\'ra';

  @override
  String get buKelimeyleIlgiliSoruSor => 'Bu so\'z haqida savol so\'ra';

  @override
  String get arapcaTurkceSozluk => 'Arabcha–o\'zbekcha lug\'at';

  @override
  String get arapcaYaDaTurkceYaz =>
      'Arabcha yoki o\'zbekcha yozing, hammasi bitta kartada.';

  @override
  String get sesleYaDaArapcaKlavyeyle =>
      'Ovozli yoki arabcha klaviatura bilan qidiring';

  @override
  String get kokCogulVeOrnekCumleler => 'O\'zak, ko\'plik va namunaviy gaplar';

  @override
  String get fiilKarti => 'Fe\'l kartasi';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'Fe\'llarning turlanishi kartaning ichida.';

  @override
  String get maziMuzariMastarVeEmir => 'Moziy, muzori, masdar va amr';

  @override
  String get tumCekimlerIcinEmsileyeGec =>
      'Barcha turlanishlar uchun Emsila\'ga o\'t';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'So\'z kartasining eng chapidagi belgiga teging.';

  @override
  String get sorunuYazYaDaHazir => 'Savolingizni yozing yoki tayyorini tanlang';

  @override
  String get kisaVeNetCevap => 'Qisqa va aniq javob';

  @override
  String get m5500DenFazlaFiilin =>
      '5500 dan ortiq fe\'lning turlanish jadvali.';

  @override
  String get fiileDokunKartiAcilsin => 'Fe\'lga teging, kartasi ochilsin';

  @override
  String get anlamlariVe24SigaCekimi => 'Ma\'nolari va 24 sig\'a turlanishi';

  @override
  String get kurAnSozlugu => 'Qur\'on lug\'ati';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'Qur\'on so\'zlarini oyatlari bilan o\'rganing.';

  @override
  String get kelimeVeKurAniAnlamlari => 'So\'z va Qur\'oniy ma\'nolari';

  @override
  String get gectigiAyetVeMeali => 'O\'tgan oyati va tarjimasi';

  @override
  String get lehceCeviri => 'Lahja tarjimasi';

  @override
  String get turkceYazYaDaKonus =>
      'O\'zbekcha yozing yoki gapiring, 17 ta lahjaga tarjima qiling.';

  @override
  String get karsiligiVeOkunusu => 'Muqobili va o\'qilishi';

  @override
  String get lehceyiSecYaDaSesle => 'Lahjani tanlang yoki ovozli ayting';

  @override
  String get listelerVeKartlar => 'Ro\'yxatlar va kartalar';

  @override
  String get kaydettiginHerSeyTekYerde => 'Saqlagan hamma narsangiz bir joyda.';

  @override
  String get listeYaDaKartlarlaTekrar =>
      'Ro\'yxat yoki kartalar bilan takrorlang';

  @override
  String get sozlukKurAnVeEmsile => 'Lug\'at, Qur\'on va Emsila yozuvlari';

  @override
  String get a1DenC1EResimli => 'A1 dan C1 gacha rasmli arabcha hikoyalar.';

  @override
  String get kelimeyeDokunAnlamiCiksin => 'So\'zga teging, ma\'nosi chiqsin';

  @override
  String get metniSesliDinle => 'Matnni ovozli eshiting';

  @override
  String get gec => 'O\'tkazib yuborish';

  @override
  String get yeni => 'YANGI';

  @override
  String get ara => 'Qidirish';

  @override
  String get bosluk => 'Bo\'sh joy';

  @override
  String get hesabinizYoksaOnceKayitOlun =>
      'Hisobingiz bo\'lmasa, avval ro\'yxatdan o\'ting';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'Ro\'yxatdan o\'tganingizdan so\'ng tizimga kirishingiz kerak.';

  @override
  String get ePosta => 'E-pochta';

  @override
  String get gecersizEPostaAdresi => 'Yaroqsiz e-pochta manzili';

  @override
  String get sifre => 'Parol';

  @override
  String get sifreGerekli => 'Parol talab qilinadi';

  @override
  String get sifremiUnuttum => 'Parolni unutdim';

  @override
  String get sifreTekrar => 'Parolni qayta kiriting';

  @override
  String get sifreTekrariGerekli => 'Parolni takrorlash shart';

  @override
  String get sifrelerEslesmiyor => 'Parollar mos emas';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'Parolni tiklash uchun avval e-mail manzilingizni kiriting.';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return '$email manziliga ro‘yxatdan o‘tgan hisob mavjud bo‘lsa, parolni tiklash havolasi yuborildi. Pochtangizni va spam papkasini tekshiring.';
  }

  @override
  String get gecerliBirEPostaAdresi => 'Yaroqli e-mail manzilini kiriting.';

  @override
  String get buEPostaIleKayit => 'Bu e-mail bilan hisob topilmadi.';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'Juda ko‘p urinishlar qilindi. Bir ozdan keyin qayta urinib ko‘ring.';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'Tarmoq xatosi. Internet aloqasini tekshiring.';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'Havola yuborilmadi. Iltimos, qayta urinib ko‘ring.';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 Xush kelibsiz! Hisobingiz muvaffaqiyatli yaratildi.';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'Amal bajarilmadi. Iltimos, qayta urinib ko‘ring.';

  @override
  String get ePostaVeyaSifreHatali =>
      'E-mail yoki parol noto‘g‘ri. Iltimos, tekshiring.';

  @override
  String get sifreHatali => 'Parol noto‘g‘ri.';

  @override
  String get buEPostaZatenKayitli => 'Bu e-mail allaqachon ro‘yxatdan o‘tgan.';

  @override
  String get sifreCokZayifDahaGuclu =>
      'Parol juda kuchsiz. Kuchliroq parol tanlang.';

  @override
  String get buGirisYontemiProjeIcin =>
      'Ushbu kirish usuli loyiha uchun faollashtirilmagan.';

  @override
  String get oDisil => 'U (ayol)';

  @override
  String get ikisi => 'Ikkalasi';

  @override
  String get ikisiEril => 'Ikkalasi (erkak)';

  @override
  String get ikisiDisil => 'Ikkalasi (ayol)';

  @override
  String get onlarDisil => 'Ular (ayol)';

  @override
  String get senDisil => 'Sen (ayol)';

  @override
  String get ikiniz => 'Ikkalangiz';

  @override
  String get sizDisil => 'Sizlar (ayol)';

  @override
  String get m3Sahis => 'غَائِب (3-shaxs)';

  @override
  String get m2Sahis => 'مُخَاطَب (2-shaxs)';

  @override
  String get m1Sahis => 'مُتَكَلِّم (1-shaxs)';

  @override
  String get muzari => 'Muzoriy';

  @override
  String get emsileCekimleri => 'Emsila tuslanishlari';

  @override
  String get maziGecmis => 'Moziy (o‘tgan)';

  @override
  String get muzariGenis => 'Muzori';

  @override
  String get emir => 'Amr';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return '$tabTitle tuslanishi topilmadi';
  }

  @override
  String get kok => 'O‘zak';

  @override
  String get ismIFail => 'Ismi foil';

  @override
  String get ismIMefUl => 'Ismi maful';

  @override
  String get fiilCekimleriKavaidSozluk => 'Fe’l tuslanishlari • Kavaid Lug‘at';

  @override
  String get m5500DenFazlaFiilin2 =>
      '5500 dan ortiq fe’lning 24 xil Emsila-i Muxtalifa shaklini o‘rganing.';

  @override
  String get tumFiilleriAc => 'Barcha fe’llarni ochish';

  @override
  String get dahaFazlaFiilYukle => 'Ko‘proq fe’l yuklash';

  @override
  String get arananKelimeBulunamadi => 'Qidirilgan so‘z topilmadi';

  @override
  String get fiilIMaziMuttasilCekimler => 'Fe’li Moziy — Muttasil tuslanishlar';

  @override
  String get fiilIMuzariMuttasilCekimler =>
      'Fe’li Muzoriy — Muttasil tuslanishlar';

  @override
  String get emrIHazirMuttasilCekimler => 'Amri Hozir — Muttasil tuslanishlar';

  @override
  String get cekimler => 'Tuslanishlar';

  @override
  String get premiumIcerik => 'Premium kontent';

  @override
  String get m5500DenFazlaFiilin3 =>
      '5500 dan ortiq fe’lning 24 xil Emsila-i Muxtalifa tuslanishini oching';

  @override
  String get ucretsizFiiller => 'Bepul fe’llar';

  @override
  String get listeyeEkle => 'Ro‘yxatga qo‘shish';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'AI yordamchisidan foydalanish uchun kiring.';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'Bu so‘z bilan darajamga mos 5 ta yangi misol ber: osonidan qiyiniga qarab.';

  @override
  String get tumFiilCekimleri => 'Barcha fe\'l tuslanishi';

  @override
  String kokRoot(Object root) {
    return 'o‘zak $root';
  }

  @override
  String get cogul => 'Ko‘plik';

  @override
  String get ornekCumleler => 'Misol gaplar';

  @override
  String get cumleyiDinle => 'Gapni eshitish';

  @override
  String get aiAsistanASor2 => 'AI yordamchisidan so‘rash';

  @override
  String get dahaFazlaOrnek => 'Ko‘proq misollar';

  @override
  String get kelimeKaydetmekIcinOnceGiris =>
      'So‘zni saqlash uchun oldin tizimga kiring';

  @override
  String get oyna => 'O‘ynash';

  @override
  String get verbFormPast => 'Mazi';

  @override
  String get verbFormPresent => 'Muzori';

  @override
  String get verbFormInfinitive => 'Mastar';

  @override
  String get verbFormImperative => 'Amr';

  @override
  String get zamirOEril => 'U (erkak)';

  @override
  String get zamirOnlarEril => 'Ular (erkak)';

  @override
  String get zamirSenEril => 'Sen (erkak)';

  @override
  String get zamirSizEril => 'Sizlar (erkak)';

  @override
  String get zamirBen => 'Men';

  @override
  String get zamirBiz => 'Biz';

  @override
  String get dialectTr => 'Turkcha';

  @override
  String get dialectEn => 'Inglizcha';

  @override
  String get dialectDe => 'Nemischa';

  @override
  String get dialectFr => 'Fransuzcha';

  @override
  String get dialectRu => 'Ruscha';

  @override
  String get dialectEs => 'Ispancha';

  @override
  String get dialectIt => 'Italyancha';

  @override
  String get dialectPt => 'Portugalcha';

  @override
  String get dialectNl => 'Gollandcha';

  @override
  String get dialectFa => 'Forscha';

  @override
  String get dialectUr => 'Urducha';

  @override
  String get dialectId => 'Indonezcha';

  @override
  String get dialectArStandard => 'Standart arab tili';

  @override
  String get dialectArSyrian => 'Suriya arabchasi';

  @override
  String get dialectArLebanese => 'Livan arabchasi';

  @override
  String get dialectArJordanian => 'Iordaniya arabchasi';

  @override
  String get dialectArPalestinian => 'Falastin arabchasi';

  @override
  String get dialectArEgyptian => 'Misr arabchasi';

  @override
  String get dialectArIraqi => 'Iroq arabchasi';

  @override
  String get dialectArSudanese => 'Sudan arabchasi';

  @override
  String get dialectArSaudi => 'Saudiya arabchasi';

  @override
  String get dialectArEmirati => 'Amirliklar arabchasi';

  @override
  String get dialectArKuwaiti => 'Quvayt arabchasi';

  @override
  String get dialectArQatari => 'Qatar arabchasi';

  @override
  String get dialectArOmani => 'Ummon arabchasi';

  @override
  String get dialectArYemeni => 'Yaman arabchasi';

  @override
  String get dialectArMoroccan => 'Marokash arabchasi';

  @override
  String get dialectArAlgerian => 'Jazoir arabchasi';

  @override
  String get dialectArTunisian => 'Tunis arabchasi';

  @override
  String get dialectArLibyan => 'Liviya arabchasi';

  @override
  String get appLanguage => 'Ilova tili';

  @override
  String get typeNoun => 'Ism';

  @override
  String get typeProperNoun => 'Atama';

  @override
  String get typeVerb => 'Fe\'l';

  @override
  String get typeVerbPast => 'Moziy fe\'l';

  @override
  String get typeVerbPresent => 'Muzori fe\'l';

  @override
  String get typeVerbImperative => 'Amr fe\'l';

  @override
  String get typeVerbProhibitive => 'Nahiy fe\'l';

  @override
  String get typeVerbPastPassive => 'Majhul moziy';

  @override
  String get typeVerbPresentPassive => 'Majhul muzori';

  @override
  String get typeVerbDefective => 'Noqis fe\'l';

  @override
  String get typeMasdar => 'Masdar';

  @override
  String get typeActiveParticiple => 'Ism-i foil';

  @override
  String get typePassiveParticiple => 'Ism-i maful';

  @override
  String get typeElative => 'Ism-i tafdil';

  @override
  String get typeAdjective => 'Sifat';

  @override
  String get typeAdverb => 'Ravish';

  @override
  String get typeHal => 'Hol';

  @override
  String get typePronoun => 'Olmosh';

  @override
  String get typeDemonstrative => 'Ishora ismi';

  @override
  String get typeRelative => 'Ism-i mavsul';

  @override
  String get typeInterrogative => 'So\'roq so\'z';

  @override
  String get typePreposition => 'Harf-i jar';

  @override
  String get typeParticle => 'Yuklama';

  @override
  String get typeNumber => 'Son';

  @override
  String get typePhrase => 'Birikma';

  @override
  String get typeExpression => 'Iborat';

  @override
  String get typeIdiom => 'Idiom';

  @override
  String get siga01 => 'O‘tgan zamon';

  @override
  String get siga02 => 'Hozirgi zamon';

  @override
  String get siga03 => 'Masdar';

  @override
  String get siga04 => 'Ismi foil';

  @override
  String get siga05 => 'Ismi maful';

  @override
  String get siga06 => 'Jahdi mutlaq';

  @override
  String get siga07 => 'Jahdi mustag‘raq';

  @override
  String get siga08 => 'Nafyi hol';

  @override
  String get siga09 => 'Nafyi istiqbol';

  @override
  String get siga10 => 'Tak. nafy. ist.';

  @override
  String get siga11 => 'Amri g‘oyib';

  @override
  String get siga12 => 'Nahyi g‘oyib';

  @override
  String get siga13 => 'Amri hozir';

  @override
  String get siga14 => 'Nahyi hozir';

  @override
  String get siga15 => 'Zamon/Makon';

  @override
  String get siga16 => 'Ismi olat';

  @override
  String get siga17 => 'Binoi marra';

  @override
  String get siga18 => 'Binoi nav\'iy';

  @override
  String get siga19 => 'Ismi tasg‘ir';

  @override
  String get siga20 => 'Ismi mansub';

  @override
  String get siga21 => 'Mub. ismi foil';

  @override
  String get siga22 => 'Ismi tafdil';

  @override
  String get siga23 => 'Taajjub 1';

  @override
  String get siga24 => 'Taajjub 2';

  @override
  String get dialectMs => 'Malay tili';

  @override
  String get dialectBn => 'Bengal tili';

  @override
  String get dialectUz => 'O‘zbek tili';

  @override
  String get dialectAz => 'Ozarbayjon tili';

  @override
  String get prepositionsLabel => 'Harf-i cer bilan';

  @override
  String get tashkeelToggle => 'Harakat';

  @override
  String get tashkeelSettingHint =>
      'Ta’rif va misollarda harakatlarni ko‘rsatish';

  @override
  String get rootMatches => 'Bir xil o‘zak';

  @override
  String get dictionaryLanguage => 'Lug‘at tili';

  @override
  String get dictionaryLanguageHint => 'So‘z ma’nolari tili';

  @override
  String get arabicArabicDictionary => 'Arabcha–arabcha lug‘at';
}
