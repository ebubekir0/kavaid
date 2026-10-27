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

  // Release'de debugPrint susturulduğu için doğrudan print
  // ignore: avoid_print
  static void _write(String line) => _enabled ? print('PERF $line') : null;
}
