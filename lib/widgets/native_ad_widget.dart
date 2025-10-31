import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/credits_service.dart';

// MAIN: Optimized Native Ad Widget (now stateless)
class NativeAdWidget extends StatelessWidget {
  final NativeAd ad;

  const NativeAdWidget({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    // Premium kontrolü ekle
    final creditsService = CreditsService();
    if (creditsService.isPremium || creditsService.isLifetimeAdsFree) {
      return const SizedBox.shrink(); // Premium kullanıcılar için gizle
    }
    
    return Container(
      height: 100, // Reklam yüksekliğini 120'den 100 piksele küçülttük
      padding: const EdgeInsets.only(bottom: 3),
      child: AdWidget(ad: ad),
    );
  }
}
