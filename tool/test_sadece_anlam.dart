import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final kelimeler = [
    'بَحْر', 'طَرِيق', 'شَمْس', 'عَقْل', 'أُمّ'
  ];
  
  // API Anahtarı
  final apiKey = 'AIzaSyB6v5JGqHXTJ3OtmtYtkM7UGHwGMCCmDYE';

  print('========================================');
  print('  İSİM (FİİL OLMAYAN) KELİME TESTİ');
  print('========================================\n');

  for (var i = 0; i < kelimeler.length; i++) {
    final kelime = kelimeler[i];
    print('[${i+1}/5] Test Edilen Kelime: $kelime');
    
    // FINAL PROMPT
    final String prompt = '''
Sen bir Arapça-Türkçe sözlüksün. Aşağıdaki kelimenin MODERN, KLASİK ve GÜNCEL tüm anlamlarını içeren oldukça KAPSAMLI ve uzman seviyesinde bir karşılık vereceksin. 

KURALLAR:
- Anlamları en yaygın ve en alakalı olandan başlayıp az yaygın olana doğru sırala.
- Anlamları asla 1, 2, 3 gibi NUMARALANDIRMA. Sadece VİRGÜL (,) kullanarak sırayla yaz.
- Kapsam: Gerekliyse ve gerçekte varsa 30 anlama kadar çıkabilirsin.
- İSİMLER İÇİN: Kelime bir İSİM ise, harf-i cerler (edatlar) sadece o isimle kalıplaşmış çok özel bir modern/klasik tabir varsa (Örn: <blue>[على]</blue> ... gibi) eklenebilir. Yoksa sadece anlamları virgülle sıralaman yeterli.
- FİİLLER İÇİN: Varsa harf-i cerleri <blue>[harf]</blue> formatında belirt.

Başka hiçbir açıklama, örnek veya gramer bilgisi yazma. Sadece aşağıdaki JSON formatında çıktı ver:

Kelime: "$kelime"

{
  "kelime": "$kelime",
  "anlam": "Ürettiğin tüm anlam metnini buraya tek bir string olarak yaz."
}
''';

    // Model: Gemini 3 Flash Preview
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1alpha/models/gemini-3-flash-preview:generateContent?key=$apiKey');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {
             // Gemini 3 Flash için minimal temperature (0.2)
            'temperature': 0.2,
            'thinkingConfig': {
              'thinkingLevel': 'low'
            },
            'response_mime_type': 'application/json'
          }
        }),
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['candidates'] != null && resData['candidates'].isNotEmpty) {
           final content = resData['candidates'][0]['content']['parts'][0]['text'];
           
           // Temizlenmiş JSON parse (Bazen AI doğrudan düz metin string dönebilir, güvenli okuma:)
           try {
             String cleanedContent = content.toString();
             // markdown taglarını at:
             cleanedContent = cleanedContent.replaceAll(RegExp(r'```json\n?'), '').replaceAll(RegExp(r'```\n?'), '').trim();
             
             final Map<String, dynamic> parsedJson = json.decode(cleanedContent);
             final anlam = parsedJson['anlam'];
             print('✅ ÇIKTI (Anlam):\n $anlam');
           } catch (parseError) {
             print('⚠️ JSON Parse Hatası! Ham içerik (Muhtemelen JSON dönmedi):');
             print(content);
           }
        } else {
           print('❌ Candidates verisi boş geldi.');
        }
      } else {
        print('❌ Hata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('⚠️ Beklenmeyen Hata: $e');
    }
    
    print('----------------------------------------');
  }
}
