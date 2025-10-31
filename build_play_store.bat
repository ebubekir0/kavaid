@echo off
echo ===================================================
echo Kavaid Play Store Upload Build Script
echo ===================================================
echo.

echo [1/7] Proje temizleniyor...
flutter clean

echo.
echo [2/7] Bagimliliklar guncelleniyor...
flutter pub get

echo.
echo [3/7] Kod analizi yapiliyor...
flutter analyze --no-fatal-infos --no-fatal-warnings

echo.
echo [4/7] App ikonu guncelleniyor...
dart run flutter_launcher_icons

echo.
echo [5/7] Test yapiliyor...
flutter test

echo.
echo [6/7] Release AAB olusturuluyor (Play Store icin)...
flutter build appbundle --release ^
  --tree-shake-icons ^
  --obfuscate ^
  --split-debug-info=build/debug-info ^
  --dart-define=SHOW_PERFORMANCE=false

echo.
echo [7/7] AAB kopyalaniyor...
copy build\app\outputs\bundle\release\app-release.aab kavaid-v2.1.1-build2055-play-store.aab

echo.
echo ===================================================
echo Play Store Upload Hazir!
echo ===================================================
echo.
echo AAB dosyasi: kavaid-v2.1.1-build2055-play-store.aab
echo Surum: 2.1.1 (Build 2055)
echo.
echo Ozellikler:
echo - Uygulama acilis hizi optimizasyonu
echo - Reklamsiz kullanimda tum reklamlarin kaldirilmasi
echo - UI iyilestirmeleri ve buton stili guncellendi
echo - Firebase Analytics optimizasyonu
echo - Yuksek FPS optimizasyonu
echo.
echo Play Console'a yuklemeye hazir!

pause 