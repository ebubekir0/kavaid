# App Store Connect Kurulum Adımları

## 1. 🎯 Uygulamayı App Store Connect'e Ekleyin

### Yeni Uygulama Oluşturma
1. [App Store Connect](https://appstoreconnect.apple.com) açın
2. My Apps > (+) > New App
3. Bilgileri doldurun:
   - **Platform:** iOS
   - **Name:** Kavaid
   - **Primary Language:** Turkish
   - **Bundle ID:** com.onbir.kavaid
   - **SKU:** KAVAID_IOS_2024

## 2. 💰 In-App Purchase Ürünlerini Tanımlayın

### Features > In-App Purchases

#### Ürün 1: Reklamları Kaldır
1. (+) > Non-Consumable
2. Bilgileri girin:
   ```
   Reference Name: Remove Ads Lifetime
   Product ID: kavaid_remove_ads_lifetime
   ```
3. Pricing > ₺69.99 (Tier 5)
4. Localizations:
   - **TR:** "Reklamları Kaldır" / "Tüm reklamları kalıcı olarak kaldırır"
   - **EN:** "Remove Ads" / "Remove all ads permanently"
5. Review Screenshot yükleyin (640x920 min)
6. Save

#### Ürün 2: Kitabul Kıraat 1
1. (+) > Non-Consumable
2. Bilgileri girin:
   ```
   Reference Name: Book Kiraat 1
   Product ID: kavaid_kitab_kiraah_1
   ```
3. Pricing > ₺89.99 (Tier 6)
4. Localizations:
   - **TR:** "Kitabul Kıraat 1" / "Temel Kıraat Eğitimi"
   - **EN:** "Book of Kiraat 1" / "Basic Kiraat Education"
5. Review Screenshot yükleyin
6. Save

#### Ürün 3 ve 4: Aynı şekilde ekleyin
- `kavaid_book_kiraat_2`
- `kavaid_book_kiraat_3`

## 3. 📝 App Information Düzenlemeleri

### General > App Information
- **Category:** Education
- **Secondary Category:** Books
- **Content Rights:** Own all rights

### Age Rating
1. Edit Rating
2. Seçenekler:
   - Violence: None
   - Sexual Content: None
   - Profanity: None
   - Medical: None
   - Gambling: None
   - Horror: None
   - Alcohol/Drugs: None
   - Mature/Suggestive: None
   - Contests: None
   - Unrestricted Web Access: No
3. Age Rating: 4+

## 4. 🏦 Agreements, Tax, and Banking

### Paid Apps Agreement (ZORUNLU!)
1. Agreements, Tax, and Banking sayfasına gidin
2. Paid Apps > View and Agree
3. Sözleşmeyi okuyun ve kabul edin

### Banking Information
1. Add Bank Account
2. Türkiye için bilgiler:
   - Account Holder Type: Individual/Company
   - Bank Country: Turkey
   - IBAN girin
   - SWIFT kodu girin
3. Save

### Tax Forms
1. U.S. Tax Forms > Setup
2. W-8BEN formunu doldurun (Türkiye vatandaşları için)
3. Certificate of Tax Residency yükleyin (opsiyonel)

## 5. 🧪 TestFlight Kurulumu

### Internal Testing
1. TestFlight sekmesine gidin
2. Internal Testing > Create Group
3. Test kullanıcıları ekleyin
4. Build yükleyin (Xcode'dan)

### Sandbox Testers
1. Users and Access > Sandbox
2. Testers > (+)
3. Test hesapları oluşturun:
   ```
   Email: test1@kavaid.com
   Password: Test1234!
   Country: Turkey
   ```

## 6. 📱 App Submission Hazırlığı

### Version Information
1. Prepare for Submission
2. Screenshots (zorunlu):
   - 6.7" (iPhone 15 Pro Max): 1290 × 2796
   - 6.5" (iPhone 14 Plus): 1242 × 2688
   - 5.5" (iPhone 8 Plus): 1242 × 2208
   - iPad Pro 12.9": 2048 × 2732

### Description
```
Kavaid - Kur'an-ı Kerim'i Doğru Okuma Rehberi

Özellikler:
• Tecvid kuralları
• Harflerin mahreçleri
• Kitabul Kıraat serisi
• Kelime kelime takip
• Sesli okuma
```

### Keywords
```
kuran, tecvid, kıraat, islam, dua, namaz, arapça
```

### Support URL
```
https://kavaid.com/support
```

### Privacy Policy URL (ZORUNLU!)
```
https://kavaid.com/privacy
```

## 7. ✅ Submission Checklist

### Genel
- [ ] Bundle ID doğru (com.onbir.kavaid)
- [ ] Version numarası güncellendi
- [ ] Build numarası arttırıldı

### In-App Purchases
- [ ] Tüm ürünler tanımlandı
- [ ] Fiyatlar belirlendi
- [ ] Lokalizasyonlar eklendi
- [ ] Review screenshot'ları yüklendi

### Sözleşmeler
- [ ] Paid Apps Agreement imzalandı
- [ ] Banking bilgileri girildi
- [ ] Tax formları dolduruldu

### Test
- [ ] TestFlight'ta test edildi
- [ ] Sandbox testleri yapıldı
- [ ] Restore purchase çalışıyor

### Metadata
- [ ] Açıklama yazıldı
- [ ] Screenshot'lar yüklendi
- [ ] Privacy Policy linki eklendi
- [ ] Support URL eklendi

## 8. 🚨 Dikkat Edilmesi Gerekenler

### App Review Süreci
- İlk submission 24-48 saat sürer
- In-App Purchase'lar ayrı review'dan geçer
- Rejection durumunda Resolution Center'dan iletişim kurulur

### Yaygın Red Sebepleri
- Eksik screenshot
- Privacy Policy yok
- IAP açıklamaları yetersiz
- Test hesabı çalışmıyor
- Crashes/bugs

### Review Notes'a Ekleyin
```
Test Account: test1@kavaid.com
Password: Test1234!

How to test IAP:
1. Login with test account
2. Go to Profile > Remove Ads
3. Complete purchase
4. Verify ads are removed

All books have first 3 lessons free.
Purchase required for lesson 4+.
```

## 9. 📊 Analytics ve Raporlar

### Sales and Trends
- Günlük satış raporları
- IAP gelir detayları
- Ülke bazlı analizler

### Payments and Financial Reports
- Aylık ödemeler
- Vergi kesintileri
- Transfer detayları

## 10. 🔄 Güncelleme Süreci

### Yeni Version
1. Xcode'da Archive > Upload
2. App Store Connect'te version oluştur
3. Build seç
4. Submit for Review

### IAP Güncellemeleri
- Fiyat değişiklikleri anında
- Yeni ürün eklemek review gerektirir
- Lokalizasyon güncellemeleri anında

## Notlar
- Türkiye'de %18 KDV Apple tarafından otomatik hesaplanır
- Kullanıcı ₺69.99 öder, siz ~₺40.88 alırsınız (Apple %30 + KDV)
- İlk $1M gelir için Small Business Program'a başvurun (%15 komisyon)
