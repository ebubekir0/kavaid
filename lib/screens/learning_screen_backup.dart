import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
// import '../services/one_time_purchase_service.dart'; // Kitap satın alma ile karışmasın diye kaldırıldı
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/word_model.dart';
import '../services/tts_service.dart';
import '../widgets/fps_counter_widget.dart';
import '../services/book_lessons_service.dart';
import '../services/book_store_service.dart';
import '../services/book_purchase_service.dart';
import 'book_texts_screen.dart';
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
  // Not: Dinamik kelime sayımı kaldırıldı; sabit sayılar UI'da gösteriliyor.

  @override
  void initState() {
    super.initState();
    // eski UI: ilk açılışta kelime yüklemiyoruz
    _bookStore.initialize();
    _bookPurchase.initialize();
    _bookPurchase.addListener(_updateState);
    // Kıraat 1 fiyatını önceden yükle
    _bookPurchase.loadProductFor('kitab_kiraah_1');
    // Release modda fiyatların erken yüklenmesi için başlat
    if (kReleaseMode) {
      // OneTimePurchaseService kitap satın alma ile karışmasın diye kaldırıldı
    }
    // Kelime sayımı yapılmıyor; sabit sayılar gösterilecek.
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
      SnackBar(
        content: const Text(
          'Lütfen önce kayıt olup giriş yapın.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  void _showAuthSheet(bool isDarkMode) {
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

  // Dinamik kelime sayımı ve cache fonksiyonları kaldırıldı.

  Widget _buildBooksList(bool isDarkMode) {
    // Show all available books
    final books = BookStoreService.books;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (ctx, index) {
        final book = books[index];
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
                          // Title may already include "Kelimeleri"; remove dots/ellipsis
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
                        // Alt başlık kaldırıldı (başlangıç seviye gösterilmesin)
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
                            // Play Console'dan dinamik fiyat: tüm kitaplar BookPurchaseService
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
      itemCount: books.length,
    );
  }
  Future<void> _loadRandomWord() async {
    setState(() {
      _isLoading = true;
      _showMeaning = false;
      _isReversed = false;
    });

    try {
      if (_currentPool.isNotEmpty) {
        final BookWord bw = _currentPool[_poolIndex % _currentPool.length];
        _poolIndex++;
        if (!mounted) return;
        setState(() {
          _currentWord = WordModel(
            kelime: bw.arabic,
            anlam: bw.turkish,
            harekeliKelime: null,
          );
          _isLoading = false;
        });
      } else {
      final randomWord = await _databaseService.getRandomWord();
        if (!mounted) return;
        setState(() {
          _currentWord = randomWord;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
    }
  }

  void _handlePrimaryButton() {
    if (_currentWord == null) {
      _loadRandomWord();
      return;
    }
    if (!_showMeaning) {
      setState(() {
        _showMeaning = true;
        _learnedWordsCount++;
      });
    } else {
      _loadRandomWord();
    }
  }

  Future<void> _speakArabic(String text) async {
    try {
      await _ttsService.speak(text);
    } catch (_) {}
  }

  Future<void> openFirstBookLesson1() async {
    setState(() {
      _currentPool = const [];
      _poolIndex = 0;
    });
    final pool = await _lessons.loadLessonWords(bookId: 'kitab_kiraah_1', lessonNo: 1);
    if (!mounted) return;
    setState(() {
      _currentPool = pool;
    });
    await _loadRandomWord();
  }

  void _showBookPurchaseSheet() {
    final book = BookStoreService.books.first;
    final displayTitle = book.title.replaceAll(RegExp(r'[.…]+'), '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purchased = _bookStore.isPurchased(book.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _BookImage(base: book.imageBase, width: 60, height: 80),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (purchased)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await openFirstBookLesson1();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF007AFF),
                            side: const BorderSide(color: Color(0xFF007AFF)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Aç',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                    else ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Require sign-in before showing purchase dialog
                            final auth = AuthService();
                            if (!auth.isSignedIn) {
                              Navigator.of(ctx).pop();
                              _showLoginRequiredDialog(isDark);
                              return;
                            }
                            Navigator.of(ctx).pop();
                            _showPurchaseDialog(book.id, book.title, isDark);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            '₺89,99', // Kitap fiyatı sabit
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
{{ ... }}
            style: TextStyle(fontSize: 12, color: subColor),
          ),
          // Alt başlık kaldırıldı (başlangıç seviye gösterilmesin)
          if (!purchased) ...[
            const SizedBox(height: 8),
            Text(
              '₺89,99', // Kitap fiyatı sabit
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E)),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
{{ ... }}
                color: const Color(0xFF007AFF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Satın alındı',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF007AFF)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (!purchased)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  if (!mounted) return;
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                  side: const BorderSide(color: Color(0xFF007AFF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Önizle',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleWordCard(bool isDarkMode) {
    final cardColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    return Container(
          width: double.infinity,
      padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
        color: cardColor,
            borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
           child: Column(
            mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     IconButton(
                onPressed: _currentWord == null ? null : () => _speakArabic(_currentWord!.kelime),
                icon: Icon(Icons.volume_up, color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70)),
              )
            ],
          ),
          const SizedBox(height: 8),
                 Text(
                   _currentWord!.harekeliKelime ?? _currentWord!.kelime,
                   textAlign: TextAlign.center,
                   textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'ScheherazadeNew',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ).copyWith(color: textColor),
                 ),
                 const SizedBox(height: 24),
                  _MeaningBox(
                    text: _currentWord!.anlam,
                    isDarkMode: isDarkMode,
            isVisible: _showMeaning && (_currentWord!.anlam != null && _currentWord!.anlam!.isNotEmpty),
          ),
        ],
      ),
    );
  }
}

class _MeaningBox extends StatelessWidget {
  final String? text;
  final bool isDarkMode;
  final bool isVisible;

  const _MeaningBox({
    required this.text,
    required this.isDarkMode,
    this.isVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sabit yükseklik: yaklaşık 3 satırlık içeriğe göre ayarlandı
    const double reservedHeight = 88;
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 180),
      crossFadeState: isVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: reservedHeight),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text ?? '',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      secondChild: Container(
        width: double.infinity,
        height: reservedHeight,
      ),
    );
  }
}

class _BookImage extends StatelessWidget {
  final String base;
  final double width;
  final double height;
  const _BookImage({required this.base, required this.width, required this.height});

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

