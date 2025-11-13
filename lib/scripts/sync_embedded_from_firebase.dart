// Firebase Realtime Database'den güncel kelime verilerini çekip
// embedded_words_data.dart dosyasını otomatik günceller

import 'dart:io';
import 'dart:convert';
import '../services/firebase_service.dart';
import '../models/word_model.dart';

Future<void> main() async {
  print('🚀 Firebase\'den embedded words sync işlemi başlatılıyor...\n');
  
  try {
    // Firebase servisini kullan (zaten yapılandırılmış)
    final firebaseService = FirebaseService();
    
    // Bağlantı testi
    final isConnected = await firebaseService.testConnection();
    if (!isConnected) {
      print('❌ Firebase bağlantısı kurulamadı!');
      return;
    }
    print('✅ Firebase bağlantısı kuruldu');
    
    print('📥 Firebase\'den tüm kelimeler çekiliyor...');
    final List<WordModel> firebaseWords = await firebaseService.getAllWordsFromFirebase();
    
    if (firebaseWords.isEmpty) {
      print('❌ Firebase\'de kelime bulunamadı!');
      return;
    }
    
    print('🔄 Kelimeler işleniyor...');
    
    // WordModel'lerden Map<String, dynamic> formatına dönüştür
    final words = <Map<String, dynamic>>[];
    
    for (final word in firebaseWords) {
      try {
        // WordModel'den embedded format'a dönüştür
        final cleanWordData = <String, dynamic>{
          'kelime': word.kelime,
          'harekeliKelime': word.harekeliKelime ?? word.kelime,
          'anlam': word.anlam ?? '',
          'koku': word.koku ?? '',
          'dilbilgiselOzellikler': word.dilbilgiselOzellikler ?? {},
          'ornekCumleler': word.ornekCumleler ?? [],
          'fiilCekimler': word.fiilCekimler ?? {},
          'eklenmeTarihi': word.eklenmeTarihi ?? DateTime.now().millisecondsSinceEpoch,
        };
        
        words.add(cleanWordData);
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
