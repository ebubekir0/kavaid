// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get kavaidSozluk => 'Kavaid Wörterbuch';

  @override
  String get markaAdi => 'Kavaid';

  @override
  String get tanitimDevam => 'Weiter';

  @override
  String get tanitimBasla => 'Los geht\'s';

  @override
  String get tekrarDene => 'Erneut versuchen';

  @override
  String get kavaidArapcaSozluk => 'Kavaid - Arabisch-Wörterbuch';

  @override
  String get sozluk => 'Wörterbuch';

  @override
  String get ceviri => 'Übersetzen';

  @override
  String get ogren => 'Lernen';

  @override
  String get profil => 'Profil';

  @override
  String get kelimeBulunamadi => 'Wort nicht gefunden';

  @override
  String get baglantiAcilamadi => 'Link konnte nicht geöffnet werden';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'Glückwunsch! 1 Monat Premium wurde deinem Konto hinzugefügt 🌟';

  @override
  String get gecersizVeyaKullanilmisKod =>
      'Ungültiger oder bereits eingelöster Code.';

  @override
  String get buKoduDahaOnceKullandiniz =>
      'Du hast diesen Code bereits verwendet.';

  @override
  String get buKodunSuresiDolmus => 'Dieser Code ist abgelaufen.';

  @override
  String get buKodunKullanimLimitiDolmus =>
      'Das Einlöselimit dieses Codes ist erreicht.';

  @override
  String get lutfenOnceGirisYapin => 'Bitte melde dich zuerst an.';

  @override
  String get m1AyUcretsizPremiumKazan => '1 Monat Premium gratis sichern';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'Zitiere den angegebenen Tweet mit deiner Meinung über die App auf Twitter (X) und erhalte 1 Monat Premium gratis!';

  @override
  String get nasilKatilirim => 'Wie mache ich mit?';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'Zitiere den angegebenen Tweet auf Twitter (X) mit deiner Meinung zur App.';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'Sende deinen Post als Direktnachricht an @ebubekr53 auf Twitter, um deinen Code zu erhalten.';

  @override
  String get koduAsagiyaGirin => 'Code unten eingeben.';

  @override
  String get tweetiAlintila => 'Tweet zitieren';

  @override
  String get promosyonKodu => 'Promocode';

  @override
  String get kullan => 'Einlösen';

  @override
  String get dahaFazlaOzellik => 'Mehr Funktionen';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'Upgrade auf Premium, um mehr\nListen zu erstellen';

  @override
  String get kapat => 'Schließen';

  @override
  String get premiumAl => 'Premium holen';

  @override
  String get yeniListe => 'Neue Liste';

  @override
  String get listeAdi => 'Listenname';

  @override
  String get iptal => 'Abbrechen';

  @override
  String get olustur => 'Erstellen';

  @override
  String get listeyiYenidenAdlandir => 'Liste umbenennen';

  @override
  String get kaydet => 'Speichern';

  @override
  String get kelimeListelerim => 'Meine Wortlisten';

  @override
  String get yeniListeOlustur => 'Neue Liste erstellen';

  @override
  String get henuzListeYok => 'Noch keine Listen';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'Erstelle eine Liste, um deine\nWörter zu organisieren';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCount Wörter',
      one: '1 Wort',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'Umbenennen';

  @override
  String get sil => 'Löschen';

  @override
  String get listeyiSil => 'Liste löschen';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return '\"$name\" wirklich löschen?\nAlle darin enthaltenen Wörter werden ebenfalls gelöscht.';
  }

  @override
  String get buListedeHenuzKelimeYok => 'Diese Liste enthält noch keine Wörter';

  @override
  String get liste => 'Liste';

  @override
  String get kart => 'Karte';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'Upgrade auf Premium für mehr Lernkarten';

  @override
  String get premiumAYukselt => 'Auf Premium upgraden';

  @override
  String get dinle => 'Anhören';

  @override
  String get oyun => 'Spiel';

  @override
  String get kullanimSiniriDoldu => 'Nutzungslimit erreicht';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'Bitte melde dich an und upgrade auf Premium, um das Koran-Wörterbuch unbegrenzt zu nutzen.';

  @override
  String get tamam => 'OK';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'Alle Bücher freigeschaltet und Werbung entfernt.';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'Alle Bücher freigeschaltet. Melde dich an, um die Werbung dauerhaft zu entfernen.';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'Geheimcode konnte nicht angewendet werden: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'Wörterbuch wird aktualisiert... Bitte warten.';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 Wörter',
      one: '1 Wort',
    );
    return 'Wörterbuch erfolgreich aktualisiert! $_temp0 geladen.';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu =>
      'Fehler bei der Aktualisierung des Wörterbuchs!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'Fehler beim Neuladen der Datenbank: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris =>
      'Bitte erst registrieren oder anmelden.';

  @override
  String get kelimeAra => 'Wort suchen';

  @override
  String get emsile => 'Konjugation';

  @override
  String get kuranSozlugu => 'Koran-Wörterbuch';

  @override
  String get kavaidIDegerlendir => 'Kavaid bewerten';

  @override
  String get gorusunBizimIcinCokDegerli => 'Ihre Meinung ist uns sehr wichtig.';

  @override
  String get kuranSozluguYukleniyor => 'Koran-Wörterbuch wird geladen...';

  @override
  String get kuranSozlugundeAraniyor => 'Suche im Koran-Wörterbuch...';

  @override
  String get araniyor => 'Suche läuft...';

  @override
  String get kuranSozlugundeBulunamadi => 'Nicht im Koran-Wörterbuch gefunden';

  @override
  String get farkliBirKelimeVeyaKok =>
      'Versuchen Sie es mit einem anderen Wort oder einer anderen Wurzel';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'Upgrade auf Premium, um das Koran-Wörterbuch uneingeschränkt zu nutzen.';

  @override
  String get kurAnIKerimSozlugu => 'Wörterbuch des Korans';

  @override
  String get kurAnDaGecenTum =>
      'Lernen Sie die Verwendung und die koranische Bedeutung aller Wörter im Koran anhand von Versen.';

  @override
  String get kurAnDakiBenzersizTum => 'Alle einzigartigen Wörter im Koran.';

  @override
  String get kuraniAnlamlar => 'Koranische Bedeutungen';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'Erfahren Sie die Bedeutungen, die Wörter in Koranversen erhalten.';

  @override
  String get kurAnAyetleri => 'Koranverse';

  @override
  String get onBinlerceKurAnAyeti =>
      'Sehen Sie die Verwendung von Wörtern im Koran anhand von zehntausenden Versen.';

  @override
  String get kavaidArapcaSozluk2 => 'Kavaid Arabisch-Wörterbuch';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'Das erste KI-gestützte Arabisch-Wörterbuch der neuen Generation';

  @override
  String get premiumAGec => 'Zu Premium wechseln';

  @override
  String get sinirsizErisim => 'Unbegrenzter Zugriff';

  @override
  String get profilResmiGuncellendi => '✅ Profilbild aktualisiert!';

  @override
  String get birHataOlustu => 'Ein Fehler ist aufgetreten';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'Firebase Storage nicht konfiguriert. Bitte aktivieren Sie Storage in der Firebase-Konsole.';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'Berechtigungsfehler. Bitte überprüfen Sie die Storage-Regeln.';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'Authentifizierungsfehler. Bitte melden Sie sich an.';

  @override
  String get internetBaglantisiHatasi => 'Internetverbindungsfehler.';

  @override
  String get detay => 'Details';

  @override
  String get hataDetayi => 'Fehlerdetails';

  @override
  String get kullanici => 'Benutzer';

  @override
  String get kurucu => 'GRÜNDER';

  @override
  String get moderator => 'MODERATOR';

  @override
  String get emailYok => 'Keine E-Mail';

  @override
  String get cikisYapilsinMi => 'Abmelden?';

  @override
  String get oturumunuzKapatilacak => 'Sie werden abgemeldet.';

  @override
  String get cikis => 'Abmelden';

  @override
  String get aboneligiYonet => 'Abonnement verwalten';

  @override
  String get satinAlmalarKontrolEdiliyor => 'Käufe werden überprüft...';

  @override
  String get geriYukle => 'Wiederherstellen';

  @override
  String get girisYapinVeyaKayitOlun => 'Anmelden oder registrieren';

  @override
  String get girisYap => 'Anmelden';

  @override
  String get kayitOl => 'Registrieren';

  @override
  String get premiumUyesiniz => 'Sie sind Premium-Mitglied';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'Unbegrenzte Inhalte, werbefreie Nutzung.';

  @override
  String get tumOzelliklereErisin => 'Zugriff auf alle Funktionen.';

  @override
  String get reklamsizKullanim => 'Werbefreie Nutzung';

  @override
  String get uygulamayiPaylas => 'App teilen';

  @override
  String get iletisim => 'Kontakt';

  @override
  String get kavaidUygulamasiHakkinda => 'Über die Kavaid-App';

  @override
  String get hesabimiSil => 'Konto löschen';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'Sind Sie sicher, dass Sie Ihr Konto und alle damit verbundenen Daten dauerhaft löschen möchten? Dieser Vorgang kann nicht rückgängig gemacht werden.';

  @override
  String get vazgec => 'Abbrechen';

  @override
  String get hesabinizBasariylaSilindi =>
      'Ihr Konto wurde erfolgreich gelöscht.';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'Konto konnte nicht gelöscht werden: $e. Aus Sicherheitsgründen müssen Sie sich möglicherweise erneut anmelden.';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi => 'Kavaid – Arabisch-Wörterbuch App';

  @override
  String get paylasimSirasindaBirHataOlustu =>
      'Beim Teilen ist ein Fehler aufgetreten';

  @override
  String get internetGerekli => 'Internet erforderlich';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'Für diesen Vorgang ist eine Internetverbindung erforderlich.';

  @override
  String get kullaniciAdiDegistir => 'Benutzername ändern';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'Aktuell: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'Neuer Benutzername';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'nutzername123 (kleingeschrieben, ohne Leerzeichen)';

  @override
  String get enAz3KarakterSadece =>
      '• Mindestens 3 Zeichen\n• Nur Kleinbuchstaben und Zahlen';

  @override
  String get kullaniciAdiEnAz3 =>
      'Der Benutzername muss mindestens 3 Zeichen lang sein';

  @override
  String get sadeceKucukHarfRakamVe => 'Nur Kleinbuchstaben und Zahlen erlaubt';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'Dein Benutzername wurde zu \"$newUsername\" geändert!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'Dieser Benutzername ist nicht verfügbar oder bereits vergeben';

  @override
  String get degistir => 'Ändern';

  @override
  String get premiumUyelikAktif => '🎉 Premium-Mitgliedschaft aktiv!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'Verbindung konnte nicht hergestellt werden: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'Bitte melde dich an, um Premium zu kaufen.';

  @override
  String hataE(Object e) {
    return 'Fehler: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid Premium';

  @override
  String get aiAsistanASinirsizErisim =>
      'Unbegrenzter Zugriff auf den KI-Assistenten';

  @override
  String get ceviriyeSinirsizErisim => 'Unbegrenzter Zugriff auf Übersetzungen';

  @override
  String get m5500Fiilin24Siga =>
      'Konjugation von über 5.500 Verben in 24 Formen freischalten';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'Zugriff auf alle Lernmaterialien';

  @override
  String get kuranSozluguneSinirsizErisim =>
      'Unbegrenzter Zugriff auf das Koran-Wörterbuch';

  @override
  String get sinirsizKelimeKartiVeListe =>
      'Unbegrenzte Vokabelkarten und Listen erstellen';

  @override
  String get reklamsizDeneyim => 'Werbefreie Nutzung';

  @override
  String get aylikAbonelik => 'Monatsabo';

  @override
  String get m1AyBoyuncaSinirsizErisim => '1 Monat unbegrenzter Zugriff';

  @override
  String get yillikAbonelik => 'Jahresabo';

  @override
  String get m1YilBoyuncaSinirsizErisim => '1 Jahr unbegrenzter Zugriff';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return '1 Jahr unbegrenzter Zugriff ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return '$yearlyDiscount% RABATT';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Monatlich abonnieren$buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'Jährlich abonnieren$buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'Die Zahlung erfolgt über deine Apple ID. Das Abonnement verlängert sich automatisch, sofern es nicht mindestens 24 Stunden vor Ende des Zeitraums gekündigt wird. Du kannst es jederzeit in deinen App-Store-Kontoeinstellungen verwalten.';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'Die Zahlung erfolgt über Google Play. Das Abonnement verlängert sich automatisch, sofern es nicht mindestens 24 Stunden vor Ende des Zeitraums gekündigt wird. Du kannst es jederzeit in deinen Google-Play-Kontoeinstellungen verwalten.';

  @override
  String get satinAlmalariGeriYukle => 'Käufe wiederherstellen';

  @override
  String get kullanimKosullariEula => 'Nutzungsbedingungen (EULA)';

  @override
  String get gizlilikPolitikasi => 'Datenschutzrichtlinie';

  @override
  String get metinGirin => 'Text eingeben';

  @override
  String get harekeAc => 'Vokalisierung anzeigen';

  @override
  String get kopyala => 'Kopieren';

  @override
  String get kopyalandi => 'Kopiert';

  @override
  String get cevir => 'Übersetzen';

  @override
  String get suDileCevir => 'In diese Sprache übersetzen';

  @override
  String get premiumAGecin => 'Zu Premium wechseln';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'Werde Premium-Mitglied für mehr Übersetzungen.';

  @override
  String get lutfenOnceKayitOlupGiris =>
      'Bitte registriere dich und melde dich an.';

  @override
  String get diller => 'Sprachen';

  @override
  String get lehceler => 'Dialekte';

  @override
  String get internetBaglantisiGerekiyor => 'Internetverbindung erforderlich.';

  @override
  String get aiAsistanSuAnKullanilamiyor =>
      'Der KI-Assistent ist derzeit nicht verfügbar.';

  @override
  String get yanitGelmedi => 'Keine Antwort erhalten.';

  @override
  String get suAndaCevapAlinamadi => 'Konnte derzeit nicht antworten.';

  @override
  String get hazir => 'Bereit.';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'Für den KI-Wortschatz-Assistenten ist eine Internetverbindung erforderlich.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'Dein tägliches Limit für den kostenlosen KI-Wortschatz-Assistenten ist erreicht.';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'Der API-Schlüssel des KI-Lehrers ist ungültig. Bitte überprüfe den Firebase gemini_api-Wert.';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'Der KI-Wortschatz-Assistent konnte nicht antworten. Bitte versuche es erneut.';

  @override
  String get yukleniyor => 'Lädt...';

  @override
  String get sozlukHazir => 'Wörterbuch bereit.';

  @override
  String get sozlukYuklenemedi => 'Wörterbuch konnte nicht geladen werden.';

  @override
  String get ekranHazirlaniyor => 'Bildschirm wird vorbereitet...';

  @override
  String get sozlukKontrolEdiliyor => 'Wörterbuch wird überprüft...';

  @override
  String get sozlukAyarlaniyor => 'Wörterbuch wird eingerichtet...';

  @override
  String get aramaHazirlaniyor => 'Suche wird vorbereitet...';

  @override
  String get aramaHazir => 'Suche bereit.';

  @override
  String get internetBaglantisiYok => 'Keine Internetverbindung';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'Du benötigst eine Internetverbindung, um die App nutzen zu können. Bitte prüfe deine WLAN- oder mobile Datenverbindung.';

  @override
  String get sozlukHazirlaniyor => 'Wörterbuch wird vorbereitet...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    String _temp0 = intl.Intl.pluralLogic(
      existingCount,
      locale: localeName,
      other: 'Wörterbuch bereit. $existingCount Wörter vorhanden.',
      one: 'Wörterbuch bereit. 1 Wort vorhanden.',
    );
    return '$_temp0';
  }

  @override
  String get kelimelerYukleniyor => 'Wörter werden geladen...';

  @override
  String get sozlukHazir2 => 'Wörterbuch bereit!';

  @override
  String get mevcutVeritabaniKullanilacak =>
      'Vorhandene Datenbank wird verwendet.';

  @override
  String get hicGuncellenmedi => 'Nie aktualisiert';

  @override
  String get girisYapmalisiniz => 'Du musst dich anmelden.';

  @override
  String get paketBulunamadiLifetime => 'Paket nicht gefunden (Lifetime).';

  @override
  String get hataOlustu => 'Ein Fehler ist aufgetreten';

  @override
  String beklenmedikHataE(Object e) {
    return 'Unerwarteter Fehler: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'RevenueCat konnte nicht gestartet werden: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris => 'Bitte melde dich vor dem Kauf an.';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'Kauffehler: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'Abonnement-Paket konnte nicht geladen werden. Bitte prüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'Für die Kaufprüfung ist eine Internetverbindung erforderlich.';

  @override
  String get aktifBirAbonelikBulunamadi => 'Kein aktives Abonnement gefunden.';

  @override
  String restoreHatasiE(Object e) {
    return 'Wiederherstellungsfehler: $e';
  }

  @override
  String get hataOlustu2 => 'Ein Fehler ist aufgetreten.';

  @override
  String get ceviriIcinGirisYapmanGerekiyor =>
      'Du musst dich anmelden, um übersetzen zu können.';

  @override
  String get premiumKullanici => 'Premium-Nutzer.';

  @override
  String get ceviriHakkiKullanildi => 'Übersetzungslimit erreicht.';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'Übersetzungslimit konnte nicht geprüft werden. Prüfe deine Verbindung.';

  @override
  String get yeniSohbet => 'Neuer Chat';

  @override
  String get buSohbetinGecmisiSilinsinMi =>
      'Soll der Verlauf dieses Chats gelöscht werden?';

  @override
  String get aiAsistan => 'KI-Assistent';

  @override
  String get hakkinda => ' über';

  @override
  String get arapcaSozlukYardimcin => 'Dein Arabisch-Wörterbuch-Assistent';

  @override
  String get bugunkuUcretsizSoruHakkin => 'Deine täglichen kostenlosen Fragen';

  @override
  String get arapcasiniDinle => 'Arabische Aussprache hören';

  @override
  String get tekrarDene2 => 'Erneut versuchen';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    return 'Dein Limit von $freeDailyLimit kostenlosen Fragen für heute ist erreicht';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'Dein Limit wird morgen zurückgesetzt. Mit Premium kannst du unbegrenzt fragen.';

  @override
  String get premiumAGec2 => 'Zu Premium wechseln';

  @override
  String get kisacaAnlat => 'Erkläre es kurz';

  @override
  String get m3OrnekCumleVer => 'Nenne 3 Beispielsätze';

  @override
  String get benzerKelimelerdenFarkiNe =>
      'Was ist der Unterschied zu ähnlichen Wörtern?';

  @override
  String get okunusunuLatinHarfleriyleYaz =>
      'Schreibe die Aussprache in lateinischen Buchstaben';

  @override
  String get gecmisZamanNasilKurulur =>
      'Wie bildet man die Vergangenheitsform?';

  @override
  String get harfICerNedir => 'Was ist eine Präposition (Harf-i Cer)?';

  @override
  String get isimCumlesiNasilKurulur => 'Wie bildet man einen Nominalsatz?';

  @override
  String get enSikKullanilan10Fiil => 'Die 10 häufigsten Verben';

  @override
  String get sonSorduklarim => 'Zuletzt gefragt';

  @override
  String get ornekSorular => 'Beispielfragen';

  @override
  String get buKelimeHakkindaKisaVe =>
      'Erhalte eine kurze und klare Antwort zu diesem Wort.';

  @override
  String get arapcaSorunuYaz => 'Schreibe deine arabische Frage';

  @override
  String get kisaVeNetCevapVerir =>
      'Gibt kurze und klare Antworten, ohne zu raten.';

  @override
  String get ornekVer => 'Gib ein Beispiel';

  @override
  String get dahaBasitAnlat => 'Erkläre es einfacher';

  @override
  String get derinles => 'Gehe ins Detail';

  @override
  String get cekiminiGoster => 'Zeige die Konjugation';

  @override
  String get aiAsistanASor => 'Frag den KI-Assistenten...';

  @override
  String get yeniAiAsistan => 'Neu: KI-Assistent';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'Tippe auf dieses Symbol links in der Wortkarte, um nach der Bedeutung, Unterschieden zu ähnlichen Wörtern oder Beispielsätzen zu fragen.';

  @override
  String get anladim => 'Verstanden';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'Gib mehr Beispiele für dieses Wort nach Schwierigkeitsgrad: einfach, mittel, Alltagssprache, grammatikorientiert und Fragesätze.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'Dein tägliches kostenloses Kontingent für den KI-Wortassistenten ist aufgebraucht. Werde Premium-Nutzer, um fortzufahren.';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'Antwort konnte nicht geladen werden. Bitte prüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get aiKelimeAsistani => 'KI-Wortassistent';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    return 'KI-Wortassistent · $remaining kostenlose Nutzung';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi =>
      'KI-Wortassistent konnte nicht geladen werden.';

  @override
  String get premiumAGec3 => 'Zu Premium wechseln';

  @override
  String get kisacaAnlat2 => 'Kurze Erklärung';

  @override
  String get gramerNotlari => 'Grammatikhinweise';

  @override
  String get kullanimNotlari => 'Gebrauchshinweise';

  @override
  String get buKelimeNeredeKullanilir => 'Wo wird dieses Wort verwendet?';

  @override
  String get m5YeniOrnekVer => 'Gib 5 neue Beispiele';

  @override
  String get kolayCumlelerleAnlat => 'Erkläre mit einfachen Sätzen';

  @override
  String get cekimleOrnekVer => 'Beispiele mit Konjugationen';

  @override
  String get harfICerFarkiniAnlat =>
      'Erkläre den Unterschied der Präpositionen';

  @override
  String get ornekleOgren => 'Lerne durch Beispiele';

  @override
  String get miniAlistirma => 'Mini-Übung';

  @override
  String get hazirSorular => 'Vorgefertigte Fragen';

  @override
  String get sor => 'Fragen';

  @override
  String get buKelimeyleIlgiliSoruSor => 'Stelle eine Frage zu diesem Wort';

  @override
  String get arapcaTurkceSozluk => 'Arabisch-Englisches Wörterbuch';

  @override
  String get arapcaYaDaTurkceYaz =>
      'Schreibe auf Arabisch oder Englisch – alles auf einer Karte.';

  @override
  String get sesleYaDaArapcaKlavyeyle =>
      'Per Stimme oder arabischer Tastatur suchen';

  @override
  String get kokCogulVeOrnekCumleler => 'Wurzel, Plural und Beispielsätze';

  @override
  String get fiilKarti => 'Verbkarte';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'Verbkonjugationen direkt auf der Karte.';

  @override
  String get maziMuzariMastarVeEmir => 'Mazi, Müzari, Mastar und Imperativ';

  @override
  String get tumCekimlerIcinEmsileyeGec => 'Alle Formen unter Konjugation';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'Tippe auf das Symbol ganz links auf der Wortkarte.';

  @override
  String get sorunuYazYaDaHazir =>
      'Schreibe deine Frage oder wähle eine vorgegebene.';

  @override
  String get kisaVeNetCevap => 'Kurze und klare Antwort';

  @override
  String get m5500DenFazlaFiilin =>
      'Konjugationstabellen für über 5.500 Verben.';

  @override
  String get fiileDokunKartiAcilsin =>
      'Tippe auf das Verb, um die Karte zu öffnen';

  @override
  String get anlamlariVe24SigaCekimi => 'Bedeutungen und alle 24 Formen';

  @override
  String get kurAnSozlugu => 'Koran-Wörterbuch';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'Lerne Koranwörter anhand der Verse.';

  @override
  String get kelimeVeKurAniAnlamlari => 'Wort und seine Bedeutung im Koran';

  @override
  String get gectigiAyetVeMeali => 'Der Vers und seine Übersetzung';

  @override
  String get lehceCeviri => 'Dialektübersetzung';

  @override
  String get turkceYazYaDaKonus =>
      'Schreibe oder sprich auf Deutsch, übersetze in 17 Dialekte.';

  @override
  String get karsiligiVeOkunusu => 'Entsprechung und Aussprache';

  @override
  String get lehceyiSecYaDaSesle =>
      'Wähle einen Dialekt oder sag es per Sprachbefehl';

  @override
  String get listelerVeKartlar => 'Listen und Karten';

  @override
  String get kaydettiginHerSeyTekYerde =>
      'Alles, was du speicherst, an einem Ort.';

  @override
  String get listeYaDaKartlarlaTekrar => 'Wiederhole mit Listen oder Karten';

  @override
  String get sozlukKurAnVeEmsile =>
      'Einträge aus Wörterbuch, Koran und Konjugation';

  @override
  String get a1DenC1EResimli =>
      'Illustrierte arabische Geschichten von A1 bis C1.';

  @override
  String get kelimeyeDokunAnlamiCiksin =>
      'Tippe auf ein Wort für die Bedeutung';

  @override
  String get metniSesliDinle => 'Text anhören';

  @override
  String get gec => 'Überspringen';

  @override
  String get yeni => 'NEU';

  @override
  String get ara => 'Suche';

  @override
  String get bosluk => 'Leerzeichen';

  @override
  String get hesabinizYoksaOnceKayitOlun =>
      'Falls du noch kein Konto hast, registriere dich bitte zuerst.';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'Nach der Registrierung musst du dich anmelden.';

  @override
  String get ePosta => 'E-Mail';

  @override
  String get gecersizEPostaAdresi => 'Ungültige E-Mail-Adresse';

  @override
  String get sifre => 'Passwort';

  @override
  String get sifreGerekli => 'Passwort erforderlich';

  @override
  String get sifremiUnuttum => 'Passwort vergessen';

  @override
  String get sifreTekrar => 'Passwort wiederholen';

  @override
  String get sifreTekrariGerekli => 'Passwortbestätigung erforderlich';

  @override
  String get sifrelerEslesmiyor => 'Passwörter stimmen nicht überein';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'Gib bitte deine E-Mail-Adresse ein, um dein Passwort zurückzusetzen.';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return 'Falls ein Konto mit $email verknüpft ist, wurde ein Link zum Zurücksetzen des Passworts gesendet. Bitte prüfe deinen Posteingang und den Spam-Ordner.';
  }

  @override
  String get gecerliBirEPostaAdresi =>
      'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get buEPostaIleKayit =>
      'Es wurde kein Konto mit dieser E-Mail-Adresse gefunden.';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'Zu viele Versuche. Bitte versuche es später noch einmal.';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'Netzwerkfehler. Bitte prüfe deine Internetverbindung.';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'Der Link konnte nicht gesendet werden. Bitte versuche es erneut.';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 Willkommen! Dein Konto wurde erfolgreich erstellt.';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'Vorgang fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get ePostaVeyaSifreHatali =>
      'E-Mail oder Passwort falsch. Bitte prüfe deine Eingaben.';

  @override
  String get sifreHatali => 'Passwort falsch.';

  @override
  String get buEPostaZatenKayitli => 'Diese E-Mail ist bereits registriert.';

  @override
  String get sifreCokZayifDahaGuclu =>
      'Passwort zu schwach. Bitte wähle ein sichereres Passwort.';

  @override
  String get buGirisYontemiProjeIcin =>
      'Diese Anmeldemethode ist für dieses Projekt nicht aktiviert.';

  @override
  String get oDisil => 'Sie (weiblich)';

  @override
  String get ikisi => 'Sie beide';

  @override
  String get ikisiEril => 'Beide (mask.)';

  @override
  String get ikisiDisil => 'Beide (fem.)';

  @override
  String get onlarDisil => 'Sie (fem.)';

  @override
  String get senDisil => 'Du (weiblich)';

  @override
  String get ikiniz => 'Ihr beide';

  @override
  String get sizDisil => 'Ihr (fem.)';

  @override
  String get m3Sahis => 'غَائِب (3. Person)';

  @override
  String get m2Sahis => 'مُخَاطَب (2. Person)';

  @override
  String get m1Sahis => 'مُتَكَلِّم (1. Person)';

  @override
  String get muzari => 'Muzari';

  @override
  String get emsileCekimleri => 'Verbkonjugationen';

  @override
  String get maziGecmis => 'Vergangenheit';

  @override
  String get muzariGenis => 'Gegenwart';

  @override
  String get emir => 'Imperativ';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return '$tabTitle-Konjugation nicht gefunden';
  }

  @override
  String get kok => 'Wurzel';

  @override
  String get ismIFail => 'Ism-i Fâ\'il';

  @override
  String get ismIMefUl => 'Ism-i Maf\'ûl';

  @override
  String get fiilCekimleriKavaidSozluk =>
      'Verbkonjugationen • Kavaid Wörterbuch';

  @override
  String get m5500DenFazlaFiilin2 =>
      'Lerne die Konjugation von über 5.500 Verben in allen 24 Formen.';

  @override
  String get tumFiilleriAc => 'Alle Verben freischalten';

  @override
  String get dahaFazlaFiilYukle => 'Weitere Verben laden';

  @override
  String get arananKelimeBulunamadi => 'Kein Ergebnis gefunden';

  @override
  String get fiilIMaziMuttasilCekimler => 'Fi\'l-i Mâzî — Konjugationen';

  @override
  String get fiilIMuzariMuttasilCekimler => 'Fi\'l-i Muzâri — Konjugationen';

  @override
  String get emrIHazirMuttasilCekimler => 'Amr-i Hâdır — Konjugationen';

  @override
  String get cekimler => 'Konjugationen';

  @override
  String get premiumIcerik => 'Premium-Inhalte';

  @override
  String get m5500DenFazlaFiilin3 =>
      'Schalte die Konjugation von über 5.500 Verben in allen 24 Formen frei.';

  @override
  String get ucretsizFiiller => 'Kostenlose Verben';

  @override
  String get listeyeEkle => 'Zur Liste hinzufügen';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'Bitte melde dich an, um den KI-Assistenten zu nutzen.';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'Gib mir 5 Beispiele für dieses Wort, angepasst an mein Niveau: von leicht bis schwer.';

  @override
  String get tumFiilCekimleri => 'Alle Verbkonjugationen';

  @override
  String kokRoot(Object root) {
    return 'Wurzel $root';
  }

  @override
  String get cogul => 'Plural';

  @override
  String get ornekCumleler => 'Beispielsätze';

  @override
  String get cumleyiDinle => 'Satz anhören';

  @override
  String get aiAsistanASor2 => 'KI-Assistent fragen';

  @override
  String get dahaFazlaOrnek => 'Weitere Beispiele';

  @override
  String get kelimeKaydetmekIcinOnceGiris =>
      'Bitte melden Sie sich an, um Wörter zu speichern';

  @override
  String get oyna => 'Spielen';

  @override
  String get verbFormPast => 'Verg.';

  @override
  String get verbFormPresent => 'Gegenwart';

  @override
  String get verbFormInfinitive => 'Infinitiv';

  @override
  String get verbFormImperative => 'Imperativ';

  @override
  String get zamirOEril => 'Er';

  @override
  String get zamirOnlarEril => 'Sie (mask. Pl.)';

  @override
  String get zamirSenEril => 'Du (mask.)';

  @override
  String get zamirSizEril => 'Ihr (mask.)';

  @override
  String get zamirBen => 'Ich';

  @override
  String get zamirBiz => 'Wir';

  @override
  String get dialectTr => 'Türkisch';

  @override
  String get dialectEn => 'Englisch';

  @override
  String get dialectDe => 'Deutsch';

  @override
  String get dialectFr => 'Französisch';

  @override
  String get dialectRu => 'Russisch';

  @override
  String get dialectEs => 'Spanisch';

  @override
  String get dialectIt => 'Italienisch';

  @override
  String get dialectPt => 'Portugiesisch';

  @override
  String get dialectNl => 'Niederländisch';

  @override
  String get dialectFa => 'Persisch';

  @override
  String get dialectUr => 'Urdu';

  @override
  String get dialectId => 'Indonesisch';

  @override
  String get dialectArStandard => 'Hocharabisch';

  @override
  String get dialectArSyrian => 'Syrisches Arabisch';

  @override
  String get dialectArLebanese => 'Libanesisches Arabisch';

  @override
  String get dialectArJordanian => 'Jordanisches Arabisch';

  @override
  String get dialectArPalestinian => 'Palästinensisches Arabisch';

  @override
  String get dialectArEgyptian => 'Ägyptisches Arabisch';

  @override
  String get dialectArIraqi => 'Irakisches Arabisch';

  @override
  String get dialectArSudanese => 'Sudanesisches Arabisch';

  @override
  String get dialectArSaudi => 'Saudi-arabisches Arabisch';

  @override
  String get dialectArEmirati => 'Emiratisch';

  @override
  String get dialectArKuwaiti => 'Kuwaitisches Arabisch';

  @override
  String get dialectArQatari => 'Katarisches Arabisch';

  @override
  String get dialectArOmani => 'Omanisches Arabisch';

  @override
  String get dialectArYemeni => 'Jemenitisches Arabisch';

  @override
  String get dialectArMoroccan => 'Marokkanisches Arabisch';

  @override
  String get dialectArAlgerian => 'Algerisches Arabisch';

  @override
  String get dialectArTunisian => 'Tunesisches Arabisch';

  @override
  String get dialectArLibyan => 'Libysches Arabisch';

  @override
  String get appLanguage => 'App-Sprache';

  @override
  String get typeNoun => 'Nomen';

  @override
  String get typeProperNoun => 'Eigenname';

  @override
  String get typeVerb => 'Verb';

  @override
  String get typeVerbPast => 'Māḍī-Verb';

  @override
  String get typeVerbPresent => 'Muḍāriʿ-Verb';

  @override
  String get typeVerbImperative => 'Imperativ';

  @override
  String get typeVerbProhibitive => 'Prohibitiv';

  @override
  String get typeVerbPastPassive => 'Passiv (Māḍī)';

  @override
  String get typeVerbPresentPassive => 'pass. Imp.';

  @override
  String get typeVerbDefective => 'Defektivverb';

  @override
  String get typeMasdar => 'Maṣdar';

  @override
  String get typeActiveParticiple => 'Akt. Part.';

  @override
  String get typePassiveParticiple => 'Pass. Part.';

  @override
  String get typeElative => 'Elativ';

  @override
  String get typeAdjective => 'Adjektiv';

  @override
  String get typeAdverb => 'Adverb';

  @override
  String get typeHal => 'Ḥāl';

  @override
  String get typePronoun => 'Pronomen';

  @override
  String get typeDemonstrative => 'Demonstrativ';

  @override
  String get typeRelative => 'Relativpron.';

  @override
  String get typeInterrogative => 'Interrogativ';

  @override
  String get typePreposition => 'Präposition';

  @override
  String get typeParticle => 'Partikel';

  @override
  String get typeNumber => 'Zahl';

  @override
  String get typePhrase => 'Konstrukt';

  @override
  String get typeExpression => 'Ausdruck';

  @override
  String get typeIdiom => 'Redewendung';

  @override
  String get siga01 => 'Vergangenheit';

  @override
  String get siga02 => 'Gegenwart';

  @override
  String get siga03 => 'Masdar';

  @override
  String get siga04 => 'Aktiv-Partizip';

  @override
  String get siga05 => 'Passiv-Partizip';

  @override
  String get siga06 => 'Verneint (Verg.)';

  @override
  String get siga07 => 'Nicht geschehen';

  @override
  String get siga08 => 'Verneint (Gegw.)';

  @override
  String get siga09 => 'Verneint (Fut.)';

  @override
  String get siga10 => 'Emphat. Verneint';

  @override
  String get siga11 => 'Befehl 3. Pers.';

  @override
  String get siga12 => 'Verbot 3. Pers.';

  @override
  String get siga13 => 'Imperativ';

  @override
  String get siga14 => 'Verbot';

  @override
  String get siga15 => 'Zeit-/Ort-Nomen';

  @override
  String get siga16 => 'Instrumental-N.';

  @override
  String get siga17 => 'Einmaligkeit';

  @override
  String get siga18 => 'Art und Weise';

  @override
  String get siga19 => 'Diminutiv';

  @override
  String get siga20 => 'Nisba-Adjektiv';

  @override
  String get siga21 => 'Int. Akt. Part.';

  @override
  String get siga22 => 'Elativ';

  @override
  String get siga23 => 'Exklamation 1';

  @override
  String get siga24 => 'Exklamation 2';

  @override
  String get dialectMs => 'Malaiisch';

  @override
  String get dialectBn => 'Bengalisch';

  @override
  String get dialectUz => 'Usbekisch';

  @override
  String get dialectAz => 'Aserbaidschanisch';

  @override
  String get prepositionsLabel => 'mit Präpositionen';

  @override
  String get tashkeelToggle => 'Vokalzeichen';

  @override
  String get tashkeelSettingHint =>
      'Vokalzeichen in Definitionen und Beispielen zeigen';

  @override
  String get rootMatches => 'Gleiche Wurzel';

  @override
  String get dictionaryLanguage => 'Wörterbuchsprache';

  @override
  String get dictionaryLanguageHint => 'Sprache der Wortbedeutungen';

  @override
  String get arabicArabicDictionary => 'Arabisch–arabisches Wörterbuch';
}
