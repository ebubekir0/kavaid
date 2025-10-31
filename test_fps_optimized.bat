@echo off
echo ======================================
echo KAVAID FPS PERFORMANCE TEST
echo ======================================
echo.

echo This script will run the app with FPS counter enabled.
echo Make sure your device is connected via USB.
echo.

REM Check if device is connected
echo [1/3] Checking connected devices...
adb devices
echo.

REM Ask user to continue
set /p CONTINUE="Is your device listed above? (Y/N): "
if /i "%CONTINUE%" neq "Y" goto end

REM Clean and get dependencies
echo.
echo [2/3] Preparing the app...
call flutter clean
call flutter pub get

REM Run in profile mode with FPS counter
echo.
echo [3/3] Running app in PROFILE mode with FPS counter...
echo.
echo ======================================
echo PERFORMANCE MONITORING ACTIVE
echo ======================================
echo.
echo Look for these in the console:
echo - Device detection info
echo - Performance category
echo - FPS reports every 60 frames
echo - Optimization suggestions
echo.
echo FPS Counter will be shown in top-left corner.
echo Colors indicate performance:
echo - GREEN: 55+ FPS (Good)
echo - ORANGE: 30-55 FPS (Medium)
echo - RED: Below 30 FPS (Poor)
echo.

call flutter run --profile --dart-define=SHOW_PERFORMANCE=true

:end
echo.
echo Test completed.
pause 