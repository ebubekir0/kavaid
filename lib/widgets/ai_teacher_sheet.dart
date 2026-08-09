import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ai_teacher_model.dart';
import '../models/word_model.dart';
import '../screens/subscription_screen.dart';
import '../services/ai_teacher_service.dart';

enum AiTeacherInitialMode { overview, moreExamples }

class AiTeacherSheet extends StatefulWidget {
  final WordModel word;
  final bool isDarkMode;
  final AiTeacherInitialMode initialMode;

  const AiTeacherSheet({
    super.key,
    required this.word,
    required this.isDarkMode,
    this.initialMode = AiTeacherInitialMode.overview,
  });

  @override
  State<AiTeacherSheet> createState() => _AiTeacherSheetState();
}

class _AiTeacherSheetState extends State<AiTeacherSheet> {
  final AiTeacherService _service = AiTeacherService();
  final TextEditingController _questionController = TextEditingController();
  final List<_TeacherMessage> _messages = [];

  AiTeacherResult? _result;
  bool _isLoading = true;
  bool _isAsking = false;
  bool _didRunInitialPrompt = false;
  int _remaining = AiTeacherService.freeDailyLimit;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getExplanation(widget.word);
    final remaining = await _service.remainingFreeUses();
    if (!mounted) return;
    setState(() {
      _remaining = remaining;
      _result = result;
      _isLoading = false;
    });
    if (result.isSuccess &&
        widget.initialMode == AiTeacherInitialMode.moreExamples &&
        !_didRunInitialPrompt) {
      _didRunInitialPrompt = true;
      await _sendQuestion(
        'Bu kelimeyle seviye seviye daha fazla örnek ver: kolay, orta, günlük kullanım, gramer odaklı ve soru cümlesi.',
      );
    }
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isAsking) return;
    _questionController.clear();
    await _sendQuestion(question);
  }

  Future<void> _sendQuestion(String question) async {
    if (question.trim().isEmpty || _isAsking) return;

    setState(() {
      _isAsking = true;
      _messages.add(_TeacherMessage(text: question.trim(), isUser: true));
    });

    try {
      final answer = await _service.answerQuestion(
        widget.word,
        question.trim(),
        previousContext: _result?.explanation,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_TeacherMessage(text: answer, isUser: false));
      });
      final remaining = await _service.remainingFreeUses();
      if (!mounted) return;
      setState(() {
        _remaining = remaining;
      });
    } on AiTeacherLimitException {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _TeacherMessage(
            text:
                'Bugünkü ücretsiz AI Kelime Asistanı hakkın doldu. Devam etmek için premiuma geçebilirsin.',
            isUser: false,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _TeacherMessage(
            text:
                'Şu anda cevap alınamadı. İnternet bağlantını kontrol edip tekrar deneyebilirsin.',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _isAsking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final text = widget.isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final subText = widget.isDarkMode
        ? const Color(0xFFB0B0B5)
        : const Color(0xFF6D6D70);

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
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
                  color: widget.isDarkMode
                      ? const Color(0xFF48484A)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0x1F007AFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.word.harekeliKelime?.isNotEmpty == true
                                ? widget.word.harekeliKelime!
                                : widget.word.kelime,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'ScheherazadeNew',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ).copyWith(color: text),
                          ),
                          Text(
                            _service.isPremium
                                ? 'AI Kelime Asistanı'
                                : 'AI Kelime Asistanı · $_remaining ücretsiz hak',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: subText),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildBody(scrollController, text, subText),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    ScrollController scrollController,
    Color text,
    Color subText,
  ) {
    final result = _result;
    if (result == null) {
      return _StatusView(
        message: 'AI Kelime Asistanı hazırlanamadı.',
        actionText: 'Tekrar dene',
        onAction: _load,
        isDarkMode: widget.isDarkMode,
      );
    }

    if (!result.isSuccess || result.explanation == null) {
      return _StatusView(
        message: result.message,
        actionText: result.status == AiTeacherAccessStatus.limitReached
            ? 'Premium’a geç'
            : 'Tekrar dene',
        onAction: result.status == AiTeacherAccessStatus.limitReached
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              }
            : _load,
        isDarkMode: widget.isDarkMode,
      );
    }

    final explanation = result.explanation!;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        _Section(
          title: 'Kısaca Anlat',
          isDarkMode: widget.isDarkMode,
          child: Text(explanation.summary, style: _bodyStyle(text)),
        ),
        _NotesSection(
          title: 'Gramer Notları',
          notes: explanation.grammarNotes,
          isDarkMode: widget.isDarkMode,
        ),
        _NotesSection(
          title: 'Kullanım Notları',
          notes: explanation.usageNotes,
          isDarkMode: widget.isDarkMode,
        ),
        _ExamplesSection(
          examples: explanation.examples,
          isDarkMode: widget.isDarkMode,
        ),
        _QuizSection(quiz: explanation.quiz, isDarkMode: widget.isDarkMode),
        if (explanation.confidenceNote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Text(
              explanation.confidenceNote,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: subText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        _SuggestedQuestionsSection(
          questions: _suggestedQuestions(explanation),
          isDarkMode: widget.isDarkMode,
          isDisabled: _isAsking,
          onSelected: _sendQuestion,
        ),
        _QuestionBox(
          controller: _questionController,
          messages: _messages,
          isAsking: _isAsking,
          isDarkMode: widget.isDarkMode,
          onSend: _askQuestion,
        ),
      ],
    );
  }

  TextStyle _bodyStyle(Color color) {
    return GoogleFonts.inter(
      fontSize: 13.5,
      height: 1.45,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  List<String> _suggestedQuestions(AiTeacherExplanation explanation) {
    final defaults = <String>[
      'Bu kelime nerede kullanılır?',
      'Benzer kelimelerden farkı ne?',
      '5 yeni örnek ver',
      'Kolay cümlelerle anlat',
    ];
    if (widget.word.fiilCekimler?.isNotEmpty == true) {
      defaults.add('Çekimle örnek ver');
    }
    if (widget.word.harfiCerler.isNotEmpty) {
      defaults.add('Harf-i cer farkını anlat');
    }

    return [...explanation.suggestedQuestions, ...defaults]
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(6)
        .toList();
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDarkMode;

  const _Section({
    required this.title,
    required this.child,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF48484A) : const Color(0xFFE1E4E8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final String title;
  final List<String> notes;
  final bool isDarkMode;

  const _NotesSection({
    required this.title,
    required this.notes,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final color = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    return _Section(
      title: title,
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notes
            .map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $note',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.35,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ExamplesSection extends StatelessWidget {
  final List<AiTeacherExample> examples;
  final bool isDarkMode;

  const _ExamplesSection({required this.examples, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) return const SizedBox.shrink();
    final color = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final subColor = isDarkMode
        ? const Color(0xFFB0B0B5)
        : const Color(0xFF6D6D70);
    return _Section(
      title: 'Örnekle Öğren',
      isDarkMode: isDarkMode,
      child: Column(
        children: examples
            .map(
              (example) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      example.arabic,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      example.turkish,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: subColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuizSection extends StatelessWidget {
  final List<AiTeacherQuizItem> quiz;
  final bool isDarkMode;

  const _QuizSection({required this.quiz, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    if (quiz.isEmpty) return const SizedBox.shrink();
    final color = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    return _Section(
      title: 'Mini Alıştırma',
      isDarkMode: isDarkMode,
      child: Column(
        children: quiz.take(3).map((item) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.question,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.options.take(3).map((option) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: option == item.answer
                            ? const Color(0x1F007AFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: option == item.answer
                              ? const Color(0xFF007AFF)
                              : (isDarkMode
                                    ? const Color(0xFF48484A)
                                    : const Color(0xFFD1D1D6)),
                        ),
                      ),
                      child: Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: option == item.answer
                              ? const Color(0xFF007AFF)
                              : color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (item.explanation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.explanation,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDarkMode
                          ? const Color(0xFFB0B0B5)
                          : const Color(0xFF6D6D70),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SuggestedQuestionsSection extends StatelessWidget {
  final List<String> questions;
  final bool isDarkMode;
  final bool isDisabled;
  final ValueChanged<String> onSelected;

  const _SuggestedQuestionsSection({
    required this.questions,
    required this.isDarkMode,
    required this.isDisabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    return _Section(
      title: 'Hazır Sorular',
      isDarkMode: isDarkMode,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: questions.map((question) {
          return ActionChip(
            avatar: const Icon(Icons.auto_awesome_rounded, size: 15),
            label: Text(
              question,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            onPressed: isDisabled ? null : () => onSelected(question),
            backgroundColor: isDarkMode
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
            side: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF48484A)
                  : const Color(0xFFD1D1D6),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuestionBox extends StatelessWidget {
  final TextEditingController controller;
  final List<_TeacherMessage> messages;
  final bool isAsking;
  final bool isDarkMode;
  final VoidCallback onSend;

  const _QuestionBox({
    required this.controller,
    required this.messages,
    required this.isAsking,
    required this.isDarkMode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    return _Section(
      title: 'Sor',
      isDarkMode: isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...messages.map((message) {
            return Align(
              alignment: message.isUser
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? const Color(0xFF007AFF)
                      : (isDarkMode ? const Color(0xFF1C1C1E) : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.text,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: message.isUser ? Colors.white : text,
                    height: 1.35,
                  ),
                ),
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    hintText: 'Bu kelimeyle ilgili soru sor',
                    hintStyle: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF8E8E93),
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: isAsking ? null : onSend,
                icon: isAsking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final String message;
  final String actionText;
  final VoidCallback onAction;
  final bool isDarkMode;

  const _StatusView({
    required this.message,
    required this.actionText,
    required this.onAction,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 42,
              color: isDarkMode
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF007AFF),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}

class _TeacherMessage {
  final String text;
  final bool isUser;

  const _TeacherMessage({required this.text, required this.isUser});
}
