import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Google Cloud TTS ile önceden indirilmiş ses dosyalarını çalan veya
/// flutter_tts ile dinamik telaffuz sağlayan servis.
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isInitialized = false;
  bool _isPlaying = false;
  Completer<void>? _playCompleter;
  double _playbackRate = 1.0;
  String _audioBasePath = "audio/taysir_sira";

  void setBookId(String bookId) {
    _audioBasePath = "audio/$bookId";
    debugPrint('🔊 TTS Yolu Ayarlandı: $_audioBasePath');
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // AudioPlayer handlers
      _audioPlayer.onPlayerComplete.listen((_) {
        debugPrint('✅ Ses (Asset) tamamlandı');
        _isPlaying = false;
        _completeCurrentPlayback();
      });

      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.stopped || state == PlayerState.completed) {
          _isPlaying = false;
        } else if (state == PlayerState.playing) {
          _isPlaying = true;
        }
      });

      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      // FlutterTts settings
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _flutterTts.setEngine("com.google.android.tts");
      }
      await _flutterTts.setLanguage("ar");
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setVolume(1.0);

      _isInitialized = true;
      debugPrint('✅ TTS (Mixed Mode) servisi başlatıldı');
    } catch (e) {
      debugPrint('❌ TTS init hatası: $e');
    }
  }

  void _completeCurrentPlayback() {
    if (_playCompleter != null && !_playCompleter!.isCompleted) {
      _playCompleter!.complete();
    }
  }

  String _getAudioFileName(String word) {
    final hash = md5.convert(utf8.encode(word)).toString();
    return "$hash.mp3";
  }

  Future<void> warmUp() async {
    if (!_isInitialized) await initialize();
  }

  /// Normal konuşma: Önce asset dener, yoksa FlutterTts kullanır.
  Future<void> speak(String text) async {
    await _playAudio(text, wait: false);
  }

  /// Beklemeli konuşma (auto-play için): Ses bitene kadar bekler.
  Future<void> speakAndWait(String text) async {
    await _playAudio(text, wait: true);
  }

  Future<void> _playAudio(String text, {required bool wait}) async {
    if (text.trim().isEmpty) return;
    if (!_isInitialized) await initialize();

    try {
      if (_isPlaying) await stop();

      final fileName = _getAudioFileName(text);
      final assetPath = "$_audioBasePath/$fileName";

      bool assetExists = false;
      try {
        await rootBundle.load("assets/$assetPath");
        assetExists = true;
      } catch (e) {
        // Asset yok, FlutterTts fallback
      }

      if (assetExists) {
        if (wait) _playCompleter = Completer<void>();
        await _audioPlayer.setPlaybackRate(_playbackRate);
        await _audioPlayer.play(AssetSource(assetPath));
        _isPlaying = true;

        if (wait && _playCompleter != null) {
          await _playCompleter!.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () => debugPrint('⏰ Ses asset timeout'),
          );
        }
      } else {
        // FlutterTts ile oku
        await _flutterTts.setSpeechRate(_playbackRate * 0.4); // Orantıla
        if (wait) {
          await _flutterTts.awaitSpeakCompletion(true);
        }
        await _flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint('❌ Ses çalma hatası: $e');
      _completeCurrentPlayback();
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    await _flutterTts.stop();
    _isPlaying = false;
    _completeCurrentPlayback();
  }

  Future<void> setRate(double rate) async {
    _playbackRate = rate.clamp(0.5, 2.0);
    if (_isPlaying) {
      await _audioPlayer.setPlaybackRate(_playbackRate);
    }
    await _flutterTts.setSpeechRate(_playbackRate * 0.4);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }
}