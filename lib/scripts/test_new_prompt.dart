import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kavaid/services/gemini_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  List<String> words = ['بحث', 'ذهب', 'قال', 'جميل'];
  
  print('==== GEMINI PROMPT TEST ====');
  final gemini = GeminiService();
  await gemini.initialize();
  
  for (String word in words) {
    print('Testing word: \$word');
    final result = await gemini.searchWord(word);
    print('BulunduMu: \${result.bulunduMu}');
    print('Kelime: \${result.kelime}');
    print('Anlam:\\n\${result.anlam}');
    print('-----------------------------------------');
    await Future.delayed(Duration(seconds: 2));
  }
  
  print('==== TEST BİTTİ ====');
}
