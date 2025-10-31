import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/user_color_helper.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../services/community_chat_service.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../models/chat_message.dart';

class ModernTelegramChatScreen extends StatefulWidget {
  final double bottomPadding;
  final double topPadding;

  const ModernTelegramChatScreen({
    super.key,
    this.bottomPadding = 0,
    this.topPadding = 0,
  });

  @override
  State<ModernTelegramChatScreen> createState() => _ModernTelegramChatScreenState();
}

class _ModernTelegramChatScreenState extends State<ModernTelegramChatScreen> 
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  final CommunityChatService _chatService = CommunityChatService();
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isLoading = false;
  String? _currentUserId;
  String? _username;
  bool _hasPhoneNumber = false;
  late final Stream<List<ChatMessage>> _messagesStream;
  
  // Örnek mesajlar (resimde görülenler)
  final List<MockMessage> _mockMessages = [
    MockMessage(
      id: '1',
      userName: 'Sinan',
      message: 'Ablam yeri değil gibi😂😂',
      time: '13:49',
      userColor: const Color(0xFFFF5722),
      avatarText: 'S',
      replyTo: MockReply(userName: 'Fatma', message: 'Selamünaleykûm İzzet eker soru ba...'),
    ),
    MockMessage(
      id: '2',
      userName: 'Kader',
      message: 'Kur\'an da arapça ve bizim alan dilimiz arapça',
      time: '13:49',
      userColor: const Color(0xFF9C27B0),
      avatarText: 'K',
      isAdmin: true,
    ),
    MockMessage(
      id: '3',
      userName: 'İlahiyatçı',
      message: 'Kürtçe sohbet mi edildi',
      time: '13:49',
      userColor: const Color(0xFF673AB7),
      avatarText: 'İ',
    ),
    MockMessage(
      id: '4',
      userName: 'Ayşe',
      message: 'Size ilahiyat okumuşsunuz ama iyi ve kötüyü ayırt edemiyorsunuz',
      time: '13:49',
      userColor: const Color(0xFF2196F3),
      avatarText: 'A',
      replyTo: MockReply(userName: 'Kader', message: 'İlahiyatçı olmuşsunuz arapça konu...'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messagesStream = _chatService.getMessages(limit: 100);
    _initializeUser();
    _updateOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateOnlineStatus(false);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

  void _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _hasPhoneNumber = user.phoneNumber != null;
      });
      
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (!_chatService.isUserLoggedIn()) {
      _showLoginDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _messageController.clear();
    
    final success = await _chatService.sendMessage(message);
    
    setState(() {
      _isLoading = false;
    });
    
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
      _messageController.text = message;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj gönderilemedi'),
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasUser = _chatService.isUserLoggedIn();
    
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0E1621) : const Color(0xFFFFFFFF),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Modern Telegram Header
            _buildModernHeader(isDarkMode),
            
            // Sabitlenen Mesaj - Modern Telegram Style
            _buildPinnedMessage(isDarkMode),
            
            // Mesaj listesi - Modern Telegram Background
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? const Color(0xFF0B1426)
                      : const Color(0xFFDBDDBB), // Telegram'ın açık yeşil tonları
                ),
                child: _buildModernMessagesList(isDarkMode),
              ),
            ),
            
            // Modern Input Area
            _buildModernMessageInput(isDarkMode, hasUser),
          ],
        ),
      ),
    );
  }

  // Modern Telegram Header
  Widget _buildModernHeader(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF17212B) : const Color(0xFF517DA2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Geri butonu
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
          
          // Grup bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'İlahiyat Grubu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('✅', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.volume_off_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      margin: const EdgeInsets.only(left: 3),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      margin: const EdgeInsets.only(left: 3),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'yazıyor...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          
          // Menü butonu
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              // Menü
            },
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  // Sabitlenen Mesaj - Modern Style
  Widget _buildPinnedMessage(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2C3A) : const Color(0xFFE3F2FD),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode 
                ? const Color(0xFF2A3942).withOpacity(0.2)
                : const Color(0xFFBBDEFB).withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.push_pin_rounded,
            color: isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sabitlenen Mesaj',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Arkadaşlar hafız arkadaşlar özellikle bir şey ric...',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? const Color(0xFFE9EDEF) : const Color(0xFF424242),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.close_rounded,
            color: isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF757575),
            size: 20,
          ),
        ],
      ),
    );
  }

  // Modern Mesaj Listesi
  Widget _buildModernMessagesList(bool isDarkMode) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: _mockMessages.length,
      itemBuilder: (context, index) {
        final message = _mockMessages[_mockMessages.length - 1 - index];
        return _buildModernMessageBubble(message, isDarkMode);
      },
    );
  }

  // Modern Mesaj Balonu
  Widget _buildModernMessageBubble(MockMessage message, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: message.userColor,
            ),
            margin: const EdgeInsets.only(right: 8, top: 4),
            child: Center(
              child: Text(
                message.avatarText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Mesaj balonu
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  // Kullanıcı adı
                  Row(
                    children: [
                      Text(
                        message.userName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: message.userColor,
                        ),
                      ),
                      if (message.isAdmin || message.userName == 'Kurucu') ...[
                        const SizedBox(width: 6),
                        Text(
                          message.userName == 'Kurucu' ? 'Kurucu' : 'Moderatör',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Reply (varsa)
                  if (message.replyTo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: const Color(0xFF4CAF50),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.replyTo!.userName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message.replyTo!.message,
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
                  Text(
                    message.message,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF000000),
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Zaman
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      message.time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Input Area
  Widget _buildModernMessageInput(bool isDarkMode, bool hasUser) {
    if (!hasUser) {
      return _buildLoginPrompt(isDarkMode);
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 56.0;
    
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: 8 + bottomPadding + navBarHeight,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF17212B) : const Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(
            color: isDarkMode 
                ? const Color(0xFF2A3942).withOpacity(0.3)
                : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Emoji butonu
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Icon(
              Icons.emoji_emotions_outlined,
              color: isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF757575),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Input alanı
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0E1621) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF2A3942) : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                ),
                decoration: InputDecoration(
                  hintText: 'Mesaj yazın',
                  hintStyle: TextStyle(
                    color: isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF999999),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Send/Attach/Mic butonları
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, child) {
              final hasText = value.text.trim().isNotEmpty;
              
              if (!hasText) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.attach_file,
                        color: isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF757575),
                        size: 24,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF757575),
                        size: 24,
                      ),
                    ),
                  ],
                );
              }
              
              return GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF517DA2),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Login prompt
  Widget _buildLoginPrompt(bool isDarkMode) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 56.0;
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + bottomPadding + navBarHeight,
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
          Icon(
            Icons.info_outline_rounded,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mesaj göndermek için giriş yapmalısınız',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Giriş ekranına yönlendir
            },
            child: const Text(
              'Giriş Yap',
              style: TextStyle(
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mock mesaj modeli
class MockMessage {
  final String id;
  final String userName;
  final String message;
  final String time;
  final Color userColor;
  final String avatarText;
  final bool isAdmin;
  final MockReply? replyTo;

  MockMessage({
    required this.id,
    required this.userName,
    required this.message,
    required this.time,
    required this.userColor,
    required this.avatarText,
    this.isAdmin = false,
    this.replyTo,
  });
}

// Mock reply modeli
class MockReply {
  final String userName;
  final String message;

  MockReply({
    required this.userName,
    required this.message,
  });
}
