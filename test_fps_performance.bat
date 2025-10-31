@echo off
echo.
echo ========================================
echo    KAVAID FPS PERFORMANCE TEST
echo ========================================
echo.

echo 🚀 FPS Performans Testi Başlatılıyor...
echo.

echo 📱 Telefonu USB ile bağladığınızdan emin olun!
echo 🔧 Developer Options ve USB Debugging aktif olmalı!
echo.
pause

echo.
echo 🔍 Bağlı cihazları kontrol ediliyor...
adb devices
echo.

echo 📊 FPS izleme başlatılıyor...
echo.
echo 🎯 Uygulama şimdi FPS optimizasyonları ile başlatılacak.
echo 📝 Terminal'de FPS raporlarını görebileceksiniz:
echo    • 🚀 120Hz mod: Ultra performans
echo    • ⚡ 90Hz mod: Yüksek performans  
echo    • 📱 60Hz mod: Standart performans
echo.
echo 📊 Her 60 frame'de performans raporu gösterilecek.
echo ⚠️ Frame drop oranı %5'in üzerindeyse uyarı verilecek.
echo.

echo FPS test modu ile uygulamayı başlatıyor...
flutter run --debug --verbose

echo.
echo 🏁 Test tamamlandı!
echo 📊 Performans raporlarını terminal çıktısında gözden geçirin.
echo.
pause 