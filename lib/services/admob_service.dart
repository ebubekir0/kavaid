import 'package:flutter/widgets.dart';

/// AdMob servisinin devre dışı bırakılmış stub versiyonu.
/// Tüm metodlar boş/no-op olarak çalışır.
/// Uygulamayı yavaşlatmaması için google_mobile_ads paketi kaldırıldı.
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool get mounted => false;
  bool get isInterstitialAdAvailable => false;

  static String get bannerAdUnitId => '';
  static String get nativeAdUnitId => '';
  static String get interstitialAdUnitId => '';

  static Future<void> initialize() async {}

  void loadInterstitialAd() {}

  Future<void> onSearchAdRequest({required VoidCallback onAdDismissed}) async {
    onAdDismissed();
  }

  Future<void> onWordCardOpenedAdRequest() async {}

  void onAppStateChanged(AppLifecycleState state) {}

  void setInAppActionFlag(String actionType) {}

  void clearInAppActionFlag() {}

  void debugAdStatus() {}

  void forceShowInterstitialAd() {}

  void dispose() {}

  static Future<String?> openAdInspector() async => null;

  static Future<void> setTestDeviceIds(List<String> ids) async {}
}