part of 'profile_screen.dart';

// Profil ekranındaki geliştirici test araçları. Yalnızca debug/profile
// derlemelerinde gösterilir; ekranın asıl kodunu kalabalıklaştırmasın
// diye ayrı dosyada tutulur.
extension _ProfileDebugTools on _ProfileScreenState {
  /// Kullanım süresi, değerlendirme ve satın alma akışlarını elle tetiklemek için test butonları.
  List<Widget> _buildDebugButtons(BuildContext context) => [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEBUG PANEL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _appUsageService.setUsageTimeForTest(31);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kullanım süresi 31 dakikaya ayarlandı'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      '31 dakika',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _reviewService.resetRatingStatus();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Değerlendirme durumu sıfırlandı - Yıldız butonu aktif'),
                            backgroundColor: Colors.purple,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text(
                      'Yıldız Reset',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _appUsageService.resetUsageStats();
                      await _reviewService.resetRatingStatus();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tüm veriler sıfırlandı'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Tümünü Sıfırla',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Reklam kaldırma durumunu toggle et
                      await _creditsService.toggleAdsFreeForTest();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_creditsService.isLifetimeAdsFree
                                ? 'Reklamsız kullanım aktif'
                                : 'Reklamsız kullanım deaktif'),
                            backgroundColor: _creditsService.isLifetimeAdsFree
                                ? Colors.green
                                : Colors.orange,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _creditsService.isLifetimeAdsFree
                          ? Colors.green
                          : Colors.blue,
                    ),
                    child: Text(
                      _creditsService.isLifetimeAdsFree ? 'Premium AÇ' : 'Premium KAP',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final bookId = 'kitab_kiraah_1';
                      try {
                        await _bookPurchase.loadProductFor(bookId);
                        final started = await _bookPurchase.buyBook(bookId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(started ? 'Satın alma başlatıldı' : (_bookPurchase.lastError.isNotEmpty ? _bookPurchase.lastError : 'Satın alma başlatılamadı')),
                              backgroundColor: started ? Colors.blue : Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Satın alma hatası: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: Text(
                      'Kıraat 1 Satın Al',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Reklam kaldırma satın alma testi
                      try {
                        await _purchaseService.loadProducts();
                        final started = await _purchaseService.buyRemoveAds();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(started ? 'Reklam kaldırma satın alma başlatıldı' : (_purchaseService.lastError.isNotEmpty ? _purchaseService.lastError : 'Satın alma başlatılamadı')),
                              backgroundColor: started ? Colors.blue : Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reklam kaldırma hatası: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: Text(
                      'Reklam Kaldır',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Interstitial reklam testi
                      try {
                        final AdMobService adService = AdMobService();
                        adService.forceShowInterstitialAd();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Interstitial reklam test edildi'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }

                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reklam test hatası: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                    ),
                    child: Text(
                      'Reklam Test',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Debug durumunu göster
                      final AdMobService adService = AdMobService();
                      adService.debugAdStatus();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Debug bilgileri console\'da'),
                            backgroundColor: Colors.purple,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: Text(
                      'Debug Info',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Mevcut kullanım: ${_appUsageService.totalUsageMinutes} dakika',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red,
              ),
            ),
            Text(
              'Reklamsız durumu: ${_creditsService.isLifetimeAdsFree ? "AKTİF" : "DEAKTİF"}',
              style: TextStyle(
                fontSize: 11,
                color: _creditsService.isLifetimeAdsFree ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Play Console: ${_purchaseService.isAvailable ? "BAĞLI" : "BAĞLI DEĞİL"}',
              style: TextStyle(
                fontSize: 11,
                color: _purchaseService.isAvailable ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ürün sayısı: ${_purchaseService.products.length}',
              style: TextStyle(
                fontSize: 11,
                color: _purchaseService.products.isEmpty ? Colors.red : Colors.green,
              ),
            ),
            Text(
              'Fiyat: ${_purchaseService.removeAdsPrice}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue,
              ),
            ),
            Text(
              'AdMob Credits: ${AdMobService().mounted ? "HAZIR" : "BEKLİYOR"}',
              style: TextStyle(
                fontSize: 11,
                color: AdMobService().mounted ? Colors.green : Colors.orange,
              ),
            ),
            Text(
              'Interstitial Ad: ${AdMobService().isInterstitialAdAvailable ? "MEVCUT" : "YOK"}',
              style: TextStyle(
                fontSize: 11,
                color: AdMobService().isInterstitialAdAvailable ? Colors.green : Colors.red,
              ),
            ),
            Text(
              'Native Ad Performance: OPTİMİZE',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Native Ad Mode: DİREKT YÜKLEME',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Performance Mode: KAPALI (Hızlı Yükleme)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
  ];

  /// Satın alma durumlarını simüle eden araçlar (sadece debug derlemede).
  List<Widget> _buildPurchaseTestTools(BuildContext context) => [
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Satın Alma Test Araçları (DEBUG)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Auth State Tests
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Auth State Null simüle ediliyor...');
                      await FirebaseAuth.instance.signOut();
                      debugPrint('🔍 [TEST] Console\'da auth null loglarını kontrol et');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Auth Null Test'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Restore Purchase tetikleniyor...');
                      try {
                        await OneTimePurchaseService().initialize();
                        await OneTimePurchaseService().restorePurchases();
                        await BookPurchaseService().initialize();
                        debugPrint('✅ [TEST] Restore Purchase tamamlandı');
                      } catch (e) {
                        debugPrint('❌ [TEST] Restore hatası: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Restore Test'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Purchase Status Tests  
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Satın alma durumları yazdırılıyor...');
                      final oneTime = OneTimePurchaseService();
                      final book = BookStoreService();
                      final credits = CreditsService();

                      debugPrint('📊 [TEST] OneTime AdsFree: ${oneTime.isLifetimeAdsFree}');
                      debugPrint('📊 [TEST] Credits Premium: ${credits.isPremium}');
                      debugPrint('📊 [TEST] Book 1 Purchased: ${book.isPurchased("kitab_kiraah_1")}');
                      debugPrint('📊 [TEST] Book 2 Purchased: ${book.isPurchased("kitab_kiraah_2")}');
                      debugPrint('📊 [TEST] Book 3 Purchased: ${book.isPurchased("kitab_kiraah_3")}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Durum Raporu'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Local cache durumu kontrol ediliyor...');
                      final prefs = await SharedPreferences.getInstance();

                      // Ads cache
                      final adsCache = prefs.getBool('lifetime_ads_free_cache');
                      final adsTimestamp = prefs.getInt('lifetime_ads_free_timestamp');
                      final adsUserId = prefs.getString('lifetime_ads_free_cache_user_id');

                      // Books cache
                      final booksCache = prefs.getStringList('purchased_books');
                      final booksUserId = prefs.getString('purchased_books_user_id');

                      debugPrint('📱 [TEST] Ads Cache: $adsCache (User: $adsUserId, timestamp: $adsTimestamp)');
                      debugPrint('📱 [TEST] Books Cache: $booksCache (User: $booksUserId)');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Cache Kontrol'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // TEST SATIN ALMA BUTONLARI
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.orange, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'TEST SATIN ALMA (Ücretsiz)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  SizedBox(height: 10),

                  // Premium Test
                  ElevatedButton.icon(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Premium (Abone) olma simüle ediliyor...');
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Önce giriş yapın!')),
                          );
                          return;
                        }

                        // Firestore'u güncelle
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'is_premium': true,
                          'premium_expiry': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
                        }, SetOptions(merge: true));

                        // Manager'ı yenile
                        if (!context.mounted) return;
                        await Provider.of<PurchaseManager>(context, listen: false).loadUserPurchases();

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ Debug: Premium verildi!')),
                        );
                      } catch (e) {
                        debugPrint('Test hatası: $e');
                      }
                    },
                    icon: const Icon(Icons.diamond_outlined),
                    label: const Text('DEBUG: Premium Yap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 36),
                    ),
                  ),

                  SizedBox(height: 10),

                  // Reklamları Kaldır Test
                  ElevatedButton.icon(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Reklamları Kaldır satın alımı simüle ediliyor...');
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Önce giriş yapın!')),
                          );
                          return;
                        }

                        // Firestore'a kaydet
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'lifetimeAdsFree': true,
                          'lastAdFreePurchase': FieldValue.serverTimestamp(),
                          'purchaseType': 'test_debug',
                        }, SetOptions(merge: true));

                        // Servisleri güncelle
                        final creditsService = CreditsService();
                        await creditsService.setLifetimeAdsFree(true);
                        await creditsService.initialize();

                        debugPrint('✅ [TEST] Reklamları kaldır aktifleştirildi!');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ TEST: Reklamları Kaldır Aktif!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        debugPrint('❌ [TEST] Hata: $e');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.block, size: 16),
                    label: Text('Reklamları Kaldır TEST'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 36),
                    ),
                  ),

                  SizedBox(height: 6),

                  // Kitap 1 Test
                  ElevatedButton.icon(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Kitap 1 satın alımı simüle ediliyor...');
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          debugPrint('❌ [TEST] Kullanıcı giriş yapmamış!');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Önce giriş yapın!')),
                          );
                          return;
                        }

                        // BookStoreService ile ekle
                        final bookStore = BookStoreService();
                        await bookStore.mockPurchase('kitab_kiraah_1');

                        debugPrint('✅ [TEST] Kitap 1 satın alındı!');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ TEST: Kitap 1 Aktif!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        debugPrint('❌ [TEST] Hata: $e');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.book, size: 16),
                    label: Text('Kitap 1 TEST'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 36),
                    ),
                  ),

                  SizedBox(height: 6),

                  // Kitap 2 Test
                  ElevatedButton.icon(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Kitap 2 satın alımı simüle ediliyor...');
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          debugPrint('❌ [TEST] Kullanıcı giriş yapmamış!');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Önce giriş yapın!')),
                          );
                          return;
                        }

                        // BookStoreService ile ekle
                        final bookStore = BookStoreService();
                        await bookStore.mockPurchase('kitab_kiraah_2');

                        debugPrint('✅ [TEST] Kitap 2 satın alındı!');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ TEST: Kitap 2 Aktif!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        debugPrint('❌ [TEST] Hata: $e');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.book, size: 16),
                    label: Text('Kitap 2 TEST'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 36),
                    ),
                  ),

                  SizedBox(height: 6),

                  // Kitap 3 Test
                  ElevatedButton.icon(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Kitap 3 satın alımı simüle ediliyor...');
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          debugPrint('❌ [TEST] Kullanıcı giriş yapmamış!');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Önce giriş yapın!')),
                          );
                          return;
                        }

                        // BookStoreService ile ekle
                        final bookStore = BookStoreService();
                        await bookStore.mockPurchase('kitab_kiraah_3');

                        debugPrint('✅ [TEST] Kitap 3 satın alındı!');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ TEST: Kitap 3 Aktif!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        debugPrint('❌ [TEST] Hata: $e');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.book, size: 16),
                    label: Text('Kitap 3 TEST'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 36),
                    ),
                  ),

                  SizedBox(height: 10),

                  // TÜM SATIN ALIMLARI TEMİZLE
                  ElevatedButton.icon(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Tüm satın alımlar temizleniyor...');
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          debugPrint('❌ [TEST] Kullanıcı giriş yapmamış!');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Önce giriş yapın!')),
                          );
                          return;
                        }

                        // Firestore'dan reklamları kaldırı temizle
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                          'lifetimeAdsFree': false,
                          'purchasedBooks': [],
                        });

                        // Servisleri sıfırla
                        final creditsService = CreditsService();
                        await creditsService.setLifetimeAdsFree(false);
                        await creditsService.initialize();

                        // BookStore'u sıfırla - manuel olarak
                        final bookStore = BookStoreService();
                        await bookStore.removePurchase('kitab_kiraah_1');
                        await bookStore.removePurchase('kitab_kiraah_2');
                        await bookStore.removePurchase('kitab_kiraah_3');

                        debugPrint('✅ [TEST] Tüm satın alımlar temizlendi!');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ TEST: Tüm Satın Alımlar Temizlendi!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } catch (e) {
                        debugPrint('❌ [TEST] Hata: $e');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.delete_forever, size: 16),
                    label: Text('TÜM SATIN ALIMLARI TEMİZLE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 36),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Logout Test
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      debugPrint('🧪 [TEST] Manuel çıkış testi başlatılıyor...');
                      debugPrint('📊 [TEST] Çıkış öncesi durumlar:');

                      final oneTime = OneTimePurchaseService();
                      final book = BookStoreService();
                      debugPrint('   - AdsFree: ${oneTime.isLifetimeAdsFree}');
                      debugPrint('   - Books: ${book.isPurchased("kitab_kiraah_1")}, ${book.isPurchased("kitab_kiraah_2")}, ${book.isPurchased("kitab_kiraah_3")}');

                      await FirebaseAuth.instance.signOut();
                      debugPrint('🚪 [TEST] Çıkış yapıldı - 2 saniye sonra kontrol edilecek...');

                      await Future.delayed(Duration(seconds: 2));

                      debugPrint('📊 [TEST] Çıkış sonrası durumlar:');
                      debugPrint('   - AdsFree: ${oneTime.isLifetimeAdsFree}');
                      debugPrint('   - Books: ${book.isPurchased("kitab_kiraah_1")}, ${book.isPurchased("kitab_kiraah_2")}, ${book.isPurchased("kitab_kiraah_3")}');
                      debugPrint('🔍 [TEST] Bu değerler FALSE olmalı (güvenlik için)');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Manuel Çıkış Testi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // 🧹 DEBUG: Veritabanı temizlik bölümü (sadece debug modda)
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Veritabanı Araçları (DEBUG)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      debugPrint('🔍 Veritabanı analizi başlatılıyor...');
                      await DatabaseCleanupUtility.printDatabaseStatus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Analiz Et'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      debugPrint('🧹 Otomatik temizlik başlatılıyor...');
                      final result = await DatabaseCleanupUtility.performAutoCleanup();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result.containsKey('error') 
                                ? 'Hata: ${result['error']}'
                                : '✅ Temizlendi: ${result['duplicatesDeleted']} duplicate, ${result['latinDeleted']} Latin harf',
                            ),
                            backgroundColor: result.containsKey('error') ? Colors.red : Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Temizle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
  ];
}
