import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/word_model.dart';
import '../services/tts_service.dart';
import '../widgets/fps_counter_widget.dart';
import '../services/book_lessons_service.dart';
import '../services/book_store_service.dart';
import '../services/book_purchase_service.dart';
import 'book_texts_screen.dart';
import 'custom_words_screen.dart';
import 'profile_screen.dart';

class LearningScreen extends StatefulWidget {
  final double bottomPadding;
  final bool isDarkMode;
  final VoidCallback? onThemeToggle;

  const LearningScreen({
    super.key,
    required this.bottomPadding,
    required this.isDarkMode,
    this.onThemeToggle,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final TTSService _ttsService = TTSService();
  final BookLessonsService _lessons = BookLessonsService();
  final BookStoreService _bookStore = BookStoreService();
  final BookPurchaseService _bookPurchase = BookPurchaseService();
  
  WordModel? _currentWord;
  bool _isLoading = false;
  bool _showMeaning = false;
  bool _isReversed = false;
  int _learnedWordsCount = 0;
  List<BookWord> _currentPool = const [];
  int _poolIndex = 0;

  @override
  void initState() {
    super.initState();
    _bookStore.initialize();
    _bookPurchase.initialize();
    _bookPurchase.addListener(_updateState);
    _bookPurchase.loadProductFor('kitab_kiraah_1');
  }

  @override
  void dispose() {
    _bookPurchase.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showPurchaseDialog(String bookId, String bookTitle, bool isDarkMode) {
    final auth = AuthService();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          String priceText = 'Yükleniyor...';

          // Play Console'dan dinamik fiyat: tüm kitaplar için BookPurchaseService
          _bookPurchase.loadProductFor(bookId).then((_) {
            if (mounted) {
              setDialogState(() {
                priceText = _bookPurchase.currentBookPrice;
              });
            }
          });
          priceText = _bookPurchase.currentBookPrice;

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
                  '${bookId == 'kitab_kiraah_1' ? 'Kitabul Kıraat 1' : bookId == 'kitab_kiraah_2' ? 'Kitabul Kıraat 2' : 'Kitabul Kıraat 3'} kelimelerine ömür boyu erişmek için ürünü satın al.',
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
              ElevatedButton(
                onPressed: () async {
                  // Satın alma için önce giriş kontrolü
                  if (!auth.isSignedIn) {
                    Navigator.of(ctx).pop();
                    _showLoginRequiredDialog(isDarkMode);
                    return;
                  }
                  Navigator.of(ctx).pop();

                  // Kitap satın alma (Play Console) – tüm kitaplar
                  try {
                    await _bookPurchase.loadProductFor(bookId);
                    await _bookPurchase.buyBook(bookId);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Satın alma hatası: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                  if (mounted) setState(() {});
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

  void _showLoginRequiredDialog(bool isDarkMode) {
    if (!mounted) return;
    
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

  Widget _buildBooksList(bool isDarkMode) {
    final books = BookStoreService.books;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (ctx, index) {
        if (index == 0) {
          return _buildCustomWordsCard(isDarkMode);
        }
        final book = books[index - 1];
        final displayTitle = book.title.replaceAll(RegExp(r'[.…]+'), '');
        final purchased = _bookStore.isPurchased(book.id);
        final cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
        final borderColor = isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
        final titleColor = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
        final subColor = isDarkMode ? Colors.white70 : Colors.black54;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (!mounted) return;
              
              // Direkt kitap ekranına yönlendir (önizleme modu kaldırıldı)
              // İlk 3 ders otomatik açık olacak
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BookTextsScreen(
                  bookId: book.id,
                  bookTitle: book.title,
                  isDarkMode: isDarkMode,
                ),
              ));
              if (!mounted) return;
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _BookImage(base: book.imageBase, width: 64, height: 84),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (() {
                            switch (book.id) {
                              case 'kitab_kiraah_1':
                                return '2217 kelime';
                              case 'kitab_kiraah_2':
                                return '2219 kelime';
                              case 'kitab_kiraah_3':
                                return '1715 kelime';
                              default:
                                return '';
                            }
                          })(),
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      SizedBox(
                        width: 72,
                        height: purchased ? 42 : 36,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!mounted) return;
                            final purchased = _bookStore.isPurchased(book.id);
                            
                            if (purchased) {
                              // Satın alınmışsa direkt aç
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => BookTextsScreen(
                                  bookId: book.id,
                                  bookTitle: book.title,
                                  isDarkMode: isDarkMode,
                                ),
                              ));
                              if (!mounted) return;
                              setState(() {});
                              return;
                            }
                            
                            // Satın alınmamışsa satın alma işlemine git
                            final auth = AuthService();
                            if (!auth.isSignedIn) {
                              _showLoginRequiredDialog(isDarkMode);
                              return;
                            }
                            _showPurchaseDialog(book.id, book.title, widget.isDarkMode);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Builder(builder: (context) {
                            String price = 'Yükleniyor...';
                            _bookPurchase.loadProductFor(book.id);
                            price = _bookPurchase.currentBookPrice;
                            final buttonText = purchased ? 'Aç' : price;

                            return Container(
                              margin: const EdgeInsets.only(top: 2),
                              child: Center(
                                child: Text(
                                  buttonText,
                                  style: const TextStyle(
                                    fontSize: 13.1,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (!purchased)
                        SizedBox(
                          width: 72,
                          height: 36,
                          child: OutlinedButton(
                            onPressed: () async {
                              if (!mounted) return;
                              // Önizleme için giriş gerekmez - ilk 3 ders otomatik açık
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => BookTextsScreen(
                                  bookId: book.id,
                                  bookTitle: book.title,
                                  isDarkMode: isDarkMode,
                                ),
                              ));
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: const Color(0xFF007AFF),
                              side: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            ),
                            child: const Text(
                              'Önizle',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF007AFF),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: books.length + 1,
    );
  }

  Widget _buildCustomWordsCard(bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final subColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomWordsScreen(isDarkMode: isDarkMode),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.bookmarks_rounded,
                    size: 32,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelimelerim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kaydettiğin ve eklediğin kelimeler',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF007AFF),
        elevation: 0,
        title: const Text(
          'Öğren',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.onThemeToggle != null)
            // Tema değiştirme toggle butonu (yalnızca callback varsa)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Container(
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: widget.isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.3),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      left: widget.isDarkMode ? 22 : 2,
                      top: 2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            size: 16,
                            color: widget.isDarkMode
                                ? const Color(0xFF007AFF)
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    // Tıklanabilir alan
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: widget.onThemeToggle,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        child: _buildBooksList(isDarkMode),
      ),
    );
  }
}

class _BookImage extends StatelessWidget {
  final String base;
  final double width;
  final double height;
  
  const _BookImage({
    required this.base,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
          width: width,
          height: height,
          color: Colors.grey.withOpacity(0.2),
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, color: Color(0xFF7A7A7A)),
        );

    // Try jpg then png
    return Image.asset(
      '$base.jpg',
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          '$base.png',
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        );
      },
    );
  }
}
