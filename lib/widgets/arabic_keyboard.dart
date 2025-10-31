import 'package:flutter/material.dart';

class ArabicKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onClose;
  final VoidCallback? onSearch;

  const ArabicKeyboard({
    super.key,
    required this.controller,
    this.onClose,
    this.onSearch,
  });

  // Standart Arapça klavye düzeni (görüntüdeki gibi)
  static const List<List<String>> _arabicKeys = [
    // İlk sıra
    ['ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ', 'ح', 'ج'],
    // İkinci sıra  
    ['ش', 'س', 'ي', 'ب', 'ل', 'ا', 'ت', 'ن', 'م', 'ك', 'ط'],
    // Üçüncü sıra
    ['ذ', 'ء', 'و', 'ر', 'ى', 'ة', 'ي', 'ز', 'ظ', 'د'],
  ];

  // Hareke satırı - üstte ayrı
  static const List<String> _diacritics = [
    'َ', // Fetha
    'ِ', // Kesra  
    'ُ', // Damma
    'ْ', // Sukun
    'ّ', // Şedde
    'ً', // Tenvin Fetha
    'ٍ', // Tenvin Kesra
    'ٌ', // Tenvin Damma
  ];

  void _insertText(String text) {
    final currentText = controller.text;
    final selection = controller.selection;
    
    if (selection.isValid) {
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        text,
      );
      
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + text.length,
        ),
      );
    } else {
      controller.text = currentText + text;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
  }

  void _backspace() {
    final currentText = controller.text;
    final selection = controller.selection;
    
    if (selection.isValid && selection.start > 0) {
      final newText = currentText.replaceRange(
        selection.start - 1,
        selection.end,
        '',
      );
      
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start - 1,
        ),
      );
    }
  }

  void _addSpace() {
    _insertText(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: 280,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF2F2F7),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hareke satırı - en üstte ve kapatma butonu
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF007AFF).withOpacity(0.1)
                  : const Color(0xFF007AFF).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF007AFF).withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                // Harekeler
                ..._diacritics.map((diacritic) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _buildDiacriticKey(context, diacritic),
                    ),
                  );
                }).toList(),
                // Kapatma butonu
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 36,
                      width: 40,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF48484A).withOpacity(0.3)
                            : const Color(0xFF8E8E93).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.keyboard_hide_rounded,
                        size: 20,
                        color: isDarkMode
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Ana harfler
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Column(
                children: [
                  // Üç satır Arapça harf için Expanded widget'lar
                  ..._arabicKeys.map((row) {
                    return Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((letter) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: _buildKey(context, letter),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                  
                  // Son satır: Boşluk ve kontrol butonları - Expanded ile
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2, right: 2, top: 2),
                            child: _buildSpecialKey(
                              context,
                              text: 'Ara',
                              onPressed: () {
                                if (onSearch != null) onSearch!();
                              },
                              isSearch: true,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2, right: 2, top: 2),
                            child: _buildSpecialKey(
                              context,
                              text: 'Boşluk',
                              onPressed: _addSpace,
                              isSpace: true,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2, right: 2, top: 2),
                            child: _buildSpecialKey(
                              context,
                              icon: Icons.backspace_outlined,
                              onPressed: _backspace,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKey(BuildContext context, String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _insertText(text),
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFF007AFF).withOpacity(0.3),
        highlightColor: const Color(0xFF007AFF).withOpacity(0.1),
        child: Ink(
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF2C2C2E)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF48484A).withOpacity(0.3)
                  : const Color(0xFFE5E5EA).withOpacity(0.5),
              width: 0.5,
            ),
          ),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? Colors.white
                    : const Color(0xFF1C1C1E),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiacriticKey(BuildContext context, String diacritic) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _insertText(diacritic),
        borderRadius: BorderRadius.circular(6),
        splashColor: const Color(0xFF007AFF).withOpacity(0.4),
        highlightColor: const Color(0xFF007AFF).withOpacity(0.2),
        child: Ink(
          height: 36,
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF007AFF).withOpacity(0.2)
                : const Color(0xFF007AFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              diacritic,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF007AFF),
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(
    BuildContext context, {
    String? text,
    IconData? icon,
    required VoidCallback onPressed,
    bool isSearch = false,
    bool isSpace = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: isSearch 
                ? const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                  )
                : null,
            color: isSearch 
                ? null
                : (isSpace
                    ? (isDarkMode
                        ? const Color(0xFF3C3C3E)
                        : const Color(0xFFE5E5EA))
                    : (isDarkMode
                        ? const Color(0xFF2C2C2E)
                        : Colors.white)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isSearch
                    ? const Color(0xFF007AFF).withOpacity(0.3)
                    : (isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08)),
                blurRadius: isSearch ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: isSearch ? null : Border.all(
              color: isDarkMode
                  ? const Color(0xFF48484A).withOpacity(0.3)
                  : const Color(0xFFE5E5EA).withOpacity(0.5),
              width: 0.5,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    color: isSearch 
                        ? Colors.white 
                        : (isDarkMode
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF8E8E93)),
                    size: 22,
                  )
                : Text(
                    text!,
                    style: TextStyle(
                      fontSize: isSpace ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: isSearch 
                          ? Colors.white 
                          : (isDarkMode
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
} 