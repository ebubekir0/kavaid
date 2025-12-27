# Kavaid Uygulaması - Yeni Kitap Ekleme Şablonu

Bu dosya, uygulamaya yeni bir interaktif kitap eklemek için gereken tüm adımları ve dosya formatlarını açıklar.

---

## 📁 Klasör Yapısı

Yeni bir kitap eklemek için aşağıdaki klasör yapısını oluşturun:

```
assets/
├── books/
│   └── <kitap_id>/                    # Kitabın benzersiz ID'si (örn: taysir_sira)
│       ├── full_book.json             # ⭐ ANA DOSYA: Tüm kelimelerin listesi
│       └── index.json                 # Ders listesi (opsiyonel, ileride kullanılabilir)
│
└── images/
    └── <kitap_id>.jpg                 # Kitap kapak görseli (thumbnail)
```

---

## 📄 Dosya Formatları

### 1. `full_book.json` — Ana Kelime Dosyası (ZORUNLU)

Bu dosya, kitaptaki TÜM kelimeleri sırayla içerir. Uygulama bu dosyayı yükler ve kullanıcıya gösterir.

```json
{
    "book_id": "<kitap_id>",
    "title": "Kitap Başlığı (Türkçe)",
    "kelimeler": [
        {
            "type": "word",
            "arapca": "هَذَا",
            "turkce": "Bu"
        },
        {
            "type": "word",
            "arapca": "خَالِدٌ",
            "turkce": "Halid"
        },
        {
            "type": "newline"
        },
        {
            "type": "word",
            "arapca": "يَسْكُنُ",
            "turkce": "yaşıyor"
        }
    ]
}
```

**Önemli Kurallar:**
- `type`: Sadece `"word"` veya `"newline"` olabilir.
- `arapca`: Arapça kelime (harekeli olmalı).
- `turkce`: Türkçe anlam. **BOŞ BIRAKILMAMALI!** Boş bırakılırsa "..." gösterilir.
- `newline`: Yeni paragraf/satır için kullanılır. `arapca` ve `turkce` alanları gereksizdir.

---

### 2. `index.json` — Ders Listesi (OPSİYONEL)

Bu dosya, kitabın bölümlerini/derslerini listeler. Şu an için kullanılmıyor ama gelecekte ders seçme özelliği için hazır.

```json
{
    "bookId": "<kitap_id>",
    "metinler": [
        {
            "id": "lesson_1",
            "title": "Ders 1 — Başlık (Arapça Başlık)"
        },
        {
            "id": "lesson_2",
            "title": "Ders 2 — Başka Bir Başlık"
        }
    ]
}
```

---

### 3. Kapak Görseli — `assets/images/<kitap_id>.jpg`

- Format: JPG veya PNG
- Önerilen Boyut: 300x400 piksel (dikey, portre)
- Dosya Adı: `<kitap_id>.jpg` (örn: `taysir_sira.jpg`)

---

## ⚙️ Kod Değişiklikleri

### 1. `lib/services/book_store_service.dart`

`BookStoreService` sınıfındaki `books` listesine yeni kitabı ekleyin:

```dart
static final List<BookInfo> books = [
    // ... mevcut kitaplar ...
    BookInfo(
      id: '<kitap_id>',                           // Klasör adı ile aynı olmalı
      title: 'Kitap Başlığı',                     // Anasayfada görünen başlık
      subtitle: 'Alt başlık veya açıklama',       // Kısa açıklama
      priceText: 'Satın Al',                      // Buton metni
      imageBase: 'assets/images/<kitap_id>',      // .jpg uzantısız
    ),
];
```

---

## 🔄 Uygulama Akışı

```
1. Kullanıcı anasayfada kitap listesini görür
   └── BookStoreService.books listesi kullanılır
   └── Kapak görseli: assets/images/<kitap_id>.jpg

2. Kullanıcı kitaba tıklar
   └── Satın almışsa → InteractiveBookScreen açılır
   └── Satın almamışsa → Satın alma ekranı gösterilir

3. InteractiveBookScreen yüklenir
   └── `assets/books/<kitap_id>/full_book.json` dosyası okunur
   └── Kelimeler ekrana RTL (sağdan sola) olarak yazılır

4. Kullanıcı kelimeye tıklar
   └── Anlam balonu gösterilir (turkce alanı)
   └── TTS ile kelime okunur (arapca alanı)

5. Otomatik okuma başlatılabilir
   └── Her kelime sırayla seçilir ve okunur
```

---

## ✅ Kontrol Listesi

Yeni kitap eklerken aşağıdaki adımları tamamlayın:

- [ ] `assets/books/<kitap_id>/` klasörü oluşturuldu
- [ ] `full_book.json` dosyası oluşturuldu ve formatı doğru
- [ ] Tüm kelimelerin `turkce` alanı dolu (boş string yok)
- [ ] `assets/images/<kitap_id>.jpg` kapak görseli eklendi
- [ ] `book_store_service.dart` içinde `BookInfo` eklendi
- [ ] `pubspec.yaml` içinde `assets` yolları tanımlı:
  ```yaml
  flutter:
    assets:
      - assets/books/<kitap_id>/
      - assets/images/
  ```
- [ ] `flutter pub get` çalıştırıldı
- [ ] `flutter run` ile test edildi

---

## 🎨 InteractiveBookScreen Özellikleri

Mevcut ekran şu özelliklere sahiptir:

| Özellik | Açıklama |
|---------|----------|
| **Kelime Seçimi** | Tıklanan kelime mavi renkte vurgulanır |
| **Anlam Balonu** | Seçilen kelimenin üstünde Türkçe anlam gösterilir |
| **TTS (Okuma)** | Kelimeye tıklayınca sesli okunur |
| **Otomatik Okuma** | Play butonuyla tüm metin sırayla okunur |
| **Ses Kontrolü** | Sesi aç/kapa butonu |
| **Ayarlar** | Yazı boyutu ve okuma hızı ayarlanabilir |
| **Karanlık Mod** | Tema desteği (widget.isDarkMode) |

---

## 📝 Örnek: Yeni Kitap Ekleme

### Senaryo: "Siyer-i Nebi" kitabı eklemek

1. **Klasör oluştur:**
   ```
   assets/books/siyer_nebi/
   ```

2. **full_book.json oluştur:**
   ```json
   {
       "book_id": "siyer_nebi",
       "title": "Siyer-i Nebi",
       "kelimeler": [
           {"type": "word", "arapca": "وُلِدَ", "turkce": "Doğdu"},
           {"type": "word", "arapca": "النَّبِيُّ", "turkce": "Peygamber"},
           {"type": "newline"},
           {"type": "word", "arapca": "فِي", "turkce": "içinde"},
           {"type": "word", "arapca": "مَكَّةَ", "turkce": "Mekke"}
       ]
   }
   ```

3. **Kapak görseli ekle:**
   ```
   assets/images/siyer_nebi.jpg
   ```

4. **BookStoreService'e ekle:**
   ```dart
   BookInfo(
     id: 'siyer_nebi',
     title: 'Siyer-i Nebi',
     subtitle: 'Peygamber Efendimizin Hayatı',
     priceText: 'Satın Al',
     imageBase: 'assets/images/siyer_nebi',
   ),
   ```

5. **pubspec.yaml kontrol et:**
   ```yaml
   assets:
     - assets/books/siyer_nebi/
   ```

6. **Test et:**
   ```bash
   flutter pub get
   flutter run
   ```

---

## 🚫 Kullanılmayan Eski Özellikler (Kaldırıldı)

Aşağıdaki özellikler artık kullanılmıyor:
- `lesson_XX.json` dosyaları (tek `full_book.json` kullanılıyor)
- Font değiştirme ayarı (Scheherazade New sabit)
- Üst navigasyon (AppBar) - Kaldırıldı
- Geri butonu - Kaldırıldı

---

## 📞 Destek

Bu şablon hakkında sorularınız varsa veya yardıma ihtiyacınız olursa, kod tabanını inceleyebilir veya geliştiriciyle iletişime geçebilirsiniz.

---

*Son Güncelleme: 24 Aralık 2025*
