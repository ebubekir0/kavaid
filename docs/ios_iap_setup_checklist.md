# iOS In-App Purchase Kurulum Kontrol Listesi

## 1. ✅ Apple Developer Account Ayarları

### App ID Configuration
1. developer.apple.com'a gidin
2. Certificates, Identifiers & Profiles > Identifiers
3. App ID'nizi bulun (com.onbir.kavaid)
4. Capabilities'de "In-App Purchase" aktif olmalı ✓

### Provisioning Profile
1. Provisioning Profiles'a gidin
2. App Store Distribution profile oluşturun/güncelleyin
3. In-App Purchase capability dahil olmalı

## 2. ✅ App Store Connect Ürün Tanımlamaları

### Ürün Oluşturma (App Store Connect)
1. appstoreconnect.apple.com'a gidin
2. My Apps > Kavaid
3. Features > In-App Purchases
4. (+) butonuna tıklayarak ürün ekleyin:

#### Ürün 1: Reklamları Kaldır
```
Product ID: kavaid_remove_ads_lifetime
Type: Non-Consumable
Reference Name: Remove Ads Lifetime
Price: Tier 5 (₺69,99)
```

#### Ürün 2: Kitabul Kıraat 1
```
Product ID: kavaid_kitab_kiraah_1
Type: Non-Consumable
Reference Name: Book Kiraat 1
Price: Tier 6 (₺89,99)
```

#### Ürün 3: Kitabul Kıraat 2
```
Product ID: kavaid_book_kiraat_2
Type: Non-Consumable
Reference Name: Book Kiraat 2
Price: Tier 6 (₺89,99)
```

#### Ürün 4: Kitabul Kıraat 3
```
Product ID: kavaid_book_kiraat_3
Type: Non-Consumable
Reference Name: Book Kiraat 3
Price: Tier 6 (₺89,99)
```

## 3. ✅ Lokalleştirme (Her Ürün İçin)

### Türkçe (TR)
- Display Name: [Yukarıdaki isimleri kullanın]
- Description: [APP_STORE_REVIEW_NOTES.md'deki açıklamaları kullanın]
- Screenshot: 1242x2208px (iPhone gereksinimi)

### İngilizce (EN)
- Display Name: [İngilizce versiyonları]
- Description: [İngilizce açıklamalar]
- Screenshot: Aynı görsel kullanılabilir

## 4. ✅ Sözleşmeler ve Vergi

### Paid Apps Agreement
1. App Store Connect > Agreements, Tax, and Banking
2. Paid Apps agreement'ı imzalayın
3. Banking bilgilerini girin
4. Tax formlarını doldurun

## 5. ✅ Sandbox Test Kullanıcıları

### Test Hesapları Oluşturma
1. App Store Connect > Users and Access
2. Sandbox > Testers
3. (+) ile test kullanıcısı ekleyin:
```
Email: sandbox1@kavaid.com
Password: Test1234!
Country: Turkey
```

## 6. ✅ Xcode Proje Ayarları

### Capabilities
1. Xcode'da projeyi açın
2. Runner target'ı seçin
3. Signing & Capabilities
4. "+ Capability" > In-App Purchase ekleyin

### Entitlements
- ✅ Runner.entitlements dosyası oluşturuldu
- ✅ In-App Purchase capability eklendi

## 7. ✅ Test Etme

### Simulator'de Test
1. Xcode > Product > Scheme > Edit Scheme
2. Run > Options > StoreKit Configuration
3. Configuration.storekit dosyasını seçin

### Gerçek Cihazda Test
1. Cihazda Settings > App Store > Sandbox Account
2. Sandbox hesabıyla giriş yapın
3. Uygulamada satın alma test edin

## 8. ✅ App Store Review İçin Hazırlık

### Review Information
```
Test Account: sandbox1@kavaid.com
Password: Test1234!
Notes: Lütfen APP_STORE_REVIEW_NOTES.md dosyasını okuyun
```

### Screenshot'lar
- Satın alma ekranının screenshot'ı
- Başarılı satın alma sonrası ekran
- Restore purchase ekranı

## 9. ⚠️ Yaygın Sorunlar ve Çözümleri

### "Cannot connect to iTunes Store"
- Paid Apps Agreement imzalanmamış
- Banking bilgileri eksik

### "Invalid Product IDs"
- Product ID'ler App Store Connect'te oluşturulmamış
- Ürünler "Ready to Submit" durumunda değil

### "User cancelled"
- Sandbox hesabıyla giriş yapılmamış
- Cihazda farklı Apple ID aktif

## 10. 📱 Production Checklist

- [ ] Tüm ürünler App Store Connect'te tanımlı
- [ ] Ürünler "Ready to Submit" durumunda
- [ ] Paid Apps Agreement imzalı
- [ ] Banking ve Tax bilgileri tam
- [ ] Review notları hazır
- [ ] Screenshot'lar yüklendi
- [ ] Sandbox testleri başarılı
- [ ] Restore purchase çalışıyor

## Notlar
- İlk submission'da ürünler otomatik onaylanır
- Sonraki güncellemelerde ayrı review gerekebilir
- Fiyat değişiklikleri anında yansır
