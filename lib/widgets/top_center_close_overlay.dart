import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/credits_service.dart';
import '../services/one_time_purchase_service.dart';
import '../services/auth_service.dart';
import '../services/admob_service.dart';
import '../screens/profile_screen.dart';

/// Uygulamanın her ekranında üst-ortada konumlanan bağımsız kapatma (X) ikonu.
/// Premium/reklamsız hesaplarda görünmez. Tıklanınca reklam kaldırma akışını açar.
class TopCenterCloseOverlay extends StatefulWidget {
  const TopCenterCloseOverlay({Key? key}) : super(key: key);

  @override
  State<TopCenterCloseOverlay> createState() => _TopCenterCloseOverlayState();
}

class _TopCenterCloseOverlayState extends State<TopCenterCloseOverlay> {
  final CreditsService _creditsService = CreditsService();
  final OneTimePurchaseService _oneTimePurchase = OneTimePurchaseService();

  Future<void> _showRemoveAdsFlow() async {
    // Premium/Reklamsız ise diyalog göstermeyelim
    if (_creditsService.isPremium || _creditsService.isLifetimeAdsFree) {
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
        debugPrint('❌ [TopCenterCloseOverlay] ProfileScreen açılamadı: $e');
      }
      if (!auth.isSignedIn) {
        debugPrint('❌ [TopCenterCloseOverlay] Giriş yapılmadı – diyalog açılmayacak');
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
    // Premium/reklamsız ise hiç göstermeyelim
    if (_creditsService.isPremium || _creditsService.isLifetimeAdsFree) {
      return const SizedBox.shrink();
    }

    // Üst-orta konum: SafeArea ile çentik/padding dikkate alınır
    return IgnorePointer(
      ignoring: false,
      child: Align(
        alignment: const Alignment(0, -0.98), // üst-orta
        child: SafeArea(
          bottom: false,
          child: Material(
            color: Colors.transparent,
            child: InkWell
              (
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                debugPrint('🖱️ [TopCenterCloseOverlay] Close icon tapped');
                _showRemoveAdsFlow();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.close,
                  size: 22,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
