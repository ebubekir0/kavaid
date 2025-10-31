@echo off
echo 🎨 KAVAID APP ICON GÜNCELLEME SCRIPT
echo =====================================
echo.
echo 📋 Bu script uygulama ikonunu günceller:
echo    1. assets/images/app_icon.png dosyasını yeni icon ile değiştirin
echo    2. Bu script'i çalıştırın
echo    3. Icon'lar otomatik olarak oluşturulur
echo.

REM 1. Yeni icon'u kontrol et
if not exist "assets\images\app_icon.png" (
    echo ❌ HATA: assets\images\app_icon.png dosyası bulunamadı!
    echo    Lütfen yeni icon'unuzu bu dosya adıyla kaydedin.
    pause
    exit /b 1
)

echo ✅ Icon dosyası bulundu: assets\images\app_icon.png
echo.

REM 2. Flutter launcher icons generate
echo 🔄 Icon'lar oluşturuluyor...
echo.
flutter pub get
flutter pub run flutter_launcher_icons:main

if %errorlevel% equ 0 (
    echo.
    echo ✅ BAŞARILI! Uygulama icon'u güncellendi.
    echo.
    echo 📋 Sonraki adımlar:
    echo    1. flutter build apk --release
    echo    2. Yeni APK/AAB dosyasını test edin
    echo    3. Play Console'a yükleyin
    echo.
) else (
    echo.
    echo ❌ HATA! Icon oluşturma başarısız.
    echo    Lütfen konsol çıktısını kontrol edin.
    echo.
)

pause 