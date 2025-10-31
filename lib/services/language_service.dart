import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _isFirstLaunchKey = 'is_first_launch';
  
  Locale _currentLocale = const Locale('tr');
  bool _isFirstLaunch = true;
  
  Locale get currentLocale => _currentLocale;
  bool get isFirstLaunch => _isFirstLaunch;
  
  // Desteklenen diller
  static const List<Locale> supportedLocales = [
    Locale('tr'), // Türkçe
    Locale('ar'), // Arapça
  ];
  
  // Singleton pattern
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();
  
  /// Servis başlatma
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // İlk açılış kontrolü
    _isFirstLaunch = prefs.getBool(_isFirstLaunchKey) ?? true;
    
    if (_isFirstLaunch) {
      // İlk açılış: Sistem dilini kontrol et
      await _setLanguageFromSystem();
      
      // İlk açılış flag'ini false yap
      await prefs.setBool(_isFirstLaunchKey, false);
      _isFirstLaunch = false;
    } else {
      // Daha önce açılmış: Kayıtlı dil tercihini yükle
      final savedLanguage = prefs.getString(_languageKey) ?? 'tr';
      await _setLanguage(savedLanguage);
    }
    
    notifyListeners();
  }
  
  /// Sistem dilini kontrol et ve uygun dili seç
  Future<void> _setLanguageFromSystem() async {
    final systemLocale = ui.window.locale;
    final systemLanguageCode = systemLocale.languageCode;
    
    debugPrint('📱 Sistem dili tespit edildi: $systemLanguageCode');
    
    // Sistem dili Arapça ise Arapça, değilse Türkçe seç
    if (systemLanguageCode == 'ar') {
      await _setLanguage('ar');
      debugPrint('✅ Sistem dili Arapça olduğu için uygulama dili Arapça seçildi');
    } else {
      await _setLanguage('tr');
      debugPrint('✅ Sistem dili Türkçe/diğer olduğu için uygulama dili Türkçe seçildi');
    }
  }
  
  /// Dil değiştirme
  Future<void> changeLanguage(String languageCode) async {
    await _setLanguage(languageCode);
    notifyListeners();
  }
  
  /// Dil ayarlama (internal)
  Future<void> _setLanguage(String languageCode) async {
    if (languageCode == 'tr' || languageCode == 'ar') {
      _currentLocale = Locale(languageCode);
      
      // Tercihi kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      debugPrint('🌐 Dil değiştirildi: $languageCode');
    } else {
      debugPrint('⚠️ Desteklenmeyen dil kodu: $languageCode');
    }
  }
  
  /// Mevcut dil Arapça mı?
  bool get isArabic => _currentLocale.languageCode == 'ar';
  
  /// Mevcut dil Türkçe mi?
  bool get isTurkish => _currentLocale.languageCode == 'tr';
  
  /// Arapça RTL desteği için TextDirection döndür
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;
  
  /// Mevcut dil adını döndür
  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'tr':
      default:
        return 'Türkçe';
    }
  }
  
  /// Desteklenen dillerin listesi
  List<Map<String, String>> get availableLanguages => [
    {'code': 'tr', 'name': 'Türkçe'},
    {'code': 'ar', 'name': 'العربية'},
  ];
} 