import 'package:flutter/material.dart';

/// BannerAdWidget - Devre dışı bırakılmış stub.
/// AdMob kaldırıldığı için bu widget hiçbir şey göstermez.
class BannerAdWidget extends StatelessWidget {
  final Function(double) onAdHeightChanged;
  final String? stableKey;

  const BannerAdWidget({
    super.key,
    required this.onAdHeightChanged,
    this.stableKey,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}