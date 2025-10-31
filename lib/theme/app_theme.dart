import 'package:flutter/material.dart';

class AppTheme {
  // Ana renkler
  static const Color primaryColor = Color(0xFF007AFF);
  static const Color secondaryColor = Color(0xFF5AC8FA);
  static const Color accentColor = Color(0xFF34C759);
  
  // Arka plan renkleri
  static const Color lightBackground = Color(0xFFF5F7FB);
  static const Color darkBackground = Color(0xFF1C1C1E);
  
  // Kart renkleri
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF2C2C2E);
  
  // Metin renkleri
  static const Color darkText = Color(0xFF2C2C2E);
  static const Color lightText = Color(0xFFE5E5EA);
  static const Color greyText = Color(0xFF8E8E93);
  
  // Durum renkleri
  static const Color successColor = Color(0xFF34C759);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color errorColor = Color(0xFFFF3B30);
  
  // Gölge
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  // Border radius
  static const double cardRadius = 16.0;
  static const double buttonRadius = 8.0;
  static const double inputRadius = 6.0;
}
