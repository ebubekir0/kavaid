@echo off
chcp 65001 >nul
title Gemini Kelime Zenginleştirici

echo ============================================
echo    Gemini API Kelime Zenginleştirici
echo ============================================
echo.

REM API anahtarını buraya yazabilirsiniz
REM veya ortam değişkeni olarak ayarlayabilirsiniz
REM set GEMINI_API_KEY=your_api_key_here

cd /d "%~dp0"

if "%1"=="resume" (
    echo Kaldığı yerden devam ediliyor...
    python gemini_enricher.py --resume
) else if "%1"=="" (
    echo Varsayılan: 100 kelime işlenecek
    python gemini_enricher.py --start 0 --count 100
) else (
    echo Özel parametrelerle çalıştırılıyor...
    python gemini_enricher.py %*
)

echo.
echo İşlem tamamlandı!
pause
