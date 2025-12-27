import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

void main() {
  final file = File('assets/books/taysir_sira/full_book.json');
  if (!file.existsSync()) return;
  
  final data = json.decode(file.readAsStringSync());
  final List<dynamic> kelimeler = data['kelimeler'] ?? [];
  
  for (var item in kelimeler) {
    if (item['type'] == 'word' && item['arapca'] != null) {
      String word = item['arapca'].toString().trim();
      final hash = md5.convert(utf8.encode(word)).toString();
      if (hash == "00364e143c9ee4078b28d9d2963ef77b") {
        print("Found matching word: $word");
      }
    }
  }
}
