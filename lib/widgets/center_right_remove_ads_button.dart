import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/credits_service.dart';
import '../services/auth_service.dart';
import '../services/one_time_purchase_service.dart';
import '../services/admob_service.dart';
import '../screens/profile_screen.dart';

/// Ekranın orta-sağında siyah bir çarpı ikonu gösterir.
///
/// Davranış:
/// - Kullanıcı premium/reklamsız ise gösterilmez.
/// - Tıklanınca:
///   - Giriş yapılmamışsa önce giriş sayfasını (login sheet) açar
///   - Giriş yapılmışsa Reklamları Kaldır satın alma diyalogunu gösterir
class CenterRightRemoveAdsButton extends StatefulWidget {
  final EdgeInsetsGeometry padding;

  const CenterRightRemoveAdsButton({super.key, this.padding = const EdgeInsets.only(right: 8) });

  @override
  State<CenterRightRemoveAdsButton> createState() => _CenterRightRemoveAdsButtonState();
}

class _CenterRightRemoveAdsButtonState extends State<CenterRightRemoveAdsButton> {
  final CreditsService _credits = CreditsService();
  final OneTimePurchaseService _oneTime = OneTimePurchaseService();

  @override
  void initState() {
    super.initState();
    // Premium durum değişimlerini dinleyip yeniden çizelim
    _credits.addListener(_onCreditsChanged);
    // Fiyat metninin hızlı gelmesi için mümkünse başlat
    _oneTime.initialize().catchError((_) {});
  }

  @override
  void dispose() {
    _credits.removeListener(_onCreditsChanged);
    super.dispose();
  }

  void _onCreditsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleTap() async {
    // Premium/reklamsız ise bilgilendir ve çık
    if (_credits.isPremium || _credits.isLifetimeAdsFree) {
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

    final auth = AuthService();

    // Giriş değilse önce login sheet’i açan profile ekranına gidelim
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
      } catch (_) {}
      if (!auth.isSignedIn) return; // hala girişsizse dur
    }

    // Satın alma diyalogu
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
                    await _oneTime.buyRemoveAds();
                    Future.delayed(const Duration(minutes: 1), () {
                      AdMobService().clearInAppActionFlag();
                    });
                  } catch (_) {
                    AdMobService().clearInAppActionFlag();
                    rethrow;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                ),
                child: Text(_oneTime.removeAdsPrice),
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
    if (_credits.isPremium || _credits.isLifetimeAdsFree) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: widget.padding,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _handleTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.close, size: 24, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
