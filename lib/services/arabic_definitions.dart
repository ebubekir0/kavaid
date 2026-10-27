import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/embedded_words.dart';
import '../models/word_model.dart';
import 'database_service.dart';

/// Arapça–Arapça maddeler (anlamlar, örnekler, harf-i cerli kullanımlar).
///
/// Madde, Arapça dil paketinden (`assets/data/lang/ar.json.xz`) sözlük kurulurken kaydın
/// `dilbilgiselOzellikler['arDef']` alanına konur (embedded_words.dart); bellekte ayrı bir
/// sözlük tutulmaz. Biçim: {"s": [[tanım, örnek]], "p": [[kalıp, anlam]]}; kartlar bunu
/// `{senses: [{d, ex, ext}], preps: [{h, m}]}` olarak okur.
class ArabicDefinitions {
  ArabicDefinitions._();

  static final ArabicDefinitions instance = ArabicDefinitions._();

  /// Anlam dili Arapçaysa true; açık kartlar değişince kendini yeniler.
  final ValueNotifier<bool> loaded = ValueNotifier(false);

  /// Tanım ve örneklerde hareke gösterilsin mi? Arapça sözlüklerdeki gibi varsayılan harekesiz;
  /// başlık kelime her zaman harekeli kalır. Profildeki «التشكيل» ayarıyla değişir.
  final ValueNotifier<bool> showTashkeel = ValueNotifier(false);

  static const _tashkeelPref = 'ar_show_tashkeel';

  // Emsile gibi yalnız harekeli başlığı bilinen yerler için (veritabanından okunur)
  final Map<String, Map<String, dynamic>?> _byHeadword = {};

  Future<void> setShowTashkeel(bool value) async {
    showTashkeel.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tashkeelPref, value);
  }

  /// Anlam dili Arapça mı?
  bool get isActive => loaded.value;

  /// Anlam diline göre etkinleşir; sözlük dili değişince yeniden çağrılır.
  Future<void> initialize() async {
    _byHeadword.clear();
    final active = await EmbeddedWords.meaningLang() == 'ar';
    if (active) {
      final prefs = await SharedPreferences.getInstance();
      showTashkeel.value = prefs.getBool(_tashkeelPref) ?? false;
    }
    loaded.value = active;
  }

  /// Kelimenin Arapça maddesi, yoksa null.
  Map<String, dynamic>? of(WordModel word) =>
      isActive ? _toEntry(word.dilbilgiselOzellikler?['arDef']) : null;

  /// Harekeli başlığa göre madde (ör. emsiledeki mazi fiil); önce [prefetchHeadwords]
  /// ile veritabanından okunmuş olmalı, yoksa null.
  Map<String, dynamic>? ofHeadword(String headword) => _byHeadword[headword];

  /// Verilen başlıkların maddelerini veritabanından okuyup [ofHeadword] için saklar.
  /// Yeni okunan varsa true döner (çağıran ekranı yenilesin).
  Future<bool> prefetchHeadwords(Iterable<String> headwords) async {
    if (!isActive) return false;
    final missing = headwords.where((h) => h.isNotEmpty && !_byHeadword.containsKey(h)).toSet();
    if (missing.isEmpty) return false;
    final found = await DatabaseService.instance.grammarByHeadwords(missing);
    for (final h in missing) {
      _byHeadword[h] = _toEntry(found[h]?['arDef']);
    }
    return true;
  }

  static Map<String, dynamic>? _toEntry(Object? raw) {
    if (raw is! Map) return null;
    return {
      'senses': [
        for (final s in raw['s'] as List? ?? const [])
          {'d': (s as List)[0], 'ex': -1, 'ext': s.length > 1 ? s[1] : ''},
      ],
      'preps': [
        for (final p in raw['p'] as List? ?? const []) {'h': (p as List)[0], 'm': p.length > 1 ? p[1] : ''},
      ],
    };
  }
}
