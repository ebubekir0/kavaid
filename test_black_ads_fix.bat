@echo off
echo ================================================
echo SİYAH REKLAM SORUNU DÜZELTMESİ TEST
echo ================================================
echo.

echo [1/2] Debug APK olusturuluyor...
call flutter build apk --debug
if %errorlevel% neq 0 (
    echo HATA: Debug APK olusturulamadi!
    pause
    exit /b 1
)

echo [2/2] APK yukleniyor ve baslatiliyor...
call adb install -r build\app\outputs\flutter-apk\app-debug.apk
call adb shell am start -n com.onbir.kavaid/.MainActivity

echo.
echo ================================================
echo SİYAH REKLAM TEST SENARYOLARI
echo ================================================
echo.
echo Bu test ile şunları kontrol edeceksiniz:
echo.
echo 1. ❌ ESKİ PROBLEM: Uygulamadan birkaç kez çık-gir sonrası siyah reklamlar
echo 2. ✅ YENİ ÇÖZÜM: Reklamlar her zaman düzgün gösterilmeli
echo.
echo ADIM ADIM TEST:
echo.
echo 1. Ana sayfa açılsın, native reklamları gösterilsin
echo 2. HOME tuşuna basıp uygulamadan çıkın (3 saniye bekleyin)
echo 3. Task manager'dan uygulamayı tekrar açın
echo 4. Reklamlar normal görünmeli (siyah OLMAMALI)
echo.
echo 5. Bu işlemi 3-4 kez tekrarlayın:
echo    - Çık (HOME tuşu)
echo    - 3-5 saniye bekle
echo    - Geri dön (task manager)
echo    - Reklamları kontrol et
echo.
echo 6. Kelime arayın, native reklamlar gösterilsin
echo 7. Tekrar çık-gir yapın
echo 8. Arama sayfasında reklamlar hala düzgün olmalı
echo.
echo KONSOL LOGLARINI TAKİP EDİN:
echo - ✅ [BannerAd] Reklam başarıyla yüklendi
echo - 💾 Native reklam cache'e eklendi
echo - 🗑️ [BannerAd] Widget dispose ediliyor
echo - 🧹 Arka planda native ad cache temizlendi
echo.
echo ⚠️ EĞER REKLAM SİYAH ÇIKARSA:
echo - Konsolda "dispose" ve "cache" loglarını kontrol edin
echo - Memory leak var demektir
echo.
echo ✅ EĞER REKLAMLAR NORMAL ÇIKARSA:
echo - Sorun çözülmüştür!
echo - Performans iyileştirmeleri çalışıyor
echo.
pause 