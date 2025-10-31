@echo off
echo ================================================
echo REKLAM DEBUG TEST - LOG TAKİBİ
echo ================================================
echo.

echo Debug APK olusturuluyor ve yukleniyor...
call flutter build apk --debug --dart-define=SHOW_PERFORMANCE=true
call adb install -r build\app\outputs\flutter-apk\app-debug.apk

echo.
echo Uygulama baslatiliyor...
call adb shell am start -n com.onbir.kavaid/.MainActivity

echo.
echo ================================================
echo DEBUG LOGLARINI TAKİP EDİN:
echo ================================================
echo.
echo BANNER REKLAMLARI:
echo - "🔄 [BannerAd] Credits service başlatılıyor..."
echo - "✅ [BannerAd] Credits service başlatıldı: isPremium=false"
echo - "🚀 [BannerAd] Reklam yükleme çağırılıyor..."
echo - "🔄 [BannerAd] Reklam yükleme başlatılıyor..."
echo - "✅ [BannerAd] Reklam başarıyla yüklendi: 320x50"
echo - "🎯 [BannerAd] Banner yükleme tamamlandı, UI güncellenecek"
echo.
echo NATIVE REKLAMLARI:
echo - "🔄 [NativeAd] PostFrameCallback - Premium check başlatılıyor..."
echo - "🔄 [NativeAd] Credits service başlatılıyor..."
echo - "✅ [NativeAd] Credits service başlatıldı: isPremium=false"
echo - "🚀 [NativeAd] Premium değil - Reklam yükleme başlatılıyor..."
echo - "🔄 [NativeAd] Reklam yükleme başlatılıyor..."
echo - "📦 [NativeAd] Cache'de reklam yok, yeni yüklenecek"
echo - "✅ [NativeAd] Reklam yüklendi başarıyla"
echo - "💾 [NativeAd] Reklam cache'e eklendi"
echo.
echo PROBLEM DURUMLARI:
echo - "⚠️ [BannerAd] Yükleme atlandı: disposed=true, loading=true"
echo - "👑 [BannerAd] Premium kullanıcı - Reklam yüklenmeyecek"
echo - "❌ [BannerAd] Reklam yüklenemedi: No fill"
echo - "❌ [NativeAd] Credits service hatası"
echo.
echo ==> EĞER REKLAMLAR GÖZÜKMÜYORSa:
echo 1. Premium durumu kontrol edin (isPremium=false olmalı)
echo 2. Platform kontrolü (Android/iOS olmalı)
echo 3. Ad unit ID'lerin doğru olduğunu kontrol edin
echo 4. İnternet bağlantısı olup olmadığını kontrol edin
echo.
echo Logları izleyerek sorunun nereden kaynaklandığını görebilirsiniz!
echo.
pause 