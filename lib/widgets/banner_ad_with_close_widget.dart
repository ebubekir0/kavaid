import 'package:flutter/material.dart';
import 'banner_ad_widget.dart';
import '../screens/subscription_screen.dart';

class BannerAdWithCloseWidget extends StatefulWidget {
  final Function(double) onAdHeightChanged;
  final String? stableKey;

  const BannerAdWithCloseWidget({
    Key? key,
    required this.onAdHeightChanged,
    this.stableKey,
  }) : super(key: key);

  @override
  State<BannerAdWithCloseWidget> createState() => _BannerAdWithCloseWidgetState();
}

class _BannerAdWithCloseWidgetState extends State<BannerAdWithCloseWidget> {
  final GlobalKey<BannerAdWidgetState> _bannerKey = GlobalKey<BannerAdWidgetState>();
  double _bannerHeight = 0.0;

  void _onBannerHeightChanged(double height) {
    setState(() {
      _bannerHeight = height;
    });
    widget.onAdHeightChanged(height);
  }

  @override
  Widget build(BuildContext context) {
    // Klavye yüksekliğini al - Stack içinde relative pozisyonlama için
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      // Çarpı ikonu için üst ve sağ tarafta extra alan bırak
      margin: const EdgeInsets.only(top: 30, right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner reklam
          BannerAdWidget(
            key: _bannerKey,
            onAdHeightChanged: _onBannerHeightChanged,
            stableKey: widget.stableKey,
          ),
          // Çarpı ikonu - banner dışında bağımsız
          if (_bannerHeight > 0) // Sadece banner yüklendiyse göster
            Positioned(
              // Klavye açıldığında bile banner'a göre sabit konumda kal
              top: -28,
              right: -8,
              child: Container(
                // Tıklanabilir alanı genişlet
                width: 40,
                height: 40,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      debugPrint('🖱️ [BannerAdWithClose] Close icon tapped -> Navigating to SubscriptionScreen');
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
