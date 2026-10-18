import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/word_model.dart';
import '../screens/subscription_screen.dart';
import '../services/ai_chat_service.dart';
import '../services/ai_teacher_service.dart';
import '../services/tts_service.dart';
import 'ai_answer_text.dart';
import 'search_result_card_parts.dart' show ArabicTextStyles;

/// Sözlük içindeki AI asistan sohbeti.
///
/// Sohbet hemen başlar ve bağlamı korur. Cevaplar kısa tutulur; Arapça
/// kısımlar Arapça fontla gösterilir, kopyalanabilir ve yalnızca Arapça
/// kısımları seslendirilebilir.
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

class _Palette {
  _Palette(this.dark)
    : bg = dark ? const Color(0xFF1C1C1E) : Colors.white,
      text = dark ? Colors.white : const Color(0xFF1C1C1E),
      sub = dark ? const Color(0xFFB0B0B5) : const Color(0xFF6D6D70),
      surface = dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F4F7),
      line = dark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

  final bool dark;
  final Color bg;
  final Color text;
  final Color sub;
  final Color surface;
  final Color line;

  static const blue = Color(0xFF007AFF);
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
    if (text.isEmpty || _service.isSending) return;
    if (preset == null) {
      _controller.clear();
      unawaited(_rememberQuestion(text));
    }
    await _service.send(text);
  }

  void _openPremium() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kopyalandı'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Cevabın yalnızca Arapça kısımlarını okur; Türkçe metni Arapça sesle
  /// okumak anlamsız olurdu.
  Future<void> _speakArabic(String text) async {
    final parts = arabicParts(text);
    if (parts.isEmpty) return;
    try {
      await _tts.initialize();
      await _tts.speak(parts.join('، '));
    } catch (_) {
      // Ses yoksa sessizce geç, sohbeti bozma.
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni sohbet'),
        content: const Text('Bu sohbetin geçmişi silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _service.reset();
      _controller.clear();
    }
  }

  static String _head(WordModel word) =>
      (word.harekeliKelime?.isNotEmpty == true
              ? word.harekeliKelime!
              : word.kelime)
          .trim();

  @override
  Widget build(BuildContext context) {
    final p = _Palette(widget.isDarkMode);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, _) {
        // Kendi ScrollController'ımızı kullanıyoruz, mesaj listesi
        // büyüdükçe otomatik aşağı kaydırılsın.
        return Container(
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: p.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildHeader(p),
              Divider(height: 1, color: p.line),
              Expanded(child: _buildConversation(p)),
              _buildFollowUps(p),
              _buildComposer(p),
            ],
          ),
        );
      },
    );
  }

  Widget _aiBadge(double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _Palette.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: _Palette.blue,
        size: iconSize,
      ),
    );
  }

  Widget _buildHeader(_Palette p) {
    final word = _service.contextWord;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 10),
      child: Row(
        children: [
          _aiBadge(34, 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Asistan',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                if (word != null)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _head(word),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                          style: ArabicTextStyles.form.copyWith(
                            fontSize: 16,
                            height: 1.25,
                            color: _Palette.blue,
                          ),
                        ),
                      ),
                      Text(
                        ' hakkında',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: p.sub,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Arapça sözlük yardımcın',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: p.sub,
                    ),
                  ),
              ],
            ),
          ),
          if (!_service.isPremium) _buildQuotaPill(p),
          if (_service.messages.isNotEmpty)
            IconButton(
              onPressed: _confirmReset,
              icon: Icon(Icons.restart_alt_rounded, size: 21, color: p.sub),
              tooltip: 'Yeni sohbet',
            ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, size: 21, color: p.sub),
            tooltip: 'Kapat',
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaPill(_Palette p) {
    final left = _service.remainingUses;
    final empty = left <= 0;
    return Tooltip(
      message: 'Bugünkü ücretsiz soru hakkın',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (empty ? const Color(0xFFFF9500) : _Palette.blue).withValues(
            alpha: 0.12,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 14,
              color: empty ? const Color(0xFFFF9500) : _Palette.blue,
            ),
            const SizedBox(width: 2),
            Text(
              '$left/${AiTeacherService.freeDailyLimit}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: empty ? const Color(0xFFFF9500) : _Palette.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversation(_Palette p) {
    final messages = _service.messages;
    if (messages.isEmpty && _service.error == null && !_service.isSending) {
      return _buildStarter(p);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) return _buildStatus(p);
        final message = messages[index];
        return message.isUser
            ? _buildQuestion(message.text)
            : _buildAnswer(message.text, p);
      },
    );
  }

  Widget _buildQuestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 48),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: const BoxDecoration(
            color: _Palette.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswer(String text, _Palette p) {
    final hasArabic = arabicParts(text).isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aiBadge(26, 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: SelectionArea(
                    child: AiAnswerText(text: text, color: p.text),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _miniAction(
                      Icons.copy_rounded,
                      'Kopyala',
                      () => _copy(text),
                      p,
                    ),
                    if (hasArabic)
                      _miniAction(
                        Icons.volume_up_rounded,
                        'Arapçasını dinle',
                        () => _speakArabic(text),
                        p,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniAction(
    IconData icon,
    String label,
    VoidCallback onTap,
    _Palette p,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: p.sub),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: p.sub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Listenin sonu: yazıyor göstergesi, hata (tekrar dene) ya da hak bitti.
  Widget _buildStatus(_Palette p) {
    final error = _service.error;
    if (error == 'limit') return _buildLimitCard(p);
    if (error != null) {
      final failed = _service.failedText;
      return Padding(
        padding: const EdgeInsets.only(left: 34, bottom: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 16, color: p.sub),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                error,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: p.sub,
                ),
              ),
            ),
            if (failed != null)
              TextButton(
                onPressed: () => _submit(failed),
                child: const Text('Tekrar dene'),
              ),
          ],
        ),
      );
    }
    if (!_service.isSending) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _aiBadge(26, 14),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _TypingDots(color: p.sub),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard(_Palette p) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.blue.withValues(alpha: p.dark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_clock_rounded,
                size: 18,
                color: _Palette.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bugünkü ${AiTeacherService.freeDailyLimit} ücretsiz soru hakkın bitti',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hakların yarın yenilenir. Premium ile sınırsız sorabilirsin.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: p.sub,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _openPremium,
            style: FilledButton.styleFrom(
              backgroundColor: _Palette.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Premium\'a geç'),
          ),
        ],
      ),
    );
  }

  Widget _buildStarter(_Palette p) {
    final word = _service.contextWord;
    final starters = word != null
        ? const <String>[
            'Kısaca anlat',
            '3 örnek cümle ver',
            'Benzer kelimelerden farkı ne?',
            'Okunuşunu Latin harfleriyle yaz',
          ]
        : const <String>[
            'Geçmiş zaman nasıl kurulur?',
            'Harf-i cer nedir?',
            'İsim cümlesi nasıl kurulur?',
            'En sık kullanılan 10 fiil',
          ];

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      children: [
        if (word != null) _buildWordContext(word, p) else _buildIntro(p),
        const SizedBox(height: 18),
        if (_recent.isNotEmpty) ...[
          _sectionLabel('Son sorduklarım', p),
          for (final q in _recent) _suggestionRow(Icons.history_rounded, q, p),
          const SizedBox(height: 14),
        ],
        _sectionLabel(word != null ? 'Hızlı sorular' : 'Örnek sorular', p),
        for (final q in starters)
          _suggestionRow(Icons.north_east_rounded, q, p),
      ],
    );
  }

  Widget _buildWordContext(WordModel word, _Palette p) {
    final meaning =
        (word.sadeAnlam?.isNotEmpty == true
                ? word.sadeAnlam!
                : (word.anlam ?? ''))
            .trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _head(word),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: ArabicTextStyles.word.copyWith(
              fontSize: 26,
              height: 1.4,
              color: p.text,
            ),
          ),
          if (meaning.isNotEmpty)
            Text(
              meaning,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: p.sub,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Bu kelime hakkında kısa ve net cevap alırsın.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _Palette.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(_Palette p) {
    return Row(
      children: [
        _aiBadge(40, 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arapça sorunu yaz',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Kısa ve net cevap verir, bilmediğini uydurmaz.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: p.sub,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label, _Palette p) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: p.sub,
        ),
      ),
    );
  }

  Widget _suggestionRow(IconData icon, String question, _Palette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _submit(question),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _Palette.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: p.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bir cevaptan sonra tek dokunuşla sorulabilecek devam soruları.
  Widget _buildFollowUps(_Palette p) {
    final messages = _service.messages;
    if (messages.isEmpty ||
        messages.last.isUser ||
        _service.isSending ||
        _service.error != null) {
      return const SizedBox.shrink();
    }
    final word = _service.contextWord;
    final followUps = <String>[
      'Örnek ver',
      'Daha basit anlat',
      'Derinleş',
      if (word?.fiilCekimler?.isNotEmpty == true) 'Çekimini göster',
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
        itemCount: followUps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final q = followUps[i];
          return ActionChip(
            label: Text(
              q,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _Palette.blue,
              ),
            ),
            onPressed: () => _submit(q),
            backgroundColor: _Palette.blue.withValues(
              alpha: p.dark ? 0.16 : 0.08,
            ),
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildComposer(_Palette p) {
    final pillBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide.none,
    );
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        10,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: p.bg,
        border: Border(top: BorderSide(color: p.line)),
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
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: p.text,
              ),
              decoration: InputDecoration(
                hintText: 'AI Asistan\'a sor...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: p.sub,
                ),
                isDense: true,
                filled: true,
                fillColor: p.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                // Temadaki çerçeveyi ezmek için üçü de ayrı verilir.
                border: pillBorder,
                enabledBorder: pillBorder,
                focusedBorder: pillBorder,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final canSend =
                  value.text.trim().isNotEmpty && !_service.isSending;
              return IconButton.filled(
                onPressed: canSend ? () => _submit() : null,
                icon: _service.isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: _Palette.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: p.dark
                      ? const Color(0xFF3A3A3C)
                      : const Color(0xFFD1D1D6),
                  disabledForegroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Üç noktalı "yazıyor" göstergesi.
class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Her nokta sırayla belirginleşir.
            final phase = (_anim.value * 3 - i) % 3;
            final opacity = phase < 1 ? 1.0 - phase * 0.6 : 0.35;
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: Opacity(
                opacity: opacity.clamp(0.35, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
