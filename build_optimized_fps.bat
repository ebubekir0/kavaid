@echo off
echo ========================================
echo KAVAID FPS OPTIMIZED BUILD - v2025
echo ========================================
echo.

REM Clean previous builds
echo [1/5] Temizlik yapiliyor...
call flutter clean
if %errorlevel% neq 0 (
    echo HATA: Flutter clean basarisiz!
    pause
    exit /b 1
)

REM Get dependencies
echo.
echo [2/5] Bagimliliklar yukleniyor...
call flutter pub get
if %errorlevel% neq 0 (
    echo HATA: Flutter pub get basarisiz!
    pause
    exit /b 1
)

REM Build optimized APK with split APKs
echo.
echo [3/5] Optimize edilmis APK olusturuluyor...
call flutter build apk --release --split-per-abi --target-platform android-arm64 --obfuscate --split-debug-info=debug-info
if %errorlevel% neq 0 (
    echo HATA: APK build basarisiz!
    pause
    exit /b 1
)

REM Rename the APK with version and date
echo.
echo [4/5] APK yeniden adlandiriliyor...
set TODAY=%date:~-4%-%date:~3,2%-%date:~0,2%
set OUTPUT_NAME=kavaid-v2.1.0-build2025-fps-optimized-%TODAY%.apk
copy "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "%OUTPUT_NAME%"

echo.
echo [5/5] BUILD TAMAMLANDI!
echo ========================================
echo Dosya: %OUTPUT_NAME%
echo Boyut: 
dir /b /-c "%OUTPUT_NAME%" | findstr /r "^[0-9]"
echo.
echo OPTIMIZASYONLAR:
echo - Impeller devre disi (Xiaomi/Redmi uyumlulugu)
echo - Adaptif performans sistemi aktif
echo - Yuksek refresh rate destegi (120Hz)
echo - Split APK (sadece ARM64)
echo - Obfuscation aktif
echo ========================================
echo.
pause 