import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

// === YAPILANDIRMA ===
const String SERVICE_ACCOUNT_FILE = "tool/service_account.json";
const String SOURCE_JSON = "assets/books/aglayan_deve/full_book.json";
const String DEST_DIR = "assets/audio/aglayan_deve";

// TTS Ayarları (Chirp 3 HD Achernar - Female Arabic)
const String VOICE_NAME = "ar-XA-Chirp3-HD-Achernar";
const String LANGUAGE_CODE = "ar-XA";
const String TTS_URL = "https://texttospeech.googleapis.com/v1/text:synthesize";

void main(List<String> args) async {
  if (args.isEmpty) {
    print("❌ Lütfen kitap ID'sini parametre olarak girin.");
    print("Örnek: dart tool/download_book_audio.dart aglayan_deve");
    return;
  }

  final String bookId = args[0];
  final String SOURCE_JSON = "assets/books/$bookId/full_book.json";
  final String DEST_DIR = "assets/audio/$bookId";

  print("🚀 Google Cloud TTS İndirici Başlatılıyor...");
  print("📖 Kitap: $bookId");
  print("📂 Hedef: $DEST_DIR");
  
  // 1. Service Account Credentials
  final saFile = File(SERVICE_ACCOUNT_FILE);
  if (!saFile.existsSync()) {
    print("❌ Service Account dosyası bulunamadı: $SERVICE_ACCOUNT_FILE");
    return;
  }

  final saContent = saFile.readAsStringSync();
  final credentials = auth.ServiceAccountCredentials.fromJson(saContent);

  // 2. OAuth2 Client oluştur
  print("🔑 Google Cloud'a bağlanılıyor...");
  final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
  final authClient = await auth.clientViaServiceAccount(credentials, scopes);
  print("✅ Kimlik doğrulandı!");

  // 3. Dizin oluştur
  final destDir = Directory(DEST_DIR);
  if (!destDir.existsSync()) {
    destDir.createSync(recursive: true);
    print("📁 Klasör oluşturuldu: $DEST_DIR");
  }

  // 4. Kelimeleri yükle
  final sourceFile = File(SOURCE_JSON);
  if (!sourceFile.existsSync()) {
    print("❌ Kaynak JSON bulunamadı: $SOURCE_JSON");
    authClient.close();
    return;
  }

  final data = json.decode(sourceFile.readAsStringSync());
  final List<dynamic> kelimeler = data['kelimeler'] ?? [];

  final Set<String> uniqueWords = {};
  for (var item in kelimeler) {
    if (item['type'] == 'word' && item['arapca'] != null) {
      String word = item['arapca'].toString().trim();
      if (word.isNotEmpty) uniqueWords.add(word);
    }
  }

  print("🔍 Benzersiz kelime sayısı: ${uniqueWords.length}");

  int successCount = 0, errorCount = 0, skipCount = 0;
  int index = 0;

  for (String word in uniqueWords) {
    index++;
    final filename = "${md5.convert(utf8.encode(word))}.mp3";
    final filePath = "$DEST_DIR/$filename";
    
    if (File(filePath).existsSync() && File(filePath).lengthSync() > 100) {
      skipCount++;
      if (skipCount % 50 == 0) print("⏩ $skipCount kelime atlandı (zaten var)");
      continue;
    }

    if (index % 10 == 0 || index == 1) {
      print("[$index/${uniqueWords.length}] ⬇️ $word");
    }
    
    final success = await synthesize(authClient, word, filePath);
    if (success) {
      successCount++;
    } else {
      errorCount++;
      print("❌ Hata: $word");
      if (errorCount > 20) {
        print("⛔ Çok fazla hata. Durduruluyor.");
        break;
      }
    }
    
    // Rate limiting (saniyede ~8 istek)
    await Future.delayed(Duration(milliseconds: 120));
  }

  authClient.close();
  print("\n✨ İşlem Tamamlandı!");
  print("✅ Başarılı: $successCount");
  print("⏩ Atlanan: $skipCount");
  print("❌ Hatalı: $errorCount");
}

Future<bool> synthesize(http.Client client, String text, String filePath) async {
  try {
    final response = await client.post(
      Uri.parse(TTS_URL),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: json.encode({
        "input": {"text": text},
        "voice": {
          "languageCode": LANGUAGE_CODE,
          "name": VOICE_NAME,
        },
        "audioConfig": {
          "audioEncoding": "MP3",
          "speakingRate": 1.0 
        }
      }),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final audioContent = body['audioContent'];
      if (audioContent != null) {
        File(filePath).writeAsBytesSync(base64.decode(audioContent));
        return true;
      }
    } else {
      final err = json.decode(response.body);
      print("   ⚠️ API: ${err['error']?['message'] ?? response.reasonPhrase}");
    }
    return false;
  } catch (e) {
    print("   ❌ İstek Hatası: $e");
    return false;
  }
}
