import 'dart:convert';
import 'dart:isolate';

import 'package:archive/archive.dart' show XZDecoder;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/language_service.dart';
import 'embedded_words_meta.dart';
import 'lang_packs_meta.dart';

export 'embedded_words_meta.dart';

/// Uygulamayla gelen sözlük verisi.
///
/// Temel: `assets/data/sozluk.json.xz` (Arapça alanlar + Türkçe anlamlar; yalnız sözlük
/// sürümü değişince çözülür, her açılışta değil). Anlam dili
/// Türkçe değilse o dilin paketi (`assets/data/lang/<dil>.json.xz`, aynı kayıt sırasında)
/// temel verinin üzerine uygulanır: anlam ve örnek çevirileri o dile geçer; Arapça–Arapça'da
/// anlam İngilizce kalır, Arapça madde `dilbilgiselOzellikler['arDef']` içine konur.
/// Veri sürümü dille birlikte değiştiği için dil değişince yerel sözlük ve arama fihristi
/// o dille yeniden kurulur. Veriyi güncellemek: `tool/build_dictionary_asset.py`,
/// dil paketleri: `tool/i18n/build_lang_packs.py`.
class EmbeddedWords {
  EmbeddedWords._();

  static const String meaningLangKey = 'meaning_lang';
  static const String _explicitKey = 'meaning_lang_explicit';

  /// Test derlemesinin varsayılan anlam dili: `--dart-define=MEANING_LANG=en`.
  static const String _forcedMeaningLang = String.fromEnvironment('MEANING_LANG');

  /// Profil ekranındaki test seçicisi gösterilsin mi (test derlemesi).
  static const bool meaningLangSelectable = bool.hasEnvironment('MEANING_LANG');

  /// Seçilebilen anlam dilleri: Türkçe (yerleşik) + uygulamadaki paketler.
  static List<String> get availableLangs => ['tr', ...langPacks.keys];

  static String? _current;

  /// Son okunan anlam dili (senkron erişim; [meaningLang] en az bir kez çağrıldıktan sonra).
  static String get currentLang => _current ?? defaultFor(LanguageService().uiLocale.languageCode);

  /// Arayüz diline göre varsayılan anlam dili: o dilin paketi varsa o, Türkçe ise Türkçe,
  /// sözlüğü olmayan dillerde İngilizce.
  static String defaultFor(String uiLang) {
    if (_forcedMeaningLang.isNotEmpty) return _forcedMeaningLang;
    if (uiLang == 'tr') return 'tr';
    return langPacks.containsKey(uiLang) ? uiLang : 'en';
  }

  static Future<String> meaningLang() async {
    final saved = (await SharedPreferences.getInstance()).getString(meaningLangKey);
    final lang = saved != null && availableLangs.contains(saved)
        ? saved
        : defaultFor(LanguageService().uiLocale.languageCode);
    return _current = lang;
  }

  /// Kullanıcı sözlük dilini kendisi seçtiyse true; seçmediyse arayüz dili değişince
  /// sözlük dili de onu izler.
  static Future<bool> isExplicit() async =>
      (await SharedPreferences.getInstance()).getBool(_explicitKey) ?? false;

  static Future<void> setMeaningLang(String lang, {bool explicit = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(meaningLangKey, lang);
    if (explicit) await prefs.setBool(_explicitKey, true);
    _current = lang;
  }

  /// Seçili anlam dilinin veri sürümü. Dil değişince sürüm de değiştiği için
  /// yerel sözlük açılışta o dilin verisiyle yeniden kurulur.
  static Future<String> currentVersion() async {
    final lang = await meaningLang();
    final pack = langPacks[lang];
    if (pack == null) return embeddedWordsVersion;
    final en = lang == 'ar' ? '_${langPacks['en']!.version}' : '';
    return '${embeddedWordsVersion}_${lang}_${pack.version}$en';
  }

  static Future<Uint8List> _asset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Sözlüğün ham baytları: temel veri + seçili dilin paketi (Arapçada İngilizce de).
  /// Ana izolede çağrılmalı (rootBundle); çözme işi [decode] ile arka planda yapılır.
  static Future<List<Object?>> loadSources() async {
    final lang = await meaningLang();
    final base = await _asset(embeddedWordsAsset);
    if (lang == 'tr' || !langPacks.containsKey(lang)) return [lang, base, null, null];
    final pack = await _asset(langPacks[lang]!.asset);
    final en = lang == 'ar' ? await _asset(langPacks['en']!.asset) : null;
    return [lang, base, pack, en];
  }

  /// [loadSources] çıktısını kelime listesine çözer. Ağır bir iş olduğu için arka plan
  /// izolesinde çağrılmalı.
  static List<Map<String, dynamic>> decode(List<Object?> sources) {
    final lang = sources[0] as String;
    final words = List<Map<String, dynamic>>.from(
      jsonDecode(utf8.decode(XZDecoder().decodeBytes(sources[1] as Uint8List))) as List,
    );
    final pack = sources[2] as Uint8List?;
    if (pack == null) return words;
    final en = sources[3] as Uint8List?;
    if (lang == 'ar') {
      if (en != null) _applyTranslations(words, _decodePack(en));
      _applyArabic(words, _decodePack(pack));
    } else {
      _applyTranslations(words, _decodePack(pack));
    }
    return words;
  }

  static List<dynamic> _decodePack(Uint8List xz) =>
      jsonDecode(utf8.decode(XZDecoder().decodeBytes(xz))) as List<dynamic>;

  /// Çeviri dili: [anlam, [örnek çevirileri]]. Sonucu olmayan kayıt Türkçe kalır.
  static void _applyTranslations(List<Map<String, dynamic>> words, List<dynamic> items) {
    for (var i = 0; i < words.length && i < items.length; i++) {
      final item = items[i];
      if (item is! List) continue;
      final word = words[i];
      word['anlam'] = item[0] as String;
      final translations = item[1] as List;
      final examples = <Map<String, dynamic>>[];
      var j = 0;
      for (final o in word['ornekCumleler'] as List? ?? const []) {
        if (o is! Map || j >= translations.length) continue;
        examples.add({
          'arapcaCumle': o['arapcaCümle'] ?? o['arapcaCumle'] ?? '',
          'turkceCeviri': translations[j++] as String,
        });
      }
      word['ornekCumleler'] = examples;
    }
  }

  /// Arapça–Arapça madde: {"s": [[tanım, örnek]], "p": [[kalıp, anlam]]}.
  static void _applyArabic(List<Map<String, dynamic>> words, List<dynamic> items) {
    for (var i = 0; i < words.length && i < items.length; i++) {
      final item = items[i];
      if (item is! Map) continue;
      final word = words[i];
      final gram = Map<String, dynamic>.from(word['dilbilgiselOzellikler'] as Map? ?? const {});
      gram['arDef'] = item;
      word['dilbilgiselOzellikler'] = gram;
    }
  }

  /// Sözlüğü okur ve arka planda çözer.
  static Future<List<Map<String, dynamic>>> load() async {
    final sources = await loadSources();
    return Isolate.run(() => decode(sources));
  }
}
