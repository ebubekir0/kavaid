import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dialect_language.dart';
import 'api_keys.dart';
import 'language_service.dart';

/// Çeviri yapılamadı; [message] kullanıcıya gösterilir.
class TranslationException implements Exception {
  const TranslationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Levanten uygulamasından adapte edilmiş Gemini çeviri servisi.
///
/// Hata durumlarında [TranslationException] fırlatır; böylece başarısız
/// çeviri, çeviri hakkından düşülmez.
class DialectTranslationService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-3-flash-preview';

  static const int maxInputLength = 500;
  static const int maxWordLength = 80;

  /// Çeviri yap + okunuş al (tek API çağrısı)
  Future<Map<String, String>> translateWithPronunciation({
    required String text,
    required DialectLanguage source,
    required DialectLanguage target,
  }) async {
    if (text.trim().isEmpty) return {'translation': '', 'pronunciation': ''};

    final limitedText = text.trim().length > maxInputLength
        ? text.trim().substring(0, maxInputLength)
        : text.trim();

    final prompt = _buildPrompt(limitedText, source, target);

    try {
      final apiKey = await ApiKeys.gemini();
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey');
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.0,
          'responseMimeType': 'application/json',
          'thinkingConfig': {'thinkingLevel': 'MINIMAL'},
        },
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw const TranslationException('Çeviri sonucu boş.');
        }
        final parts = candidates[0]['content']['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          throw const TranslationException('Çeviri sonucu boş.');
        }

        String result = '';
        for (var part in parts) {
          if (part['text'] != null && part['thought'] != true) {
            result = part['text'];
            break;
          }
        }
        if (result.isEmpty) {
          for (var part in parts) {
            if (part['text'] != null) {
              result = part['text'];
              break;
            }
          }
        }

        try {
          final json = jsonDecode(result) as Map<String, dynamic>;
          return {
            'translation': json['translation']?.toString().trim() ?? '',
            'pronunciation': json['pronunciation']?.toString().trim() ?? '',
          };
        } catch (_) {
          return {
            'translation': result.trim().replaceAll(RegExp(r'^["]+|["]+$'), ''),
            'pronunciation': '',
          };
        }
      } else {
        throw TranslationException('Çeviri hatası (${response.statusCode}).');
      }
    } on TranslationException {
      rethrow;
    } catch (e) {
      throw const TranslationException('Bağlantı hatası.');
    }
  }

  String _buildPrompt(
    String text,
    DialectLanguage source,
    DialectLanguage target,
  ) {
    String dialectInstructions = '';
    if (target.type == DialectLanguageType.arabic) {
      if (target.code == 'ar_standard') {
        dialectInstructions = '''

STANDART ARAPÇA (FUSHA) TALİMATLARI:
- Resmi, kitabi Arapça (Fusha) kullan.
- Gramatikal kurallara tam uygun yaz.
- Fusha telaffuzuna göre harekele.
- Her kelimenin son harfine mutlaka hareke koy.''';
      } else {
        dialectInstructions =
            '''

LEHÇE TALİMATLARI:
- ${target.name} lehçesinin YERLİ KONUŞUCUSU gibi yaz.
- Günlük hayatta konuşulan doğal dili kullan, Fusha kullanma.
- Harekeleri ${target.name} lehçesinin TELAFFUZUNA göre koy.
- Her kelimenin son harfine mutlaka hareke koy.
- ا و ي uzatma harflerine hareke koyma.''';
      }
    }

    String pronunciationInstr = '';
    final uiCode = LanguageService().uiLocale.languageCode;
    final readsArabicScript = LanguageService().isRtl;
    final pronunciationHint = uiCode == 'tr'
        ? 'Türkçe harflerle okunuş'
        : readsArabicScript
            ? ''
            : 'pronunciation in simple Latin letters';
    if (target.type == DialectLanguageType.arabic && uiCode != 'tr') {
      // Okunuş kullanıcının okuyabileceği harflerle; Arap harfli dillerde gereksiz
      pronunciationInstr = readsArabicScript
          ? '\n\nPRONUNCIATION: leave the "pronunciation" field empty.'
          : '\n\nPRONUNCIATION (pronunciation field): write how it sounds in simple Latin letters '
              'that a ${LanguageService.englishNames[uiCode] ?? 'English'} speaker can read '
              "(kh, sh, gh, th; use ' for ع). Do not use Turkish letters.";
    } else if (target.type == DialectLanguageType.arabic) {
      pronunciationInstr = '''

TÜRKÇE OKUNUŞ TALİMATLARI (pronunciation alanı):
- Sadece Türkçe alfabesi kullan (ğ,ş,ç,ü,ö,ı dahil).
- ع → boş veya ′ | ح → h | خ → hı | ق → k | غ → ğ | ش → ş | ص → s | ض → d | ط → t
- Türk biri okuyunca doğru telaffuz edebilmeli.''';
    }

    return '''Çeviri yap ve JSON formatında dön.

KAYNAK: ${source.name}
HEDEF: ${target.name}

KURALLAR:
1. Girilen metni ${target.name} diline çevir.
2. Girdiyi tekrarlama — mutlaka çeviri yap.
3. Sadece JSON döndür, başka açıklama yazma.
$dialectInstructions
$pronunciationInstr

GİRDİ: $text

JSON FORMATI:
{
  "translation": "Çevrilen metin${target.type == DialectLanguageType.arabic ? ' (harekeli)' : ''}",
  "pronunciation": "${target.type == DialectLanguageType.arabic ? pronunciationHint : ''}"
}''';
  }
}
