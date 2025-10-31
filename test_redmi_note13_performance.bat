@echo off
echo 🧪 KAVAID REDMI NOTE 13 PERFORMANS TEST
echo =======================================

echo 📱 Cihaz bağlantısı kontrol ediliyor...
adb devices

echo.
echo 🔍 Cihaz bilgileri alınıyor...
adb shell getprop ro.product.brand
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release

echo.
echo 📊 Display bilgileri kontrol ediliyor...
adb shell dumpsys display | find "mRefreshRate"
adb shell dumpsys display | find "supportedModes"

echo.
echo 🎮 GPU bilgileri alınıyor...
adb shell getprop ro.hardware.vulkan
adb shell getprop debug.egl.hw

echo.
echo 🚀 Uygulamayı test modda çalıştırıyor...
echo ⚠️  Konsol çıktılarını takip edin:
echo    - "MIUI cihaz tespit edildi" mesajını arayın
echo    - "REDMI NOTE 13 tespit edildi" mesajını arayın  
echo    - FPS raporlarını izleyin
echo    - Frame drop uyarılarını kontrol edin
echo.

flutter run --debug --verbose

echo.
echo 📊 Test tamamlandı. Performans loglarını kontrol edin.
pause 