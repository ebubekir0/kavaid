import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Çeviri özelliği için çok dilli TTS servisi.
/// Kavaid'in singleton TTSService'inden bağımsız çalışır.
class DialectTTSService {
  FlutterTts? _tts;
  bool _isInitialized = false;
  bool _isInitializing = false;

  Future<FlutterTts> _getEngine() async {
    if (_tts != null && _isInitialized) return _tts!;
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _tts!;
    }

    _isInitializing = true;
    try {
      _tts = FlutterTts();
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await _tts!.setEngine('com.google.android.tts');
        } catch (_) {}
      }
      await _tts!.setSharedInstance(true);
      await _tts!.setSpeechRate(0.5);
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      debugPrint('DialectTTS init error: $e');
      _tts = FlutterTts();
      _isInitialized = true;
    } finally {
      _isInitializing = false;
    }
    return _tts!;
  }

  Future<void> speak(String text, {required String languageCode}) async {
    if (text.trim().isEmpty) return;
    try {
      final tts = await _getEngine();
      await tts.stop();

      final isAvailable = await tts.isLanguageAvailable(languageCode);
      if (isAvailable) {
        await tts.setLanguage(languageCode);
      } else if (languageCode.startsWith('ar')) {
        await tts.setLanguage('ar');
      } else {
        final short = languageCode.split('-').first;
        await tts.setLanguage(short);
      }
      await tts.speak(text);
    } catch (e) {
      debugPrint('DialectTTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  void dispose() {
    _tts?.stop();
  }
}
