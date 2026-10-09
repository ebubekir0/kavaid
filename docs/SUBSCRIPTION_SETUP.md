# 💳 Kavaid - Gerçek Abonelik Sistemi Kurulum Rehberi

## 🎯 Sistem Özellikleri
- ✅ Aylık 50 TL otomatik yenilenen abonelik
- ✅ Sınırsız kelime erişimi
- ✅ Reklamsız deneyim
- ✅ iOS ve Android desteği
- ✅ Güvenli receipt validation
- ✅ Cihaz değişikliğinde restore desteği

---

## 🔥 ÖNEMLİ: GERÇEK PRODUCTION KURULUMU

### ⚠️ Sıra Çok Önemli!
1. **ÖNCE** Google Play Console ve App Store Connect'te ürünleri oluşturun
2. **SONRA** uygulamayı store'lara yükleyin
3. **EN SON** test edin

---

## 📱 ANDROID - Google Play Console Kurulumu

### 1️⃣ Google Play Console'da Abonelik Oluşturma

1. [Google Play Console](https://play.google.com/console) → Uygulamanız
2. **Monetization** → **Products** → **Subscriptions**
3. **Create subscription** butonuna tıklayın

**Gerekli Bilgiler:**
```
Product ID: kavaid_monthly_subscription
Subscription name: Kavaid Premium
Description: Sınırsız kelime detayları ve reklamsız deneyim

Base plan:
- Billing period: Monthly (1 month)
- Price: 50.00 TRY
- Grace period: 3 days
- Auto-renewal: ON
```

### 2️⃣ Test Kullanıcıları Ayarlama

1. **Setup** → **License testing**
2. Test e-mail adreslerinizi ekleyin
3. **License response**: RESPOND_NORMALLY

### 3️⃣ Android Uygulama Ayarları

**AndroidManifest.xml** zaten hazır, kontrol edin:
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

---

## 🍎 iOS - App Store Connect Kurulumu

### 1️⃣ App Store Connect'te Abonelik Oluşturma

1. [App Store Connect](https://appstoreconnect.apple.com) → Uygulamanız
2. **Features** → **In-App Purchases**
3. **+** → **Auto-Renewable Subscription**

**Gerekli Bilgiler:**
```
Reference Name: Kavaid Premium Monthly
Product ID: kavaid_monthly_subscription
Subscription Group: Kavaid Premium Group
Duration: 1 Month
Price: Tier 7 (≈50 TRY)
```

### 2️⃣ Subscription Group Ayarlama

1. **Subscription Group** oluşturun
2. **Group Reference Name**: KavaidPremium
3. **Localization** → Türkçe açıklamalar ekleyin

### 3️⃣ iOS Uygulama Ayarları

**Xcode'da:**
1. **Signing & Capabilities** → **+ Capability**
2. **In-App Purchase** ekleyin

---

## 🧪 TEST ETME SÜRECİ

### 🤖 Android Test

1. **Internal Testing Track'e Yükleme:**
   ```bash
   flutter build appbundle --release
   ```
   - APK'yı Google Play Console → Testing → Internal testing'e yükleyin

2. **Test Kullanıcısı Olarak Test:**
   - Test e-mailini Google Play Console'a ekleyin
   - Google Play Store'dan uygulamayı indirin
   - Abonelik satın alma işlemini test edin
   - **ÖNEMLİ**: Test ortamında gerçek para kesılmez!

3. **Test Senaryoları:**
   - ✅ Abonelik satın alma
   - ✅ Premium özelliklerin açılması
   - ✅ Uygulama kapatıp açma (restore)
   - ✅ İptal etme

### 🍎 iOS Test

1. **TestFlight'a Yükleme:**
   ```bash
   flutter build ios --release
   ```
   - Xcode ile Archive → TestFlight'a yükleyin

2. **Sandbox Test Hesabı:**
   - App Store Connect → Users and Roles → Sandbox Testers
   - Test hesabı oluşturun

3. **Test Cihazında:**
   - Settings → App Store → Sandbox Account ile giriş yapın
   - TestFlight'tan uygulamayı indirin
   - Test satın almaları yapın

---

## 🔒 GÜVENLİK - Receipt Validation

### Production'da Mutlaka Yapılması Gerekenler:

1. **Google Play Billing Library v5+** kullanın
2. **Server-side receipt validation** yapın
3. **Purchase token'ları** sunucunuzda doğrulayın

**Örnek Validation Endpoint:**
```
POST https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}
```

---

## 🚀 PRODUCTION'A GEÇİŞ

### ✅ Production Checklist

**Google Play Console:**
- [ ] Subscription ürünü oluşturuldu ve aktif
- [ ] Pricing ve billing country ayarları yapıldı
- [ ] App Bundle yüklendi ve incelemeye gönderildi
- [ ] Privacy Policy ve Terms of Service linkleri eklendi

**App Store Connect:**
- [ ] Auto-renewable subscription oluşturuldu
- [ ] Subscription group ayarlandı
- [ ] App Store Review için gönderildi
- [ ] In-App Purchase review geçti

**Uygulama Kodu:**
- [ ] Product ID'ler doğru: `kavaid_monthly_subscription`
- [ ] Error handling tamamlandı
- [ ] Loading states eklendi
- [ ] Restore purchases çalışıyor

### 🎯 CANLI TEST ADAMLARI

**1. Gerçek Para Test (Dikkatli!):**
- Gerçek hesaplarla küçük test satın almaları yapın
- Hemen iptal edin (para iadesi için)

**2. Family & Friends Test:**
- Güvenilir kişilerle test edin
- İptal süreçlerini test edin

---

## 📊 MONİTÖRİNG & ANALİTİK

### Revenue Takibi:
1. **Google Play Console** → Analytics → Financial reports
2. **App Store Connect** → Analytics → Sales and Trends

### Subscription Health:
- Churn rate (iptal oranı)
- Retention rate (devam oranı)  
- Revenue per user

---

## 🆘 SORUN GİDERME

### "Ürün Bulunamadı" Hatası:
```
❌ Sebep: Product ID yanlış veya ürün inaktif
✅ Çözüm: 
1. Product ID'yi kontrol edin: kavaid_monthly_subscription
2. Google Play Console'da ürünün ACTIVE olduğunu kontrol edin
3. Uygulamanın store'da yayında olduğunu kontrol edin
```

### "Satın Alma Başarısız" Hatası:
```
❌ Sebep: Test kullanıcısı değil veya network problemi
✅ Çözüm:
1. Test kullanıcısı listesinde olduğunuzu kontrol edin
2. İnternet bağlantısını kontrol edin
3. Google Play Store'u güncelleyin
```

### "Receipt Validation Failed":
```
❌ Sebep: Sunucu tarafı doğrulama problemi
✅ Çözüm:
1. Google Play API anahtarlarını kontrol edin
2. Server endpoint'lerini test edin
3. Purchase token'ın geçerli olduğunu kontrol edin
```

---

## 📞 DESTEK & İLETİŞİM

- **Developer Support**: Google Play Developer Support
- **Documentation**: [In-App Purchase Flutter Docs](https://pub.dev/packages/in_app_purchase)
- **Community**: Stack Overflow, Flutter Community

---

## 🎉 BAŞARI METRIKLERI

Production'da takip edilmesi gerekenler:
- ✅ Subscription conversion rate: %X
- ✅ Monthly churn rate: <%X
- ✅ Average revenue per user: ₺X
- ✅ Customer lifetime value: ₺X

**🎯 İlk hedef: Stabil %5+ conversion rate ile başlayın!** 