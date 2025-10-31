@echo off
echo.
echo =====================================
echo     KAVAID APK BUILD SCRIPT
echo =====================================
echo.

echo 🧹 Cache temizleniyor...
flutter clean
echo.

echo 🔨 Debug APK oluşturuluyor...
flutter build apk --debug
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    copy "build\app\outputs\flutter-apk\app-debug.apk" "kavaid-debug.apk" >nul
    echo ✅ kavaid-debug.apk oluşturuldu
) else (
    echo ❌ Debug APK oluşturulamadı
)
echo.

echo 🔨 Release APK oluşturuluyor...
flutter build apk --release
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy "build\app\outputs\flutter-apk\app-release.apk" "kavaid-release.apk" >nul
    echo ✅ kavaid-release.apk oluşturuldu
) else (
    echo ❌ Release APK oluşturulamadı
)
echo.

echo 📱 APK dosyaları:
dir kavaid-*.apk 2>nul
echo.

echo =====================================
echo     BUILD TAMAMLANDI!
echo =====================================
pause 