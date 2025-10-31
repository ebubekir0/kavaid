@echo off
color 0A
echo.
echo ============================================================
echo             KELİME KARTI REKLAM DEBUG TESTİ
echo ============================================================
echo.
echo 🔍 Bu test kelime kartı açıldığında reklamların 
echo    çalışıp çalışmadığını debug eder.
echo.
echo 📋 TEST ADIMLARI:
echo    1. Uygulama açılacak
echo    2. Herhangi bir kelime kartına dokunun
echo    3. Terminal/console'da debug çıktılarını izleyin
echo.
echo 🔍 ARANACAK LOG MESAJLARI:
echo    - 🔴 [AdMobService] Constructor çağırıldı
echo    - ✅ AdMob başlatıldı
echo    - 🚀 [MAIN] interstitial reklam yükleniyor
echo    - 🔴 [WordCard] _toggleExpanded fonksiyonu çağırıldı
echo    - 🎯 [WordCard] KELİME KARTI DETAYLARI AÇILDI
echo    - 🔍 [Debug] AdMob servis durumu kontrol ediliyor
echo    - 🎬 [AdLogic] Reklam gösterilecek
echo.
echo ⚠️  NOT: Reklamların çalışması için internet bağlantısı gereklidir!
echo.
echo ============================================================
echo.

cd /d "%~dp0"

echo [DEBUG] Uygulama debug modda başlatılıyor...
echo [DEBUG] Aşağıdaki Flutter debug çıktılarını izleyin:
echo.
echo ============================================================
echo.

flutter run --debug --verbose

echo.
echo ============================================================
echo                       TEST TAMAMLANDI
echo ============================================================
pause 