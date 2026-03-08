# Oyunlar Modülü Kullanım Kılavuzu

Kavaid uygulamasına eklenen yeni "Oyunlar" (Games Hub) modülü, Arapça kelime öğrenimini eğlenceli ve interaktif hale getirmek için tasarlanmıştır.

## 🎮 Oyunlar Listesi

Modülde şu an toplam 9 farklı oyun bulunmaktadır:

1.  **🎯 Kelime Eşleştir (Word Match)**
    *   **Amaç:** Sol sütundaki Arapça kelimelerle sağ sütundaki Türkçe anlamlarını eşleştirmek.
    *   **Nasıl Oynanır:** Önce bir Arapça kelimeye, sonra karşılığına dokunun.
    *   **Puan:** Doğru eşleşme +25 puan.

2.  **📝 Anlam Tahmini (Meaning Quiz)**
    *   **Amaç:** Verilen Arapça kelimenin doğru anlamını 4 şık arasından bulmak.
    *   **Nasıl Oynanır:** Doğru olduğunu düşündüğünüz şıkkı seçin.
    *   **Puan:** Doğru cevap +10 puan.

3.  **✅ Doğru / Yanlış (True / False)**
    *   **Amaç:** Gösterilen Arapça kelime ve Türkçe anlamın birbiriyle eşleşip eşleşmediğine karar vermek.
    *   **Nasıl Oynanır:** "Doğru" veya "Yanlış" butonuna basın.
    *   **Puan:** Doğru karar +10 puan.

4.  **🃏 Bilgi Kartları (Flashcards)**
    *   **Amaç:** Kelimeleri stressiz bir şekilde öğrenmek ve kendinizi test etmek.
    *   **Nasıl Oynanır:** Kartın ön yüzünde Arapça kelimeyi okuyun, karta dokunup arka yüzdeki anlamı görün. "Biliyorum" veya "Bilmiyorum" diyerek ilerleyin.
    *   **Puan:** Bildiğiniz her kart +10 puan.

5.  **🔤 Harf Karıştırma (Letter Scramble)**
    *   **Amaç:** Harfleri karışık verilmiş kelimeyi doğru sıraya dizmek.
    *   **Nasıl Oynanır:** Alttaki harf kutucuklarına sırasıyla dokunarak kelimeyi oluşturun.
    *   **Puan:** Kelime uzunluğuna göre puan (Harf başı 5 puan + 10 bonus).

6.  **🌱 Kök Bulma (Root Finding)**
    *   **Amaç:** Verilen kelimenin Arapça kökünü (3 harfli kök) bulmak.
    *   **Nasıl Oynanır:** Verilen şıklardan doğru kökü seçin.
    *   **Puan:** Doğru cevap +10 puan.

7.  **⏱️ Hızlı Yanıt (Speed Quiz)**
    *   **Amaç:** 60 saniye içinde yapabildiğiniz kadar çok doğru cevap vermek.
    *   **Nasıl Oynanır:** Hızlıca iki şıktan birini seçin.
    *   **Puan:** Her doğru +10, her yanlış -5 puan.

8.  **🏆 3'te 1 (Category Sort / 3-Option)**
    *   **Amaç:** 3 seçenek arasından doğru anlamı bulmak.
    *   **Nasıl Oynanır:** Doğru şıkkı (A, B, C) işaretleyin.
    *   **Puan:** Doğru cevap +10 puan.

9.  **✍️ Kelime Yazma (Writing Game)**
    *   **Amaç:** Türkçe anlamı verilen kelimenin Arapçasını yazmak.
    *   **Nasıl Oynanır:** Ekrandaki Arapça klavyeyi kullanarak kelimeyi yazın ve "Kontrol Et"e basın. İpucu olarak kelimenin ilk harfi verilir.
    *   **Puan:** Doğru yazım +15 puan.

## 🎨 Tasarım ve Tema

*   Tüm oyun ekranları, uygulamanın genel temasıyla uyumlu **Mavi (0xFF007AFF)** başlık çubuğuna sahiptir.
*   Karanlık mod (Dark Mode) ve Aydınlık mod (Light Mode) tam uyumludur.
*   Her oyunun kendine özgü bir emoji ve renk gradyanı vardır.

## 🛠️ Teknik Notlar

*   Oyunlar yerel veritabanındaki (`words` tablosu) kelimeleri kullanır.
*   Skorlar ve istatistikler `GameService` aracılığıyla yerel olarak (`SharedPreferences`) saklanır.
*   Klavye gerektiren oyunlar (`WritingGame`) için uygulama içi özel Arapça klavye geliştirilmiştir.
