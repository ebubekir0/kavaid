import 'package:flutter/material.dart';

/// Parses text containing <blue>...</blue> tags and returns a list of TextSpans.
/// The text inside <blue> tags will be rendered in blue with a subtle background.
/// Regular text will use the provided [defaultStyle].
List<TextSpan> parseBlueTagSpans(String text, TextStyle defaultStyle) {
  final List<TextSpan> spans = [];
  final RegExp blueTagRegex = RegExp(r'<blue>(.*?)</blue>');
  
  int lastEnd = 0;
  
  for (final match in blueTagRegex.allMatches(text)) {
    // Add text before the tag
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: text.substring(lastEnd, match.start),
        style: defaultStyle,
      ));
    }
    
    // Add the blue-tagged text
    final blueText = match.group(1) ?? '';
    spans.add(TextSpan(
      text: blueText,
      style: defaultStyle.copyWith(
        color: const Color(0xFF007AFF),
        fontWeight: FontWeight.w600,
      ),
    ));
    
    lastEnd = match.end;
  }
  
  // Add remaining text after the last tag
  if (lastEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastEnd),
      style: defaultStyle,
    ));
  }
  
  // If no tags were found, return the whole text as a single span
  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: defaultStyle));
  }
  
  return spans;
}

/// Builds a RichText widget that renders <blue>...</blue> tags in blue.
/// [maxLines] and [overflow] control truncation behavior.
Widget buildBlueTagText(
  String text, {
  required TextStyle defaultStyle,
  int? maxLines,
  TextOverflow? overflow,
}) {
  final spans = parseBlueTagSpans(text, defaultStyle);
  return RichText(
    text: TextSpan(children: spans),
    maxLines: maxLines,
    overflow: overflow ?? TextOverflow.clip,
  );
}

/// Strips <blue> and </blue> tags from text (for plain text usage like sharing).
String stripBlueTags(String text) {
  return text.replaceAll(RegExp(r'</?blue>'), '');
}
