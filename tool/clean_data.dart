import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('tool/firebase_all_words.json');
  if (!await file.exists()) {
    print('❌ Hata: tool/firebase_all_words.json bulunamadı.');
    return;
  }

  print('🔄 Veri okunuyor ve temizleniyor...');
  final content = await file.readAsString();
  final Map<String, dynamic> data = json.decode(content);

  final Map<String, dynamic> cleanedData = {};
  final Set<String> seenHarekeli = {};
  
  int duplicateCount = 0;
  int garbageCount = 0;

  // Çöp kelime filtreleri
  final garbageKeywords = [
    'hareke işaretidir',
    'sayısal bir ifade',
    'Arapça bir kelime değil',
    'bir harf',
    'tek başına bir kelime değildir'
  ];

  data.forEach((key, value) {
    final wordInfo = value as Map<String, dynamic>;
    final String kelime = (wordInfo['kelime'] ?? '').toString().trim();
    final String harekeli = (wordInfo['harekeliKelime'] ?? '').toString().trim();
    final String anlam = (wordInfo['anlam'] ?? '').toString().toLowerCase();

    // 1. KURAL: Kelime Olmayanları Filtrele
    bool isGarbage = false;

    // Sadece sayı mı?
    if (RegExp(r'^\d+$').hasMatch(kelime) || RegExp(r'^[0-9.]+$').hasMatch(kelime)) {
      isGarbage = true;
    }
    
    // Çöp anahtar kelimeler içeriyor mu?
    for (var keyword in garbageKeywords) {
      if (anlam.contains(keyword.toLowerCase())) {
        isGarbage = true;
        break;
      }
    }

    // Çok kısa ve anlamsız mı? (Örn: tek bir hareke veya sembol)
    if (kelime.length < 2 && harekeli.isEmpty) {
      isGarbage = true;
    }

    if (isGarbage) {
      garbageCount++;
      return; // Bu kaydı atla
    }

    // 2. KURAL: Harekeli Kelime Tekrarını Engelle
    if (harekeli.isNotEmpty) {
      if (seenHarekeli.contains(harekeli)) {
        duplicateCount++;
        return; // Zaten var, atla
      }
      seenHarekeli.add(harekeli);
    }

    // Temiz veriye ekle
    cleanedData[key] = value;
  });

  // Sonuçları kaydet
  final outputFile = File('tool/cleaned_firebase_words.json');
  await outputFile.writeAsString(const JsonEncoder.withIndent('  ').convert(cleanedData));

  // Yeni kelime listesi (ID'ler)
  final listFile = File('tool/cleaned_word_list.txt');
  await listFile.writeAsString(cleanedData.keys.join('\n'));

  print('\n==================================================');
  print('📊 TEMİZLİK SONUÇLARI:');
  print('   Orijinal Kelime Sayısı: ${data.length}');
  print('   Çıkarılan Çöp Kayıtlar: $garbageCount');
  print('   Çıkarılan Tekrar Edenler: $duplicateCount');
  print('   Kalan Temiz Kelime Sayısı: ${cleanedData.length}');
  print('==================================================');
  print('✅ Temizlenmiş veri: tool/cleaned_firebase_words.json');
}
