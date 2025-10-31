# Gemini AI Instructions Yönetimi

Bu rehber, Kavaid uygulamasında Gemini AI'ya verilen talimatları Firebase üzerinden nasıl yönetebileceğinizi açıklar.

## 🚀 Özellikler

- Firebase Realtime Database üzerinden talimatları dinamik olarak güncelleme
- Değişikliklerin anında uygulamaya yansıması
- Cache mekanizması ile performans optimizasyonu

## 📋 Firebase Yapısı

Firebase Realtime Database'de aşağıdaki yapı otomatik olarak oluşturulur:

```
kavaid-app/
├── config/
│   ├── gemini_api: "API_KEY_HERE"
│   └── gemini_instructions: "INSTRUCTIONS_HERE"
└── kelimeler/
    └── ...
```

## 🔧 Instructions Güncelleme

### 1. Firebase Console'a Giriş

1. [Firebase Console](https://console.firebase.google.com/)'a gidin
2. Kavaid projesini seçin
3. Sol menüden "Realtime Database" seçeneğine tıklayın

### 2. Instructions'ı Bulma

Database içinde şu yolu takip edin:
```
config → gemini_instructions
```

### 3. Instructions'ı Düzenleme

1. `gemini_instructions` alanının yanındaki değere tıklayın
2. Açılan editörde talimatları düzenleyin
3. **ÖNEMLİ**: `[WORD]` placeholder'ını kullanmayı unutmayın. Bu, aranacak kelime ile değiştirilecektir.

### 4. Varsayılan Instructions Formatı

```
YAPAY ZEKA İÇİN GÜNCEL VE KESİN TALİMATLAR

Sen bir Arapça sözlük uygulamasısın. Kullanıcıdan Arapça veya Türkçe bir kelime al ve gramer özelliklerini dikkate alarak detaylı bir tarama yap.
Sadece kesin olarak bildiğin ve doğrulayabildiğin bilgileri sun. 
Bilmediğin veya emin olmadığın hiçbir bilgiyi uydurma ya da tahmin etme. Çıktıyı aşağıdaki JSON formatında üret.

Kelime: "[WORD]"

{
  "bulunduMu": true,
  "kelimeBilgisi": {
    ...
  }
}
```

## 🔄 Cache Yönetimi

### Cache Süresi
- Instructions 30 dakika boyunca cache'lenir
- Bu süre boyunca değişiklikler uygulamaya yansımaz

### Cache'i Temizleme
Değişikliklerin hemen yansıması için:

1. **Uygulama İçinden**: 
   - Profil sayfasına gidin
   - "Önbelleği Temizle" seçeneğine tıklayın

2. **Otomatik Temizlenme**:
   - Uygulama her açıldığında cache süresi kontrol edilir
   - 30 dakika geçmişse otomatik olarak yeni instructions alınır

## 📝 Instructions Yazma İpuçları

### Yapılması Gerekenler:
- ✅ `[WORD]` placeholder'ını kullanın
- ✅ JSON formatını net bir şekilde belirtin
- ✅ Gramer kurallarını açık yazın
- ✅ Örnek çıktı verin

### Yapılmaması Gerekenler:
- ❌ `$word` gibi farklı placeholder formatları kullanmayın
- ❌ JSON dışında format talep etmeyin
- ❌ Çok uzun ve karmaşık talimatlar yazmayın

## 🛠️ Sorun Giderme

### Instructions Güncellenmiyor
1. Cache'i temizleyin
2. Firebase Console'da değişikliğin kaydedildiğinden emin olun
3. İnternet bağlantınızı kontrol edin

### Hatalı JSON Çıktısı
1. Instructions'ta JSON formatının doğru tanımlandığından emin olun
2. Örnek JSON'un geçerli olduğunu kontrol edin
3. Gramer kurallarının net olduğundan emin olun

## 🔐 Güvenlik

- Instructions'lar herkese açık okunabilir
- Sadece yetkili kullanıcılar düzenleyebilir
- API anahtarları veya gizli bilgiler eklemeyin

## 📊 İzleme

Firebase Console üzerinden:
- Instructions'ın ne zaman güncellendiğini görebilirsiniz
- Kaç kez okunduğunu takip edebilirsiniz
- Bandwidth kullanımını izleyebilirsiniz

## 💡 Öneriler

1. **Test Edin**: Değişikliklerden sonra birkaç kelime ile test edin
2. **Yedek Alın**: Önemli değişikliklerden önce mevcut instructions'ı kopyalayın
3. **Kademeli Değişiklik**: Büyük değişiklikleri kademeli olarak yapın
4. **Dökümantasyon**: Yaptığınız değişiklikleri not edin

## 🚨 Dikkat Edilmesi Gerekenler

- Instructions değişikliği tüm kullanıcıları etkiler
- Hatalı instructions uygulamanın çalışmasını bozabilir
- Cache nedeniyle değişiklikler 30 dakika içinde yansır
- Acil durumlarda kullanıcılara cache temizlemelerini bildirin 