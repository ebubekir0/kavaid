import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

final List<String> books = [
  'alice_harikalar_diyarinda',
  'don_kisot',
  'oliver_twist',
  'yasli_adam_ve_deniz',
  'monte_kristo_kontu',
  'seksen_gunde_devrialem',
  'hz_musa_ve_hizirin_yolculugu',
  'kucuk_prens',
  'robinson_crusoe',
  'sherlock_holmesun_zekasi'
];

void main() async {
  print("📖 Kelime çeviri işlemi başlıyor...");

  for (var bookId in books) {
    print("\n📘 Kitap işleniyor: $bookId");
    var file = File('assets/books/$bookId/full_book.json');
    
    if (!await file.exists()) {
      print("❌ Dosya bulunamadı: $bookId");
      continue;
    }

    var content = await file.readAsString();
    Map<String, dynamic> json = jsonDecode(content);
    List<dynamic> words = json['kelimeler'];
    int count = 0;

    for (var word in words) {
      if (word['type'] == 'word') {
        String currentTurkce = word['turkce'] ?? "";
        
        // Sadece boş olanları çevir
        if (currentTurkce.trim().isEmpty) {
          String arabic = word['arapca'].toString().trim();
          // Noktalama işaretlerini temizle
          String cleanArabic = arabic.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
          
          if (cleanArabic.isNotEmpty) {
            String translation = await translateGoogle(cleanArabic);
            word['turkce'] = translation;
            count++;
            
            // İlerleme çubuğu gibi çıktı ver (her 10 kelimede bir)
            if (count % 10 == 0) stdout.write(".");
            
            // Rate limit yememek için kısa bekleme
            await Future.delayed(Duration(milliseconds: 100));
          }
        }
      }
    }

    if (count > 0) {
      // JSON'ı güncelle (Formatlı yazdırma olmadan, dosya boyutu şişmesin)
      await file.writeAsString(jsonEncode(json));
      print("\n✅ $bookId: $count kelime çevrildi ve kaydedildi.");
    } else {
      print("\n✨ $bookId: Çevrilecek yeni kelime yok.");
    }
  }
  print("\n🎉 Tüm işlemler tamamlandı!");
}

Future<String> translateGoogle(String text) async {
  try {
    var url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=ar&tl=tr&dt=t&q=${Uri.encodeComponent(text)}');
    
    var response = await http.get(url);
    
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty && data[0] is List && data[0].isNotEmpty) {
        return data[0][0][0].toString();
      }
    }
  } catch (e) {
    // Hata durumunda boş dön
  }
  return "";
}
