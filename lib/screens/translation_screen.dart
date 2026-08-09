import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/dialect_language.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/translation_notifier.dart';
import '../services/dialect_translation_service.dart';
import '../services/translation_quota_service.dart';
import 'subscription_screen.dart';

class TranslationScreen extends StatefulWidget {
  final bool isDarkMode;
  final double bottomPadding;
  final bool isEmbedded;

  const TranslationScreen({
    super.key,
    required this.isDarkMode,
    this.bottomPadding = 0,
    this.isEmbedded = false,
  });

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // STT
  final SpeechToText _stt = SpeechToText();
  bool _sttEnabled = false;
  bool _isListening = false;
  bool _isGateBusy = false;
  double _lastKeyboardHeight = 0;

  String _lastTranslatedText = '';
  bool? _lastDirection;
  String? _lastSourceCode;
  String? _lastTargetCode;
  final TranslationQuotaService _quotaService = TranslationQuotaService();

  @override
  void initState() {
    super.initState();
    _quotaService.refresh();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isDark => widget.isDarkMode;

  // ── Renkler ─────────────────────────────────────────────
  Color get _bgColor => _isDark ? const Color(0xFF1C1C1E) : Colors.white;
  Color get _surfaceColor =>
      _isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F3F4);
  Color get _accentColor => const Color(0xFF1A73E8);
  Color get _textPrimary =>
      _isDark ? const Color(0xFFE5E5EA) : const Color(0xFF202124);
  Color get _textSecondary =>
      _isDark ? const Color(0xFF8E8E93) : const Color(0xFF5F6368);
  Color get _dividerColor =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8EAED);
  Color get _outputColor =>
      _isDark ? const Color(0xFF5EA1FF) : const Color(0xFF0B3D91);
  Color get _iconBg =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8F0FE);

  // ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TranslationNotifier(),
      child: Consumer<TranslationNotifier>(
        builder: (context, notifier, _) {
          // Sync text controller
          if (_textController.text != notifier.inputText &&
              !_focusNode.hasFocus) {
            _textController.text = notifier.inputText;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          }

          final bool hasContent =
              notifier.inputText.isNotEmpty || notifier.hasOutput;
          final bool isSignedIn = AuthService().isSignedIn;
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final isKeyboardVisible = keyboardHeight > 0;
          if (keyboardHeight > 0 &&
              (keyboardHeight - _lastKeyboardHeight).abs() > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _lastKeyboardHeight = keyboardHeight);
            });
          } else if (keyboardHeight == 0 && _lastKeyboardHeight != 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _lastKeyboardHeight = 0);
            });
          }
          const micAreaHeight = 132.0;

          Widget content = Stack(
            children: [
              // ── 1. Mikrofon Alanı (sabit altta) ──────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: micAreaHeight + widget.bottomPadding,
                child: _buildMicArea(notifier),
              ),

              // ── 2. Dil Seçim Barı ─────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: micAreaHeight + widget.bottomPadding,
                child: _buildLanguageBar(notifier),
              ),

              // ── 3. Ana İçerik ─────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: isKeyboardVisible
                    ? keyboardHeight
                    : micAreaHeight + widget.bottomPadding + 68,
                child: Column(
                  children: [
                    if (!widget.isEmbedded) _buildTopBar(notifier, hasContent),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_focusNode.hasFocus) {
                            FocusScope.of(context).requestFocus(_focusNode);
                          }
                        },
                        behavior: HitTestBehavior.translucent,
                        child: _buildContent(notifier),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 4. Çevir Butonu (yüzen) ───────────────────────
              if (hasContent)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _translateButtonBottom(
                    isKeyboardVisible,
                    keyboardHeight,
                    micAreaHeight,
                    widget.bottomPadding,
                  ),
                  child: _buildTranslateButton(notifier),
                ),
              if (!isSignedIn)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showLoginRequiredSnack,
                  ),
                ),
            ],
          );

          if (widget.isEmbedded) {
            return content;
          }

          return GestureDetector(
            onTap: () {
              if (_isListening) _stopListening(notifier);
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.translucent,
            child: Scaffold(
              backgroundColor: _bgColor,
              resizeToAvoidBottomInset: false,
              body: SafeArea(bottom: false, child: content),
            ),
          );
        },
      ),
    );
  }

  double _translateButtonBottom(
    bool isKeyboardVisible,
    double keyboardHeight,
    double micAreaHeight,
    double bottomPadding,
  ) {
    if (isKeyboardVisible) {
      final stableKeyboardHeight = keyboardHeight > _lastKeyboardHeight
          ? keyboardHeight
          : _lastKeyboardHeight;
      return stableKeyboardHeight + 8;
    }
    return micAreaHeight + bottomPadding + 68 + 16;
  }

  // ── Top Bar ──────────────────────────────────────────────
  Widget _buildTopBar(TranslationNotifier notifier, bool hasContent) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: hasContent
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: _textSecondary),
                    onPressed: () {
                      _textController.clear();
                      notifier.clearAll();
                      _focusNode.unfocus();
                    },
                  )
                : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Çeviri',
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: hasContent
                ? IconButton(
                    icon: Icon(Icons.close, color: _textSecondary),
                    onPressed: () {
                      _textController.clear();
                      notifier.clearAll();
                    },
                  )
                : null,
          ),
        ],
      ),
    );
  }

  // ── Dil Barı ─────────────────────────────────────────────
  Widget _buildLanguageBar(TranslationNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildLangButton(
                notifier.leftLang,
                (l) => notifier.setLeftLanguage(l),
                isSource: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () {
                  notifier.toggleDirection();
                  _textController.text = notifier.inputText;
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Icon(
                    notifier.isLeftToRight
                        ? Icons.arrow_forward
                        : Icons.arrow_back,
                    key: ValueKey(notifier.isLeftToRight),
                    color: _accentColor,
                    size: 24,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildLangButton(
                notifier.rightLang,
                (l) => notifier.setRightLanguage(l),
                isSource: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangButton(
    DialectLanguage lang,
    Function(DialectLanguage) onSel, {
    required bool isSource,
  }) {
    return Material(
      color: _isDark ? const Color(0xFF3A3A3C) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _pickLanguage(lang, onSel, isSource: isSource),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  lang.name,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                    letterSpacing: 0,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mikrofon Alanı ───────────────────────────────────────
  Widget _buildMicArea(TranslationNotifier notifier) {
    return Container(
      color: _surfaceColor,
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(bottom: 16 + widget.bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _toggleListening(notifier),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _isListening
                    ? const Color(0xFFD93025)
                    : _isDark
                    ? const Color(0xFF1D3461)
                    : const Color(0xFFD2E3FC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic_none,
                color: _isListening
                    ? Colors.white
                    : _isDark
                    ? const Color(0xFF5EA1FF)
                    : const Color(0xFF174EA6),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Ana İçerik ────────────────────────────────────────────
  Widget _buildContent(TranslationNotifier notifier) {
    final bool isArabicSource =
        notifier.sourceLanguage.type == DialectLanguageType.arabic;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Input ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  maxLength: DialectTranslationService.maxInputLength,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      DialectTranslationService.maxInputLength,
                    ),
                  ],
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  textDirection: isArabicSource
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  textAlign: isArabicSource ? TextAlign.right : TextAlign.left,
                  style: isArabicSource
                      ? GoogleFonts.notoNaskhArabic(
                          fontSize: _calcFontSizeArabic(_textController.text),
                          fontWeight: FontWeight.w400,
                          color: _textPrimary,
                          height: 1.8,
                          letterSpacing: 0,
                        )
                      : GoogleFonts.roboto(
                          fontSize: _calcFontSize(_textController.text),
                          fontWeight: FontWeight.w400,
                          color: _textPrimary,
                          letterSpacing: 0,
                        ),
                  decoration: InputDecoration(
                    hintText: isArabicSource ? 'أدخل النص' : 'Metin girin',
                    hintStyle: isArabicSource
                        ? GoogleFonts.notoNaskhArabic(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: _textSecondary,
                            letterSpacing: 0,
                          )
                        : GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: _textSecondary,
                            letterSpacing: 0,
                          ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    notifier.updateInputText(val);
                  },
                  onTap: () {
                    if (_isListening) _stopListening(notifier);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 1,
              color: _dividerColor,
            ),
            const SizedBox(height: 8),

            // ── Output ───────────────────────────────────────
            if (!notifier.isLoading && notifier.hasOutput)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Çeviri metni
                    _buildOutputText(notifier),

                    // Transliterasyon (okunuş)
                    if (notifier.targetLanguage.type ==
                            DialectLanguageType.arabic &&
                        notifier.transliteration.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        notifier.transliteration,
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: _textSecondary,
                          height: 1.4,
                          letterSpacing: 0,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Aksiyon butonları
                    _buildActionButtons(notifier),
                  ],
                ),
              ),

            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputText(TranslationNotifier notifier) {
    final isArabicTarget =
        notifier.targetLanguage.type == DialectLanguageType.arabic;
    final text = notifier.outputText;

    final textStyle = isArabicTarget
        ? GoogleFonts.notoNaskhArabic(
            fontSize: _calcFontSizeArabic(text),
            fontWeight: FontWeight.w400,
            color: _outputColor,
            height: 1.8,
            letterSpacing: 0,
          )
        : GoogleFonts.roboto(
            fontSize: _calcFontSize(text),
            fontWeight: FontWeight.w400,
            color: _outputColor,
            height: 1.5,
            letterSpacing: 0,
          );

    return Text(
      text,
      style: textStyle,
      textDirection: isArabicTarget ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isArabicTarget ? TextAlign.right : TextAlign.left,
    );
  }

  Widget _buildActionButtons(TranslationNotifier notifier) {
    final isArabicTarget =
        notifier.targetLanguage.type == DialectLanguageType.arabic;

    return Row(
      children: [
        // Hareke butonu (sadece Arapça hedef)
        if (isArabicTarget) ...[
          _buildCircleBtn(
            icon: notifier.showDiacritics
                ? Icons.text_fields
                : Icons.text_format,
            tooltip: notifier.showDiacritics ? 'Hareke kapat' : 'Hareke aç',
            onTap: notifier.toggleDiacritics,
          ),
          const SizedBox(width: 8),
        ],

        // Kopyala
        _buildCircleBtn(
          icon: Icons.content_copy_rounded,
          tooltip: 'Kopyala',
          onTap: () {
            Clipboard.setData(ClipboardData(text: notifier.outputText));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Kopyalandı'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                backgroundColor: _isDark
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFF2C2C2E),
              ),
            );
          },
        ),
        const SizedBox(width: 8),

        // Seslendir
        _buildCircleBtn(
          icon: notifier.isSpeaking
              ? Icons.stop_rounded
              : Icons.volume_up_rounded,
          tooltip: notifier.isSpeaking ? 'Durdur' : 'Seslendir',
          active: notifier.isSpeaking,
          onTap: notifier.speakTarget,
        ),
      ],
    );
  }

  Widget _buildCircleBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? _accentColor.withValues(alpha: 0.15) : _iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _accentColor, size: 20),
        ),
      ),
    );
  }

  // ── Çevir Butonu ─────────────────────────────────────────
  Widget _buildTranslateButton(TranslationNotifier notifier) {
    final directionChanged =
        _lastDirection != null && _lastDirection != notifier.isLeftToRight;
    final languageChanged =
        (_lastSourceCode != null &&
            _lastSourceCode != notifier.sourceLanguage.code) ||
        (_lastTargetCode != null &&
            _lastTargetCode != notifier.targetLanguage.code);
    final bool needsTranslation =
        notifier.inputText.isNotEmpty &&
        (notifier.inputText != _lastTranslatedText ||
            directionChanged ||
            languageChanged);

    if (!needsTranslation && !notifier.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: notifier.isLoading || _isGateBusy
            ? null
            : () => _requestTranslate(notifier),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          disabledBackgroundColor: _accentColor,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 42),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 4,
        ),
        child: notifier.isLoading || _isGateBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Çevir',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }

  // ── Dil Seçici ───────────────────────────────────────────
  void _pickLanguage(
    DialectLanguage current,
    Function(DialectLanguage) onSel, {
    required bool isSource,
  }) {
    final langs = DialectLanguage.supportedLanguages.where((l) {
      if (isSource) return DialectLanguage.isAllowedSource(l);
      return l.type == DialectLanguageType.arabic;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LanguagePickerSheet(
        languages: langs,
        current: current,
        isDark: _isDark,
        onSelected: (l) {
          onSel(l);
          FocusScope.of(context).unfocus();
        },
        title: isSource ? 'Şu Dilden Çevir' : 'Şu Dile Çevir',
        isSource: isSource,
      ),
    );
  }

  // ── STT ──────────────────────────────────────────────────
  Future<void> _toggleListening(TranslationNotifier notifier) async {
    if (_isListening) {
      await _stopListening(notifier);
      return;
    }
    if (!_sttEnabled) {
      _sttEnabled = await _stt.initialize(
        onError: (e) => debugPrint('STT error: $e'),
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    }
    if (!_sttEnabled) return;

    setState(() => _isListening = true);
    notifier.updateInputText('');
    _textController.clear();

    await _stt.listen(
      localeId: notifier.sourceLanguage.sttCode,
      onResult: (result) {
        if (mounted) {
          _textController.text = result.recognizedWords;
          notifier.updateInputText(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<void> _stopListening(TranslationNotifier notifier) async {
    await _stt.stop();
    if (mounted) setState(() => _isListening = false);
    if (notifier.inputText.isNotEmpty) {
      await _requestTranslate(notifier);
    }
  }

  Future<void> _requestTranslate(TranslationNotifier notifier) async {
    if (notifier.inputText.trim().isEmpty ||
        notifier.isLoading ||
        _isGateBusy) {
      return;
    }
    if (!AuthService().isSignedIn) {
      _showLoginRequiredSnack();
      return;
    }

    setState(() => _isGateBusy = true);
    final access = await _quotaService.reserveTranslation();
    if (!mounted) return;
    setState(() => _isGateBusy = false);

    if (!access.isAllowed) {
      _handleAccessDenied(access);
      return;
    }

    _lastTranslatedText = notifier.inputText;
    _lastDirection = notifier.isLeftToRight;
    _lastSourceCode = notifier.sourceLanguage.code;
    _lastTargetCode = notifier.targetLanguage.code;
    await notifier.translate();
    await _quotaService.refresh();
  }

  void _handleAccessDenied(TranslationAccessResult access) {
    switch (access.status) {
      case TranslationAccessStatus.loginRequired:
        _showLoginRequiredSnack();
        break;
      case TranslationAccessStatus.limitReached:
        _showPremiumPrompt();
        break;
      case TranslationAccessStatus.unavailable:
        _showSnack(access.message);
        break;
      case TranslationAccessStatus.allowed:
        break;
    }
  }

  void _showPremiumPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: _accentColor),
                const SizedBox(width: 10),
                Text(
                  "Premium'a geçin",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Daha fazla çeviri yapabilmek için Premium'a geçin.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen(),
                        ),
                      )
                      .then((_) => _quotaService.refresh());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "Premium'a Geç",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isDark
            ? const Color(0xFF3A3A3C)
            : const Color(0xFF2C2C2E),
      ),
    );
  }

  void _showLoginRequiredSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LanguageService().isEnglish
              ? 'Please log in or sign up first'
              : 'Lütfen önce kayıt olup giriş yapın.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: _isDark
            ? const Color(0xFF3A3A3C)
            : const Color(0xFF2C2C2E),
      ),
    );
  }

  // ── Yardımcı ─────────────────────────────────────────────
  double _calcFontSize(String text) {
    if (text.length < 50) return 24;
    if (text.length < 100) return 20;
    return 18;
  }

  double _calcFontSizeArabic(String text) {
    if (text.length < 30) return 28;
    if (text.length < 60) return 26;
    if (text.length < 100) return 24;
    return 22;
  }
}

// ── Dil Seçici Bottom Sheet ───────────────────────────────
class _LanguagePickerSheet extends StatelessWidget {
  final List<DialectLanguage> languages;
  final DialectLanguage current;
  final bool isDark;
  final Function(DialectLanguage) onSelected;
  final String title;
  final bool isSource;

  const _LanguagePickerSheet({
    required this.languages,
    required this.current,
    required this.isDark,
    required this.onSelected,
    required this.title,
    required this.isSource,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFE5E5EA)
        : const Color(0xFF202124);
    const accent = Color(0xFF1A73E8);
    final standardLanguages = languages
        .where(
          (l) =>
              l.type == DialectLanguageType.standard || l.code == 'ar_standard',
        )
        .toList();
    final arabicLanguages = languages
        .where(
          (l) =>
              l.type == DialectLanguageType.arabic && l.code != 'ar_standard',
        )
        .toList();
    final targetArabicLanguages = languages
        .where((l) => l.type == DialectLanguageType.arabic)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A3C) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  letterSpacing: 0,
                ),
              ),
            ),
            Expanded(
              child: isSource
                  ? DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: accent,
                            unselectedLabelColor: isDark
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF5F6368),
                            indicatorColor: accent,
                            labelStyle: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                            unselectedLabelStyle: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                            ),
                            tabs: const [
                              Tab(text: 'Diller'),
                              Tab(text: 'Lehçeler'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildLanguageList(
                                  standardLanguages,
                                  controller,
                                  textColor,
                                  accent,
                                ),
                                _buildLanguageList(
                                  arabicLanguages,
                                  controller,
                                  textColor,
                                  accent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildLanguageList(
                      targetArabicLanguages,
                      controller,
                      textColor,
                      accent,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageList(
    List<DialectLanguage> list,
    ScrollController _,
    Color textColor,
    Color accent,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEEEEEE),
      ),
      itemBuilder: (context, i) {
        final l = list[i];
        final isSelected = l.code == current.code;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text(l.flagEmoji, style: const TextStyle(fontSize: 24)),
          title: Text(
            l.name,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? accent : textColor,
              letterSpacing: 0,
            ),
          ),
          subtitle: Text(
            l.nativeName,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF5F6368),
              letterSpacing: 0,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: Color(0xFF1A73E8))
              : null,
          onTap: () {
            onSelected(l);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
