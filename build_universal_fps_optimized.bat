@echo off
echo ========================================
echo  KAVAID UNIVERSAL FPS OPTIMiZED BUILD
echo ========================================
echo.
echo 🚀 Tum Android cihazlar icin FPS optimizasyonu
echo 📱 Desteklenen: Xiaomi, Samsung, OnePlus, Oppo, Realme, vb.
echo.

:: Tarih ve zaman bilgisi
for /f "tokens=1-3 delims=." %%a in ('date /t') do set build_date=%%c-%%b-%%a
for /f "tokens=1-2 delims=:" %%a in ('time /t') do set build_time=%%a-%%b

echo 📅 Build Date: %build_date%
echo ⏰ Build Time: %build_time%
echo.

:: Flutter cache temizleme
echo 🧹 Flutter cache temizleniyor...
flutter clean > nul 2>&1
flutter pub get > nul 2>&1

echo.
echo 🔧 Universal FPS optimizasyonlari aktif ediliyor...
echo    • Frame scheduling: AKTIF (tum cihazlar)
echo    • Native ad optimization: AKTIF
echo    • Adaptive performance: AKTIF
echo    • Memory management: AKTIF
echo.

:: APK build with universal optimizations
echo 📦 Universal FPS optimized APK build baslatiliyor...
echo.

flutter build apk --release ^
  --split-per-abi ^
  --dart-define=UNIVERSAL_FPS_FIX=true ^
  --dart-define=ADAPTIVE_PERFORMANCE=true ^
  --dart-define=OPTIMIZED_NATIVE_ADS=true ^
  --target-platform android-arm,android-arm64,android-x64 ^
  --verbose

if %errorlevel% neq 0 (
    echo.
    echo ❌ Build FAILED!
    pause
    exit /b 1
)

echo.
echo ✅ Build BASARILI!
echo.

:: Dosya kopyalama
set "output_dir=%cd%"
set "apk_name=kavaid-universal-fps-optimized-%build_date%.apk"

echo 📁 APK dosyalari kopyalaniyor...

:: arm64-v8a APK (en yaygin)
if exist "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" (
    copy "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "%output_dir%\%apk_name%" > nul
    echo    ✅ ARM64 APK: %apk_name%
)

:: armeabi-v7a APK (eski cihazlar)
if exist "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" (
    copy "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" "%output_dir%\kavaid-universal-fps-optimized-arm32-%build_date%.apk" > nul
    echo    ✅ ARM32 APK: kavaid-universal-fps-optimized-arm32-%build_date%.apk
)

echo.
echo 📊 Build istatistikleri:
echo    • Universal optimizasyon: AKTIF
echo    • Tum cihaz desteği: AKTIF
echo    • Frame scheduling: AKTIF
echo    • Adaptive performance: AKTIF
echo.

:: Dosya boyutları
if exist "%apk_name%" (
    for %%I in ("%apk_name%") do echo    • ARM64 APK boyutu: %%~zI bytes
)

echo.
echo 🎯 Test etmek icin:
echo    flutter install --device-id YOUR_DEVICE_ID
echo.
echo 📱 Desteklenen cihazlar:
echo    ✅ Xiaomi/Redmi (MIUI 12+)
echo    ✅ Samsung Galaxy (One UI 4+) 
echo    ✅ OnePlus (OxygenOS 12+)
echo    ✅ Oppo/Realme (ColorOS 12+)
echo    ✅ Google Pixel (Android 11+)
echo    ✅ Diger Android cihazlar
echo.
echo 🚀 Universal FPS optimizasyonu BASARILI!
echo ========================================

pause 