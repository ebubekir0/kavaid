import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/user_color_helper.dart';
import 'community_chat_screen.dart';
import '../services/auth_service.dart';
import '../widgets/telegram_drawer.dart';
import 'package:intl/intl.dart';

class TelegramCommunityScreen extends StatefulWidget {
  final double bottomPadding;
  final double topPadding;

  const TelegramCommunityScreen({
    super.key,
    this.bottomPadding = 0,
    this.topPadding = 0,
  });

  @override
  State<TelegramCommunityScreen> createState() => _TelegramCommunityScreenState();
}

class _TelegramCommunityScreenState extends State<TelegramCommunityScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  // Örnek chat listesi data'sı
  final List<ChatListItem> _chatItems = [
    ChatListItem(
      id: 'general',
      title: 'Kavaid Topluluğu',
      subtitle: 'Arkadaşlar hafız arkadaşlar özellikle bir şey ric...',
      time: '14:32',
      unreadCount: 5,
      isOnline: true,
      avatarText: 'K',
      avatarColor: Color(0xFF517DA2),
      isPinned: true,
      isGroup: true,
      isMuted: false,
    ),
    ChatListItem(
      id: 'grammar',
      title: 'Gramer Soruları',
      subtitle: 'Ahmed: Bu kelimenin i\'rabı nasıl olacak?',
      time: '13:45',
      unreadCount: 2,
      isOnline: true,
      avatarText: 'G',
      avatarColor: Color(0xFF4CAF50),
      isPinned: false,
      isGroup: true,
      isMuted: false,
    ),
    ChatListItem(
      id: 'vocabulary',
      title: 'Kelime Tartışmaları',
      subtitle: 'Fatma: Bu kelime hangi babta?',
      time: '12:28',
      unreadCount: 0,
      isOnline: false,
      avatarText: 'K',
      avatarColor: Color(0xFF9C27B0),
      isPinned: false,
      isGroup: true,
      isMuted: true,
    ),
    ChatListItem(
      id: 'books',
      title: 'Kitap Tartışmaları',
      subtitle: 'Ali: 3. kitaptaki 15. ders çok güzeldi',
      time: '11:15',
      unreadCount: 0,
      isOnline: true,
      avatarText: 'K',
      avatarColor: Color(0xFFFF9800),
      isPinned: false,
      isGroup: true,
      isMuted: false,
    ),
    ChatListItem(
      id: 'announcements',
      title: 'Duyurular',
      subtitle: 'Yeni özellikler eklendi! Hemen keşfedin.',
      time: '10:00',
      unreadCount: 1,
      isOnline: false,
      avatarText: 'D',
      avatarColor: Color(0xFFE91E63),
      isPinned: true,
      isGroup: false,
      isMuted: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0E1621) : const Color(0xFFFFFFFF),
      drawer: const TelegramDrawer(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Telegram Header
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF17212B) : const Color(0xFF517DA2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: _buildHeader(isDarkMode),
            ),
            
            // Arama çubuğu (isteğe bağlı)
            if (_isSearching)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF17212B) : const Color(0xFFF5F5F5),
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode 
                          ? const Color(0xFF2A3942).withOpacity(0.3)
                          : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            
            // Story/Durum listesi
            _buildStoriesSection(isDarkMode),
            
            // Chat listesi
            Expanded(
              child: Container(
                color: isDarkMode ? const Color(0xFF0E1621) : const Color(0xFFFFFFFF),
                child: _buildChatList(isDarkMode),
              ),
            ),
          ],
        ),
      ),
      
      // Floating Action Button - Telegram tarzı
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni sohbet başlat
          _showNewChatDialog();
        },
        backgroundColor: const Color(0xFF517DA2),
        child: const Icon(
          Icons.edit,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // Telegram tarzı header
  Widget _buildHeader(bool isDarkMode) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Hamburger menu
          GestureDetector(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: Container(
              width: 24,
              height: 24,
              child: Icon(
                Icons.menu,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Başlık
          Expanded(
            child: Text(
              'Telegram',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Arama butonu
          IconButton(
            icon: Icon(
              _isSearching ? Icons.clear : Icons.search,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          
          // More options
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
    );
  }

  // Telegram tarzı story/durum listesi
  Widget _buildStoriesSection(bool isDarkMode) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0E1621) : const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode 
                ? const Color(0xFF2A3942).withOpacity(0.3)
                : const Color(0xFFE0E0E0).withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: 6, // Örnek story sayısı
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Durum Ekle" item'ı
            return _buildAddStoryItem(isDarkMode);
          } else {
            // Normal story item'ları
            return _buildStoryItem(index, isDarkMode);
          }
        },
      ),
    );
  }

  // "Durum Ekle" item'ı
  Widget _buildAddStoryItem(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.camera_alt,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 24,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF517DA2),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF0E1621) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Durum',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Normal story item'ı
  Widget _buildStoryItem(int index, bool isDarkMode) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF2196F3),
      const Color(0xFFE91E63),
    ];
    
    final names = [
      'Ahmed',
      'Fatma',
      'Ali',
      'Ayşe',
      'Mehmet',
    ];
    
    final color = colors[(index - 1) % colors.length];
    final name = names[(index - 1) % names.length];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () {
          // Story'yi aç
        },
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF517DA2), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
                child: Center(
                  child: Text(
                    name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chat listesi
  Widget _buildChatList(bool isDarkMode) {
    List<ChatListItem> filteredChats = _chatItems;
    
    if (_searchController.text.isNotEmpty) {
      filteredChats = _chatItems.where((chat) =>
        chat.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        chat.subtitle.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }
    
    // Pinned chats önce
    filteredChats.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });

    return ListView.builder(
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        return _buildChatListItem(chat, isDarkMode);
      },
    );
  }

  // Telegram tarzı chat list item
  Widget _buildChatListItem(ChatListItem chat, bool isDarkMode) {
    return InkWell(
      onTap: () {
        // Chat ekranına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CommunityChatScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkMode 
                  ? const Color(0xFF2A3942).withOpacity(0.3)
                  : const Color(0xFFE0E0E0).withOpacity(0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chat.avatarColor,
                  ),
                  child: Center(
                    child: Text(
                      chat.avatarText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                // Online indicator
                if (chat.isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4CAF50),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF0E1621) : Colors.white,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Chat bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Chat title
                      Expanded(
                        child: Row(
                          children: [
                            if (chat.isPinned)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.push_pin,
                                  size: 16,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            Flexible(
                              child: Text(
                                chat.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white : const Color(0xFF000000),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chat.isMuted)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.volume_off,
                                  size: 16,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Zaman
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 13,
                          color: chat.unreadCount > 0 
                              ? const Color(0xFF517DA2)
                              : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      // Son mesaj
                      Expanded(
                        child: Text(
                          chat.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Unread count
                      if (chat.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: chat.isMuted 
                                ? Colors.grey[500]
                                : const Color(0xFF517DA2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yeni sohbet dialog'u
  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              
              Text(
                'Yeni Sohbet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Seçenekler
              _buildNewChatOption(
                icon: Icons.group_add,
                title: 'Yeni Grup',
                subtitle: 'Grup sohbeti oluştur',
                onTap: () {
                  Navigator.pop(context);
                  // Grup oluşturma
                },
              ),
              
              _buildNewChatOption(
                icon: Icons.person_add,
                title: 'Kişi Ekle',
                subtitle: 'Yeni üye davet et',
                onTap: () {
                  Navigator.pop(context);
                  // Kişi ekleme
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Yeni sohbet seçeneği
  Widget _buildNewChatOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF517DA2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF517DA2),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Seçenekler menüsü
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              
              _buildMenuOption(
                icon: Icons.settings,
                title: 'Ayarlar',
                onTap: () {
                  Navigator.pop(context);
                  // Ayarlar
                },
              ),
              
              _buildMenuOption(
                icon: Icons.help_outline,
                title: 'Yardım',
                onTap: () {
                  Navigator.pop(context);
                  // Yardım
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Menü seçeneği
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chat list item modeli
class ChatListItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final String avatarText;
  final Color avatarColor;
  final bool isPinned;
  final bool isGroup;
  final bool isMuted;

  ChatListItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    required this.avatarText,
    required this.avatarColor,
    required this.isPinned,
    required this.isGroup,
    required this.isMuted,
  });
}
