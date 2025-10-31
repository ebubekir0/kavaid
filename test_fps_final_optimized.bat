@echo off
echo =============================================
echo KAVAID - Final FPS Optimized Test Build
echo =============================================
echo.

REM Move to project directory
cd /d "C:\Users\kul\Desktop\kavaid1111\kavaid"

echo [1/4] Cleaning previous builds...
call flutter clean

echo.
echo [2/4] Getting dependencies...
call flutter pub get

echo.
echo [3/4] Building optimized APK with FPS counter...
call flutter build apk --release --dart-define=SHOW_PERFORMANCE=true

echo.
echo [4/4] Installing on connected device...
call flutter install --release

echo.
echo =============================================
echo Build completed successfully!
echo.
echo Test the following features:
echo - Open word cards and scroll (check FPS)
echo - Save/unsave words rapidly
echo - Native ads should appear AFTER loading
echo - Try the in-app review from Profile
echo =============================================
pause 