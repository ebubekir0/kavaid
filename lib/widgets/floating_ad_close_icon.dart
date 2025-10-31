import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admob_service.dart';
import '../services/credits_service.dart';
import '../services/one_time_purchase_service.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';

class FloatingAdCloseIcon extends StatefulWidget {
  final GlobalKey bannerKey;
  final bool isAdVisible;

  const FloatingAdCloseIcon({
    Key? key,
    required this.bannerKey,
    required this.isAdVisible,
  }) : super(key: key);

  @override
  State<FloatingAdCloseIcon> createState() => _FloatingAdCloseIconState();
}

class _FloatingAdCloseIconState extends State<FloatingAdCloseIcon> {
  final CreditsService _creditsService = CreditsService();
  final OneTimePurchaseService _oneTimePurchase = OneTimePurchaseService();
  Offset? _bannerPosition;
  Size? _bannerSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBannerPosition();
    });
  }

  @override
  void didUpdateWidget(FloatingAdCloseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAdVisible != oldWidget.isAdVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateBannerPosition();
      });
    }
  }

  void _updateBannerPosition() {
    if (!widget.isAdVisible || !mounted) return;
    
    final RenderBox? renderBox = widget.bannerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      
      if (mounted) {
        setState(() {
          _bannerPosition = position;
          _bannerSize = size;
        });
      }
    }
  }

  void _showRemoveAdsDialog() async {
    // Premium/Reklamsız ise diyalog göstermeyelim
    if (_creditsService.isPremium || _creditsService.isLifetimeAdsFree) {
      debugPrint('👑 [FloatingIcon] Kullanıcı premium/reklamsız – diyalog açılmayacak');
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

    // Giriş kontrolü
    final auth = AuthService();
    if (!auth.isSignedIn) {
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      try {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ProfileScreen(
              bottomPadding: MediaQuery.of(context).padding.bottom,
              isDarkMode: isDark,
              onThemeToggle: () {},
              autoOpenLoginSheet: true,
            ),
          ),
        );
      } catch (e) {
        debugPrint('❌ [FloatingIcon] ProfileScreen açılamadı: $e');
      }
      
      if (!auth.isSignedIn) {
        debugPrint('❌ [FloatingIcon] Giriş yapılmadı – diyalog açılmayacak');
        return;
      }
    }

    // Ürün fiyatını yükle
    try {
      if (_oneTimePurchase.products.isEmpty) {
        await _oneTimePurchase.initialize();
      }
    } catch (_) {}

    // Klavye kapat
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            return true;
          },
          child: AlertDialog(
            title: const Text('Reklamları Kaldır'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bu hesap için ömür boyu tüm reklamları kaldır'),
                SizedBox(height: 16),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                  });
                },
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  AdMobService().setInAppActionFlag('satın_alma');
                  try {
                    FocusManager.instance.primaryFocus?.unfocus();
                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                    Navigator.of(context).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                    });
                    await _oneTimePurchase.buyRemoveAds();
                    Future.delayed(const Duration(minutes: 1), () {
                      AdMobService().clearInAppActionFlag();
                      debugPrint('🔓 Satın alma işlemi sonrası 1 dakika flag temizlendi');
                    });
                  } catch (e) {
                    AdMobService().clearInAppActionFlag();
                    rethrow;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                ),
                child: Text(_oneTimePurchase.removeAdsPrice),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Premium/reklamsız ise icon gösterme
    if (_creditsService.isPremium || _creditsService.isLifetimeAdsFree) {
      return const SizedBox.shrink();
    }

    // Banner görünür değilse icon gösterme
    if (!widget.isAdVisible) {
      return const SizedBox.shrink();
    }

    // Banner pozisyonunu güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBannerPosition();
    });

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          debugPrint('🖱️ [FloatingIcon] Close icon tapped');
          _showRemoveAdsDialog();
        },
        child: const Padding(
          padding: EdgeInsets.only(top: 5.0, left: 8.0, right: 8.0, bottom: 3.0),
          child: Icon(Icons.close, size: 24, color: Colors.black),
        ),
      ),
    );
  }
}
