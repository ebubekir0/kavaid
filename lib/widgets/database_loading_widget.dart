import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';
import '../services/database_initialization_service.dart';
import '../services/turkce_analytics_service.dart';

class DatabaseLoadingWidget extends StatefulWidget {
  const DatabaseLoadingWidget({super.key});

  @override
  State<DatabaseLoadingWidget> createState() => _DatabaseLoadingWidgetState();
}

class _DatabaseLoadingWidgetState extends State<DatabaseLoadingWidget> {
  final DatabaseService _dbService = DatabaseService.instance;
  final DatabaseInitializationService _dbInitService = DatabaseInitializationService.instance;
  
  String _statusText = 'Sözlük hazırlanıyor...';
  bool _isLoading = true;
  bool _showRetryButton = false;
  double _progress = 0.0;
  String _sizeText = '';
  bool _isDatabaseReady = false;
  
  @override
  void initState() {
    super.initState();
    _checkDatabaseStatus();
  }
  
  Future<void> _checkDatabaseStatus() async {
    try {
      final db = await _dbService.database;
      final tableInfo = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='words'");
      bool tableExists = tableInfo.isNotEmpty;
      int wordCount = 0;
      
      if (tableExists) {
        final countResult = await db.rawQuery('SELECT COUNT(*) FROM words');
        wordCount = Sqflite.firstIntValue(countResult) ?? 0;
      }
      
      if (tableExists && wordCount > 0) {
        setState(() {
          _isDatabaseReady = true;
        });
        return;
      }
      
      _startLoadingProcess();
    } catch (e) {
      debugPrint('❌ Database status check hatası: $e');
      _startLoadingProcess();
    }
  }
  
  Future<void> _startLoadingProcess() async {
    try {
      await _loadEmbeddedDatabase();
    } catch (e) {
      debugPrint('❌ Database loading hatası: $e');
      await _handleError('Hata oluştu');
    }
  }
  
  Future<void> _loadEmbeddedDatabase() async {
    try {
      await TurkceAnalyticsService.ekranGoruntulendi('veritabani_yukleme_basladi');
      
      // Progress callback ayarla
      _dbInitService.onProgress = (progress, message) {
        setState(() {
          _progress = progress;
          _statusText = message;
        });
      };
      
      // Embedded data'yı yükle
      final success = await _dbInitService.initializeDatabase();
      
      if (success) {
        final db = await _dbService.database;
        final countResult = await db.rawQuery('SELECT COUNT(*) FROM words');
        final finalWordCount = Sqflite.firstIntValue(countResult) ?? 0;
        
        await TurkceAnalyticsService.ekranGoruntulendi('veritabani_yukleme_tamamlandi');
        
        setState(() {
          _isDatabaseReady = true;
          _isLoading = false;
        });
      } else {
        await _handleError('Sözlük yüklenemedi');
      }
      
    } catch (e) {
      debugPrint('❌ Database sync hatası: $e');
      await _handleError('Hata oluştu');
    }
  }
  
  Future<void> _handleError(String error) async {
    setState(() {
      _statusText = error;
      _isLoading = false;
      _showRetryButton = true;
    });
  }
  
  void _retry() {
    setState(() {
      _isLoading = true;
      _showRetryButton = false;
      _progress = 0.0;
      _statusText = 'Sözlük hazırlanıyor...';
    });
    _startLoadingProcess();
  }
  
  @override
  Widget build(BuildContext context) {
    // Veritabanı hazırsa boş widget döndür
    if (_isDatabaseReady) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sözlük ikonu
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Durum metni
          Text(
            _statusText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2E),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          const SizedBox(height: 32),

          // Progress bar (sadece yükleme sırasında)
          if (_isLoading) ...[
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],

          // Retry butonu (hata durumunda)
          if (_showRetryButton) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Tekrar Dene',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
