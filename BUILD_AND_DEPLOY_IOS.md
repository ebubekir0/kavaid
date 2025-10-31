# iOS Build ve Deploy Rehberi

## 🛠 Gereksinimler

- macOS bilgisayar (veya CI/CD servisi)
- Xcode 14.0+ yüklü
- Apple Developer hesabı ($99/yıl)
- Flutter 3.0+ yüklü

## 📱 Build Adımları

### 1. Temizlik ve Hazırlık
```bash
# Proje dizinine git
cd kavaid

# Temizlik yap
flutter clean
rm -rf ios/Pods
rm ios/Podfile.lock

# Bağımlılıkları güncelle
flutter pub get

# iOS bağımlılıklarını yükle
cd ios
pod install
cd ..
```

### 2. Version Güncelleme

`pubspec.yaml` dosyasını düzenle:
```yaml
version: 3.0.4+3004  # version: major.minor.patch+buildNumber
```

### 3. Debug Build (Test için)
```bash
# iOS Simulator için
flutter build ios --debug --simulator

# Gerçek cihaz için
flutter build ios --debug
```

### 4. Release Build (App Store için)
```bash
# Release build oluştur
flutter build ios --release

# veya doğrudan IPA oluştur
flutter build ipa --release
```

## 📦 Xcode'da Archive ve Upload

### 1. Xcode'u Açın
```bash
open ios/Runner.xcworkspace
```

### 2. Signing & Capabilities
1. Runner target'ı seçin
2. Signing & Capabilities sekmesi
3. Team seçin (Apple Developer hesabınız)
4. Bundle Identifier: `com.onbir.kavaid`
5. ✅ Automatically manage signing

### 3. Capabilities Kontrol
- ✅ In-App Purchase
- ✅ Push Notifications (Firebase için)

### 4. Archive Oluşturma
1. Scheme: Runner
2. Device: Generic iOS Device / Any iOS Device
3. Product > Archive (⌘+Shift+B)
4. Bekleme süresi: 5-10 dakika

### 5. Upload to App Store
1. Archives Organizer açılır
2. Distribute App
3. App Store Connect
4. Upload
5. Seçenekler:
   - ✅ Include bitcode for iOS content
   - ✅ Upload your app's symbols
6. Next > Upload

## 🔧 Sorun Giderme

### "No valid code signing identity found"
```bash
# Sertifikaları yenile
xcodebuild -showBuildSettings
flutter doctor -v
```

### "Profile doesn't match the entitlements"
1. Xcode > Preferences > Accounts
2. Download Manual Profiles
3. Clean build folder (⌘+Shift+K)

### Pod install hataları
```bash
cd ios
pod deintegrate
pod cache clean --all
pod install
```

### Archive butonu disabled
- Generic iOS Device seçili olmalı
- Simulator seçili olmamalı

## 📲 TestFlight Dağıtımı

### 1. App Store Connect
1. My Apps > Kavaid
2. TestFlight sekmesi
3. iOS builds altında yeni build görünür (15-30 dk)

### 2. Test Information
```
What to Test: 
- In-App Purchase flows
- Remove ads functionality
- Book purchases
- Restore purchases

Test Account:
Email: test@kavaid.com
Password: Test1234!
```

### 3. Internal Testing
1. Internal Testing > (+) New Group
2. Grup adı: "Beta Testers"
3. Tester ekle (email adresleri)
4. Build seç > Save

### 4. External Testing
1. External Testing > (+) New Group
2. Grup adı: "Public Beta"
3. Build seç
4. Test Information doldur
5. Submit for Review (24 saat)

## 🚀 App Store Submission

### 1. Version Hazırlığı
1. App Store Connect > (+) Version
2. Version Number: 3.0.4
3. What's New:
   ```
   • Satın alma sistemi iyileştirmeleri
   • iOS 17 uyumluluk güncellemeleri
   • Performans iyileştirmeleri
   • Hata düzeltmeleri
   ```

### 2. Build Seçimi
1. Build bölümü > Select a build
2. TestFlight'tan test edilmiş build seç

### 3. Review Information
```
Sign-in Required: Yes
Username: test@kavaid.com
Password: Test1234!
Notes: First 3 lessons are free. Purchase required for full access.
```

### 4. Submit for Review
1. Save
2. Submit for Review
3. Advertising Identifier: No (IDFA kullanmıyoruz)
4. Submit

## ⏱ Süre Tahminleri

- **Build süresi:** 5-10 dakika
- **Archive süresi:** 5-10 dakika
- **Upload süresi:** 5-15 dakika
- **Processing süresi:** 15-60 dakika
- **TestFlight Beta Review:** 24 saat
- **App Store Review:** 24-48 saat

## 📝 Checklist

### Build Öncesi
- [ ] Version numarası güncellendi
- [ ] GoogleService-Info.plist mevcut
- [ ] Entitlements dosyası doğru
- [ ] Team ID seçildi

### Test
- [ ] Debug build çalışıyor
- [ ] IAP testleri yapıldı
- [ ] Restore purchase test edildi
- [ ] Crash yok

### Submission
- [ ] Screenshots hazır
- [ ] Description güncel
- [ ] Privacy Policy linki çalışıyor
- [ ] Review notes hazır

## 🆘 Acil Durumlar

### Expedited Review İsteği
Kritik bug fix için hızlandırılmış inceleme:
1. Contact Us > Request Expedited Review
2. Sebep: Critical bug affecting users
3. 6-24 saat içinde sonuç

### Rejection Durumu
1. Resolution Center'dan feedback alın
2. Sorunu düzeltin
3. Reply to App Review
4. Resubmit

## 📊 Post-Release

### Monitoring
- App Store Connect > App Analytics
- Crash Reports kontrol
- Customer Reviews takip
- Sales Reports inceleme

### Phased Release (Aşamalı Yayın)
1. Version > Phased Release
2. 7 günde %100 kullanıcıya ulaş:
   - Gün 1: %1
   - Gün 2: %2  
   - Gün 3: %5
   - Gün 4: %10
   - Gün 5: %20
   - Gün 6: %50
   - Gün 7: %100

## Notlar
- Her zaman TestFlight'ta test edin
- Production'a geçmeden önce en az 24 saat bekleyin
- Critical bug varsa Expedited Review kullanın
- Pazartesi-Perşembe submit edin (hızlı review)
