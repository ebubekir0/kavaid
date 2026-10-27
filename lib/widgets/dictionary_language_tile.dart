import 'package:flutter/material.dart';

import '../data/embedded_words.dart';
import '../l10n/l10n.dart';
import '../services/dictionary_language.dart';
import '../services/language_service.dart';

/// Profildeki "Sözlük dili" satırı: kelime anlamlarının dili. Dokununca liste açılır;
/// seçilen dille sözlük yeniden kurulur (birkaç saniye "Sözlük hazırlanıyor").
class DictionaryLanguageTile extends StatelessWidget {
  const DictionaryLanguageTile({super.key, required this.isDarkMode});

  final bool isDarkMode;

  static String _name(String code) =>
      LanguageService.languageNames[code] ?? code;

  @override
  Widget build(BuildContext context) {
    final secondary = isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70);
    return ValueListenableBuilder<String>(
      valueListenable: DictionaryLanguage.current,
      builder: (context, lang, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _showPicker(context, lang),
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
                  color: isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
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
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF007AFF), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dictionaryLanguage,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(l10n.dictionaryLanguageHint, style: TextStyle(fontSize: 13, color: secondary)),
                    ],
                  ),
                ),
                Text(_name(lang), style: TextStyle(fontSize: 14, color: secondary)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 16, color: secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, String current) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final code in EmbeddedWords.availableLangs)
              ListTile(
                title: Text(_name(code), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                subtitle: code == 'ar'
                    ? Text(l10n.arabicArabicDictionary,
                        style: TextStyle(color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70)))
                    : null,
                trailing: code == current ? const Icon(Icons.check_rounded, color: Color(0xFF007AFF)) : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (code != current) DictionaryLanguage.change(code);
                },
              ),
          ],
        ),
      ),
    );
  }
}
