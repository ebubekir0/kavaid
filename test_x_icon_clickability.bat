@echo off
echo ================================================
echo X ICON CLICKABILITY FIX TEST
echo ================================================
echo.

echo Building debug APK with clickability fixes...
call flutter build apk --debug
call adb install -r build\app\outputs\flutter-apk\app-debug.apk

echo.
echo Starting app...
call adb shell am start -n com.onbir.kavaid/.MainActivity

echo.
echo ================================================
echo CLICKABILITY FIXES APPLIED:
echo ================================================
echo.
echo FIXED: GestureDetector instead of InkWell for better touch detection
echo FIXED: Increased clickable area to 44x44 pixels
echo FIXED: Added white background for better visibility
echo FIXED: Increased positioning margins for better touch area
echo FIXED: Added shadow for better visual feedback
echo.
echo ================================================
echo TEST CHECKLIST - CLICKABILITY:
echo ================================================
echo.
echo 1. [CRITICAL] X icon should be CLICKABLE
echo 2. [FIXED] Larger touch area (44x44 pixels)
echo 3. [FIXED] White background for better visibility
echo 4. [FIXED] Shadow for visual feedback
echo 5. [FIXED] GestureDetector for reliable touch detection
echo 6. Clicking should open "Remove Ads" dialog
echo 7. Debug message should appear in logs when clicked
echo.
echo TESTING INSTRUCTIONS:
echo ================================================
echo.
echo 1. Wait for banner ad to load
echo 2. Look for X icon in TOP-RIGHT corner (white circle with black X)
echo 3. Tap the X icon - it should be easily clickable
echo 4. "Remove Ads" dialog should open
echo 5. Check logs for: "[BannerAdWithClose] Close icon tapped"
echo.
echo If X icon is still not clickable, check:
echo - Make sure banner ad has loaded first
echo - Try tapping slightly different areas of the X icon
echo - Check if the icon is being covered by other UI elements
echo.
echo Navigate through different tabs to test on all screens!
echo.
pause