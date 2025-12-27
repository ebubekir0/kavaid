import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../services/credits_service.dart';
import '../services/subscription_service.dart';
import '../services/turkce_analytics_service.dart';
import '../services/one_time_purchase_service.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';
import 'floating_ad_close_icon.dart';
import '../screens/subscription_screen.dart'; // Yeni import

class BannerAdWidget extends StatefulWidget {
  final Function(double) onAdHeightChanged;
  final String? stableKey;

  const BannerAdWidget({
    Key? key,
    required this.onAdHeightChanged,
    this.stableKey,
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => BannerAdWidgetState();
}

class BannerAdWidgetState extends State<BannerAdWidget>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  AdSize? _adSize;
  int _retryCount = 0;
  static const int _maxRetries = 5; // Artırılmış deneme
  static const Duration _retryDelay = Duration(seconds: 5);
  final CreditsService _creditsService = CreditsService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final OneTimePurchaseService _oneTimePurchase = OneTimePurchaseService();
  bool _isVisible = true;
  final GlobalKey _bannerKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Credits service'i dinle
    _creditsService.addListener(_onCreditsChanged);
    
    // Başlangıçta yüksekliği 0 olarak bildir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onAdHeightChanged(0.0);
      }
    });
    
    // Credits service başlatıldıktan sonra reklam yükle
    _initializeAndLoadAd();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
  }

  
  Future<void> _initializeAndLoadAd() async {
    // Credits service'in başlatılmasını bekle
    await _creditsService.initialize();
    
    // Şimdi reklam yükle
    if (mounted) {
      _loadBannerAd();
    }
  }
  
  void _onCreditsChanged() {
    // Premium durumu değiştiğinde reklamı güncelle
    if ((_creditsService.isPremium || _creditsService.isLifetimeAdsFree) && _bannerAd != null) {
      // Premium/Reklamsız olduysa reklamı kaldır
      _disposeAd();
    } else if (!_creditsService.isPremium && !_creditsService.isLifetimeAdsFree && _bannerAd == null && !_isAdLoaded) {
      // Premium/Reklamsız değilse ve reklam yoksa yükle
      _loadBannerAd();
    }
  }
  
  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isAdLoaded = false;
    _adSize = null;
    widget.onAdHeightChanged(0.0);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Uygulama öne geldiğinde gerekirse reklamı yeniden yükle
      if (!_isAdLoaded && !_creditsService.isPremium && !_creditsService.isLifetimeAdsFree) {
        if (_bannerAd == null && _retryCount < _maxRetries) {
          _loadBannerAd();
        }
      }
      return;
    }

    // Arka plan durumlarında yüzey artık mevcut olmayabilir. Güvenli tarafta kalmak için
    // reklamı ve overlay'i temizliyoruz ki Android tarafında surface olmayan bağlama çizim denenmesin.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _disposeAd();
      return;
    }
  }

  @override
  void deactivate() {
    _isVisible = false;
    super.deactivate();
  }

  @override
  void activate() {
    _isVisible = true;
    if (_bannerAd == null && _retryCount < _maxRetries && !_isAdLoaded && !_creditsService.isPremium && !_creditsService.isLifetimeAdsFree) {
      _loadBannerAd();
    }
    super.activate();
  }

  Future<void> _loadBannerAd() async {
    // Premium ve reklamsız kontrolü - her zaman güncel değeri kontrol et
    if (_creditsService.isPremium || _creditsService.isLifetimeAdsFree) {
      debugPrint('👑 [BannerAd] Premium/Reklamsız kullanıcı - Reklam yüklenmeyecek');
      if (mounted) widget.onAdHeightChanged(0.0);
      return;
    }

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      if (mounted) widget.onAdHeightChanged(0.0);
      return;
    }

    await _bannerAd?.dispose();
    if (mounted) {
      setState(() {
        _bannerAd = null;
        _isAdLoaded = false;
        _adSize = null;
      });
    }

    // Ekran genişliğini al
    if (!context.mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final adaptiveSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      screenWidth.truncate(),
    );

    if (adaptiveSize == null) {
      _handleLoadError();
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId,
      size: adaptiveSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          if (!mounted) return;
          
          // Reklam yüklendikten sonra da premium/reklamsız kontrolü yap
          if (_creditsService.isPremium || _creditsService.isLifetimeAdsFree) {
            debugPrint('👑 [BannerAd] Reklam yüklendi ama kullanıcı premium/reklamsız - Reklam gösterilmeyecek');
            ad.dispose();
            return;
          }
          
          final bannerAd = ad as BannerAd;
          final platformSize = await bannerAd.getPlatformAdSize();
          if (platformSize == null) return;
          
          setState(() {
            _bannerAd = bannerAd;
            _isAdLoaded = true;
            _adSize = platformSize;
            _retryCount = 0;
          });
          // Parent'a bildirilen yükseklik: sadece reklam yüksekliği (çarpı ikonu yukarıda olduğu için)
          widget.onAdHeightChanged(platformSize.height.toDouble());
          
          // Analytics event'i gönder
          TurkceAnalyticsService.reklamGoruntulendi('banner');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner reklam yüklenemedi: ${error.message}');
          ad.dispose();
          _handleLoadError();
        },
      ),
    );

    await _bannerAd?.load();
  }

  void _handleLoadError() {
    if (mounted) {
      setState(() {
        _bannerAd = null;
        _isAdLoaded = false;
      });
      widget.onAdHeightChanged(0.0);
    }

    if (_retryCount < _maxRetries && !_creditsService.isPremium && !_creditsService.isLifetimeAdsFree) {
      _retryCount++;
      Future.delayed(_retryDelay, () {
        if (mounted && _isVisible && !_creditsService.isPremium && !_creditsService.isLifetimeAdsFree) {
          _loadBannerAd();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _creditsService.removeListener(_onCreditsChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  void showRemoveAdsDialog() {
    // Premium/Reklamsız ise diyalog göstermeyelim (bilgi ver)
    if (_creditsService.isPremium || _creditsService.isLifetimeAdsFree) {
      debugPrint('👑 [BannerAd] Kullanıcı premium/reklamsız – yönlendirme yapılmayacak');
      try {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesabınız reklamsız. Satın alma gerekli değil.'),
            duration: Duration(milliseconds: 1200),
          ),
        );
      } catch (_) {}
      return;
    }

    // Giriş kontrolü: Girişli değilse uyarı göster
    final auth = AuthService();
    if (!auth.isSignedIn) {
      // Klavye kapat
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen önce kayıt olup giriş yapın.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.fixed,
        ),
      );
      return;
    }

    // Güçlü klavye kapatma
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Doğrudan SubscriptionScreen'e yönlendir
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Build sırasında da premium/reklamsız kontrolü
    if (_creditsService.isPremium || _creditsService.isLifetimeAdsFree) {
      return const SizedBox.shrink();
    }

    if (_isAdLoaded && _bannerAd != null && _adSize != null) {
      // Sadece banner reklamı - çarpı ikonu main.dart'ta ayrı olacak
      final banner = SizedBox(
        key: _bannerKey,
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
      
      if (kDebugMode) {
        return GestureDetector(
          onLongPress: () async {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(const SnackBar(content: Text('Ad Inspector açılıyor...')));
            final err = await AdMobService.openAdInspector();
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(SnackBar(
              content: Text(err == null ? 'Ad Inspector kapandı (başarılı).' : 'Ad Inspector hata: $err'),
              duration: const Duration(seconds: 2),
            ));
          },
          child: banner,
        );
      }
      return banner;
    }

    // Reklam görünmüyorken debug modda uzun basış ile hızlı durum loglama
    if (kDebugMode) {
      return GestureDetector(
        onLongPress: () {
          AdMobService().debugAdStatus();
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('AdMob debug durumu loglandı.')),
            );
          } catch (_) {}
        },
        child: const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }
  


} 