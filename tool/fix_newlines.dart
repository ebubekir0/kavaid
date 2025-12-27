import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print("Usage: dart tool/fix_newlines.dart <book_id>");
    return;
  }
  final String bookId = args[0];
  final file = File('assets/books/$bookId/full_book.json');
  if (!file.existsSync()) {
      print("File not found");
      return;
  }
  final content = file.readAsStringSync();
  final data = json.decode(content);
  List<dynamic> words = data['kelimeler'];
  
  List<dynamic> newWords = [];
  
  for (int i = 0; i < words.length; i++) {
    var item = words[i];
    if (item['type'] == 'newline') {
      // Algoritma:
      // Eğer peş peşe newline varsa (double newline), bir tanesini koru.
      // Eğer tek newline varsa, sil.
      
      bool isNextNewline = (i + 1 < words.length && words[i+1]['type'] == 'newline');
      
      if (isNextNewline) {
        newWords.add(item); // Birini ekle
        // Diğerlerini atla (while loop ile tüm ardışık newline'ları tüket)
        while(i + 1 < words.length && words[i+1]['type'] == 'newline') {
            i++;
        }
      } else {
        // Tek newline -> Atla (Sil)
      }
    } else {
      newWords.add(item);
    }
  }
  
  data['kelimeler'] = newWords;
  // Pretty print ile yazalım okunabilir olsun
  file.writeAsStringSync(JsonEncoder.withIndent('    ').convert(data));
  print('Newline fix done! Total items: ${newWords.length}');
}
