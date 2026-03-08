import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../data/embedded_words_data.dart';

class WowGuruMiniGame extends StatefulWidget {
  final bool isDarkMode;
  const WowGuruMiniGame({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  State<WowGuruMiniGame> createState() => _WowGuruMiniGameState();
}

class _WowGuruMiniGameState extends State<WowGuruMiniGame>
    with SingleTickerProviderStateMixin {
  late String _targetWord;
  late String _meaning;
  late List<String> _letters;

  List<int> _selectedIndices = [];
  Offset? _currentDragPosition;

  // Game states
  bool _isSuccess = false;
  bool _isError = false;
  bool _isLoading = true;

  // Coordinates for letters
  final double circleRadius = 100.0;
  final double letterBoxSize = 50.0;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _loadRandomWord();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  String _removeDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
  }

  void _loadRandomWord() {
    // Sadece 3 ile 6 harf arası Arapça kelimeler
    final candidates = embeddedWordsData.where((w) {
      final harekeli = w['harekeliKelime'] as String? ?? '';
      final anlam = w['anlam'] as String? ?? '';
      if (harekeli.isEmpty || anlam.isEmpty) return false;

      final clean = _removeDiacritics(harekeli);
      if (clean.length < 3 || clean.length > 6) return false;
      if (clean.contains(' ')) return false;
      if (!RegExp(r'[\u0600-\u06FF]').hasMatch(clean)) return false;
      return true;
    }).toList();

    if (candidates.isEmpty) {
      setState(() {
        _isLoading = false;
        _targetWord = "";
        _letters = [];
      });
      return;
    }

    final random = Random();
    final selected = candidates[random.nextInt(candidates.length)];
    _targetWord = _removeDiacritics(
      selected['harekeliKelime'] as String? ?? '',
    );
    _meaning = selected['anlam'] as String? ?? '';

    // Shuffle the letters
    _letters = _targetWord.split('');
    _letters.shuffle(random);

    setState(() {
      _selectedIndices = [];
      _currentDragPosition = null;
      _isSuccess = false;
      _isError = false;
      _isLoading = false;
    });
  }

  List<Offset> _getLetterPositions(Size size) {
    List<Offset> positions = [];
    final center = Offset(size.width / 2, size.height / 2);
    final count = _letters.length;
    for (int i = 0; i < count; i++) {
      final angle = (2 * pi * i / count) - pi / 2;
      positions.add(
        Offset(
          center.dx + circleRadius * cos(angle),
          center.dy + circleRadius * sin(angle),
        ),
      );
    }
    return positions;
  }

  void _handlePanStart(DragStartDetails details, Size size) {
    if (_isSuccess) return;
    _checkDrag(details.localPosition, size, isStart: true);
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (_isSuccess) return;
    setState(() {
      _currentDragPosition = details.localPosition;
    });
    _checkDrag(details.localPosition, size);
  }

  void _handlePanEnd(DragEndDetails details, Size size) {
    if (_isSuccess) return;
    setState(() {
      _currentDragPosition = null;
    });

    if (_selectedIndices.isNotEmpty) {
      final formedWord = _selectedIndices.map((i) => _letters[i]).join('');
      if (formedWord == _targetWord) {
        // Doğru!
        HapticFeedback.mediumImpact();
        setState(() {
          _isSuccess = true;
          _isError = false;
        });

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _loadRandomWord();
        });
      } else {
        // Yanlış!
        HapticFeedback.heavyImpact();
        setState(() {
          _isError = true;
        });
        _shakeController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              _isError = false;
              _selectedIndices = [];
            });
          }
        });
      }
    }
  }

  void _checkDrag(Offset position, Size size, {bool isStart = false}) {
    final positions = _getLetterPositions(size);
    for (int i = 0; i < positions.length; i++) {
      if ((positions[i] - position).distance < letterBoxSize) {
        // hit radius
        if (!_selectedIndices.contains(i)) {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedIndices.add(i);
          });
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_targetWord.isEmpty) {
      return Center(
        child: Text(
          'Kelime bulunamadı',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Top status bar (Diamonds/Score)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Oyna',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode
                            ? Colors.white
                            : const Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.diamond_rounded,
                      color: Color(0xFF007AFF),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '100', // Demo score
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Meaning / Question Area
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDarkMode
                  ? [const Color(0xFF311B92), const Color(0xFF1A237E)] // Dark Purple/Deep Blue
                  : [const Color(0xFF5E35B1), const Color(0xFF4527A0)], // Guru Purple
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5E35B1).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.5),
                blurRadius: 2,
                offset: const Offset(0, -1), // Subtle inner light
              ),
            ],
          ),
          child: Text(
            _meaning,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),

        const SizedBox(height: 30),

        // Empty boxes for the word
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final shake =
                sin(_shakeAnimation.value * pi * 3) *
                10 *
                (1 - _shakeAnimation.value);
            return Transform.translate(offset: Offset(shake, 0), child: child);
          },
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_targetWord.length, (index) {
                // Determine if a letter should be shown
                String letterToShow = '';
                if (_isSuccess) {
                  letterToShow = _targetWord[index];
                } else if (index < _selectedIndices.length) {
                  letterToShow = _letters[_selectedIndices[index]];
                }

                Color boxColor = Colors.white.withOpacity(0.9);
                Color borderColor = Colors.white.withOpacity(0.3);

                if (_isSuccess) {
                  boxColor = const Color(0xFF4CAF50);
                  borderColor = const Color(0xFF4CAF50);
                } else if (_isError && index < _selectedIndices.length) {
                  boxColor = const Color(0xFFFF3B30);
                  borderColor = const Color(0xFFFF3B30);
                } else if (index < _selectedIndices.length) {
                  boxColor = const Color(0xFF5E35B1);
                  borderColor = const Color(0xFF5E35B1);
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      if (letterToShow.isNotEmpty)
                        BoxShadow(
                          color: boxColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letterToShow,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: index < _selectedIndices.length || _isSuccess
                          ? Colors.white
                          : (widget.isDarkMode
                                ? Colors.white24
                                : Colors.black26),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 50),

        // Circular letter wheel
        SizedBox(
          width: circleRadius * 2 + letterBoxSize * 2,
          height: circleRadius * 2 + letterBoxSize * 2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final positions = _getLetterPositions(size);

              return GestureDetector(
                onPanStart: (d) => _handlePanStart(d, size),
                onPanUpdate: (d) => _handlePanUpdate(d, size),
                onPanEnd: (d) => _handlePanEnd(d, size),
                child: Stack(
                  children: [
                    // Ana Beyaz Yuvarlak Alan (Görseldeki gibi)
                    Center(
                      child: Container(
                        width: circleRadius * 2 + letterBoxSize + 20,
                        height: circleRadius * 2 + letterBoxSize + 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bağlantı çizgileri
                    CustomPaint(
                      size: size,
                      painter: _LinePainter(
                        positions: positions,
                        selectedIndices: _selectedIndices,
                        currentPosition: _currentDragPosition,
                        pathColor: _isError
                            ? const Color(0xFFFF3B30)
                            : const Color(0xFF5E35B1), // Purple theme
                      ),
                    ),

                    // Harfler
                    ...List.generate(_letters.length, (index) {
                      final pos = positions[index];
                      final isSelected = _selectedIndices.contains(index);

                      return Positioned(
                        left: pos.dx - letterBoxSize / 2,
                        top: pos.dy - letterBoxSize / 2,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: letterBoxSize,
                          height: letterBoxSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (_isError
                                      ? const Color(0xFFFF3B30)
                                      : const Color(0xFF5E35B1)) // Dark Purple
                                : Colors.transparent, // Unselected has no background
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _letters[index],
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E), // Dark letters
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<Offset> positions;
  final List<int> selectedIndices;
  final Offset? currentPosition;
  final Color pathColor;

  _LinePainter({
    required this.positions,
    required this.selectedIndices,
    this.currentPosition,
    required this.pathColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndices.isEmpty) return;

    final paint = Paint()
      ..color = pathColor.withOpacity(0.8)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(
      positions[selectedIndices[0]].dx,
      positions[selectedIndices[0]].dy,
    );

    for (int i = 1; i < selectedIndices.length; i++) {
      path.lineTo(
        positions[selectedIndices[i]].dx,
        positions[selectedIndices[i]].dy,
      );
    }

    if (currentPosition != null) {
      path.lineTo(currentPosition!.dx, currentPosition!.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.selectedIndices != selectedIndices ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.pathColor != pathColor;
  }
}
