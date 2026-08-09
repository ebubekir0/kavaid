import 'package:flutter/material.dart';

import '../services/credits_service.dart';

class NativeAdWidget extends StatelessWidget {
  final Object? ad;

  const NativeAdWidget({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final creditsService = CreditsService();
    if (creditsService.isEntitlementPending ||
        creditsService.isPremium ||
        creditsService.isLifetimeAdsFree) {
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }
}
