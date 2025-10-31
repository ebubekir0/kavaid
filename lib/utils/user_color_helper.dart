import 'dart:math';
import 'package:flutter/material.dart';

class UserColorHelper {
  // WhatsApp tarzı renkler
  static final List<Color> _colors = [
    const Color(0xFF00A884), // WhatsApp yeşil
    const Color(0xFF0088CC), // Telegram mavi
    const Color(0xFFE91E63), // Pembe
    const Color(0xFF9C27B0), // Mor
    const Color(0xFF673AB7), // Derin mor
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF2196F3), // Mavi
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF009688), // Teal
    const Color(0xFF4CAF50), // Yeşil
    const Color(0xFFFF9800), // Turuncu
    const Color(0xFFFF5722), // Derin turuncu
    const Color(0xFFF44336), // Kırmızı
    const Color(0xFF795548), // Kahverengi
  ];

  /// Kullanıcı ID'sine göre tutarlı renk döndürür
  static Color getColorForUser(String userId) {
    if (userId.isEmpty) return _colors[0];
    
    // userId'nin hash'ini al ve renk listesinden seç
    final hash = userId.hashCode.abs();
    final index = hash % _colors.length;
    return _colors[index];
  }

  /// Kullanıcı adının baş harfini döndürür
  static String getInitials(String username) {
    if (username.isEmpty) return '?';
    return username[0].toUpperCase();
  }

  /// Profil resmi widget'ı oluşturur
  static Widget buildProfileAvatar({
    required String userId,
    required String username,
    String? photoUrl,
    double radius = 20,
  }) {
    final color = getColorForUser(userId);
    final initials = getInitials(username);

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color,
        child: ClipOval(
          child: Image.network(
            photoUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Resim yüklenemezse baş harfi göster
              return Container(
                width: radius * 2,
                height: radius * 2,
                color: color,
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              // Yüklenirken baş harfi göster
              return Container(
                width: radius * 2,
                height: radius * 2,
                color: color,
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
