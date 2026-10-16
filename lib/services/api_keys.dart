import 'package:firebase_database/firebase_database.dart';

/// Gemini API anahtarının tek kaynağı.
///
/// Anahtar kaynak koda yazılmaz. Sırasıyla:
/// 1. Derlemede verildiyse `--dart-define=GEMINI_API_KEY=...`
///    (yerelde: `--dart-define-from-file=dart_defines.json`, dosya git'e girmez),
/// 2. yoksa Firebase Realtime Database'deki `config/gemini_api` değeri.
///
/// İkinci yol sayesinde anahtar değiştiğinde uygulama güncellemesi gerekmez:
/// Firebase Console'da `config/gemini_api` değerini değiştirmek yeterli.
class ApiKeys {
  ApiKeys._();

  static const String _compiled = String.fromEnvironment('GEMINI_API_KEY');
  static String? _remote;

  static Future<String> gemini() async {
    if (_compiled.isNotEmpty) return _compiled;
    final cached = _remote;
    if (cached != null && cached.isNotEmpty) return cached;

    final snapshot = await FirebaseDatabase.instance
        .ref('config/gemini_api')
        .get()
        .timeout(const Duration(seconds: 8));
    final value = snapshot.value?.toString().trim() ?? '';
    if (value.isNotEmpty && value != 'null') _remote = value;
    return value;
  }
}
