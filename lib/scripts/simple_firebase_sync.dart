// Firebase Realtime Database REST API kullanarak kelime verilerini çekip
// embedded_words_data.dart dosyasını günceller (Flutter bağımlılığı olmadan)

import 'dart:io';
import 'dart:convert';

const String FIREBASE_URL = 'https://kavaid-2f778-default-rtdb.europe-west1.firebasedatabase.app';

Future<void> main() async {
  print('🚀 Firebase REST API ile embedded words sync işlemi başlatılıyor...\n');
  
  try {
    // HTTP client oluştur
    final httpClient = HttpClient();
    
    print('📥 Firebase\'den kelimeler çekiliyor...');
    
    // Firebase REST API endpoint'i
    final uri = Uri.parse('$FIREBASE_URL/kelimeler.json');
    final request = await httpClient.getUrl(uri);
    final response = await request.close();
    
    if (response.statusCode != 200) {
      print('❌ Firebase\'den veri çekilemedi. Status code: ${response.statusCode}');
      return;
    }
    
    // Response'u string olarak oku
    final responseBody = await response.transform(utf8.decoder).join();
    
    // JSON parse et
    final dynamic jsonData = json.decode(responseBody);
    
    if (jsonData == null || jsonData is! Map) {
      print('❌ Firebase\'de kelime verisi bulunamadı!');
      return;
    }
    
    final data = jsonData as Map<String, dynamic>;
    final words = <Map<String, dynamic>>[];
    
    print('🔄 ${data.length} kelime işleniyor...');
    
    // Firebase verilerini embedded format'a dönüştür
    for (final entry in data.entries) {
      try {
        final key = entry.key;
        final value = entry.value;
        
        if (value != null && value is Map) {
          final wordData = Map<String, dynamic>.from(value);
          
          // Embedded format için temizle
          final cleanWordData = <String, dynamic>{
            'kelime': wordData['kelime'] ?? key,
            'harekeliKelime': wordData['harekeliKelime'] ?? key,
            'anlam': wordData['anlam'] ?? '',
            'koku': wordData['koku'] ?? '',
            'dilbilgiselOzellikler': wordData['dilbilgiselOzellikler'] ?? {},
            'ornekCumleler': wordData['ornekCumleler'] ?? [],
            'fiilCekimler': wordData['fiilCekimler'] ?? {},
            'eklenmeTarihi': wordData['eklenmeTarihi'] ?? DateTime.now().millisecondsSinceEpoch,
          };
          
          words.add(cleanWordData);
        }
      } catch (e) {
        print('⚠️ Kelime işleme hatası: $e');
        continue;
      }
    }
    
    print('✅ ${words.length} kelime işlendi');
    
    // Kelimeleri alfabetik sırala (Arapça hareke kaldırarak)
    words.sort((a, b) {
      final aKelime = _removeArabicDiacritics(a['kelime'] ?? '');
      final bKelime = _removeArabicDiacritics(b['kelime'] ?? '');
      return aKelime.compareTo(bKelime);
    });
    
    // Embedded data dosyasını oluştur
    final embeddedDataContent = _generateEmbeddedDataFile(words);
    
    // Dosyayı yaz
    final embeddedFilePath = 'lib/data/embedded_words_data.dart';
    final embeddedFile = File(embeddedFilePath);
    await embeddedFile.writeAsString(embeddedDataContent, encoding: utf8);
    
    print('✅ embedded_words_data.dart güncellendi');
    print('📁 Dosya yolu: $embeddedFilePath');
    print('📊 Toplam kelime sayısı: ${words.length}');
    print('🕒 Güncelleme zamanı: ${DateTime.now().toIso8601String()}');
    print('\n🎉 Sync işlemi başarıyla tamamlandı!');
    
    httpClient.close();
    
  } catch (e) {
    print('❌ Hata: $e');
    exit(1);
  }
}

/// Embedded data dosyasının içeriğini oluşturur
String _generateEmbeddedDataFile(List<Map<String, dynamic>> words) {
  final buffer = StringBuffer();
  final now = DateTime.now().toIso8601String();
  
  // Dosya başlığı
  buffer.writeln('// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY');
  buffer.writeln('// Generated from Firebase Realtime Database');
  buffer.writeln('// Total words: ${words.length}');
  buffer.writeln('// Generated on: $now');
  buffer.writeln();
  buffer.writeln('const embeddedWordsData = <Map<String, dynamic>>[');
  buffer.writeln();
  
  // Her kelime için
  for (int i = 0; i < words.length; i++) {
    final word = words[i];
    final harekeliKelime = word['harekeliKelime'] ?? word['kelime'] ?? '';
    final anlam = word['anlam'] ?? '';
    
    // Kelime yorumu
    buffer.writeln('  // $harekeliKelime - $anlam');
    
    // JSON formatı
    final jsonStr = const JsonEncoder().convert(word);
    buffer.writeln('  $jsonStr${i < words.length - 1 ? ',' : ''}');
    
    // Son kelime değilse boş satır ekle
    if (i < words.length - 1) {
      buffer.writeln();
    }
  }
  
  buffer.writeln();
  buffer.writeln('];');
  buffer.writeln();
  
  return buffer.toString();
}

/// Arapça harekelerini kaldırır (normalizasyon için)
String _removeArabicDiacritics(String text) {
  // Arapça harekeler: َ ِ ُ ً ٌ ٍ ّ ْ ٓ ٰ ٔ ٕ
  return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0653-\u0655]'), '');
}
