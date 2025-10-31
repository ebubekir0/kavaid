@echo off
echo ========================================
echo Kavaid - Test ve Analiz
echo ========================================
echo.

REM Renkleri ayarla
color 0B

REM Flutter Doctor
echo [1/4] Flutter durumu kontrol ediliyor...
call flutter doctor -v
echo.
echo ========================================
echo.

REM Analyze
echo [2/4] Kod analizi yapiliyor...
call flutter analyze
if %errorlevel% neq 0 (
    color 0E
    echo UYARI: Kod analizinde hatalar bulundu!
    echo.
)

REM Test
echo.
echo [3/4] Unit testler calistiriliyor...
call flutter test
if %errorlevel% neq 0 (
    color 0E
    echo UYARI: Bazi testler basarisiz!
    echo.
)

REM Build debug APK
echo.
echo [4/4] Debug APK olusturuluyor...
call flutter build apk --debug
if %errorlevel% neq 0 (
    color 0C
    echo HATA: Debug APK olusturulamadi!
    pause
    exit /b 1
)

REM Başarı mesajı
echo.
echo ========================================
echo TEST TAMAMLANDI!
echo ========================================
echo.
echo Debug APK:
echo   - build\app\outputs\flutter-apk\app-debug.apk
echo.
echo Cihazda test etmek icin:
echo   adb install build\app\outputs\flutter-apk\app-debug.apk
echo.
echo ========================================
echo.
pause 