# Kavaid - Arapça Sözlük Uygulaması

Bu uygulama Flutter ile geliştirilmiş bir Arapça sözlük uygulamasıdır. Google'ın Gemini-2.5-flash-preview AI modeli kullanarak Arapça kelimelerin anlamlarını, gramer özelliklerini ve çekimlerini detaylı JSON formatında sunar.

## 🎯 Özellikler

- 🔍 **Arapça-Türkçe Kelime Arama**: Arapça veya Türkçe kelimelerin anlamlarını arayın
- 🤖 **AI Destekli**: Gemini-2.5-flash-preview modeli ile güçlendirilmiş
- 📱 **Modern UI**: Material Design 3 ile tasarlanmış
- 🔥 **Firebase Entegrasyonu**: 
  - Realtime Database ile kelime veritabanı
  - Akıllı arama algoritması
  - Bulunan kelimelerin otomatik kaydedilmesi
- ✨ **Detaylı Bilgiler**: 
  - Kelime anlamı ve harekeli yazılışı
  - Kök (köken) bilgisi
  - Gramer özellikleri (tür, çoğul form)
  - Örnek cümleler (Arapça ve Türkçe çeviri)
  - Fiil çekimleri (mazi, muzari, mastar, emir)
- 💡 **Akıllı Öneriler**:
  - Her harf girişinde anlık kelime önerileri
  - Eşleşme skoruna göre sıralama
  - Hızlı erişim için kelime kartları

## 📋 Gereksinimler

- Flutter SDK (3.8.1 veya üzeri)
- Dart SDK (3.8.1 veya üzeri)
- Firebase projesi
- Google Gemini API anahtarı

## 🚀 Kurulum

### 1. Repository'yi klonlayın
```bash
git clone <repository-url>
cd kavaid
```

### 2. Bağımlılıkları yükleyin
```bash
flutter pub get
```

### 3. Firebase Konfigürasyonu

#### Firebase Projesi Oluşturma
1. [Firebase Console](https://console.firebase.google.com/)'a gidin
2. Yeni proje oluşturun (proje adı: `kavaid-sozluk`)
3. Realtime Database'i etkinleştirin
4. Güvenlik kurallarını test moduna ayarlayın:
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

#### Firebase CLI ile Konfigürasyon
```bash
# Firebase CLI yükleyin
npm install -g firebase-tools

# Firebase'e giriş yapın
firebase login

# Flutter projesi için Firebase'i yapılandırın
flutter pub global activate flutterfire_cli
flutterfire configure
```

Bu komut otomatik olarak `lib/services/firebase_options.dart` dosyasını oluşturacaktır.

### 4. Gemini API Key Konfigürasyonu

1. [Google AI Studio](https://makersuite.google.com/app/apikey)'ya gidin
2. Yeni API key oluşturun
3. `lib/services/gemini_service.dart` dosyasındaki `_apiKey` değerini güncelleyin:

```dart
static const String _apiKey = 'YOUR_ACTUAL_GEMINI_API_KEY';
```

### 5. Arapça Font Ekleme (Opsiyonel)

Arapça metinlerin daha iyi görünmesi için Google Noto Sans Arabic fontunu indirip `assets/fonts/` klasörüne ekleyin:

1. [Google Fonts](https://fonts.google.com/noto/specimen/Noto+Sans+Arabic)'dan Noto Sans Arabic'i indirin
2. `NotoSansArabic-Regular.ttf` ve `NotoSansArabic-Bold.ttf` dosyalarını `assets/fonts/` klasörüne kopyalayın

## 🏃‍♂️ Çalıştırma

```bash
# Android emülatör veya cihazda çalıştırın
flutter run

# iOS simülatör veya cihazda çalıştırın
flutter run

# Web için çalıştırın
flutter run -d chrome
```

## 📖 Kullanım

### 🔍 Kelime Arama:
1. Arama çubuğuna Arapça veya Türkçe kelime yazmaya başlayın
2. **Otomatik öneriler** görünecek - istediğinize tıklayabilirsiniz
3. Ara butonuna basın veya Enter'a basın
4. AI modeli kelimeyi analiz ederek JSON formatında detaylı bilgi sunar

### 💡 Akıllı Öneriler:
- Her harf girişinde Firebase'den kelime önerileri gelir
- Öneriler eşleşme skoruna göre sıralanır
- Kelime kartlarına tıklayarak hızlıca erişebilirsiniz

### 🔄 Otomatik Kaydetme:
- Gemini'den gelen yeni kelimeler otomatik olarak Firebase'e kaydedilir
- Sadece `"bulunduMu": true` olan kelimeler kaydedilir
- Harekeli hali ile birlikte tam bilgi saklanır

### 📊 Sonuç Formatı:
- Kelimenin anlamı ve harekeli yazılışı
- Kök bilgisi
- Gramer özellikleri (tür, çoğul form)
- Örnek cümleler (Arapça-Türkçe)
- Fiil çekimleri (mazi, muzari, mastar, emir)

## 🛠️ Teknik Detaylar

### 🤖 AI Konfigürasyonu:
- **AI Model**: Gemini-2.5-flash-preview
- **API**: Google Gemini v1beta API
- **Temperature**: 0 (tutarlı sonuçlar)
- **Max Tokens**: 1024
- **Format**: JSON çıktı

### 🔥 Firebase Konfigürasyonu:
- **Database**: Firebase Realtime Database
- **Struktur**: `/kelimeler/{kelimeId}`
- **Arama**: Debounce ile 300ms gecikme
- **Sıralama**: Eşleşme skoruna göre

### 📱 Flutter Paketleri:
- `firebase_core`, `cloud_firestore`, `firebase_database`, `firebase_auth`: Firebase
- `purchases_flutter` (RevenueCat): Abonelik ve satın almalar
- `sqflite`: Yerel sözlük veritabanı
- `http`: Gemini API istekleri
- `json_annotation` & `json_serializable`: JSON serializasyon

## 📁 Proje Yapısı

```
kavaid/
├── lib/
│   ├── data/
│   │   ├── embedded_words.dart       # Gömülü sözlüğü asset'ten yükler
│   │   └── embedded_words_meta.dart  # Veri sürümü (otomatik üretilir)
│   ├── models/                       # Veri modelleri
│   ├── services/                     # Firebase, Gemini, satın alma, veritabanı...
│   ├── screens/                      # Ekranlar
│   ├── widgets/                      # Ortak bileşenler
│   └── main.dart                     # Uygulama girişi
├── assets/
│   ├── data/sozluk.json.gz           # Gömülü sözlük (54.971 kelime)
│   ├── books/, audio/                # Okuma kitapları ve sesleri
│   ├── fonts/                        # Arapça fontlar
│   └── images/                       # Görseller
├── test/                             # Birim testleri (flutter test)
├── tool/                             # Veri hazırlama betikleri
├── docs/                             # Yayın, IAP, güvenlik rehberleri (eski notlar: docs/arsiv)
└── pubspec.yaml                      # Bağımlılıklar
```

### 📚 Gömülü sözlüğü güncelleme

```bash
python tool/build_dictionary_asset.py SON_GUNCEL_VERITABANI_V2.json
```

Bu komut `assets/data/sozluk.json.gz` ve `lib/data/embedded_words_meta.dart`
dosyalarını üretir. Veri sürümü içerikten hesaplanır; sürüm değişince uygulama
açılışta kullanıcının yerel sözlüğünü otomatik olarak yeniden kurar.

### ✅ Test ve analiz

```bash
flutter analyze
flutter test
```

GitHub Actions (`.github/workflows/ci.yml`) bunları her push ve pull request'te çalıştırır.

## 🐛 Sorun Giderme

### Firebase Bağlantı Hatası
```
⚠️ Firebase bağlantısı kurulamadı!
```
**Çözüm**: `flutterfire configure` komutunu tekrar çalıştırın ve Firebase projesi ayarlarını kontrol edin.

### Gemini API Hatası
```
⚠️ Gemini API Key yapılandırılmamış!
```
**Çözüm**: `lib/services/gemini_service.dart` dosyasındaki API anahtarını güncelleyin.

### JSON Serialization Hatası
```
Build hatası: '...g.dart' bulunamadı
```
**Çözüm**: JSON serializasyon kodlarını yeniden generate edin:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 📄 Lisans

Bu proje MIT Lisansı ile lisanslanmıştır.

## 👨‍💻 Geliştirici

**OnBir Software**
- 📧 Email: [iletisim@onbir.software](mailto:iletisim@onbir.software)
- 🌐 Website: [onbir.software](https://onbir.software)

## 🤝 Katkıda Bulunma

1. Bu repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun

## 🙏 Teşekkürler

- [Google AI Studio](https://makersuite.google.com/) - Gemini API
- [Firebase](https://firebase.google.com/) - Backend hizmetleri
- [Flutter](https://flutter.dev/) - UI framework
- [Google Fonts](https://fonts.google.com/) - Noto Sans Arabic font

---

**Not**: Bu uygulama eğitim amaçlı geliştirilmiştir. Üretim ortamında kullanmadan önce güvenlik ayarlarını gözden geçirin.
