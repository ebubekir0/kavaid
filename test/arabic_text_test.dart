import 'package:flutter_test/flutter_test.dart';
import 'package:kavaid/data/embedded_words.dart';
import 'package:kavaid/utils/arabic_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('formatRoot', () {
    test('bitişik kök olduğu gibi kalır', () {
      expect(formatRoot('كتب'), 'كتب');
    });

    test('harfleri boşlukla ayrılmış kök birleştirilir', () {
      expect(formatRoot('ض ب ب'), 'ضبب');
      expect(formatRoot('ه و ي'), 'هوي');
    });

    test('birden çok kök " · " ile ayrılır', () {
      expect(formatRoot('قوس مطر'), 'قوس · مطر');
      expect(formatRoot('عدد, رتب'), 'عدد · رتب');
      expect(formatRoot('جسر، طير'), 'جسر · طير');
    });

    test('harekeler silinir', () {
      expect(formatRoot('زمرّد'), 'زمرد');
      expect(formatRoot('صَبَن'), 'صبن');
    });

    test('Farsça klavye harfleri Arapçaya çevrilir', () {
      expect(formatRoot('فید'), 'فيد');
      expect(formatRoot('عیش'), 'عيش');
      expect(formatRoot('کتب'), 'كتب');
    });

    test('boş ya da yok kök için boş metin döner', () {
      expect(formatRoot(null), '');
      expect(formatRoot(''), '');
      expect(formatRoot('   '), '');
    });
  });

  test('sözlükteki tüm köklerin biçimlendirilmiş hali temiz Arapça yazıdır', () async {
    final words = await EmbeddedWords.load();
    final allowed = RegExp(r'^[ء-ي]+( · [ء-ي]+)*$');
    final bad = <String>[];
    var spacedJoined = 0;

    for (final w in words) {
      final raw = w['koku'] as String? ?? '';
      final formatted = formatRoot(raw);
      if (formatted.isEmpty) continue;
      if (!allowed.hasMatch(formatted)) bad.add('$raw -> $formatted');
      if (raw.contains(' ') && !formatted.contains(' · ')) spacedJoined++;
    }

    expect(bad, isEmpty, reason: bad.take(10).join('\n'));
    // Harfleri boşluklu yazılmış (ve artık birleştirilen) kökler gerçekten var
    expect(spacedJoined, greaterThan(50));
  });
}
