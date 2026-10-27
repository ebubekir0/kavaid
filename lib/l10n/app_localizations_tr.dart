// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get kavaidSozluk => 'Kavaid Sözlük';

  @override
  String get tekrarDene => 'Tekrar Dene';

  @override
  String get kavaidArapcaSozluk => 'Kavaid - Arapça Sözlük';

  @override
  String get sozluk => 'Sözlük';

  @override
  String get ceviri => 'Çeviri';

  @override
  String get ogren => 'Öğren';

  @override
  String get profil => 'Profil';

  @override
  String get kelimeBulunamadi => 'Kelime bulunamadı';

  @override
  String get baglantiAcilamadi => 'Bağlantı açılamadı';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'Tebrikler! 1 Ay Premium hesabınıza tanımlandı 🌟';

  @override
  String get gecersizVeyaKullanilmisKod => 'Geçersiz veya kullanılmış kod.';

  @override
  String get buKoduDahaOnceKullandiniz => 'Bu kodu daha önce kullandınız.';

  @override
  String get buKodunSuresiDolmus => 'Bu kodun süresi dolmuş.';

  @override
  String get buKodunKullanimLimitiDolmus => 'Bu kodun kullanım limiti dolmuş.';

  @override
  String get lutfenOnceGirisYapin => 'Lütfen önce giriş yapın.';

  @override
  String get m1AyUcretsizPremiumKazan => '1 Ay Ücretsiz Premium Kazan';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'Uygulama hakkında görüşlerinizi belirtilen tweeti alıntılayarak Twitter (X)\'te paylaşın, 1 ay ücretsiz premium kazanın!';

  @override
  String get nasilKatilirim => 'Nasıl Katılırım?';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'Uygulama ile ilgili görüşlerinizi belirtilen tweeti alıntılayarak Twitter (X)\'te paylaşın.';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'Paylaşımınızı Twitter\'da @ebubekr53 hesabına direkt mesaj atın, kodunuzu alın.';

  @override
  String get koduAsagiyaGirin => 'Kodu aşağıya girin.';

  @override
  String get tweetiAlintila => 'Tweeti Alıntıla';

  @override
  String get promosyonKodu => 'Promosyon Kodu';

  @override
  String get kullan => 'Kullan';

  @override
  String get dahaFazlaOzellik => 'Daha Fazla Özellik';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'Daha fazla liste oluşturmak için\nPremium\'a yükselt';

  @override
  String get kapat => 'Kapat';

  @override
  String get premiumAl => 'Premium Al';

  @override
  String get yeniListe => 'Yeni Liste';

  @override
  String get listeAdi => 'Liste adı';

  @override
  String get iptal => 'İptal';

  @override
  String get olustur => 'Oluştur';

  @override
  String get listeyiYenidenAdlandir => 'Listeyi Yeniden Adlandır';

  @override
  String get kaydet => 'Kaydet';

  @override
  String get kelimeListelerim => 'Kelime Listelerim';

  @override
  String get yeniListeOlustur => 'Yeni Liste Oluştur';

  @override
  String get henuzListeYok => 'Henüz liste yok';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'Kelimelerinizi düzenlemek için\nbir liste oluşturun';

  @override
  String wordcountKelime(int wordCount) {
    return '$wordCount kelime';
  }

  @override
  String get yenidenAdlandir => 'Yeniden Adlandır';

  @override
  String get sil => 'Sil';

  @override
  String get listeyiSil => 'Listeyi Sil';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return '\"$name\" silinsin mi?\nİçindeki tüm kelimeler de silinecek.';
  }

  @override
  String get buListedeHenuzKelimeYok => 'Bu listede henüz kelime yok';

  @override
  String get liste => 'Liste';

  @override
  String get kart => 'Kart';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'Daha fazla kelime kartı için Premium\'a yükselt';

  @override
  String get premiumAYukselt => 'Premium\'a Yükselt';

  @override
  String get dinle => 'Dinle';

  @override
  String get oyun => 'Oyun';

  @override
  String get kullanimSiniriDoldu => 'Kullanım Sınırı Doldu';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'Kuran sözlüğünü sınırsız kullanmaya devam etmek için lütfen giriş yapın ve Premium\'a yükseltin.';

  @override
  String get tamam => 'Tamam';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'Tüm kitaplar açıldı ve reklamlar kaldırıldı.';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'Tüm kitaplar açıldı. Reklamları kalıcı kaldırmak için lütfen giriş yapın.';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'Gizli kod uygulanamadı: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'Sözlük güncelleniyor... Lütfen bekleyin.';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    return 'Sözlük başarıyla güncellendi! $p1 kelime yüklendi.';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu =>
      'Sözlük güncellenirken hata oluştu!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'Database reload hatası: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris => 'Lütfen önce kayıt olun, giriş yapın.';

  @override
  String get kelimeAra => 'Kelime ara';

  @override
  String get emsile => 'Emsile';

  @override
  String get kuranSozlugu => 'Kuran Sözlüğü';

  @override
  String get kavaidIDegerlendir => 'Kavaid’i değerlendir';

  @override
  String get gorusunBizimIcinCokDegerli => 'Görüşün bizim için çok değerli.';

  @override
  String get kuranSozluguYukleniyor => 'Kuran sözlüğü yükleniyor...';

  @override
  String get kuranSozlugundeAraniyor => 'Kuran sözlüğünde aranıyor...';

  @override
  String get araniyor => 'Aranıyor...';

  @override
  String get kuranSozlugundeBulunamadi => 'Kuran sözlüğünde bulunamadı';

  @override
  String get farkliBirKelimeVeyaKok =>
      'Farklı bir kelime veya kök ile aramayı deneyin';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'Kuran sözlüğünü daha fazla kullanabilmek için Premium\'a yükseltin.';

  @override
  String get kurAnIKerimSozlugu => 'Kur\'an-ı Kerim Sözlüğü';

  @override
  String get kurAnDaGecenTum =>
      'Kur\'an\'da geçen tüm kelimelerin kullanımlarını ve Kur\'ani anlamlarını ayetlerle birlikte öğrenin.';

  @override
  String get kurAnDakiBenzersizTum => 'Kur\'an\'daki benzersiz tüm kelimeler.';

  @override
  String get kuraniAnlamlar => 'Kurani Anlamlar';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'Kelimelerin Kur\'an ayetlerinde kazandığı anlamları öğrenin.';

  @override
  String get kurAnAyetleri => 'Kur\'an Ayetleri';

  @override
  String get onBinlerceKurAnAyeti =>
      'On binlerce Kur\'an ayeti ile kelimelerin Kur\'andaki kullanımlarını görün.';

  @override
  String get kavaidArapcaSozluk2 => 'Kavaid Arapça Sözlük';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'Yeni nesil yapay zeka destekli ilk Arapça sözlük';

  @override
  String get premiumAGec => 'Premium\'a Geç';

  @override
  String get sinirsizErisim => 'Sınırsız erişim';

  @override
  String get profilResmiGuncellendi => '✅ Profil resmi güncellendi!';

  @override
  String get birHataOlustu => 'Bir hata oluştu';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'Firebase Storage yapılandırılmamış. Lütfen Firebase Console\'dan Storage\'ı aktifleştirin.';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'İzin hatası. Storage kurallarını kontrol edin.';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'Yetkilendirme hatası. Lütfen giriş yapın.';

  @override
  String get internetBaglantisiHatasi => 'İnternet bağlantısı hatası.';

  @override
  String get detay => 'Detay';

  @override
  String get hataDetayi => 'Hata Detayı';

  @override
  String get kullanici => 'Kullanıcı';

  @override
  String get kurucu => 'KURUCU';

  @override
  String get moderator => 'MODERATÖR';

  @override
  String get emailYok => 'Email yok';

  @override
  String get cikisYapilsinMi => 'Çıkış yapılsın mı?';

  @override
  String get oturumunuzKapatilacak => 'Oturumunuz kapatılacak.';

  @override
  String get cikis => 'Çıkış';

  @override
  String get aboneligiYonet => 'Aboneliği Yönet';

  @override
  String get satinAlmalarKontrolEdiliyor => 'Satın almalar kontrol ediliyor...';

  @override
  String get geriYukle => 'Geri Yükle';

  @override
  String get girisYapinVeyaKayitOlun => 'Giriş yapın veya kayıt olun';

  @override
  String get girisYap => 'Giriş Yap';

  @override
  String get kayitOl => 'Kayıt Ol';

  @override
  String get premiumUyesiniz => 'Premium Üyesiniz';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'Sınırsız içerik, reklamsız kullanım.';

  @override
  String get tumOzelliklereErisin => 'Tüm özelliklere erişin.';

  @override
  String get reklamsizKullanim => 'Reklamsız Kullanım';

  @override
  String get uygulamayiPaylas => 'Uygulamayı Paylaş';

  @override
  String get iletisim => 'İletişim';

  @override
  String get kavaidUygulamasiHakkinda => 'Kavaid Uygulaması Hakkında';

  @override
  String get hesabimiSil => 'Hesabımı Sil';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'Hesabınızı ve hesabınıza bağlı tüm verileri kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get vazgec => 'Vazgeç';

  @override
  String get hesabinizBasariylaSilindi => 'Hesabınız başarıyla silindi.';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'Hesap silinemedi: $e. Güvenlik gereği yeniden giriş yapmanız gerekebilir.';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi =>
      'Kavaid - Arapça Sözlük Uygulaması';

  @override
  String get paylasimSirasindaBirHataOlustu =>
      'Paylaşım sırasında bir hata oluştu';

  @override
  String get internetGerekli => 'İnternet Gerekli';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'Bu işlem için internet bağlantısı gereklidir.';

  @override
  String get kullaniciAdiDegistir => 'Kullanıcı Adı Değiştir';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'Mevcut: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'Yeni Kullanıcı Adı';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'kullaniciadi123 (küçük harf, boşluksuz)';

  @override
  String get enAz3KarakterSadece =>
      '• En az 3 karakter\n• Sadece küçük harf, rakam ve Türkçe karakterler';

  @override
  String get kullaniciAdiEnAz3 => 'Kullanıcı adı en az 3 karakter olmalı';

  @override
  String get sadeceKucukHarfRakamVe =>
      'Sadece küçük harf, rakam ve Türkçe karakterler';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'Kullanıcı adınız \"$newUsername\" olarak güncellendi!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'Bu kullanıcı adı kullanılamıyor veya zaten alınmış';

  @override
  String get degistir => 'Değiştir';

  @override
  String get premiumUyelikAktif => '🎉 Premium üyelik aktif!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'Bağlantı açılamadı: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'Premium satın almak için lütfen önce giriş yapın.';

  @override
  String hataE(Object e) {
    return 'Hata: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid Premium';

  @override
  String get aiAsistanASinirsizErisim => 'AI Asistan\'a sınırsız erişim';

  @override
  String get ceviriyeSinirsizErisim => 'Çeviriye sınırsız erişim';

  @override
  String get m5500Fiilin24Siga => '5.500+ fiilin 24 sığa emsile çekimlerini aç';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'Öğren kısmındaki tüm materyallere erişim';

  @override
  String get kuranSozluguneSinirsizErisim => 'Kuran Sözlüğüne Sınırsız Erişim';

  @override
  String get sinirsizKelimeKartiVeListe =>
      'Sınırsız kelime kartı ve liste oluştur';

  @override
  String get reklamsizDeneyim => 'Reklamsız deneyim';

  @override
  String get aylikAbonelik => 'Aylık Abonelik';

  @override
  String get m1AyBoyuncaSinirsizErisim => '1 Ay boyunca sınırsız erişim';

  @override
  String get yillikAbonelik => 'Yıllık Abonelik';

  @override
  String get m1YilBoyuncaSinirsizErisim => '1 Yıl boyunca sınırsız erişim';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return '1 Yıl boyunca sınırsız erişim ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return '%$yearlyDiscount İNDİRİM';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Aylık Abone Ol$buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Yıllık Abone Ol$buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'Ödeme Apple ID hesabınızdan tahsil edilir. Abonelik, dönem sonundan en az 24 saat önce iptal edilmediği sürece otomatik yenilenir. İstediğiniz zaman App Store Hesap Ayarları\'ndan iptal edebilirsiniz.';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'Ödeme Google Play üzerinden tahsil edilir. Abonelik, dönem sonundan en az 24 saat önce iptal edilmediği sürece otomatik yenilenir. İstediğiniz zaman Google Play Hesap Ayarları\'ndan iptal edebilirsiniz.';

  @override
  String get satinAlmalariGeriYukle => 'Satın Almaları Geri Yükle';

  @override
  String get kullanimKosullariEula => 'Kullanım Koşulları (EULA)';

  @override
  String get gizlilikPolitikasi => 'Gizlilik Politikası';

  @override
  String get metinGirin => 'Metin girin';

  @override
  String get harekeAc => 'Hareke aç';

  @override
  String get kopyala => 'Kopyala';

  @override
  String get kopyalandi => 'Kopyalandı';

  @override
  String get cevir => 'Çevir';

  @override
  String get suDileCevir => 'Şu Dile Çevir';

  @override
  String get premiumAGecin => 'Premium\'a geçin';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'Daha fazla çeviri yapabilmek için Premium\'a geçin.';

  @override
  String get lutfenOnceKayitOlupGiris => 'Lütfen önce kayıt olup giriş yapın.';

  @override
  String get diller => 'Diller';

  @override
  String get lehceler => 'Lehçeler';

  @override
  String get internetBaglantisiGerekiyor => 'İnternet bağlantısı gerekiyor.';

  @override
  String get aiAsistanSuAnKullanilamiyor => 'AI asistan şu an kullanılamıyor.';

  @override
  String get yanitGelmedi => 'Yanıt gelmedi.';

  @override
  String get suAndaCevapAlinamadi => 'Şu anda cevap alınamadı.';

  @override
  String get hazir => 'Hazir.';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'AI Kelime Asistani icin internet baglantisi gerekiyor.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'Bugunku ucretsiz AI Kelime Asistani hakkin doldu.';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'AI Öğretmen API anahtarı geçersiz. Firebase gemini_api değerini kontrol edin.';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'AI Kelime Asistani su anda yanit veremedi. Tekrar deneyin.';

  @override
  String get yukleniyor => 'Yükleniyor...';

  @override
  String get sozlukHazir => 'Sözlük hazır.';

  @override
  String get sozlukYuklenemedi => 'Sözlük yüklenemedi.';

  @override
  String get ekranHazirlaniyor => 'Ekran hazırlanıyor...';

  @override
  String get sozlukKontrolEdiliyor => 'Sözlük kontrol ediliyor...';

  @override
  String get sozlukAyarlaniyor => 'Sözlük ayarlanıyor...';

  @override
  String get aramaHazirlaniyor => 'Arama hazırlanıyor...';

  @override
  String get aramaHazir => 'Arama hazır.';

  @override
  String get internetBaglantisiYok => 'İnternet Bağlantısı Yok';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'Uygulamayı kullanabilmek için internet bağlantısına ihtiyacınız var. Lütfen WiFi veya mobil veri bağlantınızı kontrol edin.';

  @override
  String get sozlukHazirlaniyor => 'Sözlük hazırlanıyor...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    return 'Sözlük hazır. $existingCount kelime mevcut.';
  }

  @override
  String get kelimelerYukleniyor => 'Kelimeler yükleniyor...';

  @override
  String get sozlukHazir2 => 'Sözlük hazır!';

  @override
  String get mevcutVeritabaniKullanilacak => 'Mevcut veritabanı kullanılacak.';

  @override
  String get hicGuncellenmedi => 'Hiç güncellenmedi';

  @override
  String get girisYapmalisiniz => 'Giriş yapmalısınız.';

  @override
  String get paketBulunamadiLifetime => 'Paket bulunamadı (Lifetime).';

  @override
  String get hataOlustu => 'Hata oluştu';

  @override
  String beklenmedikHataE(Object e) {
    return 'Beklenmedik hata: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'RevenueCat baslatilamadi: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris => 'Satın almak için önce giriş yapın.';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'Satın alma hatası: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'Abonelik paketi yüklenemedi. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'Satın alma kontrolü için internet bağlantısı gerekiyor.';

  @override
  String get aktifBirAbonelikBulunamadi => 'Aktif bir abonelik bulunamadi.';

  @override
  String restoreHatasiE(Object e) {
    return 'Restore hatasi: $e';
  }

  @override
  String get hataOlustu2 => 'Hata oluştu.';

  @override
  String get ceviriIcinGirisYapmanGerekiyor =>
      'Çeviri için giriş yapman gerekiyor.';

  @override
  String get premiumKullanici => 'Premium kullanıcı.';

  @override
  String get ceviriHakkiKullanildi => 'Çeviri hakkı kullanıldı.';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'Çeviri hakkı kontrol edilemedi. Bağlantını kontrol et.';

  @override
  String get yeniSohbet => 'Yeni sohbet';

  @override
  String get buSohbetinGecmisiSilinsinMi => 'Bu sohbetin geçmişi silinsin mi?';

  @override
  String get aiAsistan => 'AI Asistan';

  @override
  String get hakkinda => ' hakkında';

  @override
  String get arapcaSozlukYardimcin => 'Arapça sözlük yardımcın';

  @override
  String get bugunkuUcretsizSoruHakkin => 'Bugünkü ücretsiz soru hakkın';

  @override
  String get arapcasiniDinle => 'Arapçasını dinle';

  @override
  String get tekrarDene2 => 'Tekrar dene';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    return 'Bugünkü $freeDailyLimit ücretsiz soru hakkın bitti';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'Hakların yarın yenilenir. Premium ile sınırsız sorabilirsin.';

  @override
  String get premiumAGec2 => 'Premium\'a geç';

  @override
  String get kisacaAnlat => 'Kısaca anlat';

  @override
  String get m3OrnekCumleVer => '3 örnek cümle ver';

  @override
  String get benzerKelimelerdenFarkiNe => 'Benzer kelimelerden farkı ne?';

  @override
  String get okunusunuLatinHarfleriyleYaz => 'Okunuşunu Latin harfleriyle yaz';

  @override
  String get gecmisZamanNasilKurulur => 'Geçmiş zaman nasıl kurulur?';

  @override
  String get harfICerNedir => 'Harf-i cer nedir?';

  @override
  String get isimCumlesiNasilKurulur => 'İsim cümlesi nasıl kurulur?';

  @override
  String get enSikKullanilan10Fiil => 'En sık kullanılan 10 fiil';

  @override
  String get sonSorduklarim => 'Son sorduklarım';

  @override
  String get ornekSorular => 'Örnek sorular';

  @override
  String get buKelimeHakkindaKisaVe =>
      'Bu kelime hakkında kısa ve net cevap alırsın.';

  @override
  String get arapcaSorunuYaz => 'Arapça sorunu yaz';

  @override
  String get kisaVeNetCevapVerir =>
      'Kısa ve net cevap verir, bilmediğini uydurmaz.';

  @override
  String get ornekVer => 'Örnek ver';

  @override
  String get dahaBasitAnlat => 'Daha basit anlat';

  @override
  String get derinles => 'Derinleş';

  @override
  String get cekiminiGoster => 'Çekimini göster';

  @override
  String get aiAsistanASor => 'AI Asistan\'a sor...';

  @override
  String get yeniAiAsistan => 'Yeni: AI Asistan';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'Kelime kartındaki ikonların en solundaki bu simgeye dokun: anlamını, benzerlerinden farkını ve örnek cümleleri sor.';

  @override
  String get anladim => 'Anladım';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'Bu kelimeyle seviye seviye daha fazla örnek ver: kolay, orta, günlük kullanım, gramer odaklı ve soru cümlesi.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'Bugünkü ücretsiz AI Kelime Asistanı hakkın doldu. Devam etmek için premiuma geçebilirsin.';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'Şu anda cevap alınamadı. İnternet bağlantını kontrol edip tekrar deneyebilirsin.';

  @override
  String get aiKelimeAsistani => 'AI Kelime Asistanı';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    return 'AI Kelime Asistanı · $remaining ücretsiz hak';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi =>
      'AI Kelime Asistanı hazırlanamadı.';

  @override
  String get premiumAGec3 => 'Premium’a geç';

  @override
  String get kisacaAnlat2 => 'Kısaca Anlat';

  @override
  String get gramerNotlari => 'Gramer Notları';

  @override
  String get kullanimNotlari => 'Kullanım Notları';

  @override
  String get buKelimeNeredeKullanilir => 'Bu kelime nerede kullanılır?';

  @override
  String get m5YeniOrnekVer => '5 yeni örnek ver';

  @override
  String get kolayCumlelerleAnlat => 'Kolay cümlelerle anlat';

  @override
  String get cekimleOrnekVer => 'Çekimle örnek ver';

  @override
  String get harfICerFarkiniAnlat => 'Harf-i cer farkını anlat';

  @override
  String get ornekleOgren => 'Örnekle Öğren';

  @override
  String get miniAlistirma => 'Mini Alıştırma';

  @override
  String get hazirSorular => 'Hazır Sorular';

  @override
  String get sor => 'Sor';

  @override
  String get buKelimeyleIlgiliSoruSor => 'Bu kelimeyle ilgili soru sor';

  @override
  String get arapcaTurkceSozluk => 'Arapça–Türkçe sözlük';

  @override
  String get arapcaYaDaTurkceYaz =>
      'Arapça ya da Türkçe yaz, her şey tek kartta.';

  @override
  String get sesleYaDaArapcaKlavyeyle => 'Sesle ya da Arapça klavyeyle ara';

  @override
  String get kokCogulVeOrnekCumleler => 'Kök, çoğul ve örnek cümleler';

  @override
  String get fiilKarti => 'Fiil kartı';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'Fiillerin çekimleri kartın içinde.';

  @override
  String get maziMuzariMastarVeEmir => 'Mazi, müzari, mastar ve emir';

  @override
  String get tumCekimlerIcinEmsileyeGec => 'Tüm çekimler için emsileye geç';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'Kelime kartının en solundaki simgeye dokun.';

  @override
  String get sorunuYazYaDaHazir => 'Sorunu yaz ya da hazır soru seç';

  @override
  String get kisaVeNetCevap => 'Kısa ve net cevap';

  @override
  String get m5500DenFazlaFiilin => '5.500’den fazla fiilin çekim tablosu.';

  @override
  String get fiileDokunKartiAcilsin => 'Fiile dokun, kartı açılsın';

  @override
  String get anlamlariVe24SigaCekimi => 'Anlamları ve 24 sığa çekimi';

  @override
  String get kurAnSozlugu => 'Kur’an sözlüğü';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'Kur’an kelimelerini ayetleriyle öğren.';

  @override
  String get kelimeVeKurAniAnlamlari => 'Kelime ve Kur’ani anlamları';

  @override
  String get gectigiAyetVeMeali => 'Geçtiği ayet ve meali';

  @override
  String get lehceCeviri => 'Lehçe çeviri';

  @override
  String get turkceYazYaDaKonus => 'Türkçe yaz ya da konuş, 17 lehçeye çevir.';

  @override
  String get karsiligiVeOkunusu => 'Karşılığı ve okunuşu';

  @override
  String get lehceyiSecYaDaSesle => 'Lehçeyi seç ya da sesle söyle';

  @override
  String get listelerVeKartlar => 'Listeler ve kartlar';

  @override
  String get kaydettiginHerSeyTekYerde => 'Kaydettiğin her şey tek yerde.';

  @override
  String get listeYaDaKartlarlaTekrar => 'Liste ya da kartlarla tekrar et';

  @override
  String get sozlukKurAnVeEmsile => 'Sözlük, Kur’an ve emsile kayıtları';

  @override
  String get a1DenC1EResimli => 'A1’den C1’e resimli Arapça hikâyeler.';

  @override
  String get kelimeyeDokunAnlamiCiksin => 'Kelimeye dokun, anlamı çıksın';

  @override
  String get metniSesliDinle => 'Metni sesli dinle';

  @override
  String get gec => 'Geç';

  @override
  String get yeni => 'YENİ';

  @override
  String get ara => 'Ara';

  @override
  String get bosluk => 'Boşluk';

  @override
  String get hesabinizYoksaOnceKayitOlun => 'Hesabınız yoksa önce kayıt olun';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'Kayıt tamamlandıktan sonra giriş yapmanız gerekir.';

  @override
  String get ePosta => 'E-posta';

  @override
  String get gecersizEPostaAdresi => 'Geçersiz e-posta adresi';

  @override
  String get sifre => 'Şifre';

  @override
  String get sifreGerekli => 'Şifre gerekli';

  @override
  String get sifremiUnuttum => 'Şifremi unuttum';

  @override
  String get sifreTekrar => 'Şifre Tekrar';

  @override
  String get sifreTekrariGerekli => 'Şifre tekrarı gerekli';

  @override
  String get sifrelerEslesmiyor => 'Şifreler eşleşmiyor';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'Şifreni sıfırlamak için önce e-posta adresini yaz.';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return '$email adresine kayıtlı bir hesap varsa şifre sıfırlama bağlantısı gönderildi. Gelen kutunu ve gereksiz (spam) klasörünü kontrol et.';
  }

  @override
  String get gecerliBirEPostaAdresi => 'Geçerli bir e‑posta adresi giriniz.';

  @override
  String get buEPostaIleKayit => 'Bu e‑posta ile kayıt bulunamadı.';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'Çok fazla deneme yapıldı. Bir süre sonra tekrar deneyin.';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'Ağ hatası. İnternet bağlantınızı kontrol edin.';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'Bağlantı gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 Hoş geldiniz! Hesabınız başarıyla oluşturuldu.';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'İşlem başarısız. Lütfen tekrar deneyin.';

  @override
  String get ePostaVeyaSifreHatali =>
      'E‑posta veya şifre hatalı. Lütfen kontrol ediniz.';

  @override
  String get sifreHatali => 'Şifre hatalı.';

  @override
  String get buEPostaZatenKayitli => 'Bu e‑posta zaten kayıtlı.';

  @override
  String get sifreCokZayifDahaGuclu =>
      'Şifre çok zayıf. Daha güçlü bir şifre seçin.';

  @override
  String get buGirisYontemiProjeIcin =>
      'Bu giriş yöntemi proje için etkin değil.';

  @override
  String get oDisil => 'O (dişil)';

  @override
  String get ikisi => 'İkisi';

  @override
  String get ikisiEril => 'İkisi (eril)';

  @override
  String get ikisiDisil => 'İkisi (dişil)';

  @override
  String get onlarDisil => 'Onlar (dişil)';

  @override
  String get senDisil => 'Sen (dişil)';

  @override
  String get ikiniz => 'İkiniz';

  @override
  String get sizDisil => 'Siz (dişil)';

  @override
  String get m3Sahis => 'غَائِب (3. Şahıs)';

  @override
  String get m2Sahis => 'مُخَاطَب (2. Şahıs)';

  @override
  String get m1Sahis => 'مُتَكَلِّم (1. Şahıs)';

  @override
  String get muzari => 'Müzari';

  @override
  String get emsileCekimleri => 'Emsile Çekimleri';

  @override
  String get maziGecmis => 'Mazi (Geçmiş)';

  @override
  String get muzariGenis => 'Müzari (Geniş)';

  @override
  String get emir => 'Emir';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return '$tabTitle çekimi bulunamadı';
  }

  @override
  String get kok => 'Kök';

  @override
  String get ismIFail => 'İsm-i Fail';

  @override
  String get ismIMefUl => 'İsm-i Mef\'ul';

  @override
  String get fiilCekimleriKavaidSozluk => 'Fiil çekimleri • Kavaid Sözlük';

  @override
  String get m5500DenFazlaFiilin2 =>
      '5.500\'den fazla fiilin 24 sığa Emsile-i Muhtelife çekimlerini öğrenin.';

  @override
  String get tumFiilleriAc => 'Tüm fiilleri aç';

  @override
  String get dahaFazlaFiilYukle => 'Daha Fazla Fiil Yükle';

  @override
  String get arananKelimeBulunamadi => 'Aranan kelime bulunamadı';

  @override
  String get fiilIMaziMuttasilCekimler => 'Fiil-i Mâzi — Muttasıl Çekimler';

  @override
  String get fiilIMuzariMuttasilCekimler => 'Fiil-i Muzâri — Muttasıl Çekimler';

  @override
  String get emrIHazirMuttasilCekimler => 'Emr-i Hâzır — Muttasıl Çekimler';

  @override
  String get cekimler => 'Çekimler';

  @override
  String get premiumIcerik => 'Premium İçerik';

  @override
  String get m5500DenFazlaFiilin3 =>
      '5.500\'den fazla fiilin 24 sığa Emsile-i Muhtelife çekimlerini açın';

  @override
  String get ucretsizFiiller => 'Ücretsiz Fiiller';

  @override
  String get listeyeEkle => 'Listeye Ekle';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'AI asistanı kullanmak için lütfen giriş yapın.';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'Bu kelimeyle seviyeme uygun 5 yeni örnek ver: kolaydan zora doğru.';

  @override
  String get tumFiilCekimleri => 'Tüm Fiil Çekimleri';

  @override
  String kokRoot(Object root) {
    return 'kök $root';
  }

  @override
  String get cogul => 'Çoğul';

  @override
  String get ornekCumleler => 'Örnek Cümleler';

  @override
  String get cumleyiDinle => 'Cümleyi dinle';

  @override
  String get aiAsistanASor2 => 'AI Asistan\'a sor';

  @override
  String get dahaFazlaOrnek => 'Daha fazla örnek';

  @override
  String get kelimeKaydetmekIcinOnceGiris =>
      'Kelime kaydetmek için önce giriş yapın';

  @override
  String get oyna => 'Oyna';

  @override
  String get verbFormPast => 'Mazi';

  @override
  String get verbFormPresent => 'Müzari';

  @override
  String get verbFormInfinitive => 'Mastar';

  @override
  String get verbFormImperative => 'Emir';

  @override
  String get zamirOEril => 'O (eril)';

  @override
  String get zamirOnlarEril => 'Onlar (eril)';

  @override
  String get zamirSenEril => 'Sen (eril)';

  @override
  String get zamirSizEril => 'Siz (eril)';

  @override
  String get zamirBen => 'Ben';

  @override
  String get zamirBiz => 'Biz';

  @override
  String get dialectTr => 'Türkçe';

  @override
  String get dialectEn => 'İngilizce';

  @override
  String get dialectDe => 'Almanca';

  @override
  String get dialectFr => 'Fransızca';

  @override
  String get dialectRu => 'Rusça';

  @override
  String get dialectEs => 'İspanyolca';

  @override
  String get dialectIt => 'İtalyanca';

  @override
  String get dialectPt => 'Portekizce';

  @override
  String get dialectNl => 'Hollandaca';

  @override
  String get dialectFa => 'Farsça';

  @override
  String get dialectUr => 'Urduca';

  @override
  String get dialectId => 'Endonezce';

  @override
  String get dialectArStandard => 'Standart Arapça';

  @override
  String get dialectArSyrian => 'Suriye Arapçası';

  @override
  String get dialectArLebanese => 'Lübnan Arapçası';

  @override
  String get dialectArJordanian => 'Ürdün Arapçası';

  @override
  String get dialectArPalestinian => 'Filistin Arapçası';

  @override
  String get dialectArEgyptian => 'Mısır Arapçası';

  @override
  String get dialectArIraqi => 'Irak Arapçası';

  @override
  String get dialectArSudanese => 'Sudan Arapçası';

  @override
  String get dialectArSaudi => 'Suudi Arapçası';

  @override
  String get dialectArEmirati => 'Emirlik Arapçası';

  @override
  String get dialectArKuwaiti => 'Kuveyt Arapçası';

  @override
  String get dialectArQatari => 'Katar Arapçası';

  @override
  String get dialectArOmani => 'Umman Arapçası';

  @override
  String get dialectArYemeni => 'Yemen Arapçası';

  @override
  String get dialectArMoroccan => 'Fas Arapçası';

  @override
  String get dialectArAlgerian => 'Cezayir Arapçası';

  @override
  String get dialectArTunisian => 'Tunus Arapçası';

  @override
  String get dialectArLibyan => 'Libya Arapçası';

  @override
  String get appLanguage => 'Uygulama dili';

  @override
  String get typeNoun => 'İsim';

  @override
  String get typeProperNoun => 'Özel isim';

  @override
  String get typeVerb => 'Fiil';

  @override
  String get typeVerbPast => 'Mazi fiil';

  @override
  String get typeVerbPresent => 'Muzari fiil';

  @override
  String get typeVerbImperative => 'Emir fiil';

  @override
  String get typeVerbProhibitive => 'Nehiy fiil';

  @override
  String get typeVerbPastPassive => 'Meçhul mazi';

  @override
  String get typeVerbPresentPassive => 'Meçhul muzari';

  @override
  String get typeVerbDefective => 'Nakıs fiil';

  @override
  String get typeMasdar => 'Mastar';

  @override
  String get typeActiveParticiple => 'İsm-i fail';

  @override
  String get typePassiveParticiple => 'İsm-i mef\'ul';

  @override
  String get typeElative => 'İsm-i tafdil';

  @override
  String get typeAdjective => 'Sıfat';

  @override
  String get typeAdverb => 'Zarf';

  @override
  String get typeHal => 'Hal';

  @override
  String get typePronoun => 'Zamir';

  @override
  String get typeDemonstrative => 'İşaret ismi';

  @override
  String get typeRelative => 'İsm-i mevsul';

  @override
  String get typeInterrogative => 'Soru edatı';

  @override
  String get typePreposition => 'Harf-i cer';

  @override
  String get typeParticle => 'Edat';

  @override
  String get typeNumber => 'Sayı';

  @override
  String get typePhrase => 'Tamlama';

  @override
  String get typeExpression => 'İfade';

  @override
  String get typeIdiom => 'Deyim';

  @override
  String get siga01 => 'Fiil-i Mâzi';

  @override
  String get siga02 => 'Fiil-i Muzâri';

  @override
  String get siga03 => 'Masdar';

  @override
  String get siga04 => 'İsm-i Fâil';

  @override
  String get siga05 => 'İsm-i Mef’ûl';

  @override
  String get siga06 => 'C. Mutlak';

  @override
  String get siga07 => 'C. Müstağrak';

  @override
  String get siga08 => 'Nefy-i Hâl';

  @override
  String get siga09 => 'Nef. İstik.';

  @override
  String get siga10 => 'Tek. N. İstik.';

  @override
  String get siga11 => 'Emr-i Gâib';

  @override
  String get siga12 => 'Nehy-i Gâib';

  @override
  String get siga13 => 'Emr-i Hâzır';

  @override
  String get siga14 => 'Nehy-i Hâzır';

  @override
  String get siga15 => 'Zaman/Mekân';

  @override
  String get siga16 => 'İsm-i Âlet';

  @override
  String get siga17 => 'Bina-i Merre';

  @override
  String get siga18 => 'Bina-i Nev\'î';

  @override
  String get siga19 => 'İsm-i Tasğîr';

  @override
  String get siga20 => 'İsm-i Mensûb';

  @override
  String get siga21 => 'Müb. İ. Fâil';

  @override
  String get siga22 => 'İsm-i Tafdîl';

  @override
  String get siga23 => 'Taaccüb 1';

  @override
  String get siga24 => 'Taaccüb 2';

  @override
  String get dialectMs => 'Malayca';

  @override
  String get dialectBn => 'Bengalce';

  @override
  String get dialectUz => 'Özbekçe';

  @override
  String get dialectAz => 'Azerice';

  @override
  String get prepositionsLabel => 'Harf-i cerle';

  @override
  String get tashkeelToggle => 'Hareke';

  @override
  String get tashkeelSettingHint => 'Tanım ve örneklerde harekeleri göster';

  @override
  String get rootMatches => 'Kök eşleşme';

  @override
  String get dictionaryLanguage => 'Sözlük dili';

  @override
  String get dictionaryLanguageHint => 'Kelime anlamlarının dili';

  @override
  String get arabicArabicDictionary => 'Arapça–Arapça sözlük';
}
