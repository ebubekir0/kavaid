@echo off
echo ===================================
echo     KAVAID DEĞERLENDIRME SISTEMI TEST
echo ===================================
echo.

echo 🧪 Değerlendirme sistemi test ediliyor...
echo 📊 Kullanım süresi takibi: AKTIF
echo ⭐ Uygulama içi değerlendirme: AKTIF
echo.

echo 🔨 Debug APK oluşturuluyor...
flutter build apk --debug

echo.
echo 📱 Uygulamayı cihaza yüklüyor...
flutter install --debug

echo.
echo 🚀 Uygulama başlatılıyor...
adb shell am start -n com.onbir.kavaid/.MainActivity

echo.
echo ===================================
echo TEST ADIMLARI:
echo ===================================
echo.
echo 1. PROFIL SEKMESINE GİDİN
echo    - Geliştirici Araçları bölümü görünmeli
echo    - Kullanım Süresi Testleri görünmeli
echo.
echo 2. KULLANIM SÜRESİ TESTİ:
echo    - "0 dk" butonuna basın (sıfırlama)
echo    - "30 dk" butonuna basın
echo    - Değerlendirme butonu görünmeli!
echo.
echo 3. DEĞERLENDİRME TESTİ:
echo    - "Uygulamayı Değerlendir" butonuna tıklayın
echo    - Yıldızlı değerlendirme formu açılmalı
echo    - 5 yıldız verin ve yorum yazın
echo    - "Değerlendirmeyi Gönder" butonuna basın
echo.
echo 4. SONUÇ KONTROLÜ:
echo    - Değerlendirme formu kapanmalı
echo    - Değerlendirme butonu artık görünmemeli
echo    - "✅ Değerlendirme yapıldı" yazısı görünmeli
echo.
echo 5. SIFIRLAMA TESTİ:
echo    - "Değerlendirmeyi Sıfırla" butonuna basın
echo    - Tekrar "30 dk" butonuna basın
echo    - Değerlendirme butonu tekrar görünmeli
echo.

echo.
echo 📊 Debug loglarını takip etmek için:
adb logcat | findstr "UsageTracking\|Review\|Analytics"

echo.
echo ✅ Test hazır!
pause 