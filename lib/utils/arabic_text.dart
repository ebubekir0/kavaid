/// Arapça metin yardımcıları.
library;

final RegExp _marksRx = RegExp(r'[ً-ٰٟـ]');
final RegExp _rootSeparatorRx = RegExp(r'[\s,،;/·]+');

/// Harekeleri ve uzatma çizgisini (ـ) siler.
String stripArabicMarks(String text) => text.replaceAll(_marksRx, '');

/// Farsça/Urduca klavyeden gelen harfleri Arapça karşılıklarına çevirir:
/// ی -> ي, ک -> ك, ھ ہ -> ه.
String _arabizeLetters(String text) => text
    .replaceAll('ی', 'ي')
    .replaceAll('ک', 'ك')
    .replaceAll('ھ', 'ه')
    .replaceAll('ہ', 'ه');

/// Sözlükteki kök yazımını ekranda gösterilecek biçime getirir.
///
/// Veride kökler tutarsız yazılmış: çoğu "كتب" gibi bitişik, ama 90 kadarının
/// harfleri boşlukla ayrılmış ("ض ب ب" — ekranda harfler birbirine bağlanmaz,
/// bozuk yazı gibi görünür), 500 kadarı iki kelimelik ifadelerin kökleri
/// ("قوس مطر"), birkaçı virgüllü ("عدد, رتب"), 20 kadarı harekeli ve 16 tanesi
/// Farsça harfli.
///
/// - Harekeler silinir (kök harekesiz yazılır).
/// - Farsça klavye harfleri Arapçaya çevrilir: "فید" -> "فيد" (Farsça ye U+06CC
///   kelime sonunda noktasız çizilir, bozuk harf gibi görünür).
/// - Her harfi ayrı yazılmış kök birleştirilir: "ض ب ب" -> "ضبب".
/// - Birden çok kök varsa " · " ile ayrılır: "قوس · مطر".
///
/// Kök yoksa boş metin döner.
String formatRoot(String? raw) {
  if (raw == null) return '';
  final tokens = _arabizeLetters(stripArabicMarks(raw))
      .split(_rootSeparatorRx)
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return '';
  if (tokens.length > 1 && tokens.every((t) => t.length == 1)) {
    return tokens.join();
  }
  return tokens.join(' · ');
}
