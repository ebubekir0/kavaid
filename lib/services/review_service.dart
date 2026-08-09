import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admob_service.dart';
import 'turkce_analytics_service.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;
  static const String _hasRatedAppKey = 'has_rated_app_v2';

  bool _hasRated = false;
  bool get hasRated => _hasRated;

  // Servis başlangıcında durumu yükle
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _hasRated = prefs.getBool(_hasRatedAppKey) ?? false;
    debugPrint('✅ [ReviewService] Değerlendirme durumu yüklendi: $_hasRated');
  }

  // Değerlendirme ekranını açmayı talep et
  Future<void> requestReview() async {
    // Reklamların araya girmesini önle
    AdMobService().setInAppActionFlag('in_app_review');
    // Analytics
    await TurkceAnalyticsService.uygulamaDegerlendirmeAcildi();

    try {
      final isAvailable = await _inAppReview.isAvailable();
      debugPrint('ℹ️ [ReviewService] In-app review kullanılabilir mi?: $isAvailable');

      if (isAvailable) {
        debugPrint('✅ [ReviewService] Sistem değerlendirme penceresi isteniyor...');
        await _inAppReview.requestReview();
        debugPrint('✅ [ReviewService] `requestReview` çağrısı tamamlandı.');
      } else {
        debugPrint('⚠️ [ReviewService] In-app review kullanılamıyor. Mağaza sayfasına yönlendiriliyor...');
        await _openStoreListing();
      }
    } catch (e) {
      debugPrint('❌ [ReviewService] Değerlendirme hatası, mağaza sayfasına yönlendiriliyor: $e');
      await _openStoreListing();
    } finally {
      // Değerlendirme yapılmış olsun veya olmasın, butonu tekrar gösterme.
      await _setRated();
      // Reklam engelini 1 dakika sonra kaldır.
      Future.delayed(const Duration(minutes: 1), () {
        AdMobService().clearInAppActionFlag();
      });
    }
  }

  // Yedek plan: Uygulamanın mağaza sayfasını aç
  Future<void> _openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: '6503463570', // iOS App Store ID'niz
      );
    } catch (e) {
      debugPrint('❌ [ReviewService] Mağaza sayfası açılamadı: $e');
      // En son çare olarak URL ile dene
      final Uri fallbackUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.onbir.kavaid');
       if (await canLaunchUrl(fallbackUrl)) {
         await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
       }
    }
  }

  // Kullanıcının değerlendirme yaptığını kaydet
  Future<void> _setRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedAppKey, true);
    _hasRated = true;
    debugPrint('✅ [ReviewService] Kullanıcı değerlendirme yaptı olarak işaretlendi.');
  }

  // Test için değerlendirme durumunu sıfırla
  Future<void> resetRatingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasRatedAppKey);
    _hasRated = false;
    debugPrint('🔄 [ReviewService] Değerlendirme durumu test için sıfırlandı.');
  }
}
