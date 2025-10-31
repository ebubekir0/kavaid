// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get searchPlaceholder => 'ابحث عن كلمة';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get appName => 'كوائد';

  @override
  String get rateApp => 'قيم التطبيق';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get notFound => 'لم يتم العثور عليه';

  @override
  String get searchWithAI => 'البحث بالذكاء الاصطناعي';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get language => 'اللغة';

  @override
  String get languageTurkish => 'التركية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get premium => 'بريميوم';

  @override
  String get removeAds => 'إزالة الإعلانات';

  @override
  String get restorePurchases => 'استعادة المشتريات';

  @override
  String get share => 'مشاركة';

  @override
  String get contact => 'اتصل بنا';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String credits(Object count) {
    return 'الحق: $count';
  }

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get searching => 'جاري البحث...';

  @override
  String get wordMeaning => 'Kelime Anlamı';

  @override
  String get exampleSentence => 'Örnek Cümle';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get save => 'حفظ';

  @override
  String get savedWords => 'الكلمات المحفوظة';

  @override
  String get home => 'الصفحة الرئيسية';

  @override
  String get darkMode => 'الوضع المظلم';

  @override
  String get lightMode => 'الوضع المضيء';
}
