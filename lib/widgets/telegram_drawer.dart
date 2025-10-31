import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class TelegramDrawer extends StatefulWidget {
  const TelegramDrawer({super.key});

  @override
  State<TelegramDrawer> createState() => _TelegramDrawerState();
}

class _TelegramDrawerState extends State<TelegramDrawer> {
  final AuthService _authService = AuthService();
  String? _username;
  String? _userEmail;
  String? _userPhoneNumber;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
        _userPhoneNumber = user.phoneNumber;
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    
    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF17212B) : const Color(0xFFFFFFFF),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0E1621) : const Color(0xFF517DA2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _username?.isNotEmpty == true 
                                ? _username![0].toUpperCase()
                                : (_userEmail?.isNotEmpty == true 
                                    ? _userEmail![0].toUpperCase() 
                                    : '?'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _username ?? 'Kullanıcı',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userPhoneNumber ?? _userEmail ?? 'Giriş yapılmamış',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.group,
                    title: 'Yeni Grup',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      // Yeni grup oluştur
                    },
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.person_add,
                    title: 'Kişi Ekle',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      // Kişi ekle
                    },
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.contacts,
                    title: 'Kişiler',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      // Kişiler
                    },
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.phone,
                    title: 'Aramalar',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      // Aramalar
                    },
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.bookmark,
                    title: 'Kayıtlı Mesajlar',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      // Kayıtlı mesajlar
                    },
                  ),
                  
                  const Divider(height: 32),
                  
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Ayarlar',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      // Ayarlar
                    },
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.dark_mode,
                    title: 'Karanlık Mod',
                    isDarkMode: isDarkMode,
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        // Theme toggle
                      },
                      activeColor: const Color(0xFF517DA2),
                    ),
                    onTap: null,
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Yardım',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.pop(context);
                      // Yardım
                    },
                  ),
                  
                  if (user != null) ...[
                    const Divider(height: 32),
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Çıkış Yap',
                      isDarkMode: isDarkMode,
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutDialog();
                      },
                    ),
                  ],
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Kavaid v2.2.0',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isDarkMode,
    VoidCallback? onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final color = isDestructive 
        ? Colors.red 
        : (isDarkMode ? Colors.white : const Color(0xFF1C1C1E));
    
    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                // Ana ekrana dön
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
