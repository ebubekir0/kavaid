@echo off
echo ===================================================
echo Kavaid Optimize Edilmis APK Build Script
echo ===================================================
echo.

echo [1/5] Proje temizleniyor...
flutter clean

echo.
echo [2/5] Bagimliliklar guncelleniyor...
flutter pub get

echo.
echo [3/5] Kod analizi yapiliyor...
flutter analyze --no-fatal-infos --no-fatal-warnings

echo.
echo [4/5] Release APK olusturuluyor (Optimize edilmis)...
flutter build apk --release --tree-shake-icons --split-per-abi --obfuscate --split-debug-info=build/debug-info

echo.
echo [5/5] APK'lar kopyalaniyor...
copy build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk kavaid-arm-optimized.apk
copy build\app\outputs\flutter-apk\app-arm64-v8a-release.apk kavaid-arm64-optimized.apk
copy build\app\outputs\flutter-apk\app-x86_64-release.apk kavaid-x86-optimized.apk

echo.
echo ===================================================
echo Build tamamlandi! Optimize edilmis APK'lar:
echo - kavaid-arm-optimized.apk (32-bit cihazlar)
echo - kavaid-arm64-optimized.apk (64-bit cihazlar)
echo - kavaid-x86-optimized.apk (Emulator)
echo ===================================================
echo.
echo APK boyutlari:
dir *.apk | findstr optimized

pause 