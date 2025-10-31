@echo off
echo ===================================
echo     KAVAID FPS PERFORMANCE TEST
echo     (OPTIMIZED VERSION - 2025)
echo ===================================
echo.

echo 🚀 Kelime kartlarinin FPS performansini test ediyoruz...
echo 📊 Optimizasyon durumu: AKTIF
echo 🔧 RepaintBoundary optimizasyonlari: AKTIF
echo ⚡ Font cache optimizasyonlari: AKTIF
echo 🖼️ Image cache optimizasyonlari: AKTIF
echo.

echo 📱 Cihaz bilgilerini aliniyor...
flutter devices

echo.
echo 🔄 APK building with performance optimizations...
flutter build apk --profile --dart-define=SHOW_PERFORMANCE=true --verbose

echo.
echo 🚀 Uygulamayi cihaza yukleniyor ve basliatiliyor...
flutter install --profile --verbose

echo.
echo 📊 Performance profiling baslatiliyor...
echo ⚠️  PERFORMANCE TEST NOTLARI:
echo    • Kelime kartlarini acin ve kapatin
echo    • Listede hizlica scroll yapin
echo    • FPS counter'i gozlemleyin (ust sag kose)
echo    • Frame drop'lari kontrol edin
echo    • RepaintBoundary etkilerini gozlemleyin
echo.
echo 🧪 Test Adimlari:
echo    1. Ana ekranda kelime arayın
echo    2. Kelime kartini ackın (ilk acilis hizı)
echo    3. Kartı kapatıp tekrar acın (cache etkisi)
echo    4. Liste scroll performance test
echo    5. Coklu kart acma/kapama testi
echo.

echo 🔍 Debug logs takip ediliyor...
flutter logs

echo.
echo ✅ Test tamamlandi!
echo 📈 Performance raporunu logs'tan kontrol edin
pause 