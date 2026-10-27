import 'package:flutter/material.dart';
import 'package:kavaid/l10n/l10n.dart';

/// Güncelleme sonrası ilk kullanımda, kelime kartındaki ikonların en solundaki AI
/// simgesini tanıtan tek seferlik, kapatılabilir bilgi kartı.
class AiIntroBanner extends StatelessWidget {
  const AiIntroBanner({
    super.key,
    required this.isDarkMode,
    required this.onDismiss,
  });

  final bool isDarkMode;
  final VoidCallback onDismiss;

  static const _blue = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    final primary = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final secondary = isDarkMode
        ? const Color(0xFFB0B0B5)
        : const Color(0xFF6D6D70);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: isDarkMode ? 0.14 : 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _blue.withValues(alpha: isDarkMode ? 0.35 : 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 28,
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: isDarkMode ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: _blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.yeniAiAsistan,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.kelimeKartindakiIkonlarinEnSolundaki,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: _blue,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.anladim,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded, size: 18, color: secondary),
              visualDensity: VisualDensity.compact,
              tooltip: l10n.kapat,
            ),
          ],
        ),
      ),
    );
  }
}
