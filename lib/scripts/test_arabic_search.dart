// Test script for Arabic search debugging
// Run: dart run lib/scripts/test_arabic_search.dart

import 'dart:io';

void main() {
  final testWord = 'كتب';
  
  print('🔍 Arapça arama testi: "$testWord"');
  print('');
  
  // Unicode kod noktalarını incele
  final codeUnits = testWord.codeUnits;
  final runes = testWord.runes.toList();
  
  print('📝 Karakter analizi:');
  for (int i = 0; i < testWord.length; i++) {
    final char = testWord[i];
    final codeUnit = codeUnits[i];
    final hexCode = codeUnit.toRadixString(16).toUpperCase();
    
    print('  [$i] "$char" → U+$hexCode (decimal: $codeUnit)');
  }
  
  print('');
  print('🎯 Unicode aralık kontrolleri:');
  
  // Test Unicode ranges
  final ranges = [
    {'name': 'Arapça temel (U+0600-U+06FF)', 'min': 0x0600, 'max': 0x06FF},
    {'name': 'Arapça ek (U+0750-U+077F)', 'min': 0x0750, 'max': 0x077F},
    {'name': 'Arapça genişletilmiş (U+08A0-U+08FF)', 'min': 0x08A0, 'max': 0x08FF},
    {'name': 'Arapça sunum A (U+FB50-U+FDFF)', 'min': 0xFB50, 'max': 0xFDFF},
    {'name': 'Arapça sunum B (U+FE70-U+FEFF)', 'min': 0xFE70, 'max': 0xFEFF},
  ];
  
  for (final range in ranges) {
    bool inRange = true;
    for (final codeUnit in codeUnits) {
      if (codeUnit < (range['min']! as int) || codeUnit > (range['max']! as int)) {
        inRange = false;
        break;
      }
    }
    print('  ${inRange ? "✅" : "❌"} ${range['name']}');
  }
  
  print('');
  print('🔍 SQL GLOB pattern testi:');
  
  // Test SQL GLOB patterns
  final globPatterns = [
    '*[؀-ۿ]*',  // Mevcut pattern (U+0600-U+06FF)
    '*[ؐ-ۿ]*',  // Alternatif 1
    '*[؀-ؿ]*',  // Alternatif 2
  ];
  
  for (final pattern in globPatterns) {
    print('  Pattern: $pattern');
    // GLOB pattern'i RegExp'e çevir (basit test için)
    final regexPattern = pattern.replaceAll('*', '.*');
    final regex = RegExp(regexPattern);
    final matches = regex.hasMatch(testWord);
    print('    ${matches ? "✅" : "❌"} Eşleşiyor: $matches');
  }
  
  print('');
  print('🧪 Hareke testi:');
  
  // Test with and without diacritics
  final testWords = [
    'كتب',      // Harekesiz
    'كَتَبَ',    // Harekeli
    'كِتَابٌ',   // Farklı hareke
  ];
  
  for (final word in testWords) {
    print('  Test kelime: "$word"');
    final hasDiacritics = _hasArabicDiacritics(word);
    final normalized = _removeArabicDiacritics(word);
    print('    Harekeli: $hasDiacritics');
    print('    Normalize: "$normalized"');
    print('');
  }
}

// Helper functions (DatabaseService'ten kopyalandı)
bool _hasArabicDiacritics(String text) {
  return RegExp(r'[\u064B-\u065F\u0670\u0653-\u0655]').hasMatch(text);
}

String _removeArabicDiacritics(String text) {
  return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0653-\u0655]'), '');
}
