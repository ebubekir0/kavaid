import 'package:flutter/material.dart';
import '../../widgets/wow_guru_mini_game.dart';
import 'package:google_fonts/google_fonts.dart';

class GameScreen extends StatelessWidget {
  final bool isDarkMode;

  const GameScreen({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF000000) 
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'Oyun',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/game_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay for Contrast
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          // Game Content
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0), // Bottom nav için
              child: WowGuruMiniGame(isDarkMode: isDarkMode),
            ),
          ),
        ],
      ),
    );
  }
}
