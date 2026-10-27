import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/dictionary_language.dart';
import '../services/language_service.dart';

/// Profildeki "Uygulama dili" satırı; dokununca dil listesi açılır.
class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final secondary = isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70);
    return GestureDetector(
      onTap: () => _showPicker(context),
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
              child: const Icon(Icons.language_rounded, color: Color(0xFF007AFF), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.appLanguage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            Text(
              LanguageService().currentLanguageName,
              style: TextStyle(fontSize: 14, color: secondary),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: secondary),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final current = LanguageService().uiLocale.languageCode;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.75),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final lang in LanguageService().availableLanguages)
                ListTile(
                  title: Text(
                    lang['name']!,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  trailing: lang['code'] == current
                      ? const Icon(Icons.check_rounded, color: Color(0xFF007AFF))
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    LanguageService().changeLanguage(lang['code']!);
                    // Sözlük dilini kullanıcı seçmediyse o da arayüz dilini izler
                    DictionaryLanguage.followUiLanguage(lang['code']!);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
