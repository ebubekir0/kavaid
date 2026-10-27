import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/embedded_words.dart';
import 'app_startup_service.dart';
import 'arabic_definitions.dart';
import 'database_service.dart';

/// Sözlük (anlam) dilini değiştirir: tercihi kaydeder, arama fihristini bırakır ve açılış
/// akışını yeniden çalıştırır. Açılış akışı veri sürümünün değiştiğini görüp yerel sözlüğü
/// yeni dille kurar ("Sözlük hazırlanıyor" ekranı); uygulamayı kapatıp açmak gerekmez.
class DictionaryLanguage {
  DictionaryLanguage._();

  /// Geçerli sözlük dili; değişince uygulama ağacı yeniden kurulur (main.dart).
  static final ValueNotifier<String> current = ValueNotifier(EmbeddedWords.currentLang);

  /// Okunmuş dili [current]'e yansıtır (açılışta bir kez).
  static Future<void> load() async => current.value = await EmbeddedWords.meaningLang();

  /// [explicit] false ise kullanıcı seçmiş sayılmaz (arayüz dili değişince otomatik geçiş).
  static Future<void> change(String lang, {bool explicit = true}) async {
    final old = await EmbeddedWords.meaningLang();
    await EmbeddedWords.setMeaningLang(lang, explicit: explicit);
    if (old == lang) return;
    DatabaseService.restartSearch();
    await ArabicDefinitions.instance.initialize();
    unawaited(AppStartupService.instance.retry());
    current.value = lang;
  }

  /// Arayüz dili değişti: kullanıcı sözlük dilini kendisi seçmediyse sözlük de o dile geçer.
  static Future<void> followUiLanguage(String uiLang) async {
    if (await EmbeddedWords.isExplicit()) return;
    await change(EmbeddedWords.defaultFor(uiLang), explicit: false);
  }
}
