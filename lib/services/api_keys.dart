/// Gemini API anahtarı.
///
/// Anahtar kaynak koda yazılmaz: derleme sırasında
/// `--dart-define-from-file=dart_defines.json` ile verilir (dosya git'e
/// girmez, bkz. dart_defines.example.json). Verilmezse eski yedek anahtar
/// kullanılır.
class ApiKeys {
  ApiKeys._();

  static const String gemini = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: _fallbackGemini,
  );

  static const String _fallbackGemini = 'AIzaSyBJhiD9uzHDLd1BE_FYqoXlbw6L5_IXW54';
}
