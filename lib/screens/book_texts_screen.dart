import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle, SystemUiOverlayStyle;
import 'package:flutter/foundation.dart' show kReleaseMode;
import '../services/one_time_purchase_service.dart';
import '../services/book_store_service.dart';
import '../services/book_purchase_service.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../services/book_lessons_service.dart';
import '../models/word_model.dart';
import '../services/tts_service.dart';
import '../widgets/search_result_card.dart';
import 'profile_screen.dart';

class BookTextsScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final bool isDarkMode;
  final bool preview; // önizleme modu: tüm dersler kilitli

  const BookTextsScreen({super.key, required this.bookId, required this.bookTitle, required this.isDarkMode, this.preview = false});

  @override
  State<BookTextsScreen> createState() => _BookTextsScreenState();
}

class _BookTextsScreenState extends State<BookTextsScreen> {
  String? _loadingTextId;
  final BookLessonsService _lessons = BookLessonsService();
  final AuthService _auth = AuthService();
  final BookStoreService _bookStore = BookStoreService();
  Future<List<BookTextInfo>>? _indexFuture;
  // Extract Arabic part as the text inside the LAST parentheses pair
  String _extractArabic(String title) {
    final start = title.lastIndexOf('(');
    final end = title.lastIndexOf(')');
    if (start != -1 && end != -1 && end > start) {
      return title.substring(start + 1, end).trim();
    }
    return '';
  }

  // Remove Arabic diacritics (tashkeel) and tatweel
  String _stripHarakat(String s) {
    // \u064B-\u0652: tashkeel, \u0670: small alef, \u0640: tatweel
    return s.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');
  }

  String _extractTurkish(String title) {
    // Keep everything before the LAST '(' so Turkish can contain its own parentheses
    final start = title.lastIndexOf('(');
    if (start != -1) {
      return title.substring(0, start).trim();
    }
    return title.trim();
  }

  String _cleanTurkish(String turkish) {
    final reg = RegExp(r'^Ders\s*\d+\s*[—\-]?\s*', caseSensitive: false);
    return turkish.replaceFirst(reg, '').trim();
  }

  // Remove any parenthetical phrases from a string, e.g., "Zühurat... (Bitki Çayları...)" -> "Zühurat..."
  String _stripParentheses(String s) {
    return s.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  // Remove dots/ellipsis characters from a string
  String _stripDots(String s) {
    return s.replaceAll(RegExp(r'[.…]+'), '').trim();
  }

  // Strip trailing 'kelimeleri' (case-insensitive) from a title
  String _stripKelimeleriSuffix(String s) {
    return s.replaceFirst(RegExp(r'\s*kelimeleri\s*$', caseSensitive: false), '').trim();
  }

  @override
  void initState() {
    super.initState();
    _bookStore.initialize().then((_) {
      if (mounted) setState(() {});
    });
    _bookStore.addListener(_onStoreChanged);
    _indexFuture = _lessons.loadTextIndex(bookId: widget.bookId);
  }

  Future<void> _navigateToTextWords(BookTextInfo textInfo) async {
    if (_loadingTextId != null) return; // Prevent multiple taps

    setState(() {
      _loadingTextId = textInfo.id;
    });

    try {
      final words = await _lessons.loadTextWords(bookId: widget.bookId, textId: textInfo.id);
      if (!mounted) return;

      // Using await ensures we only clear loading state after returning
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TextWordsScreen(
          bookId: widget.bookId,
          textId: textInfo.id,
          title: textInfo.title,
          isDarkMode: widget.isDarkMode,
          preloadedWords: words,
        ),
      ));
    } finally {
      if (mounted) {
        setState(() {
          _loadingTextId = null;
        });
      }
    }
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final purchased = _bookStore.isPurchased(widget.bookId);
    final bool isPreview = widget.preview;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF007AFF),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: Text(
          _stripKelimeleriSuffix(widget.bookTitle),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF007AFF),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      body: FutureBuilder<List<BookTextInfo>>(
        future: _indexFuture ??= _lessons.loadTextIndex(bookId: widget.bookId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<BookTextInfo> items = (snapshot.hasData && (snapshot.data ?? []).isNotEmpty)
              ? (snapshot.data ?? <BookTextInfo>[])
              : List.generate(25, (i) => BookTextInfo(id: 'lesson_${i + 1}', title: 'Ders ${i + 1}'));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: items.length,
            itemBuilder: (c, i) {
              final t = items[i];
              final turkish = _extractTurkish(t.title);
              final arabicRaw = _extractArabic(t.title);
              final arabic = _stripHarakat(arabicRaw.isNotEmpty ? arabicRaw : t.title);

              return Container(
                constraints: const BoxConstraints(minHeight: 88),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Satın alınmışsa tüm dersler açık
                      if (purchased) {
                        _navigateToTextWords(t);
                        return;
                      }
                      
                      // Satın alınmamışsa ilk 3 ders önizleme için açık (giriş gerekmez)
                      if (i < 3) {
                        _navigateToTextWords(t);
                        return;
                      }
                      
                      // 3. dersten sonrası için giriş ve satın alma gerekli
                      if (!_auth.isSignedIn) {
                        _showLoginRequiredDialog(context, isDarkMode);
                        return;
                      }
                      _showPurchaseDialog(context, isDarkMode);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _stripDots(arabic),
                                  style: GoogleFonts.scheherazadeNew(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                                    height: 1.3,
                                    fontFeatures: const [
                                      ui.FontFeature.enable('liga'),
                                      ui.FontFeature.enable('calt'),
                                    ],
                                  ),
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _stripDots(_stripParentheses(_cleanTurkish(turkish))),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkMode
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF6D6D70),
                                    height: 1.2,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              gradient: (purchased || i < 3)
                                  ? const LinearGradient(
                                      colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: (purchased || i < 3)
                                  ? null
                                  : (isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA)),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: (purchased || i < 3) ? [
                                BoxShadow(
                                  color: const Color(0xFF007AFF).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                              ] : [],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                onTap: () {
                                  // Satın alınmışsa tüm dersler açık
                                  if (purchased) {
                                    _navigateToTextWords(t);
                                    return;
                                  }
                                  
                                  // Satın alınmamışsa ilk 3 ders önizleme için açık (giriş gerekmez)
                                  if (i < 3) {
                                    _navigateToTextWords(t);
                                    return;
                                  }
                                  
                                  // 3. dersten sonrası için giriş ve satın alma gerekli
                                  if (!_auth.isSignedIn) {
                                    _showLoginRequiredDialog(context, isDarkMode);
                                    return;
                                  }
                                  _showPurchaseDialog(context, isDarkMode);
                                },
                                borderRadius: BorderRadius.circular(18),
                                splashColor: Colors.white.withOpacity(0.3),
                                highlightColor: Colors.white.withOpacity(0.1),
                                child: Center(
                                  child: (_loadingTextId == t.id)
                                          ? const SizedBox(
                                              width: 16, height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                                            )
                                          : (purchased || i < 3)
                                              ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Aç',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Icon(
                                              Icons.lock_outline,
                                              color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                                              size: 16,
                                            ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context, bool isDarkMode) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Lütfen önce kayıt olup giriş yapın.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, bool isDarkMode) {
    final auth = AuthService();
    final bookPurchase = BookPurchaseService();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          String priceText = 'Yüklüyor...';

          // Play Console'dan dinamik fiyat: tüm kitaplar için BookPurchaseService
          bookPurchase.loadProductFor(widget.bookId).then((_) {
            if (mounted) {
              setDialogState(() {
                priceText = bookPurchase.currentBookPrice;
              });
            }
          });
          priceText = bookPurchase.currentBookPrice;

          return AlertDialog(
            backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Satın Al',
              style: TextStyle(
                color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.bookId == 'kitab_kiraah_1' ? 'Kitabul Kıraat 1' : widget.bookId == 'kitab_kiraah_2' ? 'Kitabul Kıraat 2' : 'Kitabul Kıraat 3'} kelimelerine ömür boyu erişmek için ürünü satın al.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Not: Ürün hesabınıza tanımlanır.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('İptal'),
              ),
              if (!kReleaseMode)
                TextButton(
                  onPressed: () async {
                    if (!auth.isSignedIn) {
                      Navigator.of(ctx).pop();
                      _showLoginRequiredDialog(context, isDarkMode);
                      return;
                    }
                    try {
                      await BookStoreService().mockPurchase(widget.bookId);
                      if (context.mounted) Navigator.of(ctx).pop();
                      setState(() {});
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Giriş hatası: $e')),
                      );
                    }
                  },
                  child: const Text('DEBUG: Hemen Tanımla'),
                ),
              ElevatedButton(
                onPressed: () async {
                  if (!auth.isSignedIn) {
                    Navigator.of(ctx).pop();
                    _showLoginRequiredDialog(context, isDarkMode);
                    return;
                  }
                  Navigator.of(ctx).pop();
                  await bookPurchase.buyBook(widget.bookId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                ),
                child: Text(priceText),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAuthSheet(BuildContext context, bool isDarkMode) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final auth = AuthService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bCtx) {
        final viewInsets = MediaQuery.of(bCtx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giriş Yap',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hesabınız yoksa önce kayıt olun',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    validator: (v) => (v == null || v.isEmpty) ? 'E-posta gerekli' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Şifre'),
                    validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            try {
                              await auth.signInWithEmail(email: emailController.text.trim(), password: passController.text);
                              if (mounted) Navigator.of(bCtx).pop();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Giriş hatası: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF)),
                          child: const Text('Giriş Yap'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            try {
                              await auth.signUpWithEmail(email: emailController.text.trim(), password: passController.text);
                              if (mounted) Navigator.of(bCtx).pop();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Kayıt hatası: $e')),
                              );
                            }
                          },
                          child: const Text('Kayıt Ol'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login),
                      onPressed: () async {
                        try {
                          await auth.signInWithGoogle();
                          if (mounted) Navigator.of(bCtx).pop();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Google ile giriş hatası: $e')),
                          );
                        }
                      },
                      label: const Text('Google ile giriş yap'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _bookStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}

class TextWordsScreen extends StatefulWidget {
  final String bookId;
  final String textId;
  final String title;
  final bool isDarkMode;
  final List<BookWord>? preloadedWords;

  const TextWordsScreen({super.key, required this.bookId, required this.textId, required this.title, required this.isDarkMode, this.preloadedWords});

  @override
  State<TextWordsScreen> createState() => _TextWordsScreenState();
}

class _TextWordsScreenState extends State<TextWordsScreen> {
  final BookLessonsService _lessons = BookLessonsService();
  final TTSService _ttsService = TTSService();
  Future<String>? _titleFuture;
  List<WordModel> _words = [];
  bool _isLoadingWords = true;
  bool _isCardMode = false; // Varsayılan: Liste görünümü
  int _currentCardIndex = 0;
  late PageController _pageController;
  bool _showMeaning = false;

  String _extractArabic(String title) {
    final start = title.indexOf('(');
    final end = title.lastIndexOf(')');
    if (start != -1 && end != -1 && end > start) {
      return title.substring(start + 1, end).trim();
    }
    return '';
  }

  String _extractTurkish(String title) {
    final start = title.indexOf('(');
    if (start != -1) {
      return title.substring(0, start).trim();
    }
    return title;
  }

  // Remove Arabic diacritics (tashkeel) and tatweel
  String _stripHarakat(String s) {
    // \u064B-\u0652: tashkeel, \u0670: small alef, \u0640: tatweel
    return s.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');
  }

  // Remove any parenthetical phrases from a string
  String _stripParentheses(String s) {
    return s.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  // Remove dots/ellipsis characters from a string
  String _stripDots(String s) {
    return s.replaceAll(RegExp(r'[.…]+'), '').trim();
  }

  String _cleanTurkish(String turkish) {
    final reg = RegExp(r'^Ders\s*\d+\s*[—\-]?\s*', caseSensitive: false);
    return turkish.replaceFirst(reg, '').trim();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _titleFuture = _loadDisplayTitle();
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      List<BookWord> items;
      if (widget.preloadedWords != null) {
        items = widget.preloadedWords!;
      } else {
        items = await _lessons.loadTextWords(bookId: widget.bookId, textId: widget.textId);
      }
      if (mounted) {
        setState(() {
          _words = items
              .map((bw) => WordModel(kelime: bw.arabic, anlam: bw.turkish, tip: bw.type))
              .toList();
          _isLoadingWords = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWords = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    _pageController.dispose();
    super.dispose();
  }

  Future<String> _loadDisplayTitle() async {
    try {
      final String path = 'assets/books/${widget.bookId}/${widget.textId}.json';
      final String jsonStr = await rootBundle.loadString(path);
      final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;
      if (data.containsKey('ders_bilgisi')) {
        final Map<String, dynamic> ders = data['ders_bilgisi'] as Map<String, dynamic>;
        final String? dersAdi = (ders['ders_adi'] as String?);
        if (dersAdi != null && dersAdi.trim().isNotEmpty) {
          return dersAdi.trim();
        }
      }
    } catch (e) {
      // ignore and fallback
    }
    return widget.title;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF007AFF),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: FutureBuilder<String>(
          future: _titleFuture ??= _loadDisplayTitle(),
          builder: (context, snapshot) {
            final combined = snapshot.data ?? widget.title;
            final turkish = _extractTurkish(combined);
            final arabicRaw = _extractArabic(combined);
            final arabic = _stripHarakat(arabicRaw.isNotEmpty ? arabicRaw : combined);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _stripDots(arabic.isNotEmpty ? arabic : combined),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                ),
                if (_stripDots(_stripParentheses(_cleanTurkish(turkish))).isNotEmpty)
                  Text(
                    _stripDots(_stripParentheses(_cleanTurkish(turkish))),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                  ),
              ],
            );
          },
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF007AFF),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      body: _isLoadingWords
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? Center(
                  child: Text(
                    'Bu metin için kelime henüz eklenmedi.',
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildViewToggle(isDarkMode),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isCardMode
                            ? _buildFlashcardView(_words, isDarkMode)
                            : _buildListView(_words),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildViewToggle(bool isDarkMode) {
    final Color activeColor = const Color(0xFF007AFF);
    final Color bgColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final Color borderColor = isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final Color inactiveText = isDarkMode ? const Color(0xFFEBEBF5) : const Color(0xFF1C1C1E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Soldaki buton: Liste
                  if (_isCardMode) {
                    setState(() {
                      _isCardMode = false;
                      _showMeaning = false;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: !_isCardMode ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Liste',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !_isCardMode ? Colors.white : inactiveText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Sağdaki buton: Kart
                  if (!_isCardMode) {
                    _pageController.dispose();
                    _pageController = PageController(initialPage: _currentCardIndex);
                    setState(() {
                      _isCardMode = true;
                      _showMeaning = false;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: _isCardMode ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Kart',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isCardMode ? Colors.white : inactiveText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<WordModel> words) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: words.length,
        itemBuilder: (c, i) {
          return SearchResultCard(
            word: words[i],
            onTap: () {
              _ttsService.speak(words[i].kelime);
            },
            showExpandButton: false,
            enableExpand: false,
            showAddButton: false, // Kaydetme ikonu olmasın
          );
        },
      ),
    );
  }

  Widget _buildFlashcardView(List<WordModel> words, bool isDarkMode) {
    final Color cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final Color subTextColor = isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70);

    if (words.isEmpty) {
      return const SizedBox.shrink();
    }

    final int safeIndex = _currentCardIndex.clamp(0, words.length - 1);
    if (safeIndex != _currentCardIndex) {
      _currentCardIndex = safeIndex;
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification && _showMeaning) {
                  setState(() {
                    _showMeaning = false;
                  });
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: words.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentCardIndex = index;
                    _showMeaning = false;
                  });
                },
                itemBuilder: (context, index) {
                  final word = words[index];
                  final displayWord = word.harekeliKelime?.isNotEmpty == true 
                      ? word.harekeliKelime! 
                      : word.kelime;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _showMeaning = !_showMeaning;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      clipBehavior: Clip.antiAlias, // Köşelerdeki kareliği çözer
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.35)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Ses Butonu - En Üstte
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              onPressed: () {
                                _ttsService.speak(word.kelime);
                              },
                              icon: Icon(
                                Icons.volume_up_rounded,
                                color: subTextColor.withOpacity(0.7),
                                size: 28,
                              ),
                              tooltip: 'Dinle',
                            ),
                          ),

                          // Kelime/Anlam Bölümü - Tam Merkezde Sabit
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24), // Tam ortala
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 100),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: _showMeaning
                                    ? Text(
                                        word.anlam ?? '',
                                        key: const ValueKey('meaning'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          height: 1.4,
                                        ),
                                      )
                                    : Text(
                                        displayWord,
                                        key: const ValueKey('word'),
                                        textAlign: TextAlign.center,
                                        textDirection: ui.TextDirection.rtl,
                                        style: GoogleFonts.scheherazadeNew(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                          height: 1.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          // Örnek Cümle - Minimalist
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Builder(
                              builder: (context) {
                                final ornekler = word.ornekCumleler;
                                if (ornekler == null || ornekler.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                
                                final ornek = ornekler[0];
                                if (ornek is! Map<String, dynamic>) {
                                  return const SizedBox.shrink();
                                }
                                
                                // Farklı format desteği (arapcaCümle vs arapcaCumle, turkceAnlam vs turkceCeviri)
                                final arapcaCumle = (ornek['arapcaCumle'] ?? ornek['arapcaCümle'] ?? ornek['arapca'] ?? '').toString();
                                final turkceCeviri = (ornek['turkceCeviri'] ?? ornek['turkceAnlam'] ?? ornek['turkce'] ?? '').toString();
                                
                                // Dinamik font boyutu - uzun cümleler için küçültme
                                final double fontSize = arapcaCumle.length > 90 ? 17 : (arapcaCumle.length > 50 ? 19 : 21);

                                if (arapcaCumle.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                
                                return Container(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                        ? Colors.white.withOpacity(0.03)
                                        : Colors.black.withOpacity(0.025),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDarkMode 
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.05),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Arapça örnek cümle
                                      Text(
                                        arapcaCumle,
                                        textAlign: TextAlign.center,
                                        textDirection: ui.TextDirection.rtl,
                                        style: GoogleFonts.scheherazadeNew(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.w600,
                                          color: textColor.withOpacity(0.85),
                                          height: 1.5,
                                        ),
                                      ),
                                      
                                      // Türkçe çeviri - Smooth
                                      AnimatedSize(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOut,
                                        child: _showMeaning && turkceCeviri.isNotEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  turkceCeviri,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: subTextColor,
                                                    fontStyle: FontStyle.italic,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Slider navigasyon
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Page number chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${safeIndex + 1} / ${words.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Slider with arrow buttons on sides
                Row(
                  children: [
                    // Left arrow button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _currentCardIndex > 0
                            ? () {
                                final target = _currentCardIndex - 1;
                                _pageController.animateToPage(
                                  target,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                );
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 28,
                            color: _currentCardIndex > 0
                                ? (isDarkMode ? Colors.white : const Color(0xFF1C1C1E))
                                : subTextColor,
                          ),
                        ),
                      ),
                    ),
                    // Slider
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 2,
                            pressedElevation: 4,
                          ),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                          activeTrackColor: const Color(0xFF007AFF),
                          inactiveTrackColor: isDarkMode
                              ? const Color(0xFF3A3A3C)
                              : const Color(0xFFE5E5EA),
                          thumbColor: const Color(0xFF007AFF),
                          overlayColor: const Color(0xFF007AFF).withOpacity(0.2),
                          trackShape: const RoundedRectSliderTrackShape(),
                        ),
                        child: Slider(
                          value: _currentCardIndex.toDouble(),
                          min: 0,
                          max: (words.length - 1).toDouble(),
                          divisions: words.length > 1 ? words.length - 1 : null,
                          onChanged: (value) {
                            final pageIndex = value.round();
                            setState(() {
                              _currentCardIndex = pageIndex;
                              _showMeaning = false;
                            });
                            _pageController.jumpToPage(pageIndex);
                          },
                        ),
                      ),
                    ),
                    // Right arrow button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: safeIndex < words.length - 1
                            ? () {
                                final target = _currentCardIndex + 1;
                                _pageController.animateToPage(
                                  target,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                );
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 28,
                            color: safeIndex < words.length - 1
                                ? (isDarkMode ? Colors.white : const Color(0xFF1C1C1E))
                                : subTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


