@echo off
echo ================================================
echo KAVAID - FPS OPTIMIZED TEST v2.0
echo ================================================
echo.

REM Renkleri ayarla
color 0A

echo [INFO] Mevcut build temizleniyor...
call flutter clean
timeout /t 2 >nul

echo.
echo [INFO] Paketler guncelleniyor...
call flutter pub get
timeout /t 2 >nul

echo.
echo [INFO] Performans optimizasyonlari ile APK olusturuluyor...
echo.
echo OPTIMIZASYONLAR:
echo - GoogleFonts preload aktif
echo - RepaintBoundary optimizasyonlari
echo - Lazy loading ve virtualization
echo - AnimatedContainer optimizasyonlari
echo - FPS counter optimizasyonlari
echo - ListView cache extent
echo - AutomaticKeepAliveClientMixin
echo.

REM Flutter build komutunu calistir
call flutter build apk --release --obfuscate --split-debug-info=debug-info

if %ERRORLEVEL% NEQ 0 (
    echo.
    color 0C
    echo [HATA] Build basarisiz!
    pause
    exit /b 1
)

echo.
echo [INFO] APK basariyla olusturuldu!
echo.

REM APK'yi kopyala
set SOURCE_APK=build\app\outputs\flutter-apk\app-release.apk
set DEST_APK=kavaid-fps-optimized-v2-%date:~-4,4%-%date:~-10,2%-%date:~-7,2%.apk

if exist "%SOURCE_APK%" (
    copy "%SOURCE_APK%" "%DEST_APK%"
    echo [INFO] APK kopyalandi: %DEST_APK%
) else (
    echo [HATA] APK bulunamadi!
    pause
    exit /b 1
)

echo.
echo ================================================
echo PERFORMANS OPTIMIZASYONLARI:
echo ================================================
echo.
echo 1. WIDGET OPTIMIZASYONLARI:
echo    - WordCard: AnimatedContainer -> Container (ilk acilista)
echo    - SearchResultCard: Lazy animation initialization
echo    - Text style cache sistemi
echo    - RepaintBoundary kullanimini genislettik
echo.
echo 2. LISTE OPTIMIZASYONLARI:
echo    - ListView.builder cache extent
echo    - addAutomaticKeepAlives: true
echo    - addRepaintBoundaries: true
echo    - Unique key'ler ile widget recycling
echo.
echo 3. FONT OPTIMIZASYONLARI:
echo    - GoogleFonts preload
echo    - Runtime fetching devre disi
echo    - Font cache sistemi
echo.
echo 4. FPS COUNTER OPTIMIZASYONLARI:
echo    - setState cagrilerini azalttik
echo    - 1000ms update interval
echo    - RepaintBoundary ile izolasyon
echo.
echo ================================================

echo.
echo [INFO] Test icin APK yukleniyor...
call adb install -r "%DEST_APK%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [BASARILI] APK yuklendi!
    echo.
    echo PERFORMANS TEST ADIMLARI:
    echo 1. Uygulamayi acin
    echo 2. Kelime arayarak sonuclari goruntulen
    echo 3. Kelime kartlarini acip kapatin
    echo 4. FPS degerlerini kontrol edin
    echo 5. Liste scroll performansini test edin
    echo.
    echo BEKLENEN IYILESTIRMELER:
    echo - Kelime kartlari daha hizli acilacak
    echo - FPS dususu azalacak (55+ FPS hedefi)
    echo - Liste scroll daha akici olacak
    echo - Ilk acilis performansi iyilesecek
    echo.
    
    REM Uygulamayi baslat
    echo [INFO] Uygulama baslatiliyor...
    call adb shell am start -n com.onbir.kavaid/.MainActivity
) else (
    echo.
    color 0C
    echo [HATA] APK yuklenemedi!
)

echo.
echo ================================================
echo Test tamamlandi!
echo ================================================
pause 