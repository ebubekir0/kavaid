import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/purchase_manager.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  String _selectedPlan = 'monthly';

  static const String _privacyPolicyUrl = 'https://kavaid.app/privacy';
  static const String _termsOfUseUrl = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  @override
  void initState() {
    super.initState();
    final pm = Provider.of<PurchaseManager>(context, listen: false);
    pm.addListener(_onPurchaseUpdate);
    pm.fetchProducts();
  }

  @override
  void dispose() {
    final pm = Provider.of<PurchaseManager>(context, listen: false);
    pm.removeListener(_onPurchaseUpdate);
    super.dispose();
  }

  void _onPurchaseUpdate() {
    if (!mounted) return;
    final pm = Provider.of<PurchaseManager>(context, listen: false);
    if (pm.isPremium) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Premium üyelik aktif!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bağlantı açılamadı: $e')),
        );
      }
    }
  }

  Future<void> _handlePurchase() async {
    final pm = Provider.of<PurchaseManager>(context, listen: false);

    setState(() => _isLoading = true);
    try {
      if (pm.getPrice('monthly').isEmpty && pm.getPrice('yearly').isEmpty) {
        await pm.fetchProducts();
      }
      if (_selectedPlan == 'monthly') {
        await pm.buyPremiumMonthly();
      } else {
        await pm.buyPremiumYearly();
      }

      // Hata kontrolü
      if (pm.lastError.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pm.lastError),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pm = Provider.of<PurchaseManager>(context);
    const gradientStart = Color(0xFF0D47A1);
    const gradientEnd = Color(0xFF1976D2);

    final monthlyPrice = pm.getPrice('monthly').isEmpty ? '79,99₺' : pm.getPrice('monthly');
    final yearlyPrice = pm.getPrice('yearly').isEmpty ? '479,99₺' : pm.getPrice('yearly');
    final yearlyMonthlyCost = pm.getMonthlyCostForYearly().isEmpty ? '40₺/ay' : pm.getMonthlyCostForYearly();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  // ÜST BAR: Çarpı Butonu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),

                  // ANA İÇERİK - SCROLLABLE (iPad ve her ekran boyutuna uygun)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        children: [
                          // 1. HEADER
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Kavaid Premium",
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBullet("Çeviriye sınırsız erişim"),
                          const SizedBox(height: 8),
                          _buildBullet("7000+ fiilin 24 sığa emsile çekimlerini aç"),
                          const SizedBox(height: 8),
                          _buildBullet("Öğren kısmındaki tüm materyallere erişim"),
                          const SizedBox(height: 8),
                          _buildBullet("Kuran Sözlüğüne Sınırsız Erişim"),
                          const SizedBox(height: 8),
                          _buildBullet("Sınırsız kelime kartı ve liste oluştur"),
                          const SizedBox(height: 8),
                          _buildBullet("Reklamsız deneyim"),

                          const SizedBox(height: 24),

                          // 2. PLANLAR (Aylık ve Yıllık)
                          _buildPlanTile(
                            id: 'monthly',
                            title: 'Aylık Abonelik',
                            subtitleText: '1 Ay boyunca sınırsız erişim',
                            price: monthlyPrice,
                            badge: null,
                          ),
                          const SizedBox(height: 12),
                          _buildPlanTile(
                            id: 'yearly',
                            title: 'Yıllık Abonelik',
                            subtitleText: '1 Yıl boyunca sınırsız erişim ($yearlyMonthlyCost)',
                            price: yearlyPrice,
                            badge: '%50 İNDİRİM',
                          ),

                          const SizedBox(height: 20),

                          // 3. SATIN ALMA BUTONU
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handlePurchase,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: gradientStart,
                                disabledBackgroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: gradientStart, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      _selectedPlan == 'monthly'
                                          ? "Aylık Abone Ol ($monthlyPrice)"
                                          : "Yıllık Abone Ol ($yearlyPrice)",
                                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 4. ABONELİK AÇIKLAMASI (App Store / Guideline 3.1.2 Uyumu)
                          Text(
                            "Ödeme Apple ID hesabınızdan tahsil edilir. Abonelik, dönem sonundan en az 24 saat önce iptal edilmediği sürece otomatik yenilenir. İstediğiniz zaman App Store Hesap Ayarları'ndan iptal edebilirsiniz.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.75),
                              height: 1.35,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 5. SATIN ALMALARI GERİ YÜKLE & YASAL LİNKLER (EULA & Gizlilik Politikası)
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Satın almalar kontrol ediliyor...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  await Provider.of<PurchaseManager>(context, listen: false).restorePurchases();
                                },
                                child: Text(
                                  "Satın Almaları Geri Yükle",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                              Text("•", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                              GestureDetector(
                                onTap: () => _openUrl(_termsOfUseUrl),
                                child: Text(
                                  "Kullanım Koşulları (EULA)",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                              Text("•", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                              GestureDetector(
                                onTap: () => _openUrl(_privacyPolicyUrl),
                                child: Text(
                                  "Gizlilik Politikası",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13.5, color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTile({
    required String id,
    required String title,
    required String subtitleText,
    required String price,
    String? badge,
  }) {
    final isSelected = _selectedPlan == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF1976D2) : Colors.white54,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? const Color(0xFF1976D2) : Colors.white70,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (badge != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF1976D2) : Colors.white,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

