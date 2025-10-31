@echo off
echo.
echo ==========================================
echo     KAVAID - ADAPTİF PERFORMANS TESTİ
echo ==========================================
echo.

echo [1/5] Eski APK'yi kaldırıyor...
adb uninstall com.onbir.kavaid 2>nul

echo [2/5] Yeni optimizasyonlarla debug build yapılıyor...
call flutter clean
call flutter build apk --target-platform android-arm64 --debug --dart-define=SHOW_PERFORMANCE=true

if errorlevel 1 (
    echo HATA: Build başarısız!
    pause
    exit /b 1
)

echo [3/5] APK yükleniyor...
adb install build\app\outputs\flutter-apk\app-debug.apk

if errorlevel 1 (
    echo HATA: APK yüklenemedi!
    pause
    exit /b 1
)

echo [4/5] Performance monitoring başlatılıyor...
echo.
echo KONTROL LİSTESİ:
echo ✓ Adaptif performans sistemi devrede
echo ✓ Cihaz kategorisi otomatik tespit edilecek  
echo ✓ FPS sayacı ekranda görünecek
echo ✓ Düşük performanslı cihazlarda optimizasyonlar devrede
echo.

echo [5/5] Uygulamayı başlatıyor ve logları izliyor...
echo.
echo === PERFORMANS İZLEME BAŞLADI ===
echo Çıkmak için Ctrl+C basın
echo.

adb shell am start -n com.onbir.kavaid/com.onbir.kavaid.MainActivity
adb logcat | findstr "KavaidPerformance\|flutter\|FPS\|PERFORMANS" 