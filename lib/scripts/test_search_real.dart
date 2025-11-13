// Real search test script
// Run: dart run lib/scripts/test_search_real.dart

import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

Future<void> main() async {
  print('🔍 Gerçek arama testi başlatılıyor...');
  
  try {
    final dbService = DatabaseService.instance;
    final testQuery = 'كتب';
    
    print('📊 Test Query: "$testQuery"');
    print('');
    
    // Arama yap
    print('🔍 searchWords() çağrılıyor...');
    final results = await dbService.searchWords(testQuery);
    
    print('✅ Sonuç sayısı: ${results.length}');
    print('');
    
    if (results.isNotEmpty) {
      print('📝 İlk 5 sonuç:');
      for (int i = 0; i < results.length && i < 5; i++) {
        final word = results[i];
        print('  ${i+1}. "${word.kelime}" / "${word.harekeliKelime}" → "${word.anlam}"');
      }
    } else {
      print('❌ Hiç sonuç bulunamadı!');
      
      // Debug: Veritabanında kelime var mı kontrol et
      print('');
      print('🔍 Debug: Exact match testi...');
      final exactMatch = await dbService.getWordByExactMatch(testQuery);
      if (exactMatch != null) {
        print('✅ Exact match bulundu: "${exactMatch.kelime}" → "${exactMatch.anlam}"');
      } else {
        print('❌ Exact match bulunamadı');
      }
      
      // Debug: Tüm kelimeleri çek ve manuel ara
      print('');
      print('🔍 Debug: Manuel arama...');
      final allWords = await dbService.getAllWords();
      print('📊 Toplam kelime sayısı: ${allWords.length}');
      
      int foundCount = 0;
      for (final word in allWords) {
        final kelime = word.kelime;
        final harekeliKelime = word.harekeliKelime ?? '';
        
        // Basit içerme kontrolü
        if (kelime.contains(testQuery) || harekeliKelime.contains(testQuery)) {
          foundCount++;
          if (foundCount <= 3) {
            print('  Bulundu: "${word.kelime}" / "${word.harekeliKelime}" → "${word.anlam}"');
          }
        }
      }
      print('📊 Manuel aramada bulunan: $foundCount kelime');
    }
    
  } catch (e, stackTrace) {
    print('❌ Hata: $e');
    print('Stack trace: $stackTrace');
  }
}
