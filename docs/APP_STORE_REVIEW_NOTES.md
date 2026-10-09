# App Store İnceleme Notları - Kavaid

## 🎯 Uygulama Hakkında
Kavaid, Kur'an-ı Kerim'in doğru okunmasını öğreten eğitim uygulamasıdır.

## 💳 Uygulama İçi Satın Almalar

### Test Hesabı (Sandbox)
```
Email: test@kavaid.com
Şifre: Test1234!
```

### Ürünler ve SKU'lar

#### 1. Kavaid Premium Aylık Abonelik (Auto-Renewable Subscription)
- **SKU:** `kavaid_premium_monthly` (veya `kavaid_monthly_subscription`)
- **Fiyat:** ₺79,99 / ay
- **Açıklama:** Sınırsız kelime detayları, çekimler, sözlük ve reklamsız deneyim

#### 2. Kavaid Premium Yıllık Abonelik (Auto-Renewable Subscription)
- **SKU:** `kavaid_premium_yearly` (veya `kavaid_yearly_subscription`)
- **Fiyat:** ₺479,99 / yıl
- **Açıklama:** 1 yıl boyunca tüm özelliklere sınırsız erişim (%50 indirimli)

#### 3. Reklamları Kaldır (Non-Consumable)
- **SKU:** `kavaid_remove_ads_lifetime`
- **Fiyat:** ₺69,99
- **Açıklama:** Uygulamadaki tüm reklamları kalıcı olarak kaldırır

#### 4. Kitabul Kıraat 1 (Non-Consumable)
- **SKU:** `kavaid_kitab_kiraah_1`
- **Fiyat:** ₺89,99
- **Açıklama:** Temel Kıraat Eğitimi kitabının tamamına erişim

#### 5. Kitabul Kıraat 2 (Non-Consumable)
- **SKU:** `kavaid_book_kiraat_2`
- **Fiyat:** ₺89,99
- **Açıklama:** İleri Seviye Kıraat kitabının tamamına erişim

#### 6. Kitabul Kıraat 3 (Non-Consumable)
- **SKU:** `kavaid_book_kiraat_3`
- **Fiyat:** ₺89,99
- **Açıklama:** Uzman Seviye Kıraat kitabının tamamına erişim

## ✅ App Store Gereksinimleri

### İzinler ve Kullanım Amaçları

#### Fotoğraf Kütüphanesi
- **Kullanım:** Profil fotoğrafı değiştirme
- **Teknoloji:** iOS Photo Picker (izin gerektirmez)
- **Not:** Sadece kullanıcı tetiklemesi ile açılır

#### Mikrofon (Opsiyonel)
- **Kullanım:** Sesli komutlar ve konuşma tanıma
- **Not:** Kullanıcı reddederse uygulama çalışmaya devam eder

#### İnternet
- **Kullanım:** Firebase, satın alma doğrulama, içerik senkronizasyonu
- **Not:** Offline modda da çalışır (sınırlı özellikler)

### Güvenlik ve Gizlilik

1. **HTTPS Kullanımı:** Tüm API çağrıları HTTPS üzerinden
2. **Şifreleme:** ITSAppUsesNonExemptEncryption = false (sadece HTTPS)
3. **Veri Toplama:** Analytics için anonim kullanım verileri
4. **COPPA Uyumluluğu:** 13 yaş altı kullanıcılar için uygun değil

## 🧪 Test Senaryoları

### Senaryo 1: İlk Kurulum
1. Uygulamayı yeni yükleyin
2. Hesap oluşturun
3. Ücretsiz içerikleri kullanın (ilk 3 ders)
4. Reklamlı deneyimi test edin

### Senaryo 2: Satın Alma
1. Test hesabıyla giriş yapın
2. Sandbox ortamında satın alma yapın
3. Satın almanın başarıyla tamamlandığını doğrulayın
4. İçeriğin açıldığını kontrol edin

### Senaryo 3: Restore Purchase
1. Uygulamayı silin ve yeniden yükleyin
2. Aynı hesapla giriş yapın
3. Profil > Debug > Restore Test'e tıklayın
4. Satın almaların geri yüklendiğini doğrulayın

## 📱 Desteklenen Cihazlar

- **iOS Minimum:** 15.0
- **iPhone:** 6s ve üzeri
- **iPad:** Desteklenir
- **Orientation:** Portrait only

## 🚨 Önemli Notlar

1. **Sandbox Test:** App Store Connect'te test kullanıcısı eklemeniz gerekir
2. **Production:** Gerçek satın almalar için App Store Connect'te ürünler onaylanmalı
3. **Firebase:** GoogleService-Info.plist dosyası gerekli
4. **AdMob:** Test cihazları için test reklamları gösterilir

## 📞 İletişim
Sorunuz olursa: support@kavaid.com

## ✉️ Apple Review Ekibine Gönderilecek Yanıt Şablonu

```text
Hello Apple Review Team,

Thank you for your feedback. We have addressed the issue regarding In-App Purchases (Guideline 2.1(b) - Performance - App Completeness).

1. In-App Purchase and Subscription Products:
We have verified that the Auto-Renewable Subscriptions (Monthly and Yearly) and Non-Consumable products are active and configured in App Store Connect.
- Monthly Subscription: kavaid_premium_monthly (or kavaid_monthly_subscription)
- Yearly Subscription: kavaid_premium_yearly (or kavaid_yearly_subscription)
- Remove Ads: kavaid_remove_ads_lifetime

2. App Implementation:
We updated the StoreKit product fetching logic, handled dynamic localized price display, strengthened fallback product identifiers, and improved error handling / retry flow on the subscription screen to ensure a seamless purchasing experience in the sandbox environment.

3. Testing:
We tested the purchase flow in the Sandbox environment, and both subscription tiers as well as in-app purchases complete successfully.

Please let us know if any further information is needed. Thank you for your review.

Best regards,
Kavaid Team
```

## Değişiklik Geçmişi
- v4.0.1: App Store Review IAP & Subscription (StoreKit) geliştirmeleri ve dinamik fiyatlandırma
- v3.0.4: iOS satın alma sistemi eklendi
- v3.0.3: Android Photo Picker entegrasyonu
- v3.0.2: Restore purchase düzeltmesi

