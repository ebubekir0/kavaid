import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/message_tracking_service.dart';

class AdminConsoleScreen extends StatefulWidget {
  final double bottomPadding;
  final double topPadding;

  const AdminConsoleScreen({
    super.key,
    this.bottomPadding = 0,
    this.topPadding = 0,
  });

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MessageTrackingService _trackingService = MessageTrackingService();
  final TextEditingController _emailController = TextEditingController();
  
  // İstatistikler
  int _totalUsers = 0;
  int _usersWithUsername = 0;
  int _onlineUsers = 0;
  int _activeUsersWithUsername = 0;
  List<Map<String, dynamic>> _recentRegistrations = [];
  List<Map<String, dynamic>> _recentUsernameSelections = [];
  List<Map<String, dynamic>> _onlineUsersList = [];
  
  bool _chatEnabled = true;
  String _selectedTab = 'dashboard';
  late TabController _tabController;
  int _currentTabIndex = 0; // Mevcut sekme index'ini takip et

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // TabController listener ekle
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _currentTabIndex = _tabController.index;
      }
    });
    
    _startPeriodicUpdates();
    _loadStats();
    _loadChatStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _loadChatStatus() async {
    final enabled = await _adminService.isChatEnabled();
    if (mounted) setState(() => _chatEnabled = enabled);
  }

  void _startPeriodicUpdates() {
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        _loadStats(silent: true); // Silent güncelleme - UI'ı etkilemez
        _startPeriodicUpdates();
      }
    });
  }

  Future<void> _loadStats({bool silent = false}) async {
    if (!_adminService.isFounder()) return;

    // Manuel yenilemede loading indicator göster (overlay olarak)
    if (!silent && mounted) {
      // Loading overlay göster
      _showLoadingOverlay();
    }

    try {
      await Future.wait([
        _loadBasicStats(),
        _loadRecentRegistrations(),
        _loadRecentUsernameSelections(),
        _loadOnlineUsers(),
      ]);
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (!silent && mounted) {
        // Loading overlay'i kapat
        Navigator.of(context).pop();
      }
      // Her durumda data'yı güncelle
      if (mounted) setState(() {});
    }
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _loadBasicStats() async {
    // Tüm kullanıcıları çek
    final usersSnapshot = await _firestore.collection('users').get();
    final allUsers = usersSnapshot.docs;

    _totalUsers = allUsers.length;

    // Kullanıcı adı seçmiş olanları say
    _usersWithUsername = allUsers.where((doc) {
      final data = doc.data();
      final username = data['username'] as String?;
      return username != null && username.isNotEmpty;
    }).length;

    // Online kullanıcıları say (son 5 dakikada aktif)
    final now = DateTime.now();
    final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
    
    final onlineUsers = allUsers.where((doc) {
      final data = doc.data();
      final lastSeen = data['lastSeen'] as Timestamp?;
      return lastSeen != null && lastSeen.toDate().isAfter(fiveMinutesAgo);
    }).toList();

    _onlineUsers = onlineUsers.length;

    // Online + kullanıcı adı olan kullanıcıları say
    _activeUsersWithUsername = onlineUsers.where((doc) {
      final data = doc.data();
      final username = data['username'] as String?;
      return username != null && username.isNotEmpty;
    }).length;
  }

  Future<void> _loadRecentRegistrations() async {
    final usersSnapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    _recentRegistrations = usersSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'email': data['email'] ?? 'Bilinmiyor',
        'createdAt': data['createdAt'] as Timestamp?,
        'username': data['username'] ?? 'Yok',
        'photoUrl': data['photoUrl'],
      };
    }).toList();
  }

  Future<void> _loadRecentUsernameSelections() async {
    try {
      // Önce username'i null olmayan kullanıcıları al
      final usersSnapshot = await _firestore
          .collection('users')
          .where('username', isNull: false)
          .get();

      // Client-side'da sırala ve filtrele
      final usersList = usersSnapshot.docs
          .where((doc) {
            final data = doc.data();
            final username = data['username'] as String?;
            return username != null && username.trim().isNotEmpty;
          })
          .map((doc) {
            final data = doc.data();
            return {
              'uid': doc.id,
              'username': data['username'] ?? 'Yok',
              'usernameSetAt': data['usernameSetAt'] as Timestamp?,
              'email': data['email'] ?? 'Bilinmiyor',
              'photoUrl': data['photoUrl'],
              'createdAt': data['createdAt'] as Timestamp?,
            };
          })
          .toList();

      // usernameSetAt varsa ona göre sırala, yoksa createdAt'e göre
      usersList.sort((a, b) {
        final aTime = a['usernameSetAt'] as Timestamp? ?? a['createdAt'] as Timestamp?;
        final bTime = b['usernameSetAt'] as Timestamp? ?? b['createdAt'] as Timestamp?;
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        return bTime.compareTo(aTime); // Descending order
      });

      // İlk 20'sini al
      _recentUsernameSelections = usersList.take(20).toList();
      
      debugPrint('✅ Username selections yüklendi: ${_recentUsernameSelections.length} kullanıcı');
      
    } catch (e) {
      debugPrint('❌ Username selections yüklenemedi: $e');
      _recentUsernameSelections = [];
    }
  }

  Future<void> _loadOnlineUsers() async {
    final now = DateTime.now();
    final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
    
    final usersSnapshot = await _firestore
        .collection('users')
        .where('lastSeen', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
        .orderBy('lastSeen', descending: true)
        .get();

    _onlineUsersList = usersSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'username': data['username'] ?? 'Kullanıcı adı yok',
        'email': data['email'] ?? 'Bilinmiyor',
        'lastSeen': data['lastSeen'] as Timestamp?,
        'photoUrl': data['photoUrl'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Kurucu kontrolü - sadece ebubekir@gmail.com
    if (!_adminService.isFounder()) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0B141A) : Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.security,
                    size: 60,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Kurucu Paneli',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bu alan sadece kuruca özeldir\n(ebubekir@gmail.com)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mevcut hesap: ${FirebaseAuth.instance.currentUser?.email ?? "Giriş yapılmamış"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0B141A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('🏛️ Kurucu Dashboard'),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStats,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2196F3),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2196F3),
              isScrollable: true,
              tabs: const [
                Tab(text: '📈 İstatistikler'),
                Tab(text: '👥 Kullanıcılar'),
                Tab(text: '🟢 Online'),
                Tab(text: '🛡️ Yönetim'),
                Tab(text: '🔧 Ayarlar'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralStats(isDarkMode),
                _buildUsersTab(isDarkMode),
                _buildOnlineTab(isDarkMode),
                _buildModerators(isDarkMode),
                _buildSettings(isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // İstatistikler sekmesi
  Widget _buildGeneralStats(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // İstatistik kartları
          Row(
            children: [
              Expanded(child: _buildStatCard(
                title: 'Toplam Kullanıcı', 
                value: _totalUsers.toString(),
                icon: Icons.people,
                color: Colors.blue,
                isDarkMode: isDarkMode,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                title: 'Kullanıcı Adı Seçen', 
                value: _usersWithUsername.toString(),
                icon: Icons.badge,
                color: Colors.green,
                isDarkMode: isDarkMode,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                title: 'Online Şimdi', 
                value: _onlineUsers.toString(),
                icon: Icons.circle,
                color: Colors.orange,
                isDarkMode: isDarkMode,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                title: 'Aktif + Kullanıcı Adı', 
                value: _activeUsersWithUsername.toString(),
                icon: Icons.verified_user,
                color: Colors.purple,
                isDarkMode: isDarkMode,
              )),
            ],
          ),
          const SizedBox(height: 24),

          // Yüzdeler
          _buildPercentageCard(isDarkMode),
        ],
      ),
    );
  }

  // Kullanıcılar sekmesi
  Widget _buildUsersTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Son kullanıcı adı seçenler (ÜSTTE)
          _buildSectionTitle('🏷️ En Son Kullanıcı Adı Seçenler', isDarkMode),
          _buildUserList(_recentUsernameSelections, showUsername: true, isDarkMode: isDarkMode),
          
          const SizedBox(height: 24),
          
          // Son kayıtlar (ALTTA)
          _buildSectionTitle('🆕 En Son Kayıt Olanlar', isDarkMode),
          _buildUserList(_recentRegistrations, showEmail: true, isDarkMode: isDarkMode),
        ],
      ),
    );
  }

  // Online sekmesi
  Widget _buildOnlineTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🟢 Şu Anda Online Olanlar', isDarkMode),
          const SizedBox(height: 8),
          Text(
            'Son 5 dakikada aktif olan kullanıcılar',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildOnlineUsersList(isDarkMode),
        ],
      ),
    );
  }

  // Mesajlar sekmesi
  Widget _buildMessagesTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('📨 Mesaj Okuma İstatistikleri', isDarkMode),
          const SizedBox(height: 8),
          Text(
            'Gönderdiğiniz mesajların kaç kişi tarafından okunduğu',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildMessageReadStats(isDarkMode),
        ],
      ),
    );
  }

  // Dashboard'u oluşturab
  Widget _buildDashboard(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İstatistik kartları
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Toplam Kullanıcı',
                  value: _totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Online Kullanıcı',
                  value: _onlineUsers.toString(),
                  icon: Icons.circle,
                  color: Colors.green,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Chat durumu
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.chat,
                      color: _chatEnabled ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chat Durumu',
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
                  _chatEnabled ? 'Chat aktif ve kullanıcılar mesaj gönderebiliyor' : 'Chat kapalı - kullanıcılar mesaj gönderemiyor',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toggleChat,
                    icon: Icon(_chatEnabled ? Icons.pause : Icons.play_arrow),
                    label: Text(_chatEnabled ? 'Chat\'i Durdur' : 'Chat\'i Başlat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _chatEnabled ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // İstatistik kartı
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Moderatörler tab
  Widget _buildModerators(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Moderatör ekleme
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Moderatör Yönetimi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Adresi',
                    hintText: 'ornek@gmail.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _assignModerator,
                        icon: const Icon(Icons.add),
                        label: const Text('Moderatör Ata'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _removeModerator,
                        icon: const Icon(Icons.remove),
                        label: const Text('Moderatör Kaldır'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Moderatör listesi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people, color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Aktif Moderatörler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _adminService.getModerators(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final moderators = snapshot.data!.docs;
                    
                    if (moderators.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Henüz moderatör bulunmuyor',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: moderators.length,
                      itemBuilder: (context, index) {
                        final mod = moderators[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                (mod['username'] ?? 'M')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(mod['username'] ?? 'Moderatör'),
                            subtitle: Text(mod['email'] ?? ''),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey[300]!, width: 0.5),
                              ),
                              child: const Text(
                                'Moderatör',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Loglar tab
  Widget _buildLogs(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Colors.purple, size: 24),
              SizedBox(width: 8),
              Text(
                'Moderasyon Logları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _adminService.getModerationLogs(limit: 50),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final logs = snapshot.data!.docs;
                
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Henüz moderasyon logu bulunmuyor',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data() as Map<String, dynamic>;
                    final timestamp = log['timestamp'] as Timestamp?;
                    final action = log['action'] ?? '';
                    final moderatorUsername = log['moderatorUsername'] ?? 'Bilinmiyor';
                    final targetUsername = log['targetUsername'] ?? 'Bilinmiyor';
                    
                    IconData actionIcon;
                    Color actionColor;
                    String actionText;
                    
                    switch (action) {
                      case 'delete_message':
                        actionIcon = Icons.delete;
                        actionColor = Colors.red;
                        actionText = 'Mesaj silindi';
                        break;
                      case 'mute':
                        actionIcon = Icons.volume_off;
                        actionColor = Colors.orange;
                        actionText = 'Kullanıcı susturuldu';
                        break;
                      case 'ban':
                        actionIcon = Icons.block;
                        actionColor = Colors.red;
                        actionText = 'Kullanıcı engellendi';
                        break;
                      case 'assign_moderator':
                        actionIcon = Icons.person_add;
                        actionColor = Colors.green;
                        actionText = 'Moderatör atandı';
                        break;
                      case 'remove_moderator':
                        actionIcon = Icons.person_remove;
                        actionColor = Colors.red;
                        actionText = 'Moderatör kaldırıldı';
                        break;
                      default:
                        actionIcon = Icons.info;
                        actionColor = Colors.blue;
                        actionText = action;
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: actionColor.withOpacity(0.1),
                          child: Icon(actionIcon, color: actionColor, size: 20),
                        ),
                        title: Text(actionText),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Moderatör: $moderatorUsername'),
                            Text('Hedef: $targetUsername'),
                            if (timestamp != null)
                              Text(
                                DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toDate()),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Ayarlar tab
  Widget _buildSettings(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.grey[700], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Sistem Ayarları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Chat kontrolü
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat Kontrolü',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                // Tüm mesajları silme butonu - sadece kurucu için
                if (_adminService.isFounder())
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _deleteAllMessages,
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Tüm Mesajları Sil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Kurucu bilgisi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kurucu Bilgileri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2196F3),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: const Text('Kurucu'),
                  subtitle: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Kurucu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Chat toggle
  Future<void> _toggleChat() async {
    try {
      await _adminService.setChatEnabled(!_chatEnabled);
      await _loadChatStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_chatEnabled 
              ? 'Chat başarıyla açıldı' 
              : 'Chat başarıyla kapatıldı'),
            backgroundColor: _chatEnabled ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tüm mesajları sil
  Future<void> _deleteAllMessages() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Mesajları Sil'),
        content: const Text('Tüm chat mesajlarını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteAllMessages();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tüm mesajlar başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mesajlar silinirken hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Moderatör atama
  Future<void> _assignModerator() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email adresi boş olamaz')),
      );
      return;
    }

    try {
      await _adminService.assignModerator(email);
      _emailController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moderatör başarıyla atandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Moderatör kaldırma
  Future<void> _removeModerator() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email adresi boş olamaz')),
      );
      return;
    }

    try {
      await _adminService.removeModerator(email);
      _emailController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moderatör başarıyla kaldırıldı'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Mesaj logları tab'ı
  Widget _buildMessageLogs(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mesaj Silme Logları',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _adminService.getMessageDeletionLogs(limit: 100),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('❌ Hata: ${snapshot.error}'),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('📝 Henüz mesaj silme logu yok'),
                  );
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final timestamp = data['timestamp'] as Timestamp?;
                    final deleterUsername = data['deleterUsername'] ?? 'Bilinmiyor';
                    final deleterRole = data['deleterRole'] ?? 'user';
                    final messageOwnerUsername = data['messageOwnerUsername'] ?? 'Bilinmiyor';
                    final messageContent = data['messageContent'] ?? '';
                    final isMultiple = data['isMultipleDelete'] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: deleterRole == 'founder' 
                              ? Colors.red 
                              : deleterRole == 'moderator'
                                  ? Colors.orange
                                  : Colors.blue,
                          child: Icon(
                            deleterRole == 'founder'
                                ? Icons.admin_panel_settings
                                : deleterRole == 'moderator'
                                    ? Icons.security
                                    : Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '$deleterUsername → $messageOwnerUsername',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageContent.isEmpty 
                                  ? '[Boş mesaj]' 
                                  : messageContent,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (isMultiple)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ÇOKLU SİLME',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  timestamp != null
                                      ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                                      : 'Tarih bilinmiyor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: deleterRole == 'founder' 
                                ? Colors.red[100] 
                                : deleterRole == 'moderator'
                                    ? Colors.orange[100]
                                    : Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            deleterRole == 'founder'
                                ? 'KURUCU'
                                : deleterRole == 'moderator'
                                    ? 'MODER'
                                    : 'USER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: deleterRole == 'founder'
                                  ? Colors.red[700]
                                  : deleterRole == 'moderator'
                                      ? Colors.orange[700]
                                      : Colors.blue[700],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Yardımcı metodlar

  Widget _buildPercentageCard(bool isDarkMode) {
    final usernamePercentage = _totalUsers > 0 
        ? ((_usersWithUsername / _totalUsers) * 100).toStringAsFixed(1)
        : '0.0';
    
    final onlinePercentage = _totalUsers > 0 
        ? ((_onlineUsers / _totalUsers) * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2832) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Yüzdeler',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '%$usernamePercentage',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Kullanıcı adı seçen', 
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '%$onlinePercentage',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Online olan',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, 
                       {bool showEmail = false, bool showUsername = false, required bool isDarkMode}) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            showUsername 
                ? 'Henüz kullanıcı adı seçen kullanıcı yok'
                : 'Henüz kayıt olan kullanıcı yok',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final timestamp = showUsername 
            ? user['usernameSetAt'] as Timestamp?
            : user['createdAt'] as Timestamp?;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E2832) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user['photoUrl'] != null 
                  ? NetworkImage(user['photoUrl'])
                  : null,
              child: user['photoUrl'] == null 
                  ? Text((showUsername ? user['username'] : user['email'])?.substring(0, 1).toUpperCase() ?? '?')
                  : null,
            ),
            title: Text(
              showUsername ? (user['username'] ?? 'Yok') : (user['email'] ?? 'Bilinmiyor'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showUsername && user['email'] != null) 
                  Text(user['email'] ?? 'Bilinmiyor'),
                if (timestamp != null)
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnlineUsersList(bool isDarkMode) {
    if (_onlineUsersList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Henüz online kullanıcı yok'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _onlineUsersList.length,
      itemBuilder: (context, index) {
        final user = _onlineUsersList[index];
        final lastSeen = user['lastSeen'] as Timestamp?;
        final username = user['username'] as String;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E2832) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundImage: user['photoUrl'] != null 
                      ? NetworkImage(user['photoUrl'])
                      : null,
                  child: user['photoUrl'] == null 
                      ? Text(username.substring(0, 1).toUpperCase())
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              username == 'Kullanıcı adı yok' ? '👤 ${user['email']}' : '🏷️ $username',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              lastSeen != null 
                  ? 'Son görülme: ${DateFormat('HH:mm').format(lastSeen.toDate())}'
                  : 'Bilinmiyor',
            ),
            trailing: const Icon(Icons.circle, color: Colors.green, size: 12),
          ),
        );
      },
    );
  }

  Widget _buildMessageReadStats(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('community_chat')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Henüz mesajınız bulunmuyor',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageDoc = messages[index];
            final data = messageDoc.data() as Map<String, dynamic>;
            final messageId = messageDoc.id;
            final message = data['message'] ?? '';
            final timestamp = data['timestamp'] as Timestamp?;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E2832) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.length > 50 ? '${message.substring(0, 50)}...' : message,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      // Okuma sayısı
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('message_reads')
                            .where('messageId', isEqualTo: messageId)
                            .snapshots(),
                        builder: (context, readSnapshot) {
                          final readCount = readSnapshot.hasData 
                              ? readSnapshot.data!.docs.length 
                              : 0;
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility, size: 16, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  '$readCount',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate()),
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
