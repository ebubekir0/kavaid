// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get kavaidSozluk => 'Kamus Kavaid';

  @override
  String get markaAdi => 'Kavaid';

  @override
  String get tanitimDevam => 'Lanjut';

  @override
  String get tanitimBasla => 'Mulai';

  @override
  String get tekrarDene => 'Coba Lagi';

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
  String get kelimeBulunamadi => 'Kata tidak ditemukan';

  @override
  String get baglantiAcilamadi => 'Gagal membuka tautan';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'Selamat! 1 bulan Premium telah ditambahkan ke akun Anda 🌟';

  @override
  String get gecersizVeyaKullanilmisKod =>
      'Kode tidak valid atau sudah digunakan.';

  @override
  String get buKoduDahaOnceKullandiniz =>
      'Anda sudah menggunakan kode ini sebelumnya.';

  @override
  String get buKodunSuresiDolmus => 'Kode ini sudah kedaluwarsa.';

  @override
  String get buKodunKullanimLimitiDolmus =>
      'Batas penggunaan kode ini telah tercapai.';

  @override
  String get lutfenOnceGirisYapin => 'Silakan login terlebih dahulu.';

  @override
  String get m1AyUcretsizPremiumKazan => 'Dapatkan 1 Bulan Premium Gratis';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'Bagikan pendapat Anda tentang aplikasi ini dengan me-retweet tweet yang ditentukan di Twitter (X) dan dapatkan 1 bulan premium gratis!';

  @override
  String get nasilKatilirim => 'Cara Mengikuti?';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'Bagikan pendapat Anda tentang aplikasi dengan me-retweet tweet yang ditentukan di Twitter (X).';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'Kirimkan bukti tweet Anda melalui DM ke akun @ebubekr53 di Twitter untuk mendapatkan kode Anda.';

  @override
  String get koduAsagiyaGirin => 'Masukkan kode di bawah ini.';

  @override
  String get tweetiAlintila => 'Retweet';

  @override
  String get promosyonKodu => 'Kode Promosi';

  @override
  String get kullan => 'Gunakan';

  @override
  String get dahaFazlaOzellik => 'Fitur Lebih Lanjut';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'Upgrade ke Premium untuk\nmembuat lebih banyak daftar';

  @override
  String get kapat => 'Tutup';

  @override
  String get premiumAl => 'Dapatkan Premium';

  @override
  String get yeniListe => 'Daftar Baru';

  @override
  String get listeAdi => 'Nama daftar';

  @override
  String get iptal => 'Batal';

  @override
  String get olustur => 'Buat';

  @override
  String get listeyiYenidenAdlandir => 'Ganti Nama Daftar';

  @override
  String get kaydet => 'Simpan';

  @override
  String get kelimeListelerim => 'Daftar Kata Saya';

  @override
  String get yeniListeOlustur => 'Buat Daftar Baru';

  @override
  String get henuzListeYok => 'Belum ada daftar';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'Buat daftar untuk mengatur\nkosa kata Anda';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCount kata',
      one: '1 kata',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'Ganti Nama';

  @override
  String get sil => 'Hapus';

  @override
  String get listeyiSil => 'Hapus Daftar';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return 'Hapus \"$name\"?\nSemua kata di dalamnya juga akan terhapus.';
  }

  @override
  String get buListedeHenuzKelimeYok => 'Belum ada kata dalam daftar ini';

  @override
  String get liste => 'Daftar';

  @override
  String get kart => 'Kartu';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'Upgrade ke Premium untuk lebih banyak kartu kata';

  @override
  String get premiumAYukselt => 'Upgrade ke Premium';

  @override
  String get dinle => 'Dengarkan';

  @override
  String get oyun => 'Permainan';

  @override
  String get kullanimSiniriDoldu => 'Batas Penggunaan Tercapai';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'Silakan login dan upgrade ke Premium untuk terus menggunakan kamus Al-Qur\'an tanpa batas.';

  @override
  String get tamam => 'Oke';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'Semua buku telah terbuka dan iklan dihapus.';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'Semua buku telah terbuka. Silakan login untuk menghapus iklan secara permanen.';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'Gagal menerapkan kode rahasia: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'Kamus sedang diperbarui... Mohon tunggu.';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    return 'Kamus berhasil diperbarui! $p1 kata telah dimuat.';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu =>
      'Terjadi kesalahan saat memperbarui kamus!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'Kesalahan pemuatan basis data: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris =>
      'Silakan daftar atau masuk terlebih dahulu.';

  @override
  String get kelimeAra => 'Cari kata';

  @override
  String get emsile => 'Tasrif';

  @override
  String get kuranSozlugu => 'Kamus Al-Quran';

  @override
  String get kavaidIDegerlendir => 'Nilai Kavaid';

  @override
  String get gorusunBizimIcinCokDegerli =>
      'Masukan Anda sangat berharga bagi kami.';

  @override
  String get kuranSozluguYukleniyor => 'Memuat kamus Al-Quran...';

  @override
  String get kuranSozlugundeAraniyor => 'Mencari di kamus Al-Quran...';

  @override
  String get araniyor => 'Mencari...';

  @override
  String get kuranSozlugundeBulunamadi => 'Tidak ditemukan di kamus Al-Quran';

  @override
  String get farkliBirKelimeVeyaKok =>
      'Coba cari dengan kata atau akar kata lain';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'Tingkatkan ke Premium untuk mengakses kamus Al-Quran lebih lanjut.';

  @override
  String get kurAnIKerimSozlugu => 'Kamus Al-Quran';

  @override
  String get kurAnDaGecenTum =>
      'Pelajari penggunaan semua kata dalam Al-Quran dan maknanya di dalam ayat.';

  @override
  String get kurAnDakiBenzersizTum => 'Semua kata unik dalam Al-Quran.';

  @override
  String get kuraniAnlamlar => 'Makna Quranik';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'Pelajari makna kata-kata dalam ayat Al-Quran.';

  @override
  String get kurAnAyetleri => 'Ayat Al-Quran';

  @override
  String get onBinlerceKurAnAyeti =>
      'Lihat penggunaan kata dalam Al-Quran melalui puluhan ribu ayat.';

  @override
  String get kavaidArapcaSozluk2 => 'Kamus Bahasa Arab Kavaid';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'Kamus Bahasa Arab generasi baru bertenaga AI';

  @override
  String get premiumAGec => 'Beralih ke Premium';

  @override
  String get sinirsizErisim => 'Akses tanpa batas';

  @override
  String get profilResmiGuncellendi => '✅ Foto profil diperbarui!';

  @override
  String get birHataOlustu => 'Terjadi kesalahan';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'Firebase Storage belum dikonfigurasi. Mohon aktifkan Storage di Firebase Console.';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'Kesalahan izin. Periksa aturan Storage.';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'Kesalahan otorisasi. Silakan masuk.';

  @override
  String get internetBaglantisiHatasi => 'Kesalahan koneksi internet.';

  @override
  String get detay => 'Detail';

  @override
  String get hataDetayi => 'Detail Kesalahan';

  @override
  String get kullanici => 'Pengguna';

  @override
  String get kurucu => 'PENDIRI';

  @override
  String get moderator => 'MODERATOR';

  @override
  String get emailYok => 'Email tidak ada';

  @override
  String get cikisYapilsinMi => 'Ingin keluar?';

  @override
  String get oturumunuzKapatilacak => 'Sesi Anda akan ditutup.';

  @override
  String get cikis => 'Keluar';

  @override
  String get aboneligiYonet => 'Kelola Langganan';

  @override
  String get satinAlmalarKontrolEdiliyor => 'Memeriksa pembelian...';

  @override
  String get geriYukle => 'Pulihkan';

  @override
  String get girisYapinVeyaKayitOlun => 'Masuk atau daftar';

  @override
  String get girisYap => 'Masuk';

  @override
  String get kayitOl => 'Daftar';

  @override
  String get premiumUyesiniz => 'Anda adalah anggota Premium';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'Konten tanpa batas, tanpa iklan.';

  @override
  String get tumOzelliklereErisin => 'Akses semua fitur.';

  @override
  String get reklamsizKullanim => 'Tanpa Iklan';

  @override
  String get uygulamayiPaylas => 'Bagikan Aplikasi';

  @override
  String get iletisim => 'Kontak';

  @override
  String get kavaidUygulamasiHakkinda => 'Tentang Aplikasi Kavaid';

  @override
  String get hesabimiSil => 'Hapus Akun Saya';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'Apakah Anda yakin ingin menghapus akun Anda dan semua data terkait secara permanen? Tindakan ini tidak dapat dibatalkan.';

  @override
  String get vazgec => 'Batal';

  @override
  String get hesabinizBasariylaSilindi => 'Akun Anda berhasil dihapus.';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'Akun tidak dapat dihapus: $e. Demi keamanan, Anda mungkin perlu masuk kembali.';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi =>
      'Kavaid - Aplikasi Kamus Bahasa Arab';

  @override
  String get paylasimSirasindaBirHataOlustu => 'Terjadi kesalahan saat berbagi';

  @override
  String get internetGerekli => 'Perlu Internet';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'Koneksi internet diperlukan untuk tindakan ini.';

  @override
  String get kullaniciAdiDegistir => 'Ubah Nama Pengguna';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'Saat ini: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'Nama Pengguna Baru';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'nama_pengguna123 (huruf kecil, tanpa spasi)';

  @override
  String get enAz3KarakterSadece =>
      '• Minimal 3 karakter\n• Hanya huruf kecil, angka, dan karakter biasa';

  @override
  String get kullaniciAdiEnAz3 => 'Nama pengguna minimal 3 karakter';

  @override
  String get sadeceKucukHarfRakamVe =>
      'Hanya huruf kecil, angka, dan karakter biasa';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'Nama pengguna Anda berhasil diubah menjadi \"$newUsername\"!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'Nama pengguna ini tidak tersedia atau sudah digunakan';

  @override
  String get degistir => 'Ubah';

  @override
  String get premiumUyelikAktif => '🎉 Keanggotaan Premium aktif!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'Gagal terhubung: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'Silakan masuk terlebih dahulu untuk membeli Premium.';

  @override
  String hataE(Object e) {
    return 'Error: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid Premium';

  @override
  String get aiAsistanASinirsizErisim => 'Akses tak terbatas ke Asisten AI';

  @override
  String get ceviriyeSinirsizErisim => 'Akses tak terbatas untuk terjemahan';

  @override
  String get m5500Fiilin24Siga =>
      'Buka 5.500+ tabel tasrif dalam 24 bentuk kata kerja';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'Akses semua materi di bagian Belajar';

  @override
  String get kuranSozluguneSinirsizErisim =>
      'Akses Tak Terbatas ke Kamus Al-Qur\'an';

  @override
  String get sinirsizKelimeKartiVeListe =>
      'Buat kartu kata dan daftar tak terbatas';

  @override
  String get reklamsizDeneyim => 'Pengalaman bebas iklan';

  @override
  String get aylikAbonelik => 'Langganan Bulanan';

  @override
  String get m1AyBoyuncaSinirsizErisim => 'Akses tak terbatas selama 1 bulan';

  @override
  String get yillikAbonelik => 'Langganan Tahunan';

  @override
  String get m1YilBoyuncaSinirsizErisim => 'Akses tak terbatas selama 1 tahun';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return 'Akses tak terbatas selama 1 tahun ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return 'DISKON $yearlyDiscount';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Langganan Bulanan$buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Langganan Tahunan$buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'Pembayaran akan dibebankan ke akun Apple ID Anda. Langganan diperpanjang secara otomatis kecuali dibatalkan setidaknya 24 jam sebelum periode berakhir. Anda dapat membatalkannya kapan saja melalui Pengaturan Akun App Store.';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'Pembayaran akan dibebankan melalui Google Play. Langganan diperpanjang secara otomatis kecuali dibatalkan setidaknya 24 jam sebelum periode berakhir. Anda dapat membatalkannya kapan saja melalui Pengaturan Akun Google Play.';

  @override
  String get satinAlmalariGeriYukle => 'Pulihkan Pembelian';

  @override
  String get kullanimKosullariEula => 'Ketentuan Penggunaan (EULA)';

  @override
  String get gizlilikPolitikasi => 'Kebijakan Privasi';

  @override
  String get metinGirin => 'Masukkan teks';

  @override
  String get harekeAc => 'Tampilkan harakat';

  @override
  String get kopyala => 'Salin';

  @override
  String get kopyalandi => 'Tersalin';

  @override
  String get cevir => 'Terjemahkan';

  @override
  String get suDileCevir => 'Terjemahkan ke';

  @override
  String get premiumAGecin => 'Upgrade ke Premium';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'Upgrade ke Premium untuk melakukan lebih banyak terjemahan.';

  @override
  String get lutfenOnceKayitOlupGiris =>
      'Silakan daftar dan masuk terlebih dahulu.';

  @override
  String get diller => 'Bahasa';

  @override
  String get lehceler => 'Dialek';

  @override
  String get internetBaglantisiGerekiyor => 'Memerlukan koneksi internet.';

  @override
  String get aiAsistanSuAnKullanilamiyor =>
      'Asisten AI saat ini tidak tersedia.';

  @override
  String get yanitGelmedi => 'Tidak ada respon.';

  @override
  String get suAndaCevapAlinamadi => 'Tidak bisa mendapatkan jawaban saat ini.';

  @override
  String get hazir => 'Siap.';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'Memerlukan koneksi internet untuk Asisten Kata AI.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'Jatah harian Asisten Kata AI gratis Anda telah habis.';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'API Key Asisten AI tidak valid. Periksa pengaturan Firebase gemini_api Anda.';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'Asisten Kata AI tidak dapat menjawab saat ini. Silakan coba lagi.';

  @override
  String get yukleniyor => 'Memuat...';

  @override
  String get sozlukHazir => 'Kamus siap.';

  @override
  String get sozlukYuklenemedi => 'Gagal memuat kamus.';

  @override
  String get ekranHazirlaniyor => 'Menyiapkan layar...';

  @override
  String get sozlukKontrolEdiliyor => 'Memeriksa kamus...';

  @override
  String get sozlukAyarlaniyor => 'Kamus sedang disiapkan...';

  @override
  String get aramaHazirlaniyor => 'Pencarian sedang disiapkan...';

  @override
  String get aramaHazir => 'Pencarian siap.';

  @override
  String get internetBaglantisiYok => 'Tidak Ada Koneksi Internet';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'Anda memerlukan koneksi internet untuk menggunakan aplikasi ini. Mohon periksa WiFi atau koneksi data seluler Anda.';

  @override
  String get sozlukHazirlaniyor => 'Kamus sedang disiapkan...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    String _temp0 = intl.Intl.pluralLogic(
      existingCount,
      locale: localeName,
      other: '$existingCount kata tersedia',
      one: '1 kata tersedia',
    );
    return 'Kamus siap. $_temp0.';
  }

  @override
  String get kelimelerYukleniyor => 'Kata-kata sedang dimuat...';

  @override
  String get sozlukHazir2 => 'Kamus siap!';

  @override
  String get mevcutVeritabaniKullanilacak =>
      'Basis data yang ada akan digunakan.';

  @override
  String get hicGuncellenmedi => 'Belum pernah diperbarui';

  @override
  String get girisYapmalisiniz => 'Anda harus masuk.';

  @override
  String get paketBulunamadiLifetime => 'Paket tidak ditemukan (Seumur Hidup).';

  @override
  String get hataOlustu => 'Terjadi kesalahan';

  @override
  String beklenmedikHataE(Object e) {
    return 'Kesalahan tidak terduga: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'RevenueCat tidak dapat dimulai: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris => 'Masuk terlebih dahulu untuk membeli.';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'Kesalahan pembelian: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'Paket langganan gagal dimuat. Mohon periksa koneksi internet Anda dan coba lagi.';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'Koneksi internet diperlukan untuk memeriksa pembelian.';

  @override
  String get aktifBirAbonelikBulunamadi => 'Langganan aktif tidak ditemukan.';

  @override
  String restoreHatasiE(Object e) {
    return 'Kesalahan pemulihan: $e';
  }

  @override
  String get hataOlustu2 => 'Terjadi kesalahan.';

  @override
  String get ceviriIcinGirisYapmanGerekiyor =>
      'Anda harus masuk untuk menerjemahkan.';

  @override
  String get premiumKullanici => 'Pengguna Premium.';

  @override
  String get ceviriHakkiKullanildi => 'Kuota terjemahan telah habis.';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'Kuota terjemahan tidak dapat diperiksa. Periksa koneksi Anda.';

  @override
  String get yeniSohbet => 'Obrolan baru';

  @override
  String get buSohbetinGecmisiSilinsinMi => 'Hapus riwayat obrolan ini?';

  @override
  String get aiAsistan => 'Asisten AI';

  @override
  String get hakkinda => ' tentang';

  @override
  String get arapcaSozlukYardimcin => 'Asisten kamus bahasa Arab Anda';

  @override
  String get bugunkuUcretsizSoruHakkin =>
      'Jatah pertanyaan gratis Anda hari ini';

  @override
  String get arapcasiniDinle => 'Dengarkan pelafalan Arab';

  @override
  String get tekrarDene2 => 'Coba lagi';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    String _temp0 = intl.Intl.pluralLogic(
      freeDailyLimit,
      locale: localeName,
      other: '$freeDailyLimit pertanyaan',
      one: '1 pertanyaan',
    );
    return 'Jatah $_temp0 gratis Anda hari ini telah habis';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'Jatah Anda diperbarui besok. Dengan Premium, Anda bisa bertanya sepuasnya.';

  @override
  String get premiumAGec2 => 'Beralih ke Premium';

  @override
  String get kisacaAnlat => 'Jelaskan secara singkat';

  @override
  String get m3OrnekCumleVer => 'Berikan 3 contoh kalimat';

  @override
  String get benzerKelimelerdenFarkiNe => 'Apa bedanya dengan kata serupa?';

  @override
  String get okunusunuLatinHarfleriyleYaz =>
      'Tulis pelafalannya dengan huruf Latin';

  @override
  String get gecmisZamanNasilKurulur =>
      'Bagaimana cara membuat bentuk masa lampau (fi\'il madhi)?';

  @override
  String get harfICerNedir => 'Apa itu huruf jar?';

  @override
  String get isimCumlesiNasilKurulur =>
      'Bagaimana cara membuat kalimat nominal (jumlah ismiyah)?';

  @override
  String get enSikKullanilan10Fiil =>
      '10 kata kerja yang paling sering digunakan';

  @override
  String get sonSorduklarim => 'Pertanyaan terakhir saya';

  @override
  String get ornekSorular => 'Contoh pertanyaan';

  @override
  String get buKelimeHakkindaKisaVe =>
      'Dapatkan jawaban singkat dan jelas tentang kata ini.';

  @override
  String get arapcaSorunuYaz => 'Tulis pertanyaan bahasa Arab Anda';

  @override
  String get kisaVeNetCevapVerir =>
      'Memberikan jawaban singkat dan jelas, tidak mengarang jawaban.';

  @override
  String get ornekVer => 'Berikan contoh';

  @override
  String get dahaBasitAnlat => 'Jelaskan lebih sederhana';

  @override
  String get derinles => 'Jelaskan lebih dalam';

  @override
  String get cekiminiGoster => 'Tampilkan konjugasinya';

  @override
  String get aiAsistanASor => 'Tanya Asisten AI...';

  @override
  String get yeniAiAsistan => 'Baru: Asisten AI';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'Ketuk ikon ini di kartu kata: tanya artinya, perbedaannya dengan kata lain, dan contoh kalimat.';

  @override
  String get anladim => 'Mengerti';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'Berikan contoh lebih banyak untuk kata ini berdasarkan tingkatannya: mudah, sedang, penggunaan sehari-hari, fokus tata bahasa, dan kalimat tanya.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'Jatah Asisten Kata AI gratis hari ini telah habis. Anda bisa beralih ke premium untuk melanjutkannya.';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'Tidak dapat mengambil jawaban saat ini. Silakan periksa koneksi internet Anda dan coba lagi.';

  @override
  String get aiKelimeAsistani => 'Asisten Kata AI';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining jatah gratis',
      one: '1 jatah gratis',
    );
    return 'Asisten Kata AI · $_temp0';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi =>
      'Asisten Kata AI gagal disiapkan.';

  @override
  String get premiumAGec3 => 'Beralih ke Premium';

  @override
  String get kisacaAnlat2 => 'Jelaskan Singkat';

  @override
  String get gramerNotlari => 'Catatan Tata Bahasa';

  @override
  String get kullanimNotlari => 'Catatan Penggunaan';

  @override
  String get buKelimeNeredeKullanilir => 'Di mana kata ini digunakan?';

  @override
  String get m5YeniOrnekVer => 'Berikan 5 contoh baru';

  @override
  String get kolayCumlelerleAnlat => 'Jelaskan dengan kalimat sederhana';

  @override
  String get cekimleOrnekVer => 'Berikan contoh dengan konjugasi';

  @override
  String get harfICerFarkiniAnlat => 'Jelaskan perbedaan harf jar';

  @override
  String get ornekleOgren => 'Belajar dengan Contoh';

  @override
  String get miniAlistirma => 'Latihan Singkat';

  @override
  String get hazirSorular => 'Pertanyaan Siap Pakai';

  @override
  String get sor => 'Tanya';

  @override
  String get buKelimeyleIlgiliSoruSor => 'Ajukan pertanyaan tentang kata ini';

  @override
  String get arapcaTurkceSozluk => 'Kamus Arab–Indonesia';

  @override
  String get arapcaYaDaTurkceYaz =>
      'Tulis dalam bahasa Arab atau Indonesia, semuanya dalam satu kartu.';

  @override
  String get sesleYaDaArapcaKlavyeyle =>
      'Cari dengan suara atau papan ketik Arab';

  @override
  String get kokCogulVeOrnekCumleler => 'Akar kata, jamak, dan contoh kalimat';

  @override
  String get fiilKarti => 'Kartu Kata Kerja';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'Konjugasi kata kerja ada di dalam kartu.';

  @override
  String get maziMuzariMastarVeEmir => 'Mazi, Mudhari, Mashdar, dan Amr';

  @override
  String get tumCekimlerIcinEmsileyeGec => 'Buka Tasrif untuk semua bentuk';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'Ketuk ikon di sisi paling kiri kartu kata.';

  @override
  String get sorunuYazYaDaHazir =>
      'Tulis pertanyaanmu atau pilih pertanyaan siap pakai';

  @override
  String get kisaVeNetCevap => 'Jawaban singkat dan jelas';

  @override
  String get m5500DenFazlaFiilin =>
      'Tabel konjugasi lebih dari 5.500 kata kerja.';

  @override
  String get fiileDokunKartiAcilsin =>
      'Ketuk kata kerja untuk membuka kartunya';

  @override
  String get anlamlariVe24SigaCekimi => 'Arti dan 24 konjugasi bentuk kata';

  @override
  String get kurAnSozlugu => 'Kamus Al-Quran';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'Pelajari kata-kata Al-Quran beserta ayatnya.';

  @override
  String get kelimeVeKurAniAnlamlari => 'Kata dan makna Qurani';

  @override
  String get gectigiAyetVeMeali =>
      'Ayat tempat kata tersebut muncul dan terjemahannya';

  @override
  String get lehceCeviri => 'Terjemahan Dialek';

  @override
  String get turkceYazYaDaKonus =>
      'Tulis atau ucapkan dalam bahasa Indonesia, terjemahkan ke 17 dialek.';

  @override
  String get karsiligiVeOkunusu => 'Padanan dan cara bacanya';

  @override
  String get lehceyiSecYaDaSesle => 'Pilih dialek atau ucapkan';

  @override
  String get listelerVeKartlar => 'Daftar dan Kartu';

  @override
  String get kaydettiginHerSeyTekYerde =>
      'Semua yang kamu simpan ada di satu tempat.';

  @override
  String get listeYaDaKartlarlaTekrar => 'Ulangi dengan daftar atau kartu';

  @override
  String get sozlukKurAnVeEmsile => 'Riwayat kamus, Al-Quran, dan tasrif';

  @override
  String get a1DenC1EResimli =>
      'Cerita bahasa Arab bergambar dari level A1 sampai C1.';

  @override
  String get kelimeyeDokunAnlamiCiksin => 'Ketuk kata untuk melihat artinya';

  @override
  String get metniSesliDinle => 'Dengarkan teksnya';

  @override
  String get gec => 'Lewati';

  @override
  String get yeni => 'BARU';

  @override
  String get ara => 'Cari';

  @override
  String get bosluk => 'Spasi';

  @override
  String get hesabinizYoksaOnceKayitOlun =>
      'Jika belum punya akun, silakan daftar terlebih dahulu';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'Setelah pendaftaran selesai, Anda perlu masuk.';

  @override
  String get ePosta => 'Email';

  @override
  String get gecersizEPostaAdresi => 'Alamat email tidak valid';

  @override
  String get sifre => 'Kata sandi';

  @override
  String get sifreGerekli => 'Kata sandi wajib diisi';

  @override
  String get sifremiUnuttum => 'Lupa kata sandi';

  @override
  String get sifreTekrar => 'Ulangi kata sandi';

  @override
  String get sifreTekrariGerekli => 'Konfirmasi kata sandi diperlukan';

  @override
  String get sifrelerEslesmiyor => 'Kata sandi tidak cocok';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'Masukkan alamat email Anda untuk mereset kata sandi.';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return 'Jika akun terdaftar dengan email $email, tautan reset kata sandi telah dikirim. Cek kotak masuk dan folder spam Anda.';
  }

  @override
  String get gecerliBirEPostaAdresi => 'Masukkan alamat email yang valid.';

  @override
  String get buEPostaIleKayit => 'Akun dengan email ini tidak ditemukan.';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'Terlalu banyak percobaan. Coba lagi nanti.';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'Kesalahan jaringan. Periksa koneksi internet Anda.';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'Gagal mengirim tautan. Silakan coba lagi.';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 Selamat datang! Akun Anda berhasil dibuat.';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'Proses gagal. Silakan coba lagi.';

  @override
  String get ePostaVeyaSifreHatali =>
      'Email atau kata sandi salah. Silakan periksa kembali.';

  @override
  String get sifreHatali => 'Kata sandi salah.';

  @override
  String get buEPostaZatenKayitli => 'Email ini sudah terdaftar.';

  @override
  String get sifreCokZayifDahaGuclu =>
      'Kata sandi terlalu lemah. Pilih kata sandi yang lebih kuat.';

  @override
  String get buGirisYontemiProjeIcin =>
      'Metode masuk ini tidak aktif untuk proyek ini.';

  @override
  String get oDisil => 'Dia (feminin)';

  @override
  String get ikisi => 'Mereka berdua';

  @override
  String get ikisiEril => 'Keduanya (lk)';

  @override
  String get ikisiDisil => 'Keduanya (pr)';

  @override
  String get onlarDisil => 'Mereka (feminin)';

  @override
  String get senDisil => 'Kamu (feminin)';

  @override
  String get ikiniz => 'Kalian berdua';

  @override
  String get sizDisil => 'Kalian (feminin)';

  @override
  String get m3Sahis => 'غَائِب (Orang ke-3)';

  @override
  String get m2Sahis => 'مُخَاطَب (Orang ke-2)';

  @override
  String get m1Sahis => 'مُتَكَلِّم (Orang ke-1)';

  @override
  String get muzari => 'Mudhari';

  @override
  String get emsileCekimleri => 'Tabel Tasrif';

  @override
  String get maziGecmis => 'Madhi (Lampau)';

  @override
  String get muzariGenis => 'Mudhari';

  @override
  String get emir => 'Amr (Perintah)';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return 'Konjugasi $tabTitle tidak ditemukan';
  }

  @override
  String get kok => 'Akar kata';

  @override
  String get ismIFail => 'Isim Fa\'il';

  @override
  String get ismIMefUl => 'Isim Maf\'ul';

  @override
  String get fiilCekimleriKavaidSozluk => 'Konjugasi Kata Kerja • Kamus Kavaid';

  @override
  String get m5500DenFazlaFiilin2 =>
      'Pelajari tasrif lebih dari 5.500 kata kerja dalam 24 bentuk.';

  @override
  String get tumFiilleriAc => 'Buka semua kata kerja';

  @override
  String get dahaFazlaFiilYukle => 'Muat Lebih Banyak Kata Kerja';

  @override
  String get arananKelimeBulunamadi => 'Kata tidak ditemukan';

  @override
  String get fiilIMaziMuttasilCekimler => 'Fiil Madhi — Konjugasi Muttashil';

  @override
  String get fiilIMuzariMuttasilCekimler =>
      'Fiil Mudhari — Konjugasi Muttashil';

  @override
  String get emrIHazirMuttasilCekimler => 'Amr Hadir — Konjugasi Muttashil';

  @override
  String get cekimler => 'Konjugasi';

  @override
  String get premiumIcerik => 'Konten Premium';

  @override
  String get m5500DenFazlaFiilin3 =>
      'Buka tasrif lebih dari 5.500 kata kerja dalam 24 bentuk';

  @override
  String get ucretsizFiiller => 'Kata Kerja Gratis';

  @override
  String get listeyeEkle => 'Tambah ke Daftar';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'Silakan masuk untuk menggunakan asisten AI.';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'Berikan 5 contoh kalimat baru dengan kata ini sesuai level saya: dari mudah ke sulit.';

  @override
  String get tumFiilCekimleri => 'Semua Tasrif Fiil';

  @override
  String kokRoot(Object root) {
    return 'akar kata $root';
  }

  @override
  String get cogul => 'Jamak';

  @override
  String get ornekCumleler => 'Contoh Kalimat';

  @override
  String get cumleyiDinle => 'Dengarkan kalimat';

  @override
  String get aiAsistanASor2 => 'Tanya Asisten AI';

  @override
  String get dahaFazlaOrnek => 'Contoh lainnya';

  @override
  String get kelimeKaydetmekIcinOnceGiris => 'Masuk untuk menyimpan kata';

  @override
  String get oyna => 'Mainkan';

  @override
  String get verbFormPast => 'Madi';

  @override
  String get verbFormPresent => 'Mudhari';

  @override
  String get verbFormInfinitive => 'Mashdar';

  @override
  String get verbFormImperative => 'Amr';

  @override
  String get zamirOEril => 'Dia (laki-laki)';

  @override
  String get zamirOnlarEril => 'Mereka (laki-laki)';

  @override
  String get zamirSenEril => 'Kamu (laki-laki)';

  @override
  String get zamirSizEril => 'Kalian (laki-laki)';

  @override
  String get zamirBen => 'Saya';

  @override
  String get zamirBiz => 'Kami';

  @override
  String get dialectTr => 'Turki';

  @override
  String get dialectEn => 'Inggris';

  @override
  String get dialectDe => 'Jerman';

  @override
  String get dialectFr => 'Prancis';

  @override
  String get dialectRu => 'Rusia';

  @override
  String get dialectEs => 'Spanyol';

  @override
  String get dialectIt => 'Italia';

  @override
  String get dialectPt => 'Portugis';

  @override
  String get dialectNl => 'Belanda';

  @override
  String get dialectFa => 'Persia';

  @override
  String get dialectUr => 'Urdu';

  @override
  String get dialectId => 'Indonesia';

  @override
  String get dialectArStandard => 'Bahasa Arab Standar';

  @override
  String get dialectArSyrian => 'Bahasa Arab Suriah';

  @override
  String get dialectArLebanese => 'Bahasa Arab Lebanon';

  @override
  String get dialectArJordanian => 'Bahasa Arab Yordania';

  @override
  String get dialectArPalestinian => 'Bahasa Arab Palestina';

  @override
  String get dialectArEgyptian => 'Bahasa Arab Mesir';

  @override
  String get dialectArIraqi => 'Bahasa Arab Irak';

  @override
  String get dialectArSudanese => 'Bahasa Arab Sudan';

  @override
  String get dialectArSaudi => 'Bahasa Arab Saudi';

  @override
  String get dialectArEmirati => 'Bahasa Arab Emirat';

  @override
  String get dialectArKuwaiti => 'Bahasa Arab Kuwait';

  @override
  String get dialectArQatari => 'Bahasa Arab Qatar';

  @override
  String get dialectArOmani => 'Bahasa Arab Oman';

  @override
  String get dialectArYemeni => 'Bahasa Arab Yaman';

  @override
  String get dialectArMoroccan => 'Bahasa Arab Maroko';

  @override
  String get dialectArAlgerian => 'Bahasa Arab Aljazair';

  @override
  String get dialectArTunisian => 'Bahasa Arab Tunisia';

  @override
  String get dialectArLibyan => 'Bahasa Arab Libya';

  @override
  String get appLanguage => 'Bahasa aplikasi';

  @override
  String get typeNoun => 'Isim';

  @override
  String get typeProperNoun => 'Isim Alam';

  @override
  String get typeVerb => 'Fiil';

  @override
  String get typeVerbPast => 'Fiil Madhi';

  @override
  String get typeVerbPresent => 'Fiil Mudhari';

  @override
  String get typeVerbImperative => 'Fiil Amr';

  @override
  String get typeVerbProhibitive => 'Fiil Nahyi';

  @override
  String get typeVerbPastPassive => 'Majhul Madhi';

  @override
  String get typeVerbPresentPassive => 'Majhul Mudhari';

  @override
  String get typeVerbDefective => 'Fiil Naqish';

  @override
  String get typeMasdar => 'Mashdar';

  @override
  String get typeActiveParticiple => 'Isim Fa\'il';

  @override
  String get typePassiveParticiple => 'Isim Maf\'ul';

  @override
  String get typeElative => 'Isim Tafdhil';

  @override
  String get typeAdjective => 'Sifat';

  @override
  String get typeAdverb => 'Zharf';

  @override
  String get typeHal => 'Hal';

  @override
  String get typePronoun => 'Dhamir';

  @override
  String get typeDemonstrative => 'Isim Isyarah';

  @override
  String get typeRelative => 'Isim Maushul';

  @override
  String get typeInterrogative => 'Istifham';

  @override
  String get typePreposition => 'Harf Jar';

  @override
  String get typeParticle => 'Harf';

  @override
  String get typeNumber => 'Adad';

  @override
  String get typePhrase => 'Idhafah';

  @override
  String get typeExpression => 'Ungkapan';

  @override
  String get typeIdiom => 'Idion';

  @override
  String get siga01 => 'Fi\'il Madi';

  @override
  String get siga02 => 'Fi\'il Mudhari';

  @override
  String get siga03 => 'Mashdar';

  @override
  String get siga04 => 'Isim Fa\'il';

  @override
  String get siga05 => 'Isim Maf\'ul';

  @override
  String get siga06 => 'Fi\'il Juhd';

  @override
  String get siga07 => 'Juhd Mustaghraq';

  @override
  String get siga08 => 'Nafyu Hal';

  @override
  String get siga09 => 'Nafyu Istiqbal';

  @override
  String get siga10 => 'Taukid Nafyu';

  @override
  String get siga11 => 'Amr Ghaib';

  @override
  String get siga12 => 'Nahyu Ghaib';

  @override
  String get siga13 => 'Amr Hadir';

  @override
  String get siga14 => 'Nahyu Hadir';

  @override
  String get siga15 => 'Isim Zaman/Makan';

  @override
  String get siga16 => 'Isim Alat';

  @override
  String get siga17 => 'Isim Marrah';

  @override
  String get siga18 => 'Isim Hai\'ah';

  @override
  String get siga19 => 'Isim Tashgir';

  @override
  String get siga20 => 'Isim Mansub';

  @override
  String get siga21 => 'Mub. Ism Fâ\'il';

  @override
  String get siga22 => 'Isim Tafdhil';

  @override
  String get siga23 => 'Ta\'ajjub 1';

  @override
  String get siga24 => 'Ta\'ajjub 2';

  @override
  String get dialectMs => 'Melayu';

  @override
  String get dialectBn => 'Bengali';

  @override
  String get dialectUz => 'Uzbek';

  @override
  String get dialectAz => 'Azerbaijan';

  @override
  String get prepositionsLabel => 'Dengan Preposisi';

  @override
  String get tashkeelToggle => 'Harakat';

  @override
  String get tashkeelSettingHint =>
      'Tampilkan harakat pada definisi dan contoh';

  @override
  String get rootMatches => 'Akar yang sama';

  @override
  String get dictionaryLanguage => 'Bahasa kamus';

  @override
  String get dictionaryLanguageHint => 'Bahasa arti kata';

  @override
  String get arabicArabicDictionary => 'Kamus Arab–Arab';
}
