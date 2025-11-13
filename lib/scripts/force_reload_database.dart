// Force reload embedded data - SharedPreferences'i temizler ve database'i yeniden oluşturur

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/database_service.dart';
import '../services/database_initialization_service.dart';

Future<void> main() async {
  print('🔄 Embedded data force reload işlemi başlatılıyor...\n');

  try {
    // SharedPreferences'i temizle
    print('📱 SharedPreferences temizleniyor...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('embedded_data_loaded');
    await prefs.remove('database_version');
    await prefs.remove('last_update_date');
    print('✅ SharedPreferences temizlendi');

    // Mevcut database'i sil
    print('🗑️ Mevcut database siliniyor...');
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'kavaid.db');
    final dbFile = File(dbPath);
    
    if (await dbFile.exists()) {
      await dbFile.delete();
      print('✅ Eski database silindi');
    } else {
      print('📝 Database zaten yok, devam ediliyor...');
    }

    // Database initialization service ile yeni data'yı yükle
    print('📥 Yeni embedded data yükleniyor...');
    final dbInitService = DatabaseInitializationService.instance;
    
    // Progress callback
    dbInitService.onProgress = (progress, message) {
      print('📊 Progress: ${(progress * 100).toInt()}% - $message');
    };
    
    final success = await dbInitService.initializeDatabase();
    
    if (success) {
      print('✅ Database başarıyla yeniden oluşturuldu!');
      
      // Database info göster
      final info = await dbInitService.getDatabaseInfo();
      print('📊 Database bilgileri:');
      print('   - Kelime sayısı: ${info['wordCount']}');
      print('   - Version: ${info['version']}');
      print('   - Son güncelleme: ${info['lastUpdate']}');
    } else {
      print('❌ Database yeniden oluşturulamadı!');
      exit(1);
    }

    print('\n🎉 Force reload işlemi tamamlandı!');
    print('💡 Uygulamayı yeniden başlatın.');

  } catch (e) {
    print('❌ Hata: $e');
    exit(1);
  }
}
