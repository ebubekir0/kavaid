import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('tool/cleaned_firebase_words.json');
  final data = json.decode(await file.readAsString()) as Map<String, dynamic>;
  
  final words = <String>[];
  data.forEach((id, info) {
    words.add(info['kelime'] ?? '');
  });

  final outputFile = File('tool/cleaned_unique_words_only.txt');
  await outputFile.writeAsString(words.join('\n'));
  
  print('✅ Kelime listesi tool/cleaned_unique_words_only.txt dosyasına ${words.length} kelime olarak kaydedildi.');
}
