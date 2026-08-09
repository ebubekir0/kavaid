import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';

class QuranTextScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(String) onWordTapped;

  const QuranTextScreen({
    super.key,
    required this.isDarkMode,
    required this.onWordTapped,
  });

  @override
  State<QuranTextScreen> createState() => _QuranTextScreenState();
}

class _QuranTextScreenState extends State<QuranTextScreen> {
  bool _isLoading = true;
  List<dynamic> _pages = [];
  int _currentPage = 1;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/quran_text_pages.json');
      final data = json.decode(jsonString) as List<dynamic>;
      setState(() {
        _pages = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading quran pages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Kelimenin sadece Arapça harflerden oluşmasını sağlayarak temizleme (noktalama işaretlerini, numaraları atma)
  String _cleanArabicWord(String word) {
    // Sadece Arapça harfleri ve harekeleri tut
    final regExp = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+');
    final matches = regExp.allMatches(word);
    if (matches.isEmpty) return '';
    return matches.map((m) => m.group(0)).join('');
  }

  Widget _buildPage(Map<String, dynamic> pageData) {
    final String fullText = pageData['text'] ?? '';
    final bgColor = widget.isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9F9);
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    
    // Satır satır bölelim, formati korumak için
    final lines = fullText.split('\n');

    List<InlineSpan> spans = [];

    for (var line in lines) {
      final words = line.split(RegExp(r'\s+'));
      for (var word in words) {
        if (word.trim().isEmpty) continue;
        
        final cleanWord = _cleanArabicWord(word);
        final isClickable = cleanWord.isNotEmpty;

        spans.add(
          TextSpan(
            text: '$word ',
            style: GoogleFonts.scheherazadeNew(
              fontSize: 28,
              height: 1.8,
              color: isClickable 
                  ? (widget.isDarkMode ? const Color(0xFFB8D4A0) : const Color(0xFF4A5729))
                  : textColor,
              fontWeight: isClickable ? FontWeight.w600 : FontWeight.normal,
            ),
            recognizer: isClickable ? (TapGestureRecognizer()
              ..onTap = () {
                // Tıklanan kelimenin harekelerini de tutabiliriz, çünkü quran_dictionary_service 
                // search ederken ignore ediyor. Ama temiz kelime üzerinden arama yapalım.
                widget.onWordTapped(cleanWord);
              }) : null,
          ),
        );
      }
      // Satır sonu
      spans.add(const TextSpan(text: '\n'));
    }

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          text: TextSpan(children: spans),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9F9);
    final isPremiumTheme = widget.isDarkMode;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Kuran-ı Kerim',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(
          color: widget.isDarkMode ? Colors.white : Colors.black87,
        ),
        actions: [
          if (!_isLoading && _pages.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Sayfa: $_currentPage/${_pages.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: widget.isDarkMode ? const Color(0xFF8BC34A) : const Color(0xFF4A5729),
              ),
            )
          : _pages.isEmpty
              ? Center(
                  child: Text(
                    'Kuran metni bulunamadı.',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index + 1;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildPage(_pages[index]);
                      },
                    ),
                    
                    // Alt Kısımda Etkileşim İpucu
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              bgColor,
                              bgColor.withOpacity(0.9),
                              bgColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                        child: Text(
                          'Sözlükte aramak için kelimelere dokunun',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: widget.isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
