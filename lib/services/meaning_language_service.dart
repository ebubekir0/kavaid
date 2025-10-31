import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kelime anlamlarının hangi dilde gösterileceğini yöneten servis
/// Türkçe (tr) ve İngilizce (en) arasında geçiş sağlar
class MeaningLanguageService extends ChangeNotifier {
  static const String _meaningLanguageKey = 'meaning_language_preference';
  
  String _currentMeaningLanguage = 'tr'; // Varsayılan: Türkçe
  
  String get currentMeaningLanguage => _currentMeaningLanguage;
  bool get isEnglish => _currentMeaningLanguage == 'en';
  bool get isTurkish => _currentMeaningLanguage == 'tr';
  
  // Singleton pattern
  static final MeaningLanguageService _instance = MeaningLanguageService._internal();
  factory MeaningLanguageService() => _instance;
  MeaningLanguageService._internal();
  
  /// Servis başlatma - kayıtlı tercihi yükle
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentMeaningLanguage = prefs.getString(_meaningLanguageKey) ?? 'tr';
    notifyListeners();
    debugPrint('🌐 Anlam dili tercihi yüklendi: $_currentMeaningLanguage');
  }
  
  /// Anlam dilini değiştir (tr/en)
  Future<void> changeMeaningLanguage(String languageCode) async {
    if (languageCode == 'tr' || languageCode == 'en') {
      _currentMeaningLanguage = languageCode;
      
      // Tercihi kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_meaningLanguageKey, languageCode);
      
      notifyListeners();
      debugPrint('🔄 Anlam dili değiştirildi: $languageCode');
    } else {
      debugPrint('⚠️ Desteklenmeyen anlam dili: $languageCode');
    }
  }
  
  /// Türkçe ve İngilizce arasında toggle yap
  Future<void> toggleMeaningLanguage() async {
    final newLanguage = _currentMeaningLanguage == 'tr' ? 'en' : 'tr';
    await changeMeaningLanguage(newLanguage);
  }
  
  /// Mevcut anlam dilinin adını döndür
  String get currentLanguageName {
    switch (_currentMeaningLanguage) {
      case 'en':
        return 'English';
      case 'tr':
      default:
        return 'Türkçe';
    }
  }
  
  /// Mevcut anlam dilinin kısa adını döndür
  String get currentLanguageShort {
    switch (_currentMeaningLanguage) {
      case 'en':
        return 'EN';
      case 'tr':
      default:
        return 'TR';
    }
  }
}
