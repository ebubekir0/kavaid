// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get kavaidSozluk => 'Kamus Kavaid';

  @override
  String get markaAdi => 'Kavaid';

  @override
  String get tanitimDevam => 'Teruskan';

  @override
  String get tanitimBasla => 'Mula';

  @override
  String get tekrarDene => 'Cuba Semula';

  @override
  String get kavaidArapcaSozluk => 'Kavaid - Kamus Bahasa Arab';

  @override
  String get sozluk => 'Kamus';

  @override
  String get ceviri => 'Terjemahan';

  @override
  String get ogren => 'Belajar';

  @override
  String get profil => 'Profil';

  @override
  String get kelimeBulunamadi => 'Perkataan tidak ditemui';

  @override
  String get baglantiAcilamadi => 'Pautan tidak dapat dibuka';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'Tahniah! 1 Bulan Premium telah ditambah ke akaun anda 🌟';

  @override
  String get gecersizVeyaKullanilmisKod =>
      'Kod tidak sah atau telah digunakan.';

  @override
  String get buKoduDahaOnceKullandiniz =>
      'Anda telah menggunakan kod ini sebelum ini.';

  @override
  String get buKodunSuresiDolmus => 'Kod ini telah tamat tempoh.';

  @override
  String get buKodunKullanimLimitiDolmus =>
      'Had penggunaan kod ini telah tamat.';

  @override
  String get lutfenOnceGirisYapin => 'Sila log masuk dahulu.';

  @override
  String get m1AyUcretsizPremiumKazan => 'Dapatkan 1 Bulan Premium Percuma';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'Kongsi pendapat anda tentang aplikasi ini dengan memetik (quote) tweet yang ditetapkan di Twitter (X) untuk dapatkan 1 bulan premium percuma!';

  @override
  String get nasilKatilirim => 'Bagaimana cara menyertai?';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'Kongsi pendapat anda tentang aplikasi dengan memetik (quote) tweet yang ditetapkan di Twitter (X).';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'Hantarkan mesej terus (DM) perkongsian anda kepada akaun @ebubekr53 di Twitter untuk mendapatkan kod anda.';

  @override
  String get koduAsagiyaGirin => 'Masukkan kod di bawah.';

  @override
  String get tweetiAlintila => 'Petik Tweet';

  @override
  String get promosyonKodu => 'Kod Promosi';

  @override
  String get kullan => 'Guna';

  @override
  String get dahaFazlaOzellik => 'Lebih Banyak Ciri';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'Naik taraf ke Premium\nuntuk buat lebih banyak senarai';

  @override
  String get kapat => 'Tutup';

  @override
  String get premiumAl => 'Dapatkan Premium';

  @override
  String get yeniListe => 'Senarai Baharu';

  @override
  String get listeAdi => 'Nama senarai';

  @override
  String get iptal => 'Batal';

  @override
  String get olustur => 'Buat';

  @override
  String get listeyiYenidenAdlandir => 'Namakan Semula Senarai';

  @override
  String get kaydet => 'Simpan';

  @override
  String get kelimeListelerim => 'Senarai Perkataan Saya';

  @override
  String get yeniListeOlustur => 'Buat Senarai Baharu';

  @override
  String get henuzListeYok => 'Tiada senarai lagi';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'Buat senarai untuk\nmenguruskan perkataan anda';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCount perkataan',
      one: '1 perkataan',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'Namakan Semula';

  @override
  String get sil => 'Padam';

  @override
  String get listeyiSil => 'Padam Senarai';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return 'Padam \"$name\"?\nSemua perkataan di dalamnya juga akan dipadam.';
  }

  @override
  String get buListedeHenuzKelimeYok =>
      'Tiada perkataan dalam senarai ini lagi';

  @override
  String get liste => 'Senarai';

  @override
  String get kart => 'Kad';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'Naik taraf ke Premium untuk lebih banyak kad perkataan';

  @override
  String get premiumAYukselt => 'Naik Taraf ke Premium';

  @override
  String get dinle => 'Dengar';

  @override
  String get oyun => 'Permainan';

  @override
  String get kullanimSiniriDoldu => 'Had Penggunaan Dicapai';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'Sila log masuk dan naik taraf ke Premium untuk terus menggunakan kamus Quran tanpa had.';

  @override
  String get tamam => 'OK';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'Semua buku telah dibuka dan iklan telah dibuang.';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'Semua buku telah dibuka. Sila log masuk untuk membuang iklan secara kekal.';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'Kod rahsia gagal digunakan: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'Kamus sedang dikemas kini... Sila tunggu.';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    return 'Kamus berjaya dikemas kini! $p1 perkataan dimuatkan.';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu =>
      'Ralat berlaku semasa mengemas kini kamus!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'Ralat memuat semula pangkalan data: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris =>
      'Sila daftar atau log masuk terlebih dahulu.';

  @override
  String get kelimeAra => 'Cari perkataan';

  @override
  String get emsile => 'Tasrif';

  @override
  String get kuranSozlugu => 'Kamus al-Quran';

  @override
  String get kavaidIDegerlendir => 'Nilai Kavaid';

  @override
  String get gorusunBizimIcinCokDegerli =>
      'Pendapat anda sangat berharga bagi kami.';

  @override
  String get kuranSozluguYukleniyor => 'Kamus al-Quran sedang dimuatkan...';

  @override
  String get kuranSozlugundeAraniyor => 'Mencari dalam Kamus al-Quran...';

  @override
  String get araniyor => 'Sedang mencari...';

  @override
  String get kuranSozlugundeBulunamadi => 'Tidak dijumpai dalam Kamus al-Quran';

  @override
  String get farkliBirKelimeVeyaKok =>
      'Cuba cari perkataan atau kata dasar yang lain';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'Naik taraf ke Premium untuk akses penuh Kamus al-Quran.';

  @override
  String get kurAnIKerimSozlugu => 'Kamus al-Quran';

  @override
  String get kurAnDaGecenTum =>
      'Pelajari penggunaan dan makna semua perkataan dalam al-Quran beserta ayatnya.';

  @override
  String get kurAnDakiBenzersizTum => '21,000+ perkataan unik dalam al-Quran.';

  @override
  String get kuraniAnlamlar => 'Makna dalam al-Quran';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'Pelajari makna perkataan mengikut konteks ayat al-Quran.';

  @override
  String get kurAnAyetleri => 'Ayat al-Quran';

  @override
  String get onBinlerceKurAnAyeti =>
      'Lihat penggunaan perkataan dalam berpuluh ribu ayat al-Quran.';

  @override
  String get kavaidArapcaSozluk2 => 'Kamus Arab Kavaid';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'Kamus Arab pertama dengan sokongan AI generasi baharu';

  @override
  String get premiumAGec => 'Langgan Premium';

  @override
  String get sinirsizErisim => 'Akses tanpa had';

  @override
  String get profilResmiGuncellendi => '✅ Gambar profil dikemas kini!';

  @override
  String get birHataOlustu => 'Ralat berlaku';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'Firebase Storage tidak dikonfigurasikan. Sila aktifkan Storage daripada Firebase Console.';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'Ralat kebenaran. Sila periksa peraturan Storage.';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'Ralat pengesahan. Sila log masuk.';

  @override
  String get internetBaglantisiHatasi => 'Ralat sambungan internet.';

  @override
  String get detay => 'Butiran';

  @override
  String get hataDetayi => 'Butiran Ralat';

  @override
  String get kullanici => 'Pengguna';

  @override
  String get kurucu => 'PENGASAS';

  @override
  String get moderator => 'MODERATOR';

  @override
  String get emailYok => 'Tiada e-mel';

  @override
  String get cikisYapilsinMi => 'Log keluar?';

  @override
  String get oturumunuzKapatilacak => 'Sesi anda akan ditamatkan.';

  @override
  String get cikis => 'Log keluar';

  @override
  String get aboneligiYonet => 'Urus Langganan';

  @override
  String get satinAlmalarKontrolEdiliyor => 'Memeriksa pembelian...';

  @override
  String get geriYukle => 'Pulihkan';

  @override
  String get girisYapinVeyaKayitOlun => 'Log masuk atau daftar';

  @override
  String get girisYap => 'Log masuk';

  @override
  String get kayitOl => 'Daftar';

  @override
  String get premiumUyesiniz => 'Anda Ahli Premium';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'Kandungan tanpa had, tanpa iklan.';

  @override
  String get tumOzelliklereErisin => 'Akses semua ciri.';

  @override
  String get reklamsizKullanim => 'Tanpa Iklan';

  @override
  String get uygulamayiPaylas => 'Kongsi Aplikasi';

  @override
  String get iletisim => 'Hubungi Kami';

  @override
  String get kavaidUygulamasiHakkinda => 'Tentang Aplikasi Kavaid';

  @override
  String get hesabimiSil => 'Padam Akaun Saya';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'Adakah anda pasti mahu memadam akaun anda dan semua data yang berkaitan secara kekal? Tindakan ini tidak boleh dibatalkan.';

  @override
  String get vazgec => 'Batal';

  @override
  String get hesabinizBasariylaSilindi => 'Akaun anda berjaya dipadamkan.';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'Akaun tidak dapat dipadam: $e. Anda mungkin perlu log masuk semula atas sebab keselamatan.';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi => 'Kavaid - Aplikasi Kamus Arab';

  @override
  String get paylasimSirasindaBirHataOlustu => 'Ralat berlaku semasa berkongsi';

  @override
  String get internetGerekli => 'Internet Diperlukan';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'Sambungan internet diperlukan untuk tindakan ini.';

  @override
  String get kullaniciAdiDegistir => 'Tukar Nama Pengguna';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'Semasa: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'Nama Pengguna Baharu';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'namaanda123 (huruf kecil, tiada ruang)';

  @override
  String get enAz3KarakterSadece =>
      '• Sekurang-kurangnya 3 aksara\n• Hanya huruf kecil, angka, dan aksara Latin';

  @override
  String get kullaniciAdiEnAz3 =>
      'Nama pengguna mestilah sekurang-kurangnya 3 aksara';

  @override
  String get sadeceKucukHarfRakamVe =>
      'Hanya huruf kecil, angka, dan aksara Latin';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'Nama pengguna anda telah dikemas kini kepada \"$newUsername\"!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'Nama pengguna ini tidak boleh digunakan atau sudah diambil';

  @override
  String get degistir => 'Tukar';

  @override
  String get premiumUyelikAktif => '🎉 Keahlian Premium aktif!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'Sambungan tidak dapat dibuka: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'Sila log masuk dahulu untuk membeli Premium.';

  @override
  String hataE(Object e) {
    return 'Ralat: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid Premium';

  @override
  String get aiAsistanASinirsizErisim => 'Akses tanpa had kepada Pembantu AI';

  @override
  String get ceviriyeSinirsizErisim => 'Akses tanpa had kepada penterjemahan';

  @override
  String get m5500Fiilin24Siga =>
      'Buka tasrif 24 bentuk untuk 5,500+ kata kerja';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'Akses kepada semua bahan dalam bahagian Belajar';

  @override
  String get kuranSozluguneSinirsizErisim =>
      'Akses Tanpa Had kepada Kamus al-Quran';

  @override
  String get sinirsizKelimeKartiVeListe =>
      'Buat kad imbasan dan senarai tanpa had';

  @override
  String get reklamsizDeneyim => 'Pengalaman tanpa iklan';

  @override
  String get aylikAbonelik => 'Langganan Bulanan';

  @override
  String get m1AyBoyuncaSinirsizErisim => 'Akses tanpa had selama 1 bulan';

  @override
  String get yillikAbonelik => 'Langganan Tahunan';

  @override
  String get m1YilBoyuncaSinirsizErisim => 'Akses tanpa had selama 1 tahun';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return 'Akses tanpa had selama 1 tahun ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return 'DISKAUN $yearlyDiscount%';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Langgan Bulanan$buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Langgan Tahunan$buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'Bayaran akan dicaj ke akaun Apple ID anda. Langganan diperbaharui secara automatik melainkan dibatalkan sekurang-kurangnya 24 jam sebelum tamat tempoh. Anda boleh membatalkannya melalui Tetapan Akaun App Store pada bila-bila masa.';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'Bayaran akan dicaj melalui Google Play. Langganan diperbaharui secara automatik melainkan dibatalkan sekurang-kurangnya 24 jam sebelum tamat tempoh. Anda boleh membatalkannya melalui Tetapan Akaun Google Play pada bila-bila masa.';

  @override
  String get satinAlmalariGeriYukle => 'Pulihkan Pembelian';

  @override
  String get kullanimKosullariEula => 'Syarat Penggunaan (EULA)';

  @override
  String get gizlilikPolitikasi => 'Dasar Privasi';

  @override
  String get metinGirin => 'Masukkan teks';

  @override
  String get harekeAc => 'Buka baris';

  @override
  String get kopyala => 'Salin';

  @override
  String get kopyalandi => 'Disalin';

  @override
  String get cevir => 'Terjemah';

  @override
  String get suDileCevir => 'Terjemah ke Bahasa Ini';

  @override
  String get premiumAGecin => 'Langgan Premium';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'Langgan Premium untuk melakukan lebih banyak terjemahan.';

  @override
  String get lutfenOnceKayitOlupGiris => 'Sila daftar dan log masuk dahulu.';

  @override
  String get diller => 'Bahasa';

  @override
  String get lehceler => 'Dialek';

  @override
  String get internetBaglantisiGerekiyor => 'Sambungan internet diperlukan.';

  @override
  String get aiAsistanSuAnKullanilamiyor =>
      'Pembantu AI tidak tersedia buat masa ini.';

  @override
  String get yanitGelmedi => 'Tiada respons diterima.';

  @override
  String get suAndaCevapAlinamadi =>
      'Tidak dapat menerima jawapan buat masa ini.';

  @override
  String get hazir => 'Sedia.';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'Pembantu Perkataan AI memerlukan sambungan internet.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'Had penggunaan Pembantu Perkataan AI percuma anda hari ini telah tamat.';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'Kunci API Guru AI tidak sah. Sila semak nilai gemini_api Firebase.';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'Pembantu Perkataan AI tidak dapat menjawab buat masa ini. Sila cuba lagi.';

  @override
  String get yukleniyor => 'Sedang memuatkan...';

  @override
  String get sozlukHazir => 'Kamus sedia.';

  @override
  String get sozlukYuklenemedi => 'Kamus tidak dapat dimuatkan.';

  @override
  String get ekranHazirlaniyor => 'Skrin sedang disediakan...';

  @override
  String get sozlukKontrolEdiliyor => 'Kamus sedang diperiksa...';

  @override
  String get sozlukAyarlaniyor => 'Kamus sedang disediakan...';

  @override
  String get aramaHazirlaniyor => 'Carian sedang disediakan...';

  @override
  String get aramaHazir => 'Carian sedia.';

  @override
  String get internetBaglantisiYok => 'Tiada Sambungan Internet';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'Anda memerlukan sambungan internet untuk menggunakan aplikasi ini. Sila semak sambungan WiFi atau data mudah alih anda.';

  @override
  String get sozlukHazirlaniyor => 'Kamus sedang disediakan...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    return 'Kamus sedia. $existingCount perkataan tersedia.';
  }

  @override
  String get kelimelerYukleniyor => 'Perkataan sedang dimuatkan...';

  @override
  String get sozlukHazir2 => 'Kamus sedia!';

  @override
  String get mevcutVeritabaniKullanilacak =>
      'Pangkalan data sedia ada akan digunakan.';

  @override
  String get hicGuncellenmedi => 'Tidak pernah dikemas kini';

  @override
  String get girisYapmalisiniz => 'Anda perlu log masuk.';

  @override
  String get paketBulunamadiLifetime => 'Pakej tidak ditemui (Seumur Hidup).';

  @override
  String get hataOlustu => 'Ralat berlaku';

  @override
  String beklenmedikHataE(Object e) {
    return 'Ralat tidak dijangka: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'RevenueCat tidak dapat dimulakan: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris => 'Log masuk dahulu untuk membeli.';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'Ralat pembelian: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'Pakej langganan tidak dapat dimuatkan. Sila semak sambungan internet anda dan cuba lagi.';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'Sambungan internet diperlukan untuk menyemak pembelian.';

  @override
  String get aktifBirAbonelikBulunamadi => 'Tiada langganan aktif ditemui.';

  @override
  String restoreHatasiE(Object e) {
    return 'Ralat pemulihan: $e';
  }

  @override
  String get hataOlustu2 => 'Ralat berlaku.';

  @override
  String get ceviriIcinGirisYapmanGerekiyor =>
      'Anda perlu log masuk untuk menterjemah.';

  @override
  String get premiumKullanici => 'Pengguna Premium.';

  @override
  String get ceviriHakkiKullanildi => 'Had terjemahan telah digunakan.';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'Had terjemahan tidak dapat disemak. Sila semak sambungan anda.';

  @override
  String get yeniSohbet => 'Sembang baharu';

  @override
  String get buSohbetinGecmisiSilinsinMi =>
      'Adakah anda mahu memadamkan sejarah sembang ini?';

  @override
  String get aiAsistan => 'Pembantu AI';

  @override
  String get hakkinda => ' mengenai';

  @override
  String get arapcaSozlukYardimcin => 'Pembantu kamus Bahasa Arab anda';

  @override
  String get bugunkuUcretsizSoruHakkin => 'Had soalan percuma anda hari ini';

  @override
  String get arapcasiniDinle => 'Dengar sebutan Bahasa Arab';

  @override
  String get tekrarDene2 => 'Cuba lagi';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    return 'Had $freeDailyLimit soalan percuma anda untuk hari ini telah tamat';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'Had anda akan diperbaharui esok. Tanya tanpa had dengan Premium.';

  @override
  String get premiumAGec2 => 'Langgan Premium';

  @override
  String get kisacaAnlat => 'Terangkan secara ringkas';

  @override
  String get m3OrnekCumleVer => 'Berikan 3 contoh ayat';

  @override
  String get benzerKelimelerdenFarkiNe =>
      'Apa bezanya dengan perkataan serupa?';

  @override
  String get okunusunuLatinHarfleriyleYaz => 'Tulis sebutan dengan huruf Rumi';

  @override
  String get gecmisZamanNasilKurulur => 'Bagaimana bina Past Tense (Mazi)?';

  @override
  String get harfICerNedir => 'Apa itu Harf-i Cer?';

  @override
  String get isimCumlesiNasilKurulur => 'Bagaimana bina ayat ismiyah?';

  @override
  String get enSikKullanilan10Fiil => '10 kata kerja paling kerap digunakan';

  @override
  String get sonSorduklarim => 'Soalan terakhir saya';

  @override
  String get ornekSorular => 'Contoh soalan';

  @override
  String get buKelimeHakkindaKisaVe =>
      'Dapatkan jawapan yang ringkas dan jelas tentang perkataan ini.';

  @override
  String get arapcaSorunuYaz => 'Tulis soalan Bahasa Arab anda';

  @override
  String get kisaVeNetCevapVerir =>
      'Memberikan jawapan yang ringkas dan jelas, tidak meneka jika tidak tahu.';

  @override
  String get ornekVer => 'Berikan contoh';

  @override
  String get dahaBasitAnlat => 'Terangkan lebih mudah';

  @override
  String get derinles => 'Terangkan dengan mendalam';

  @override
  String get cekiminiGoster => 'Tunjukkan tasrif';

  @override
  String get aiAsistanASor => 'Tanya Pembantu AI...';

  @override
  String get yeniAiAsistan => 'Baharu: Pembantu AI';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'Sentuh ikon di paling kiri pada kad perkataan: tanya maksud, perbezaan dengan perkataan serupa, dan contoh ayat.';

  @override
  String get anladim => 'Faham';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'Berikan lebih banyak contoh mengikut tahap untuk perkataan ini: mudah, sederhana, kegunaan harian, fokus tatabahasa, dan ayat tanya.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'Hak bantuan AI harian anda telah tamat. Langgan Premium untuk teruskan.';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'Tiada jawapan buat masa ini. Sila semak sambungan internet anda dan cuba lagi.';

  @override
  String get aiKelimeAsistani => 'Pembantu Kata AI';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining akses percuma',
      one: '1 akses percuma',
    );
    return 'Pembantu Kata AI · $_temp0';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi =>
      'Pembantu Kata AI gagal dimuatkan.';

  @override
  String get premiumAGec3 => 'Langgan Premium';

  @override
  String get kisacaAnlat2 => 'Terangkan Ringkas';

  @override
  String get gramerNotlari => 'Nota Tatabahasa';

  @override
  String get kullanimNotlari => 'Nota Penggunaan';

  @override
  String get buKelimeNeredeKullanilir => 'Di manakah perkataan ini digunakan?';

  @override
  String get m5YeniOrnekVer => 'Berikan 5 contoh baharu';

  @override
  String get kolayCumlelerleAnlat => 'Terangkan dengan ayat mudah';

  @override
  String get cekimleOrnekVer => 'Berikan contoh dengan tasrif';

  @override
  String get harfICerFarkiniAnlat => 'Terangkan perbezaan Harf Jar';

  @override
  String get ornekleOgren => 'Belajar Melalui Contoh';

  @override
  String get miniAlistirma => 'Latihan Ringkas';

  @override
  String get hazirSorular => 'Soalan Sedia Ada';

  @override
  String get sor => 'Tanya';

  @override
  String get buKelimeyleIlgiliSoruSor => 'Tanya soalan mengenai perkataan ini';

  @override
  String get arapcaTurkceSozluk => 'Kamus Bahasa Arab–Melayu';

  @override
  String get arapcaYaDaTurkceYaz =>
      'Tulis dalam Bahasa Arab atau Melayu, semuanya dalam satu kad.';

  @override
  String get sesleYaDaArapcaKlavyeyle =>
      'Cari melalui suara atau papan kekunci Arab';

  @override
  String get kokCogulVeOrnekCumleler => 'Kata dasar, jamak, dan contoh ayat';

  @override
  String get fiilKarti => 'Kad Kata Kerja';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'Tasrif kata kerja di dalam kad.';

  @override
  String get maziMuzariMastarVeEmir => 'Mazi, Mudhari, Masdar, dan Amar';

  @override
  String get tumCekimlerIcinEmsileyeGec => 'Lihat Tasrif untuk semua bentuk';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'Ketik ikon di bahagian paling kiri kad perkataan.';

  @override
  String get sorunuYazYaDaHazir =>
      'Tulis soalan anda atau pilih soalan sedia ada';

  @override
  String get kisaVeNetCevap => 'Jawapan ringkas dan tepat';

  @override
  String get m5500DenFazlaFiilin =>
      'Jadual tasrif untuk lebih 5,500 kata kerja.';

  @override
  String get fiileDokunKartiAcilsin => 'Ketik kata kerja untuk buka kad';

  @override
  String get anlamlariVe24SigaCekimi => 'Maksud dan 24 bentuk tasrif';

  @override
  String get kurAnSozlugu => 'Kamus Al-Quran';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'Pelajari perkataan Al-Quran berserta ayatnya.';

  @override
  String get kelimeVeKurAniAnlamlari => 'Perkataan dan maksud Al-Quran';

  @override
  String get gectigiAyetVeMeali => 'Ayat berkaitan dan terjemahannya';

  @override
  String get lehceCeviri => 'Terjemahan Dialek';

  @override
  String get turkceYazYaDaKonus =>
      'Tulis atau cakap dalam Bahasa Melayu, terjemah kepada 17 dialek.';

  @override
  String get karsiligiVeOkunusu => 'Padanan dan sebutan';

  @override
  String get lehceyiSecYaDaSesle => 'Pilih dialek atau guna suara';

  @override
  String get listelerVeKartlar => 'Senarai dan Kad';

  @override
  String get kaydettiginHerSeyTekYerde =>
      'Segala yang anda simpan di satu tempat.';

  @override
  String get listeYaDaKartlarlaTekrar => 'Ulang kaji dengan senarai atau kad';

  @override
  String get sozlukKurAnVeEmsile => 'Rekod kamus, Al-Quran dan tasrif';

  @override
  String get a1DenC1EResimli => 'Kisah Arab bergambar dari tahap A1 hingga C1.';

  @override
  String get kelimeyeDokunAnlamiCiksin => 'Ketik perkataan untuk lihat maksud';

  @override
  String get metniSesliDinle => 'Dengar teks melalui audio';

  @override
  String get gec => 'Langkau';

  @override
  String get yeni => 'BAHARU';

  @override
  String get ara => 'Cari';

  @override
  String get bosluk => 'Jarak';

  @override
  String get hesabinizYoksaOnceKayitOlun =>
      'Jika belum mempunyai akaun, sila daftar dahulu';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'Anda perlu log masuk selepas pendaftaran selesai.';

  @override
  String get ePosta => 'E-mel';

  @override
  String get gecersizEPostaAdresi => 'Alamat e-mel tidak sah';

  @override
  String get sifre => 'Kata laluan';

  @override
  String get sifreGerekli => 'Kata laluan diperlukan';

  @override
  String get sifremiUnuttum => 'Lupa kata laluan';

  @override
  String get sifreTekrar => 'Ulang Kata Laluan';

  @override
  String get sifreTekrariGerekli => 'Kata laluan semula diperlukan';

  @override
  String get sifrelerEslesmiyor => 'Kata laluan tidak sepadan';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'Masukkan alamat e-mel anda dahulu untuk menetapkan semula kata laluan.';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return 'Jika terdapat akaun berdaftar dengan $email, pautan tetapan semula kata laluan telah dihantar. Semak peti masuk dan folder spam anda.';
  }

  @override
  String get gecerliBirEPostaAdresi => 'Sila masukkan alamat e-mel yang sah.';

  @override
  String get buEPostaIleKayit => 'Tiada akaun dijumpai dengan e-mel ini.';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'Terlalu banyak percubaan. Sila cuba lagi sebentar nanti.';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'Ralat rangkaian. Sila periksa sambungan internet anda.';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'Pautan gagal dihantar. Sila cuba lagi.';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 Selamat datang! Akaun anda berjaya dicipta.';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'Operasi gagal. Sila cuba lagi.';

  @override
  String get ePostaVeyaSifreHatali =>
      'E-mel atau kata laluan salah. Sila semak semula.';

  @override
  String get sifreHatali => 'Kata laluan salah.';

  @override
  String get buEPostaZatenKayitli => 'E-mel ini sudah berdaftar.';

  @override
  String get sifreCokZayifDahaGuclu =>
      'Kata laluan terlalu lemah. Sila pilih kata laluan yang lebih kuat.';

  @override
  String get buGirisYontemiProjeIcin =>
      'Kaedah log masuk ini tidak aktif untuk projek ini.';

  @override
  String get oDisil => 'Dia (perempuan)';

  @override
  String get ikisi => 'Mereka berdua';

  @override
  String get ikisiEril => 'Mereka berdua (L)';

  @override
  String get ikisiDisil => 'Mereka berdua (P)';

  @override
  String get onlarDisil => 'Mereka (perempuan)';

  @override
  String get senDisil => 'Awak (perempuan)';

  @override
  String get ikiniz => 'Kamu berdua';

  @override
  String get sizDisil => 'Kamu (perempuan)';

  @override
  String get m3Sahis => 'غَائِب (Ghaib / Orang Ketiga)';

  @override
  String get m2Sahis => 'مُخَاطَب (Mukhatab / Orang Kedua)';

  @override
  String get m1Sahis => 'مُتَكَلِّم (Mutakallim / Orang Pertama)';

  @override
  String get muzari => 'Mudhari';

  @override
  String get emsileCekimleri => 'Jadual Tasrif';

  @override
  String get maziGecmis => 'Madi (Lampau)';

  @override
  String get muzariGenis => 'Mudhari\'';

  @override
  String get emir => 'Amar';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return 'Tasrif $tabTitle tidak dijumpai';
  }

  @override
  String get kok => 'Akar kata';

  @override
  String get ismIFail => 'Isim Fail';

  @override
  String get ismIMefUl => 'Isim Maf\'ul';

  @override
  String get fiilCekimleriKavaidSozluk => 'Tasrif fiil • Kamus Kavaid';

  @override
  String get m5500DenFazlaFiilin2 =>
      'Pelajari tasrif bagi lebih 5,500 fiil dalam 24 bentuk (sighah).';

  @override
  String get tumFiilleriAc => 'Buka semua fiil';

  @override
  String get dahaFazlaFiilYukle => 'Muat Lagi Fiil';

  @override
  String get arananKelimeBulunamadi => 'Perkataan tidak dijumpai';

  @override
  String get fiilIMaziMuttasilCekimler => 'Fiil Madi — Tasrif Muttasil';

  @override
  String get fiilIMuzariMuttasilCekimler => 'Fiil Mudhari — Tasrif Muttasil';

  @override
  String get emrIHazirMuttasilCekimler => 'Amar Hadhir — Tasrif Muttasil';

  @override
  String get cekimler => 'Tasrif';

  @override
  String get premiumIcerik => 'Kandungan Premium';

  @override
  String get m5500DenFazlaFiilin3 =>
      'Buka tasrif bagi lebih 5,500 fiil dalam 24 bentuk (sighah)';

  @override
  String get ucretsizFiiller => 'Fiil Percuma';

  @override
  String get listeyeEkle => 'Tambah ke senarai';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'Sila log masuk untuk menggunakan pembantu AI.';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'Berikan 5 contoh ayat baharu dengan perkataan ini mengikut tahap saya: dari mudah ke sukar.';

  @override
  String get tumFiilCekimleri => 'Semua Tasrif Fiil';

  @override
  String kokRoot(Object root) {
    return 'akar $root';
  }

  @override
  String get cogul => 'Jamak';

  @override
  String get ornekCumleler => 'Contoh Ayat';

  @override
  String get cumleyiDinle => 'Dengar ayat';

  @override
  String get aiAsistanASor2 => 'Tanya AI';

  @override
  String get dahaFazlaOrnek => 'Lagi contoh';

  @override
  String get kelimeKaydetmekIcinOnceGiris =>
      'Sila log masuk untuk menyimpan perkataan';

  @override
  String get oyna => 'Main';

  @override
  String get verbFormPast => 'Madi';

  @override
  String get verbFormPresent => 'Mudhari\'';

  @override
  String get verbFormInfinitive => 'Masdar';

  @override
  String get verbFormImperative => 'Amar';

  @override
  String get zamirOEril => 'Dia (lelaki)';

  @override
  String get zamirOnlarEril => 'Mereka (lelaki)';

  @override
  String get zamirSenEril => 'Awak (lelaki)';

  @override
  String get zamirSizEril => 'Kalian (L)';

  @override
  String get zamirBen => 'Saya';

  @override
  String get zamirBiz => 'Kami';

  @override
  String get dialectTr => 'Bahasa Turki';

  @override
  String get dialectEn => 'Bahasa Inggeris';

  @override
  String get dialectDe => 'Bahasa Jerman';

  @override
  String get dialectFr => 'Bahasa Perancis';

  @override
  String get dialectRu => 'Bahasa Rusia';

  @override
  String get dialectEs => 'Bahasa Sepanyol';

  @override
  String get dialectIt => 'Bahasa Itali';

  @override
  String get dialectPt => 'Bahasa Portugis';

  @override
  String get dialectNl => 'Bahasa Belanda';

  @override
  String get dialectFa => 'Bahasa Parsi';

  @override
  String get dialectUr => 'Bahasa Urdu';

  @override
  String get dialectId => 'Bahasa Indonesia';

  @override
  String get dialectArStandard => 'Bahasa Arab Standard';

  @override
  String get dialectArSyrian => 'Bahasa Arab Syria';

  @override
  String get dialectArLebanese => 'Bahasa Arab Lubnan';

  @override
  String get dialectArJordanian => 'Bahasa Arab Jordan';

  @override
  String get dialectArPalestinian => 'Bahasa Arab Palestin';

  @override
  String get dialectArEgyptian => 'Bahasa Arab Mesir';

  @override
  String get dialectArIraqi => 'Bahasa Arab Iraq';

  @override
  String get dialectArSudanese => 'Bahasa Arab Sudan';

  @override
  String get dialectArSaudi => 'Bahasa Arab Saudi';

  @override
  String get dialectArEmirati => 'Bahasa Arab Emiriah';

  @override
  String get dialectArKuwaiti => 'Bahasa Arab Kuwait';

  @override
  String get dialectArQatari => 'Bahasa Arab Qatar';

  @override
  String get dialectArOmani => 'Bahasa Arab Oman';

  @override
  String get dialectArYemeni => 'Bahasa Arab Yaman';

  @override
  String get dialectArMoroccan => 'Bahasa Arab Maghribi';

  @override
  String get dialectArAlgerian => 'Bahasa Arab Algeria';

  @override
  String get dialectArTunisian => 'Bahasa Arab Tunisia';

  @override
  String get dialectArLibyan => 'Bahasa Arab Libya';

  @override
  String get appLanguage => 'Bahasa aplikasi';

  @override
  String get typeNoun => 'Kata Nama';

  @override
  String get typeProperNoun => 'Kata Nama Khas';

  @override
  String get typeVerb => 'Kata Kerja';

  @override
  String get typeVerbPast => 'Fi\'il Madi';

  @override
  String get typeVerbPresent => 'Fi\'il Mudhari\'';

  @override
  String get typeVerbImperative => 'Fi\'il Amr';

  @override
  String get typeVerbProhibitive => 'Fi\'il Nahyi';

  @override
  String get typeVerbPastPassive => 'Madi Majhul';

  @override
  String get typeVerbPresentPassive => 'Mudhari Majhul';

  @override
  String get typeVerbDefective => 'Fi\'il Naqis';

  @override
  String get typeMasdar => 'Masdar';

  @override
  String get typeActiveParticiple => 'Ism Fail';

  @override
  String get typePassiveParticiple => 'Ism Maf\'ul';

  @override
  String get typeElative => 'Ism Tafdil';

  @override
  String get typeAdjective => 'Kata Sifat';

  @override
  String get typeAdverb => 'Zarf';

  @override
  String get typeHal => 'Hal';

  @override
  String get typePronoun => 'Kata Ganti';

  @override
  String get typeDemonstrative => 'Ism Isyarah';

  @override
  String get typeRelative => 'Ism Mausul';

  @override
  String get typeInterrogative => 'Kata Tanya';

  @override
  String get typePreposition => 'Harf Jarr';

  @override
  String get typeParticle => 'Huruf';

  @override
  String get typeNumber => 'Bilangan';

  @override
  String get typePhrase => 'Frasa';

  @override
  String get typeExpression => 'Ungkapan';

  @override
  String get typeIdiom => 'Idiom';

  @override
  String get siga01 => 'Fiil Madi';

  @override
  String get siga02 => 'Fiil Mudhari';

  @override
  String get siga03 => 'Masdar';

  @override
  String get siga04 => 'Ism Fa\'il';

  @override
  String get siga05 => 'Ism Maf\'ul';

  @override
  String get siga06 => 'Jahd Mutlaq';

  @override
  String get siga07 => 'Jahd Mustaqraq';

  @override
  String get siga08 => 'Nafi Hal';

  @override
  String get siga09 => 'Nafi Istiqbal';

  @override
  String get siga10 => 'Nafi I. Muakkad';

  @override
  String get siga11 => 'Amar Ghaib';

  @override
  String get siga12 => 'Nahi Ghaib';

  @override
  String get siga13 => 'Amar Hadir';

  @override
  String get siga14 => 'Nahi Hadir';

  @override
  String get siga15 => 'Ism Zaman/Makan';

  @override
  String get siga16 => 'Ism Alat';

  @override
  String get siga17 => 'Ism Marrah';

  @override
  String get siga18 => 'Ism Hai\'ah';

  @override
  String get siga19 => 'Ism Tasghir';

  @override
  String get siga20 => 'Ism Mansub';

  @override
  String get siga21 => 'Mubalaghah';

  @override
  String get siga22 => 'Ism Tafdil';

  @override
  String get siga23 => 'Ta\'ajjub 1';

  @override
  String get siga24 => 'Ta\'ajjub 2';

  @override
  String get dialectMs => 'Bahasa Melayu';

  @override
  String get dialectBn => 'Bahasa Bengali';

  @override
  String get dialectUz => 'Bahasa Uzbek';

  @override
  String get dialectAz => 'Bahasa Azerbaijan';

  @override
  String get prepositionsLabel => 'Dengan Harf-i Cer';

  @override
  String get tashkeelToggle => 'Baris';

  @override
  String get tashkeelSettingHint => 'Papar baris pada takrif dan contoh';

  @override
  String get rootMatches => 'Akar yang sama';

  @override
  String get dictionaryLanguage => 'Bahasa kamus';

  @override
  String get dictionaryLanguageHint => 'Bahasa makna perkataan';

  @override
  String get arabicArabicDictionary => 'Kamus Arab–Arab';
}
