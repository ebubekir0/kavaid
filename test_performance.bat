@echo off
echo ========================================
echo Kavaid Performans Testi Baslatiliyor
echo ========================================
echo.
echo FPS gostergesi acik olarak uygulama baslatiliyor...
echo Ekranin sag ust kosesinde FPS degerlerini goreceksiniz.
echo.
echo Test icin:
echo 1. Hizli kaydirim yapin
echo 2. Kelime kartlarini acip kapatin
echo 3. Arama yapin ve sonuclari kaydririn
echo.
echo Cikmak icin Ctrl+C basin
echo.
flutter run --dart-define=SHOW_PERFORMANCE=true
pause 