import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_teacher_model.dart';
import '../models/word_model.dart';
import 'connectivity_service.dart';
import 'gemini_service.dart';
import 'purchase_manager.dart';
import 'package:kavaid/l10n/l10n.dart';

enum AiTeacherAccessStatus { allowed, noInternet, limitReached, unavailable }

class AiTeacherResult {
  final AiTeacherAccessStatus status;
  final AiTeacherExplanation? explanation;
  final String message;

  const AiTeacherResult({
    required this.status,
    this.explanation,
    required this.message,
  });

  bool get isSuccess => status == AiTeacherAccessStatus.allowed;
}

class AiTeacherLimitException implements Exception {
  const AiTeacherLimitException();
}

class AiTeacherService {
  static final AiTeacherService _instance = AiTeacherService._internal();
  factory AiTeacherService() => _instance;
  AiTeacherService._internal();

  static const int freeDailyLimit = 5;
  static const String _usageDateKey = 'ai_teacher_usage_date_v1';
  static const String _usageCountKey = 'ai_teacher_usage_count_v1';

  final GeminiService _geminiService = GeminiService();
  final PurchaseManager _purchaseManager = PurchaseManager();
  final Map<String, AiTeacherExplanation> _sessionCache = {};

  bool get isPremium => _purchaseManager.isPremium;

  Future<AiTeacherResult> getExplanation(WordModel word) async {
    final cacheKey = _cacheKey(word);
    final cached = _sessionCache[cacheKey];
    if (cached != null) {
      return AiTeacherResult(
        status: AiTeacherAccessStatus.allowed,
        explanation: cached,
        message: l10n.hazir,
      );
    }

    final hasInternet = await ConnectivityService().hasInternetConnection();
    if (!hasInternet) {
      return AiTeacherResult(
        status: AiTeacherAccessStatus.noInternet,
        message: l10n.aiKelimeAsistaniIcinInternet,
      );
    }

    if (!isPremium && await _isFreeLimitReached()) {
      return AiTeacherResult(
        status: AiTeacherAccessStatus.limitReached,
        message: l10n.bugunkuUcretsizAiKelimeAsistani,
      );
    }

    try {
      final explanation = await _geminiService.explainWordForTeacherMode(word);
      _sessionCache[cacheKey] = explanation;
      if (!isPremium) {
        await _incrementUsage();
      }
      return AiTeacherResult(
        status: AiTeacherAccessStatus.allowed,
        explanation: explanation,
        message: l10n.hazir,
      );
    } on GeminiApiKeyInvalidException {
      debugPrint('[AiTeacherService] invalid Gemini API key');
      return AiTeacherResult(
        status: AiTeacherAccessStatus.unavailable,
        message:
            l10n.aiOgretmenApiAnahtariGecersiz,
      );
    } catch (e) {
      debugPrint('[AiTeacherService] explanation failed: $e');
      return AiTeacherResult(
        status: AiTeacherAccessStatus.unavailable,
        message: l10n.aiKelimeAsistaniSuAnda,
      );
    }
  }

  Future<String> answerQuestion(
    WordModel word,
    String question, {
    AiTeacherExplanation? previousContext,
  }) async {
    final hasInternet = await ConnectivityService().hasInternetConnection();
    if (!hasInternet) {
      throw Exception('Internet baglantisi gerekiyor.');
    }
    if (!isPremium && await _isFreeLimitReached()) {
      throw const AiTeacherLimitException();
    }

    final answer = await _geminiService.answerTeacherQuestion(
      word,
      question,
      previousContext: previousContext,
    );
    if (!isPremium) {
      await _incrementUsage();
    }
    return answer;
  }

  Future<int> remainingFreeUses() async {
    if (isPremium) return freeDailyLimit;
    await _resetIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_usageCountKey) ?? 0;
    return (freeDailyLimit - used).clamp(0, freeDailyLimit).toInt();
  }

  Future<bool> _isFreeLimitReached() async {
    return await remainingFreeUses() <= 0;
  }

  /// Günlük hakkı tüket. AiChatService de aynı kotayı paylaşsın diye açık.
  Future<void> consumeQuota() async {
    if (isPremium) return;
    await _incrementUsage();
  }

  Future<void> _incrementUsage() async {
    await _resetIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_usageCountKey) ?? 0;
    await prefs.setInt(_usageCountKey, used + 1);
  }

  Future<void> _resetIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final savedDate = prefs.getString(_usageDateKey);
    if (savedDate != today) {
      await prefs.setString(_usageDateKey, today);
      await prefs.setInt(_usageCountKey, 0);
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String _cacheKey(WordModel word) {
    return (word.harekeliKelime?.isNotEmpty == true
            ? word.harekeliKelime!
            : word.kelime)
        .trim();
  }
}
