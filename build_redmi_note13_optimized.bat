@echo off
echo 🚀 KAVAID REDMI NOTE 13 OPTIMIZE BUILD SCRIPT
echo ===============================================

:: Timestamp oluştur
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%-%MM%-%DD%"

echo 📅 Build Tarihi: %timestamp%
echo 🎯 Hedef Cihaz: Redmi Note 13
echo ⚡ Optimizasyon: MIUI + Yüksek FPS

:: Flutter clean
echo.
echo 🧹 Cache temizleniyor...
call flutter clean
if %errorlevel% neq 0 (
    echo ❌ Flutter clean başarısız!
    pause
    exit /b 1
)

:: Pub get
echo.
echo 📦 Dependencies yükleniyor...
call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Pub get başarısız!
    pause
    exit /b 1
)

:: Gradle clean
echo.
echo 🧹 Android build cache temizleniyor...
cd android
call gradlew clean
cd ..

:: Build optimized APK
echo.
echo 🔨 Redmi Note 13 optimize APK build ediliyor...
call flutter build apk ^
    --release ^
    --target-platform android-arm64 ^
    --obfuscate ^
    --split-debug-info=./debug-info ^
    --dart-define=HIGH_PERFORMANCE=true ^
    --dart-define=MIUI_OPTIMIZATION=true ^
    --dart-define=REDMI_NOTE_13=true ^
    --dart-define=TARGET_FPS=90 ^
    --no-tree-shake-icons ^
    --build-name=2.1.0 ^
    --build-number=2041

if %errorlevel% neq 0 (
    echo ❌ APK build başarısız!
    pause
    exit /b 1
)

:: APK'yı yeniden adlandır
echo.
echo 📱 APK yeniden adlandırılıyor...
set "output_name=kavaid-redmi-note-13-optimized-%timestamp%.apk"
copy "build\app\outputs\flutter-apk\app-release.apk" "%output_name%"

echo.
echo ✅ BUILD TAMAMLANDI!
echo 📱 Çıktı: %output_name%
echo 🎯 Redmi Note 13 için özel optimize edildi
echo ⚡ MIUI optimizasyonları aktif
echo 🚀 Yüksek FPS desteği aktif
echo.
echo 📊 APK Bilgileri:
dir "%output_name%" | findstr "kavaid-redmi"
echo.
echo 🔧 Test önerileri:
echo - Geliştirici seçeneklerini aktif edin
echo - Force GPU rendering açın
echo - Ekran yenileme hızını maksimuma alın
echo - Performans modunu aktif edin
echo.
pause 