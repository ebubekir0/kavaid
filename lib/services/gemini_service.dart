import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import '../models/ai_teacher_model.dart';
import '../models/word_model.dart';
import 'api_keys.dart';
import 'dart:math' as math;

class GeminiApiKeyInvalidException implements Exception {
  const GeminiApiKeyInvalidException();
}

class GeminiService {
  static const String _defaultModel = 'gemini-3.1-flash-lite';
  static const String _defaultPrompt =
      '''YAPAY ZEKA İÇİN GÜNCEL VE KESİN TALİMATLAR

Sen bir Arapça sözlük uygulamasısın. Kullanıcıdan Arapça veya Türkçe bir kelime al ve gramer özelliklerini dikkate alarak detaylı bir tarama yap.
Sadece kesin olarak bildiğin ve doğrulayabildiğin bilgileri sun. 
Bilmediğin veya emin olmadığın hiçbir bilgiyi uydurma ya da tahmin etme. Çıktıyı aşağıdaki JSON formatında üret.

Genel Kurallar
JSON Formatı: Çıktı, belirtilen JSON yapısına tam uymalıdır.

eğer kullanıcı türkçe bir kelime girerse bu kelimenin gramer yapısına çok dikkat et arapça gramerinde ve  çevir ve öyle devam et.
anlam kısmında girilen türkçe kelimeyide ver.
aranan türkçe kelimenin mazi müzari mastar olarak arapça korşlığını en doğru oalrak ver
Harekeler: kelime ve koku alanları harekesiz, diğer tüm Arapça kelimeler tam harekeli (vokalize edilmiş) olmalıdır.
Boş Bırakma: Bilgi yoksa veya alan uygulanamıyorsa, ilgili alanlar "" (boş string) veya [] (boş dizi) olmalıdır. Asla uydurma bilgi ekleme.
Hata Durumu: Kelime bulunamazsa veya dilbilgisel olarak anlaşılamazsa, bulunduMu alanını false yap, kelimeBilgisi alanını null bırak.
Örnek Cümleler: ornekCumleler dizisi, iki adet orta uzunlukta ve orta zorlukta cümle içermelidir.
genel yapı: veriler kısa, öz, resmi ve net olmalıdır. Parantezli ek açıklamalar veya gayri resmi ifadeler kullanılmamalıdır.
dikkat: parantez kullanılmamalı.

Kelime: "{KELIME}"

{
  "bulunduMu": true,
  "kelimeBilgisi": {
    "kelime": "تهنئة",
    "harekeliKelime": "تَهْنِئَةٌ",
    "anlam": "Tebrik, kutlama",
    "koku": "هنا",
    "dilbilgiselOzellikler": {
      "tur": "Mastar",
      "cogulForm": "تَهَانِئُ"
    },
    "ornekCumleler": [
      {
        "arapcaCumle": "أَرْسَلْتُ تَهْنِئَةً بِالنَّجَاحِ.",
        "turkceCeviri": "Başarı için tebrik mesajı gönderdim."
      },
      {
        "arapcaCumle": "تَلَقَّيْتُ تَهْنِئَةً بِالْعِيدِ.",
        "turkceCeviri": "Bayram tebriği aldım."
      }
    ],
    "fiilCekimler": {
      "maziForm": "هَنَّأَ",
      "muzariForm": "يُهَنِّئُ",
      "mastarForm": "تَهْنِئَةٌ",
      "emirForm": "هَنِّئْ"
    }
  }
}

JSON Alanlarının Tanımı:
bulunduMu (boolean): Kelimenin sözlükte bulunup bulunmadığını gösterir.
kelimeBilgisi (object | null): Kelimeye ait tüm bilgiler.
kelime (string): Kullanıcının girdiği kelime (harekesiz).
harekeliKelime (string): Kelimenin tam harekeli hali.
anlam (string): Türkçe anlam(lar).
koku (string): Kelimenin kökü (harekesiz).
dilbilgiselOzellikler (object):
  tur (string): Kelimenin türü (ör. İsim, Fiil, Mastar).
  cogulForm (string): İsimse tam harekeli çoğul hali.
ornekCumleler (array of object): İki örnek cümle.
  arapcaCumle (string): Tam harekeli Arapça cümle.
  turkceCeviri (string): Cümlenin Türkçe çevirisi.
fiilCekimler (object): Fiilse çekimler.
  maziForm, muzariForm, mastarForm, emirForm (string): İlgili fiil çekimleri.
''';

  // Singleton pattern
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Public initializer, main.dart'tan çağrılacak
  Future<void> initialize() async {
    await _initializeFirebaseConfig();
  }

  // Firebase config durumu
  bool _isConfigInitialized = false;
  int _adCooldownSeconds = 60; // Varsayılan değer
  int _firstAdDelaySeconds = 90; // İlk interstitial için varsayılan gecikme
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Dışarıdan erişim için public getter
  int get adCooldownSeconds => _adCooldownSeconds;
  int get firstAdDelaySeconds => _firstAdDelaySeconds;

  // Firebase config'i initialize et ve validate et
  Future<void> _initializeFirebaseConfig() async {
    if (_isConfigInitialized) return;

    debugPrint('🔧 Firebase config initialization başlatılıyor...');

    try {
      await _createConfigInDatabase();
      await _validateConfig();
      _isConfigInitialized = true;
      debugPrint('✅ Firebase config başarıyla initialize edildi');
    } catch (e) {
      debugPrint('❌ Firebase config initialization hatası: $e');
      // Hata durumunda da devam et ama flag'i false bırak
    }
  }

  // Config'in valid olup olmadığını kontrol et
  Future<void> _validateConfig() async {
    debugPrint('🔍 Firebase config validation başlatılıyor...');

    try {
      // API key kontrolü
      final apiKey = await _getApiKey();
      if (apiKey.isEmpty || apiKey == 'null') {
        throw Exception('API key boş veya geçersiz');
      }

      // Model kontrolü
      final model = await _getModel();
      if (model.isEmpty || model == 'null') {
        throw Exception('Model boş veya geçersiz');
      }

      // Prompt kontrolü
      final prompt = await _getPrompt();
      if (prompt.isEmpty || prompt.length < 100) {
        throw Exception('Prompt boş veya çok kısa');
      }

      // Reklam süresi kontrolü
      _adCooldownSeconds = await _getAdCooldown();
      _firstAdDelaySeconds = await _getFirstAdDelay();

      debugPrint('✅ Firebase config validation başarılı');
      debugPrint('   API Key: ${apiKey.length} karakter');
      debugPrint('   Model: $model');
      debugPrint('   Prompt: ${prompt.length} karakter');
      debugPrint('   Ad Cooldown: $_adCooldownSeconds saniye');
      debugPrint('   First Ad Delay: $_firstAdDelaySeconds saniye');
    } catch (e) {
      debugPrint('❌ Firebase config validation hatası: $e');
      rethrow;
    }
  }

  // Retry mekanizması ile API key al
  Future<String> _getApiKey() => ApiKeys.gemini();

  // Retry mekanizması ile model al
  Future<String> _getModel() async {
    return await _getConfigWithRetry('gemini_model');
  }

  // Retry mekanizması ile prompt al
  Future<String> _getPrompt() async {
    try {
      final remotePrompt = await _getConfigWithRetry('gemini_prompt');
      // Firebase'den gelen prompt'ta yanlış alan adları varsa düzelt
      String correctedPrompt = remotePrompt;

      // Yanlış alan adlarını doğrularıyla değiştir
      correctedPrompt = correctedPrompt.replaceAll(
        '"arapcaCümle"',
        '"arapcaCumle"',
      );
      correctedPrompt = correctedPrompt.replaceAll(
        '"turkceAnlam"',
        '"turkceCeviri"',
      );

      // Düzeltilmiş prompt'u döndür
      return correctedPrompt;
    } catch (e) {
      debugPrint(
        '⚠️ Firebase prompt alınamadı, varsayılan prompt kullanılacak',
      );
      return _defaultPrompt;
    }
  }

  // Retry mekanizması ile reklam süresini al
  Future<int> _getAdCooldown() async {
    final valueStr = await _getConfigWithRetry('ad_cooldown_seconds');
    debugPrint(
      'ℹ️ [GeminiService] Firebase\'den okunan "ad_cooldown_seconds" ham değeri: "$valueStr"',
    );
    final intValue = int.tryParse(valueStr);
    if (intValue == null) {
      debugPrint(
        '⚠️ [GeminiService] "ad_cooldown_seconds" değeri sayıya çevrilemedi. Güvenlik için 60sn kullanılıyor.',
      );
      return 60;
    }
    debugPrint(
      '✅ [GeminiService] "ad_cooldown_seconds" başarıyla parse edildi: $intValue saniye.',
    );
    return intValue;
  }

  // Retry mekanizması ile ilk reklam gecikmesini al
  Future<int> _getFirstAdDelay() async {
    final valueStr = await _getConfigWithRetry('first_ad_delay_seconds');
    debugPrint(
      'ℹ️ [GeminiService] Firebase\'den okunan "first_ad_delay_seconds" ham değeri: "$valueStr"',
    );
    final intValue = int.tryParse(valueStr);
    if (intValue == null) {
      debugPrint(
        '⚠️ [GeminiService] "first_ad_delay_seconds" değeri sayıya çevrilemedi. Varsayılan 90sn kullanılacak.',
      );
      return 90;
    }
    debugPrint(
      '✅ [GeminiService] "first_ad_delay_seconds" başarıyla parse edildi: $intValue saniye.',
    );
    return intValue;
  }

  // Retry mekanizması ile config değeri al
  Future<String> _getConfigWithRetry(String configKey) async {
    for (int i = 0; i < _maxRetries; i++) {
      DataSnapshot snapshot;
      try {
        debugPrint(
          '🔄 Firebase config okunuyor (${i + 1}/$_maxRetries): $configKey',
        );

        final database = FirebaseDatabase.instance;
        final configRef = database.ref('config/$configKey');
        snapshot = await configRef.get();
      } catch (e) {
        debugPrint(
          '❌ Firebase ağ hatası (${i + 1}/$_maxRetries): $configKey - $e',
        );
        if (i < _maxRetries - 1) {
          debugPrint(
            '🔄 ${_retryDelay.inSeconds} saniye beklenip tekrar denenecek...',
          );
          await Future.delayed(_retryDelay);
          continue; // Sonraki denemeye geç
        } else {
          // Bu son deneme, ağ hatasıyla ilgili kesin bir hata fırlat.
          throw Exception(
            'Firebase config okunamadı ($configKey) ve tüm ağ denemeleri başarısız oldu: $e',
          );
        }
      }

      // Ağ isteği başarılı, şimdi veriyi kontrol et.
      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value.toString().trim();
        if (value.isNotEmpty && value != 'null') {
          debugPrint('✅ Firebase config başarıyla okundu: $configKey');
          return value; // Başarılı, değeri döndür.
        } else {
          // Değer boş, bu bir konfigürasyon hatası. Yeniden deneme yok.
          throw Exception(
            'Firebase config değeri boş veya geçersiz: $configKey',
          );
        }
      } else {
        // Anahtar bulunamadı, bu bir konfigürasyon hatası. Yeniden deneme yok.
        throw Exception('Firebase config anahtarı bulunamadı: $configKey');
      }
    }
    // Bu kod normalde ulaşılamaz olmalı.
    throw Exception(
      'Beklenmedik durum: _getConfigWithRetry döngüsü tamamlandı.',
    );
  }

  // Config alanını database'de oluştur (geliştirilmiş)
  Future<void> _createConfigInDatabase() async {
    try {
      debugPrint('🔧 Firebase config kontrolü yapılıyor...');

      final database = FirebaseDatabase.instance;
      final configRef = database.ref('config');

      // Config alanının var olup olmadığını kontrol et
      final snapshot = await configRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final configData = snapshot.value as Map<dynamic, dynamic>;

        // Eksik alanları kontrol et ve ekle
        final updates = <String, dynamic>{};

        if (!configData.containsKey('gemini_api') ||
            configData['gemini_api'] == null ||
            configData['gemini_api'] == '') {
          // API anahtarı boş bırakılacak, Firebase Console'dan manuel eklenecek
          updates['gemini_api'] = '';
          debugPrint(
            '📝 gemini_api alanı boş olarak eklenecek - Firebase Console\'dan manuel ekleyin',
          );
        }

        if (!configData.containsKey('gemini_model') ||
            configData['gemini_model'] == null) {
          updates['gemini_model'] = _defaultModel;
          debugPrint('📝 gemini_model alanı eklenecek');
        }

        if (!configData.containsKey('gemini_prompt') ||
            configData['gemini_prompt'] == null) {
          updates['gemini_prompt'] = _defaultPrompt;
          debugPrint('📝 gemini_prompt alanı eklenecek');
        }

        // Reklamla ilgili ayarlar
        if (!configData.containsKey('ad_cooldown_seconds') ||
            configData['ad_cooldown_seconds'] == null) {
          updates['ad_cooldown_seconds'] = _adCooldownSeconds;
          debugPrint(
            '📝 ad_cooldown_seconds alanı eklenecek (varsayılan: $_adCooldownSeconds)',
          );
        }
        if (!configData.containsKey('first_ad_delay_seconds') ||
            configData['first_ad_delay_seconds'] == null) {
          updates['first_ad_delay_seconds'] = _firstAdDelaySeconds;
          debugPrint(
            '📝 first_ad_delay_seconds alanı eklenecek (varsayılan: $_firstAdDelaySeconds)',
          );
        }

        if (updates.isNotEmpty) {
          await configRef.update(updates);
          debugPrint(
            '✅ Eksik config alanları güncellendi: ${updates.keys.join(', ')}',
          );
        } else {
          debugPrint('✅ Tüm config alanları mevcut');
        }
      } else {
        // Config alanı hiç yoksa tamamen oluştur
        await configRef.set({
          'gemini_api': '', // Firebase Console'dan manuel eklenecek
          'gemini_model': _defaultModel,
          'gemini_prompt': _defaultPrompt,
          'ad_cooldown_seconds': _adCooldownSeconds,
          'first_ad_delay_seconds': _firstAdDelaySeconds,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'note': 'Firebase Console\'dan bu değerleri düzenleyebilirsiniz',
        });

        debugPrint('✅ Firebase config tamamen oluşturuldu');
      }
    } catch (e) {
      debugPrint('❌ Firebase config oluşturma hatası: $e');
      rethrow;
    }
  }

  // API anahtarını manuel refresh et (artık her seferinde fresh alındığı için sadece log)
  void clearApiKeyCache() {
    debugPrint(
      '🔄 API anahtarı bir sonraki istekte Firebase\'den fresh alınacak',
    );
  }

  // Firebase config'i manuel olarak yeniden initialize et
  Future<void> forceConfigRefresh() async {
    debugPrint('🔄 Firebase config manuel refresh başlatılıyor...');
    _isConfigInitialized = false;
    await _initializeFirebaseConfig();
  }

  // Manual olarak config değerlerini set et (test için)
  Future<bool> setConfigValues({
    String? apiKey,
    String? model,
    String? prompt,
  }) async {
    try {
      debugPrint('🔧 Firebase config değerleri manuel olarak set ediliyor...');

      final database = FirebaseDatabase.instance;
      final configRef = database.ref('config');

      final updates = <String, dynamic>{};

      if (apiKey != null && apiKey.isNotEmpty) {
        updates['gemini_api'] = apiKey;
        debugPrint('🔑 API Key güncelleniyor: (gizli)');
      }

      if (model != null && model.isNotEmpty) {
        updates['gemini_model'] = model;
        debugPrint('🤖 Model güncelleniyor: $model');
      }

      if (prompt != null && prompt.isNotEmpty) {
        // Prompt'taki alan adlarını düzelt
        String correctedPrompt = prompt;
        correctedPrompt = correctedPrompt.replaceAll(
          '"arapcaCümle"',
          '"arapcaCumle"',
        );
        correctedPrompt = correctedPrompt.replaceAll(
          '"turkceAnlam"',
          '"turkceCeviri"',
        );

        updates['gemini_prompt'] = correctedPrompt;
        debugPrint(
          '📝 Prompt güncelleniyor: ${correctedPrompt.length} karakter',
        );
        debugPrint(
          '📝 Alan adları düzeltildi: arapcaCümle->arapcaCumle, turkceAnlam->turkceCeviri',
        );
      }

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        await configRef.update(updates);

        // Config'i yeniden initialize et
        await forceConfigRefresh();

        debugPrint('✅ Firebase config manuel güncelleme başarılı');
        return true;
      } else {
        debugPrint('⚠️ Güncellenecek config değeri bulunamadı');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Firebase config manuel güncelleme hatası: $e');
      return false;
    }
  }

  // Config durumunu debug et
  Future<void> debugConfigStatus() async {
    try {
      debugPrint('🔍 GeminiService Config Debug Başlıyor...');
      debugPrint('────────────────────────────────────');

      // Initialization durumu
      debugPrint('🔧 Config Initialize Durumu: $_isConfigInitialized');

      // Firebase bağlantısı test et
      debugPrint('🔥 Firebase bağlantısı test ediliyor...');
      final database = FirebaseDatabase.instance;
      final configRef = database.ref('config');

      try {
        final snapshot = await configRef.get();
        if (snapshot.exists) {
          debugPrint('✅ Firebase config alanı mevcut');
          final configData = snapshot.value as Map<dynamic, dynamic>;
          debugPrint('📊 Config alanları: ${configData.keys.toList()}');
        } else {
          debugPrint('❌ Firebase config alanı bulunamadı');
        }
      } catch (e) {
        debugPrint('❌ Firebase bağlantı hatası: $e');
      }

      // Tüm config değerlerini test et
      debugPrint('🔍 Config değerleri test ediliyor...');

      try {
        final apiKey = await _getApiKey();
        debugPrint('🔑 API Key: (gizli) (${apiKey.length} karakter)');
      } catch (e) {
        debugPrint('❌ API Key hatası: $e');
      }

      try {
        final model = await _getModel();
        debugPrint('🤖 Model: $model');
        debugPrint('🤖 Model Default?: ${model == _defaultModel}');
      } catch (e) {
        debugPrint('❌ Model hatası: $e');
      }

      try {
        final prompt = await _getPrompt();
        debugPrint('📝 Prompt: ${prompt.length} karakter');
        debugPrint('📝 Prompt Default?: ${prompt == _defaultPrompt}');
        debugPrint(
          '📝 Prompt Preview: ${prompt.substring(0, math.min(100, prompt.length))}...',
        );

        // Reklam süresi debug
        try {
          final cooldown = await _getAdCooldown();
          debugPrint('⏱️ Ad Cooldown: $cooldown saniye');
        } catch (e) {
          debugPrint('❌ Ad Cooldown hatası: $e');
        }
      } catch (e) {
        debugPrint('❌ Prompt hatası: $e');
      }

      debugPrint('────────────────────────────────────');
      debugPrint('✅ GeminiService Config Debug Tamamlandı');
    } catch (e) {
      debugPrint('❌ Config debug kritik hatası: $e');
    }
  }

  Future<AiTeacherExplanation> explainWordForTeacherMode(WordModel word) async {
    final jsonMap = await _generateTeacherJson(
      _buildTeacherExplanationPrompt(word),
      maxOutputTokens: 1400,
      timeout: const Duration(seconds: 12),
    );
    return AiTeacherExplanation.fromJson(jsonMap);
  }

  Future<String> answerTeacherQuestion(
    WordModel word,
    String question, {
    AiTeacherExplanation? previousContext,
  }) async {
    final jsonMap = await _generateTeacherJson(
      _buildTeacherQuestionPrompt(word, question, previousContext),
      maxOutputTokens: 700,
      timeout: const Duration(seconds: 10),
    );
    final answer = jsonMap['answer']?.toString().trim() ?? '';
    if (answer.isEmpty) {
      throw const FormatException('AI ogretmen yaniti bos geldi.');
    }
    return answer;
  }

  Future<Map<String, dynamic>> _generateTeacherJson(
    String prompt, {
    required int maxOutputTokens,
    required Duration timeout,
  }) async {
    await _initializeFirebaseConfig();

    final apiKey = await _getApiKey();
    final model = await _getModel();
    final url = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
      {'key': apiKey},
    );

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': 0.1,
        'topK': 16,
        'topP': 0.6,
        'maxOutputTokens': maxOutputTokens,
        'responseMimeType': 'application/json',
        'thinkingConfig': _teacherThinkingConfig(model),
      },
      'systemInstruction': {
        'parts': [
          {
            'text':
                'Sen Arapca-Turkce sozluk icinde calisan kisa, net ve guvenilir bir AI ogretmensin. Bilmedigin bilgiyi uydurma.',
          },
        ],
      },
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      final errorPreview = response.body.length > 500
          ? response.body.substring(0, 500)
          : response.body;
      debugPrint(
        '[GeminiService] AI teacher API failed with model "$model": ${response.statusCode} $errorPreview',
      );
      if (response.body.contains('API_KEY_INVALID')) {
        throw const GeminiApiKeyInvalidException();
      }
      throw Exception('AI ogretmen API hatasi: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FormatException('AI ogretmen candidates bos.');
    }
    final content = candidates.first['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) {
      throw const FormatException('AI ogretmen content bos.');
    }
    final text = parts.first['text']?.toString();
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('AI ogretmen metni bos.');
    }

    final cleanedJson = _cleanJsonResponse(text);
    return json.decode(cleanedJson) as Map<String, dynamic>;
  }

  Map<String, dynamic> _teacherThinkingConfig(String model) {
    if (model.toLowerCase().startsWith('gemini-3')) {
      return {'thinkingLevel': 'minimal'};
    }
    return {'thinkingBudget': 0};
  }

  String _buildTeacherExplanationPrompt(WordModel word) {
    final payload = _teacherWordPayload(word);
    return '''
Kelime kartindaki veriye gore Turkce kisa bir AI kelime asistani acilisi uret.
Tonun sohbet eden ogretmen gibi olsun: net, canli, pratik ve ogrenci dostu.
Uzun kalip konu anlatimi yapma; kelimenin kullanimini, nufusunu ve pratik ornekleri one cikar.
Kesin olmayan bilgileri uydurma. Parantez kullanma.
Kullanici Arapca ogreniyor.

Kelime verisi:
${json.encode(payload)}

Sadece JSON dondur:
{
  "summary": "2-3 cumlelik kisa ogretici aciklama",
  "grammarNotes": ["kisa not", "kisa not"],
  "usageNotes": ["anlam nufusu veya harf-i cer farki", "yaygin kullanim notu"],
  "examples": [
    {"arabic": "tam harekeli Arapca cumle", "turkish": "Turkce ceviri"},
    {"arabic": "tam harekeli Arapca cumle", "turkish": "Turkce ceviri"}
  ],
  "quiz": [
    {"question": "soru", "options": ["A", "B", "C"], "answer": "dogru secenek metni", "explanation": "kisa aciklama"},
    {"question": "soru", "options": ["A", "B", "C"], "answer": "dogru secenek metni", "explanation": "kisa aciklama"},
    {"question": "soru", "options": ["A", "B", "C"], "answer": "dogru secenek metni", "explanation": "kisa aciklama"}
  ],
  "suggestedQuestions": [
    "Bu kelime nerede kullanilir?",
    "Benzer kelimelerden farki ne?",
    "5 yeni ornek ver",
    "Kolay cumlelerle anlat"
  ],
  "confidenceNote": "Bilgi kartindaki veriye dayali kisa guven notu"
}
''';
  }

  String _buildTeacherQuestionPrompt(
    WordModel word,
    String question,
    AiTeacherExplanation? previousContext,
  ) {
    final context = previousContext == null
        ? null
        : {
            'summary': previousContext.summary,
            'grammarNotes': previousContext.grammarNotes,
            'usageNotes': previousContext.usageNotes,
          };
    return '''
Kullanici kelime kartindaki kelime hakkinda soru soruyor.
Turkce, dogal bir chat cevabi ver: kisa basla, gerekirse maddeler ve yeni Arapca orneklerle ac.
Eger kullanici daha fazla ornek isterse 5 cesit ornek ver: kolay, orta, gunluk, gramer odakli, soru cumlesi.
Bilmedigini uydurma.

Kelime verisi:
${json.encode(_teacherWordPayload(word))}

Onceki AI ogretmen ozeti:
${json.encode(context)}

Soru:
$question

Sadece JSON dondur:
{"answer": "kisa ve ogretici cevap"}
''';
  }

  // ─── SÖZLÜK SOHBETİ (chat bot) ───────────────────────────────────────────
  // Mevcut answerTeacherQuestion tek seferliktir ve sadece önceki özeti
  // gönderir; kullanıcı "peki ya bu?" diye sorunca bağ kopuyor.
  // Burada gerçek konuşma geçmişi (contents dizisi) gönderilir.

  /// Sohbet asistanına düz metin cevap alır (JSON değil, hızlı ve doğal).
  /// [history] sırayla gönderilir; ilk girdi 'user' olmalıdır.
  Future<String> askInChat({
    required List<Map<String, dynamic>> history,
    WordModel? contextWord,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (history.isEmpty) {
      throw const FormatException('Sohbet gecmisi bos.');
    }

    await _initializeFirebaseConfig();

    final apiKey = await _getApiKey();
    final model = await _getModel();
    final url = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
      {'key': apiKey},
    );

    final requestBody = <String, dynamic>{
      'contents': history,
      'generationConfig': <String, dynamic>{
        'temperature': 0.3,
        'topP': 0.85,
        // Uzunluğu istem belirler (kısa); tavan yalnızca harekeli örnek
        // listeleri kesilmesin diye.
        'maxOutputTokens': 800,
        'thinkingConfig': _teacherThinkingConfig(model),
      },
      'systemInstruction': {
        'parts': [
          {'text': _buildChatSystemPrompt(contextWord)},
        ],
      },
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      if (response.body.contains('API_KEY_INVALID')) {
        throw const GeminiApiKeyInvalidException();
      }
      debugPrint(
        '[GeminiService] Chat API hatasi: ${response.statusCode} ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}',
      );
      throw Exception('AI asistan hatasi: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FormatException('AI asistan cevabi bos.');
    }
    final content = candidates.first['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) {
      throw const FormatException('AI asistan cevabi bos.');
    }
    final text = parts.first['text']?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw const FormatException('AI asistan metni bos.');
    }
    // Tavana takılıp yarıda kesildiyse kullanıcı bunu görsün.
    if (candidates.first['finishReason'] == 'MAX_TOKENS') {
      return '$text…';
    }
    return text;
  }

  String _buildChatSystemPrompt(WordModel? word) {
    final buffer = StringBuffer('''
Sen Kavaid sozlugunun icindeki Arapca asistanisin.
Kullanici Turkce konusuyor, Arapca ogreniyor.

En onemli kural: kisa yaz ve kullanici ne istiyorsa tam olarak onu yap.
- Uzunluk:
  - Varsayilan: 1-3 kisa cumle, en fazla 40 kelime.
  - "detayli", "derinles", "ayrintili anlat", "biraz daha ac", "neden" derse: biraz daha ac ama yine oz kal; en fazla 5-6 cumle ya da 5 kisa madde, en fazla 100 kelime.
  - "kisa", "tek cumle", "ozetle" derse: tek cumle.
- Sayi verildiyse ("5 ornek", "3 fark") tam o sayida ver; ornek istenip sayi verilmediyse 2 ornek ver.
- "Daha basit anlat" derse ayni konuyu sade kelimelerle, kisa cumlelerle anlat.
- Onceki mesaja bagli isteklerde ("derinles", "devam", "peki ya bu?") ayni konuyu surdur.
- Dogrudan konuya gir: selamlama, soruyu tekrar etme, ovgu ve "umarim yardimci olmustur" gibi kapanislar yok. Sorulmayan konuya sapma.
- Ornek cumle formati: her satira bir ornek; tam harekeli Arapca cumle, " — ", Turkce ceviri. Ornekleri sade cumlelerle kendin kur; ayetleri ornek cumle olarak verme.
- Arapca her kelime ve cumle tam harekeli olsun.
- Madde icin "- " kullan. Baslik, emoji ve parantez kullanma.
- Kalip (vezin) ve irab bilgisini yalnizca kesin biliyorsan ver. "Kac kez gecer" gibi sayi ve istatistik verme.
- Kur'an ayetlerinin metnini yazma; gerekirse yalnizca sure adi ve ayet numarasi ver (ornek: Bakara 2).
- Emin degilsen "Emin degilim" de; asla uydurma.
''');

    if (word != null) {
      buffer.write('''
Su an su kelime uzerine konusuyoruz. Kelime kartindaki veriler:
${json.encode(_teacherWordPayload(word))}
Bu kelimeye bagli sorulari bu veriye gore cevapla.
''');
    } else {
      buffer.write('''
Su an belirli bir kelime secili degil. Genel Arapca sorularini cevapla.
Kullanicinin kelimesini sozluk mantigina gore yorumla: koku, kalip, harf-i cer.
''');
    }

    return buffer.toString();
  }

  Map<String, dynamic> _teacherWordPayload(WordModel word) {
    return {
      'kelime': word.kelime,
      'harekeliKelime': word.harekeliKelime,
      'anlam': word.anlam,
      'sadeAnlam': word.sadeAnlam,
      'koku': word.koku,
      'tip': word.tip,
      'dilbilgiselOzellikler': word.dilbilgiselOzellikler,
      'fiilCekimler': word.fiilCekimler,
      'ornekCumleler': word.ornekCumleler,
      'harfiCerler': word.harfiCerler,
    };
  }

  String _cleanJsonResponse(String response) {
    try {
      // Markdown kod bloklarını temizle
      String cleaned = response.replaceAll(RegExp(r'```json\s*'), '');
      cleaned = cleaned.replaceAll(RegExp(r'```\s*$'), '');
      cleaned = cleaned.replaceAll('```', '');

      // Başındaki ve sonundaki boşlukları temizle
      cleaned = cleaned.trim();

      // Eğer JSON ile başlamıyorsa, JSON'u bul
      int jsonStart = cleaned.indexOf('{');
      if (jsonStart > 0) {
        cleaned = cleaned.substring(jsonStart);
      }

      // JSON'un tam olup olmadığını kontrol et
      int braceCount = 0;
      int lastValidIndex = -1;

      for (int i = 0; i < cleaned.length; i++) {
        if (cleaned[i] == '{') {
          braceCount++;
        } else if (cleaned[i] == '}') {
          braceCount--;
          if (braceCount == 0) {
            lastValidIndex = i;
            break;
          }
        }
      }

      if (lastValidIndex > 0) {
        cleaned = cleaned.substring(0, lastValidIndex + 1);
      }

      // Eğer hala geçersizse, son } karakterinden sonrasını temizle
      int jsonEnd = cleaned.lastIndexOf('}');
      if (jsonEnd > 0 && jsonEnd < cleaned.length - 1) {
        cleaned = cleaned.substring(0, jsonEnd + 1);
      }

      return cleaned;
    } catch (e) {
      debugPrint('❌ JSON temizleme hatası: $e');
      // Hata durumunda basit temizlik yap
      String fallback = response.trim();
      int start = fallback.indexOf('{');
      int end = fallback.lastIndexOf('}');
      if (start >= 0 && end > start) {
        return fallback.substring(start, end + 1);
      }
      return response;
    }
  }

  // API Key kontrolü
  Future<bool> get isConfigured async {
    try {
      final apiKey = await _getApiKey();
      return apiKey.isNotEmpty;
    } catch (e) {
      debugPrint('❌ API anahtarı kontrol hatası: $e');
      return false;
    }
  }
}
