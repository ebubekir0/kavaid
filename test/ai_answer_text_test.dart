import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/widgets/ai_answer_text.dart';

void main() {
  test('markdown temizlenir, maddeler ayrılır, fazla boş satır teke iner', () {
    final lines = parseAnswer(
      '**Kitap** demektir.\n\n\n- كِتَابٌ — kitap\n* قَلَمٌ — kalem\n## Not\n\n',
    );
    expect(lines.map((l) => l.text).toList(), [
      'Kitap demektir.',
      '',
      'كِتَابٌ — kitap',
      'قَلَمٌ — kalem',
      'Not',
    ]);
    expect(lines.map((l) => l.isBullet).toList(), [
      false,
      false,
      true,
      true,
      false,
    ]);
  });

  test('harekeli Arapça cümle tek parça olarak ayrılır', () {
    expect(arabicParts('قَرَأْتُ الْكِتَابَ — Kitabı okudum.'), [
      'قَرَأْتُ الْكِتَابَ',
    ]);
    expect(arabicParts('Sadece Türkçe.'), isEmpty);
  });

  test('Arapça kısımlar ayrı stille işaretlenir', () {
    const arabic = TextStyle(fontFamily: 'ScheherazadeNew');
    final spans = answerSpans(
      'Örnek: كِتَابٌ demek',
      arabic,
    ).cast<TextSpan>().toList();
    expect(spans.map((s) => s.text).toList(), ['Örnek: ', 'كِتَابٌ', ' demek']);
    expect(spans[1].style, arabic);
    expect(spans[0].style, isNull);
  });
}
