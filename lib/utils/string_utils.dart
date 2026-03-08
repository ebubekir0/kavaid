import 'package:flutter/material.dart';

class StringUtils {
  /// <blue>[عَلَى]</blue> gibi harfi cer taglerini mavi+büyük olarak render eder.
  static List<TextSpan> parseMeaningWithBlue(
    String text, {
    required bool isDarkMode,
    required double fontSize,
    required double blueFontSize,
  }) {
    final List<TextSpan> spans = [];
    final RegExp blueTagRegex = RegExp(r'<blue>(.*?)<\/blue>', dotAll: true);
    int lastEnd = 0;

    final Color normalColor = isDarkMode
        ? const Color(0xFF8E8E93)
        : const Color(0xFF6D6D70);
    final Color blueColor = const Color(0xFF007AFF);

    for (final match in blueTagRegex.allMatches(text)) {
      // Tagden önce gelen normal metin
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            fontSize: fontSize,
            color: normalColor,
            height: 1.5,
          ),
        ));
      }
      // <blue> içindeki harfi cer - Köşeli parantezleri kaldır
      final rawBlue = match.group(1) ?? '';
      final cleanBlue = rawBlue.replaceAll(RegExp(r'^\[|\]$'), '').trim();

      spans.add(TextSpan(
        text: cleanBlue,
        style: TextStyle(
          fontSize: blueFontSize,
          color: blueColor,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ));
      lastEnd = match.end;
    }

    // Kalan normal metin
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          fontSize: fontSize,
          color: normalColor,
          height: 1.5,
        ),
      ));
    }

    // Hiç tag yoksa ve boş değilse
    if (spans.isEmpty && text.isNotEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: normalColor,
          height: 1.5,
        ),
      ));
    }

    return spans;
  }
}
