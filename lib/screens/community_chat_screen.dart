import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import '../utils/user_color_helper.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
// Timer already imported with dart:async
import '../services/community_chat_service.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/message_tracking_service.dart';
import '../services/profile_sync_service.dart';
import '../models/chat_message.dart';
import 'dart:async' as async;
import '../services/saved_words_service.dart';

class CommunityChatScreen extends StatefulWidget {
  final double bottomPadding;
  final double topPadding;

  const CommunityChatScreen({
    super.key,
    this.bottomPadding = 0,
    this.topPadding = 0,
  });

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Widget state'ini koru
  final CommunityChatService _chatService = CommunityChatService();
  final AdminService _adminService = AdminService();
  final SavedWordsService _savedWordsService = SavedWordsService();
  final AuthService _authService = AuthService();
  final MessageTrackingService _trackingService = MessageTrackingService();
  final ProfileSyncService _profileSync = ProfileSyncService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _usernameController = TextEditingController();
  
  bool _isLoading = false;
  String? _currentUserId;
  String? _username;
  bool _hasPhoneNumber = false;
  final ValueNotifier<bool> _hasText = ValueNotifier<bool>(false);
  
  // Stream'i bir kez oluştur, her build'de yeniden oluşturma
  Stream<List<ChatMessage>>? _messagesStream;
  
  // Kurucu email cache (performans için)
  final Map<String, bool> _founderCache = {};
  
  // Moderatör cache (performans için)
  final Map<String, bool> _moderatorCache = {};
  
  // Yönetici mi (admin veya moderatör)
  bool _isStaff = false;
  
  // Engellenmiş mi
  bool _isBanned = false;
  
  // Real-time role listener
  StreamSubscription<DocumentSnapshot>? _roleSubscription;
  
  // Internet bağlantısı durumu
  bool _hasInternet = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Otomatik klavye açılmasını engellemek için
  bool _canRequestFocus = true;
  
  // Mesaj sınırları ve cooldown
  static const int maxMessageLength = 2000; // Maksimum mesaj uzunluğu
  static const int messageCooldownSeconds = 2; // 2 saniye bekleme
  DateTime? _lastMessageTime; // Son mesaj zamanı
  int _cooldownRemaining = 0; // Kalan cooldown süresi
  Timer? _cooldownTimer; // Cooldown timer
  
  // Çoklu seçim sistemi
  bool _isMultiSelectMode = false;
  Set<String> _selectedMessages = {};
  
  // Engelleme ve susturma sistemi
  bool _isUserBlocked = false;
  DateTime? _muteEndTime;
  StreamSubscription<DocumentSnapshot>? _userStatusSubscription;

  // Online durum güncelleme timer
  Timer? _onlineTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Stream'i initialize et (sadece null ise)
    _messagesStream ??= _chatService.getMessages(limit: 100);
    
    // Auth state değişikliklerini dinle (profil ekranından giriş için)
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUserId = user?.uid;
        });
        
        // Kullanıcı giriş yaptıysa username'i yükle
        if (user != null) {
          _loadUsername();
          _updateOnlineStatus(true);
          _startRoleListener(); // Rol dinleyicisini başlat
          _startUserStatusListener(); // Engelleme/susturma dinleyicisi
        } else {
          _updateOnlineStatus(false);
          _stopUserStatusListener();
        }
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentUser();
      _loadChatStatus(); // Chat durumunu yükle
      _startChatStatusListener(); // Real-time chat durumu dinleyicisi
      // Mevcut kullanıcı için user status listener başlat
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _startUserStatusListener();
        _startRoleListener();
      }
    });
    
    // Internet bağlantısını sürekli dinle
    _startConnectivityListener();

    _hasText.addListener(() {
      if (mounted) {
        setState(() {
          // Sadece UI güncelle
        });
      }
    });

    // Klavye açıldığında scroll'u en üste kaydır
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    // Anlık mesajları dinle
    _setupMessageListener();

    // Kullanıcının online durumunu güncelle
    _trackingService.updateUserLastSeen();

    // Periyodik olarak online durumu güncelle (her 2 dakikada bir)
    _startOnlineStatusUpdates();
  }

  void _setupMessageListener() {
    // Mesajların gerçek zamanlı güncellemelerini dinle (sadece null ise)
    _messagesStream ??= _chatService.getMessages(limit: 100);
  }

  void _startOnlineStatusUpdates() {
    _onlineTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _trackingService.updateUserLastSeen();
      }
    });
  }

  void _markMessagesAsRead(List<ChatMessage> messages) {
    for (final message in messages) {
      if (message.userId != _currentUserId) {
        _trackingService.markMessageAsRead(message.id);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Widget yeniden göründüğünde (profil ekranından dönüş) kontrol yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCurrentUser();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateOnlineStatus(false);
    _roleSubscription?.cancel(); // Role listener'ı iptal et
    _connectivitySubscription?.cancel(); // Connectivity listener'ı iptal et
    _userStatusSubscription?.cancel(); // User status listener'ı iptal et
    _cooldownTimer?.cancel(); // Cooldown timer'ı iptal et
    _onlineTimer?.cancel(); // Online timer'ı iptal et
    _scrollController.dispose();
    _messageController.dispose();
    _usernameController.dispose();
    _focusNode.dispose();
    _hasText.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused) {
      _updateOnlineStatus(false);
    }
  }

  void _updateOnlineStatus(bool isOnline) {
    if (_chatService.isUserLoggedIn()) {
      _chatService.updateOnlineStatus(isOnline);
    }
  }
  
  // Kullanıcı durumu dinleyicisi başlat (engelleme/susturma)
  void _startUserStatusListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    _userStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data()!;
        
        // Engelleme durumu kontrolü
        final isBlocked = data['isBlocked'] as bool? ?? false;
        
        // Susturma durumu kontrolü
        DateTime? muteEnd;
        final muteUntil = data['muteUntil'] as Timestamp?;
        if (muteUntil != null) {
          muteEnd = muteUntil.toDate();
          // Süre geçmişse susturma kaldır
          if (muteEnd.isBefore(DateTime.now())) {
            muteEnd = null;
          }
        }
        
        setState(() {
          _isUserBlocked = isBlocked;
          _muteEndTime = muteEnd;
        });
        
        // Engellenmişse uyarı göster
        if (isBlocked) {
          _showBlockedWarning();
        }
      }
    });
  }
  
  // Kullanıcı durumu dinleyicisini durdur
  void _stopUserStatusListener() {
    _userStatusSubscription?.cancel();
    _userStatusSubscription = null;
  }
  
  // Role listener başlat
  void _startRoleListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    _roleSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data()!;
        final role = data['role'] as String? ?? 'user';
        final isAdmin = currentUser.email?.toLowerCase() == 'ebubekir@gmail.com';
        
        setState(() {
          _isStaff = isAdmin || role == 'moderator' || role == 'founder';
        });
      }
    });
  }
  
  // Kullanıcının engellenip engellenmediğini kontrol et
  Future<bool> _checkIfUserBlocked() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      if (userDoc.exists) {
        final isBlocked = userDoc.data()?['isBlocked'] as bool? ?? false;
        return isBlocked;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Kullanıcı adını yükle
  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        final username = data['username'] as String?;
        
        // Kullanıcı adı her zaman olmalı (AuthService tarafından otomatik oluşturulur)
        if (username != null && username.isNotEmpty) {
          setState(() {
            _username = username;
          });
        } else {
          // Eğer bir şekilde kullanıcı adı yoksa, tekrar giriş yapılmış gibi kontrol et
          debugPrint('⚠️ [CHAT] Kullanıcı adı bulunamadı, otomatik oluşturulacak');
          // AuthService giriş işleminde otomatik olarak kullanıcı adı oluşturur
          
          // Yeniden yükle
          final updatedDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
              
          if (updatedDoc.exists && mounted) {
            final updatedUsername = updatedDoc.data()?['username'] as String?;
            setState(() {
              _username = updatedUsername;
            });
          }
        }
      } else {
        // Kullanıcı profili yoksa oluştur
        debugPrint('⚠️ [CHAT] Kullanıcı profili bulunamadı, otomatik kullanıcı adı oluşturulacak');
        
        // Otomatik kullanıcı adı oluştur
        final random = (100 + (DateTime.now().millisecondsSinceEpoch % 899900)).toString();
        final autoUsername = 'kullanıcı$random';
        
        // Firestore'a kaydet
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'username': autoUsername,
          'usernameChanged': false, // Henüz değiştirilmedi
          'autoGenerated': true, // Otomatik oluşturuldu
          'uid': user.uid,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        setState(() {
          _username = autoUsername;
        });
      }
    } catch (e) {
      debugPrint('❌ [CHAT] Kullanıcı adı yükleme hatası: $e');
    }
  }

  // Kullanıcı email'ini al (sadece kurucu için)
  Future<String?> _getUserEmail(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
          
      if (userDoc.exists) {
        return userDoc.data()?['email'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Susturma durumuna göre hint text
  String _getMutedHintText() {
    
    if (!_hasInternet) {
      return 'İnternet bağlantısı gerekli';
    }
    
    if (!_isChatEnabled && !_isFounder()) {
      return 'Topluluk durduruldu';
    }
    
    if (_isUserBlocked) {
      return '🚫 Engellendiniz - Mesaj gönderemezsiniz';
    }
    
    if (_muteEndTime != null && _muteEndTime!.isAfter(DateTime.now())) {
      final remaining = _muteEndTime!.difference(DateTime.now());
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes.remainder(60);
      return '🔇 ${hours}h ${minutes}m susturulmusunuz';
    }
    
    return 'Mesaj yazın';
  }

  // Chat durumu state variable'i eklenecek
  bool _isChatEnabled = true;
  
  // Kurucu kontrolü
  bool _isFounder() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email?.toLowerCase() == 'ebubekir@gmail.com';
  }

  // Belirtilen kullanıcı kurucu mu kontrol et (email bazında)
  Future<bool> _isFounderUserAsync(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final email = userDoc.data()?['email'] as String? ?? '';
        return email.toLowerCase() == 'ebubekir@gmail.com';
      }
    } catch (e) {
    }
    return false;
  }

  // Senkron kurucu kontrolü (cache kullanarak)
  bool _isFounderUser(String userId) {
    // Eğer mevcut kullanıcı ise direkt kontrol et
    if (userId == FirebaseAuth.instance.currentUser?.uid) {
      return _isFounder();
    }
    // Bilinen kurucu ID'si varsa
    return false; // Şimdilik false, async versiyonu kullanılacak
  }

  // Chat durumunu yükle
  Future<void> _loadChatStatus() async {
    try {
      final enabled = await _adminService.isChatEnabled();
      if (mounted) {
        setState(() {
          _isChatEnabled = enabled;
        });
      }
    } catch (e) {
    }
  }

  // Real-time chat durumu dinleyicisi başlat
  void _startChatStatusListener() {
    FirebaseFirestore.instance
        .collection('settings')
        .doc('chat')
        .snapshots()
        .listen((doc) {
      if (mounted) {
        final enabled = doc.exists ? (doc.data()?['enabled'] as bool? ?? true) : true;
        
        if (_isChatEnabled != enabled) {
          setState(() {
            _isChatEnabled = enabled;
          });
        }
      }
    });
  }

  // Engellenme uyarısı göster
  void _showBlockedWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('🚫 Engellendiniz'),
          ],
        ),
        content: const Text(
          'Topluluk kurallarını ihlal ettiğiniz için engellendiniz.\n\nMesajlara erişim izniniz bulunmamaktadır.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Ana ekrana dön
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _hasPhoneNumber = user.phoneNumber != null;
      });
      
      // Kullanıcı adını Firestore'dan al
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            _username = data?['username'] as String?;
          });
        }
      } catch (e) {
        print('Kullanıcı bilgisi alınamadı: $e');
      }
    }
  }
  
  // Topluluğa erişim kontrolü - sadece giriş kontrolü
  bool _canAccessCommunity() {
    final user = _authService.currentUser;
    return user != null; // Kullanıcı adı artık otomatik olarak atanacağı için sadece girişi kontrol et
  }
  
  String _getAccessMessage() {
    final user = _authService.currentUser;
    if (user == null) return 'Topluluğa katılmak için giriş yapın';
    return '';
  }
  
  IconData _getAccessIcon() {
    final user = _authService.currentUser;
    if (user == null) return Icons.login;
    return Icons.forum_rounded;
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Chat durumu kontrolü (kurucu için istisna)
    final chatEnabled = await _adminService.isChatEnabled();
    if (!chatEnabled && !_isFounder()) {
      // Sonuçsuz dön, uyarı verme
      return;
    }

    // Mesaj uzunluk kontrolü
    if (message.length > maxMessageLength) {
      _showError('⚠️ Mesaj çok uzun! Maksimum $maxMessageLength karakter olabilir.');
      return;
    }
    
    // Cooldown kontrolü (2 saniye) - sessizce engelle
    final now = DateTime.now();
    if (_lastMessageTime != null) {
      final difference = now.difference(_lastMessageTime!);
      if (difference.inSeconds < messageCooldownSeconds) {
        // Sessizce return, uyarı verme
        return;
      }
    }

    // Engelleme kontrolü
    if (_isUserBlocked) {
      _showError('🚫 Engellendiniz! Mesaj gönderemezsiniz.');
      return;
    }
    
    // Susturma kontrolü
    if (_muteEndTime != null && _muteEndTime!.isAfter(DateTime.now())) {
      final remaining = _muteEndTime!.difference(DateTime.now());
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes.remainder(60);
      _showError('🔇 ${hours}h ${minutes}m susturulmusunuz! Mesaj gönderemezsiniz.');
      return;
    }

    // İnternet bağlantısı kontrolü - MESAJLAŞMA AŞAMASI
    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) return;

    // Giriş kontrolü
    if (!_chatService.isUserLoggedIn()) {
      _showLoginDialog();
      return;
    }
    
    // Kullanıcı adı artık otomatik atandığı için kontrol gerekmiyor
    

    setState(() {
      _isLoading = true;
    });

    // Mesajı hemen temizle (optimistic UI)
    _messageController.clear();
    
    final success = await _chatService.sendMessage(message);
    
    // Mesaj başarıyla gönderildiyse son mesaj zamanını güncelle
    if (success) {
      _lastMessageTime = DateTime.now();
    }
    
    setState(() {
      _isLoading = false;
    });
    
    // Başarılı mesaj gönderiminde cooldown timer başlat
    if (success) {
      _startCooldownTimer();
    }
    
    // Mesaj gönderildikten sonra scroll'u en üste kaydır
    if (success && _scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    if (!success) {
      // Hata durumunda mesajı geri koy
      _messageController.text = message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mesaj gönderilemedi'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Tekrar Dene',
            textColor: Colors.white,
            onPressed: () => _sendMessage(),
          ),
        ),
      );
    } else {
      // Başarılı gönderim sonrası scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giriş Gerekli'),
        content: const Text('Mesaj göndermek için giriş yapmanız gerekiyor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showEmailAuthDialog(bool isDarkMode, {bool initialIsLogin = true}) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final confirmPassController = TextEditingController();
    final emailFocus = FocusNode();
    final passFocus = FocusNode();
    final confirmFocus = FocusNode();
    bool isLogin = initialIsLogin;
    bool isLoading = false;
    String? errorText;
    String? successText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        final keyboardHeight = viewInsets.bottom;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: keyboardHeight + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setSheetState(() => isLogin = !isLogin),
                            child: Text(isLogin ? 'Kayıt Ol' : 'Giriş Yap'),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isLogin) ...[
                        Text(
                          'Hesabınız yoksa önce kayıt olun',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (!isLogin) const SizedBox(height: 8),
                      // Başarı/Bilgi mesajı alanı
                      if (errorText == null && !isLogin)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Kayıt tamamlandıktan sonra giriş yapmanız gerekir.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      if (successText != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            successText!,
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (errorText != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            errorText!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      TextFormField(
                        controller: emailController,
                        focusNode: emailFocus,
                        decoration: const InputDecoration(labelText: 'E-posta'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Geçersiz e-posta adresi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passController,
                        focusNode: passFocus,
                        decoration: const InputDecoration(labelText: 'Şifre'),
                        obscureText: true,
                        validator: (v) => (v == null || v.isEmpty) ? 'Şifre gerekli' : null,
                      ),
                      const SizedBox(height: 8),
                      if (!isLogin)
                        TextFormField(
                          controller: confirmPassController,
                          focusNode: confirmFocus,
                          decoration: const InputDecoration(labelText: 'Şifre Tekrar'),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Şifre tekrarı gerekli';
                            if (v != passController.text) return 'Şifreler eşleşmiyor';
                            return null;
                          },
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            try {
                              setSheetState(() {
                                errorText = null;
                                successText = null;
                                isLoading = true;
                              });
                              if (isLogin) {
                                final user = await _authService.signInWithEmail(
                                  email: emailController.text.trim(),
                                  password: passController.text,
                                );
                                if (user != null) {
                                  // Kullanıcı bilgilerini güncelle
                                  if (mounted) {
                                    setState(() {
                                      _currentUserId = user.uid;
                                      _hasPhoneNumber = user.phoneNumber != null;
                                    });
                                    
                                    // Firestore'dan kullanıcı adını al
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .get()
                                        .then((doc) {
                                      if (doc.exists && mounted) {
                                        final data = doc.data();
                                        final username = data?['username'] as String?;
                                        setState(() {
                                          _username = username;
                                        });
                                        
                                        // Otomatik dialog açma - kullanıcı kendi seçecek
                                        // Artık otomatik açılmıyor, sadece UI'da buton görünüyor
                                      }
                                    });
                                  }
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                                  Navigator.pop(context);
                                }
                              } else {
                                final user = await _authService.signUpWithEmail(
                                  email: emailController.text.trim(),
                                  password: passController.text,
                                );
                                if (user != null) {
                                  // Otomatik giriş moduna geç ve alanları temizle
                                  setSheetState(() {
                                    successText = 'Kayıt tamamlandı. Lütfen giriş yapın.';
                                    isLogin = true;
                                    emailController.clear();
                                    passController.clear();
                                    confirmPassController.clear();
                                  });
                                  // Klavye açık kalsın ve e-posta alanına odaklanılsın
                                  Future.delayed(const Duration(milliseconds: 50), () {
                                    emailFocus.requestFocus();
                                  });
                                }
                              }
                            } catch (e) {
                              String message = 'İşlem başarısız. Lütfen tekrar deneyin.';
                              if (e is FirebaseAuthException) {
                                switch (e.code) {
                                  case 'invalid-email':
                                    message = 'Geçerli bir e‑posta adresi giriniz.'; break;
                                  case 'invalid-credential':
                                    message = 'E‑posta veya şifre hatalı. Lütfen kontrol ediniz.'; break;
                                  case 'user-not-found':
                                    message = 'Bu e‑posta ile kayıt bulunamadı.'; break;
                                  case 'wrong-password':
                                    message = 'Şifre hatalı.'; break;
                                  case 'email-already-in-use':
                                    message = 'Bu e‑posta zaten kayıtlı.'; break;
                                  case 'weak-password':
                                    message = 'Şifre çok zayıf. Daha güçlü bir şifre seçin.'; break;
                                  case 'operation-not-allowed':
                                    message = 'Bu giriş yöntemi proje için etkin değil.'; break;
                                  case 'network-request-failed':
                                    message = 'Ağ hatası. İnternet bağlantınızı kontrol edin.'; break;
                                  case 'too-many-requests':
                                    message = 'Çok fazla deneme yapıldı. Bir süre sonra tekrar deneyin.'; break;
                                  default:
                                    message = 'Hata: ${e.message ?? e.code}';
                                }
                              } else {
                                message = e.toString();
                              }
                              setSheetState(() { errorText = message; });
                            }
                            finally {
                              setSheetState(() { isLoading = false; });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                        ),
                      ),
                      // Klavyeyi ve sheet'i düzgün kapat
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            SystemChannels.textInput.invokeMethod('TextInput.hide');
                            Navigator.pop(context);
                          },
                          child: const Text('Kapat'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    // Türkçe ay isimleri
    final months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];

    if (difference.inDays > 7) {
      return '${timestamp.day} ${months[timestamp.month - 1]}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasUser = _chatService.isUserLoggedIn();
    
    // Her build'de güncel kullanıcı ID'sini al
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF1C1C1E) // Koyu gri (sistem teması)
          : const Color(0xFFF2F2F7), // Açık gri (sistem teması)
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // İnternet durumu bannerı
            if (!_hasInternet) _buildInternetWarningBanner(isDarkMode),
            
            // Çoklu seçim action bar
            if (_isMultiSelectMode) _buildMultiSelectActionBar(isDarkMode),
            
            // Mesaj listesi - Bejimsi arka plan
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDCDDBB), // #dcddbb rgba(220, 221, 187)
                ),
                child: _buildMessagesList(isDarkMode),
              ),
            ),
            // Mesaj gönderme alanı
            _buildMessageInput(isDarkMode, hasUser),
          ],
        ),
      ),
    );
  }

  // Modern Telegram Header
  Widget _buildHeader(bool isDarkMode) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: const EdgeInsets.all(8),
          ),
          
          // Grup profil resmi
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFF8B6914)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Boş alan
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  // Telegram tarzı mesaj listesi
  Widget _buildMessagesList(bool isDarkMode) {
    // Engellenen kullanıcı mesajlara erişemez
    if (_isUserBlocked) {
      return _buildBlockedState(isDarkMode);
    }
    
    // Giriş yapılmamışsa veya kullanıcı adı yoksa mesajları gösterme
    if (_currentUserId == null || _username == null) {
      return _buildEmptyState(isDarkMode);
    }
    
    // Çift kontrol: Engellenen kullanıcı için ek güvenlik
    return FutureBuilder<bool>(
      future: _checkIfUserBlocked(),
      builder: (context, blockedSnapshot) {
        if (blockedSnapshot.hasData && blockedSnapshot.data == true) {
          return _buildBlockedState(isDarkMode);
        }
        
        return StreamBuilder<List<ChatMessage>>(
            stream: _messagesStream!,
            builder: (context, snapshot) {
          
          // Hata durumu
          if (snapshot.hasError) {
            return _buildErrorState(isDarkMode);
          }

          // Veri varsa göster (waiting olsa bile)
          if (snapshot.hasData) {
            final messages = snapshot.data ?? [];
            
            if (messages.isEmpty) {
              return _buildEmptyState(isDarkMode);
            }

            return ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMyMessage = message.userId == _currentUserId;
                
                return _buildMessageBubble(message, isMyMessage, isDarkMode);
              },
            );
          }
          
          // İlk yüklemede loading göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(isDarkMode);
          }

          // Varsayılan: boş durum
          return _buildEmptyState(isDarkMode);
        });
      },
    );
  }

  // Telegram tarzı loading durumu
  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? const Color(0xFF3390EC) : const Color(0xFF3390EC),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mesajlar yükleniyor...',
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  // Hata durumu
  Widget _buildErrorState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bağlantı Hatası',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mesajlar yüklenemedi',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Telegram tarzı engellenmiş kullanıcı durumu
  Widget _buildBlockedState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 80,
            color: isDarkMode ? Colors.red[300] : Colors.red[600],
          ),
          const SizedBox(height: 24),
          Text(
            '🚫 Engellendiniz',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Topluluk kurallarını ihlal ettiğiniz için\nmesajlara erişim izniniz kaldırılmıştır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Geri Dön'),
          ),
        ],
      ),
    );
  }

  // Telegram tarzı boş durum
  Widget _buildEmptyState(bool isDarkMode) {
    // Giriş yapılmamışsa veya kullanıcı adı yoksa farklı mesaj göster
    if (_currentUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Giriş/Kayıt butonları (ortada)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? const Color(0xFF2C2C2E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDarkMode 
                      ? const Color(0xFF3A3A3C)
                      : const Color(0xFFE5E5EA),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFF007AFF),
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Topluluğa Katıl',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Topluluğa katılmak için kayıt olup giriş yapın',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Butonlar
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
                      onPressed: () async {
                        // İnternet bağlantısı kontrolü - GİRİŞ AŞAMASI
                        final hasInternet = await _checkInternetConnection();
                        if (hasInternet) {
                          _showEmailAuthSheet(isDarkMode, initialIsLogin: true);
                        }
                      },
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
                      onPressed: () async {
                        // İnternet bağlantısı kontrolü - KAYIT AŞAMASI
                        final hasInternet = await _checkInternetConnection();
                        if (hasInternet) {
                          _showEmailAuthSheet(isDarkMode, initialIsLogin: false);
                        }
                      },
                      child: const Text('Kayıt Ol'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Kullanıcı adı artık otomatik atanacağı için bu kontrol gerekmiyor
    
    // Normal boş durum (mesaj yok)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 80,
            color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFFC7C7CC),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz mesaj yok',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : const Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk mesajı gönderin',
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Modern Telegram mesaj bubble
  Widget _buildMessageBubble(ChatMessage message, bool isMyMessage, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar diğer mesajlarda (sol tarafta)
          if (!isMyMessage) ...[
            Container(
              margin: const EdgeInsets.only(right: 4, top: 2),
              child: _buildAvatar(message),
            ),
          ],
          
          // Mesaj balonu - Telegram tarzı
          Flexible(
            child: GestureDetector(
              // Long press davranışı - kendi mesajında silme, diğerlerinde çoklu seçim
              onLongPress: () async {
                // Klavyenin açılmasını engelle
                _focusNode.unfocus();
                
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                
                // Kendi mesajıysa silme menüsü göster
                if (message.userId == currentUserId) {
                  _showDeleteMenu(message);
                  return;
                }
                
                // Diğerleri için çoklu seçim yetki kontrolü
                final canSelect = await _canSelectMessageAsync(message);
                if (canSelect) {
                  _toggleMultiSelectMode(message);
                }
              },
              onTap: _isMultiSelectMode ? () async {
                // Çoklu seçim modunda klavyenin açılmasını engelle
                _focusNode.unfocus();
                
                final canSelect = await _canSelectMessageAsync(message);
                if (canSelect) {
                  _toggleMessageSelection(message);
                }
              } : null,
              child: IntrinsicWidth(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                    minWidth: 60, // Minimum genişlik
                  ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getBubbleColor(isMyMessage, isDarkMode),
                  border: _selectedMessages.contains(message.id) 
                      ? Border.all(color: const Color(0xFF007AFF), width: 2)
                      : null,
                  borderRadius: _getBubbleBorderRadius(isMyMessage),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kullanıcı adı ve yönetici badge - sadece diğer mesajlarda
                    if (!isMyMessage) ...[
                      Row(
                        children: [
                          Text(
                            message.userName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getUsernameColor(message.userId),
                            ),
                          ),
                          // Yeni rol badge sistemi
                          _buildUserRoleWidget(message),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // Reply (varsa) - Sinan ve Ayşe mesajları için
                    if (_hasReply(message)) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            left: BorderSide(
                              color: Color(0xFF4CAF50),
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getReplyUserName(message),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getReplyMessage(message),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Mesaj içeriği
                    if (message.isDeleted)
                      _buildDeletedMessage(isDarkMode)
                    else
                      _buildMessageContent(message, isMyMessage, isDarkMode),
                    
                    const SizedBox(height: 4),
                    
                    // Zaman - sağ alt köşede
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _buildMessageFooter(message, isMyMessage, isDarkMode),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
          
          // Kendi mesajlarda avatar yok
        ],
      ),
    );
  }

  // Modern Telegram avatar - profil resmi destekli (tıklanabilir)
  Widget _buildAvatar(ChatMessage message) {
    final baseColor = _getUsernameColor(message.userId);
    
    return GestureDetector(
      onTap: () => _showUserProfile(message),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: baseColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: message.userPhotoUrl?.isNotEmpty == true
              ? Image.network(
                  message.userPhotoUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high, // Yüksek kalite
                  cacheWidth: 120, // Daha yüksek cache kalitesi
                  cacheHeight: 120,
                  errorBuilder: (context, error, stackTrace) {
                    // Resim yüklenemezse harf göster
                    return Center(
                      child: Text(
                        message.userName.isNotEmpty ? message.userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Text(
                        message.userName.isNotEmpty ? message.userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    message.userName.isNotEmpty ? message.userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Kendi avatar'ım - profil resmi destekli
  Widget _buildMyAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    final firstLetter = _username?.isNotEmpty == true 
        ? _username![0].toUpperCase() 
        : (user?.email?.isNotEmpty == true 
            ? user!.email![0].toUpperCase() 
            : 'B');
            
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF517DA2), // Mavi renk kendi avatar için
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: user?.photoURL?.isNotEmpty == true
            ? Image.network(
                user!.photoURL!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high, // Yüksek kalite
                cacheWidth: 120, // Daha yüksek cache kalitesi
                cacheHeight: 120,
                errorBuilder: (context, error, stackTrace) {
                  // Resim yüklenemezse harf göster
                  return Center(
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
      ),
    );
  }

  // WhatsApp tarzı bubble rengi
  Color _getBubbleColor(bool isMyMessage, bool isDarkMode) {
    if (isMyMessage) {
      // Kendi mesajlar WhatsApp yeşili
      return isDarkMode ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6);
    } else {
      // Diğer mesajlar beyaz
      return isDarkMode ? const Color(0xFF182533) : const Color(0xFFFFFFFF);
    }
  }

  // Daha belirgin kuyruk - profil resmine işaret ediyor
  BorderRadius _getBubbleBorderRadius(bool isMyMessage) {
    if (isMyMessage) {
      // Kendi mesajlar - sağ üst köşe daha sivri kuyruk (profil resmine doğru)
      return const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(2), // Daha belirgin kuyruk
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      );
    } else {
      // Diğer mesajlar - sol üst köşe daha sivri kuyruk (profil resmine doğru)
      return const BorderRadius.only(
        topLeft: Radius.circular(2), // Daha belirgin kuyruk
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      );
    }
  }

  // Silinen mesaj
  Widget _buildDeletedMessage(bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.block_rounded,
          size: 16,
          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          'Mesaj silindi',
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Modern mesaj içeriği
  Widget _buildMessageContent(ChatMessage message, bool isMyMessage, bool isDarkMode) {
    Color textColor;
    if (isMyMessage) {
      // Kendi mesajlarda (WhatsApp yeşilinde siyah metin)
      textColor = isDarkMode ? Colors.white : const Color(0xFF000000);
    } else {
      // Diğer mesajlarda normal renk
      textColor = isDarkMode ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    }
    
    return Text(
      message.message,
      style: TextStyle(
        fontSize: 15,
        color: textColor,
        height: 1.3,
      ),
    );
  }

  // Mesaj footer
  Widget _buildMessageFooter(ChatMessage message, bool isMyMessage, bool isDarkMode) {
    Color timeColor;
    if (isMyMessage) {
      // Kendi mesajlarda WhatsApp yeşili için koyu gri
      timeColor = isDarkMode ? Colors.white.withOpacity(0.8) : const Color(0xFF666666);
    } else {
      // Diğer mesajlarda normal renk
      timeColor = isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF999999);
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(
            fontSize: 11,
            color: timeColor,
          ),
        ),
        
        // Kurucu mesajları için okuma sayısı
        if (_adminService.isFounder() && message.userId == _currentUserId)
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('message_reads')
                .where('messageId', isEqualTo: message.id)
                .snapshots(),
            builder: (context, readSnapshot) {
              final readCount = readSnapshot.hasData 
                  ? readSnapshot.data!.docs.length 
                  : 0;
              
              if (readCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(left: 6, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 12,
                        color: timeColor.withOpacity(0.8),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$readCount',
                        style: TextStyle(
                          fontSize: 10,
                          color: timeColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        
        // 3 nokta menüsü - yetki kontrolü ile
        FutureBuilder<bool>(
          future: _shouldShowMessageMenu(message, isMyMessage),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!) {
              return const SizedBox.shrink();
            }
            
            return GestureDetector(
              onTap: () => _showMessageActionMenu(message, isMyMessage),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 14,
                  color: timeColor,
                ),
              ),
            );
          },
        ),
        
        // İkinci 3 nokta menü kaldırıldı - çift menü sorununu çözüyor
      ],
    );
  }

  // Çeşitli ve güzel kullanıcı renkleri
  Color _getUsernameColor(String userId) {
    final colors = [
      const Color(0xFFE74C3C), // Kırmızı
      const Color(0xFF3498DB), // Mavi 
      const Color(0xFF2ECC71), // Yeşil
      const Color(0xFF9B59B6), // Mor
      const Color(0xFFF39C12), // Turuncu
      const Color(0xFF1ABC9C), // Teal
      const Color(0xFFE67E22), // Koyu turuncu
      const Color(0xFF34495E), // Koyu gri-mavi
      const Color(0xFFFF6B6B), // Açık kırmızı
      const Color(0xFF4ECDC4), // Açık teal
      const Color(0xFF45B7D1), // Açık mavi
      const Color(0xFF96CEB4), // Açık yeşil
      const Color(0xFFFECCA7), // Açık turuncu
      const Color(0xFFD63031), // Koyu kırmızı
      const Color(0xFF74B9FF), // Koyu mavi
      const Color(0xFF00B894), // Koyu yeşil
    ];
    
    final hash = userId.hashCode;
    return colors[hash.abs() % colors.length];
  }

  // Kullanıcı rolü widget'ı
  Widget _buildUserRoleWidget(ChatMessage message) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(message.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final role = userData?['role'] as String? ?? 'user';
        
        // Kurucu kontrolu iyileştirildi - email ile de kontrol
        final userEmail = userData?['email'] as String? ?? '';
        final isFounder = role == 'founder' || userEmail.toLowerCase() == 'ebubekir@gmail.com';
        
        String roleText;
        if (isFounder) {
          roleText = 'Kurucu';
        } else if (role == 'moderator') {
          roleText = 'Moderatör';
        } else {
          return const SizedBox.shrink();
        }
        
        final roleColor = Colors.grey[700]!; // Biraz daha koyu gri
        
        // Orijinal konum ve boyutta rol badge tasarımı
        return Container(
          margin: const EdgeInsets.only(left: 6, top: 1), // Orijinal konum
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), // Daha ince yükseklik
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            // Çerçeve kaldırıldı
          ),
          child: Text(
            roleText,
            style: TextStyle(
              fontSize: 11, // Daha da büyük yazı
              color: roleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
  
  // Yönetici kontrolü (geriye uyumluluk için)
  bool _isUserAdmin(String userId) {
    return false; // Artık _buildUserRoleWidget kullanılacak
  }

  // Reply var mı kontrolü  
  bool _hasReply(ChatMessage message) {
    // Sinan ve Ayşe'nin mesajlarında reply var
    return message.userName.toLowerCase() == 'sinan' || 
           message.userName.toLowerCase() == 'ayşe';
  }

  // Reply kullanıcı adı
  String _getReplyUserName(ChatMessage message) {
    if (message.userName.toLowerCase() == 'sinan') {
      return 'Fatma';
    } else if (message.userName.toLowerCase() == 'ayşe') {
      return 'Kader';
    }
    return '';
  }

  // Reply mesaj içeriği
  String _getReplyMessage(ChatMessage message) {
    if (message.userName.toLowerCase() == 'sinan') {
      return 'Selamünaleykûm İzzet eker soru ba...';
    } else if (message.userName.toLowerCase() == 'ayşe') {
      return 'İlahiyatçı olmuşsunuz arapça konu...';
    }
    return '';
  }

  // Mesaj menüsü gösterilmeli mi kontrolü (sadece başkalarının mesajları için)
  Future<bool> _shouldShowMessageMenu(ChatMessage message, bool isMyMessage) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;
    
    // Kendi mesajında 3 nokta olmasın
    if (isMyMessage) return false;
    
    // Yetki sahibi, yetkisi altındaki kullanıcıların mesajını yönetebilir
    return await _adminService.canManageUser(currentUserId, message.userId);
  }

  // Mesaj aksiyon menüsü göster
  void _showMessageActionMenu(ChatMessage message, bool isMyMessage) {
    _disableFocusTemporarily(); // Otomatik klavye açılmasını engelle
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2C2C2E) 
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _buildAvatar(message),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Mesaj silme seçeneği
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Mesajı Sil'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
              
              // Diğer kullanıcı mesajı için yönetim seçenekleri
              if (!isMyMessage) ...[
                ListTile(
                  leading: const Icon(Icons.volume_off_outlined, color: Colors.orange),
                  title: const Text('Kullanıcıyı Sustur'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMuteDialog(message.userId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block_outlined, color: Colors.red),
                  title: const Text('Kullanıcıyı Engelle'),
                  onTap: () {
                    Navigator.pop(context);
                    _showBanDialog(message.userId);
                  },
                ),
              ],
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Kendi mesaj silme menüsü (basılı tutma)
  void _showDeleteMenu(ChatMessage message) {
    _disableFocusTemporarily(); // Otomatik klavye açılmasını engelle
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2C2C2E) 
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _buildMyAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mesajınız',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sadece silme seçeneği
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Mesajı Sil'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Mesaj silme
  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _chatService.deleteMessage(message.id);
      
      // Klavyenin açılmasını engelle
      _focusNode.unfocus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj silinemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Susturma süresi seçim dialogu
  void _showMuteDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sustur'),
        content: const Text('Susturma süresini seçin:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _muteUser(userId, const Duration(minutes: 5));
            },
            child: const Text('5 Dakika'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _muteUser(userId, const Duration(hours: 1));
            },
            child: const Text('1 Saat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _muteUser(userId, const Duration(days: 1));
            },
            child: const Text('1 Gün'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  // Kullanıcı susturma
  Future<void> _muteUser(String userId, Duration duration) async {
    try {
      await _adminService.muteUser(userId, duration);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı ${duration.inMinutes} dakika susturuldu'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Susturma işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Engelleme onay dialogu
  void _showBanDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Engelle'),
        content: const Text('Bu kullanıcıyı kalıcı olarak engellemek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _banUser(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
  }

  // Kullanıcı engelleme
  Future<void> _banUser(String userId) async {
    try {
      await _adminService.banUser(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı engellendi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Engelleme işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Modern Telegram input alanı
  Widget _buildMessageInput(bool isDarkMode, bool hasUser) {
    // Eğer kullanıcı giriş yapmamışsa veya username seçmemmişse login prompt göster
    if (_currentUserId == null || _username == null) {
      return _buildLoginPrompt(isDarkMode);
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final navBarHeight = 56.0;
    
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: keyboardHeight > 0 ? 12 : 12 + bottomPadding + navBarHeight,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF17212B) : const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mesaj input alanı
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 48,
                maxHeight: 200, // Klavye için daha yüksek limit
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF232D3F) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                enabled: _hasInternet && (_isChatEnabled || _isFounder()), // İnternet ve chat kontrolü
                canRequestFocus: _canRequestFocus, // Otomatik focus kontrolü
                maxLines: null,
                minLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  color: _hasInternet 
                      ? (isDarkMode ? const Color(0xFFE9EDEF) : const Color(0xFF1C1E21))
                      : (isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF9CA3AF)),
                ),
                decoration: InputDecoration(
                  hintText: _getMutedHintText(),
                  hintStyle: TextStyle(
                    color: isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  
                  // Karakter sayacı
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _messageController,
                    builder: (context, value, child) {
                      final length = value.text.length;
                      final isOverLimit = length > maxMessageLength;
                      
                      if (length == 0) return const SizedBox.shrink();
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 12, top: 8),
                        child: Text(
                          '$length/$maxMessageLength',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverLimit 
                                ? Colors.red 
                                : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                            fontWeight: isOverLimit ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Güzel gönder butonu
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, child) {
              final hasText = value.text.trim().isNotEmpty;
              
              final canSend = hasText && _hasInternet && (_isChatEnabled || _isFounder()) && _cooldownRemaining <= 0;
              final isInCooldown = _cooldownRemaining > 0;
              final showButton = hasText && _hasInternet && (_isChatEnabled || _isFounder());
              
              return Tooltip(
                message: 'Cooldown: $_cooldownRemaining, CanSend: $canSend',
                child: GestureDetector(
                  onTap: canSend ? _sendMessage : null,
                  child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: showButton 
                        ? const LinearGradient(
                            colors: [Color(0xFF517DA2), Color(0xFF4A90E2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: showButton ? null : Colors.grey[400],
                    boxShadow: showButton ? [
                      BoxShadow(
                        color: const Color(0xFF517DA2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: isInCooldown && hasText
                        ? Text(
                            '$_cooldownRemaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: showButton 
                                ? Colors.white 
                                : Colors.grey[600],
                            size: 22,
                          ),
                  ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Login prompt - giriş yapılmamışsa hiçbir şey gösterme
  Widget _buildLoginPrompt(bool isDarkMode) {
    // Giriş yapılmamışsa hiç alan kaplamayız
    // Tüm aksiyonlar ortadaki card'larda
    return const SizedBox.shrink();
  }
  
  // Email ile giriş/kayıt
  Widget _buildEmailAuth(bool isDarkMode, double bottomPadding, double navBarHeight) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomPadding + navBarHeight,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF17212B) : const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: const Color(0xFF007AFF),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Topluluğa Katıl',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Mesajlaşmaya başlamak için giriş yapın veya hesap oluşturun',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          
          // Giriş/Kayıt butonları - profil ekranındaki ile aynı
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
              onPressed: () => _showEmailAuthSheet(isDarkMode, initialIsLogin: true),
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
              onPressed: () => _showEmailAuthSheet(isDarkMode, initialIsLogin: false),
              child: const Text('Kayıt Ol'),
            ),
          ),
        ],
      ),
    );
  }
  
  // Email auth sheet göster
  void _showEmailAuthSheet(bool isDarkMode, {bool initialIsLogin = true}) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final confirmPassController = TextEditingController();
    final emailFocus = FocusNode();
    final passFocus = FocusNode();
    final confirmFocus = FocusNode();
    bool isLogin = initialIsLogin;
    bool isLoading = false;
    String? errorText;
    String? successText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        final keyboardHeight = viewInsets.bottom;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: keyboardHeight + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setSheetState(() => isLogin = !isLogin),
                            child: Text(isLogin ? 'Kayıt Ol' : 'Giriş Yap'),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isLogin) ...[
                        Text(
                          'Hesabınız yoksa önce kayıt olun',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (!isLogin) const SizedBox(height: 8),
                      // Başarı/Bilgi mesajı alanı
                      if (errorText == null && !isLogin)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Kayıt tamamlandıktan sonra giriş yapmanız gerekir.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      if (successText != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            successText!,
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (errorText != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            errorText!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      TextFormField(
                        controller: emailController,
                        focusNode: emailFocus,
                        decoration: const InputDecoration(labelText: 'E-posta'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Geçersiz e-posta adresi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passController,
                        focusNode: passFocus,
                        decoration: const InputDecoration(labelText: 'Şifre'),
                        obscureText: true,
                        validator: (v) => (v == null || v.isEmpty) ? 'Şifre gerekli' : null,
                      ),
                      const SizedBox(height: 8),
                      if (!isLogin)
                        TextFormField(
                          controller: confirmPassController,
                          focusNode: confirmFocus,
                          decoration: const InputDecoration(labelText: 'Şifre Tekrar'),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Şifre tekrarı gerekli';
                            if (v != passController.text) return 'Şifreler eşleşmiyor';
                            return null;
                          },
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            try {
                              setSheetState(() {
                                errorText = null;
                                successText = null;
                                isLoading = true;
                              });
                              if (isLogin) {
                                final user = await _authService.signInWithEmail(
                                  email: emailController.text.trim(),
                                  password: passController.text,
                                );
                                if (user != null) {
                                  setState(() {
                                    _currentUserId = user.uid;
                                  });
                                  Navigator.pop(context);
                                  _checkUserProfile();
                                }
                              } else {
                                final user = await _authService.signUpWithEmail(
                                  email: emailController.text.trim(),
                                  password: passController.text,
                                );
                                if (user != null) {
                                  // Otomatik giriş moduna geç ve alanları temizle
                                  setSheetState(() {
                                    successText = 'Kayıt tamamlandı. Lütfen giriş yapın.';
                                    isLogin = true;
                                    emailController.clear();
                                    passController.clear();
                                    confirmPassController.clear();
                                  });
                                  // Klavye açık kalsın ve e-posta alanına odaklanılsın
                                  Future.delayed(const Duration(milliseconds: 50), () {
                                    emailFocus.requestFocus();
                                  });
                                }
                              }
                            } catch (e) {
                              String message = 'İşlem başarısız. Lütfen tekrar deneyin.';
                              if (e is FirebaseAuthException) {
                                switch (e.code) {
                                  case 'invalid-email':
                                    message = 'Geçerli bir e‑posta adresi giriniz.';
                                    break;
                                  case 'invalid-credential':
                                    message = 'E‑posta veya şifre hatalı. Lütfen kontrol ediniz.';
                                    break;
                                  case 'user-not-found':
                                    message = 'Bu e‑posta ile kayıt bulunamadı.';
                                    break;
                                  case 'wrong-password':
                                    message = 'Şifre hatalı.';
                                    break;
                                  case 'email-already-in-use':
                                    message = 'Bu e‑posta adresi zaten kullanılıyor.';
                                    break;
                                  case 'weak-password':
                                    message = 'Şifre çok zayıf. En az 6 karakter olmalı.';
                                    break;
                                  default:
                                    message = 'Hata: ${e.message}';
                                }
                              }
                              setSheetState(() {
                                errorText = message;
                                isLoading = false;
                              });
                            } finally {
                              setSheetState(() => isLoading = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  // Kullanıcı adı seçme ekranı
  Widget _buildUsernameSelection(bool isDarkMode, double bottomPadding, double navBarHeight) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomPadding + navBarHeight,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF17212B) : const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: const Color(0xFF007AFF),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Kullanıcı Adı Seç',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Topluluk içinde görünecek kullanıcı adınızı seçin.',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          
          // Kullanıcı adı input
          TextField(
            controller: _usernameController,
            onChanged: (value) {
              // 1. Küçük harfe çevir
              // 2. Boşlukları kaldır
              // 3. Sadece harf ve rakam kabul et
              String processed = value
                  .toLowerCase() // Küçük harfe çevir
                  .replaceAll(' ', '') // Boşlukları kaldır
                  .replaceAll(RegExp(r'[^a-z0-9çğıöşü]'), ''); // Sadece küçük harf, rakam ve Türkçe karakterler
              
              if (processed != value) {
                _usernameController.value = _usernameController.value.copyWith(
                  text: processed,
                  selection: TextSelection.collapsed(offset: processed.length),
                );
              }
            },
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'örn: ahmet123 (küçük harf, boşluksuz)',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF007AFF)),
              ),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(
                Icons.person,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Kaydet butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveUsername,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Kullanıcı Adını Kaydet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Kullanıcı adını kaydet (email için güncellendi)
  Future<void> _saveUsername() async {
    // Kullanıcı adını formatla: küçük harf + boşluksuz + temizle
    final username = _usernameController.text
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü]'), '')
        .trim();
        
    if (username.isEmpty) {
      _showError('Lütfen kullanıcı adı girin');
      return;
    }
    
    if (username.length < 3) {
      _showError('Kullanıcı adı en az 3 karakter olmalı');
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      if (_currentUserId != null) {
        // Kullanıcı adı benzersizliği kontrol et
        final existingUser = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .get();
        
        if (existingUser.docs.isNotEmpty) {
          setState(() => _isLoading = false);
          _showError('Bu kullanıcı adı zaten kullanılıyor');
          return;
        }
        
        // Firestore'da kullanıcı profili oluştur/güncelle
        await FirebaseFirestore.instance.collection('users').doc(_currentUserId).set({
          'username': username,
          'usernameSetAt': FieldValue.serverTimestamp(), // Bu satırı ekledik!
          'email': FirebaseAuth.instance.currentUser?.email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // merge: true ile mevcut verileri koru

        // MessageTrackingService'e de kaydet
        await _trackingService.recordUsernameSelection(username);

        // Eski mesajlardaki kullanıcı adını güncelle
        debugPrint('🔄 [CHAT] Eski mesajlardaki kullanıcı adı güncelleniyor...');
        await _profileSync.updateUsernameInMessages(_currentUserId!, username);
        debugPrint('✅ [CHAT] Eski mesajlardaki kullanıcı adı güncellendi');

        if (mounted) {
          setState(() {
            _username = username;
            _isLoading = false;
          });
          _usernameController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Kullanıcı adı kaydedilemedi: $e');
      }
    }
  }

  // Kullanıcı profilini kontrol et ve otomatik kullanıcı adı oluştur
  Future<void> _checkUserProfile() async {
    if (_currentUserId != null) {
      try {
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final username = data['username'] as String?;
          
          if (username != null && username.isNotEmpty) {
            if (mounted) {
              setState(() {
                _username = username;
                _hasPhoneNumber = true; // Email ile giriş yapıldı
              });
            }
          } else {
            // Kullanıcı adı yoksa otomatik oluştur
            await _loadUsername();
          }
        } else {
          // Kullanıcı profili yoksa oluştur ve otomatik kullanıcı adı ata
          await _loadUsername();
        }
      } catch (e) {
        debugPrint('❌ [CHAT] Kullanıcı profili kontrol hatası: $e');
        // Hata durumunda da otomatik kullanıcı adı oluşturmayı dene
        await _loadUsername();
      }
    }
  }

  // Mevcut kullanıcıyı kontrol et
  Future<void> _checkCurrentUser() async {
    try {
      
      // Firebase Auth'dan direkt kontrol et (daha güvenilir)
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser != null) {
        
        setState(() {
          _currentUserId = firebaseUser.uid;
        });
        
        // Kullanıcı profili var mı kontrol et
        await _checkUserProfile();
      } else {
        
        // Giriş yapılmamış
        if (mounted) {
          setState(() {
            _currentUserId = null;
            _username = null;
          });
        }
      }
    } catch (e) {
    }
  }

  // Kullanıcı adı seçme dialogu
  void _showUsernameDialog(bool isDarkMode) {
    final usernameController = TextEditingController();
    bool isLoading = false;
    String? errorText;
    String? successText;
    int characterCount = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Color(0xFF007AFF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kullanıcı Adı Seç',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Hata mesajı
              if (errorText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Başarı mesajı
              if (successText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          successText!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Kullanıcı adı input
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: errorText != null 
                        ? Colors.red.withOpacity(0.3)
                        : (isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA)),
                  ),
                ),
                child: TextField(
                  controller: usernameController,
                  autofocus: true,
                  maxLength: 15,
                  onChanged: (value) {
                    // 1. Küçük harfe çevir
                    // 2. Boşlukları kaldır
                    // 3. Sadece harf ve rakam kabul et
                    // 4. Max 15 karakter sınırla
                    String processed = value
                        .toLowerCase() // Küçük harfe çevir
                        .replaceAll(' ', '') // Boşlukları kaldır
                        .replaceAll(RegExp(r'[^a-z0-9çğıöşü]'), ''); // Sadece küçük harf, rakam ve Türkçe karakterler
                    
                    final limitedText = processed.length > 15 ? processed.substring(0, 15) : processed;
                    
                    if (limitedText != value) {
                      usernameController.value = usernameController.value.copyWith(
                        text: limitedText,
                        selection: TextSelection.collapsed(offset: limitedText.length),
                      );
                    }
                    
                    setDialogState(() {
                      characterCount = limitedText.length;
                      errorText = null; // Hata mesajını temizle
                    });
                  },
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'kullaniciadi123 (küçük harf, boşluksuz)',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.alternate_email_rounded,
                        color: Color(0xFF007AFF),
                        size: 16,
                      ),
                    ),
                    suffixIcon: characterCount > 0 
                        ? Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                '$characterCount/15',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: characterCount >= 13 
                                      ? Colors.orange 
                                      : (isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : null,
                    counterText: '', // Built-in counter'ı gizle
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                // Kullanıcı adını formatla: küçük harf + boşluksuz + temizle
                final username = usernameController.text
                    .toLowerCase()
                    .replaceAll(' ', '')
                    .replaceAll(RegExp(r'[^a-z0-9çğıöşü]'), '')
                    .trim();
                
                // İnternet bağlantısı kontrolü - KULLANICI ADI KAYDETME AŞAMASI
                final hasInternet = await _checkInternetConnection();
                if (!hasInternet) return;
                
                // Validasyonlar
                if (username.isEmpty) {
                  setDialogState(() {
                    errorText = 'Kullanıcı adı girin';
                  });
                  return;
                }
                
                if (username.length < 3) {
                  setDialogState(() {
                    errorText = 'En az 3 karakter';
                  });
                  return;
                }
                
                if (username.length > 15) {
                  setDialogState(() {
                    errorText = 'En fazla 15 karakter';
                  });
                  return;
                }
                
                // Harf ve rakam kontrolü (küçük harf formatında)
                if (!RegExp(r'^[a-z0-9çğıöşü]+$').hasMatch(username)) {
                  setDialogState(() {
                    errorText = 'Sadece küçük harf ve rakam kullanın';
                  });
                  return;
                }
                
                setDialogState(() {
                  isLoading = true;
                  errorText = null;
                });

                try {
                  if (_currentUserId != null) {
                    // Kullanıcı adı benzersizliği kontrol et
                    final existingUser = await FirebaseFirestore.instance
                        .collection('users')
                        .where('username', isEqualTo: username)
                        .get();
                    
                    if (existingUser.docs.isNotEmpty) {
                      setDialogState(() {
                        isLoading = false;
                        errorText = 'Bu ad alınmış, başkasını deneyin';
                      });
                      return;
                    }
                    
                    // Firestore'da kullanıcı profili oluştur/güncelle (KALİCI)
                    await FirebaseFirestore.instance.collection('users').doc(_currentUserId).set({
                      'username': username,
                      'email': FirebaseAuth.instance.currentUser?.email,
                      'createdAt': FieldValue.serverTimestamp(),
                      'lastSeen': FieldValue.serverTimestamp(),
                      'usernameSelectedFromCommunity': true, // Topluluk kısmından seçildi
                      'usernameCreatedAt': FieldValue.serverTimestamp(),
                    });


                    if (mounted) {
                      setState(() {
                        _username = username;
                      });
                      Navigator.pop(context);
                    }
                  }
                } catch (e) {
                  setDialogState(() {
                    isLoading = false;
                    errorText = 'Kullanıcı adı kaydedilemedi: $e';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // İnternet yokken input alanı
  Widget _buildNoInternetInput(bool isDarkMode) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 56.0;
    
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: 12 + bottomPadding + navBarHeight,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF17212B) : const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF232D3F).withOpacity(0.3) 
              : Colors.grey[200]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'İnternet bağlantısı gerekli',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kullanıcı profil dialog'unu göster
  void _showUserProfile(ChatMessage message) async {
    _disableFocusTemporarily(); // Otomatik klavye açılmasını engelle
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Kullanıcı rolünü al
    String userRole = 'user';
    try {
      userRole = await _adminService.getUserRole(message.userId);
    } catch (e) {
    }
    
    // Gerçek kayıt tarihini Firestore'dan al
    DateTime? registrationDate;
    String registrationText = 'Kayıt tarihi bilinmiyor';
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(message.userId)
          .get();
          
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final createdAt = data['createdAt'] as Timestamp?;
        
        if (createdAt != null) {
          registrationDate = createdAt.toDate();
          final now = DateTime.now();
          final difference = now.difference(registrationDate);
          
          // Ne kadar zaman önce hesapla
          if (difference.inDays > 0) {
            registrationText = '${difference.inDays} gün önce kayıt oldu';
          } else if (difference.inHours > 0) {
            registrationText = '${difference.inHours} saat önce kayıt oldu';
          } else if (difference.inMinutes > 0) {
            registrationText = '${difference.inMinutes} dakika önce kayıt oldu';
          } else {
            registrationText = 'Az önce kayıt oldu';
          }
        }
      }
    } catch (e) {
      registrationText = 'Kayıt tarihi alınamadı';
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Büyük avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  color: _getUsernameColor(message.userId),
                  boxShadow: [
                    BoxShadow(
                      color: _getUsernameColor(message.userId).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: message.userPhotoUrl?.isNotEmpty == true
                      ? Image.network(
                          message.userPhotoUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                message.userName.isNotEmpty 
                                    ? message.userName[0].toUpperCase() 
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            message.userName.isNotEmpty 
                                ? message.userName[0].toUpperCase() 
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Kullanıcı adı
              Text(
                message.userName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Yetki badge'i
              if (userRole != 'user') ...[
                _buildRoleBadge(userRole, isDarkMode),
                const SizedBox(height: 16),
              ],
              
              // Kurucu için email gösterimi
              if (_isStaff && (FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'ebubekir@gmail.com')) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<String?>(
                        future: _getUserEmail(message.userId),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Email yüklenemiyor...',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Kayıt tarihi bilgisi - kurucu, moderatör ve adminler için gizle
              FutureBuilder<bool>(
                future: _isFounderUserAsync(message.userId),
                builder: (context, snapshot) {
                  final isFounder = snapshot.data ?? false;
                  
                  // Kurucu, moderatör veya admin ise kayıt tarihini gösterme
                  if (isFounder || userRole == 'moderator' || userRole == 'admin') {
                    return const SizedBox.shrink(); // Yetkili roller için gösterme
                  }
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          registrationText,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Kapat butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kapat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Yetki badge'i için ayrı widget (sade gri tasarim)
  Widget _buildRoleBadge(String role, bool isDarkMode) {
    String roleText;
    
    switch (role) {
      case 'founder':
        roleText = 'Kurucu';
        break;
      case 'moderator':
        roleText = 'Moderatör';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        roleText,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Mesaj seçim yetkisi kontrolü (async - detaylı yetki sistemi)
  Future<bool> _canSelectMessageAsync(ChatMessage message) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;
    
    // Kendi mesajını her zaman seçebilir
    if (message.userId == currentUserId) return true;
    
    // Eğer staff değilse sadece kendi mesajını seçebilir
    if (!_isStaff) return false;
    
    // Buradan sonra staff kullanıcılar için kontrol
    return await _canStaffSelectMessage(message);
  }
  
  // Staff kullanıcılarının mesaj seçme yetkileri
  Future<bool> _canStaffSelectMessage(ChatMessage message) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      // Mevcut kullanıcının rolünü al
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      final currentUserRole = currentUserDoc.data()?['role'] as String? ?? 'user';
      final isFounder = currentUser.email?.toLowerCase() == 'ebubekir@gmail.com';
      
      // Kurucu ise herkesi seçebilir
      if (isFounder || currentUserRole == 'founder') {
        return true;
      }
      
      // Moderator ise sadece normal üyeleri seçebilir
      if (currentUserRole == 'moderator') {
        // Mesaj sahibinin rolünü ve email'ini kontrol et
        final messageOwnerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(message.userId)
            .get();
            
        final messageOwnerRole = messageOwnerDoc.data()?['role'] as String? ?? 'user';
        final messageOwnerEmail = messageOwnerDoc.data()?['email'] as String? ?? '';
        final isMessageFromFounder = messageOwnerEmail.toLowerCase() == 'ebubekir@gmail.com';
        
        // Kurucu mesajı ise seçemez (email veya role kontrolü)
        if (isMessageFromFounder || messageOwnerRole == 'founder') {
          return false;
        }
        
        // Sadece normal üye mesajlarını seçebilir
        return messageOwnerRole == 'user';
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Çoklu seçim sistemini başlat/durdur
  void _toggleMultiSelectMode(ChatMessage message) {
    setState(() {
      if (!_isMultiSelectMode) {
        // Çoklu seçim modunu başlat
        _isMultiSelectMode = true;
        _selectedMessages.clear();
        _selectedMessages.add(message.id);
      } else {
        // Çoklu seçim modunu kapat
        _isMultiSelectMode = false;
        _selectedMessages.clear();
      }
    });
  }
  
  // Mesaj seçimini aç/kapat
  void _toggleMessageSelection(ChatMessage message) {
    setState(() {
      if (_selectedMessages.contains(message.id)) {
        _selectedMessages.remove(message.id);
        
        // Hiçbir mesaj seçili değilse çoklu seçim modundan çık
        if (_selectedMessages.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedMessages.add(message.id);
      }
    });
  }
  
  // Seçili mesajları sil
  void _deleteSelectedMessages() async {
    if (_selectedMessages.isEmpty) return;
    
    final confirmed = await _showDeleteConfirmationDialog(
      'Seçili ${_selectedMessages.length} mesajı silmek istediğinizden emin misiniz?'
    );
    
    if (confirmed != true) return;
    
    try {
      // Admin kontrolü
      if (!_isStaff) {
        _showError('⚠️ Yalnızca yöneticiler çoklu mesaj silebilir!');
        return;
      }
      
      for (final messageId in _selectedMessages) {
        await _chatService.deleteMessage(messageId, isMultipleDelete: true);
      }
      
      // Klavyenin açılmasını engelle
      _focusNode.unfocus();
      
      
      // Seçim modundan çık
      setState(() {
        _isMultiSelectMode = false;
        _selectedMessages.clear();
      });
      
    } catch (e) {
      _showError('❌ Mesajlar silinirken hata oluştu: $e');
    }
  }
  
  // Tüm mesajları sil metodu kaldırıldı - sadece admin panelde mevcut
  
  // Cooldown timer başlat
  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownRemaining = messageCooldownSeconds;
    });
    
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _cooldownRemaining--;
      });
      
      if (_cooldownRemaining <= 0) {
        timer.cancel();
        _cooldownTimer = null;
      }
    });
  }
  
  // Silme onay dialogı
  Future<bool?> _showDeleteConfirmationDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Silme Onayı'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // Focus kontrolü - Otomatik klavye açılmasını engelle
  void _disableFocusTemporarily() {
    // Mevcut focus'u kaldır
    _focusNode.unfocus();
    
    // TextField'in focus almasını engelle
    setState(() {
      _canRequestFocus = false;
    });
    
    // Daha uzun süre bekle (1 saniye)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _canRequestFocus = true;
        });
      }
    });
  }
  
  // Modal kapatıldığında çağrılacak
  void _onModalClosed() {
    if (mounted) {
      _focusNode.unfocus();
      
      // Keyboard'u tamamen kapat
      FocusManager.instance.primaryFocus?.unfocus();
      
      // Sistem keyboard'unu gizle
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  // Çoklu seçim action bar
  Widget _buildMultiSelectActionBar(bool isDarkMode) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Vazgeç butonu
          IconButton(
            onPressed: () {
              setState(() {
                _isMultiSelectMode = false;
                _selectedMessages.clear();
              });
            },
            icon: const Icon(Icons.close_rounded),
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          
          const SizedBox(width: 8),
          
          // Seçili mesaj sayısı
          Text(
            '${_selectedMessages.length} mesaj seçili',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          
          const Spacer(),
          
          // Sil butonu
          IconButton(
            onPressed: _selectedMessages.isNotEmpty ? _deleteSelectedMessages : null,
            icon: const Icon(Icons.delete_rounded),
            color: _selectedMessages.isNotEmpty 
                ? Colors.red 
                : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
          ),
          
          // Tüm mesajları sil butonu kaldırıldı - sadece admin panelde
        ],
      ),
    );
  }

  // Internet uyarı bannerı
  Widget _buildInternetWarningBanner(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'İnternet bağlantısı yok',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              // Bağlantıyı tekrar kontrol et
              final results = await Connectivity().checkConnectivity();
              if (mounted) {
                final hasConnection = results.isNotEmpty && 
                                     !results.every((result) => result == ConnectivityResult.none);
                
                setState(() {
                  _hasInternet = hasConnection;
                });
                
                if (_hasInternet) {
                  _showError('✅ Bağlantı geri geldi!', isError: false);
                }
                // "Hala bağlantı yok" snackbar'ı kaldırıldı
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Yenile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Internet bağlantısını sürekli dinle
  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((resultList) {
      debugPrint('🌐 [CONNECTIVITY] Durum değişti: $resultList');
      
      if (mounted) {
        // List'te hiç bağlantı yoksa veya sadece none varsa internet yok
        final hasConnection = resultList.isNotEmpty && 
                             !resultList.every((result) => result == ConnectivityResult.none);
        
        final previousState = _hasInternet;
        
        setState(() {
          _hasInternet = hasConnection;
        });
        
        // Alttan çıkan uyarılar kaldırıldı - sadece banner gösterilecek
      }
    });
  }

  // Internet bağlantısı kontrol et
  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResults.isNotEmpty && 
                           !connectivityResults.every((result) => result == ConnectivityResult.none);
      
      if (!hasConnection) {
        _showError('🌐 İnternet bağlantısı gerekli. Lütfen bağlantınızı kontrol edin.');
        return false;
      }
      
      // Çift kontrol için ping testi
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        _showError('🌐 İnternet bağlantısında sorun var. Tekrar deneyin.');
        return false;
      }
      
      return false;
    } catch (e) {
      _showError('🌐 Bağlantı kontrolü yapılamıyor. İnternet bağlantınızı kontrol edin.');
      return false;
    }
  }

  // Kurallar listesi oluştur
  List<Widget> _buildRulesList(bool isDarkMode) {
    final rules = [
      {'icon': '🔤', 'text': 'Sadece harf ve rakam'},
      {'icon': '📏', 'text': 'En az 3 karakter'},
      {'icon': '📎', 'text': 'En fazla 15 karakter'},
      {'icon': '✨', 'text': 'Benzersiz olmalı'},
    ];
    
    return rules.map((rule) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(
              rule['icon']!,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                rule['text']!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Mesaj göster (hata veya başarı)
  void _showError(String message, {bool isError = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
    }
  }

  // Moderasyon menüsü kaldırıldı - ana 3 nokta menüde birleştirildi

  // Modern moderasyon bottom sheet
  Widget _buildModerationBottomSheet(ChatMessage message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Kullanıcı bilgisi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildAvatar(message),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Güncel Telegram mesaj menüsü
  void _showMessageMenu(ChatMessage message, bool isMyMessage) {
    _disableFocusTemporarily(); // Otomatik klavye açılmasını engelle
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF232E3C) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!message.isDeleted) ...[
                // Yanıtla
                _buildMenuOption(
                  icon: Icons.reply_rounded,
                  label: 'Yanıtla',
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    // Yanıtlama işlemi
                  },
                ),
                
                const Divider(height: 1, thickness: 0.5),
                
                // Kopyala
                _buildMenuOption(
                  icon: Icons.copy_rounded,
                  label: 'Kopyala',
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: message.message));
                  },
                ),
                
                // Sil (sadece kendi mesajları için)
                if (isMyMessage) ...[
                  const Divider(height: 1, thickness: 0.5),
                  _buildMenuOption(
                    icon: Icons.delete_rounded,
                    label: 'Sil',
                    isDarkMode: isDarkMode,
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteMessage(message);
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required bool isDarkMode,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive 
                  ? Colors.red 
                  : (isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF3390EC)),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDestructive 
                    ? Colors.red 
                    : (isDarkMode ? Colors.white : const Color(0xFF000000)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Eksik metodlar - basit implementasyonlar
  void _loadFounderCache() {
    // Kurucu cache yükleme
  }

  void _loadModeratorCache() {
    // Moderatör cache yükleme
  }

  void _checkStaffStatus() {
    // Yönetici kontrolü
  }

  void _listenToRoleChanges() {
    // Role değişikliklerini dinle
  }

  void _checkBanStatus() {
    // Engelleme kontrolü
  }

  void _checkUsernameStatus() {
    // Kullanıcı adı kontrolü
  }

  void _sendTestMessageIfNeeded() async {
    // Firestore'da hiç mesaj yoksa test mesajı gönder
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('community_chat')
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('🔍 [CHAT] Hiç mesaj yok, test mesajı gönderiliyor...');
        await _chatService.sendMessage('Hoş geldiniz! Bu topluluk sohbetinin ilk mesajıdır.');
      }
    } catch (e) {
      debugPrint('❌ [CHAT] Test mesajı gönderme hatası: $e');
    }
  }
}

// WhatsApp arka plan deseni
class WhatsAppBackgroundPainter extends CustomPainter {
  final bool isDarkMode;

  WhatsAppBackgroundPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // WhatsApp'ın klasik chat pattern deseni
    final patternColor = isDarkMode 
        ? const Color(0xFF0A0E13).withOpacity(0.2)
        : const Color(0xFFD4C5B0).withOpacity(0.3);
    
    paint.color = patternColor;

    // Küçük pattern desenler
    for (double x = 0; x < size.width; x += 50) {
      for (double y = 0; y < size.height; y += 50) {
        if ((x / 50 + y / 50) % 2 == 0) {
          final path = Path()
            ..moveTo(x + 20, y + 10)
            ..lineTo(x + 30, y + 10)
            ..lineTo(x + 30, y + 20)
            ..lineTo(x + 20, y + 20)
            ..close();
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(WhatsAppBackgroundPainter oldDelegate) {
    return isDarkMode != oldDelegate.isDarkMode;
  }
}
