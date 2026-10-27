import 'package:flutter/widgets.dart';

import '../services/language_service.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Arayüz metinleri (lib/l10n/app_*.arb). BuildContext istemez; servislerden de
/// kullanılabilir. Arayüz dili değişince uygulama ağacı yeniden kurulduğu için
/// ekranlar yeni dille çizilir.
AppLocalizations get l10n {
  final locale = LanguageService().uiLocale;
  if (locale != _cachedLocale) {
    _cached = lookupAppLocalizations(locale);
    _cachedLocale = locale;
  }
  return _cached!;
}

AppLocalizations? _cached;
Locale? _cachedLocale;
