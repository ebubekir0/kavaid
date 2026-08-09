import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _isFirstLaunchKey = 'is_first_launch';
  
  Locale _currentLocale = const Locale('tr');
  bool _isFirstLaunch = true;
  
  Locale get currentLocale => _currentLocale;
  bool get isFirstLaunch => _isFirstLaunch;
  
  // Desteklenen diller - Yalnızca Türkçe
  static const List<Locale> supportedLocales = [
    Locale('tr'),
  ];
  
  // Singleton pattern
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();
  
  /// Servis başlatma
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Her zaman Türkçe ayarlanır
    _currentLocale = const Locale('tr');
    
    // İlk açılış flag'ini kaydet
    _isFirstLaunch = prefs.getBool(_isFirstLaunchKey) ?? true;
    if (_isFirstLaunch) {
      await prefs.setBool(_isFirstLaunchKey, false);
      _isFirstLaunch = false;
    }
    
    notifyListeners();
  }
  
  /// Dil değiştirme - Sadece Türkçe destekleniyor
  Future<void> changeLanguage(String languageCode) async {
    _currentLocale = const Locale('tr');
    notifyListeners();
  }
  
  /// Mevcut dil Arapça mı? - Her zaman false
  bool get isArabic => false;
  
  /// Mevcut dil Türkçe mi? - Her zaman true
  bool get isTurkish => true;

  /// Mevcut dil İngilizce mi? - Her zaman false
  bool get isEnglish => false;
  
  /// Arapça RTL desteği için TextDirection döndür - Her zaman ltr
  TextDirection get textDirection => TextDirection.ltr;
  
  /// Mevcut dil adını döndür - Her zaman Türkçe
  String get currentLanguageName => 'Türkçe';
  
  /// Desteklenen dillerin listesi - Yalnızca Türkçe
  List<Map<String, String>> get availableLanguages => [
    {'code': 'tr', 'name': 'Türkçe'},
  ];
} 