import 'dart:convert';
import 'dart:io';

void main() async {
  final jsonFile = File('tool/new_books_data.json');
  if (!await jsonFile.exists()) {
    print('JSON file not found!');
    return;
  }

  final String content = await jsonFile.readAsString();
  final List<dynamic> books = jsonDecode(content);

  for (var book in books) {
    String titleTr = book['baslik_türkce'];
    String slug = _slugify(titleTr);
    
    print('Processing: $titleTr -> $slug');

    // 1. Create directory
    final Directory dir = Directory('assets/books/$slug');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('Created directory: ${dir.path}');
    }

    // 2. Process text into full_book.json format
    String text = book['metin'];
    List<Map<String, dynamic>> wordsJson = _processTextToWords(text);
    
    Map<String, dynamic> finalJson = {
      "book_id": slug,
      "title": titleTr,
      "kelimeler": wordsJson
    };
    
    final File bookFile = File('${dir.path}/full_book.json');
    await bookFile.writeAsString(jsonEncode(finalJson), mode: FileMode.write);
    print('Created full_book.json for $slug with ${wordsJson.length} words in new format.');

    // 3. (Optional) Create a metadata file if needed later, but current system stores metadata in code.
  }
}

String _slugify(String text) {
  text = text.toLowerCase();
  text = text.replaceAll('ç', 'c')
             .replaceAll('ğ', 'g')
             .replaceAll('ı', 'i')
             .replaceAll('ö', 'o')
             .replaceAll('ş', 's')
             .replaceAll('ü', 'u')
             .replaceAll('İ', 'i');
  text = text.replaceAll(RegExp(r'[^a-z0-9\s-]'), ''); // Remove special chars
  text = text.replaceAll(RegExp(r'\s+'), '_'); // Replace spaces with underscore
  return text;
}

List<Map<String, dynamic>> _processTextToWords(String text) {
  List<Map<String, dynamic>> wordsList = [];
  
  // Split by spaces but keep punctuation attached or separate?
  // Current system usually expects clean words for 'word' field. 
  // Let's iterate and split carefully.
  
  // Regex to match words and keeping punctuation is tricky for Arabic.
  // Simple split by space is safer for now, assuming the text is reasonably spaced.
  // Adjust logic if needed. Arabic text often has attached prefixes/suffixes.
  
  List<String> rawWords = text.split(RegExp(r'\s+'));
  
  for (String rawWord in rawWords) {
    if (rawWord.trim().isEmpty) continue;
    
    wordsList.add({
      "type": "word",
      "arapca": rawWord, // Eski format uyumluluğu
      "turkce": "",      // Şimdilik boş
      // Ses dosyası download_book_audio tarafından md5(arapca).mp3 olarak indirilecek
    });
  }
  
  return wordsList;
}
