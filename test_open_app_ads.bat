@echo off
echo ========================================
echo    KAVAID - OPEN APP REKLAM TEST
echo ========================================
echo.

echo [1] Flutter clean yapiliyor...
call flutter clean

echo.
echo [2] Pub get yapiliyor...
call flutter pub get

echo.
echo [3] Debug APK olusturuluyor (Open App reklam test)...
call flutter build apk --debug

echo.
echo [4] Test cihaza yukleniyor...
adb uninstall com.onbir.kavaid 2>nul
adb install build\app\outputs\flutter-apk\app-debug.apk

echo.
echo [5] Uygulama baslatiliyor ve log izleniyor...
adb shell am start -n com.onbir.kavaid/.MainActivity

echo.
echo ========================================
echo    OPEN APP REKLAM TEST ADIMLARI:
echo ========================================
echo.
echo 1. Uygulama ilk acildiginda REKLAM GOSTERMEMELI
echo 2. Uygulamayi arka plana al (Home tusu)
echo 3. Geri don - REKLAM GOSTERMELI
echo 4. Bildirim panelini ac ve kapat - REKLAM GOSTERMEMELI
echo 5. Premium dialog ac ve kapat - REKLAM GOSTERMEMELI
echo 6. 5 dakika bekle, arka plana al ve geri don - REKLAM GOSTERMELI
echo.
echo Loglar:
echo ========================================
adb logcat -s flutter:V | findstr /i "lifecycle reklam dialog keyboard"

pause 