import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/word_model.dart';
import '../screens/subscription_screen.dart';
import '../services/ai_chat_service.dart';
import '../services/tts_service.dart';

/// Sözlük içindeki AI asistan sohbeti.
///
/// Tasarım bilinçli olarak mevcut `AiTeacherSheet` diline sadık: aynı mavi,
/// aynı yüzey renkleri, aynı tipografi. Farkı: açılışta 12 saniyelik yapı
/// üretimi yok, sohbet hemen başlar ve bağlamı korur.
class AiChatSheet extends StatefulWidget {
  final WordModel? word;
  final bool isDarkMode;
  final String? openingMessage;

  const AiChatSheet({
    super.key,
    this.word,
    required this.isDarkMode,
    this.openingMessage,
  });

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final AiChatService _service = AiChatService.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TTSService _tts = TTSService();

  static const _recentKey = 'ai_recent_questions_v1';
  static const _recentMax = 5;
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _service.addListener(_onServiceChanged);
    _service.open(word: widget.word);
    final opening = widget.openingMessage;
    if (opening != null && opening.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _submit(opening);
      });
    }
  }

  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_recentKey) ?? const <String>[];
      if (mounted) setState(() => _recent = list);
    } catch (_) {}
  }

  /// Kullanıcının yazdığı soruyu "son sorulanlar" listesinin başına ekler
  /// (aynı soru tekrarlanmaz, en fazla [_recentMax] tutulur).
  Future<void> _rememberQuestion(String question) async {
    final list = [
      question,
      ..._recent.where((q) => q.toLowerCase() != question.toLowerCase()),
    ].take(_recentMax).toList();
    if (mounted) setState(() => _recent = list);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentKey, list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submit([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    if (!_service.canSend && !_service.isPremium) {
      _showLimitSheet();
      return;
    }
    if (preset == null) {
      _controller.clear();
      unawaited(_rememberQuestion(text));
    }
    await _service.send(text);
  }

  void _showLimitSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bugünkü ücretsiz asistan hakkın doldu.'),
        action: SnackBarAction(
          label: 'Premium',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final bg = dark ? const Color(0xFF1C1C1E) : Colors.white;
    final text = dark ? Colors.white : const Color(0xFF1C1C1E);
    final sub = dark ? const Color(0xFFB0B0B5) : const Color(0xFF6D6D70);
    final blue = const Color(0xFF007AFF);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        // Kendi ScrollController'ımızı kullanıyoruz, mesaj listesi
        // büyüdükçe otomatik aşağı kaydırılsın.
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildHeader(bg, text, sub, blue),
              Divider(
                height: 1,
                color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              ),
              Expanded(
                child: _buildConversation(text, sub, blue, dark),
              ),
              _buildComposer(text, sub, blue, dark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color bg, Color text, Color sub, Color blue) {
    final word = _service.contextWord;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 6, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: blue, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Asistan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _subtitle(word),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: sub,
                  ),
                ),
              ],
            ),
          ),
          if (_service.messages.isNotEmpty)
            IconButton(
              onPressed: _confirmReset,
              icon: Icon(Icons.refresh_rounded, size: 19, color: sub),
              tooltip: 'Sohbeti sıfırla',
            ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, size: 19, color: sub),
          ),
        ],
      ),
    );
  }

  String _subtitle(WordModel? word) {
    if (word != null) {
      final head = (word.harekeliKelime?.isNotEmpty == true
              ? word.harekeliKelime!
              : word.kelime)
          .trim();
      return '$head hakkında sor';
    }
    return _service.isPremium
        ? 'Arapça sözlük yardımcın'
        : 'Arapça sözlük yardımcın · ${_service.remainingUses} hak';
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbeti sıfırla'),
        content: const Text('Bu sohbetin geçmişi silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _service.reset();
      _controller.clear();
    }
  }

  Widget _buildConversation(Color text, Color sub, Color blue, bool dark) {
    final messages = _service.messages;

    if (messages.isEmpty) {
      return _buildStarter(text, sub, blue, dark);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingOrError(text, sub, blue, dark);
        }
        return _buildBubble(messages[index], text, sub, blue, dark);
      },
    );
  }

  Widget _buildBubble(
    AiChatMessage message,
    Color text,
    Color sub,
    Color blue,
    bool dark,
  ) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: blue,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isUser
                    ? blue
                    : (dark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF6F8FA)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: dark
                            ? const Color(0xFF48484A)
                            : const Color(0xFFE1E4E8),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: isUser ? Colors.white : text,
                    ),
                  ),
                  if (!isUser) _buildSpeakRow(sub, message.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakRow(Color sub, String messageText) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: () => _speak(messageText),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volume_up_outlined, size: 14, color: sub),
            const SizedBox(width: 4),
            Text(
              'Dinle',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.initialize();
      await _tts.speak(text);
    } catch (_) {
      // Ses yoksa sessizce geç, sohbeti bozma.
    }
  }

  Widget _buildTypingOrError(Color text, Color sub, Color blue, bool dark) {
    final error = _service.error;
    if (error != null) {
      final isLimit = error == 'limit';
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isLimit
                  ? 'Bugünkü ücretsiz asistan hakkın doldu.'
                  : error,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isLimit ? blue : sub,
              ),
            ),
            if (isLimit)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  child: const Text('Premium\'a geç'),
                ),
              ),
          ],
        ),
      );
    }

    if (!_service.isSending) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 30),
      child: Row(
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2, color: blue),
          ),
          const SizedBox(width: 8),
          Text(
            'Yazıyor...',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: sub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarter(Color text, Color sub, Color blue, bool dark) {
    final word = _service.contextWord;
    final starters = word != null
        ? <String>[
            'Bu kelimeyi kısaca anlat',
            '3 örnek cümle ver',
            'Benzer kelimelerden farkı ne?',
            'Nasıl telaffuz edilir?',
          ]
        : <String>[
            'Bir Arapça kelime tanıt',
            'En sık kullanılan 10 kelime',
            'Geçmiş zaman nasıl kurulur?',
            'Harf-i cer nedir?',
          ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      children: [
        Icon(Icons.auto_awesome_rounded, size: 34, color: blue),
        const SizedBox(height: 12),
        Text(
          word != null
              ? '${word.harekeliKelime?.isNotEmpty == true ? word.harekeliKelime : word.kelime} hakkında sorabilirsin'
              : 'Sözlükte takıldığın yeri sor',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kısa cevap veririm, bildiğimi uydurmam.',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: sub,
          ),
        ),
        const SizedBox(height: 18),
        if (_recent.isNotEmpty) ...[
          _chipsLabel('Son sorduklarım', sub),
          _chipsWrap(_recent, text, dark),
          const SizedBox(height: 18),
          _chipsLabel('Önerilenler', sub),
        ],
        _chipsWrap(starters, text, dark),
      ],
    );
  }

  Widget _chipsLabel(String label, Color sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: sub,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _chipsWrap(List<String> questions, Color text, bool dark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final q in questions)
          ActionChip(
            label: Text(
              q,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: text,
              ),
            ),
            onPressed: () => _submit(q),
            backgroundColor: dark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF6F8FA),
            side: BorderSide(
              color: dark ? const Color(0xFF48484A) : const Color(0xFFE1E4E8),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
      ],
    );
  }

  Widget _buildComposer(Color text, Color sub, Color blue, bool dark) {
    final enabled = _service.canSend;
    final bg = dark ? const Color(0xFF1C1C1E) : Colors.white;
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        12,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: text,
              ),
              decoration: InputDecoration(
                hintText: 'AI Asistan\'a sor...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: sub,
                ),
                isDense: true,
                filled: true,
                fillColor:
                    dark ? const Color(0xFF2C2C2E) : const Color(0xFFF6F8FA),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: enabled ? _submit : null,
            icon: _service.isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: blue,
              disabledBackgroundColor: const Color(0xFFC7C7CC),
              minimumSize: const Size(42, 42),
            ),
          ),
        ],
      ),
    );
  }
}
