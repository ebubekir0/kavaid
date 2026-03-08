import 'package:flutter/material.dart';
import '../models/quran_word_model.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';

/// Kuran sözlüğü arama sonucu kartı
class QuranSearchResultCard extends StatefulWidget {
  final QuranWordModel word;
  final VoidCallback? onTap;
  final String searchQuery;

  const QuranSearchResultCard({
    super.key,
    required this.word,
    this.onTap,
    required this.searchQuery,
  });

  @override
  State<QuranSearchResultCard> createState() => _QuranSearchResultCardState();
}

class _QuranSearchResultCardState extends State<QuranSearchResultCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    final anlamListesi = word.anlamListesi;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
            widget.onTap?.call();
          },
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode 
                    ? const Color(0xFF48484A)
                    : const Color(0xFFD0D0D0),
                width: 0.8,
              ),
              boxShadow: isDarkMode ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Üst satır: Kelime + Kök + Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                word.kelime,
                                style: GoogleFonts.scheherazadeNew(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                                  height: 1.4,
                                  fontFeatures: const [
                                    ui.FontFeature.enable('liga'),
                                    ui.FontFeature.enable('calt'),
                                  ],
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (word.kok.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF2D4720).withOpacity(0.3)
                                    : const Color(0xFF4A5729).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDarkMode
                                      ? const Color(0xFF8BC34A).withOpacity(0.4)
                                      : const Color(0xFF4A5729).withOpacity(0.3),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                word.kok,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5, // Biraz büyütüldü (9.5 -> 10.5)
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? const Color(0xFF8BC34A)
                                      : const Color(0xFF4A5729),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Aç/Kapat Butonu
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                LogicalKeyRow(
                  isExpanded: _isExpanded,
                  anlamListesi: anlamListesi,
                  isDarkMode: isDarkMode,
                  word: word,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LogicalKeyRow extends StatelessWidget {
  final bool isExpanded;
  final List<String> anlamListesi;
  final bool isDarkMode;
  final QuranWordModel word;

  const LogicalKeyRow({
    super.key,
    required this.isExpanded,
    required this.anlamListesi,
    required this.isDarkMode,
    required this.word,
  });

  @override
  Widget build(BuildContext context) {
    // Sadece Max 2 ayet listele
    final ayetList = word.ayetOrnekleri.take(2).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Text(
          anlamListesi.join(', '),
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            height: 1.3,
            fontWeight: FontWeight.w400,
          ),
          maxLines: isExpanded ? 20 : 3, // Kapalıyken 3, açıkken 20 satıra kadar göster
          overflow: TextOverflow.ellipsis,
        ),
        if (isExpanded && ayetList.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            height: 1.0,
            color: isDarkMode ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded,
                  size: 14,
                  color: isDarkMode ? const Color(0xFFB8D4A0) : const Color(0xFF4A5729)),
              const SizedBox(width: 6),
              Text(
                'Kur\'an\'dan Örnek Ayetler',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? const Color(0xFFB8D4A0) : const Color(0xFF4A5729),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...ayetList.map((ayet) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? const Color(0xFF1E3215)
                    : const Color(0xFFF1F6EC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF3D5A28) : const Color(0xFF8BC34A).withOpacity(0.5),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (ayet.sureAyet.isNotEmpty)
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2D4720)
                              : const Color(0xFFD4E4C0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ayet.sureAyet,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? const Color(0xFF8BC34A) : const Color(0xFF2D4720),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (ayet.sureAyet.isNotEmpty) const SizedBox(height: 8),
                  if (ayet.arapcaMetin.isNotEmpty)
                    Text(
                      ayet.arapcaMetin,
                      style: GoogleFonts.scheherazadeNew(
                        fontSize: 20,
                        color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right, // Sağa yaslı
                    ),
                  if (ayet.arapcaMetin.isNotEmpty && ayet.meal.isNotEmpty)
                    const SizedBox(height: 8),
                  if (ayet.meal.isNotEmpty)
                    Text(
                      ayet.meal,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? const Color(0xFFD4E4C0) : const Color(0xFF4A5729),
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.left, // Sola yaslı
                    ),
                ],
              ),
            ),
          )),
        ],
      ],
    );
  }
}

/// Kuran sözlüğü kelime detay kartı (tam ekran kullanımı için)
class QuranWordCard extends StatelessWidget {
  final QuranWordModel word;

  const QuranWordCard({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final anlamListesi = word.anlamListesi;
    // Maksimum 2 ayet listele
    final ayetList = word.ayetOrnekleri.take(2).toList();

    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C3E18) : const Color(0xFF4A5729),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF4A5729) : const Color(0xFF5C6B35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              word.kelime,
              style: GoogleFonts.scheherazadeNew(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.4,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: 8),
          if (word.kok.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? const Color(0xFF1E3215)
                      : const Color(0xFF2D4720),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode 
                        ? const Color(0xFF3D5A28)
                        : const Color(0xFF3D5A28),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  word.kok,
                  style: GoogleFonts.scheherazadeNew(
                    fontSize: 18,
                    color: const Color(0xFFD4E4C0),
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E3215) : const Color(0xFF2D4720),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3D5A28).withOpacity(0.8),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.translate, size: 16, color: Color(0xFFB8D4A0)),
                    SizedBox(width: 6),
                    Text(
                      'Anlamları',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB8D4A0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...anlamListesi.map((anlam) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFFB8D4A0), fontSize: 14)),
                          Expanded(
                            child: Text(
                              anlam,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE8F0DC),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          if (ayetList.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_rounded,
                    size: 16, color: Color(0xFFB8D4A0)),
                SizedBox(width: 6),
                Text(
                  'Kuran\'dan Örnek Ayetler',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB8D4A0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...ayetList.map((ayet) => _buildAyetDetailCard(ayet, isDarkMode)),
          ],
        ],
      ),
    );
  }

  Widget _buildAyetDetailCard(QuranAyetOrnek ayet, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E3215) : const Color(0xFF2D4720),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3D5A28).withOpacity(0.8),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ayet.sureAyet.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2D4720) : const Color(0xFF1E3215),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ayet.sureAyet,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8BC34A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (ayet.sureAyet.isNotEmpty) const SizedBox(height: 10),
            if (ayet.arapcaMetin.isNotEmpty)
              Text(
                ayet.arapcaMetin,
                style: GoogleFonts.scheherazadeNew(
                  fontSize: 22,
                  color: Colors.white,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            if (ayet.arapcaMetin.isNotEmpty && ayet.meal.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(
                color: Color(0xFF48484A),
                thickness: 0.5,
              ),
              const SizedBox(height: 4),
            ],
            if (ayet.meal.isNotEmpty)
              Text(
                ayet.meal,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFD4E4C0),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}    
