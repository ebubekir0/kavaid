import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/purchase_manager.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  String _selectedPlan = 'monthly';

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
        const SnackBar(content: Text('🎉 Premium üyelik aktif!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _handlePurchase() async {
    final pm = Provider.of<PurchaseManager>(context, listen: false);
    
    // Ürünlerin yüklenip yüklenmediğini kontrol et
    if (pm.getPrice('monthly').isEmpty && pm.getPrice('yearly').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürünler henüz yüklenmedi veya market ayarları eksik. Lütfen biraz sonra tekrar deneyin.'))
      );
      // Tekrar çekmeye çalış
      pm.fetchProducts();
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_selectedPlan == 'monthly') {
        await pm.buyPremiumMonthly();
      } else {
        await pm.buyPremiumYearly();
      }
      
      // Hata kontrolü
      if (pm.lastError.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(pm.lastError), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pm = Provider.of<PurchaseManager>(context);
    const gradientStart = Color(0xFF0D47A1); 
    const gradientEnd = Color(0xFF1976D2);   

    // Ekran boyutuna göre dinamik ölçekleme
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: true, 
          child: Column(
            children: [
              // ÜST BAR: Çarpı Butonu (Tam sol köşede)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding azaltıldı
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

              // ANA İÇERİK (Padding ile sarılı)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // 1. HEADER (Flex değerini düşürdüm, yer açmak için)
                      Expanded(
                        flex: isSmallScreen ? 3 : 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12), // Padding küçültüldü
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.white), // İkon küçültüldü
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 16),
                            Text(
                              "Kavaid Premium",
                              style: GoogleFonts.outfit(
                                fontSize: isSmallScreen ? 22 : 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 20),
                            _buildBullet("Öğren kısmındaki tüm materyallere erişim"),
                            const SizedBox(height: 8),
                            _buildBullet("Sınırsız kelime kartı ve liste oluştur"),
                            const SizedBox(height: 8),
                            _buildBullet("Reklamsız deneyim"),
                          ],
                        ),
                      ),
                      
                      // 2. PLANLAR (Aylık ve Yıllık)
                      Expanded(
                        flex: isSmallScreen ? 5 : 4, 
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // AYLIK PLAN
                            _buildPlanTile(
                              id: 'monthly', 
                              title: 'Aylık', 
                              price: pm.getPrice('monthly').isEmpty ? '₺79,99' : pm.getPrice('monthly'), 
                              badge: null,
                              isSmall: isSmallScreen
                            ),
                            const SizedBox(height: 12),
                            // YILLIK PLAN - %50 İNDİRİM
                            _buildPlanTile(
                              id: 'yearly', 
                              title: 'Yıllık', 
                              price: pm.getPrice('yearly').isEmpty ? '₺479,99' : pm.getPrice('yearly'), 
                              badge: '%50 İNDİRİM',
                              subtitle: pm.getMonthlyCostForYearly().isEmpty ? '₺40/ay' : pm.getMonthlyCostForYearly(),
                              isSmall: isSmallScreen
                            ),
                          ],
                        ),
                      ),
                      
                      // 3. BUTON ve Footer
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _handlePurchase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: gradientStart,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: _isLoading 
                                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: gradientStart, strokeWidth: 2.5))
                                  : Text("Abone Ol", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "İstediğin zaman iptal edebilirsin.",
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Abonelik otomatik yenilenir.",
                              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
                            ),
                            const SizedBox(height: 16),
                            // SATIN ALMALARI GERİ YÜKLE
                            GestureDetector(
                              onTap: () async {
                                final pm = Provider.of<PurchaseManager>(context, listen: false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Satın almalar kontrol ediliyor...'), duration: Duration(seconds: 2)),
                                );
                                await pm.restorePurchases();
                              },
                              child: Text(
                                "Satın Almaları Geri Yükle",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white70,
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
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTile({
    required String id, 
    required String title, 
    required String price, 
    String? badge,
    String? subtitle,
    bool isSmall = false,
  }) {
    final isSelected = _selectedPlan == id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isSmall ? 64 : 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      fontSize: isSmall ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
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
                    child: Text(badge, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
                Text(
                  price,
                  style: TextStyle(
                    fontSize: isSmall ? 15 : 17, 
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
