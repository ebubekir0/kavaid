import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'dart:io';
import 'dart:async';
import '../services/language_service.dart';
import '../widgets/language_tile.dart';
import '../widgets/dictionary_language_tile.dart';
import '../widgets/tashkeel_tile.dart';
import 'package:kavaid/l10n/l10n.dart';

part 'profile_debug_tools.dart';

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
        EmailAuthSheet.show(context, initialIsLogin: true, onSuccess: () {
          if (mounted) {
            setState(() {});
            _checkUserRole();
            _listenToRoleChanges();
          }
        });
      }
    });
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
    
    debugPrint('🔍 [PROFILE] Yetki kontrolü: Email=$userEmail, UserId=$userId');
    
    // Kurucu mu? (Email kontrolü)
    if (userEmail != null && userEmail.toLowerCase() == 'ebubekir@gmail.com') {
      debugPrint('👑 [PROFILE] KURUCU tespit edildi');
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
        debugPrint('📄 [PROFILE] Firestore role: $role');
        
        if (role == 'moderator') {
          debugPrint('⭐ [PROFILE] MODERATÖR tespit edildi');
          setState(() => _userRole = 'moderator');
        } else {
          debugPrint('👤 [PROFILE] Normal kullanıcı');
          setState(() => _userRole = null);
        }
      } catch (e) {
        debugPrint('❌ [PROFILE] Firestore okuma hatası: $e');
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
        debugPrint('🔄 Profil yetkisi güncellendi: ${newRole ?? "NORMAL"}');
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
          SnackBar(
            content: Text(l10n.profilResmiGuncellendi),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [PROFILE] HATA: $e');
      debugPrint('📍 [PROFILE] Stack trace: $stackTrace');
      
      String errorMessage = l10n.birHataOlustu;
      
      if (e.toString().contains('object-not-found')) {
        errorMessage = l10n.firebaseStorageYapilandirilmamisLutfenFirebase;
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = l10n.izinHatasiStorageKurallariniKontrol;
      } else if (e.toString().contains('unauthorized')) {
        errorMessage = l10n.yetkilendirmeHatasiLutfenGirisYapin;
      } else if (e.toString().contains('network')) {
        errorMessage = l10n.internetBaglantisiHatasi;
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
              label: l10n.detay,
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.hataDetayi),
                    content: SingleChildScrollView(
                      child: Text(e.toString()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.tamam),
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
            title: Text(
              l10n.profil,
              style: const TextStyle(
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
                  margin: const EdgeInsetsDirectional.only(end: 16),
                  child: Container(
                    width: 50,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: widget.isDarkMode 
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.3),
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
                                  color: Colors.black.withValues(alpha: 0.2),
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
            padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, widget.bottomPadding),
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
                            final displayText = username ?? _authService.displayName ?? _authService.userEmail?.split('@')[0] ?? l10n.kullanici;
                            
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
                                      PositionedDirectional(
                                        end: 0,
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
                                                    ? const Color(0xFFFF6B35).withValues(alpha: 0.15)
                                                    : const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: _userRole == 'founder'
                                                      ? const Color(0xFFFF6B35).withValues(alpha: 0.3)
                                                      : const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                _userRole == 'founder' 
                                                    ? (l10n.kurucu) 
                                                    : (l10n.moderator),
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
                                                    ? Colors.grey[800]?.withValues(alpha: 0.5)
                                                    : Colors.grey[300]?.withValues(alpha: 0.5),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: isDarkMode 
                                                      ? Colors.grey[600]!
                                                      : Colors.grey[500]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                l10n.moderator,
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
                                        _authService.userEmail ?? l10n.emailYok,
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
                                        title: Text(l10n.cikisYapilsinMi),
                                        content: Text(l10n.oturumunuzKapatilacak),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(dCtx).pop(false),
                                            child: Text(l10n.iptal),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(dCtx).pop(true),
                                            child: Text(l10n.cikis),
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
                                  label: Text(l10n.cikis),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (_authService.isSignedIn && Provider.of<PurchaseManager>(context).isPremium)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: InkWell(
                              onTap: () async {
                                final url = Uri.parse("https://play.google.com/store/account/subscriptions");
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
                                          l10n.aboneligiYonet,
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
                                          SnackBar(content: Text(l10n.satinAlmalarKontrolEdiliyor), duration: Duration(seconds: 2)),
                                        );
                                        await Provider.of<PurchaseManager>(context, listen: false).restorePurchases();
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.restore, color: isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.geriYukle,
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
                      if (!_authService.isSignedIn) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.girisYapinVeyaKayitOlun,
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
                            onPressed: () => EmailAuthSheet.show(context, initialIsLogin: true, onSuccess: () {
                              if (mounted) {
                                setState(() {});
                                _checkUserRole();
                                _listenToRoleChanges();
                              }
                            }),
                            child: Text(l10n.girisYap),
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
                            onPressed: () => EmailAuthSheet.show(context, initialIsLogin: false, onSuccess: () {
                              if (mounted) {
                                setState(() {});
                                _checkUserRole();
                                _listenToRoleChanges();
                              }
                            }),
                            child: Text(l10n.kayitOl),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Reklam kaldırma önerisi veya durumu - Profil kısmının hemen altında
                // Premium / Abonelik Durumu Kartı - Arapça ve İngilizce için gizle
                if (!LanguageService().isEnglish && !LanguageService().isArabic)
                  Consumer<PurchaseManager>(
                    builder: (context, purchaseManager, _) {
                    if (purchaseManager.isPremium) {
                      // 1. Premium Üye - MAVİ KART
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007AFF).withValues(alpha: 0.3),
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
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.premiumUyesiniz,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    l10n.sinirsizIcerikReklamsizKullanim,
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
                                  begin: AlignmentDirectional.topStart,
                                  end: AlignmentDirectional.bottomEnd,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
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
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.premiumAGec,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          l10n.tumOzelliklereErisin,
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
                                begin: AlignmentDirectional.topStart,
                                end: AlignmentDirectional.bottomEnd,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF007AFF).withValues(alpha: 0.3),
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
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.reklamsizKullanim,
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
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF007AFF).withValues(alpha: 0.3),
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
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.premiumAGec,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      l10n.sinirsizIcerikReklamsizKullanim,
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
                  },
                ),
                
                const SizedBox(height: 12),
                
                

                // TEST: Debug butonları (sadece debug modda)
                if (!kReleaseMode) ..._buildDebugButtons(context),
                
                // İstek: Sade UI için bulut senkron butonlarını göstermiyoruz

                // Uygulama (arayüz) dili seçimi
                LanguageTile(isDarkMode: isDarkMode),
                const SizedBox(height: 12),

                // Sözlük (anlam) dili
                DictionaryLanguageTile(isDarkMode: isDarkMode),

                // Arapça–Arapça maddelerde hareke (yalnız Arapça anlam dilinde görünür)
                TashkeelTile(isDarkMode: isDarkMode),

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
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.05),
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
                          child: Icon(
                            Icons.share_rounded,
                            color: const Color(0xFF007AFF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.uygulamayiPaylas,
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
                              l10n.iletisim,
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
                                    'subject': l10n.kavaidUygulamasiHakkinda,
                                  },
                                );
                                if (await canLaunchUrl(emailUri)) {
                                  await launchUrl(emailUri);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
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
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.05),
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
                          child: Icon(
                            Icons.email_outlined,
                            color: const Color(0xFF007AFF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.iletisim,
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
                // Hesabımı Sil kartı (Apple Guideline 5.1.1(v) Uyumlu)
                if (_authService.isSignedIn) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showDeleteAccountConfirmation(context, isDarkMode),
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
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.05),
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
                              color: Colors.red.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.hesabimiSil,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (kDebugMode) ..._buildPurchaseTestTools(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(l10n.hesabimiSil, style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          l10n.hesabiniziVeHesabinizaBagliTum,
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.vazgec),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _authService.deleteAccount();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.hesabinizBasariylaSilindi),
                      backgroundColor: Colors.red,
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.hesapSilinemediEGuvenlikGeregi(e)),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
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
        subject: l10n.kavaidArapcaSozlukUygulamasi,
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
          SnackBar(
            content: Text(l10n.paylasimSirasindaBirHataOlustu),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        title: Text(l10n.internetGerekli),
        content: Text(message ?? l10n.buIslemIcinInternetBaglantisi),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.tamam),
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
              title: Text(l10n.kullaniciAdiDegistir),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mevcutCurrentusername(currentUsername),
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
                      labelText: l10n.yeniKullaniciAdi,
                      hintText: l10n.kullaniciadi123KucukHarfBosluksuz,
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
                    l10n.enAz3KarakterSadece,
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
                    l10n.iptal,
                    style: TextStyle(color: isDarkMode ? Colors.grey : Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final newUsername = usernameController.text.trim();
                    
                    if (newUsername.isEmpty || newUsername.length < 3) {
                      setDialogState(() {
                        errorText = l10n.kullaniciAdiEnAz3;
                      });
                      return;
                    }
                    
                    if (!RegExp(r'^[a-z0-9çğıöşü]+$').hasMatch(newUsername)) {
                      setDialogState(() {
                        errorText = l10n.sadeceKucukHarfRakamVe;
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
                      if (dialogContext.mounted && context.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.kullaniciAdinizNewusernameOlarakGuncellendi(newUsername)),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {}); // UI'ı güncelle
                      }
                    } else {
                      setDialogState(() {
                        errorText = l10n.buKullaniciAdiKullanilamiyorVeya;
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
                      : Text(l10n.degistir),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
