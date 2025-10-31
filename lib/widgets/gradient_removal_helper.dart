import 'package:flutter/material.dart';

/// 🚀 PERFORMANCE MOD: Gradient'leri kaldırıp solid color'a dönüştüren yardımcı
class GradientRemovalHelper {
  // Light mode renkleri
  static const lightBackground = Color(0xFFF5F7FB);
  static const lightCard = Colors.white;
  static const lightCardAlt = Color(0xFFFAFAFA);
  static const lightBorder = Color(0xFFE5E5EA);
  
  // Dark mode renkleri
  static const darkBackground = Color(0xFF1C1C1E);
  static const darkCard = Color(0xFF2C2C2E);
  static const darkCardAlt = Color(0xFF3A3A3C);
  static const darkBorder = Color(0xFF48484A);
  
  // Optimize edilmiş BoxDecoration döndürür (gradient yerine solid color)
  static BoxDecoration getOptimizedDecoration({
    required bool isDarkMode,
    required double borderRadius,
    bool isCard = true,
    bool hasBorder = true,
    bool hasMinimalShadow = true,
  }) {
    return BoxDecoration(
      color: isDarkMode 
          ? (isCard ? darkCard : darkBackground)
          : (isCard ? lightCard : lightBackground),
      borderRadius: BorderRadius.circular(borderRadius),
      border: hasBorder 
          ? Border.all(
              color: (isDarkMode ? darkBorder : lightBorder).withOpacity(0.3),
              width: 0.5,
            )
          : null,
      boxShadow: hasMinimalShadow && !isDarkMode
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );
  }
  
  // Tek shadow döndürür (multiple shadow yerine)
  static List<BoxShadow> getOptimizedShadow({
    required bool isDarkMode,
    double opacity = 0.04,
    double blurRadius = 2,
    Offset offset = const Offset(0, 1),
  }) {
    if (isDarkMode) return [];
    
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }
  
  // Text style optimizasyonu
  static TextStyle getOptimizedTextStyle({
    required bool isDarkMode,
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    bool isArabic = false,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isDarkMode ? Colors.white : Colors.black87,
      // Arapça için özel optimizasyonlar
      fontFeatures: isArabic ? const [
        FontFeature.enable('liga'),
        FontFeature.enable('calt'),
      ] : null,
      // GPU'da daha hızlı render için
      decoration: TextDecoration.none,
      decorationThickness: 0,
    );
  }
} 