import 'dart:async';
import 'dart:io';

import 'package:kavaid/models/word_model.dart';
import 'package:flutter/material.dart';
import 'package:kavaid/services/database_service.dart';
import 'package:translator/translator.dart';

// Bu script, veritabanındaki Türkçe anlamları İngilizce'ye çevirmek için kullanılır.
// Projenin kök dizinindeyken çalıştırmak için: dart run lib/scripts/translate_database.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = DatabaseService.instance;
  final translator = GoogleTranslator();

  print('Veritabanı başlatılıyor...');
  // Veritabanı servisine erişim sağlamak için küçük bir bekleme.
  // Bu, servisin tamamen hazır olmasını sağlar.
  await Future.delayed(Duration(seconds: 1));
  final db = await dbService.database;

  print('İngilizce çevirisi olmayan kelimeler alınıyor...');
  final List<Map<String, dynamic>> maps = await db.query(
    'words',
    where: 'anlam_en IS NULL OR anlam_en = ?',
    whereArgs: [''],
  );

  if (maps.isEmpty) {
    print('Çevrilecek yeni kelime bulunamadı.');
    exit(0);
  }

  print('${maps.length} adet kelime çevrilecek...');

  int successCount = 0;
  int errorCount = 0;

  for (var i = 0; i < maps.length; i++) {
    final map = maps[i];
    final word = WordModel.fromJson(map);
    final turkceAnlam = word.anlam;

    if (turkceAnlam == null || turkceAnlam.trim().isEmpty) {
      print('(${i + 1}/${maps.length}) [ATLANDI] - ${word.kelime}: Türkçe anlam boş.');
      continue;
    }

    try {
      // API'yi yormamak için her istek arasında küçük bir bekleme ekleyelim.
      await Future.delayed(Duration(milliseconds: 500));

      var translation = await translator.translate(turkceAnlam, from: 'tr', to: 'en');
      String ingilizceAnlam = translation.text;

      await db.update(
        'words',
        {'anlam_en': ingilizceAnlam},
        where: 'kelime = ?',
        whereArgs: [word.kelime],
      );

      successCount++;
      print('(${i + 1}/${maps.length}) [BAŞARILI] - ${word.kelime}: ${turkceAnlam} -> ${ingilizceAnlam}');
    } catch (e) {
      errorCount++;
      print('(${i + 1}/${maps.length}) [HATA] - ${word.kelime} çevrilirken hata oluştu: $e');
    }
  }

  print('\n--- Çeviri İşlemi Tamamlandı ---');
  print('Başarılı: $successCount');
  print('Hatalı: $errorCount');
  print('Toplam: ${maps.length}');

  await dbService.close();
  exit(0);
}
