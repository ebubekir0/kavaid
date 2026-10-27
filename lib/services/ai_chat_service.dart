import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/word_model.dart';
import 'ai_teacher_service.dart';
import 'connectivity_service.dart';
import 'gemini_service.dart';
import 'package:kavaid/l10n/l10n.dart';

/// Sözlük içindeki AI asistanının mesajı.
class AiChatMessage {
  final String text;
  final bool isUser;

  const AiChatMessage({required this.text, required this.isUser});
}

/// Gerçek konuşma geçmişi. Gemini `contents` formatında tutulur ki takip
/// eden sorular bağını kaybetmesin ("peki ya bu?" -> anlamlı cevap).
class _Memory {
  final List<Map<String, dynamic>> _turns = [];
  String? _wordKey;

  void reset({String? wordKey}) {
    _wordKey = wordKey;
    _turns.clear();
  }

  bool matches(String? wordKey) => _wordKey == wordKey;

  void addUser(String text) => _turns.add(_turn('user', text));
  void addModel(String text) => _turns.add(_turn('model', text));

  void dropLastUserTurn() {
    for (var i = _turns.length - 1; i >= 0; i--) {
      if (_turns[i]['role'] == 'user') {
        _turns.removeRange(i, _turns.length);
        return;
      }
    }
  }

  /// Uzun sohbetlerde maliyeti ve gecikmeyi sınırla.
  List<Map<String, dynamic>> toContents() {
    const maxTurns = 10;
    var slice = _turns.length <= maxTurns
        ? List<Map<String, dynamic>>.from(_turns)
        : List<Map<String, dynamic>>.from(
            _turns.sublist(_turns.length - maxTurns),
          );
    // Gemini 'contents' her zaman 'user' ile başlamak zorunda; kısaltma
    // sonrası 'model' ile başlarsa 400 döner, o turu at.
    while (slice.isNotEmpty && slice.first['role'] != 'user') {
      slice = slice.sublist(1);
    }
    return slice;
  }

  static Map<String, dynamic> _turn(String role, String text) => {
        'role': role,
        'parts': <Map<String, String>>[
          {'text': text},
        ],
      };
}

/// Sözlük içinde çalışan basit AI sohbet asistanı.
///
/// Mevcut `AiTeacherService` tek seferlik yapılandırılmış açıklama üretir.
/// Bu servis onun yerine geçmez, üzerine çalışır: gerçek konuşma geçmişi
/// tutar, hızlı düz metin cevap döner ve **açılışta kota harcamaz**.
class AiChatService extends ChangeNotifier {
  static final AiChatService instance = AiChatService._();

  AiChatService._();

  final GeminiService _gemini = GeminiService();
  final AiTeacherService _teacher = AiTeacherService();
  final _Memory _memory = _Memory();
  final List<AiChatMessage> _messages = [];

  List<AiChatMessage> get messages => List.unmodifiable(_messages);

  WordModel? _contextWord;
  WordModel? get contextWord => _contextWord;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _error;
  String? get error => _error;

  /// Cevap alınamayan son soru; arayüz "Tekrar dene" ile yeniden gönderir.
  String? _failedText;
  String? get failedText => _failedText;

  int _remaining = 0;
  int get remainingUses => _remaining;

  bool get isPremium => _teacher.isPremium;
  bool get canSend => !_isSending && (isPremium || _remaining > 0);

  /// Kelime bağlamıyla sohbeti başlat. Aynı kelimeyle tekrar açılırsa geçmiş
  /// korunur; farklı kelime ya da kelimesiz açılışta sıfırlanır.
  void open({WordModel? word}) {
    final key = _wordKey(word);
    if (_memory.matches(key)) return;

    _memory.reset(wordKey: key);
    _messages.clear();
    _contextWord = word;
    _error = null;
    _failedText = null;
    unawaited(_refreshRemaining());
    notifyListeners();
  }

  /// Geçmişi siler; kelime bağlamı korunur (kelime hakkında yeni sohbet).
  void reset() {
    _memory.reset(wordKey: _wordKey(_contextWord));
    _messages.clear();
    _error = null;
    _failedText = null;
    notifyListeners();
  }

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isSending) return;

    _error = null;
    _failedText = null;

    // Kontroller mesaj eklenmeden önce yapılır, böylece hakkı dolmuşken
    // kullanıcı boş bir sohbet kutusunda kalmaz.
    final hasInternet = await ConnectivityService().hasInternetConnection();
    if (!hasInternet) {
      _error = l10n.internetBaglantisiGerekiyor;
      notifyListeners();
      return;
    }

    await _refreshRemaining();
    if (!isPremium && _remaining <= 0) {
      _error = 'limit';
      notifyListeners();
      return;
    }

    _messages.add(AiChatMessage(text: text, isUser: true));
    _isSending = true;
    notifyListeners();

    var answered = false;
    try {
      _memory.addUser(text);
      final reply = await _gemini.askInChat(
        history: _memory.toContents(),
        contextWord: _contextWord,
      );
      _memory.addModel(reply);
      _messages.add(AiChatMessage(text: reply, isUser: false));
      answered = true;
    } on GeminiApiKeyInvalidException {
      _fail(text, l10n.aiAsistanSuAnKullanilamiyor);
    } on TimeoutException {
      _fail(text, l10n.yanitGelmedi);
    } catch (e) {
      debugPrint('[AiChatService] send failed: $e');
      _fail(text, l10n.suAndaCevapAlinamadi);
    } finally {
      _isSending = false;
      // Hak yalnızca cevap alındığında düşer; hata kullanıcıya yazılmaz.
      if (answered && !isPremium) {
        await _teacher.consumeQuota();
        await _refreshRemaining();
      }
      notifyListeners();
    }
  }

  void _fail(String text, String message) {
    _error = message;
    _failedText = text;
    _memory.dropLastUserTurn();
    final i = _messages.lastIndexWhere((m) => m.isUser && m.text == text);
    if (i >= 0) _messages.removeAt(i);
  }

  Future<void> _refreshRemaining() async {
    try {
      _remaining = await _teacher.remainingFreeUses();
    } catch (_) {
      _remaining = 0;
    }
  }

  String? _wordKey(WordModel? word) {
    if (word == null) return null;
    final raw = (word.harekeliKelime?.isNotEmpty == true
            ? word.harekeliKelime!
            : word.kelime)
        .trim();
    return raw.isEmpty ? null : raw;
  }
}
