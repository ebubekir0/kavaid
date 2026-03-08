import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kavaid/firebase_options.dart'; // Eğer farklıysa kendi options'ınızı kullanır.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await TestAnlamUpdateScript.run();
}

class TestAnlamUpdateScript {
  static Future<void> run() async {
    debugPrint('TEST BAŞLADI: Sadece ANLAM Güncelleme');
    
    // Test amaçlı sadece 3 kelime alacağız
    final int limit = 3; 
    
    final database = FirebaseDatabase.instance;
    final kelimelerRef = database.ref('kelimeler');
    
    // limitToFirst(3) ile sadece 3 kelime çekiyoruz
    final snapshot = await kelimelerRef.limitToFirst(limit).get();
    
    if (!snapshot.exists || snapshot.value == null) {
      debugPrint('Kelimeler bulunamadı.');
      return;
    }

    final data = snapshot.value as Map<dynamic, dynamic>;
    
    // 1. Firebase API Key'i al (test için doğrudan çekiyoruz)
    final configSnapshot = await database.ref('config/gemini_api').get();
    final apiKey = configSnapshot.value?.toString() ?? '';
    if (apiKey.isEmpty) {
      debugPrint('API Anahtarı bulunamadı!');
      return;
    }

    int i = 1;
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value as Map<dynamic, dynamic>;
      final kelime = value['kelime']?.toString() ?? '';
      
      debugPrint('\n[$i/$limit] İşleniyor: $kelime');
      
      // 2. SADECE ANLAM İSTEYEN KISA PROMPT
      final String prompt = '''
Sen bir Arapça-Türkçe sözlüksün. Aşağıdaki kelimenin sadece en doğru ve güncel Türkçe anlamlarını virgülle ayırarak ver. 
Başka hiçbir açıklama, örnek cümle veya gramer bilgisi yazma. 
Sadece aşağıdaki JSON formatında çıktı ver:

Kelime: "$kelime"

{
  "kelime": "$kelime",
  "anlam": "türkçe anlamları buraya yaz"
}
''';

      // 3. Gemini 1.5 Flash'a İstek At (Test İçin 1.5 kullanıyoruz)
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
      
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'contents': [{'parts': [{'text': prompt}]}],
            'generationConfig': {
              'temperature': 0.0,
              'response_mime_type': 'application/json'
            }
          }),
        );

        if (response.statusCode == 200) {
          final resData = json.decode(response.body);
          final content = resData['candidates'][0]['content']['parts'][0]['text'];
          
          // Gelen JSON'u parse et
          final parsedJson = json.decode(content);
          final yeniAnlam = parsedJson['anlam'];
          
          debugPrint('🎯 Eski Anlam: ${value['anlam']}');
          debugPrint('✨ Yeni Anlam: $yeniAnlam');
          
          // 4. SADECE "anlam" ALANINI VERİTABANINDA GÜNCELLE
          await kelimelerRef.child(key.toString()).update({
            'anlam': yeniAnlam,
            // dilbilgiselOzellikler, ornekCumleler vs GÜNCELLENMİYOR!
            'sonAnlamGuncellemesi': DateTime.now().millisecondsSinceEpoch,
          });
          
          debugPrint('✅ Veritabanında SADECE ANLAM güncellendi!');
        } else {
          debugPrint('❌ API Hatası: ${response.body}');
        }
      } catch (e) {
        debugPrint('⚠️ Hata oluştu: $e');
      }
      
      i++;
      await Future.delayed(const Duration(seconds: 2)); // Rate limit koruması
    }
    
    debugPrint('\n🎉 TEST TAMAMLANDI!');
  }
}
