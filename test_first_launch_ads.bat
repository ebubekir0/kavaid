@echo off
echo ================================================
echo İLK AÇILIŞ SONRASI REKLAM TEST SCRİPTİ
echo ================================================
echo.

echo [1/2] Debug build olusturuluyor...
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
echo TEST SENARYOLARI
echo ================================================
echo.
echo SENARYO 1: İlk açılış testi
echo 1. Uygulama şimdi açıldı (ilk açılış)
echo 2. Konsolda "İlk açılış - reklam gösterilmeyecek" yazması gerekiyor
echo 3. Hiç reklam gösterilmemeli
echo.
echo SENARYO 2: İlk açılış sonrası arka plan testi  
echo 1. Ana sayfada dururken HOME tuşuna basın
echo 2. 3-5 saniye bekleyin
echo 3. Uygulamayı task manager'dan açın
echo 4. Konsolda "İlk açılış sonrası resume - REKLAM GÖSTERİLECEK!" yazması gerekiyor
echo 5. Open App reklamı gösterilmeli
echo.
echo SENARYO 3: Normal arka plan geçişi
echo 1. Tekrar HOME tuşuna basın  
echo 2. 3+ saniye bekleyin
echo 3. Geri açın
echo 4. Eğer 3 dakika geçmişse tekrar reklam gösterilmeli
echo.
echo SENARYO 4: Bildirim/çağrı simülasyonu
echo 1. Telefona çağrı geliyormuş gibi çağrı uygulamasını açın
echo 2. Hemen kavaid'e geri dönün  
echo 3. Bu da arka plan geçişi sayılır, reklam gösterilmeli (3 dk kuralı varsa)
echo.
echo KONSOL LOGLARINI TAKİP EDİN:
echo - 🚀 [LIFECYCLE] İlk açılış - reklam gösterilmeyecek
echo - 🔄 [LIFECYCLE] İlk açılış sonrası resume - REKLAM GÖSTERİLECEK!
echo - ✅ [LIFECYCLE] Arka plandan dönüş #X - REKLAM GÖSTERİLECEK!
echo.
pause 