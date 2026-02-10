// Firebase'den tüm kelimeleri çeken script
// Bu script Firebase'den kelime listesini indirir

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String databaseUrl = 'https://kavaid-2f778-default-rtdb.europe-west1.firebasedatabase.app';

void main() async {
  print('🔄 Firebase\'den kelime listesi çekiliyor...');
  print('📍 URL: $databaseUrl/kelimeler.json?shallow=false\n');
  
  try {
    // Tüm kelimeleri çek
    final response = await http.get(
      Uri.parse('$databaseUrl/kelimeler.json'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      
      print('✅ Toplam ${data.length} kelime indirildi.\n');
      
      // Kelime listesi (sadece kelime isimleri)
      final wordList = data.keys.toList();
      wordList.sort();
      
      // Kelime listesini dosyaya yaz
      final listFile = File('tool/firebase_word_list.txt');
      await listFile.writeAsString(wordList.join('\n'));
      print('📝 Kelime listesi tool/firebase_word_list.txt dosyasına kaydedildi.');
      
      // Tüm kelime verilerini JSON olarak kaydet
      final jsonFile = File('tool/firebase_all_words.json');
      await jsonFile.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      print('📁 Tüm kelime verileri tool/firebase_all_words.json dosyasına kaydedildi.');
      
      // İstatistikler
      print('\n📊 İSTATİSTİKLER:');
      print('   Toplam kelime: ${data.length}');
      
      // İlk 20 kelimeyi göster
      print('\n📋 İlk 20 kelime:');
      for (var i = 0; i < 20 && i < wordList.length; i++) {
        print('   ${i + 1}. ${wordList[i]}');
      }
      
    } else {
      print('❌ Hata: ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('❌ Hata: $e');
  }
}
