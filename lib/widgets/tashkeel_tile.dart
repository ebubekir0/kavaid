import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/arabic_definitions.dart';

/// Profildeki hareke ayarı: Arapça–Arapça maddelerde tanım ve örnekler harekeli mi gösterilsin.
/// Yalnız Arapça anlam dili yüklüyken görünür; varsayılan kapalı (Arapça sözlüklerdeki gibi).
class TashkeelTile extends StatelessWidget {
  const TashkeelTile({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final arabic = ArabicDefinitions.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: arabic.loaded,
      builder: (context, loaded, _) {
        if (!loaded) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: arabic.showTashkeel,
          builder: (context, on, _) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => arabic.setShowTashkeel(!on),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.text_format_rounded, color: Color(0xFF007AFF), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.tashkeelToggle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.tashkeelSettingHint,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: on,
                      activeTrackColor: const Color(0xFF007AFF),
                      onChanged: arabic.setShowTashkeel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
