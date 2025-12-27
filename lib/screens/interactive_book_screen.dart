import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import '../services/tts_service.dart';

class InteractiveBookScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final String arabicTitle;
  final String thumbnail;
  final bool isDarkMode;

  const InteractiveBookScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.arabicTitle,
    required this.thumbnail,
    required this.isDarkMode,
  });

  @override
  State<InteractiveBookScreen> createState() => _InteractiveBookScreenState();
}

class _InteractiveBookScreenState extends State<InteractiveBookScreen> with WidgetsBindingObserver {
  final TTSService _ttsService = TTSService();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _allWords = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  int _selectedIndex = 0; 
  double _fontSize = 19.0; // Default: 19

  String _selectedFont = 'Scheherazade New';
  final List<String> _arabicFonts = [
    'Scheherazade New',
    'Noto Naskh Arabic',
    'Amiri',
  ];
  bool _showDiacritics = true; 
  bool _autoReadOnTap = true; 
  bool _isAutoPlaying = false; 
  double _speechRate = 1.0; 
  double _currentVolume = 1.0; 
  double _lastVolume = 1.0; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Lifecycle takibi başlat
    _ttsService.setBookId(widget.bookId);
    _loadAllContent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer'ı kaldır
    _stopAutoPlay(); // Önce auto-play döngüsünü kır
    _ttsService.stop(); // Sonra sesi kes
    _scrollController.dispose(); // ScrollController temizle
    super.dispose();
  }

  // Uygulama alta atılınca veya ekran kapanınca çalışır
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Arka plana atıldığında durdur
      if (_isAutoPlaying) {
        _toggleAutoPlay();
      } else {
        _ttsService.stop();
      }
    }
  }

  Future<void> _stopAutoPlay() async {
     setState(() => _isAutoPlaying = false);
     await _ttsService.stop();
  }

  Future<void> _loadAllContent() async {
    try {
      final String fullBookPath = 'assets/books/${widget.bookId.toLowerCase()}/full_book.json';
      final String jsonStr = await rootBundle.loadString(fullBookPath);
      final Map<String, dynamic> bookData = json.decode(jsonStr);

      List<dynamic> items = bookData['kelimeler'] ?? [];
      List<Map<String, dynamic>> loadedWords = [];

      for (var item in items) {
        if (item['type'] == 'newline') {
           loadedWords.add({'type': 'newline', 'arapca': '', 'turkce': ''});
        } else {
           loadedWords.add({
            'type': 'word',
            'arapca': item['arapca'] ?? '',
            'turkce': item['turkce'] ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          _allWords = loadedWords;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Hata (Tek Dosya Yükleme): $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "İçerik yüklenirken bir sorun oluştu.\n\n$e";
        });
      }
    }
  }

  Future<void> _onWordTap(int index) async {
    if (index < 0 || index >= _allWords.length) return;
    final item = _allWords[index];
    if (item['type'] == 'newline') return;

    setState(() {
      _selectedIndex = index;
    });

    if (_isAutoPlaying) {
       // Auto play sırasında tıklanırsa -> Auto play'i DURDUR.
       // Bu sayede kullanıcı manuel kontrole geçer.
       _toggleAutoPlay(); // Durdurur ama ses bir kelime bitene kadar çalabilir, bunu speak() ile keseceğiz.
    } 

    // Her durumda (auto play durmuş olsa bile) o kelimeyi oku
    if (_autoReadOnTap) { 
        // DİKKAT: Ses dosyaları HAREKELİ halleriyle MD5 hashlenmiş durumda.
        // Bu yüzden _showDiacritics kapalı olsa bile sese giden kelime HAREKELİ OLMALI.
        String ttsWord = item['arapca']; 
        
        // Ses seviyesini garantiye al - Çalmadan önce set et
        await _ttsService.setVolume(_currentVolume);
        await _ttsService.speak(ttsWord); 
    }
  }

  Future<void> _toggleAutoPlay() async {
     if (_isAutoPlaying) {
       setState(() => _isAutoPlaying = false);
       await _ttsService.stop();
       return;
     }

     setState(() => _isAutoPlaying = true);

     // Kalınan yerden devam
     int currentIndex = _selectedIndex;
     if (currentIndex >= _allWords.length - 1) {
       currentIndex = 0;
     }

     while (_isAutoPlaying && currentIndex < _allWords.length) {
        // Newline atla
        if (_allWords[currentIndex]['type'] == 'newline') {
           currentIndex++;
           continue;
        }

        if (mounted) {
          setState(() => _selectedIndex = currentIndex);
        }
        _scrollToCenter(currentIndex);

        final item = _allWords[currentIndex];
        // DİKKAT: Ses dosyaları HAREKELİ halleriyle MD5 hashlenmiş durumda.
        String ttsWord = item['arapca']; 
        
        // speakAndWait KULLANIYORUZ - Kelime bitmeden geçmemesi için
        if (ttsWord.trim().isNotEmpty) {
           // Her kelimede sesi tekrar set et (Player resetlenebilir)
           await _ttsService.setVolume(_currentVolume);
           await _ttsService.speakAndWait(ttsWord);
        }
        
        if (!_isAutoPlaying) break;

        currentIndex++;
     }
     
     if (mounted) setState(() => _isAutoPlaying = false);
  }

  void _navigateWord(int delta) {
    int newIndex = _selectedIndex + delta;
    while (newIndex >= 0 && newIndex < _allWords.length) {
      if (_allWords[newIndex]['type'] != 'newline') {
        break; 
      }
      newIndex += delta; 
    }

    if (newIndex >= 0 && newIndex < _allWords.length) {
      _onWordTap(newIndex);
      _scrollToCenter(newIndex);
    }
  }

  void _scrollToCenter(int index) {
      // Pas geçildi
  }

  // Ses Ayarı Dialogu
  void _showVolumeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Color bgColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
            Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;
            Color primaryColor = widget.isDarkMode ? Colors.blueAccent : const Color(0xFF007AFF);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Row(
                     children:[
                        Icon(Icons.volume_up_rounded, color: primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          "Okuma Sesi",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                     ]
                   ),
                   const SizedBox(height: 24),
                   Row(
                     children: [
                       Icon(Icons.volume_mute_rounded, size: 20, color: textColor.withOpacity(0.5)),
                       Expanded(
                         child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 6,
                              activeTrackColor: primaryColor,
                              inactiveTrackColor: primaryColor.withOpacity(0.15),
                              thumbColor: primaryColor,
                              overlayColor: primaryColor.withOpacity(0.2),
                            ),
                            child: Slider(
                              value: _currentVolume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) {
                                setModalState(() => _currentVolume = val);
                                setState(() => _currentVolume = val); // Ana ekranı da güncelle
                                _ttsService.setVolume(val);
                              },
                            ),
                         ),
                       ),
                       Icon(Icons.volume_up_rounded, size: 20, color: textColor.withOpacity(0.5)),
                     ],
                   ),
                   const SizedBox(height: 10),
                   Text(
                     "%${(_currentVolume * 100).toInt()}",
                     style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                     ),
                   ),
                   const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;
            Color primaryBlue = widget.isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
            
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Görünüm Ayarları", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Yazı Boyutu", style: TextStyle(fontSize: 16, color: textColor)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (_fontSize > 12) {
                                setState(() => _fontSize -= 2);
                                setModalState(() {});
                              }
                            },
                          ),
                          Text("${_fontSize.toInt()}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              if (_fontSize < 40) {
                                setState(() => _fontSize += 2);
                                setModalState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text("Harekeleri Göster", style: TextStyle(fontSize: 16, color: textColor)),
                       Switch(
                         value: _showDiacritics,
                         activeColor: widget.isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
                         onChanged: (val) {
                           setState(() => _showDiacritics = val);
                           setModalState(() {});
                         },
                       ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text("Dokununca Oku", style: TextStyle(fontSize: 16, color: textColor)),
                       Switch(
                         value: _autoReadOnTap,
                         activeColor: widget.isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
                         onChanged: (val) {
                           setState(() => _autoReadOnTap = val);
                           setModalState(() {});
                         },
                       ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Okuma Hızı: ${_speechRate.toStringAsFixed(1)}x", style: TextStyle(fontSize: 16, color: textColor)),
                  Slider(
                    value: _speechRate.clamp(0.5, 2.0),
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    activeColor: primaryBlue,
                    onChanged: (val) {
                      setState(() => _speechRate = val);
                      setModalState(() {});
                      _ttsService.setRate(val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode 
        ? const Color(0xFF121212) 
        : const Color(0xFFF8F0DA);
    final primaryBlue = widget.isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
    final textColor = widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF212121);
    final barBgColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final double bottomBarHeight = 90.0 + MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          _stopAutoPlay();
          _ttsService.stop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              // 1. İçerik Katmanı
              Positioned.fill(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: primaryBlue),
                            const SizedBox(height: 16),
                            Text(
                              "Kitap içeriği hazırlanıyor...",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: textColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLoading = true;
                                        _errorMessage = '';
                                      });
                                      _loadAllContent();
                                    },
                                    child: const Text("Tekrar Dene"),
                                  )
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomBarHeight + 16),
                        child: Column(
                          children: [
                            // Üst Başlık ve Geri Butonu
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: textColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.arabicTitle,
                                    textAlign: TextAlign.center,
                                    textDirection: ui.TextDirection.rtl,
                                    style: GoogleFonts.getFont(
                                      _selectedFont,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 42),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Kitap Kapağı
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: widget.thumbnail.isNotEmpty 
                                    ? Image.asset(
                                        widget.thumbnail,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, o, s) => Container(
                                          height: 180,
                                          color: Colors.grey[300],
                                          child: const Center(child: Icon(Icons.broken_image)),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            // Metin Alanı
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: RichText(
                                textAlign: TextAlign.justify, 
                                textDirection: ui.TextDirection.rtl,
                                text: TextSpan(
                                  children: _buildTextSpans(textColor, primaryBlue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // 2. Alt Bar (Kontroller)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: barBgColor, 
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(
                      top: BorderSide(color: primaryBlue.withOpacity(0.5), width: 1.2),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).padding.bottom + 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavBtn(Icons.arrow_back_rounded, () => _navigateWord(1), textColor),
                      // Orta Kontrol Grubu
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (_currentVolume > 0) {
                                    _lastVolume = _currentVolume;
                                    _currentVolume = 0.0;
                                  } else {
                                    _currentVolume = _lastVolume > 0 ? _lastVolume : 1.0;
                                  }
                                  _ttsService.setVolume(_currentVolume);
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  _currentVolume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, 
                                  color: textColor.withOpacity(0.8),
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                                onTap: _toggleAutoPlay,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: primaryBlue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isAutoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _showSettings,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(Icons.settings_rounded, color: textColor.withOpacity(0.8), size: 22),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildNavBtn(Icons.arrow_forward_rounded, () => _navigateWord(-1), textColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, VoidCallback onTap, Color textColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: textColor.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: textColor.withOpacity(0.8), size: 24),
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(Color textColor, Color accentColor) {
    List<InlineSpan> spans = [];

    for (int i = 0; i < _allWords.length; i++) {
      final item = _allWords[i];

      if (item['type'] == 'newline') {
        spans.add(const TextSpan(text: "\n"));
        continue;
      }

      String word = item['arapca'];
      if (!_showDiacritics) {
        word = word.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
      }

      final bool isSelected = _selectedIndex == i;
      final String meaning = item['turkce'] ?? '';

      spans.add(
        TextSpan(
          text: word,
          style: GoogleFonts.getFont(
              _selectedFont,
              fontSize: _fontSize,
              height: 2.5,
              fontWeight: FontWeight.normal,
              color: textColor,
              backgroundColor: isSelected ? accentColor.withOpacity(0.2) : Colors.transparent,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _onWordTap(i),
        ),
      );

      if (isSelected) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: word,
            style: GoogleFonts.getFont(
                _selectedFont,
                fontSize: _fontSize,
                fontWeight: FontWeight.normal
            )
          ),
          textDirection: ui.TextDirection.rtl,
          maxLines: 1,
        )..layout();

        final double wordWidth = textPainter.width;
        final String displayText = meaning.isEmpty ? "..." : meaning;

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(
              width: 0,
              height: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -(wordWidth / 2),
                    bottom: 25,
                    child: FractionalTranslation(
                      translation: const Offset(0.5, 0),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              constraints: const BoxConstraints(maxWidth: 130),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                displayText,
                                textAlign: TextAlign.center,
                                textDirection: ui.TextDirection.ltr,
                                style: GoogleFonts.outfit(
                                  fontSize: _fontSize * 0.70,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -1),
                              child: CustomPaint(
                                size: const Size(12, 6),
                                painter: _BubbleArrowPainter(color: accentColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      spans.add(
        TextSpan(
           text: " ",
           style: GoogleFonts.getFont(
              _selectedFont,
              fontSize: _fontSize * 0.8,
              height: 2.3,
           ),
        ),
      );
    }
    return spans;
  }
}

class _BubbleArrowPainter extends CustomPainter {
  final Color color;
  _BubbleArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
