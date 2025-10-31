import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class LogEntry {
  final DateTime time;
  final String level; // info, warn, error
  final String message;
  final Object? error;
  final StackTrace? stack;

  LogEntry(this.level, this.message, {this.error, this.stack}) : time = DateTime.now();

  @override
  String toString() {
    final ts = time.toIso8601String();
    final err = error != null ? ' | error=$error' : '';
    final st = stack != null ? '\n$stack' : '';
    return '[$ts][$level] $message$err$st';
  }
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;

  LoggerService._internal();

  // Ring buffer
  static const int _maxEntries = 500;
  final List<LogEntry> _entries = <LogEntry>[];

  // Live stream for UI
  final StreamController<List<LogEntry>> _streamController =
      StreamController<List<LogEntry>>.broadcast();

  Stream<List<LogEntry>> get stream => _streamController.stream;
  List<LogEntry> get entries => List.unmodifiable(_entries);

  void _add(LogEntry entry) {
    if (_entries.length >= _maxEntries) {
      _entries.removeAt(0);
    }
    _entries.add(entry);
    if (!kReleaseMode) {
      // Konsola da bas (debug/dev)
      // ignore: avoid_print
      print(entry.toString());
    }
    _streamController.add(List.unmodifiable(_entries));
  }

  void info(String message) {
    // Crashlytics'e düşük seviye log gönder
    try { FirebaseCrashlytics.instance.log(message); } catch (_) {}
    _add(LogEntry('info', message));
  }

  void warn(String message) {
    try { FirebaseCrashlytics.instance.log('WARN: $message'); } catch (_) {}
    _add(LogEntry('warn', message));
  }

  void error(String message, {Object? error, StackTrace? stack, bool reportNonFatal = false}) {
    try {
      FirebaseCrashlytics.instance.log('ERROR: $message');
      if (reportNonFatal && error != null) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      }
    } catch (_) {}
    _add(LogEntry('error', message, error: error, stack: stack));
  }

  Future<void> setUser({required String id, String? email, String? name}) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(id);
      if (email != null) {
        FirebaseCrashlytics.instance.setCustomKey('user_email', email);
      }
      if (name != null) {
        FirebaseCrashlytics.instance.setCustomKey('user_name', name);
      }
    } catch (_) {}
  }

  void setKey(String key, Object value) {
    try { FirebaseCrashlytics.instance.setCustomKey(key, value); } catch (_) {}
  }

  void clear() {
    _entries.clear();
    _streamController.add(List.unmodifiable(_entries));
  }

  void dispose() {
    _streamController.close();
  }
}
