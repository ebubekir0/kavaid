// Mevcut kelime listesini çıkaran script
// Bu script embedded_words_data.dart dosyasından kelime isimlerini çıkarır

import 'dart:io';

void main() async {
  final embeddedFile = File('lib/data/embedded_words_data.dart');
  final content = await embeddedFile.readAsString();
  
  // Kelime regex pattern
  final regex = RegExp(r'"kelime"\s*:\s*"([^"]+)"');
  final matches = regex.allMatches(content);
  
  final words = <String>[];
  for (final match in matches) {
    final word = match.group(1);
    if (word != null && word.isNotEmpty) {
      words.add(word);
    }
  }
  
  print('Toplam kelime sayısı: ${words.length}');
  
  // Kelime listesini dosyaya yaz
  final outputFile = File('tool/word_list.txt');
  await outputFile.writeAsString(words.join('\n'));
  
  print('Kelime listesi tool/word_list.txt dosyasına kaydedildi.');
  
  // İlk 100 kelimeyi göster
  print('\nİlk 100 kelime:');
  for (var i = 0; i < 100 && i < words.length; i++) {
    print('${i + 1}. ${words[i]}');
  }
}
