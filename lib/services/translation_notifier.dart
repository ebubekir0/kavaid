import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dialect_language.dart';
import 'dialect_translation_service.dart';
import 'dialect_tts_service.dart';

const String _kSourceLangKey = 'dialect_source_lang';
const String _kTargetLangKey = 'dialect_target_lang';
const String _kDirectionKey = 'dialect_left_to_right';

class TranslationNotifier extends ChangeNotifier {
  final DialectTranslationService _translationService = DialectTranslationService();
  final DialectTTSService _ttsService = DialectTTSService();

  DialectLanguage _leftLang = DialectLanguage.supportedLanguages.firstWhere((l) => l.code == 'tr');
  DialectLanguage _rightLang = DialectLanguage.supportedLanguages.firstWhere((l) => l.code == 'ar_syrian');
  bool _isLeftToRight = true;

  String _inputText = '';
  String _outputText = '';
  String _outputTextWithDiacritics = '';
  String _transliteration = '';
  bool _isLoading = false;
  bool _isSpeaking = false;
  bool _showDiacritics = false;

  // Getters
  DialectLanguage get sourceLanguage => _isLeftToRight ? _leftLang : _rightLang;
  DialectLanguage get targetLanguage => _isLeftToRight ? _rightLang : _leftLang;
  DialectLanguage get leftLang => _leftLang;
  DialectLanguage get rightLang => _rightLang;
  bool get isLeftToRight => _isLeftToRight;
  String get inputText => _inputText;
  String get outputText => _outputText;
  String get outputTextWithDiacritics => _outputTextWithDiacritics;
  String get transliteration => _transliteration;
  bool get isLoading => _isLoading;
  bool get isSpeaking => _isSpeaking;
  bool get showDiacritics => _showDiacritics;
  bool get hasOutput => _outputText.isNotEmpty;

  TranslationNotifier() {
    _loadSavedLanguages();
  }

  Future<void> _loadSavedLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final leftCode = prefs.getString(_kSourceLangKey);
      final rightCode = prefs.getString(_kTargetLangKey);
      _isLeftToRight = prefs.getBool(_kDirectionKey) ?? _isLeftToRight;
      if (leftCode != null) {
        _leftLang = DialectLanguage.supportedLanguages.firstWhere(
          (l) => l.code == leftCode,
          orElse: () => _leftLang,
        );
      }
      if (rightCode != null) {
        _rightLang = DialectLanguage.supportedLanguages.firstWhere(
          (l) => l.code == rightCode,
          orElse: () => _rightLang,
        );
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSourceLangKey, _leftLang.code);
      await prefs.setString(_kTargetLangKey, _rightLang.code);
      await prefs.setBool(_kDirectionKey, _isLeftToRight);
    } catch (_) {}
  }

  void setLeftLanguage(DialectLanguage lang) {
    _leftLang = lang;
    _saveLanguages();
    notifyListeners();
  }

  void setRightLanguage(DialectLanguage lang) {
    _rightLang = lang;
    _saveLanguages();
    notifyListeners();
  }

  void toggleDirection() {
    final oldInput = _inputText;
    final oldOutput = _outputText.isNotEmpty ? _outputText : _outputTextWithDiacritics;
    _isLeftToRight = !_isLeftToRight;
    _inputText = oldOutput;
    _outputText = oldInput;
    _outputTextWithDiacritics = oldInput;
    _transliteration = '';
    _saveLanguages();
    notifyListeners();
  }

  void updateInputText(String text) {
    _inputText = text.length > DialectTranslationService.maxInputLength
        ? text.substring(0, DialectTranslationService.maxInputLength)
        : text;
    notifyListeners();
  }

  void clearAll() {
    _inputText = '';
    _outputText = '';
    _outputTextWithDiacritics = '';
    _transliteration = '';
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> translate() async {
    if (_inputText.trim().isEmpty) return;
    _isLoading = true;
    _transliteration = '';
    notifyListeners();

    try {
      final result = await _translationService.translateWithPronunciation(
        text: _inputText,
        source: sourceLanguage,
        target: targetLanguage,
      );
      final translation = result['translation'] ?? '';
      final pronunciation = result['pronunciation'] ?? '';
      _outputTextWithDiacritics = translation;
      _outputText = _showDiacritics ? translation : _removeDiacritics(translation);
      _transliteration = pronunciation;
    } catch (e) {
      _outputText = 'Hata oluştu.';
      debugPrint('TranslationNotifier.translate: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleDiacritics() {
    _showDiacritics = !_showDiacritics;
    _outputText = _showDiacritics
        ? _outputTextWithDiacritics
        : _removeDiacritics(_outputTextWithDiacritics);
    notifyListeners();
  }

  Future<void> speakTarget() async {
    if (_outputTextWithDiacritics.trim().isEmpty) return;
    if (_isSpeaking) {
      await _ttsService.stop();
      _isSpeaking = false;
      notifyListeners();
      return;
    }
    _isSpeaking = true;
    notifyListeners();
    final langCode = targetLanguage.type == DialectLanguageType.arabic
        ? 'ar'
        : targetLanguage.sttCode;
    await _ttsService.speak(_outputTextWithDiacritics, languageCode: langCode);
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> speakSource() async {
    if (_inputText.trim().isEmpty) return;
    final langCode = sourceLanguage.type == DialectLanguageType.arabic
        ? 'ar'
        : sourceLanguage.sttCode;
    await _ttsService.speak(_inputText, languageCode: langCode);
  }

  String _removeDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
