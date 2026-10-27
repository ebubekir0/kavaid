// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get kavaidSozluk => 'Dictionnaire Kavaid';

  @override
  String get markaAdi => 'Kavaid';

  @override
  String get tanitimDevam => 'Continuer';

  @override
  String get tanitimBasla => 'Commencer';

  @override
  String get tekrarDene => 'Réessayer';

  @override
  String get kavaidArapcaSozluk => 'Kavaid - Dictionnaire arabe';

  @override
  String get sozluk => 'Dictionnaire';

  @override
  String get ceviri => 'Traduction';

  @override
  String get ogren => 'Apprendre';

  @override
  String get profil => 'Profil';

  @override
  String get kelimeBulunamadi => 'Mot introuvable';

  @override
  String get baglantiAcilamadi => 'Impossible d\'ouvrir le lien';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'Félicitations ! 1 mois Premium ajouté à votre compte 🌟';

  @override
  String get gecersizVeyaKullanilmisKod => 'Code invalide ou déjà utilisé.';

  @override
  String get buKoduDahaOnceKullandiniz => 'Vous avez déjà utilisé ce code.';

  @override
  String get buKodunSuresiDolmus => 'Ce code est expiré.';

  @override
  String get buKodunKullanimLimitiDolmus =>
      'La limite d\'utilisation de ce code a été atteinte.';

  @override
  String get lutfenOnceGirisYapin => 'Veuillez d\'abord vous connecter.';

  @override
  String get m1AyUcretsizPremiumKazan => 'Gagnez 1 mois Premium gratuit';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'Partagez votre avis sur l\'application en citant le tweet indiqué sur Twitter (X) pour gagner 1 mois Premium gratuit !';

  @override
  String get nasilKatilirim => 'Comment participer ?';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'Partagez votre avis sur l\'application en citant le tweet indiqué sur Twitter (X).';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'Envoyez votre partage en message privé au compte @ebubekr53 sur Twitter pour recevoir votre code.';

  @override
  String get koduAsagiyaGirin => 'Entrez le code ci-dessous.';

  @override
  String get tweetiAlintila => 'Citer le tweet';

  @override
  String get promosyonKodu => 'Code promotionnel';

  @override
  String get kullan => 'Utiliser';

  @override
  String get dahaFazlaOzellik => 'Plus de fonctionnalités';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'Passez à Premium pour\ncréer plus de listes';

  @override
  String get kapat => 'Fermer';

  @override
  String get premiumAl => 'Devenir Premium';

  @override
  String get yeniListe => 'Nouvelle liste';

  @override
  String get listeAdi => 'Nom de la liste';

  @override
  String get iptal => 'Annuler';

  @override
  String get olustur => 'Créer';

  @override
  String get listeyiYenidenAdlandir => 'Renommer la liste';

  @override
  String get kaydet => 'Enregistrer';

  @override
  String get kelimeListelerim => 'Mes listes de mots';

  @override
  String get yeniListeOlustur => 'Créer une nouvelle liste';

  @override
  String get henuzListeYok => 'Aucune liste pour l\'instant';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'Créez une liste pour\norganiser vos mots';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCount mots',
      one: '1 mot',
      zero: '0 mots',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'Renommer';

  @override
  String get sil => 'Supprimer';

  @override
  String get listeyiSil => 'Supprimer la liste';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return 'Supprimer \"$name\" ?\nTous les mots qu\'elle contient seront également supprimés.';
  }

  @override
  String get buListedeHenuzKelimeYok => 'Cette liste ne contient aucun mot';

  @override
  String get liste => 'Liste';

  @override
  String get kart => 'Carte';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'Passez à Premium pour plus de cartes mémo';

  @override
  String get premiumAYukselt => 'Passer à Premium';

  @override
  String get dinle => 'Écouter';

  @override
  String get oyun => 'Jeu';

  @override
  String get kullanimSiniriDoldu => 'Limite d\'utilisation atteinte';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'Veuillez vous connecter et passer à Premium pour utiliser le dictionnaire du Coran en illimité.';

  @override
  String get tamam => 'OK';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'Tous les ouvrages ont été débloqués et les publicités supprimées.';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'Tous les ouvrages sont débloqués. Veuillez vous connecter pour supprimer définitivement les publicités.';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'Impossible d\'appliquer le code secret : $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'Mise à jour du dictionnaire... Veuillez patienter.';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    return 'Dictionnaire mis à jour avec succès ! $p1 mots chargés.';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu =>
      'Une erreur est survenue lors de la mise à jour du dictionnaire !';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'Erreur de rechargement de la base de données : $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris =>
      'Veuillez vous inscrire ou vous connecter d\'abord.';

  @override
  String get kelimeAra => 'Rechercher un mot';

  @override
  String get emsile => 'Conjugaison';

  @override
  String get kuranSozlugu => 'Dictionnaire coranique';

  @override
  String get kavaidIDegerlendir => 'Évaluer Kavaid';

  @override
  String get gorusunBizimIcinCokDegerli => 'Votre avis nous est précieux.';

  @override
  String get kuranSozluguYukleniyor =>
      'Chargement du dictionnaire coranique...';

  @override
  String get kuranSozlugundeAraniyor =>
      'Recherche dans le dictionnaire coranique...';

  @override
  String get araniyor => 'Recherche...';

  @override
  String get kuranSozlugundeBulunamadi =>
      'Non trouvé dans le dictionnaire coranique';

  @override
  String get farkliBirKelimeVeyaKok =>
      'Essayez un autre mot ou une autre racine';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'Passez à Premium pour un accès illimité au dictionnaire coranique.';

  @override
  String get kurAnIKerimSozlugu => 'Dictionnaire du Saint Coran';

  @override
  String get kurAnDaGecenTum =>
      'Découvrez les usages et les significations coraniques de tous les mots du Coran, accompagnés de leurs versets.';

  @override
  String get kurAnDakiBenzersizTum => 'Tous les mots uniques du Coran.';

  @override
  String get kuraniAnlamlar => 'Significations coraniques';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'Découvrez le sens des mots dans les versets du Coran.';

  @override
  String get kurAnAyetleri => 'Versets du Coran';

  @override
  String get onBinlerceKurAnAyeti =>
      'Découvrez l\'usage des mots grâce à des dizaines de milliers de versets coraniques.';

  @override
  String get kavaidArapcaSozluk2 => 'Dictionnaire arabe Kavaid';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'Le premier dictionnaire arabe propulsé par une IA de nouvelle génération';

  @override
  String get premiumAGec => 'Passer à Premium';

  @override
  String get sinirsizErisim => 'Accès illimité';

  @override
  String get profilResmiGuncellendi => '✅ Photo de profil mise à jour !';

  @override
  String get birHataOlustu => 'Une erreur est survenue';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'Firebase Storage n\'est pas configuré. Veuillez l\'activer depuis la console Firebase.';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'Erreur de permission. Vérifiez les règles de stockage.';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'Erreur d\'authentification. Veuillez vous connecter.';

  @override
  String get internetBaglantisiHatasi => 'Erreur de connexion internet.';

  @override
  String get detay => 'Détail';

  @override
  String get hataDetayi => 'Détail de l\'erreur';

  @override
  String get kullanici => 'Utilisateur';

  @override
  String get kurucu => 'FONDATEUR';

  @override
  String get moderator => 'MODÉRATEUR';

  @override
  String get emailYok => 'Aucun e-mail';

  @override
  String get cikisYapilsinMi => 'Se déconnecter ?';

  @override
  String get oturumunuzKapatilacak => 'Votre session sera fermée.';

  @override
  String get cikis => 'Déconnexion';

  @override
  String get aboneligiYonet => 'Gérer l\'abonnement';

  @override
  String get satinAlmalarKontrolEdiliyor => 'Vérification des achats...';

  @override
  String get geriYukle => 'Restaurer';

  @override
  String get girisYapinVeyaKayitOlun => 'Connectez-vous ou inscrivez-vous';

  @override
  String get girisYap => 'Connexion';

  @override
  String get kayitOl => 'Inscription';

  @override
  String get premiumUyesiniz => 'Vous êtes membre Premium';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'Contenu illimité, sans publicité.';

  @override
  String get tumOzelliklereErisin => 'Accédez à toutes les fonctionnalités.';

  @override
  String get reklamsizKullanim => 'Usage sans publicité';

  @override
  String get uygulamayiPaylas => 'Partager l\'application';

  @override
  String get iletisim => 'Contact';

  @override
  String get kavaidUygulamasiHakkinda => 'À propos de l\'application Kavaid';

  @override
  String get hesabimiSil => 'Supprimer mon compte';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'Êtes-vous sûr de vouloir supprimer définitivement votre compte et toutes les données qui y sont associées ? Cette action est irréversible.';

  @override
  String get vazgec => 'Annuler';

  @override
  String get hesabinizBasariylaSilindi =>
      'Votre compte a été supprimé avec succès.';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'Impossible de supprimer le compte : $e. Pour des raisons de sécurité, vous devrez peut-être vous reconnecter.';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi =>
      'Kavaid - Application de dictionnaire arabe';

  @override
  String get paylasimSirasindaBirHataOlustu =>
      'Une erreur est survenue lors du partage';

  @override
  String get internetGerekli => 'Connexion requise';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'Une connexion internet est requise pour cette action.';

  @override
  String get kullaniciAdiDegistir => 'Modifier le nom d\'utilisateur';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'Actuel : $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'Nouveau nom d\'utilisateur';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'nomdutilisateur123 (minuscules, sans espaces)';

  @override
  String get enAz3KarakterSadece =>
      '• 3 caractères minimum\n• Uniquement minuscules, chiffres et caractères latins';

  @override
  String get kullaniciAdiEnAz3 =>
      'Le nom d\'utilisateur doit contenir au moins 3 caractères';

  @override
  String get sadeceKucukHarfRakamVe =>
      'Uniquement minuscules, chiffres et caractères latins';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'Votre nom d\'utilisateur a été mis à jour en \"$newUsername\" !';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'Ce nom d\'utilisateur est indisponible ou déjà pris';

  @override
  String get degistir => 'Modifier';

  @override
  String get premiumUyelikAktif => '🎉 Abonnement Premium activé !';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'Échec de connexion : $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'Veuillez vous connecter pour acheter Premium.';

  @override
  String hataE(Object e) {
    return 'Erreur : $e';
  }

  @override
  String get kavaidPremium => 'Kavaid Premium';

  @override
  String get aiAsistanASinirsizErisim => 'Accès illimité à l\'assistant AI';

  @override
  String get ceviriyeSinirsizErisim => 'Accès illimité à la traduction';

  @override
  String get m5500Fiilin24Siga => 'Débloquez la conjugaison de 5 500+ verbes';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'Accès à tout le matériel d\'apprentissage';

  @override
  String get kuranSozluguneSinirsizErisim =>
      'Accès illimité au dictionnaire du Coran';

  @override
  String get sinirsizKelimeKartiVeListe =>
      'Cartes mémoire et listes illimitées';

  @override
  String get reklamsizDeneyim => 'Expérience sans publicité';

  @override
  String get aylikAbonelik => 'Abonnement mensuel';

  @override
  String get m1AyBoyuncaSinirsizErisim => 'Accès illimité pendant 1 mois';

  @override
  String get yillikAbonelik => 'Abonnement annuel';

  @override
  String get m1YilBoyuncaSinirsizErisim => 'Accès illimité pendant 1 an';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return 'Accès illimité pendant 1 an ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return '$yearlyDiscount% DE RÉDUCTION';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'S\'abonner mensuellement $buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'S\'abonner annuellement $buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'Le paiement sera débité de votre compte Apple ID. L\'abonnement se renouvelle automatiquement sauf annulation au moins 24 heures avant la fin de la période en cours. Vous pouvez annuler à tout moment dans les réglages de votre compte App Store.';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'Le paiement sera débité via Google Play. L\'abonnement se renouvelle automatiquement sauf annulation au moins 24 heures avant la fin de la période en cours. Vous pouvez annuler à tout moment dans les paramètres de votre compte Google Play.';

  @override
  String get satinAlmalariGeriYukle => 'Restaurer les achats';

  @override
  String get kullanimKosullariEula => 'Conditions d\'utilisation (EULA)';

  @override
  String get gizlilikPolitikasi => 'Politique de confidentialité';

  @override
  String get metinGirin => 'Entrez du texte';

  @override
  String get harekeAc => 'Activer les voyelles';

  @override
  String get kopyala => 'Copier';

  @override
  String get kopyalandi => 'Copié';

  @override
  String get cevir => 'Traduire';

  @override
  String get suDileCevir => 'Traduire en';

  @override
  String get premiumAGecin => 'Passer à Premium';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'Passez à Premium pour effectuer plus de traductions.';

  @override
  String get lutfenOnceKayitOlupGiris =>
      'Veuillez d\'abord vous inscrire ou vous connecter.';

  @override
  String get diller => 'Langues';

  @override
  String get lehceler => 'Dialectes';

  @override
  String get internetBaglantisiGerekiyor => 'Connexion Internet requise.';

  @override
  String get aiAsistanSuAnKullanilamiyor =>
      'L\'assistant AI est indisponible pour le moment.';

  @override
  String get yanitGelmedi => 'Aucune réponse reçue.';

  @override
  String get suAndaCevapAlinamadi =>
      'Impossible d\'obtenir une réponse pour le moment.';

  @override
  String get hazir => 'Prêt.';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'Connexion Internet requise pour l\'assistant de vocabulaire AI.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'Vous avez épuisé votre quota quotidien gratuit d\'assistant de vocabulaire AI.';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'La clé API de l\'enseignant AI est invalide. Vérifiez la valeur firebase gemini_api.';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'L\'assistant de vocabulaire AI n\'a pas pu répondre. Réessayez.';

  @override
  String get yukleniyor => 'Chargement...';

  @override
  String get sozlukHazir => 'Dictionnaire prêt.';

  @override
  String get sozlukYuklenemedi => 'Échec du chargement du dictionnaire.';

  @override
  String get ekranHazirlaniyor => 'Préparation de l\'écran...';

  @override
  String get sozlukKontrolEdiliyor => 'Vérification du dictionnaire...';

  @override
  String get sozlukAyarlaniyor => 'Configuration du dictionnaire...';

  @override
  String get aramaHazirlaniyor => 'Préparation de la recherche...';

  @override
  String get aramaHazir => 'Recherche prête.';

  @override
  String get internetBaglantisiYok => 'Pas de connexion Internet';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'Une connexion Internet est nécessaire pour utiliser l\'application. Veuillez vérifier votre connexion WiFi ou vos données mobiles.';

  @override
  String get sozlukHazirlaniyor => 'Préparation du dictionnaire...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    String _temp0 = intl.Intl.pluralLogic(
      existingCount,
      locale: localeName,
      other: '$existingCount mots disponibles',
      one: '1 mot disponible',
      zero: 'Aucun mot disponible',
    );
    return 'Dictionnaire prêt. $_temp0.';
  }

  @override
  String get kelimelerYukleniyor => 'Chargement des mots...';

  @override
  String get sozlukHazir2 => 'Dictionnaire prêt !';

  @override
  String get mevcutVeritabaniKullanilacak =>
      'La base de données actuelle sera utilisée.';

  @override
  String get hicGuncellenmedi => 'Jamais mis à jour';

  @override
  String get girisYapmalisiniz => 'Vous devez vous connecter.';

  @override
  String get paketBulunamadiLifetime => 'Forfait non trouvé (À vie).';

  @override
  String get hataOlustu => 'Une erreur est survenue';

  @override
  String beklenmedikHataE(Object e) {
    return 'Erreur inattendue : $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'Impossible de lancer RevenueCat : $e';
  }

  @override
  String get satinAlmakIcinOnceGiris =>
      'Connectez-vous d\'abord pour effectuer l\'achat.';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'Erreur d\'achat : $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'Impossible de charger le forfait d\'abonnement. Veuillez vérifier votre connexion Internet et réessayer.';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'Une connexion Internet est requise pour vérifier l\'achat.';

  @override
  String get aktifBirAbonelikBulunamadi => 'Aucun abonnement actif trouvé.';

  @override
  String restoreHatasiE(Object e) {
    return 'Erreur de restauration : $e';
  }

  @override
  String get hataOlustu2 => 'Une erreur est survenue.';

  @override
  String get ceviriIcinGirisYapmanGerekiyor =>
      'Vous devez être connecté pour traduire.';

  @override
  String get premiumKullanici => 'Utilisateur Premium.';

  @override
  String get ceviriHakkiKullanildi => 'Limite de traduction atteinte.';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'Impossible de vérifier votre droit de traduction. Vérifiez votre connexion.';

  @override
  String get yeniSohbet => 'Nouvelle discussion';

  @override
  String get buSohbetinGecmisiSilinsinMi =>
      'Voulez-vous supprimer l\'historique de cette discussion ?';

  @override
  String get aiAsistan => 'Assistant IA';

  @override
  String get hakkinda => ' à propos de';

  @override
  String get arapcaSozlukYardimcin => 'Ton assistant de dictionnaire arabe';

  @override
  String get bugunkuUcretsizSoruHakkin =>
      'Tes questions gratuites d\'aujourd\'hui';

  @override
  String get arapcasiniDinle => 'Écouter la prononciation arabe';

  @override
  String get tekrarDene2 => 'Réessayer';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    return 'Tes $freeDailyLimit questions gratuites d\'aujourd\'hui sont épuisées';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'Tes droits se renouvelleront demain. Avec Premium, pose des questions en illimité.';

  @override
  String get premiumAGec2 => 'Passer à Premium';

  @override
  String get kisacaAnlat => 'Explique brièvement';

  @override
  String get m3OrnekCumleVer => 'Donne 3 exemples de phrases';

  @override
  String get benzerKelimelerdenFarkiNe =>
      'Quelle est la différence avec les mots similaires ?';

  @override
  String get okunusunuLatinHarfleriyleYaz =>
      'Écris la prononciation en alphabet latin';

  @override
  String get gecmisZamanNasilKurulur => 'Comment former le passé (al-Mazi) ?';

  @override
  String get harfICerNedir => 'Qu\'est-ce qu\'une préposition (harf al-jarr) ?';

  @override
  String get isimCumlesiNasilKurulur => 'Comment former une phrase nominale ?';

  @override
  String get enSikKullanilan10Fiil => 'Les 10 verbes les plus utilisés';

  @override
  String get sonSorduklarim => 'Mes dernières questions';

  @override
  String get ornekSorular => 'Exemples de questions';

  @override
  String get buKelimeHakkindaKisaVe =>
      'Obtiens une réponse courte et claire sur ce mot.';

  @override
  String get arapcaSorunuYaz => 'Pose ta question sur l\'arabe';

  @override
  String get kisaVeNetCevapVerir =>
      'Répond de façon courte et précise, sans inventer.';

  @override
  String get ornekVer => 'Donne un exemple';

  @override
  String get dahaBasitAnlat => 'Explique plus simplement';

  @override
  String get derinles => 'Approfondir';

  @override
  String get cekiminiGoster => 'Montre la conjugaison';

  @override
  String get aiAsistanASor => 'Demander à l\'assistant IA...';

  @override
  String get yeniAiAsistan => 'Nouveau : Assistant IA';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'Appuie sur cette icône tout à gauche de la carte de mot : pour demander sa signification, sa différence avec des mots similaires et des exemples de phrases.';

  @override
  String get anladim => 'J\'ai compris';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'Donne plus d\'exemples avec ce mot par niveau : facile, moyen, usage quotidien, axé sur la grammaire et phrases interrogatives.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'Votre quota quotidien gratuit pour l\'Assistant IA est atteint. Passez à la version Premium pour continuer.';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'Impossible d\'obtenir une réponse pour le moment. Vérifiez votre connexion internet et réessayez.';

  @override
  String get aiKelimeAsistani => 'Assistant IA';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    return 'Assistant IA · $remaining accès gratuits';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi =>
      'Impossible de préparer l\'Assistant IA.';

  @override
  String get premiumAGec3 => 'Passer à Premium';

  @override
  String get kisacaAnlat2 => 'Expliquer brièvement';

  @override
  String get gramerNotlari => 'Notes grammaticales';

  @override
  String get kullanimNotlari => 'Notes d\'usage';

  @override
  String get buKelimeNeredeKullanilir => 'Comment utiliser ce mot ?';

  @override
  String get m5YeniOrnekVer => 'Donner 5 nouveaux exemples';

  @override
  String get kolayCumlelerleAnlat => 'Expliquer avec des phrases simples';

  @override
  String get cekimleOrnekVer => 'Exemple avec conjugaison';

  @override
  String get harfICerFarkiniAnlat =>
      'Expliquer la différence avec la préposition';

  @override
  String get ornekleOgren => 'Apprendre par l\'exemple';

  @override
  String get miniAlistirma => 'Mini exercice';

  @override
  String get hazirSorular => 'Questions suggérées';

  @override
  String get sor => 'Poser une question';

  @override
  String get buKelimeyleIlgiliSoruSor => 'Posez une question sur ce mot';

  @override
  String get arapcaTurkceSozluk => 'Dictionnaire arabe-anglais';

  @override
  String get arapcaYaDaTurkceYaz =>
      'Écrivez en arabe ou en anglais, tout est sur une seule fiche.';

  @override
  String get sesleYaDaArapcaKlavyeyle =>
      'Recherchez par la voix ou via le clavier arabe';

  @override
  String get kokCogulVeOrnekCumleler => 'Racine, pluriel et exemples';

  @override
  String get fiilKarti => 'Fiche verbe';

  @override
  String get fiillerinCekimleriKartinIcinde =>
      'Conjugaison des verbes incluse.';

  @override
  String get maziMuzariMastarVeEmir => 'Mazi, muzari, masdar et impératif';

  @override
  String get tumCekimlerIcinEmsileyeGec =>
      'Voir toutes les formes dans Conjugaison';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'Appuyez sur l\'icône à gauche de la fiche.';

  @override
  String get sorunuYazYaDaHazir =>
      'Écrivez votre question ou choisissez-en une';

  @override
  String get kisaVeNetCevap => 'Réponse courte et précise';

  @override
  String get m5500DenFazlaFiilin => 'Plus de 5 500 tableaux de conjugaison.';

  @override
  String get fiileDokunKartiAcilsin =>
      'Appuyez sur un verbe pour voir sa fiche';

  @override
  String get anlamlariVe24SigaCekimi =>
      'Significations et 24 formes de conjugaison';

  @override
  String get kurAnSozlugu => 'Dictionnaire du Coran';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'Apprenez les mots du Coran avec leurs versets.';

  @override
  String get kelimeVeKurAniAnlamlari => 'Mot et sens coranique';

  @override
  String get gectigiAyetVeMeali => 'Verset et traduction';

  @override
  String get lehceCeviri => 'Traduction dialectale';

  @override
  String get turkceYazYaDaKonus =>
      'Écrivez ou parlez en français, traduisez en 17 dialectes.';

  @override
  String get karsiligiVeOkunusu => 'Traduction et prononciation';

  @override
  String get lehceyiSecYaDaSesle =>
      'Choisissez le dialecte ou utilisez la voix';

  @override
  String get listelerVeKartlar => 'Listes et fiches';

  @override
  String get kaydettiginHerSeyTekYerde =>
      'Tout ce que vous avez enregistré est ici.';

  @override
  String get listeYaDaKartlarlaTekrar =>
      'Révisez avec des listes ou des fiches';

  @override
  String get sozlukKurAnVeEmsile =>
      'Enregistrements du dictionnaire, du Coran et des conjugaisons';

  @override
  String get a1DenC1EResimli =>
      'Histoires arabes illustrées, du niveau A1 au C1.';

  @override
  String get kelimeyeDokunAnlamiCiksin =>
      'Appuyez sur un mot pour voir sa traduction';

  @override
  String get metniSesliDinle => 'Écoutez le texte';

  @override
  String get gec => 'Passer';

  @override
  String get yeni => 'NOUVEAU';

  @override
  String get ara => 'Rechercher';

  @override
  String get bosluk => 'Espace';

  @override
  String get hesabinizYoksaOnceKayitOlun =>
      'Si vous n\'avez pas de compte, inscrivez-vous d\'abord';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'Vous devrez vous connecter une fois l\'inscription terminée.';

  @override
  String get ePosta => 'E-mail';

  @override
  String get gecersizEPostaAdresi => 'Adresse e-mail invalide';

  @override
  String get sifre => 'Mot de passe';

  @override
  String get sifreGerekli => 'Mot de passe requis';

  @override
  String get sifremiUnuttum => 'Mot de passe oublié';

  @override
  String get sifreTekrar => 'Confirmation du mot de passe';

  @override
  String get sifreTekrariGerekli => 'Confirmation du mot de passe requise';

  @override
  String get sifrelerEslesmiyor => 'Les mots de passe ne correspondent pas';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'Veuillez d\'abord saisir votre adresse e-mail pour réinitialiser votre mot de passe.';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return 'Si un compte est associé à $email, un lien de réinitialisation a été envoyé. Vérifiez votre boîte de réception et vos courriers indésirables (spam).';
  }

  @override
  String get gecerliBirEPostaAdresi =>
      'Veuillez entrer une adresse e-mail valide.';

  @override
  String get buEPostaIleKayit => 'Aucun compte trouvé avec cet e-mail.';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'Trop de tentatives. Veuillez réessayer plus tard.';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'Erreur réseau. Vérifiez votre connexion Internet.';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'Impossible d\'envoyer le lien. Veuillez réessayer.';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 Bienvenue ! Votre compte a été créé avec succès.';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'Échec de l\'opération. Veuillez réessayer.';

  @override
  String get ePostaVeyaSifreHatali =>
      'E-mail ou mot de passe incorrect. Veuillez vérifier.';

  @override
  String get sifreHatali => 'Mot de passe incorrect.';

  @override
  String get buEPostaZatenKayitli => 'Cet e-mail est déjà utilisé.';

  @override
  String get sifreCokZayifDahaGuclu =>
      'Mot de passe trop faible. Choisissez un mot de passe plus fort.';

  @override
  String get buGirisYontemiProjeIcin =>
      'Cette méthode de connexion n\'est pas activée pour ce projet.';

  @override
  String get oDisil => 'Elle';

  @override
  String get ikisi => 'Eux deux';

  @override
  String get ikisiEril => 'Eux deux (masc.)';

  @override
  String get ikisiDisil => 'Elles deux (fém.)';

  @override
  String get onlarDisil => 'Elles';

  @override
  String get senDisil => 'Toi (fém.)';

  @override
  String get ikiniz => 'Vous deux';

  @override
  String get sizDisil => 'Vous (fém.)';

  @override
  String get m3Sahis => 'غَائِب (3e personne)';

  @override
  String get m2Sahis => 'مُخَاطَب (2e personne)';

  @override
  String get m1Sahis => 'مُتَكَلِّم (1re personne)';

  @override
  String get muzari => 'Muzari';

  @override
  String get emsileCekimleri => 'Conjugaisons';

  @override
  String get maziGecmis => 'Mazi (Passé)';

  @override
  String get muzariGenis => 'Présent';

  @override
  String get emir => 'Impératif';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return 'Conjugaison $tabTitle introuvable';
  }

  @override
  String get kok => 'Racine';

  @override
  String get ismIFail => 'Participe actif';

  @override
  String get ismIMefUl => 'Participe passif';

  @override
  String get fiilCekimleriKavaidSozluk => 'Conjugaisons • Kavaid';

  @override
  String get m5500DenFazlaFiilin2 =>
      'Apprenez la conjugaison de plus de 5 500 verbes dans les 24 formes.';

  @override
  String get tumFiilleriAc => 'Débloquer tous les verbes';

  @override
  String get dahaFazlaFiilYukle => 'Charger plus de verbes';

  @override
  String get arananKelimeBulunamadi => 'Mot introuvable';

  @override
  String get fiilIMaziMuttasilCekimler => 'Mazi — Conjugaisons avec suffixes';

  @override
  String get fiilIMuzariMuttasilCekimler =>
      'Muzari — Conjugaisons avec suffixes';

  @override
  String get emrIHazirMuttasilCekimler =>
      'Impératif — Conjugaisons avec suffixes';

  @override
  String get cekimler => 'Conjugaisons';

  @override
  String get premiumIcerik => 'Contenu Premium';

  @override
  String get m5500DenFazlaFiilin3 =>
      'Accédez à la conjugaison de plus de 5 500 verbes dans les 24 formes';

  @override
  String get ucretsizFiiller => 'Verbes gratuits';

  @override
  String get listeyeEkle => 'Ajouter à la liste';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'Veuillez vous connecter pour utiliser l\'assistant IA.';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'Donne-moi 5 nouveaux exemples adaptés à mon niveau avec ce mot, du plus simple au plus complexe.';

  @override
  String get tumFiilCekimleri => 'Toutes les conjugaisons';

  @override
  String kokRoot(Object root) {
    return 'racine $root';
  }

  @override
  String get cogul => 'Pluriel';

  @override
  String get ornekCumleler => 'Exemples';

  @override
  String get cumleyiDinle => 'Écouter la phrase';

  @override
  String get aiAsistanASor2 => 'Demander à l\'assistant AI';

  @override
  String get dahaFazlaOrnek => 'Plus d\'exemples';

  @override
  String get kelimeKaydetmekIcinOnceGiris =>
      'Veuillez vous connecter pour enregistrer des mots';

  @override
  String get oyna => 'Jouer';

  @override
  String get verbFormPast => 'Passé';

  @override
  String get verbFormPresent => 'Présent';

  @override
  String get verbFormInfinitive => 'Nom verbal';

  @override
  String get verbFormImperative => 'Impératif';

  @override
  String get zamirOEril => 'Il (masc.)';

  @override
  String get zamirOnlarEril => 'Ils (masc.)';

  @override
  String get zamirSenEril => 'Tu (masc.)';

  @override
  String get zamirSizEril => 'Vous (masc.)';

  @override
  String get zamirBen => 'Je';

  @override
  String get zamirBiz => 'Nous';

  @override
  String get dialectTr => 'Turc';

  @override
  String get dialectEn => 'Anglais';

  @override
  String get dialectDe => 'Allemand';

  @override
  String get dialectFr => 'Français';

  @override
  String get dialectRu => 'Russe';

  @override
  String get dialectEs => 'Espagnol';

  @override
  String get dialectIt => 'Italien';

  @override
  String get dialectPt => 'Portugais';

  @override
  String get dialectNl => 'Néerlandais';

  @override
  String get dialectFa => 'Persan';

  @override
  String get dialectUr => 'Ourdou';

  @override
  String get dialectId => 'Indonésien';

  @override
  String get dialectArStandard => 'Arabe standard';

  @override
  String get dialectArSyrian => 'Arabe syrien';

  @override
  String get dialectArLebanese => 'Arabe libanais';

  @override
  String get dialectArJordanian => 'Arabe jordanien';

  @override
  String get dialectArPalestinian => 'Arabe palestinien';

  @override
  String get dialectArEgyptian => 'Arabe égyptien';

  @override
  String get dialectArIraqi => 'Arabe irakien';

  @override
  String get dialectArSudanese => 'Arabe soudanais';

  @override
  String get dialectArSaudi => 'Arabe saoudien';

  @override
  String get dialectArEmirati => 'Arabe émirati';

  @override
  String get dialectArKuwaiti => 'Arabe koweïtien';

  @override
  String get dialectArQatari => 'Arabe qatari';

  @override
  String get dialectArOmani => 'Arabe omanais';

  @override
  String get dialectArYemeni => 'Arabe yéménite';

  @override
  String get dialectArMoroccan => 'Arabe marocain';

  @override
  String get dialectArAlgerian => 'Arabe algérien';

  @override
  String get dialectArTunisian => 'Arabe tunisien';

  @override
  String get dialectArLibyan => 'Arabe libyen';

  @override
  String get appLanguage => 'Langue de l\'application';

  @override
  String get typeNoun => 'Nom';

  @override
  String get typeProperNoun => 'Nom propre';

  @override
  String get typeVerb => 'Verbe';

  @override
  String get typeVerbPast => 'Verbe (passé)';

  @override
  String get typeVerbPresent => 'Verbe (prés.)';

  @override
  String get typeVerbImperative => 'Impératif';

  @override
  String get typeVerbProhibitive => 'Prohibitif';

  @override
  String get typeVerbPastPassive => 'Passif (passé)';

  @override
  String get typeVerbPresentPassive => 'Passif (prés.)';

  @override
  String get typeVerbDefective => 'Verbe défect.';

  @override
  String get typeMasdar => 'Maṣdar';

  @override
  String get typeActiveParticiple => 'Part. actif';

  @override
  String get typePassiveParticiple => 'Part. passif';

  @override
  String get typeElative => 'Élatif';

  @override
  String get typeAdjective => 'Adjectif';

  @override
  String get typeAdverb => 'Adverbe';

  @override
  String get typeHal => 'Ḥāl';

  @override
  String get typePronoun => 'Pronom';

  @override
  String get typeDemonstrative => 'Démonstratif';

  @override
  String get typeRelative => 'Relatif';

  @override
  String get typeInterrogative => 'Interrogatif';

  @override
  String get typePreposition => 'Préposition';

  @override
  String get typeParticle => 'Particule';

  @override
  String get typeNumber => 'Nombre';

  @override
  String get typePhrase => 'Iḍāfa / Synt.';

  @override
  String get typeExpression => 'Expression';

  @override
  String get typeIdiom => 'Idiome';

  @override
  String get siga01 => 'Passé (Māḍī)';

  @override
  String get siga02 => 'Accompli';

  @override
  String get siga03 => 'Nom verbal';

  @override
  String get siga04 => 'Part. actif';

  @override
  String get siga05 => 'Part. passif';

  @override
  String get siga06 => 'Nég. passé';

  @override
  String get siga07 => 'Nég. accompli';

  @override
  String get siga08 => 'Nég. présent';

  @override
  String get siga09 => 'Nég. futur';

  @override
  String get siga10 => 'Nég. futur emph';

  @override
  String get siga11 => 'Impér. 3e';

  @override
  String get siga12 => 'Prohib. 3e';

  @override
  String get siga13 => 'Impératif';

  @override
  String get siga14 => 'Prohibition';

  @override
  String get siga15 => 'Nom lieu/temps';

  @override
  String get siga16 => 'Nom instrument';

  @override
  String get siga17 => 'Nom d\'unité';

  @override
  String get siga18 => 'Nom de manière';

  @override
  String get siga19 => 'Diminutif';

  @override
  String get siga20 => 'Nom relatif';

  @override
  String get siga21 => 'Intensif';

  @override
  String get siga22 => 'Élatif';

  @override
  String get siga23 => 'Exclamation 1';

  @override
  String get siga24 => 'Exclamation 2';

  @override
  String get dialectMs => 'Malais';

  @override
  String get dialectBn => 'Bengali';

  @override
  String get dialectUz => 'Ouzbek';

  @override
  String get dialectAz => 'Azéri';

  @override
  String get prepositionsLabel => 'Avec prép.';

  @override
  String get tashkeelToggle => 'Voyelles';

  @override
  String get tashkeelSettingHint =>
      'Afficher les voyelles dans les définitions et exemples';

  @override
  String get rootMatches => 'Même racine';

  @override
  String get dictionaryLanguage => 'Langue du dictionnaire';

  @override
  String get dictionaryLanguageHint => 'Langue des significations';

  @override
  String get arabicArabicDictionary => 'Dictionnaire arabe–arabe';
}
