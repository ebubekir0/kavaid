// Script to export current database to assets folder
// Run this script once to copy the current database to assets

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  try {
    // Get database path
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, 'kavaid.db');
    
    print('📍 Veritabanı konumu: $dbPath');
    
    // Check if database exists
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      print('❌ Veritabanı bulunamadı! Önce uygulamayı çalıştırıp veritabanını yükleyin.');
      return;
    }
    
    // Get database size
    final dbSize = await dbFile.length();
    print('📊 Veritabanı boyutu: ${(dbSize / 1024 / 1024).toStringAsFixed(2)} MB');
    
    // Copy to assets folder
    final assetsPath = join(Directory.current.path, 'assets', 'database');
    final assetsDir = Directory(assetsPath);
    
    // Create assets/database directory if it doesn't exist
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
      print('✅ Assets klasörü oluşturuldu: $assetsPath');
    }
    
    final targetPath = join(assetsPath, 'kavaid.db');
    await dbFile.copy(targetPath);
    
    print('✅ Veritabanı başarıyla kopyalandı!');
    print('📁 Hedef konum: $targetPath');
    print('');
    print('🔔 Sonraki adımlar:');
    print('1. pubspec.yaml dosyasına "assets/database/" ekleyin');
    print('2. DatabaseService kodunu güncelleyin');
    print('3. flutter clean && flutter pub get komutlarını çalıştırın');
    
  } catch (e) {
    print('❌ Hata: $e');
  }
}
