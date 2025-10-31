import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isSpeaking = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ TTS: Zaten başlatılmış');
      return;
    }
    
    if (_isInitializing) {
      debugPrint('⏳ TTS: Başlatma devam ediyor, bekleniyor...');
      // Başlatma işlemi devam ediyorsa bekle
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    
    try {
      debugPrint('🔄 TTS: Başlatılıyor...');

      // Android için TTS engine ayarları
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _flutterTts.setEngine("com.google.android.tts");
      }

      // Set language to Arabic. Try specific locale first.
      try {
        await _flutterTts.setLanguage("ar-SA");
        debugPrint('✅ TTS: ar-SA dili ayarlandı');
      } catch (e) {
        debugPrint('⚠️ TTS: ar-SA ayarlanamadı, genel `ar` deneniyor.');
        try {
          await _flutterTts.setLanguage("ar");
          debugPrint('✅ TTS: ar dili ayarlandı');
        } catch (e2) {
          debugPrint('❌ TTS: Arapça dil ayarlanamadı: $e2');
          // Fallback olarak İngilizce deneyelim
          await _flutterTts.setLanguage("en-US");
          debugPrint('⚠️ TTS: Fallback - İngilizce ayarlandı');
        }
      }

      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // iOS için ek ayarlar
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ]);
      }

      // Set handlers to manage speaking state
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('🎵 TTS: Konuşma başladı');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('✅ TTS: Konuşma tamamlandı');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('❌ TTS Hatası: $msg');
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        debugPrint('⏹️ TTS: Konuşma iptal edildi');
      });

      _isInitialized = true;
      debugPrint('✅ TTS servisi başarıyla başlatıldı');
    } catch (e) {
      debugPrint('❌ TTS başlatma hatası: $e');
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  // Warms up the engine to reduce initial delay. Call this on app startup.
  Future<void> warmUp() async {
    // Ensure service is initialized before warming up.
    if (!_isInitialized) {
      await initialize();
    }
    
    // If initialization failed, don't proceed.
    if (!_isInitialized) return;

    try {
      // Speak a silent character to prepare the engine, then restore volume.
      await _flutterTts.setVolume(0.0);
      await _flutterTts.speak(' ');
      await _flutterTts.stop();
      await _flutterTts.setVolume(1.0);
      debugPrint('🔥 TTS warm-up tamamlandı');
    } catch (e) {
      debugPrint('⚠️ TTS warm-up hatası: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) {
      debugPrint('⚠️ TTS: Boş metin, konuşma atlandı.');
      return;
    }

    debugPrint('🎤 TTS: Konuşma başlatılıyor: "$text"');

    if (!_isInitialized) {
      debugPrint('⚠️ TTS başlatılmamış, şimdi başlatılıyor...');
      await initialize();
      
      if (!_isInitialized) {
        debugPrint('❌ TTS başlatılamadı, konuşma iptal edildi');
        return;
      }
    }

    try {
      // Stop any currently playing speech before starting a new one.
      if (_isSpeaking) {
        debugPrint('⏹️ TTS: Önceki konuşma durduruluyor...');
        await stop();
        // Kısa bir bekleme ekleyelim
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('🔊 TTS: Ses çıkışı başlatılıyor...');
      final result = await _flutterTts.speak(text);
      debugPrint('📢 TTS speak result: $result');
      
    } catch (e) {
      debugPrint('❌ TTS konuşma hatası: $e');
    }
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    // The state is managed by handlers, no need to set _isSpeaking here.
  }

  void dispose() {
    _flutterTts.stop();
  }
}