# Google Play Console Yükleme Rehberi

## 🚀 Hızlı Başlangıç

### 1. İmzalama Anahtarı Oluşturma

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. key.properties Dosyası Oluşturma

1. `android/key.properties.template` dosyasını `android/key.properties` olarak kopyalayın
2. Dosyadaki değerleri doldurun:
   ```
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

### 3. Release Build Oluşturma

```bash
build_release.bat
```

## 📱 Play Console'a Yükleme Adımları

### 1. Uygulama Oluşturma
- [Google Play Console](https://play.google.com/console) açın
- "Uygulama oluştur" tıklayın
- Dil: Türkçe
- Uygulama adı: Kavaid
- Uygulama türü: Uygulama
- Ücretsiz/Ücretli: Ücretsiz

### 2. Uygulama Bilgileri
- **Kısa açıklama**: Arapça-Türkçe sözlük uygulaması
- **Tam açıklama**: 
  ```
  Kavaid, Arapça öğrenenler için geliştirilmiş kapsamlı bir sözlük uygulamasıdır.
  
  Özellikler:
  • Geniş kelime veritabanı
  • Hareke desteği
  • Fiil çekimleri
  • Örnek cümleler
  • Offline kullanım
  • Kolay arama
  • Kelime kaydetme
  ```

### 3. Kategori ve Etiketler
- **Kategori**: Eğitim
- **Etiketler**: arapça, sözlük, eğitim, dil öğrenme

### 4. İçerik Derecelendirmesi
- Anketi doldurun (Herkes için uygun)

### 5. Hedef Kitle
- Yaş aralığı: 13+
- İçerik: Eğitim amaçlı

### 6. Veri Güvenliği
- Veri toplama: Firebase Analytics
- Veri paylaşımı: Yok
- Şifreleme: Evet

### 7. App Bundle Yükleme
1. Production > Releases
2. Create new release
3. `release_output/kavaid-release.aab` dosyasını yükleyin
4. Release notes ekleyin

### 8. Store Listing Görselleri

#### Gerekli Görseller:
- **Uygulama ikonu**: 512x512 PNG
- **Öne çıkan grafik**: 1024x500 PNG
- **Telefon ekran görüntüleri**: En az 2 adet (1080x1920)
- **Tablet ekran görüntüleri**: Opsiyonel

### 9. Test ve Yayınlama
1. Internal testing ile test edin
2. Closed testing (kapalı test)
3. Open testing (açık test)
4. Production release

## 🔧 Optimizasyon Kontrol Listesi

- [x] ProGuard/R8 etkin
- [x] App Bundle (.aab) formatı
- [x] Split APK desteği
- [x] Minify ve shrink resources
- [x] Multi-dex desteği
- [x] Target SDK 34
- [x] AdMob entegrasyonu
- [x] Firebase entegrasyonu
- [x] In-App Purchase hazır

## 📊 Performans Metrikleri

### Beklenen APK Boyutları:
- ARM64: ~15-20 MB
- ARMv7: ~14-18 MB
- x86_64: ~16-21 MB

### Minimum Gereksinimler:
- Android 5.0 (API 21)
- RAM: 2GB
- Depolama: 50MB

## 🐛 Sorun Giderme

### Build Hataları:
```bash
flutter clean
flutter pub get
build_release.bat
```

### Signing Hatası:
- key.properties dosyasını kontrol edin
- Keystore dosyasının yerini kontrol edin

### Upload Hatası:
- Version code'u artırın (pubspec.yaml)
- Package name'i kontrol edin

## 📞 Destek

Sorunlar için:
1. Flutter doctor çalıştırın
2. test_app.bat ile test edin
3. Logları kontrol edin

## ✅ Yayınlama Öncesi Kontrol Listesi

- [ ] Tüm testler başarılı
- [ ] Release build başarılı
- [ ] APK boyutları makul
- [ ] Görseller hazır
- [ ] Store listing bilgileri dolu
- [ ] İçerik derecelendirmesi tamamlandı
- [ ] Veri güvenliği formu dolduruldu
- [ ] key.properties yapılandırıldı
- [ ] Version code/name güncellendi 