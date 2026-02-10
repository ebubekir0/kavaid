// Firebase Realtime Database'deki kelime sayısını öğrenmek için script
// Bu scripti çalıştırmak için: dart run tool/count_words.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('🔢 Firebase kelime sayısı kontrol ediliyor...\n');
  
  // Database URL - firebase_options.dart'tan
  final databaseUrl = 'https://kavaid-2f778-default-rtdb.europe-west1.firebasedatabase.app';
  print('📍 Firebase Database URL: $databaseUrl\n');
  
  try {
    // Kelimeler node'unu shallow query ile sorgula (sadece key'leri al)
    // Bu, tüm veriyi indirmeden kelime sayısını öğrenmemizi sağlar
    final shallowUrl = '$databaseUrl/kelimeler.json?shallow=true';
    print('🌐 Shallow query yapılıyor...');
    
    final response = await http.get(Uri.parse(shallowUrl));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data == null) {
        print('📊 Veritabanında kelime bulunamadı (null)');
      } else if (data is Map) {
        final wordCount = data.length;
        print('\n' + '=' * 50);
        print('📊 TOPLAM KELİME SAYISI: $wordCount');
        print('=' * 50);
      } else {
        print('⚠️ Beklenmeyen veri formatı: ${data.runtimeType}');
      }
    } else if (response.statusCode == 401) {
      print('🔒 Yetkilendirme gerekli. Firebase kurallarını kontrol edin.');
      print('   HTTP Status: ${response.statusCode}');
      print('   Response: ${response.body}');
      
      // Alternatif: stats node'unu kontrol et
      print('\n📍 Alternatif: /stats/kelime_sayisi kontrol ediliyor...');
      final statsUrl = '$databaseUrl/stats/kelime_sayisi.json';
      final statsResponse = await http.get(Uri.parse(statsUrl));
      
      if (statsResponse.statusCode == 200) {
        final count = json.decode(statsResponse.body);
        print('\n' + '=' * 50);
        print('📊 KAYITLI KELİME SAYISI (stats): $count');
        print('=' * 50);
      } else {
        print('❌ Stats node\'u da erişilemedi: ${statsResponse.statusCode}');
      }
    } else {
      print('❌ HTTP Hatası: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Bağlantı hatası: $e');
    exit(1);
  }
  
  print('\n✅ İşlem tamamlandı.');
}
