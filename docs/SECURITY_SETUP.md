# 🔒 GÜVENLİK KURULUM TALİMATLARI

## 🚨 ACİL DURUM: API Anahtarı Sızdırıldı!

Eski API anahtarınız (`AIzaSyCbAR_1yQ2QVKbpyWRFj0VpOxAQZ2JBfas`) public kodda görünüyordu ve kötüye kullanıldı.

## ✅ Yapılması Gerekenler:

### 1. Eski API Anahtarını Devre Dışı Bırakın
1. [Google Cloud Console](https://console.cloud.google.com/apis/credentials) açın
2. `AIzaSyCbAR_1yQ2QVKbpyWRFj0VpOxAQZ2JBfas` anahtarını bulun
3. **Delete** veya **Disable** butonuna tıklayın

### 2. Yeni API Anahtarı Oluşturun
1. Google Cloud Console'da **Create Credentials** → **API Key** tıklayın
2. Yeni anahtarı kopyalayın
3. **Application restrictions** ekleyin:
   - Android apps: `com.onbir.kavaid` package name ekleyin
   - iOS apps: Bundle ID ekleyin
4. **API restrictions** ekleyin:
   - Sadece **Generative Language API** seçin

### 3. Firebase'e Yeni Anahtarı Ekleyin
1. [Firebase Console](https://console.firebase.google.com) açın
2. Projenizi seçin
3. **Realtime Database** → **Data** sekmesine gidin
4. `config` → `gemini_api` alanını bulun
5. Yeni API anahtarınızı buraya yapıştırın

### 4. Maliyetleri Kontrol Edin
1. Google Cloud Console'da **Billing** → **Budget & alerts** gidin
2. Günlük/aylık bütçe limiti belirleyin (örn: $10/gün)
3. Limit aşıldığında e-posta uyarısı alın

### 5. Git Geçmişini Temizleyin (Opsiyonel)
```bash
# DİKKAT: Bu komut tüm git geçmişini siler!
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch lib/services/gemini_service.dart" \
  --prune-empty --tag-name-filter cat -- --all

# Veya BFG Repo-Cleaner kullanın (daha kolay)
bfg --delete-files gemini_service.dart
git push --force
```

## 🛡️ Gelecekte Dikkat Edilecekler:

1. **ASLA** API anahtarlarını kodda saklamayın
2. **HER ZAMAN** Firebase Remote Config veya Environment Variables kullanın
3. **API anahtarlarına** IP/uygulama kısıtlaması ekleyin
4. **Bütçe limitleri** belirleyin
5. **Düzenli olarak** API kullanımını kontrol edin

## 📊 Maliyet Kontrolü:

24 Ağustos'ta oluşan **$112.80** maliyetin detayları:
- **Gemini 2.5 Flash Native Image Generation**: Görüntü üretimi için kullanılmış
- Bu özellik uygulamanızda YOK, başkaları API anahtarınızı kullanmış

## ✉️ Destek:

Google Cloud Support'a başvurarak kötüye kullanım nedeniyle iade talep edebilirsiniz:
1. [Google Cloud Support](https://cloud.google.com/support) gidin
2. "Unauthorized API usage" konulu ticket açın
3. API anahtarının public repoda yanlışlıkla paylaşıldığını belirtin
