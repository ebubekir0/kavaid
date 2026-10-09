import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:isolate';

import 'package:flutter/services.dart';

import 'embedded_words_meta.dart';

export 'embedded_words_meta.dart';

/// Uygulamayla gelen sözlük verisi (assets/data/sozluk.json.gz).
///
/// Veri eskiden 37 MB'lık bir Dart sabiti olarak koda gömülüydü; her açılışta
/// tamamı belleğe yükleniyordu. Artık sıkıştırılmış bir asset olarak geliyor
/// ve yalnızca ihtiyaç olduğunda (ilk kurulum / arama izolesi) çözülüyor.
/// Veriyi güncellemek için: `python tool/build_dictionary_asset.py`
class EmbeddedWords {
  EmbeddedWords._();

  /// Sıkıştırılmış asset baytları. Ana izolede çağrılmalı (rootBundle).
  static Future<Uint8List> loadCompressed() async {
    final data = await rootBundle.load(embeddedWordsAsset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// gzip'li JSON'u kelime listesine çözer. Ağır bir iş olduğu için
  /// arka plan izolesinde çağrılmalı.
  static List<Map<String, dynamic>> decode(Uint8List compressed) {
    final text = utf8.decode(gzip.decode(compressed));
    return List<Map<String, dynamic>>.from(jsonDecode(text) as List);
  }

  /// Asset'i okur ve arka planda çözer.
  static Future<List<Map<String, dynamic>>> load() async {
    final compressed = await loadCompressed();
    return Isolate.run(() => decode(compressed));
  }
}
