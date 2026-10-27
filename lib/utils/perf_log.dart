import 'package:flutter/foundation.dart';

/// Açılış ve arama süreleri için ölçüm kayıtları. Debug derlemede ya da
/// `--dart-define=PERF_LOG=true` verilen ölçüm derlemesinde yazılır; mağaza sürümünde susar.
/// `adb logcat | grep PERF` ile okunur.
class PerfLog {
  PerfLog._();

  static const _enabled = bool.fromEnvironment('PERF_LOG') || !kReleaseMode;
  static final Stopwatch _sinceStart = Stopwatch()..start();

  /// main() başında çağrılır; süreler buradan itibaren sayılır.
  static void start() => _sinceStart
    ..reset()
    ..start();

  static void mark(String name) => _write('$name +${_sinceStart.elapsedMilliseconds}ms');

  static void took(String name, Stopwatch sw) => _write('$name ${sw.elapsedMilliseconds}ms');

  static void note(String line) => _write(line);

  /// Ölçüm derlemesinde (`--dart-define=PERF_BENCH=true`) açılış bitince o sözlük
  /// dilinde bu aramalar yapılır ve süreleri yazılır: telefonda klavyeye dokunmadan ölçüm.
  static const bench = bool.fromEnvironment('PERF_BENCH');
  static const benchQueries = <String, List<String>>{
    'tr': ['kitap', 'su', 'yazmak', 'güzel', 'كتاب'],
    'en': ['book', 'water', 'write', 'beautiful', 'كتاب'],
    'id': ['buku', 'air', 'menulis', 'indah', 'كتاب'],
    'ms': ['buku', 'air', 'menulis', 'cantik', 'كتاب'],
    'ur': ['کتاب', 'پانی', 'لکھنا', 'خوبصورت', 'كتب'],
    'ar': ['book', 'كتاب', 'ماء', 'كتب', 'جميل'],
  };

  // Release'de debugPrint susturulduğu için doğrudan print
  // ignore: avoid_print
  static void _write(String line) => _enabled ? print('PERF $line') : null;
}
