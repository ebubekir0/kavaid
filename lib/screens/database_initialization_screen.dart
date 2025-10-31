import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_initialization_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class DatabaseInitializationScreen extends StatefulWidget {
  const DatabaseInitializationScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseInitializationScreen> createState() => _DatabaseInitializationScreenState();
}

class _DatabaseInitializationScreenState extends State<DatabaseInitializationScreen> 
    with SingleTickerProviderStateMixin {
  final DatabaseInitializationService _initService = DatabaseInitializationService.instance;
  
  double _progress = 0.0;
  String _statusMessage = 'Başlatılıyor...';
  bool _isInitializing = false;
  bool _hasError = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _checkAndInitialize();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _checkAndInitialize() async {
    setState(() {
      _isInitializing = true;
      _hasError = false;
      _statusMessage = 'Veritabanı kontrol ediliyor...';
    });
    
    // Progress callback'i ayarla
    _initService.onProgress = (progress, message) {
      if (mounted) {
        setState(() {
          _progress = progress;
          _statusMessage = message;
        });
      }
    };
    
    // Database güncel mi kontrol et
    final isUpToDate = await _initService.isDatabaseUpToDate();
    
    if (isUpToDate) {
      // Database güncel, direkt ana ekrana geç
      setState(() {
        _progress = 1.0;
        _statusMessage = 'Veritabanı hazır!';
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(
              bottomPadding: 0,
              isDarkMode: false,
              isActive: true,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } else {
      // Database güncellenmesi gerekiyor
      final success = await _initService.initializeDatabase();
      
      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(
                bottomPadding: 0,
                isDarkMode: false,
                isActive: true,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } else {
        setState(() {
          _hasError = true;
          _isInitializing = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo veya İkon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Başlık
                  Text(
                    'Kavâid-i Arabiyye',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppTheme.darkText,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Arapça Sözlük',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : AppTheme.darkText.withOpacity(0.6),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Progress Bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: isDarkMode 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.black.withOpacity(0.05),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _hasError ? Colors.red : AppTheme.primaryColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Durum Mesajı
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusMessage,
                      key: ValueKey(_statusMessage),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _hasError 
                            ? Colors.red 
                            : (isDarkMode ? Colors.white70 : AppTheme.darkText.withOpacity(0.6)),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Hata durumunda yeniden dene butonu
                  if (_hasError) ...[
                    ElevatedButton.icon(
                      onPressed: _isInitializing ? null : _checkAndInitialize,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Yeniden Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Çevrimdışı devam et butonu
                    TextButton(
                      onPressed: () async {
                        final dbInfo = await _initService.getDatabaseInfo();
                        final wordCount = dbInfo['wordCount'] as int;
                        
                        if (wordCount > 0) {
                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(
                                  bottomPadding: 0,
                                  isDarkMode: false,
                                  isActive: true,
                                ),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Çevrimdışı kullanım için önce veritabanı indirilmelidir.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Çevrimdışı Devam Et',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : AppTheme.darkText.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                  
                  // Loading indicator
                  if (_isInitializing && !_hasError) ...[
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor.withOpacity(0.6),
                      ),
                      strokeWidth: 2,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
