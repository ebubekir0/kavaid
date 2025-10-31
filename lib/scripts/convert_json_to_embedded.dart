// Script to convert Firebase JSON export to embedded Dart data
// Run: dart lib/scripts/convert_json_to_embedded.dart

import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  try {
    print('🔄 JSON dosyası okunuyor...');
    
    // JSON dosyasını oku
    final jsonFile = File(r'C:\Users\kul\Desktop\kavaid1111\kavaid\assets\kavaid-2f778-default-rtdb-export (10).json');
    
    if (!await jsonFile.exists()) {
      print('❌ JSON dosyası bulunamadı!');
      return;
    }
    
    final jsonContent = await jsonFile.readAsString();
    final data = json.decode(jsonContent) as Map<String, dynamic>;
    
    // Kelimeler kısmını al
    final kelimelerMap = data['kelimeler'] as Map<String, dynamic>?;
    
    if (kelimelerMap == null) {
      print('❌ "kelimeler" anahtarı bulunamadı!');
      return;
    }
    
    print('✅ ${kelimelerMap.length} kelime bulundu');
    print('🔄 Embedded data dosyası oluşturuluyor...');
    
    // Dart dosyası oluştur
    final outputFile = File(r'C:\Users\kul\Desktop\kavaid1111\kavaid\lib\data\embedded_words_data.dart');
    final sink = outputFile.openWrite();
    
    // Dosya başlığı
    sink.writeln('// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY');
    sink.writeln('// Generated from Firebase JSON export');
    sink.writeln('// Total words: ${kelimelerMap.length}');
    sink.writeln('');
    sink.writeln('const embeddedWordsData = <Map<String, dynamic>>[');
    
    int count = 0;
    int errorCount = 0;
    
    // Her kelimeyi işle
    for (final entry in kelimelerMap.entries) {
      try {
        final wordData = entry.value as Map<String, dynamic>;
        
        // Sadece gerekli alanları al
        final wordMap = <String, dynamic>{
          'kelime': wordData['kelime'] ?? wordData['searchKey'] ?? '',
          'harekeliKelime': wordData['harekeliKelime'] ?? wordData['kelime'] ?? '',
          'anlam': wordData['anlam'] ?? '',
          'koku': wordData['koku'] ?? wordData['kok'] ?? '',
        };
        
        // Dilbilgisel özellikler
        if (wordData['dilbilgiselOzellikler'] != null) {
          wordMap['dilbilgiselOzellikler'] = wordData['dilbilgiselOzellikler'];
        }
        
        // Örnek cümleler
        if (wordData['ornekCumleler'] != null) {
          final ornekler = wordData['ornekCumleler'];
          if (ornekler is List && ornekler.isNotEmpty) {
            wordMap['ornekCumleler'] = ornekler.map((ornek) {
              if (ornek is Map) {
                return {
                  'arapcaCumle': ornek['arapcaCümle'] ?? ornek['arapcaCumle'] ?? '',
                  'turkceCeviri': ornek['turkceAnlam'] ?? ornek['turkceCeviri'] ?? '',
                };
              }
              return ornek;
            }).toList();
          }
        }
        
        // Fiil çekimleri
        if (wordData['fiilCekimler'] != null) {
          wordMap['fiilCekimler'] = wordData['fiilCekimler'];
        }
        
        // Kelime boş değilse ekle
        if (wordMap['kelime'].toString().isNotEmpty) {
          // JSON formatında yaz
          sink.writeln('  ${_formatJson(wordMap)},');
          count++;
          
          if (count % 1000 == 0) {
            print('  ✓ $count kelime işlendi...');
          }
        }
        
      } catch (e) {
        errorCount++;
        if (errorCount <= 10) {
          print('  ⚠️ Kelime işleme hatası: ${entry.key} - $e');
        }
      }
    }
    
    // Dosya sonu
    sink.writeln('];');
    await sink.close();
    
    print('');
    print('✅ Embedded data dosyası oluşturuldu!');
    print('📊 İstatistikler:');
    print('   - Toplam kelime: ${kelimelerMap.length}');
    print('   - İşlenen kelime: $count');
    print('   - Hata sayısı: $errorCount');
    print('📁 Dosya: ${outputFile.path}');
    print('📦 Dosya boyutu: ${(await outputFile.length() / 1024 / 1024).toStringAsFixed(2)} MB');
    
  } catch (e, stackTrace) {
    print('❌ Hata: $e');
    print('Stack trace: $stackTrace');
  }
}

// JSON formatında string oluştur
String _formatJson(Map<String, dynamic> map) {
  final buffer = StringBuffer('{');
  final entries = <String>[];
  
  map.forEach((key, value) {
    if (value != null) {
      entries.add("'$key': ${_formatValue(value)}");
    }
  });
  
  buffer.write(entries.join(', '));
  buffer.write('}');
  
  return buffer.toString();
}

// Değeri formatla
String _formatValue(dynamic value) {
  if (value == null) return 'null';
  
  if (value is String) {
    // String içindeki özel karakterleri escape et
    final escaped = value
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
    return "'$escaped'";
  }
  
  if (value is num || value is bool) {
    return value.toString();
  }
  
  if (value is List) {
    final items = value.map((item) => _formatValue(item)).join(', ');
    return '[$items]';
  }
  
  if (value is Map) {
    final entries = <String>[];
    value.forEach((k, v) {
      if (v != null) {
        entries.add("'$k': ${_formatValue(v)}");
      }
    });
    return '{${entries.join(', ')}}';
  }
  
  return 'null';
}
