@echo off
echo 🚀 Kavaid - Google Play Store Upload Hazırlığı
echo ================================================

echo 📋 Kontrol Listesi:
echo [✅] AAB Dosyası: kavaid-v2.1.0-build2046-yeni-icon.aab (86MB)
echo [✅] Keystore: upload-keystore.jks
echo [✅] Version: 2.1.0 (Build 2046)
echo [✅] Firebase Config: android/app/google-services.json

echo.
echo 📱 Dosya Kontrolleri:
if exist "kavaid-v2.1.0-build2046-yeni-icon.aab" (
    echo [✅] AAB dosyası bulundu
) else (
    echo [❌] AAB dosyası bulunamadı!
    echo     Önce: flutter build appbundle --release
    pause
    exit /b 1
)

if exist "upload-keystore.jks" (
    echo [✅] Keystore bulundu
) else (
    echo [❌] Keystore bulunamadı!
    pause
    exit /b 1
)

if exist "android\app\google-services.json" (
    echo [✅] Firebase config bulundu
) else (
    echo [❌] google-services.json bulunamadı!
    pause
    exit /b 1
)

echo.
echo 🎯 Sonraki Adımlar:
echo 1. https://play.google.com/console adresine gidin
echo 2. Developer hesabınızla giriş yapın ($25 fee)
echo 3. "Create App" tıklayın
echo 4. App Name: "Kavaid - Arapça Türkçe Sözlük"
echo 5. Internal Testing > Upload AAB
echo 6. Detaylı rehber: PLAY_STORE_YAYIN_REHBERİ.md

echo.
echo 📊 AAB Dosya Bilgileri:
for %%A in ("kavaid-v2.1.0-build2046-yeni-icon.aab") do (
    echo    Boyut: %%~zA bytes (~86MB)
    echo    Tarih: %%~tA
)

echo.
echo 🔗 Faydalı Linkler:
echo    - Play Console: https://play.google.com/console
echo    - Developer Docs: https://developer.android.com/distribute/console
echo    - App Bundle Guide: https://developer.android.com/guide/app-bundle

echo.
echo ⚠️  UYARI: Production'a yüklemeden önce Internal Testing yapın!
echo.
pause 