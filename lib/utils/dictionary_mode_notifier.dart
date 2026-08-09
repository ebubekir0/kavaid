import 'package:flutter/foundation.dart';

/// Sözlük ekranı modları
enum DictionaryMode {
  sozluk,       // Normal sözlük
  kuranSozluk,  // Kuran sözlüğü
  emsile,       // Emsile (fiil çekimleri)
  ceviri,       // Çeviri (Levanten sistemi)
}

/// Global notifier - mevcut quranModeNotifier ile birlikte çalışır
final ValueNotifier<DictionaryMode> dictionaryModeNotifier = ValueNotifier<DictionaryMode>(DictionaryMode.sozluk);

/// Emsile moduna geçerken arama tetiklemek için (format: query|timestamp)
final ValueNotifier<String> emsileSearchNotifier = ValueNotifier<String>('');
