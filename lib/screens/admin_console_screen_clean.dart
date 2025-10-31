import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';

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

class _AdminConsoleScreenState extends State<AdminConsoleScreen> with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  
  int _totalUsers = 0;
  int _onlineUsers = 0;
  bool _isLoading = true;
  bool _chatEnabled = true;
  String _selectedTab = 'dashboard';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> _loadStats() async {
    if (!_adminService.isFounder()) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      // Toplam kullanıcı sayısı
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Online kullanıcı sayısı (son 5 dakikada aktif olanlar)
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      
      final onlineSnapshot = await _firestore
          .collection('users')
          .where('lastSeen', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .get();
      final onlineUsers = onlineSnapshot.docs.length;

      if (mounted) {
        setState(() {
          _totalUsers = totalUsers;
          _onlineUsers = onlineUsers;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text('Kurucu Paneli', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Veriler yükleniyor...'),
                ],
              ),
            )
          : DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  Container(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    child: TabBar(
                      labelColor: const Color(0xFF2196F3),
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: const Color(0xFF2196F3),
                      tabs: const [
                        Tab(icon: Icon(Icons.dashboard), text: 'Panel'),
                        Tab(icon: Icon(Icons.people), text: 'Moderatörler'),
                        Tab(icon: Icon(Icons.history), text: 'Loglar'),
                        Tab(icon: Icon(Icons.settings), text: 'Ayarlar'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDashboard(isDarkMode),
                        _buildModerators(isDarkMode),
                        _buildLogs(isDarkMode),
                        _buildSettings(isDarkMode),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Dashboard tab
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
                Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.blue, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Moderatör Yönetimi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Adresi',
                    hintText: 'ornek@gmail.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.orange, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Aktif Moderatörler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
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
                            trailing: Text(
                              'Moderatör',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
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
          Row(
            children: [
              Icon(Icons.history, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              Text(
                'Moderasyon Logları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
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
              Text(
                'Sistem Ayarları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
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
                Text(
                  'Chat Kontrolü',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Chat Aktif'),
                  subtitle: Text(_chatEnabled 
                    ? 'Kullanıcılar mesaj gönderebiliyor' 
                    : 'Chat kapalı - kimse mesaj gönderemiyor'),
                  value: _chatEnabled,
                  onChanged: (value) => _toggleChat(),
                  activeColor: Colors.green,
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
                Text(
                  'Kurucu Bilgileri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'KURUCU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
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
}
