import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/gemini_service.dart';
import '../models/word_model.dart';
import 'dart:async';

/// Bu betik, Firebase'deki 'kelimeler' düğümünde bulunan mevcut kelimeleri
/// tek tek dolaşır, her biri için güncel Gemini API prompt'unu
/// (özellikle genişletilmiş fiil/harf-i cerli ve numaralandırılmış anlamları
/// almak üzere) çalıştırır ve veritabanını günceller.
/// 
/// DİKKAT: Çok fazla kelime varsa Gemini API limitlerine (rate limit)
/// takılma riski bulunur. Bu sebeple işlem aralarına gecikme konulmuştur.
/// 
/// Kullanımı:
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   await UpdateMeaningsScript.run();
/// }

class UpdateMeaningsScript {
  static Future<void> run() async {
    debugPrint('YENİ ANLAM GÜNCELLEME BETİĞİ BAŞLADI...');
    final database = FirebaseDatabase.instance;
    final kelimelerRef = database.ref('kelimeler');
    
    final snapshot = await kelimelerRef.get();
    
    if (!snapshot.exists || snapshot.value == null) {
      debugPrint('Firebase içinde kelime bulunamadı.');
      return;
    }

    final data = snapshot.value as Map<dynamic, dynamic>;
    final totalWords = data.length;
    int processedCount = 0;
    int successCount = 0;
    int errorCount = 0;

    debugPrint('Toplam $totalWords kelime güncellenecek.');

    final geminiService = GeminiService();
    await geminiService.initialize();

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value as Map<dynamic, dynamic>;
      
      final kelime = value['kelime']?.toString();
      
      if (kelime == null || kelime.isEmpty) {
        processedCount++;
        continue;
      }
      
      debugPrint('[$processedCount / $totalWords] Kelime güncelleniyor: $kelime');
      
      try {
        // Gemini API'den güncel ve geniş kapsamlı bilgiyi çek.
        // gemini_service.dart'taki prompt düzenlendiğinden
        // <blue> taglerini ve harf-i cerleri içeren yeni formatta gelecektir.
        final WordModel aiResult = await geminiService.searchWord(kelime);
        
        if (aiResult.bulunduMu) {
          final docData = aiResult.toFirebaseJson();
          await kelimelerRef.child(key.toString()).update({
            'anlam': docData['anlam'],
            'dilbilgiselOzellikler': docData['dilbilgiselOzellikler'],
            'fiilCekimler': docData['fiilCekimler'],
            'ornekCumleler': docData['ornekCumleler'],
            'guncellenmeTarihi': DateTime.now().millisecondsSinceEpoch,
          });
          successCount++;
          debugPrint('✅ Başarılı: $kelime');
        } else {
          debugPrint('❌ Başarısız (AI Yanıtı Bulamadı): $kelime');
          errorCount++;
        }
      } catch (e) {
        debugPrint('⚠️ Hata: Seçilen kelime "$kelime" atlandı. Sebep: $e');
        errorCount++;
      }

      processedCount++;
      
      // Rate limit yememek için API çağrıları arasına 2 saniye koyuyoruz (gerekiyorsa arttırın).
      await Future.delayed(const Duration(seconds: 2));
    }

    debugPrint('GÜNCELLEME İŞLEMİ TAMAMLANDI.');
    debugPrint('Toplam: $totalWords, Başarılı: $successCount, Hatalı: $errorCount');
  }
}
