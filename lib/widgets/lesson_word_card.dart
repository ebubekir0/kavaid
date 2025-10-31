import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

class LessonWordCard extends StatelessWidget {
  final String arabic;
  final String? turkish;
  final String? type;
  final bool isDarkMode;
  final VoidCallback onSpeak;

  const LessonWordCard({
    super.key,
    required this.arabic,
    required this.turkish,
    this.type,
    required this.isDarkMode,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color borderColor = isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFD0D0D0);
    final Color textColor = isDarkMode ? const Color(0xFFE5E5EA) : const Color(0xFF1C1C1E);
    final Color subColor = isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
              blurRadius: 6,
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
                  onPressed: onSpeak,
                  icon: Icon(Icons.volume_up, color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70)),
                  tooltip: 'Seslendir',
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Uzun Arapça kelimeler için otomatik sığdırma
            LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 48, maxWidth: constraints.maxWidth),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      arabic,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.scheherazadeNew(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: textColor,
                        fontFeatures: const [
                          ui.FontFeature.enable('liga'),
                          ui.FontFeature.enable('calt'),
                        ],
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                );
              },
            ),
            if (type != null && type!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                type!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: subColor,
                ),
              ),
            ],
            if ((turkish ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor.withOpacity(0.7), width: 0.8),
                ),
                child: Text(
                  turkish!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
