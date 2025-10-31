import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> 
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late TabController _tabController;
  bool _isLoading = true;
  
  // İstatistikler
  int _totalUsers = 0;
  int _usersWithUsername = 0;
  int _onlineUsers = 0;
  int _activeUsersWithUsername = 0;
  List<Map<String, dynamic>> _recentRegistrations = [];
  List<Map<String, dynamic>> _recentUsernameSelections = [];
  List<Map<String, dynamic>> _onlineUsersList = [];
  Map<String, int> _messageReadCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllStats();
    
    // Her 30 saniyede bir istatistikleri yenile
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startPeriodicUpdates() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadAllStats();
        _startPeriodicUpdates();
      }
    });
  }

  Future<void> _loadAllStats() async {
    if (!_adminService.isFounder()) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadBasicStats(),
        _loadRecentRegistrations(),
        _loadRecentUsernameSelections(),
        _loadOnlineUsers(),
        _loadMessageReadCounts(),
      ]);
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      return lastSeen != null && 
             lastSeen.toDate().isAfter(fiveMinutesAgo);
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
    final usersSnapshot = await _firestore
        .collection('users')
        .where('username', isNull: false)
        .orderBy('usernameSetAt', descending: true)
        .limit(10)
        .get();

    _recentUsernameSelections = usersSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'username': data['username'] ?? 'Yok',
        'usernameSetAt': data['usernameSetAt'] as Timestamp?,
        'email': data['email'] ?? 'Bilinmiyor',
        'photoUrl': data['photoUrl'],
      };
    }).toList();
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

  Future<void> _loadMessageReadCounts() async {
    // Kurucunun mesajlarını bul
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final messagesSnapshot = await _firestore
        .collection('community_chat')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    Map<String, int> readCounts = {};
    
    for (final messageDoc in messagesSnapshot.docs) {
      final messageId = messageDoc.id;
      
      // Bu mesajı okuyanları say
      final readBySnapshot = await _firestore
          .collection('message_reads')
          .where('messageId', isEqualTo: messageId)
          .get();
      
      readCounts[messageId] = readBySnapshot.docs.length;
    }

    _messageReadCounts = readCounts;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Kurucu kontrolü
    if (!_adminService.isFounder()) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0B141A) : Colors.white,
        appBar: AppBar(
          title: const Text('Yetkisiz Erişim'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Bu panele erişim yetkiniz yok.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('Sadece kurucu erişebilir.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0B141A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('🎛️ Admin Dashboard'),
        backgroundColor: isDarkMode ? const Color(0xFF1E2832) : const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllStats,
            tooltip: 'Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '📊 Genel', icon: Icon(Icons.dashboard)),
            Tab(text: '👥 Kullanıcılar', icon: Icon(Icons.people)),
            Tab(text: '🟢 Online', icon: Icon(Icons.online_prediction)),
            Tab(text: '📨 Mesajlar', icon: Icon(Icons.message)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(isDarkMode),
                _buildUsersTab(isDarkMode),
                _buildOnlineTab(isDarkMode),
                _buildMessagesTab(isDarkMode),
              ],
            ),
    );
  }

  Widget _buildGeneralTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // İstatistik kartları
          Row(
            children: [
              Expanded(child: _buildStatCard(
                '👥 Toplam Kullanıcı', 
                _totalUsers.toString(),
                Colors.blue,
                isDarkMode,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                '🏷️ Kullanıcı Adı Seçen', 
                _usersWithUsername.toString(),
                Colors.green,
                isDarkMode,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                '🟢 Online Şimdi', 
                _onlineUsers.toString(),
                Colors.orange,
                isDarkMode,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                '✅ Aktif + Kullanıcı Adı', 
                _activeUsersWithUsername.toString(),
                Colors.purple,
                isDarkMode,
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

  Widget _buildUsersTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Son kayıtlar
          _buildSectionTitle('🆕 En Son Kayıt Olanlar', isDarkMode),
          _buildUserList(_recentRegistrations, showEmail: true, isDarkMode: isDarkMode),
          
          const SizedBox(height: 24),
          
          // Son kullanıcı adı seçenler
          _buildSectionTitle('🏷️ En Son Kullanıcı Adı Seçenler', isDarkMode),
          _buildUserList(_recentUsernameSelections, showUsername: true, isDarkMode: isDarkMode),
        ],
      ),
    );
  }

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

  Widget _buildMessagesTab(bool isDarkMode) {
    if (!_adminService.isFounder()) {
      return const Center(child: Text('Bu bölüm sadece kurucular içindir'));
    }

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

  Widget _buildStatCard(String title, String value, Color color, bool isDarkMode) {
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
            title,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Kullanıcı adı seçen'),
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Online olan'),
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
    return Text(
      title,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, 
                       {bool showEmail = false, bool showUsername = false, required bool isDarkMode}) {
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
                  ? Text(user[showUsername ? 'username' : 'email']?.substring(0, 1).toUpperCase() ?? '?')
                  : null,
            ),
            title: Text(
              showUsername ? user['username'] ?? 'Yok' : user['email'] ?? 'Bilinmiyor',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showEmail && showUsername) Text(user['email'] ?? 'Bilinmiyor'),
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
    // Kurucunun mesajlarını gerçek zamanlı dinle
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
            child: Text(
              'Henüz mesajınız bulunmuyor',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
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
                          
                          return Row(
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
                          );
                        },
                      ),
                    ],
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
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
