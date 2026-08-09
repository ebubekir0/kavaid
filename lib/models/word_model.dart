import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

import '../data/type_translations.dart';
import '../services/language_service.dart';

part 'word_model.g.dart';

@JsonSerializable()
class WordModel {
  final String kelime;
  final String? harekeliKelime;
  final String? anlam;
  final String? koku;
  final String? tip;
  final Map<String, dynamic>? dilbilgiselOzellikler;
  final Map<String, dynamic>? fiilCekimler;
  final List<Map<String, dynamic>>? ornekCumleler;
  final int? eklenmeTarihi;
  final bool bulunduMu;

  const WordModel({
    required this.kelime,
    this.harekeliKelime,
    this.anlam,
    this.koku,
    this.tip,
    this.dilbilgiselOzellikler,
    this.fiilCekimler,
    this.ornekCumleler,
    this.eklenmeTarihi,
    this.bulunduMu = true,
  });

  // Gemini API formatından WordModel oluşturma
  factory WordModel.fromJson(Map<String, dynamic> json) {
    // Eğer Gemini API formatındaysa
    if (json.containsKey('kelimeBilgisi')) {
      final bulunduMu = json['bulunduMu'] as bool? ?? false;
      
      if (!bulunduMu || json['kelimeBilgisi'] == null) {
        return WordModel(
          kelime: json['kelime']?.toString() ?? '',
          bulunduMu: false,
          anlam: 'Kelime bulunamadı',
        );
      }
      
      final kelimeBilgisi = json['kelimeBilgisi'] as Map<String, dynamic>;
      
      return WordModel(
        kelime: kelimeBilgisi['kelime']?.toString() ?? '',
        harekeliKelime: kelimeBilgisi['harekeliKelime']?.toString(),
        anlam: kelimeBilgisi['anlam']?.toString(),
        koku: kelimeBilgisi['koku']?.toString(),
        tip: kelimeBilgisi['tip']?.toString(),
        dilbilgiselOzellikler: _safeMapConvert(kelimeBilgisi['dilbilgiselOzellikler']),
        fiilCekimler: _safeMapConvert(kelimeBilgisi['fiilCekimler']),
        ornekCumleler: _safeListConvert(kelimeBilgisi['ornekCumleler']),
        eklenmeTarihi: DateTime.now().millisecondsSinceEpoch,
        bulunduMu: true,
      );
    }
    
    // Eski format (Firebase'den gelen)
    return WordModel(
      kelime: json['kelime']?.toString() ?? '',
      harekeliKelime: json['harekeliKelime']?.toString(),
      anlam: json['anlam']?.toString(),
      koku: json['koku']?.toString(),
      tip: json['tip']?.toString(),
      dilbilgiselOzellikler: _safeMapConvert(json['dilbilgiselOzellikler']),
      fiilCekimler: _safeMapConvert(json['fiilCekimler']),
      ornekCumleler: _safeListConvert(json['ornekCumleler']),
      eklenmeTarihi: _safeIntConvert(json['eklenmeTarihi']),
      bulunduMu: json['bulunduMu'] as bool? ?? true,
    );
  }

  // Güvenli Map dönüştürme
  static Map<String, dynamic>? _safeMapConvert(dynamic value) {
    if (value == null) return null;
    
    if (value is Map<String, dynamic>) {
      return value;
    }
    
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((k, v) {
        if (k != null) {
          result[k.toString()] = v;
        }
      });
      return result;
    }
    
    return null;
  }

  // Güvenli List dönüştürme
  static List<Map<String, dynamic>>? _safeListConvert(dynamic value) {
    if (value == null) return null;
    
    if (value is List<Map<String, dynamic>>) {
      return value;
    }
    
    if (value is List) {
      final result = <Map<String, dynamic>>[];
      for (final item in value) {
        if (item is Map) {
          final mapItem = <String, dynamic>{};
          (item as Map<dynamic, dynamic>).forEach((k, v) {
            if (k != null) {
              mapItem[k.toString()] = v;
            }
          });
          // Debug: Dönüşen map'i kontrol et
          if (mapItem.containsKey('arapcaCumle') || mapItem.containsKey('turkceCeviri')) {
            print(' OrnekCumle Map Dönüştürüldü: ');
            print('   arapcaCumle: ${mapItem['arapcaCumle'] ?? "NULL"}');
            print('   turkceCeviri: ${mapItem['turkceCeviri'] ?? "NULL"}'); 
          }
          result.add(mapItem);
        }
      }
      return result;
    }
    
    return null;
  }

  // Güvenli int dönüştürme
  static int? _safeIntConvert(dynamic value) {
    if (value == null) return null;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    
    return null;
  }

  Map<String, dynamic> toJson() => _$WordModelToJson(this);

  // Firebase için ekstra metod
  Map<String, dynamic> toFirebaseJson() {
    final json = toJson();
    json['eklenmeTarihi'] = DateTime.now().millisecondsSinceEpoch;
    json['searchKey'] = kelime.toLowerCase();
    return json;
  }

  // Arama skorlama için metod - sadece başlangıç eşleşmeleri
  double searchScore(String query) {
    final lowerQuery = query.toLowerCase();
    final lowerKelime = kelime.toLowerCase();
    final lowerAnlam = anlam?.toLowerCase() ?? '';
    final lowerHarekeli = harekeliKelime?.toLowerCase() ?? '';

    // Tam eşleşme - en yüksek skor
    if (lowerKelime == lowerQuery) return 1.0;
    if (lowerHarekeli == lowerQuery) return 0.95;
    
    // Anlam kontrolü - tüm anlamları kontrol et
    if (_checkMeaningMatch(lowerAnlam, lowerQuery, exact: true)) return 0.9;

    // Başlangıç eşleşmesi - sadece bunlar kabul edilir
    if (lowerKelime.startsWith(lowerQuery)) return 0.8;
    if (lowerHarekeli.startsWith(lowerQuery)) return 0.75;
    
    // Anlam başlangıç kontrolü - tüm anlamları kontrol et
    if (_checkMeaningMatch(lowerAnlam, lowerQuery, exact: false)) return 0.7;

    return 0.0;
  }

  // Anlam eşleşmesi kontrolü - tüm anlamları kontrol eder
  bool _checkMeaningMatch(String meanings, String query, {required bool exact}) {
    if (meanings.isEmpty) return false;
    
    // Anlamları ayır (virgül, noktalı virgül, satır sonu ile)
    final meaningList = meanings
        .split(RegExp(r'[,;.\n]'))
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();
    
    for (final meaning in meaningList) {
      if (exact) {
        if (meaning == query) return true;
      } else {
        if (meaning.startsWith(query)) return true;
      }
    }
    
    return false;
  }

  // Ana sözlük tek Türkçe anlam kaynağı kullanır. İngilizce/Arapça yerel
  // anlam verileri paket boyutu ve bellek maliyeti nedeniyle kaldırıldı.
  String? get localizedAnlam {
    return anlam;
  }

  // Kelime türü çıkarma (dilbilgiselOzellikler'den)
  String? get kelimeTuru {
    if (dilbilgiselOzellikler != null) {
      return dilbilgiselOzellikler!['tür'] ?? 
             dilbilgiselOzellikler!['type'] ??
             dilbilgiselOzellikler!['kelimeTuru'];
    }
    return null;
  }

  // Yerelleştirilmiş kelime türü
  String? get localizedKelimeTuru {
    final turkishType = kelimeTuru ?? tip;
    if (turkishType == null || turkishType.isEmpty) return null;
    
    final lang = LanguageService();
    final normalizedType = turkishType.toLowerCase().trim();
    
    if (lang.isEnglish) {
      return enTypeMap[normalizedType] ?? enTypeMap[turkishType] ?? turkishType;
    } else if (lang.isArabic) {
      return arTypeMap[normalizedType] ?? arTypeMap[turkishType] ?? turkishType;
    }
    
    // Türkçe için: Eğer dilbilgiselOzellikler'de tür varsa onu kullan, yoksa tip'i kullan
    if (dilbilgiselOzellikler != null) {
      final typeFromDilbilgisel = dilbilgiselOzellikler!['tür'] ?? 
                                 dilbilgiselOzellikler!['type'] ?? 
                                 dilbilgiselOzellikler!['kelimeTuru'];
      if (typeFromDilbilgisel != null && typeFromDilbilgisel.toString().isNotEmpty) {
        return typeFromDilbilgisel.toString();
      }
    }
    
    return turkishType; // Türkçe için orijinal hal
  }

  // Çoğul formu çıkarma
  String? get cogulFormu {
    if (dilbilgiselOzellikler != null) {
      return dilbilgiselOzellikler!['çoğul'] ?? 
             dilbilgiselOzellikler!['cogul'] ??
             dilbilgiselOzellikler!['plural'];
    }
    return null;
  }

  // Örnek cümleler için getter
  List<Ornek> get ornekler {
    if (ornekCumleler == null) {
      debugPrint('⚠️ WordModel.ornekler: ornekCumleler NULL - kelime: $kelime');
      return [];
    }
    
    debugPrint('📚 WordModel.ornekler: ${ornekCumleler!.length} örnek var - kelime: $kelime');
    
    return ornekCumleler!.map((ornek) {
      // Her örnek cümlenin içeriğini ve key'lerini kontrol et
      debugPrint('  🔍 Map Keys: ${ornek.keys.toList()}');
      
      // Tüm olası alan adlarını kontrol et (eski ve yeni formatlar için)
      final arapcaCumle = ornek['arapcaCumle'] ?? 
                          ornek['arapcaCümle'] ??  // Türkçe ü harfi ile (eski format)
                          ornek['arapca'] ?? 
                          '';
                          
      final turkceCeviri = ornek['turkceCeviri'] ?? 
                           ornek['turkceAnlam'] ??  // Eski format - turkceAnlam
                           ornek['turkce'] ?? 
                           '';
      
      debugPrint('  📖 arapcaCumle: "$arapcaCumle"');
      debugPrint('  📖 turkceCeviri: "$turkceCeviri"');
      
      return Ornek(
        arapcaCumle: arapcaCumle,
        turkceCeviri: turkceCeviri,
      );
    }).toList();
  }

  // Fiil çekimi için getter
  FiilCekimi? get fiilCekimi {
    if (fiilCekimler == null) return null;
    
    return FiilCekimi.fromJson(fiilCekimler!);
  }

  // Backward compatibility için eski alanlar
  String? get harekeliYazi => harekeliKelime;
  String? get kok => koku;

  String _cleanTargetText(String text, {bool removeDots = false}) {
    // Parantezleri ve içindekileri sil (iç içe parantez yok varsayarak)
    var cleaned = text.replaceAll(RegExp(r'\([^()]*\)'), '');
    if (removeDots) {
      // 3 nokta (...) ve türevlerini kaldır
      cleaned = cleaned.replaceAll(RegExp(r'\.{2,}'), '');
    }
    // Fazla boşlukları temizle
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return cleaned;
  }

  /// Sadece gerçek anlamları döndür (harfi_cer olmadan)
  String? get sadeAnlam {
    if (anlam == null || anlam!.isEmpty) return anlam;
    final rawSade = anlam!.split('||').first.trim();
    return _cleanTargetText(rawSade, removeDots: false); 
  }

  /// Harfi_cerler listesini döndür: [{harf: 'فِي', anlamlar: '...de olmak'}]
  List<Map<String, String>> get harfiCerler {
    final results = <Map<String, String>>[];
    if (anlam == null || anlam!.isEmpty) return results;
    
    final parts = anlam!.split('||');
    for (int i = 1; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.startsWith('HARFI_CER:')) {
        final content = part.substring('HARFI_CER:'.length).trim();
        final subParts = content.split('=');
        if (subParts.length == 2) {
          results.add({'harf': subParts[0].trim(), 'anlamlar': subParts[1].trim()});
        }
      }
    }

    return results;
  }
}

@JsonSerializable()
class Ornek {
  final String arapcaCumle;
  final String turkceCeviri;

  const Ornek({
    required this.arapcaCumle,
    required this.turkceCeviri,
  });

  factory Ornek.fromJson(Map<String, dynamic> json) => _$OrnekFromJson(json);

  Map<String, dynamic> toJson() => _$OrnekToJson(this);

  // Yerelleştirilmiş çeviri
  String get localizedCeviri {
    return turkceCeviri;
  }

}

@JsonSerializable()
class FiilCekimi {
  final String? mazi;
  final String? muzari;
  final String? mastar;
  final String? emir;

  const FiilCekimi({
    this.mazi,
    this.muzari,
    this.mastar,
    this.emir,
  });

  factory FiilCekimi.fromJson(Map<String, dynamic> json) =>
      _$FiilCekimiFromJson(json);

  Map<String, dynamic> toJson() => _$FiilCekimiToJson(this);
}

// Hata durumu için model
@JsonSerializable()
class WordError {
  final String message;
  final String? detail;

  const WordError({
    required this.message,
    this.detail,
  });

  factory WordError.fromJson(Map<String, dynamic> json) =>
      _$WordErrorFromJson(json);

  Map<String, dynamic> toJson() => _$WordErrorToJson(this);
} 
