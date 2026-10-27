// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get kavaidSozluk => 'قاموس Kavaid';

  @override
  String get tekrarDene => 'أعد المحاولة';

  @override
  String get kavaidArapcaSozluk => 'Kavaid - قاموس اللغة العربية';

  @override
  String get sozluk => 'قاموس';

  @override
  String get ceviri => 'ترجمة';

  @override
  String get ogren => 'تعلّم';

  @override
  String get profil => 'الملف الشخصي';

  @override
  String get kelimeBulunamadi => 'لم يتم العثور على الكلمة';

  @override
  String get baglantiAcilamadi => 'تعذر فتح الرابط';

  @override
  String get tebrikler1AyPremiumHesabiniza =>
      'تهانينا! تم تفعيل اشتراك بريميوم لمدة شهر في حسابك 🌟';

  @override
  String get gecersizVeyaKullanilmisKod => 'الكود غير صالح أو مستخدم مسبقاً.';

  @override
  String get buKoduDahaOnceKullandiniz => 'لقد استخدمت هذا الكود من قبل.';

  @override
  String get buKodunSuresiDolmus => 'انتهت صلاحية هذا الكود.';

  @override
  String get buKodunKullanimLimitiDolmus =>
      'تم استنفاد حد الاستخدام لهذا الكود.';

  @override
  String get lutfenOnceGirisYapin => 'يرجى تسجيل الدخول أولاً.';

  @override
  String get m1AyUcretsizPremiumKazan => 'احصل على شهر بريميوم مجاناً';

  @override
  String get uygulamaHakkindaGorusleriniziBelirtilenTweeti =>
      'شارك رأيك حول التطبيق عبر اقتباس التغريدة المذكورة على تويتر (X)، واحصل على اشتراك بريميوم مجاني لمدة شهر!';

  @override
  String get nasilKatilirim => 'كيف أشارك؟';

  @override
  String get uygulamaIleIlgiliGorusleriniziBelirtilen =>
      'شارك رأيك حول التطبيق عبر اقتباس التغريدة المذكورة على تويتر (X).';

  @override
  String get paylasiminiziTwitterDaEbubekr53Hesabina =>
      'أرسل مشاركتك كرسالة مباشرة إلى حساب ebubekr53@ على تويتر، واحصل على الكود الخاص بك.';

  @override
  String get koduAsagiyaGirin => 'أدخل الكود أدناه.';

  @override
  String get tweetiAlintila => 'اقتباس التغريدة';

  @override
  String get promosyonKodu => 'كود العرض';

  @override
  String get kullan => 'استخدام';

  @override
  String get dahaFazlaOzellik => 'المزيد من الميزات';

  @override
  String get dahaFazlaListeOlusturmakIcin =>
      'رَقِّ حسابك إلى بريميوم\nلإنشاء المزيد من القوائم';

  @override
  String get kapat => 'إغلاق';

  @override
  String get premiumAl => 'احصل على بريميوم';

  @override
  String get yeniListe => 'قائمة جديدة';

  @override
  String get listeAdi => 'اسم القائمة';

  @override
  String get iptal => 'إلغاء';

  @override
  String get olustur => 'إنشاء';

  @override
  String get listeyiYenidenAdlandir => 'إعادة تسمية القائمة';

  @override
  String get kaydet => 'حفظ';

  @override
  String get kelimeListelerim => 'قوائم كلماتي';

  @override
  String get yeniListeOlustur => 'إنشاء قائمة جديدة';

  @override
  String get henuzListeYok => 'لا توجد قوائم بعد';

  @override
  String get kelimeleriniziDuzenlemekIcinBirListe =>
      'أنشئ قائمة لتنظيم\nكلماتك الخاصة';

  @override
  String wordcountKelime(int wordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      wordCount,
      locale: localeName,
      other: '$wordCount كلمة',
      few: '$wordCount كلمات',
      two: 'كلمتان',
      one: 'كلمة واحدة',
      zero: '0 كلمة',
    );
    return '$_temp0';
  }

  @override
  String get yenidenAdlandir => 'إعادة تسمية';

  @override
  String get sil => 'حذف';

  @override
  String get listeyiSil => 'حذف القائمة';

  @override
  String nameSilinsinMiIcindekiTum(Object name) {
    return 'هل تود حذف \"$name\"؟\nسيتم أيضاً حذف جميع الكلمات بداخلها.';
  }

  @override
  String get buListedeHenuzKelimeYok => 'لا توجد كلمات في هذه القائمة بعد';

  @override
  String get liste => 'قائمة';

  @override
  String get kart => 'بطاقة';

  @override
  String get dahaFazlaKelimeKartiIcin =>
      'رَقِّ حسابك إلى بريميوم للحصول على المزيد من بطاقات الكلمات';

  @override
  String get premiumAYukselt => 'الترقية إلى بريميوم';

  @override
  String get dinle => 'استمع';

  @override
  String get oyun => 'لعبة';

  @override
  String get kullanimSiniriDoldu => 'تم استنفاد حد الاستخدام';

  @override
  String get kuranSozlugunuSinirsizKullanmayaDevam =>
      'يرجى تسجيل الدخول والترقية إلى بريميوم لمواصلة استخدام قاموس القرآن بلا حدود.';

  @override
  String get tamam => 'حسناً';

  @override
  String get tumKitaplarAcildiVeReklamlar =>
      'تم فتح جميع الكتب وإزالة الإعلانات.';

  @override
  String get tumKitaplarAcildiReklamlariKalici =>
      'تم فتح جميع الكتب. يرجى تسجيل الدخول لإزالة الإعلانات بشكل دائم.';

  @override
  String gizliKodUygulanamadiE(Object e) {
    return 'تعذر تفعيل الكود السري: $e';
  }

  @override
  String get sozlukGuncelleniyorLutfenBekleyin =>
      'جاري تحديث القاموس... يرجى الانتظار.';

  @override
  String sozlukBasariylaGuncellendiP1Kelime(int p1) {
    String _temp0 = intl.Intl.pluralLogic(
      p1,
      locale: localeName,
      other: '$p1 كلمة',
      few: '$p1 كلمات',
      two: 'كلمتين',
      one: 'كلمة واحدة',
      zero: '0 كلمة',
    );
    return 'تم تحديث القاموس بنجاح! تم تحميل $_temp0.';
  }

  @override
  String get sozlukGuncellenirkenHataOlustu => 'حدث خطأ أثناء تحديث القاموس!';

  @override
  String databaseReloadHatasiE(Object e) {
    return 'حدث خطأ في إعادة تحميل قاعدة البيانات: $e';
  }

  @override
  String get lutfenOnceKayitOlunGiris => 'يرجى تسجيل الدخول أو الاشتراك أولاً';

  @override
  String get kelimeAra => 'ابحث عن كلمة';

  @override
  String get emsile => 'التصريف';

  @override
  String get kuranSozlugu => 'قاموس القرآن';

  @override
  String get kavaidIDegerlendir => 'قيّم تطبيق Kavaid';

  @override
  String get gorusunBizimIcinCokDegerli => 'رأيك يهمنا جداً.';

  @override
  String get kuranSozluguYukleniyor => 'جاري تحميل قاموس القرآن...';

  @override
  String get kuranSozlugundeAraniyor => 'جارٍ البحث في قاموس القرآن...';

  @override
  String get araniyor => 'جارٍ البحث...';

  @override
  String get kuranSozlugundeBulunamadi => 'لم يتم العثور عليه في قاموس القرآن';

  @override
  String get farkliBirKelimeVeyaKok => 'جرّب البحث بكلمة أو جذر مختلف';

  @override
  String get kuranSozlugunuDahaFazlaKullanabilmek =>
      'اشترك في بريميوم لاستخدام قاموس القرآن بشكل غير محدود.';

  @override
  String get kurAnIKerimSozlugu => 'قاموس القرآن الكريم';

  @override
  String get kurAnDaGecenTum =>
      'تعلم استخدامات جميع الكلمات الواردة في القرآن ومعانيها القرآنية مع الآيات.';

  @override
  String get kurAnDakiBenzersizTum => 'جميع الكلمات الفريدة في القرآن.';

  @override
  String get kuraniAnlamlar => 'المعاني القرآنية';

  @override
  String get kelimelerinKurAnAyetlerindeKazandigi =>
      'تعلم المعاني التي تكتسبها الكلمات في آيات القرآن.';

  @override
  String get kurAnAyetleri => 'آيات القرآن';

  @override
  String get onBinlerceKurAnAyeti =>
      'شاهد استخدامات الكلمات في القرآن من خلال عشرات الآلاف من الآيات.';

  @override
  String get kavaidArapcaSozluk2 => 'قاموس Kavaid للغة العربية';

  @override
  String get yeniNesilYapayZekaDestekli =>
      'أول قاموس عربي مدعوم بالذكاء الاصطناعي من الجيل الجديد';

  @override
  String get premiumAGec => 'اشترك في بريميوم';

  @override
  String get sinirsizErisim => 'وصول غير محدود';

  @override
  String get profilResmiGuncellendi => '✅ تم تحديث صورة الملف الشخصي!';

  @override
  String get birHataOlustu => 'حدث خطأ ما';

  @override
  String get firebaseStorageYapilandirilmamisLutfenFirebase =>
      'لم يتم إعداد Firebase Storage. يرجى تفعيله من وحدة تحكم Firebase.';

  @override
  String get izinHatasiStorageKurallariniKontrol =>
      'خطأ في الصلاحيات. تحقق من قواعد التخزين (Storage Rules).';

  @override
  String get yetkilendirmeHatasiLutfenGirisYapin =>
      'خطأ في التحقق. يرجى تسجيل الدخول.';

  @override
  String get internetBaglantisiHatasi => 'خطأ في الاتصال بالإنترنت.';

  @override
  String get detay => 'التفاصيل';

  @override
  String get hataDetayi => 'تفاصيل الخطأ';

  @override
  String get kullanici => 'مستخدم';

  @override
  String get kurucu => 'المؤسس';

  @override
  String get moderator => 'المشرف';

  @override
  String get emailYok => 'لا يوجد بريد إلكتروني';

  @override
  String get cikisYapilsinMi => 'تسجيل الخروج؟';

  @override
  String get oturumunuzKapatilacak => 'سيتم إغلاق جلستك.';

  @override
  String get cikis => 'تسجيل الخروج';

  @override
  String get aboneligiYonet => 'إدارة الاشتراك';

  @override
  String get satinAlmalarKontrolEdiliyor => 'جاري التحقق من المشتريات...';

  @override
  String get geriYukle => 'استعادة';

  @override
  String get girisYapinVeyaKayitOlun => 'تسجيل الدخول / إنشاء حساب';

  @override
  String get girisYap => 'تسجيل الدخول';

  @override
  String get kayitOl => 'إنشاء حساب';

  @override
  String get premiumUyesiniz => 'أنت مشترك في بريميوم';

  @override
  String get sinirsizIcerikReklamsizKullanim =>
      'محتوى غير محدود، استخدام بدون إعلانات.';

  @override
  String get tumOzelliklereErisin => 'استمتع بالوصول إلى جميع الميزات.';

  @override
  String get reklamsizKullanim => 'بدون إعلانات';

  @override
  String get uygulamayiPaylas => 'مشاركة التطبيق';

  @override
  String get iletisim => 'تواصل معنا';

  @override
  String get kavaidUygulamasiHakkinda => 'حول تطبيق Kavaid';

  @override
  String get hesabimiSil => 'حذف حسابي';

  @override
  String get hesabiniziVeHesabinizaBagliTum =>
      'هل أنت متأكد من رغبتك في حذف حسابك وجميع البيانات المرتبطة به نهائياً؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get vazgec => 'إلغاء';

  @override
  String get hesabinizBasariylaSilindi => 'تم حذف حسابك بنجاح.';

  @override
  String hesapSilinemediEGuvenlikGeregi(Object e) {
    return 'تعذر حذف الحساب: $e. قد تحتاج إلى تسجيل الدخول مجدداً لأسباب أمنية.';
  }

  @override
  String get kavaidArapcaSozlukUygulamasi => 'Kavaid - قاموس اللغة العربية';

  @override
  String get paylasimSirasindaBirHataOlustu => 'حدث خطأ أثناء المشاركة';

  @override
  String get internetGerekli => 'يتطلب اتصالاً بالإنترنت';

  @override
  String get buIslemIcinInternetBaglantisi =>
      'هذا الإجراء يتطلب اتصالاً بالإنترنت.';

  @override
  String get kullaniciAdiDegistir => 'تغيير اسم المستخدم';

  @override
  String mevcutCurrentusername(Object currentUsername) {
    return 'الحالي: $currentUsername';
  }

  @override
  String get yeniKullaniciAdi => 'اسم مستخدم جديد';

  @override
  String get kullaniciadi123KucukHarfBosluksuz =>
      'username123 (أحرف صغيرة، بدون مسافات)';

  @override
  String get enAz3KarakterSadece =>
      '• 3 أحرف على الأقل\n• أحرف صغيرة وأرقام فقط';

  @override
  String get kullaniciAdiEnAz3 =>
      'يجب أن يتكون اسم المستخدم من 3 أحرف على الأقل';

  @override
  String get sadeceKucukHarfRakamVe => 'أحرف صغيرة وأرقام فقط';

  @override
  String kullaniciAdinizNewusernameOlarakGuncellendi(Object newUsername) {
    return 'تم تحديث اسم المستخدم إلى \"$newUsername\"!';
  }

  @override
  String get buKullaniciAdiKullanilamiyorVeya =>
      'اسم المستخدم هذا غير متاح أو مستخدم بالفعل';

  @override
  String get degistir => 'تغيير';

  @override
  String get premiumUyelikAktif => '🎉 تم تفعيل اشتراك بريميوم!';

  @override
  String baglantiAcilamadiE(Object e) {
    return 'تعذر فتح الرابط: $e';
  }

  @override
  String get premiumSatinAlmakIcinLutfen =>
      'يرجى تسجيل الدخول أولاً لشراء بريميوم.';

  @override
  String hataE(Object e) {
    return 'خطأ: $e';
  }

  @override
  String get kavaidPremium => 'Kavaid Premium';

  @override
  String get aiAsistanASinirsizErisim =>
      'وصول غير محدود إلى مساعد الذكاء الاصطناعي';

  @override
  String get ceviriyeSinirsizErisim => 'وصول غير محدود إلى الترجمة';

  @override
  String get m5500Fiilin24Siga => 'افتح تصريف أكثر من 5500 فعل في 24 صيغة';

  @override
  String get ogrenKismindakiTumMateryallereErisim =>
      'الوصول إلى جميع مواد قسم التعلم';

  @override
  String get kuranSozluguneSinirsizErisim => 'وصول غير محدود إلى معجم القرآن';

  @override
  String get sinirsizKelimeKartiVeListe =>
      'إنشاء بطاقات وقوائم كلمات غير محدودة';

  @override
  String get reklamsizDeneyim => 'تجربة بدون إعلانات';

  @override
  String get aylikAbonelik => 'اشتراك شهري';

  @override
  String get m1AyBoyuncaSinirsizErisim => 'وصول غير محدود لمدة شهر واحد';

  @override
  String get yillikAbonelik => 'اشتراك سنوي';

  @override
  String get m1YilBoyuncaSinirsizErisim => 'وصول غير محدود لمدة سنة واحدة';

  @override
  String m1YilBoyuncaSinirsizErisim2(Object yearlyMonthlyCost) {
    return 'وصول غير محدود لمدة سنة واحدة ($yearlyMonthlyCost)';
  }

  @override
  String yearlydiscountIndirim(Object yearlyDiscount) {
    return 'خصم $yearlyDiscount%';
  }

  @override
  String aylikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'اشتراك شهري$buttonPriceText';
  }

  @override
  String yillikAboneOlButtonpricetext(Object buttonPriceText) {
    return 'اشتراك سنوي$buttonPriceText';
  }

  @override
  String get odemeAppleIdHesabinizdanTahsil =>
      'يتم الخصم من حساب Apple ID الخاص بك. سيتم تجديد الاشتراك تلقائياً ما لم يتم إلغاؤه قبل 24 ساعة على الأقل من نهاية الفترة الحالية. يمكنك الإدارة أو الإلغاء في أي وقت من إعدادات حساب Apple ID.';

  @override
  String get odemeGooglePlayUzerindenTahsil =>
      'يتم الخصم من حساب Google Play الخاص بك. سيتم تجديد الاشتراك تلقائياً ما لم يتم إلغاؤه قبل 24 ساعة على الأقل من نهاية الفترة الحالية. يمكنك الإدارة أو الإلغاء في أي وقت من إعدادات حساب Google Play.';

  @override
  String get satinAlmalariGeriYukle => 'استعادة المشتريات';

  @override
  String get kullanimKosullariEula => 'شروط الاستخدام (EULA)';

  @override
  String get gizlilikPolitikasi => 'سياسة الخصوصية';

  @override
  String get metinGirin => 'أدخل النص';

  @override
  String get harekeAc => 'إظهار التشكيل';

  @override
  String get kopyala => 'نسخ';

  @override
  String get kopyalandi => 'تم النسخ';

  @override
  String get cevir => 'ترجمة';

  @override
  String get suDileCevir => 'ترجم إلى';

  @override
  String get premiumAGecin => 'اشترك في بريميوم';

  @override
  String get dahaFazlaCeviriYapabilmekIcin =>
      'اشترك في بريميوم لإجراء المزيد من الترجمات.';

  @override
  String get lutfenOnceKayitOlupGiris => 'يرجى التسجيل وتسجيل الدخول أولاً.';

  @override
  String get diller => 'اللغات';

  @override
  String get lehceler => 'اللهجات';

  @override
  String get internetBaglantisiGerekiyor => 'مطلوب اتصال بالإنترنت.';

  @override
  String get aiAsistanSuAnKullanilamiyor =>
      'مساعد الذكاء الاصطناعي غير متاح حالياً.';

  @override
  String get yanitGelmedi => 'لم يتم تلقي أي رد.';

  @override
  String get suAndaCevapAlinamadi => 'تعذر الحصول على إجابة حالياً.';

  @override
  String get hazir => 'جاهز.';

  @override
  String get aiKelimeAsistaniIcinInternet =>
      'مطلوب اتصال بالإنترنت لمساعد الكلمات الذكي.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani =>
      'لقد استنفدت حصتك المجانية اليومية لمساعد الكلمات الذكي.';

  @override
  String get aiOgretmenApiAnahtariGecersiz =>
      'مفتاح API الخاص بمعلم AI غير صالح. تحقق من قيمة gemini_api في Firebase.';

  @override
  String get aiKelimeAsistaniSuAnda =>
      'لم يستطع مساعد الكلمات الذكي الرد حالياً. يرجى المحاولة مرة أخرى.';

  @override
  String get yukleniyor => 'جاري التحميل...';

  @override
  String get sozlukHazir => 'المعجم جاهز.';

  @override
  String get sozlukYuklenemedi => 'تعذر تحميل المعجم.';

  @override
  String get ekranHazirlaniyor => 'جاري تجهيز الشاشة...';

  @override
  String get sozlukKontrolEdiliyor => 'جاري فحص المعجم...';

  @override
  String get sozlukAyarlaniyor => 'جاري إعداد القاموس...';

  @override
  String get aramaHazirlaniyor => 'جاري إعداد البحث...';

  @override
  String get aramaHazir => 'البحث جاهز.';

  @override
  String get internetBaglantisiYok => 'لا يوجد اتصال بالإنترنت';

  @override
  String get uygulamayiKullanabilmekIcinInternetBaglantisina =>
      'تحتاج إلى اتصال بالإنترنت لاستخدام التطبيق. يرجى التحقق من اتصال الواي فاي أو بيانات الهاتف.';

  @override
  String get sozlukHazirlaniyor => 'جاري إعداد القاموس...';

  @override
  String sozlukHazirExistingcountKelimeMevcut(int existingCount) {
    return 'القاموس جاهز. توجد $existingCount كلمة.';
  }

  @override
  String get kelimelerYukleniyor => 'جاري تحميل الكلمات...';

  @override
  String get sozlukHazir2 => 'القاموس جاهز!';

  @override
  String get mevcutVeritabaniKullanilacak =>
      'سيتم استخدام قاعدة البيانات الحالية.';

  @override
  String get hicGuncellenmedi => 'لم يتم التحديث قط';

  @override
  String get girisYapmalisiniz => 'يجب عليك تسجيل الدخول.';

  @override
  String get paketBulunamadiLifetime =>
      'لم يتم العثور على الباقة (مدى الحياة).';

  @override
  String get hataOlustu => 'حدث خطأ';

  @override
  String beklenmedikHataE(Object e) {
    return 'خطأ غير متوقع: $e';
  }

  @override
  String revenuecatBaslatilamadiE(Object e) {
    return 'تعذر بدء RevenueCat: $e';
  }

  @override
  String get satinAlmakIcinOnceGiris => 'يرجى تسجيل الدخول أولاً للشراء.';

  @override
  String satinAlmaHatasiP1(Object p1) {
    return 'خطأ في الشراء: $p1';
  }

  @override
  String get abonelikPaketiYuklenemediLutfenInternet =>
      'تعذر تحميل باقة الاشتراك. يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.';

  @override
  String get satinAlmaKontroluIcinInternet =>
      'مطلوب اتصال بالإنترنت للتحقق من الشراء.';

  @override
  String get aktifBirAbonelikBulunamadi => 'لم يتم العثور على اشتراك فعال.';

  @override
  String restoreHatasiE(Object e) {
    return 'خطأ في الاستعادة: $e';
  }

  @override
  String get hataOlustu2 => 'حدث خطأ.';

  @override
  String get ceviriIcinGirisYapmanGerekiyor => 'تحتاج لتسجيل الدخول للترجمة.';

  @override
  String get premiumKullanici => 'مستخدم بريميوم.';

  @override
  String get ceviriHakkiKullanildi => 'تم استهلاك رصيد الترجمة.';

  @override
  String get ceviriHakkiKontrolEdilemediBaglantini =>
      'تعذر التحقق من رصيد الترجمة. تحقق من اتصالك.';

  @override
  String get yeniSohbet => 'محادثة جديدة';

  @override
  String get buSohbetinGecmisiSilinsinMi => 'هل تريد حذف سجل هذه المحادثة؟';

  @override
  String get aiAsistan => 'مساعد الذكاء الاصطناعي';

  @override
  String get hakkinda => ' حول';

  @override
  String get arapcaSozlukYardimcin => 'مساعدك في قاموس اللغة العربية';

  @override
  String get bugunkuUcretsizSoruHakkin => 'رصيد أسئلتك المجانية اليومي';

  @override
  String get arapcasiniDinle => 'استمع إلى النطق العربي';

  @override
  String get tekrarDene2 => 'حاول مجدداً';

  @override
  String bugunkuFreedailylimitUcretsizSoruHakkin(int freeDailyLimit) {
    return 'انتهى رصيد أسئلتك المجانية ($freeDailyLimit) اليومي';
  }

  @override
  String get haklarinYarinYenilenirPremiumIle =>
      'سيتم تجديد رصيدك غداً. يمكنك طرح أسئلة غير محدودة مع اشتراك بريميوم.';

  @override
  String get premiumAGec2 => 'اشترك في بريميوم';

  @override
  String get kisacaAnlat => 'اشرح باختصار';

  @override
  String get m3OrnekCumleVer => 'أعطِ 3 جمل أمثلة';

  @override
  String get benzerKelimelerdenFarkiNe =>
      'ما الفرق بينها وبين الكلمات المشابهة؟';

  @override
  String get okunusunuLatinHarfleriyleYaz =>
      'اكتب طريقة النطق بالحروف اللاتينية';

  @override
  String get gecmisZamanNasilKurulur => 'كيف يتم صياغة الماضي؟';

  @override
  String get harfICerNedir => 'ما هو حرف الجر؟';

  @override
  String get isimCumlesiNasilKurulur => 'كيف يتم صياغة الجملة الاسمية؟';

  @override
  String get enSikKullanilan10Fiil => 'أكثر 10 أفعال استخداماً';

  @override
  String get sonSorduklarim => 'أسئلتي الأخيرة';

  @override
  String get ornekSorular => 'أسئلة مقترحة';

  @override
  String get buKelimeHakkindaKisaVe =>
      'ستحصل على إجابة قصيرة وواضحة حول هذه الكلمة.';

  @override
  String get arapcaSorunuYaz => 'اكتب سؤالك بالعربية';

  @override
  String get kisaVeNetCevapVerir =>
      'يقدم إجابات قصيرة ومباشرة، ولا يخترع معلومات.';

  @override
  String get ornekVer => 'أعطِ مثالاً';

  @override
  String get dahaBasitAnlat => 'اشرح بطريقة أبسط';

  @override
  String get derinles => 'تعمق في الشرح';

  @override
  String get cekiminiGoster => 'أظهر التصريف';

  @override
  String get aiAsistanASor => 'اسأل مساعد الذكاء الاصطناعي...';

  @override
  String get yeniAiAsistan => 'جديد: مساعد الذكاء الاصطناعي';

  @override
  String get kelimeKartindakiIkonlarinEnSolundaki =>
      'اضغط على هذه الأيقونة الموجودة أقصى يسار بطاقة الكلمة: واسأل عن معناها، والفرق بينها وبين الكلمات المشابهة، واطلب جملاً عليها.';

  @override
  String get anladim => 'فهمت';

  @override
  String get buKelimeyleSeviyeSeviyeDaha =>
      'أعطِ المزيد من الأمثلة المتدرجة لهذه الكلمة: سهلة، متوسطة، استخدام يومي، قواعدية، وجمل استفهامية.';

  @override
  String get bugunkuUcretsizAiKelimeAsistani2 =>
      'نفدت محاولاتك اليومية المجانية لمساعد الكلمات الذكي. يمكنك الاشتراك في المميزة للمتابعة.';

  @override
  String get suAndaCevapAlinamadiInternet =>
      'تعذر الحصول على إجابة حاليًا. يرجى التحقق من اتصالك بالإنترنت والمحاولة مجددًا.';

  @override
  String get aiKelimeAsistani => 'مساعد الكلمات الذكي';

  @override
  String aiKelimeAsistaniRemainingUcretsiz(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining محاولة مجانية',
      one: 'محاولة واحدة مجانية',
    );
    return 'مساعد الكلمات الذكي · $_temp0';
  }

  @override
  String get aiKelimeAsistaniHazirlanamadi => 'تعذر إعداد مساعد الكلمات الذكي.';

  @override
  String get premiumAGec3 => 'اشترك في بريميوم';

  @override
  String get kisacaAnlat2 => 'شرح مختصر';

  @override
  String get gramerNotlari => 'ملاحظات نحوية';

  @override
  String get kullanimNotlari => 'ملاحظات الاستخدام';

  @override
  String get buKelimeNeredeKullanilir => 'أين تُستخدم هذه الكلمة؟';

  @override
  String get m5YeniOrnekVer => 'اعطني 5 أمثلة جديدة';

  @override
  String get kolayCumlelerleAnlat => 'اشرح بجمل بسيطة';

  @override
  String get cekimleOrnekVer => 'اعطني أمثلة بالتصريف';

  @override
  String get harfICerFarkiniAnlat => 'اشرح الفرق بين حروف الجر';

  @override
  String get ornekleOgren => 'تعلم بالأمثلة';

  @override
  String get miniAlistirma => 'تدريبات مصغرة';

  @override
  String get hazirSorular => 'أسئلة جاهزة';

  @override
  String get sor => 'اسأل';

  @override
  String get buKelimeyleIlgiliSoruSor => 'اسأل سؤالاً عن هذه الكلمة';

  @override
  String get arapcaTurkceSozluk => 'قاموس عربي-عربي';

  @override
  String get arapcaYaDaTurkceYaz => 'اكتب بالعربية، كل شيء في بطاقة واحدة.';

  @override
  String get sesleYaDaArapcaKlavyeyle => 'ابحث صوتيًا أو بلوحة المفاتيح';

  @override
  String get kokCogulVeOrnekCumleler => 'الجذر، الجمع، وجمل الأمثلة';

  @override
  String get fiilKarti => 'بطاقة الفعل';

  @override
  String get fiillerinCekimleriKartinIcinde => 'تصريفات الأفعال داخل البطاقة.';

  @override
  String get maziMuzariMastarVeEmir => 'الماضي، المضارع، المصدر والأمر';

  @override
  String get tumCekimlerIcinEmsileyeGec =>
      'انتقل إلى \"التصريف\" لرؤية كل الصيغ';

  @override
  String get kelimeKartininEnSolundakiSimgeye =>
      'اضغط على الأيقونة الموجودة أقصى يسار بطاقة الكلمة.';

  @override
  String get sorunuYazYaDaHazir => 'اكتب سؤالك أو اختر سؤالاً جاهزاً';

  @override
  String get kisaVeNetCevap => 'إجابة قصيرة وواضحة';

  @override
  String get m5500DenFazlaFiilin => 'جدول تصريف لأكثر من 5500 فعل.';

  @override
  String get fiileDokunKartiAcilsin => 'اضغط على الفعل لفتح بطاقته';

  @override
  String get anlamlariVe24SigaCekimi => 'معانيه وتصريفاته الـ 24';

  @override
  String get kurAnSozlugu => 'قاموس القرآن الكريم';

  @override
  String get kurAnKelimeleriniAyetleriyleOgren =>
      'تعلم كلمات القرآن مع آياتها.';

  @override
  String get kelimeVeKurAniAnlamlari => 'الكلمة ومعانيها القرآنية';

  @override
  String get gectigiAyetVeMeali => 'الآية التي وردت فيها وترجمتها';

  @override
  String get lehceCeviri => 'ترجمة اللهجات';

  @override
  String get turkceYazYaDaKonus => 'اكتب أو انطق، وترجم إلى 17 لهجة.';

  @override
  String get karsiligiVeOkunusu => 'المقابل وطريقة النطق';

  @override
  String get lehceyiSecYaDaSesle => 'اختر اللهجة أو تحدث صوتيًا';

  @override
  String get listelerVeKartlar => 'القوائم والبطاقات';

  @override
  String get kaydettiginHerSeyTekYerde => 'كل ما حفظته في مكان واحد.';

  @override
  String get listeYaDaKartlarlaTekrar => 'راجع باستخدام القوائم أو البطاقات';

  @override
  String get sozlukKurAnVeEmsile => 'سجلات القاموس والقرآن والتصريف';

  @override
  String get a1DenC1EResimli => 'قصص عربية مصورة من المستوى A1 إلى C1.';

  @override
  String get kelimeyeDokunAnlamiCiksin => 'اضغط على الكلمة لتظهر ترجمتها';

  @override
  String get metniSesliDinle => 'استمع للنص صوتيًا';

  @override
  String get gec => 'تخطَّ';

  @override
  String get yeni => 'جديد';

  @override
  String get ara => 'بحث';

  @override
  String get bosluk => 'مسافة';

  @override
  String get hesabinizYoksaOnceKayitOlun => 'سجل أولاً إذا لم يكن لديك حساب';

  @override
  String get kayitTamamlandiktanSonraGirisYapmaniz =>
      'تحتاج إلى تسجيل الدخول بعد إنشاء الحساب.';

  @override
  String get ePosta => 'البريد الإلكتروني';

  @override
  String get gecersizEPostaAdresi => 'بريد إلكتروني غير صالح';

  @override
  String get sifre => 'كلمة المرور';

  @override
  String get sifreGerekli => 'كلمة المرور مطلوبة';

  @override
  String get sifremiUnuttum => 'نسيت كلمة المرور';

  @override
  String get sifreTekrar => 'تأكيد كلمة المرور';

  @override
  String get sifreTekrariGerekli => 'تأكيد كلمة المرور مطلوب';

  @override
  String get sifrelerEslesmiyor => 'كلمات المرور غير متطابقة';

  @override
  String get sifreniSifirlamakIcinOnceE =>
      'يرجى كتابة بريدك الإلكتروني أولاً لإعادة تعيين كلمة المرور.';

  @override
  String emailAdresineKayitliBirHesap(Object email) {
    return 'إذا كان هناك حساب مسجل بـ $email، فقد تم إرسال رابط إعادة تعيين كلمة المرور. يرجى التحقق من بريدك الوارد ومجلد الرسائل غير المرغوب فيها (Spam).';
  }

  @override
  String get gecerliBirEPostaAdresi => 'يرجى إدخال عنوان بريد إلكتروني صحيح.';

  @override
  String get buEPostaIleKayit =>
      'لم يتم العثور على حساب بهذا البريد الإلكتروني.';

  @override
  String get cokFazlaDenemeYapildiBir =>
      'تم إجراء عدد كبير جداً من المحاولات. يرجى المحاولة مرة أخرى لاحقاً.';

  @override
  String get agHatasiInternetBaglantiniziKontrol =>
      'خطأ في الشبكة. يرجى التحقق من اتصالك بالإنترنت.';

  @override
  String get baglantiGonderilemediLutfenTekrarDeneyin =>
      'تعذر إرسال الرابط. يرجى المحاولة مرة أخرى.';

  @override
  String get hosGeldinizHesabinizBasariylaOlusturuldu =>
      '🎉 أهلاً بك! تم إنشاء حسابك بنجاح.';

  @override
  String get islemBasarisizLutfenTekrarDeneyin =>
      'فشلت العملية. يرجى المحاولة مرة أخرى.';

  @override
  String get ePostaVeyaSifreHatali =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة. يرجى التحقق من ذلك.';

  @override
  String get sifreHatali => 'كلمة المرور خاطئة.';

  @override
  String get buEPostaZatenKayitli => 'هذا البريد الإلكتروني مسجل بالفعل.';

  @override
  String get sifreCokZayifDahaGuclu =>
      'كلمة المرور ضعيفة جداً. اختر كلمة مرور أقوى.';

  @override
  String get buGirisYontemiProjeIcin =>
      'طريقة تسجيل الدخول هذه غير مفعلة لهذا المشروع.';

  @override
  String get oDisil => 'هي';

  @override
  String get ikisi => 'هما';

  @override
  String get ikisiEril => 'هما (للمذكر)';

  @override
  String get ikisiDisil => 'هما (للمؤنث)';

  @override
  String get onlarDisil => 'هن';

  @override
  String get senDisil => 'أنتِ';

  @override
  String get ikiniz => 'أنتما';

  @override
  String get sizDisil => 'أنتن';

  @override
  String get m3Sahis => 'غائب';

  @override
  String get m2Sahis => 'مخاطب';

  @override
  String get m1Sahis => 'متكلم';

  @override
  String get muzari => 'المضارع';

  @override
  String get emsileCekimleri => 'جدول التصريف';

  @override
  String get maziGecmis => 'الماضي';

  @override
  String get muzariGenis => 'المضارع';

  @override
  String get emir => 'الأمر';

  @override
  String tabtitleCekimiBulunamadi(Object tabTitle) {
    return 'لم يتم العثور على تصريف لـ $tabTitle';
  }

  @override
  String get kok => 'الجذر';

  @override
  String get ismIFail => 'اسم الفاعل';

  @override
  String get ismIMefUl => 'اسم المفعول';

  @override
  String get fiilCekimleriKavaidSozluk => 'تصريف الأفعال • قاموس Kavaid';

  @override
  String get m5500DenFazlaFiilin2 => 'تعلّم تصريف أكثر من 5500 فعل في 24 صيغة.';

  @override
  String get tumFiilleriAc => 'فتح جميع الأفعال';

  @override
  String get dahaFazlaFiilYukle => 'تحميل المزيد من الأفعال';

  @override
  String get arananKelimeBulunamadi => 'لم يتم العثور على الكلمة المطلوبة';

  @override
  String get fiilIMaziMuttasilCekimler => 'الفعل الماضي - التصريف المتصل';

  @override
  String get fiilIMuzariMuttasilCekimler => 'الفعل المضارع - التصريف المتصل';

  @override
  String get emrIHazirMuttasilCekimler => 'الأمر الحاضر - التصريف المتصل';

  @override
  String get cekimler => 'التصريفات';

  @override
  String get premiumIcerik => 'محتوى بريميوم';

  @override
  String get m5500DenFazlaFiilin3 => 'افتح تصريف أكثر من 5500 فعل في 24 صيغة';

  @override
  String get ucretsizFiiller => 'الأفعال المجانية';

  @override
  String get listeyeEkle => 'إضافة للقائمة';

  @override
  String get aiAsistaniKullanmakIcinLutfen =>
      'يرجى تسجيل الدخول لاستخدام مساعد الذكاء الاصطناعي.';

  @override
  String get buKelimeyleSeviyemeUygun5 =>
      'أعطني 5 أمثلة جديدة على هذه الكلمة تناسب مستواي: من الأسهل إلى الأصعب.';

  @override
  String get tumFiilCekimleri => 'جميع تصريفات الأفعال';

  @override
  String kokRoot(Object root) {
    return 'جذر $root';
  }

  @override
  String get cogul => 'جمع';

  @override
  String get ornekCumleler => 'أمثلة على الاستخدام';

  @override
  String get cumleyiDinle => 'استمع للجملة';

  @override
  String get aiAsistanASor2 => 'اسأل المساعد';

  @override
  String get dahaFazlaOrnek => 'المزيد من الأمثلة';

  @override
  String get kelimeKaydetmekIcinOnceGiris => 'سجل الدخول أولاً لحفظ الكلمات';

  @override
  String get oyna => 'العب';

  @override
  String get verbFormPast => 'ماضي';

  @override
  String get verbFormPresent => 'مضارع';

  @override
  String get verbFormInfinitive => 'مصدر';

  @override
  String get verbFormImperative => 'أمر';

  @override
  String get zamirOEril => 'هو';

  @override
  String get zamirOnlarEril => 'هم';

  @override
  String get zamirSenEril => 'أنتَ';

  @override
  String get zamirSizEril => 'أنتم';

  @override
  String get zamirBen => 'أنا';

  @override
  String get zamirBiz => 'نحن';

  @override
  String get dialectTr => 'التركية';

  @override
  String get dialectEn => 'الإنجليزية';

  @override
  String get dialectDe => 'الألمانية';

  @override
  String get dialectFr => 'الفرنسية';

  @override
  String get dialectRu => 'الروسية';

  @override
  String get dialectEs => 'الإسبانية';

  @override
  String get dialectIt => 'الإيطالية';

  @override
  String get dialectPt => 'البرتغالية';

  @override
  String get dialectNl => 'الهولندية';

  @override
  String get dialectFa => 'الفارسية';

  @override
  String get dialectUr => 'الأوردو';

  @override
  String get dialectId => 'الإندونيسية';

  @override
  String get dialectArStandard => 'العربية الفصحى';

  @override
  String get dialectArSyrian => 'اللهجة السورية';

  @override
  String get dialectArLebanese => 'اللهجة اللبنانية';

  @override
  String get dialectArJordanian => 'اللهجة الأردنية';

  @override
  String get dialectArPalestinian => 'اللهجة الفلسطينية';

  @override
  String get dialectArEgyptian => 'اللهجة المصرية';

  @override
  String get dialectArIraqi => 'اللهجة العراقية';

  @override
  String get dialectArSudanese => 'اللهجة السودانية';

  @override
  String get dialectArSaudi => 'اللهجة السعودية';

  @override
  String get dialectArEmirati => 'اللهجة الإماراتية';

  @override
  String get dialectArKuwaiti => 'اللهجة الكويتية';

  @override
  String get dialectArQatari => 'اللهجة القطرية';

  @override
  String get dialectArOmani => 'اللهجة العمانية';

  @override
  String get dialectArYemeni => 'اللهجة اليمنية';

  @override
  String get dialectArMoroccan => 'اللهجة المغربية';

  @override
  String get dialectArAlgerian => 'اللهجة الجزائرية';

  @override
  String get dialectArTunisian => 'اللهجة التونسية';

  @override
  String get dialectArLibyan => 'اللهجة الليبية';

  @override
  String get appLanguage => 'لغة التطبيق';

  @override
  String get typeNoun => 'اسم';

  @override
  String get typeProperNoun => 'اسم علم';

  @override
  String get typeVerb => 'فعل';

  @override
  String get typeVerbPast => 'فعل ماض';

  @override
  String get typeVerbPresent => 'فعل مضارع';

  @override
  String get typeVerbImperative => 'فعل أمر';

  @override
  String get typeVerbProhibitive => 'فعل نهي';

  @override
  String get typeVerbPastPassive => 'ماضٍ مجهول';

  @override
  String get typeVerbPresentPassive => 'مضارع مجهول';

  @override
  String get typeVerbDefective => 'فعل ناقص';

  @override
  String get typeMasdar => 'مصدر';

  @override
  String get typeActiveParticiple => 'اسم فاعل';

  @override
  String get typePassiveParticiple => 'اسم مفعول';

  @override
  String get typeElative => 'اسم تفضيل';

  @override
  String get typeAdjective => 'صفة';

  @override
  String get typeAdverb => 'ظرف';

  @override
  String get typeHal => 'حال';

  @override
  String get typePronoun => 'ضمير';

  @override
  String get typeDemonstrative => 'اسم إشارة';

  @override
  String get typeRelative => 'اسم موصول';

  @override
  String get typeInterrogative => 'أداة استفهام';

  @override
  String get typePreposition => 'حرف جر';

  @override
  String get typeParticle => 'أداة';

  @override
  String get typeNumber => 'عدد';

  @override
  String get typePhrase => 'تركيب';

  @override
  String get typeExpression => 'تعبير';

  @override
  String get typeIdiom => 'اصطلاح';

  @override
  String get siga01 => 'الماضي';

  @override
  String get siga02 => 'المضارع';

  @override
  String get siga03 => 'المصدر';

  @override
  String get siga04 => 'اسم الفاعل';

  @override
  String get siga05 => 'اسم المفعول';

  @override
  String get siga06 => 'جحد مطلق';

  @override
  String get siga07 => 'جحد مستغرق';

  @override
  String get siga08 => 'نفي الحال';

  @override
  String get siga09 => 'نفي الاستقبال';

  @override
  String get siga10 => 'تأكيد النفي';

  @override
  String get siga11 => 'أمر الغائب';

  @override
  String get siga12 => 'نهي الغائب';

  @override
  String get siga13 => 'أمر الحاضر';

  @override
  String get siga14 => 'نهي الحاضر';

  @override
  String get siga15 => 'الزمان والمكان';

  @override
  String get siga16 => 'اسم الآلة';

  @override
  String get siga17 => 'اسم المرة';

  @override
  String get siga18 => 'اسم الهيئة';

  @override
  String get siga19 => 'اسم التصغير';

  @override
  String get siga20 => 'الاسم المنسوب';

  @override
  String get siga21 => 'صيغة المبالغة';

  @override
  String get siga22 => 'اسم التفضيل';

  @override
  String get siga23 => 'تعجب 1';

  @override
  String get siga24 => 'تعجب 2';

  @override
  String get dialectMs => 'الماليزية';

  @override
  String get dialectBn => 'البنغالية';

  @override
  String get dialectUz => 'الأوزبكية';

  @override
  String get dialectAz => 'الأذربيجانية';

  @override
  String get prepositionsLabel => 'مع حروف الجر';

  @override
  String get tashkeelToggle => 'التشكيل';

  @override
  String get tashkeelSettingHint => 'إظهار الحركات في الشروح والأمثلة';

  @override
  String get rootMatches => 'من الجذر نفسه';

  @override
  String get dictionaryLanguage => 'لغة القاموس';

  @override
  String get dictionaryLanguageHint => 'لغة شرح الكلمات';

  @override
  String get arabicArabicDictionary => 'معجم عربي–عربي';
}
