import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // İnternet bağlantısını kontrol et
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // Daha detaylı kontrol
      bool hasConnection = false;
      for (var result in connectivityResult) {
        if (result != ConnectivityResult.none) {
          hasConnection = true;
          break;
        }
      }
      
      return hasConnection;
    } catch (e) {
      return false;
    }
  }
  
  // Bağlantı değişikliklerini dinle
  void startListening(Function(bool) onConnectionChanged) {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      onConnectionChanged(hasConnection);
    });
  }
  
  // Dinlemeyi durdur
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  // CRITICAL: Memory leak önleme için dispose
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  // İnternet yok dialog'u göster
  static Future<void> showNoInternetDialog(BuildContext context, {VoidCallback? onRetry}) async {
    // Eğer yerel DB hazırsa (words tablosu var ve kayıt > 0), internetsiz kullanım mümkün:
    try {
      final db = await DatabaseService.instance.database;
      if (db != null) {
        final tableInfo = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='words'");
        final tableExists = tableInfo.isNotEmpty;
        int wordCount = 0;
        if (tableExists) {
          final countResult = await db.rawQuery('SELECT COUNT(*) FROM words');
          wordCount = Sqflite.firstIntValue(countResult) ?? 0;
        }
        if (tableExists && wordCount > 0) {
          // DB hazır: Dialog göstermeden sessizce geri dön
          return;
        }
      }
    } catch (_) {
      // DB kontrolü hatasında, eski davranışa (dialog) geri düş
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return SafeArea(
          // 🔧 ANDROID 15 FIX: Dialog safe area padding
          child: WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
            backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF007AFF),
                ),
                const SizedBox(height: 16),
                Text(
                  'İnternet Bağlantısı Yok',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Uygulamayı kullanabilmek için internet bağlantısına ihtiyacınız var. Lütfen WiFi veya mobil veri bağlantınızı kontrol edin.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () async {
                  // Bağlantıyı tekrar kontrol et
                  final hasConnection = await ConnectivityService().hasInternetConnection();
                  if (hasConnection) {
                    Navigator.of(context).pop();
                    onRetry?.call();
                  }
                  // Hala bağlantı yoksa sessizce devam et, bildirim gösterme
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF007AFF),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tekrar Dene',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }
} 