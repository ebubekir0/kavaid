import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloud_saved_words_service.dart';
import '../services/credits_service.dart';
import '../services/one_time_purchase_service.dart';
import '../services/turkce_analytics_service.dart';
import '../services/app_usage_service.dart';
import '../services/global_config_service.dart';
import '../services/admob_service.dart';
import '../services/review_service.dart';
import '../services/book_store_service.dart';
import '../services/book_purchase_service.dart';
import '../services/profile_sync_service.dart';
import '../utils/database_cleanup_utility.dart';
import '../widgets/fps_counter_widget.dart';
import '../utils/user_color_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../services/purchase_manager.dart';
import 'subscription_screen.dart';
import 'package:kavaid/widgets/email_auth_sheet.dart';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  final double bottomPadding;
  final bool isDarkMode;
  final VoidCallback? onThemeToggle;
  final bool autoOpenLoginSheet;

  const ProfileScreen({
    super.key,
    required this.bottomPadding,
    required this.isDarkMode,
    this.onThemeToggle,
    this.autoOpenLoginSheet = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ... (Other services remain, removed _purchaseService dependency for UI mostly)
  final CreditsService _creditsService = CreditsService();
  final OneTimePurchaseService _purchaseService = OneTimePurchaseService();
  final AppUsageService _appUsageService = AppUsageService();
  final GlobalConfigService _globalConfigService = GlobalConfigService();
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  final CloudSavedWordsService _cloudSavedWords = CloudSavedWordsService();
  final BookStoreService _bookStore = BookStoreService();
  final BookPurchaseService _bookPurchase = BookPurchaseService();
  final ProfileSyncService _profileSync = ProfileSyncService();
  
  String? _userRole; // 'founder', 'moderator', veya null
  StreamSubscription<DocumentSnapshot>? _roleSubscription;

  @override
  void initState() {
    super.initState();
    _creditsService.addListener(_updateState);
    _purchaseService.addListener(_updateState);
    _appUsageService.addListener(_updateState);
    _globalConfigService.addListener(_updateState);
    _authService.addListener(_updateState); 
    _bookStore.initialize();
    _bookPurchase.addListener(_updateState);
    _bookPurchase.initialize();
    _checkUserRole(); 
    _listenToRoleChanges(); 
    
    // Play Console'dan fiyat bilgilerini yükle
    _loadPurchaseData();

    // İstek: Dışardan giriş ekranını doğrudan açma
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.autoOpenLoginSheet && !_authService.isSignedIn) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        EmailAuthSheet.show(context, initialIsLogin: true);
      }
    });
  }
  
  // Değerlendirme ekranını aç
  Future<void> _openInAppReview() async {
    await _reviewService.requestReview();
    // Butonun kaybolması için UI'ı güncelle
    setState(() {}); 
  }

  Future<void> _loadPurchaseData() async {
    // OneTimePurchaseService henüz başlatılmamışsa başlat
    try {
      if (_purchaseService.products.isEmpty) {
        debugPrint('📦 [PROFILE] One-time purchase service ürünleri yükleniyor...');
        await _purchaseService.initialize();
        debugPrint('✅ [PROFILE] One-time purchase service başlatıldı, ürün sayısı: ${_purchaseService.products.length}');
      }
      
      // Fiyat güncellemesi için UI'ı yenile
      if (mounted) {
        setState(() {});
        debugPrint('🔄 [PROFILE] UI güncellendi, fiyat: ${_purchaseService.removeAdsPrice}');
      }
    } catch (e) {
      debugPrint('❌ [PROFILE] Purchase data yükleme hatası: $e');
    }
  }

  @override
  void dispose() {
    _creditsService.removeListener(_updateState);
    _purchaseService.removeListener(_updateState);
    _appUsageService.removeListener(_updateState);
    _globalConfigService.removeListener(_updateState);
    _authService.removeListener(_updateState); // Auth listener'ı kaldır
    _bookPurchase.removeListener(_updateState);
    _roleSubscription?.cancel(); // Role listener'ı iptal et
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }
  
  // Kullanıcı yetkisini kontrol et
  Future<void> _checkUserRole() async {
    if (!_authService.isSignedIn) {
      setState(() => _userRole = null);
      return;
    }
    
    final userId = _authService.userId;
    final userEmail = _authService.userEmail;
    
    print('🔍 [PROFILE] Yetki kontrolü: Email=$userEmail, UserId=$userId');
    
    // Kurucu mu? (Email kontrolü)
    if (userEmail != null && userEmail.toLowerCase() == 'ebubekir@gmail.com') {
      print('👑 [PROFILE] KURUCU tespit edildi');
      setState(() => _userRole = 'founder');
      return;
    }
    
    // Moderatör mü? (Firestore'dan kontrol)
    if (userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        final role = userDoc.data()?['role'] as String?;
        print('📄 [PROFILE] Firestore role: $role');
        
        if (role == 'moderator') {
          print('⭐ [PROFILE] MODERATÖR tespit edildi');
          setState(() => _userRole = 'moderator');
        } else {
          print('👤 [PROFILE] Normal kullanıcı');
          setState(() => _userRole = null);
        }
      } catch (e) {
        print('❌ [PROFILE] Firestore okuma hatası: $e');
        setState(() => _userRole = null);
      }
    }
  }
  
  // Role değişikliklerini gerçek zamanlı dinle
  void _listenToRoleChanges() {
    final userId = _authService.userId;
    final userEmail = _authService.userEmail;
    if (userId == null) return;
    
    _roleSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      
      final role = snapshot.data()?['role'] as String?;
      
      String? newRole;
      
      // Kurucu email kontrolü
      if (userEmail != null && userEmail.toLowerCase() == 'ebubekir@gmail.com') {
        newRole = 'founder';
      } 
      // Moderatör Firestore kontrolü
      else if (role == 'moderator') {
        newRole = 'moderator';
      } 
      // Normal kullanıcı
      else {
        newRole = null;
      }
      
      if (_userRole != newRole) {
        setState(() => _userRole = newRole);
        print('🔄 Profil yetkisi güncellendi: ${newRole ?? "NORMAL"}');
      }
    });
  }

  // Profil resmi seçme
  Future<void> _pickProfileImage() async {
    // İnternet kontrolü
    bool hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showInternetRequiredDialog('Profil resmi yüklemek için internet bağlantısı gereklidir.');
      return;
    }
    
    try {
      debugPrint('📸 [PROFILE] Profil resmi seçme başlatıldı');
      
      final ImagePicker picker = ImagePicker();
      debugPrint('📸 [PROFILE] ImagePicker oluşturuldu - Android Photo Picker kullanılacak');
      
      // Android 13+ için Photo Picker otomatik kullanılır (izin gerekmez)
      // Android 12 ve altı için gallery seçici kullanılır
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
        // Android Photo Picker tercih edilir (image_picker otomatik yapar)
        requestFullMetadata: false, // Sadece temel metadata al
      );

      if (image == null) {
        debugPrint('⚠️ [PROFILE] Resim seçilmedi (kullanıcı iptal etti)');
        return;
      }

      debugPrint('✅ [PROFILE] Resim seçildi: ${image.path}');
      debugPrint('📏 [PROFILE] Resim boyutu: ${await image.length()} bytes');

      // Loading göster
      if (!mounted) {
        debugPrint('⚠️ [PROFILE] Widget mounted değil, işlem iptal');
        return;
      }
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Firebase Storage'a yükle
      final userId = _authService.userId;
      if (userId == null) {
        debugPrint('❌ [PROFILE] User ID null, işlem iptal');
        if (mounted) Navigator.pop(context);
        return;
      }

      debugPrint('👤 [PROFILE] User ID: $userId');

      // Storage referansı - userId'yi path olarak kullan
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/$userId');

      debugPrint('☁️ [PROFILE] Firebase Storage referansı oluşturuldu');
      debugPrint('📤 [PROFILE] Resim yükleniyor...');

      await storageRef.putFile(File(image.path));
      debugPrint('✅ [PROFILE] Resim Firebase Storage\'a yüklendi');

      final downloadUrl = await storageRef.getDownloadURL();
      debugPrint('🔗 [PROFILE] Download URL alındı: $downloadUrl');

      // Firestore'a kaydet
      debugPrint('💾 [PROFILE] Firestore\'a kaydediliyor...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'photoUrl': downloadUrl,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ [PROFILE] Firestore\'a kaydedildi');

      // Firebase Auth'a da kaydet
      debugPrint('🔐 [PROFILE] Firebase Auth güncelleniyor...');
      await _authService.currentUser?.updatePhotoURL(downloadUrl);
      debugPrint('✅ [PROFILE] Firebase Auth güncellendi');

      // Eski mesajlardaki profil resmini güncelle
      debugPrint('🔄 [PROFILE] Eski mesajlardaki profil resmi güncelleniyor...');
      await _profileSync.updateUserPhotoInMessages(userId, downloadUrl);
      debugPrint('✅ [PROFILE] Eski mesajlar güncellendi');

      if (mounted) {
        Navigator.pop(context); // Loading kapat
        debugPrint('✅ [PROFILE] Profil resmi başarıyla güncellendi!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil resmi güncellendi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [PROFILE] HATA: $e');
      debugPrint('📍 [PROFILE] Stack trace: $stackTrace');
      
      String errorMessage = 'Bir hata oluştu';
      
      if (e.toString().contains('object-not-found')) {
        errorMessage = 'Firebase Storage yapılandırılmamış. Lütfen Firebase Console\'dan Storage\'ı aktifleştirin.';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = 'İzin hatası. Storage kurallarını kontrol edin.';
      } else if (e.toString().contains('unauthorized')) {
        errorMessage = 'Yetkilendirme hatası. Lütfen giriş yapın.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'İnternet bağlantısı hatası.';
      }
      
      if (mounted) {
        try {
          Navigator.pop(context); // Loading kapat
        } catch (_) {
          debugPrint('⚠️ [PROFILE] Navigator.pop hatası (dialog zaten kapalı olabilir)');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Detay',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hata Detayı'),
                    content: SingleChildScrollView(
                      child: Text(e.toString()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // 📱 STATUS BAR: Profil ekranında her iki temada da mavi
        statusBarColor: const Color(0xFF007AFF),
        statusBarIconBrightness: Brightness.light, // Mavi arka planda beyaz iconlar
        statusBarBrightness: Brightness.dark, // iOS için
        // System navigation bar tema uyumlu ayarlar
        systemNavigationBarColor: isDarkMode 
            ? const Color(0xFF1C1C1E)  // Dark tema için siyah
            : Colors.white,            // Light tema için beyaz
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: FPSOverlay(
        showFPS: kDebugMode, // Debug modda FPS göster
        detailedFPS: true,   // Detaylı FPS bilgileri
        child: Scaffold(
          backgroundColor: isDarkMode 
              ? const Color(0xFF1C1C1E) 
              : const Color(0xFFF2F2F7),
          appBar: AppBar(
            backgroundColor: const Color(0xFF007AFF),
            elevation: 0,
            title: const Text(
              'Profil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            actions: [
              if (widget.onThemeToggle != null)
                // Tema değiştirme toggle butonu (yalnızca callback varsa)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 50,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: widget.isDarkMode 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.3),
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          left: widget.isDarkMode ? 22 : 2,
                          top: 2,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                size: 16,
                                color: widget.isDarkMode 
                                    ? const Color(0xFF007AFF)
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ),
                        // Tıklanabilir alan
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: widget.onThemeToggle,
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, widget.bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hesap - Sade: yalnız giriş / kayıt butonları
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_authService.isSignedIn)
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(_authService.userId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            // Username kontrolü - field yoksa null döner
                            String? username;
                            bool? usernameChanged;
                            try {
                              username = snapshot.data?.get('username') as String?;
                              usernameChanged = snapshot.data?.get('usernameChanged') as bool?;
                            } catch (e) {
                              username = null;
                              usernameChanged = null;
                            }
                            
                            // Username yoksa displayName veya email kullan
                            final displayText = username ?? _authService.displayName ?? _authService.userEmail?.split('@')[0] ?? 'Kullanıcı';
                            
                            // Firestore'dan photoUrl al, yoksa Auth'dan al
                            String? photoUrl;
                            try {
                              photoUrl = snapshot.data?.get('photoUrl') as String?;
                            } catch (e) {
                              photoUrl = null;
                            }
                            photoUrl ??= _authService.photoUrl;
                            
                            return Row(
                              children: [
                                // Profil resmi (tıklanabilir)
                                GestureDetector(
                                  onTap: () {
                                    debugPrint('🖼️ [PROFILE] Profil resmi tıklandı');
                                    _pickProfileImage();
                                  },
                                  child: Stack(
                                    children: [
                                      UserColorHelper.buildProfileAvatar(
                                        userId: _authService.userId!,
                                        username: displayText,
                                        photoUrl: photoUrl,
                                        radius: 30,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF007AFF),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Kullanıcı adı ve yetki etiketi
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              displayText,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode ? Colors.white : Colors.black,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // Kullanıcı adı düzenleme butonu (sadece değiştirilmemişse göster)
                                          if (usernameChanged != true) ...[
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _onUsernameEditTap(isDarkMode, displayText),
                                              child: Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: const Color(0xFF007AFF),
                                              ),
                                            ),
                                          ],
                                          // ROL ETİKETİ (KURUCU/MODERATÖR)
                                          if (_userRole == 'founder' || _userRole == 'moderator') ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _userRole == 'founder'
                                                    ? const Color(0xFFFF6B35).withOpacity(0.15)
                                                    : const Color(0xFF4ECDC4).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: _userRole == 'founder'
                                                      ? const Color(0xFFFF6B35).withOpacity(0.3)
                                                      : const Color(0xFF4ECDC4).withOpacity(0.3),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                _userRole == 'founder' ? 'KURUCU' : 'MODERATÖR',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: _userRole == 'founder'
                                                      ? const Color(0xFFFF6B35)
                                                      : const Color(0xFF4ECDC4),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                          // MODERATÖR etiketi
                                          if (_userRole == 'moderator') ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDarkMode 
                                                    ? Colors.grey[800]?.withOpacity(0.5)
                                                    : Colors.grey[300]?.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: isDarkMode 
                                                      ? Colors.grey[600]!
                                                      : Colors.grey[500]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                'MODERATÖR',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkMode 
                                                      ? Colors.grey[400]
                                                      : Colors.grey[700],
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _authService.userEmail ?? 'Email yok',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        title: const Text('Çıkış yapılsın mı?'),
                                        content: const Text('Oturumunuz kapatılacak.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(dCtx).pop(false),
                                            child: const Text('İptal'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(dCtx).pop(true),
                                            child: const Text('Çıkış'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _authService.signOut();
                                      if (mounted) setState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.logout, size: 16),
                                  label: const Text('Çıkış'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (_authService.isSignedIn && defaultTargetPlatform != TargetPlatform.iOS && Provider.of<PurchaseManager>(context).isPremium)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: InkWell(
                              onTap: () async {
                                final url = defaultTargetPlatform == TargetPlatform.iOS
                                  ? Uri.parse("https://apps.apple.com/account/subscriptions")
                                  : Uri.parse("https://play.google.com/store/account/subscriptions");
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.payment, color: isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Aboneliği Yönet",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // GERİ YÜKLE BUTONU
                                    InkWell(
                                      onTap: () async {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Satın almalar kontrol ediliyor...'), duration: Duration(seconds: 2)),
                                        );
                                        await Provider.of<PurchaseManager>(context, listen: false).restorePurchases();
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.restore, color: isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Geri Yükle",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // HESAP SİLME (Apple Gereksinimi)
                        if (_authService.isSignedIn)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dCtx) => AlertDialog(
                                    title: const Text('Hesabınızı silmek istediğinize emin misiniz?'),
                                    content: const Text('Bu işlem geri alınamaz ve tüm verileriniz (kaydedilen kelimeler, puanlar vb.) kalıcı olarak silinecektir.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(dCtx).pop(false),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(dCtx).pop(true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Hesabımı Sil'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await _authService.deleteAccount();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Hesabınız başarıyla silindi.')),
                                      );
                                      setState(() {});
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Hata: ${e.toString()}'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                }
                              },
                              child: Text(
                                "Hesabı Sil",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.withOpacity(0.7),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      if (!_authService.isSignedIn) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Giriş yapın veya kayıt olun',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => EmailAuthSheet.show(context, initialIsLogin: true),
                            child: const Text('Giriş Yap'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF007AFF),
                              side: const BorderSide(color: Color(0xFF007AFF)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => EmailAuthSheet.show(context, initialIsLogin: false),
                            child: const Text('Kayıt Ol'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Reklam kaldırma önerisi veya durumu - Profil kısmının hemen altında
                // Premium / Abonelik Durumu Kartı
                Consumer<PurchaseManager>(
                  builder: (context, purchaseManager, _) {
                      if (defaultTargetPlatform != TargetPlatform.iOS) {
                        if (purchaseManager.isPremium) {
                          // 1. Premium Üye - MAVİ KART
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF007AFF).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Premium Üyesiniz",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        "Sınırsız içerik, reklamsız kullanım.",
                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (purchaseManager.isLifetimeNoAds) {
                          // 2. Sadece Reklamsız (Eski) - Hem Premium teşviki Hem de Legacy Bilgisi
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SubscriptionScreen())
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF007AFF).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 28),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              "Premium'a Geç",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "Tüm özelliklere erişin.",
                                              style: TextStyle(color: Colors.white70, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // LEGACY CARD - MAVİ VE SADE (Premium Tasarımına Benzer)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF007AFF), Color(0xFF0051D5)], // Premium ile aynı mavi tonları
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF007AFF).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: const Text(
                                        "Reklamsız Kullanım",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          // 3. Hiçbir şeyi yok - Premium'a Geç
                          return GestureDetector(
                            onTap: () {
                              if (!_authService.isSignedIn) {
                                _showLoginRequiredSnackBar();
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SubscriptionScreen())
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          "Premium'a Geç",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          "Sınırsız içerik, reklamsız kullanım.",
                                          style: TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                                ],
                              ),
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                  },
                ),
                
                const SizedBox(height: 12),
                
                
                // TEST: Debug butonları (sadece debug modda)
                if (!kReleaseMode) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
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
                                  if (mounted) {
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
                                  
                                  if (mounted) {
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
                                  
                                  if (mounted) {
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
                                  if (mounted) {
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
                                  if (!_authService.isSignedIn) {
                                    EmailAuthSheet.show(context, initialIsLogin: true);
                                    return;
                                  }
                                  try {
                                    await _bookPurchase.loadProductFor(bookId);
                                    final started = await _bookPurchase.buyBook(bookId);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(started ? 'Satın alma başlatıldı' : (_bookPurchase.lastError.isNotEmpty ? _bookPurchase.lastError : 'Satın alma başlatılamadı')),
                                          backgroundColor: started ? Colors.blue : Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
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
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(started ? 'Reklam kaldırma satın alma başlatıldı' : (_purchaseService.lastError.isNotEmpty ? _purchaseService.lastError : 'Satın alma başlatılamadı')),
                                          backgroundColor: started ? Colors.blue : Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
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
                ],
                
                // İstek: Sade UI için bulut senkron butonlarını göstermiyoruz

                // Paylaşım butonu - UI ile uyumlu
                GestureDetector(
                  onTap: _shareApp,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? const Color(0xFF2C2C2E) 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode 
                            ? const Color(0xFF3A3A3C)
                            : const Color(0xFFE5E5EA),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
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
                            color: const Color(0xFF007AFF).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.share_rounded,
                            color: const Color(0xFF007AFF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Uygulamayı Paylaş',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isDarkMode 
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // İletişim Kartı
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Icon(
                              Icons.email_outlined,
                              size: 48,
                              color: const Color(0xFF007AFF),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'İletişim',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () async {
                                final Uri emailUri = Uri(
                                  scheme: 'mailto',
                                  path: 'ebubekirkul6153@gmail.com',
                                  queryParameters: {
                                    'subject': 'Kavaid Uygulaması Hakkında',
                                  },
                                );
                                if (await canLaunchUrl(emailUri)) {
                                  await launchUrl(emailUri);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF007AFF).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.mail_outline,
                                      color: const Color(0xFF007AFF),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ebubekirkul6153@gmail.com',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF007AFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
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
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
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
                            color: const Color(0xFF007AFF).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.email_outlined,
                            color: const Color(0xFF007AFF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'İletişim',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isDarkMode 
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6D6D70),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 🧪 DEBUG: Satın alma test araçları (sadece debug modda)
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                                  print('🧪 [TEST] Auth State Null simüle ediliyor...');
                                  await FirebaseAuth.instance.signOut();
                                  print('🔍 [TEST] Console\'da auth null loglarını kontrol et');
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
                                  print('🧪 [TEST] Restore Purchase tetikleniyor...');
                                  try {
                                    await OneTimePurchaseService().initialize();
                                    await OneTimePurchaseService().restorePurchases();
                                    await BookPurchaseService().initialize();
                                    print('✅ [TEST] Restore Purchase tamamlandı');
                                  } catch (e) {
                                    print('❌ [TEST] Restore hatası: $e');
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
                                  print('🧪 [TEST] Satın alma durumları yazdırılıyor...');
                                  final oneTime = OneTimePurchaseService();
                                  final book = BookStoreService();
                                  final credits = CreditsService();
                                  
                                  print('📊 [TEST] OneTime AdsFree: ${oneTime.isLifetimeAdsFree}');
                                  print('📊 [TEST] Credits Premium: ${credits.isPremium}');
                                  print('📊 [TEST] Book 1 Purchased: ${book.isPurchased("kitab_kiraah_1")}');
                                  print('📊 [TEST] Book 2 Purchased: ${book.isPurchased("kitab_kiraah_2")}');
                                  print('📊 [TEST] Book 3 Purchased: ${book.isPurchased("kitab_kiraah_3")}');
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
                                  print('🧪 [TEST] Local cache durumu kontrol ediliyor...');
                                  final prefs = await SharedPreferences.getInstance();
                                  
                                  // Ads cache
                                  final adsCache = prefs.getBool('lifetime_ads_free_cache');
                                  final adsTimestamp = prefs.getInt('lifetime_ads_free_timestamp');
                                  final adsUserId = prefs.getString('lifetime_ads_free_cache_user_id');
                                  
                                  // Books cache
                                  final booksCache = prefs.getStringList('purchased_books');
                                  final booksUserId = prefs.getString('purchased_books_user_id');
                                  
                                  print('📱 [TEST] Ads Cache: $adsCache (User: $adsUserId, timestamp: $adsTimestamp)');
                                  print('📱 [TEST] Books Cache: $booksCache (User: $booksUserId)');
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
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                                  print('🧪 [TEST] Premium (Abone) olma simüle ediliyor...');
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
                                    await Provider.of<PurchaseManager>(context, listen: false).loadUserPurchases();
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('✅ Debug: Premium verildi!')),
                                    );
                                  } catch (e) {
                                    print('Test hatası: $e');
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
                                  print('🧪 [TEST] Reklamları Kaldır satın alımı simüle ediliyor...');
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
                                    
                                    print('✅ [TEST] Reklamları kaldır aktifleştirildi!');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✅ TEST: Reklamları Kaldır Aktif!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    print('❌ [TEST] Hata: $e');
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
                                  print('🧪 [TEST] Kitap 1 satın alımı simüle ediliyor...');
                                  try {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      print('❌ [TEST] Kullanıcı giriş yapmamış!');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Önce giriş yapın!')),
                                      );
                                      return;
                                    }
                                    
                                    // BookStoreService ile ekle
                                    final bookStore = BookStoreService();
                                    await bookStore.mockPurchase('kitab_kiraah_1');
                                    
                                    print('✅ [TEST] Kitap 1 satın alındı!');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✅ TEST: Kitap 1 Aktif!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    print('❌ [TEST] Hata: $e');
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
                                  print('🧪 [TEST] Kitap 2 satın alımı simüle ediliyor...');
                                  try {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      print('❌ [TEST] Kullanıcı giriş yapmamış!');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Önce giriş yapın!')),
                                      );
                                      return;
                                    }
                                    
                                    // BookStoreService ile ekle
                                    final bookStore = BookStoreService();
                                    await bookStore.mockPurchase('kitab_kiraah_2');
                                    
                                    print('✅ [TEST] Kitap 2 satın alındı!');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✅ TEST: Kitap 2 Aktif!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    print('❌ [TEST] Hata: $e');
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
                                  print('🧪 [TEST] Kitap 3 satın alımı simüle ediliyor...');
                                  try {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      print('❌ [TEST] Kullanıcı giriş yapmamış!');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Önce giriş yapın!')),
                                      );
                                      return;
                                    }
                                    
                                    // BookStoreService ile ekle
                                    final bookStore = BookStoreService();
                                    await bookStore.mockPurchase('kitab_kiraah_3');
                                    
                                    print('✅ [TEST] Kitap 3 satın alındı!');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✅ TEST: Kitap 3 Aktif!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    print('❌ [TEST] Hata: $e');
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
                                  print('🧪 [TEST] Tüm satın alımlar temizleniyor...');
                                  try {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      print('❌ [TEST] Kullanıcı giriş yapmamış!');
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
                                    
                                    print('✅ [TEST] Tüm satın alımlar temizlendi!');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✅ TEST: Tüm Satın Alımlar Temizlendi!'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  } catch (e) {
                                    print('❌ [TEST] Hata: $e');
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
                                  print('🧪 [TEST] Manuel çıkış testi başlatılıyor...');
                                  print('📊 [TEST] Çıkış öncesi durumlar:');
                                  
                                  final oneTime = OneTimePurchaseService();
                                  final book = BookStoreService();
                                  print('   - AdsFree: ${oneTime.isLifetimeAdsFree}');
                                  print('   - Books: ${book.isPurchased("kitab_kiraah_1")}, ${book.isPurchased("kitab_kiraah_2")}, ${book.isPurchased("kitab_kiraah_3")}');
                                  
                                  await FirebaseAuth.instance.signOut();
                                  print('🚪 [TEST] Çıkış yapıldı - 2 saniye sonra kontrol edilecek...');
                                  
                                  await Future.delayed(Duration(seconds: 2));
                                  
                                  print('📊 [TEST] Çıkış sonrası durumlar:');
                                  print('   - AdsFree: ${oneTime.isLifetimeAdsFree}');
                                  print('   - Books: ${book.isPurchased("kitab_kiraah_1")}, ${book.isPurchased("kitab_kiraah_2")}, ${book.isPurchased("kitab_kiraah_3")}');
                                  print('🔍 [TEST] Bu değerler FALSE olmalı (güvenlik için)');
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
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                                  print('🔍 Veritabanı analizi başlatılıyor...');
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
                                  print('🧹 Otomatik temizlik başlatılıyor...');
                                  final result = await DatabaseCleanupUtility.performAutoCleanup();
                                  if (mounted) {
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginRequiredSnackBar() {
    if (!mounted) return;
    
    // Auth sheet'i aç - kullanıcı öyle istedi
    EmailAuthSheet.show(
      context, 
      initialIsLogin: false, // Kayıt ol sekmesi açılsın
      message: "Önce kayıt olup giriş yapmalısınız."
    );
  }

  Future<void> _shareApp() async {
    try {
      // Uygulama içi işlem flag'ini set et - reklam engellemek için
      AdMobService().setInAppActionFlag('paylaşım');
      
      // Analytics event'i gönder
      await TurkceAnalyticsService.uygulamaPaylasildi();
      
      const String packageName = 'com.onbir.kavaid';
      const String playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageName';
      
      await Share.share(
        playStoreUrl,
        subject: 'Kavaid - Arapça Sözlük Uygulaması',
      );
      
      debugPrint('✅ Uygulama başarıyla paylaşıldı');
      
      // Paylaşım tamamlandıktan 1 dakika sonra flag'i temizle
      // (1 dakika boyunca hiçbir şekilde geçiş reklamı gösterilmesin)
      Future.delayed(const Duration(minutes: 1), () {
        AdMobService().clearInAppActionFlag();
        debugPrint('🔓 Paylaşım işlemi sonrası 1 dakika flag temizlendi');
      });
      
    } catch (e) {
      debugPrint('❌ Paylaşım hatası: $e');
      // Hata durumunda da flag'i temizle
      AdMobService().clearInAppActionFlag();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paylaşım sırasında bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoginRequiredBottomSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Icon(Icons.lock_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'LÜTFEN ÖNCE KAYIT OLUP GİRİŞ YAPIN',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPurchaseDialog() {
    // Güçlü klavye kapatma - dialog açılmadan önce
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    if (!_authService.isSignedIn) {
      // Oturum yoksa alttan SnackBar uyarısı göster
      _showLoginRequiredSnackBar();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Dışarı tıklayarak kapatmayı engelle
      builder: (context) => SafeArea(
        // 🔧 ANDROID 15 FIX: Dialog safe area padding
        child: WillPopScope(
          onWillPop: () async {
            // Güçlü klavye kapatma - geri tuşu
            FocusManager.instance.primaryFocus?.unfocus();
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            return true;
          },
          child: AlertDialog(
          title: const Text('Reklamları Kaldır'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bu hesap için ömür boyu tüm reklamları kaldır'),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Güçlü klavye kapatma
                FocusManager.instance.primaryFocus?.unfocus();
                SystemChannels.textInput.invokeMethod('TextInput.hide');
                Navigator.of(context).pop();
                // Çoklu kontrol
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                });
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Uygulama içi işlem flag'ini set et - reklam engellemek için
                AdMobService().setInAppActionFlag('satın_alma');
                
                try {
                  // Güçlü klavye kapatma
                  FocusManager.instance.primaryFocus?.unfocus();
                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                  Navigator.of(context).pop();
                  // Çoklu kontrol
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                  });
                  await _purchaseService.buyRemoveAds();
                  
                  // Satın alma işlemi tamamlandıktan 1 dakika sonra flag'i temizle
                  Future.delayed(const Duration(minutes: 1), () {
                    AdMobService().clearInAppActionFlag();
                    debugPrint('🔓 Satın alma işlemi sonrası 1 dakika flag temizlendi');
                  });
                  
                } catch (e) {
                  // Hata durumunda flag'i temizle
                  AdMobService().clearInAppActionFlag();
                  rethrow;
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
              ),
              child: Text(_purchaseService.removeAdsPrice),
            ),
          ],
          ),
        ),
      ),
    );
  }




  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Color(0xFF007AFF)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // İnternet bağlantısını kontrol et
  Future<bool> _checkInternetConnection() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('❌ [PROFILE] İnternet kontrol hatası: $e');
      return false;
    }
  }

  // Sade internet uyarısı göster
  void _showInternetRequiredDialog([String? message]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İnternet Gerekli'),
        content: Text(message ?? 'Bu işlem için internet bağlantısı gereklidir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Kullanıcı adı düzenleme ikonuna tıklandığında internet kontrolü
  Future<void> _onUsernameEditTap(bool isDarkMode, String currentUsername) async {
    // İnternet kontrolü
    bool hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      _showInternetRequiredDialog('Kullanıcı adı değiştirmek için internet bağlantısı gereklidir.');
      return;
    }
    
    // İnternet varsa dialog'u aç
    _showUsernameEditDialog(isDarkMode, currentUsername);
  }
  
  // Kullanıcı adı düzenleme dialogu
  void _showUsernameEditDialog(bool isDarkMode, String currentUsername) {
    final TextEditingController usernameController = TextEditingController();
    String? errorText;
    bool isLoading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Kullanıcı Adı Değiştir'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mevcut: $currentUsername',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: usernameController,
                    maxLength: 15,
                    onChanged: (value) {
                      // Otomatik formatlama
                      final processed = value
                          .toLowerCase()
                          .replaceAll(' ', '')
                          .replaceAll(RegExp(r'[^a-z0-9çğıöşü]'), '');
                      
                      if (processed != value) {
                        usernameController.value = usernameController.value.copyWith(
                          text: processed,
                          selection: TextSelection.collapsed(offset: processed.length),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Yeni Kullanıcı Adı',
                      hintText: 'kullaniciadi123 (küçük harf, boşluksuz)',
                      prefixIcon: const Icon(Icons.person),
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• En az 3 karakter\n• Sadece küçük harf, rakam ve Türkçe karakterler',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'İptal',
                    style: TextStyle(color: isDarkMode ? Colors.grey : Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final newUsername = usernameController.text.trim();
                    
                    if (newUsername.isEmpty || newUsername.length < 3) {
                      setDialogState(() {
                        errorText = 'Kullanıcı adı en az 3 karakter olmalı';
                      });
                      return;
                    }
                    
                    if (!RegExp(r'^[a-z0-9çğıöşü]+$').hasMatch(newUsername)) {
                      setDialogState(() {
                        errorText = 'Sadece küçük harf, rakam ve Türkçe karakterler';
                      });
                      return;
                    }
                    
                    setDialogState(() {
                      isLoading = true;
                      errorText = null;
                    });
                    
                    // Kullanıcı adını güncelle
                    final success = await _authService.updateUsername(newUsername);
                    
                    if (success) {
                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Kullanıcı adınız "$newUsername" olarak güncellendi!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {}); // UI'ı güncelle
                      }
                    } else {
                      setDialogState(() {
                        errorText = 'Bu kullanıcı adı kullanılamıyor veya zaten alınmış';
                        isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Değiştir'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}