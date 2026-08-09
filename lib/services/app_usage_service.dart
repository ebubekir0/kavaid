import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUsageService extends ChangeNotifier {
  static const String _totalUsageKey = 'total_app_usage_minutes';
  static const String _lastActiveKey = 'last_active_time';
  static const String _sessionStartKey = 'session_start_time';
  static const String _hasClickedRatingPromptKey =
      'has_clicked_rating_prompt_after_update_v1';
  static const int _ratingPromptMinMinutes = 5;

  int _totalUsageMinutes = 0;
  DateTime? _sessionStartTime;
  bool _hasClickedRatingPrompt = false;
  Timer? _updateTimer;

  static final AppUsageService _instance = AppUsageService._internal();
  factory AppUsageService() => _instance;
  AppUsageService._internal();

  int get totalUsageMinutes => _totalUsageMinutes;
  bool get shouldShowRating =>
      _totalUsageMinutes > _ratingPromptMinMinutes && !_hasClickedRatingPrompt;
  bool get hasShownRatingUI => _hasClickedRatingPrompt;

  bool get shouldShowRatingForTest => shouldShowRating;

  void _checkRatingCondition() {
    if (_sessionStartTime == null) return;

    final currentSessionMinutes = DateTime.now()
        .difference(_sessionStartTime!)
        .inMinutes;
    final totalMinutes = _totalUsageMinutes + currentSessionMinutes;

    if (totalMinutes > _ratingPromptMinMinutes && !_hasClickedRatingPrompt) {
      debugPrint('[AppUsage] Rating prompt can be shown.');
      notifyListeners();
      _updateTimer?.cancel();
      _updateTimer = null;
    }
  }

  Future<void> startSession() async {
    final prefs = await SharedPreferences.getInstance();

    _totalUsageMinutes = prefs.getInt(_totalUsageKey) ?? 0;
    _hasClickedRatingPrompt =
        prefs.getBool(_hasClickedRatingPromptKey) ?? false;

    _sessionStartTime = DateTime.now();
    await prefs.setString(
      _sessionStartKey,
      _sessionStartTime!.toIso8601String(),
    );

    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkRatingCondition();
    });

    debugPrint(
      '[AppUsage] Session started. Total usage: $_totalUsageMinutes minutes',
    );
    notifyListeners();
  }

  Future<void> endSession() async {
    if (_sessionStartTime == null) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final sessionDuration = now.difference(_sessionStartTime!).inMinutes;

    _totalUsageMinutes += sessionDuration;
    await prefs.setInt(_totalUsageKey, _totalUsageMinutes);
    await prefs.setString(_lastActiveKey, now.toIso8601String());

    debugPrint(
      '[AppUsage] Session ended. Session: $sessionDuration minutes, '
      'Total: $_totalUsageMinutes minutes',
    );

    _sessionStartTime = null;
    _updateTimer?.cancel();
    _updateTimer = null;

    notifyListeners();
  }

  Future<void> updateUsage() async {
    if (_sessionStartTime == null) return;

    final now = DateTime.now();
    final currentSessionMinutes = now.difference(_sessionStartTime!).inMinutes;
    final totalMinutes =
        (await SharedPreferences.getInstance()).getInt(_totalUsageKey) ?? 0;

    _totalUsageMinutes = totalMinutes + currentSessionMinutes;

    if (_totalUsageMinutes > _ratingPromptMinMinutes &&
        !_hasClickedRatingPrompt &&
        totalMinutes <= _ratingPromptMinMinutes) {
      debugPrint('[AppUsage] Rating prompt threshold passed.');
      notifyListeners();
    }
  }

  Future<void> markRatingPromptClicked() async {
    _hasClickedRatingPrompt = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasClickedRatingPromptKey, true);
    debugPrint('[AppUsage] Rating prompt click saved.');
    notifyListeners();
  }

  Future<void> markRatingUIShown() async {
    await markRatingPromptClicked();
  }

  Future<void> resetUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_totalUsageKey);
    await prefs.remove(_lastActiveKey);
    await prefs.remove(_sessionStartKey);
    await prefs.remove(_hasClickedRatingPromptKey);

    _totalUsageMinutes = 0;
    _hasClickedRatingPrompt = false;
    _sessionStartTime = null;

    _updateTimer?.cancel();
    _updateTimer = null;

    debugPrint('[AppUsage] Usage stats reset.');
    notifyListeners();
  }

  Future<void> setUsageTimeForTest(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    _totalUsageMinutes = minutes;
    await prefs.setInt(_totalUsageKey, minutes);

    debugPrint('[AppUsage] TEST: usage set to $minutes minutes');
    notifyListeners();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
    super.dispose();
  }
}
