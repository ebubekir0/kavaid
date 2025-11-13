@echo off
echo ===============================================
echo   Firebase'den Embedded Words Sync Scripti
echo ===============================================
echo.
echo Firebase Realtime Database'den guncel kelime verilerini cekip
echo embedded_words_data.dart dosyasini otomatik gunceller.
echo.

cd /d "%~dp0"

echo Sync islemi baslatiliyor...
dart lib/scripts/simple_firebase_sync.dart

echo.
if %ERRORLEVEL% EQU 0 (
    echo ✅ Sync islemi basariyla tamamlandi!
    echo Embedded words data dosyasi guncellendi.
) else (
    echo ❌ Sync islemi sirasinda hata olustu!
    echo Hata kodu: %ERRORLEVEL%
)

echo.
pause
