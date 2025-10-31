@echo off
echo ======================================
echo KAVAID FPS OPTIMIZED APK BUILD
echo Version: 2.1.0 Build 2043
echo ======================================
echo.

REM Clean previous builds
echo [1/5] Cleaning previous builds...
call flutter clean
if errorlevel 1 goto error

REM Get dependencies
echo.
echo [2/5] Getting dependencies...
call flutter pub get
if errorlevel 1 goto error

REM Build optimized APK with split per ABI
echo.
echo [3/5] Building FPS optimized APK...
call flutter build apk --release --split-per-abi --dart-define=SHOW_PERFORMANCE=false
if errorlevel 1 goto error

REM Copy and rename APKs
echo.
echo [4/5] Organizing output files...
set OUTPUT_DIR=release_output
if not exist %OUTPUT_DIR% mkdir %OUTPUT_DIR%

REM Get current date
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YYYY=%dt:~0,4%"
set "MM=%dt:~4,2%"
set "DD=%dt:~6,2%"
set "DATE_STR=%YYYY%-%MM%-%DD%"

REM Copy APKs with meaningful names
copy "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "%OUTPUT_DIR%\kavaid-v2.1.0-build2043-fps-optimized-%DATE_STR%-arm64.apk"
copy "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" "%OUTPUT_DIR%\kavaid-v2.1.0-build2043-fps-optimized-%DATE_STR%-arm32.apk"

REM Build bundle for Play Store
echo.
echo [5/5] Building App Bundle for Play Store...
call flutter build appbundle --release
if errorlevel 1 goto error

copy "build\app\outputs\bundle\release\app-release.aab" "%OUTPUT_DIR%\kavaid-v2.1.0-build2043-fps-optimized-%DATE_STR%.aab"

echo.
echo ======================================
echo BUILD SUCCESSFUL!
echo ======================================
echo.
echo Output files:
echo - ARM64 APK: %OUTPUT_DIR%\kavaid-v2.1.0-build2043-fps-optimized-%DATE_STR%-arm64.apk
echo - ARM32 APK: %OUTPUT_DIR%\kavaid-v2.1.0-build2043-fps-optimized-%DATE_STR%-arm32.apk
echo - App Bundle: %OUTPUT_DIR%\kavaid-v2.1.0-build2043-fps-optimized-%DATE_STR%.aab
echo.
echo FPS Optimizations included:
echo - Advanced device detection
echo - Adaptive performance settings
echo - MIUI/Custom ROM optimizations
echo - RepaintBoundary optimizations
echo - Gradient removal for better performance
echo - Native performance mode
echo.
goto end

:error
echo.
echo ======================================
echo BUILD FAILED!
echo ======================================
echo Please check the error messages above.
echo.

:end
pause 