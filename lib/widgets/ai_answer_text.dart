import 'package:flutter/material.dart';

import 'search_result_card_parts.dart' show ArabicTextStyles;

/// AI cevabındaki bir satır.
class AnswerLine {
  final String text;
  final bool isBullet;

  const AnswerLine(this.text, {this.isBullet = false});

  bool get isGap => text.isEmpty;
}

const _arabicClass =
    r'\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF';

/// Boşlukla ayrılmış Arapça kelimeler tek parça sayılır, böylece harekeli bir
/// cümle bütün olarak Arapça fontla ve doğru yönde çizilir.
final RegExp _arabicRun = RegExp('[$_arabicClass]+(?:\\s+[$_arabicClass]+)*');
final RegExp _bulletPrefix = RegExp(r'^\s*[-*•]\s+');
final RegExp _headingPrefix = RegExp(r'^\s*#+\s*');

/// Modelin markdown alışkanlıklarını (**kalın**, # başlık, * madde) sade
/// satırlara çevirir. Art arda boş satırlar teke iner.
List<AnswerLine> parseAnswer(String raw) {
  final lines = <AnswerLine>[];
  final cleaned = raw.replaceAll('**', '').replaceAll('__', '');
  for (final line in cleaned.split('\n')) {
    final t = line.replaceFirst(_headingPrefix, '').trim();
    if (t.isEmpty) {
      if (lines.isNotEmpty && !lines.last.isGap) {
        lines.add(const AnswerLine(''));
      }
      continue;
    }
    final bullet = _bulletPrefix.firstMatch(line);
    lines.add(
      bullet != null
          ? AnswerLine(line.substring(bullet.end).trim(), isBullet: true)
          : AnswerLine(t),
    );
  }
  while (lines.isNotEmpty && lines.last.isGap) {
    lines.removeLast();
  }
  return lines;
}

/// Metindeki Arapça parçalar (seslendirme için).
List<String> arabicParts(String text) =>
    _arabicRun.allMatches(text).map((m) => m.group(0)!).toList();

/// Arapça parçaları [arabic] stiliyle, kalanını varsayılan stille böler.
List<InlineSpan> answerSpans(String text, TextStyle arabic) {
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _arabicRun.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(TextSpan(text: m.group(0), style: arabic));
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

/// AI asistan cevabı: maddeler hizalı, Arapça kısımlar Arapça fontla ve
/// okunur büyüklükte.
class AiAnswerText extends StatelessWidget {
  final String text;
  final Color color;

  const AiAnswerText({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w500,
      color: color,
    );
    final arabic = ArabicTextStyles.example.copyWith(
      fontSize: 19,
      height: 1.45,
      color: color,
    );

    final lines = parseAnswer(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in lines)
          if (line.isGap)
            const SizedBox(height: 6)
          else if (line.isBullet)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Text(
                      '•',
                      style: base.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: base,
                        children: answerSpans(line.text, arabic),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Text.rich(
              TextSpan(style: base, children: answerSpans(line.text, arabic)),
            ),
      ],
    );
  }
}
