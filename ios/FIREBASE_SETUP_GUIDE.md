# iOS Firebase Kurulum Rehberi

## ⚠️ ÖNEMLİ: GoogleService-Info.plist Gerekli!

iOS uygulamasının çalışması için Firebase yapılandırma dosyası gereklidir.

### 📥 GoogleService-Info.plist Nasıl Alınır?

1. **Firebase Console'a Gidin**
   - https://console.firebase.google.com
   - Kavaid projenizi seçin

2. **iOS Uygulaması Ekleyin/Düzenleyin**
   - Project Settings > Your Apps
   - iOS uygulamasını bulun veya ekleyin
   - Bundle ID: `com.onbir.kavaid`

3. **Dosyayı İndirin**
   - "Download GoogleService-Info.plist" butonuna tıklayın
   - İndirilen dosyayı kaydedin

4. **Xcode'a Ekleyin**
   - Xcode'da projeyi açın
   - GoogleService-Info.plist dosyasını sürükleyip Runner klasörüne bırakın
   - "Copy items if needed" seçeneğini işaretleyin
   - Target: Runner seçili olmalı

5. **Yerleştirme**
   ```
   ios/
   └── Runner/
       ├── Info.plist
       ├── GoogleService-Info.plist  <-- BURAYA
       └── Runner.entitlements
   ```

### ✅ Kontrol Listesi

- [ ] Firebase Console'da iOS uygulaması oluşturuldu
- [ ] Bundle ID doğru: `com.onbir.kavaid`
- [ ] GoogleService-Info.plist indirildi
- [ ] Dosya Xcode'a eklendi
- [ ] Build Phases > Copy Bundle Resources'da görünüyor

### 🔧 Sorun Giderme

**"Could not find a valid GoogleService-Info.plist" hatası:**
- Dosyanın Runner klasöründe olduğundan emin olun
- Xcode'da Target Membership'in işaretli olduğunu kontrol edin

**Firebase bağlantı hataları:**
- Bundle ID'nin Firebase'deki ile aynı olduğunu kontrol edin
- APNs sertifikalarının yüklendiğinden emin olun (Push Notifications için)
