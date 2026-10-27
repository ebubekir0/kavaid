import 'dart:convert';
import 'dart:isolate';

import 'package:archive/archive.dart' show XZDecoder;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/embedded_words.dart';
import 'search_ranking.dart' show containsArabic, foldLatin, normalizeArabic;

/// Emsile (çekim) bölümündeki fiil anlamları sözlük dilinde.
///
/// emsile.db'deki anlamlar Türkçe. İngilizce, Endonezce, Malayca ve Urducada
/// `assets/data/lang/emsile_<dil>.json.xz` kullanılır: anlam o dilin sözlüğünde aynı
/// fiilin (yoksa masdarının ya da muzarisinin) maddesinden gelir, kartla aynıdır;
/// maddesi olmayan fiilde boş kalır (tool/i18n/build_emsile_packs.py).
/// Kendi sözlüğü olmayan arayüz dilleri İngilizce sözlükle açıldığı için İngilizceyi
/// görür; Arapça–Arapça'da anlamlar ArabicDefinitions'tan gelir.
class EmsileMeanings {
  EmsileMeanings._();

  static final EmsileMeanings instance = EmsileMeanings._();

  static const _langs = {'en', 'id', 'ms', 'ur'};

  /// Paket yüklenince artar; görünüm yeniden çizilir.
  final ValueNotifier<int> version = ValueNotifier(0);

  String? _lang;
  Map<int, List<String>> _byId = const {};
  Map<int, String> _folded = const {};
  Future<void>? _loading;

  /// Bu sözlük dilinde çekim anlamları paketten mi gelir?
  bool get usesPack => _langs.contains(EmbeddedWords.currentLang);

  /// Geçerli sözlük dilinin paketi yüklü değilse yükler (aynı anda bir kez).
  Future<void> ensureLoaded() {
    final lang = EmbeddedWords.currentLang;
    if (!_langs.contains(lang) || lang == _lang) return Future.value();
    return _loading ??= _load(lang).whenComplete(() => _loading = null);
  }

  Future<void> _load(String lang) async {
    try {
      final data = await rootBundle.load('assets/data/lang/emsile_$lang.json.xz');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final parsed = await Isolate.run(() => _decode(bytes));
      if (EmbeddedWords.currentLang != lang) return;
      _byId = parsed.$1;
      _folded = parsed.$2;
      _lang = lang;
      version.value++;
    } catch (e) {
      debugPrint('EmsileMeanings: $lang yüklenemedi: $e');
    }
  }

  static (Map<int, List<String>>, Map<int, String>) _decode(Uint8List xz) {
    final map = jsonDecode(utf8.decode(XZDecoder().decodeBytes(xz))) as Map<String, dynamic>;
    final byId = <int, List<String>>{};
    final folded = <int, String>{};
    for (final MapEntry(:key, :value) in map.entries) {
      final id = int.parse(key);
      final meanings = [for (final m in value as List) m.toString()];
      byId[id] = meanings;
      folded[id] = meanings.map(_fold).join('\n');
    }
    return (byId, folded);
  }

  static String _fold(String text) =>
      containsArabic(text) ? normalizeArabic(text) : foldLatin(text);

  /// Fiilin anlamları; paket yüklü değilse ya da fiil pakette yoksa null.
  List<String>? of(int id) => _lang == EmbeddedWords.currentLang ? _byId[id] : null;

  /// Anlamında [query] geçen fiiller, en iyi eşleşme başta: anlamın kendisi,
  /// anlamın başı, bir kelimenin başı, içinde geçen.
  List<int> search(String query, {int limit = 300}) {
    if (_lang != EmbeddedWords.currentLang) return const [];
    final q = _fold(query.trim());
    if (q.isEmpty) return const [];
    final ranked = <(int, int)>[];
    for (final MapEntry(key: id, value: text) in _folded.entries) {
      if (!text.contains(q)) continue;
      var best = 3;
      for (final m in text.split('\n')) {
        final part = m.startsWith('to ') && !q.startsWith('to ') ? m.substring(3) : m;
        final r = part == q
            ? 0
            : part.startsWith(q)
                ? 1
                : (part.contains(' $q') ? 2 : 3);
        if (r < best) best = r;
      }
      ranked.add((best, id));
    }
    ranked.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    return [for (final r in ranked.take(limit)) r.$2];
  }
}
