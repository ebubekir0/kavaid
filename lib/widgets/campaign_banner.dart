import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/campaign_screen.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';

/// Sözlük ana sayfasında gösterilen kampanya banner widget'ı.
/// Non-premium kullanıcılara ve kampanya aktifken gösterilir.
class CampaignBanner extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onDismiss;

  const CampaignBanner({
    super.key,
    required this.isDarkMode,
    this.onDismiss,
  });

  @override
  State<CampaignBanner> createState() => _CampaignBannerState();
}

class _CampaignBannerState extends State<CampaignBanner> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return InkWell(
      onTap: () {
        final auth = AuthService();
        if (!auth.isSignedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LanguageService().isEnglish 
                    ? 'Please log in or sign up first' 
                    : (LanguageService().isArabic ? 'يرجى تسجيل الدخول أو الاشتراك أولاً' : 'Lütfen önce kayıt olun, giriş yapın.'),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black87,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.fixed,
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CampaignScreen(isDarkMode: isDark),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0)], // Mavi tonları
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D47A1).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '1 Ay Ücretsiz Premium Kazan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

