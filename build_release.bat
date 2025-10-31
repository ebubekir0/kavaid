@echo off
echo ========================================
echo Kavaid - Play Console Release Build
echo ========================================
echo.

REM Renkleri ayarla
color 0A

REM Flutter clean
echo [1/5] Temizlik yapiliyor...
call flutter clean
if %errorlevel% neq 0 (
    color 0C
    echo HATA: Flutter clean basarisiz!
    pause
    exit /b 1
)

REM Pub get
echo.
echo [2/5] Bagimliliklar yukleniyor...
call flutter pub get
if %errorlevel% neq 0 (
    color 0C
    echo HATA: Flutter pub get basarisiz!
    pause
    exit /b 1
)

REM Build appbundle
echo.
echo [3/5] App Bundle (AAB) olusturuluyor...
call flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
if %errorlevel% neq 0 (
    color 0C
    echo HATA: App Bundle olusturulamadi!
    pause
    exit /b 1
)

REM APK oluştur (test için)
echo.
echo [4/5] Test APK'lari olusturuluyor...
call flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
if %errorlevel% neq 0 (
    color 0C
    echo HATA: APK olusturulamadi!
    pause
    exit /b 1
)

REM Çıktı klasörü oluştur
echo.
echo [5/5] Dosyalar kopyalaniyor...
if not exist "release_output" mkdir release_output

REM Dosyaları kopyala
copy build\app\outputs\bundle\release\app-release.aab release_output\kavaid-release.aab
copy build\app\outputs\flutter-apk\app-arm64-v8a-release.apk release_output\kavaid-arm64-v8a.apk
copy build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk release_output\kavaid-armeabi-v7a.apk
copy build\app\outputs\flutter-apk\app-x86_64-release.apk release_output\kavaid-x86_64.apk

REM Başarı mesajı
echo.
echo ========================================
echo BASARILI! Release dosyalari hazir:
echo ========================================
echo.
echo Play Console icin:
echo   - release_output\kavaid-release.aab
echo.
echo Test icin APK'lar:
echo   - release_output\kavaid-arm64-v8a.apk (64-bit)
echo   - release_output\kavaid-armeabi-v7a.apk (32-bit)
echo   - release_output\kavaid-x86_64.apk (Emulator)
echo.
echo Debug sembolleri:
echo   - build\debug-info\
echo.
echo ========================================
echo Not: Play Console'a yuklemeden once
echo key.properties dosyasini olusturmayi
echo unutmayin!
echo ========================================
echo.
pause 