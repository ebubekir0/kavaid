import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../data/books/kitab_kiraah_1_data.dart';
import '../data/books/kitab_kiraah_2_data.dart';
import '../data/books/kitab_kiraah_3_data.dart';

class BookWord {
  final String arabic;
  final String turkish;
  final String type;
  final String? root;
  final String? notes;

  BookWord({required this.arabic, required this.turkish, required this.type, this.root, this.notes});

  factory BookWord.fromMap(Map<String, dynamic> map) {
    return BookWord(
      arabic: (map['arapca'] as String?)?.trim() ?? '',
      turkish: (map['turkce'] as String?)?.trim() ?? '',
      type: (map['tip'] as String?)?.trim() ?? 'kelime',
      root: (map['kok'] as String? ?? map['kök'] as String?)?.trim(),
      notes: (map['notlar'] as String?)?.trim(),
    );
  }
}

class BookLessonsService {
  Future<List<BookTextInfo>> loadTextIndex({required String bookId}) async {
    try {
      final String path = 'assets/books/'
          '${bookId}/index.json';
      print('DEBUG: Loading text index from path: ' + path);
      final String jsonStr = await rootBundle.loadString(path);
      final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> items = (data['metinler'] as List<dynamic>? ) ?? const [];
      print('DEBUG: Found ' + items.length.toString() + ' lessons');
      return items.map((e) => BookTextInfo.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('DEBUG: Error loading text index: ' + e.toString());
      // Embedded fallback
      if (bookId == 'kitab_kiraah_1') {
        final List<dynamic> items = (kitabKiraah1Index['metinler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded index with ' + items.length.toString() + ' lessons');
        return items.map((e) => BookTextInfo.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2') {
        final List<dynamic> items = (kitabKiraah2Index['metinler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded index (book 2) with ' + items.length.toString() + ' lessons');
        return items.map((e) => BookTextInfo.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3') {
        final List<dynamic> items = (kitabKiraah3Index['metinler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded index (book 3) with ' + items.length.toString() + ' lessons');
        return items.map((e) => BookTextInfo.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      return <BookTextInfo>[];
    }
  }

  Future<List<BookWord>> loadLessonWords({required String bookId, required int lessonNo}) async {
    try {
      final String path = 'assets/books/'
          '${bookId}/lesson_${lessonNo}.json';
      print('DEBUG: Loading words from path: $path');
      final String jsonStr = await rootBundle.loadString(path);
      final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;
      print('DEBUG: JSON data keys: ${data.keys.toList()}');

      // İki farklı yapı için destek: ders_bilgisi.kelimeler veya doğrudan kelimeler
      if (data.containsKey('ders_bilgisi')) {
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Found ${words.length} words in ders_bilgisi');
        return words.map((e) => BookWord.fromMap(e as Map<String, dynamic>)).toList();
      }

      final List<dynamic> words = (data['kelimeler'] as List<dynamic>? ) ?? const [];
      print('DEBUG: Found ${words.length} words directly');
      return words.map((e) => BookWord.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('DEBUG: Error loading words: $e');
      // Embedded fallback
      if (bookId == 'kitab_kiraah_1' && lessonNo == 1) {
        final Map<String, dynamic> data = kitabKiraah1Lesson1;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_1 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 2) {
        final Map<String, dynamic> data = kitabKiraah1Lesson2;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_2 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 3) {
        final Map<String, dynamic> data = kitabKiraah1Lesson3;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_3 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 4) {
        final Map<String, dynamic> data = kitabKiraah1Lesson4;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_4 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 5) {
        final Map<String, dynamic> data = kitabKiraah1Lesson5;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_5 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 6) {
        final Map<String, dynamic> data = kitabKiraah1Lesson6;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_6 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 7) {
        final Map<String, dynamic> data = kitabKiraah1Lesson7;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_7 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 8) {
        final Map<String, dynamic> data = kitabKiraah1Lesson8;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_8 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 9) {
        final Map<String, dynamic> data = kitabKiraah1Lesson9;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_9 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 10) {
        final Map<String, dynamic> data = kitabKiraah1Lesson10;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_10 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 11) {
        final Map<String, dynamic> data = kitabKiraah1Lesson11;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_11 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 12) {
        final Map<String, dynamic> data = kitabKiraah1Lesson12;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_12 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 13) {
        final Map<String, dynamic> data = kitabKiraah1Lesson13;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_13 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 14) {
        final Map<String, dynamic> data = kitabKiraah1Lesson14;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_14 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 15) {
        final Map<String, dynamic> data = kitabKiraah1Lesson15;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_15 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 16) {
        final Map<String, dynamic> data = kitabKiraah1Lesson16;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_16 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 17) {
        final Map<String, dynamic> data = kitabKiraah1Lesson17;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_17 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 18) {
        final Map<String, dynamic> data = kitabKiraah1Lesson18;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_18 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 19) {
        final Map<String, dynamic> data = kitabKiraah1Lesson19;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_19 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 20) {
        final Map<String, dynamic> data = kitabKiraah1Lesson20;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_20 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 21) {
        final Map<String, dynamic> data = kitabKiraah1Lesson21;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_21 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 22) {
        final Map<String, dynamic> data = kitabKiraah1Lesson22;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_22 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 23) {
        final Map<String, dynamic> data = kitabKiraah1Lesson23;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_23 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 24) {
        final Map<String, dynamic> data = kitabKiraah1Lesson24;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_24 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_1' && lessonNo == 25) {
        final Map<String, dynamic> data = kitabKiraah1Lesson25;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded lesson_25 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 1) {
        final Map<String, dynamic> data = kitabKiraah2Lesson1;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_1 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 2) {
        final Map<String, dynamic> data = kitabKiraah2Lesson2;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_2 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 3) {
        final Map<String, dynamic> data = kitabKiraah2Lesson3;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_3 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 4) {
        final Map<String, dynamic> data = kitabKiraah2Lesson4;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_4 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 5) {
        final Map<String, dynamic> data = kitabKiraah2Lesson5;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_5 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 6) {
        final Map<String, dynamic> data = kitabKiraah2Lesson6;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_6 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 7) {
        final Map<String, dynamic> data = kitabKiraah2Lesson7;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_7 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 8) {
        final Map<String, dynamic> data = kitabKiraah2Lesson8;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_8 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 9) {
        final Map<String, dynamic> data = kitabKiraah2Lesson9;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_9 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 10) {
        final Map<String, dynamic> data = kitabKiraah2Lesson10;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_10 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 11) {
        final Map<String, dynamic> data = kitabKiraah2Lesson11;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_11 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 12) {
        final Map<String, dynamic> data = kitabKiraah2Lesson12;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_12 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 13) {
        final Map<String, dynamic> data = kitabKiraah2Lesson13;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_13 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 14) {
        final Map<String, dynamic> data = kitabKiraah2Lesson14;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_14 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 15) {
        final Map<String, dynamic> data = kitabKiraah2Lesson15;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_15 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 16) {
        final Map<String, dynamic> data = kitabKiraah2Lesson16;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_16 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 17) {
        final Map<String, dynamic> data = kitabKiraah2Lesson17;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_17 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 18) {
        final Map<String, dynamic> data = kitabKiraah2Lesson18;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_18 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 19) {
        final Map<String, dynamic> data = kitabKiraah2Lesson19;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_19 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 20) {
        final Map<String, dynamic> data = kitabKiraah2Lesson20;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_20 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 21) {
        final Map<String, dynamic> data = kitabKiraah2Lesson21;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_21 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 22) {
        final Map<String, dynamic> data = kitabKiraah2Lesson22;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_22 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 23) {
        final Map<String, dynamic> data = kitabKiraah2Lesson23;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_23 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 24) {
        final Map<String, dynamic> data = kitabKiraah2Lesson24;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_24 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 25) {
        final Map<String, dynamic> data = kitabKiraah2Lesson25;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_25 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 26) {
        final Map<String, dynamic> data = kitabKiraah2Lesson26;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_26 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 27) {
        final Map<String, dynamic> data = kitabKiraah2Lesson27;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_27 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 28) {
        final Map<String, dynamic> data = kitabKiraah2Lesson28;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_28 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 29) {
        final Map<String, dynamic> data = kitabKiraah2Lesson29;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_29 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_2' && lessonNo == 30) {
        final Map<String, dynamic> data = kitabKiraah2Lesson30;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 2) lesson_30 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      // Generic shift fallback for kitab_kiraah_3 after removing lesson 3:
      // For lessonNo in [3,23], load words from embedded data of (lessonNo + 1)
      if (bookId == 'kitab_kiraah_3' && lessonNo >= 3 && lessonNo <= 23) {
        Map<String, dynamic>? dataShift;
        switch (lessonNo + 1) {
          case 4:
            dataShift = kitabKiraah3Lesson4;
            break;
          case 5:
            dataShift = kitabKiraah3Lesson5;
            break;
          case 6:
            dataShift = kitabKiraah3Lesson6;
            break;
          case 7:
            dataShift = kitabKiraah3Lesson7;
            break;
          case 8:
            dataShift = kitabKiraah3Lesson8;
            break;
          case 9:
            dataShift = kitabKiraah3Lesson9;
            break;
          case 10:
            dataShift = kitabKiraah3Lesson10;
            break;
          case 11:
            dataShift = kitabKiraah3Lesson11;
            break;
          case 12:
            dataShift = kitabKiraah3Lesson12;
            break;
          case 13:
            dataShift = kitabKiraah3Lesson13;
            break;
          case 14:
            dataShift = kitabKiraah3Lesson14;
            break;
          case 15:
            dataShift = kitabKiraah3Lesson15;
            break;
          case 16:
            dataShift = kitabKiraah3Lesson16;
            break;
          case 17:
            dataShift = kitabKiraah3Lesson17;
            break;
          case 18:
            dataShift = kitabKiraah3Lesson18;
            break;
          case 19:
            dataShift = kitabKiraah3Lesson19;
            break;
          case 20:
            dataShift = kitabKiraah3Lesson20;
            break;
          case 21:
            dataShift = kitabKiraah3Lesson21;
            break;
          case 22:
            dataShift = kitabKiraah3Lesson22;
            break;
          case 23:
            dataShift = kitabKiraah3Lesson23;
            break;
          case 24:
            dataShift = kitabKiraah3Lesson24;
            break;
          case 25:
            dataShift = kitabKiraah3Lesson25;
            break;
          default:
            dataShift = null;
        }
        if (dataShift != null) {
          final Map<String, dynamic> ders = (dataShift['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using shifted embedded (book 3) lesson_' + lessonNo.toString() + ' <- lesson_' + (lessonNo + 1).toString() + ' with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }

      // kitab_kiraah_3 embedded fallbacks
      if (bookId == 'kitab_kiraah_3' && lessonNo == 1) {
        final Map<String, dynamic> data = kitabKiraah3Lesson1;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_1 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 2) {
        final Map<String, dynamic> data = kitabKiraah3Lesson2;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_2 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 3) {
        final Map<String, dynamic> data = kitabKiraah3Lesson3;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_3 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 4) {
        final Map<String, dynamic> data = kitabKiraah3Lesson4;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_4 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 5) {
        final Map<String, dynamic> data = kitabKiraah3Lesson5;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_5 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 6) {
        final Map<String, dynamic> data = kitabKiraah3Lesson6;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_6 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 7) {
        final Map<String, dynamic> data = kitabKiraah3Lesson7;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_7 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 8) {
        final Map<String, dynamic> data = kitabKiraah3Lesson8;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_8 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 9) {
        final Map<String, dynamic> data = kitabKiraah3Lesson9;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_9 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 10) {
        final Map<String, dynamic> data = kitabKiraah3Lesson10;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_10 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 11) {
        final Map<String, dynamic> data = kitabKiraah3Lesson11;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_11 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 12) {
        final Map<String, dynamic> data = kitabKiraah3Lesson12;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_12 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 13) {
        final Map<String, dynamic> data = kitabKiraah3Lesson13;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_13 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 14) {
        final Map<String, dynamic> data = kitabKiraah3Lesson14;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_14 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 15) {
        final Map<String, dynamic> data = kitabKiraah3Lesson15;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_15 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 16) {
        final Map<String, dynamic> data = kitabKiraah3Lesson16;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_16 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 17) {
        final Map<String, dynamic> data = kitabKiraah3Lesson17;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_17 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 18) {
        final Map<String, dynamic> data = kitabKiraah3Lesson18;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_18 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 19) {
        final Map<String, dynamic> data = kitabKiraah3Lesson19;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_19 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 20) {
        final Map<String, dynamic> data = kitabKiraah3Lesson20;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_20 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 21) {
        final Map<String, dynamic> data = kitabKiraah3Lesson21;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_21 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 22) {
        final Map<String, dynamic> data = kitabKiraah3Lesson22;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_22 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 23) {
        final Map<String, dynamic> data = kitabKiraah3Lesson23;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_23 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 24) {
        final Map<String, dynamic> data = kitabKiraah3Lesson24;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_24 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (bookId == 'kitab_kiraah_3' && lessonNo == 25) {
        final Map<String, dynamic> data = kitabKiraah3Lesson25;
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Using embedded (book 3) lesson_25 with ' + words.length.toString() + ' words');
        return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
      return <BookWord>[];
    }
  }

  Future<List<BookWord>> loadTextWords({required String bookId, required String textId}) async {
    try {
      final String path = 'assets/books/'
          '${bookId}/${textId}.json';
      print('DEBUG: Loading words from path: $path'); // DEBUG
      final String jsonStr = await rootBundle.loadString(path);
      final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;
      print('DEBUG: JSON data keys: ${data.keys.toList()}'); // DEBUG
      
      // destek: ders_bilgisi.kelimeler veya doğrudan kelimeler
      List<dynamic> wordsDyn = const [];
      if (data.containsKey('ders_bilgisi')) {
        final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
        wordsDyn = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Found ${wordsDyn.length} words in ders_bilgisi'); // DEBUG
      } else {
        wordsDyn = (data['kelimeler'] as List<dynamic>? ) ?? const [];
        print('DEBUG: Found ${wordsDyn.length} words directly'); // DEBUG
      }

      // Eğer JSON başarıyla yüklense de kelimeler boşsa, gömülü fallback'e düş
      if (wordsDyn.isEmpty) {
        if (bookId == 'kitab_kiraah_2') {
          print('DEBUG: Empty words list after JSON load, trying embedded fallback for $textId (book 2)');
          Map<String, dynamic>? embedded;
          switch (textId) {
            case 'lesson_12':
              embedded = kitabKiraah2Lesson12;
              break;
            case 'lesson_13':
              embedded = kitabKiraah2Lesson13;
              break;
            case 'lesson_18':
              embedded = kitabKiraah2Lesson18;
              break;
            default:
              embedded = null;
          }
          if (embedded != null && embedded.containsKey('ders_bilgisi')) {
            final Map<String, dynamic> ders = embedded['ders_bilgisi'] as Map<String, dynamic>;
            final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
            print('DEBUG: Using embedded fallback for $textId with ' + words.length.toString() + ' words');
            return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
          }
        }
        // Genel delege: lesson_<n> pattern'i yakalanırsa numaraya göre loadLessonWords çağır (book 2 ve 3 için)
        final match = RegExp(r'^lesson_(\d+)$').firstMatch(textId);
        if (match != null && (bookId == 'kitab_kiraah_2' || bookId == 'kitab_kiraah_3')) {
          final int n = int.tryParse(match.group(1)!) ?? -1;
          if (n > 0) {
            print('DEBUG: Delegating to loadLessonWords for $bookId lessonNo=$n (empty list path)');
            return await loadLessonWords(bookId: bookId, lessonNo: n);
          }
        }
      }

      return wordsDyn.map((e) => BookWord.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('DEBUG: Error loading words: $e'); // DEBUG
      // Embedded fallback by textId or delegate when asset load fails
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_1') {
        final Map<String, dynamic> data = kitabKiraah1Lesson1;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_1 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_2') {
        final Map<String, dynamic> data = kitabKiraah1Lesson2;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_2 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      // Genel delege: kitap 3 için lesson_<n> pattern'i yakala ve loadLessonWords'e delege et
      final match3 = RegExp(r'^lesson_(\d+)$').firstMatch(textId);
      if (bookId == 'kitab_kiraah_3' && match3 != null) {
        final int n = int.tryParse(match3.group(1)!) ?? -1;
        if (n > 0) {
          print('DEBUG: Delegating to loadLessonWords for kitab_kiraah_3 lessonNo=$n (catch path)');
          return await loadLessonWords(bookId: bookId, lessonNo: n);
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_3') {
        final Map<String, dynamic> data = kitabKiraah1Lesson3;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_3 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_4') {
        final Map<String, dynamic> data = kitabKiraah1Lesson4;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_4 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_5') {
        final Map<String, dynamic> data = kitabKiraah1Lesson5;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_5 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      // Book 2: textId-based fallback for lesson_18
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_18') {
        final Map<String, dynamic> data = kitabKiraah2Lesson18;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_18 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      // Book 2: textId-based fallback for lesson_12
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_12') {
        final Map<String, dynamic> data = kitabKiraah2Lesson12;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_12 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      // Book 2: textId-based fallback for lesson_13
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_13') {
        final Map<String, dynamic> data = kitabKiraah2Lesson13;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_13 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_6') {
        final Map<String, dynamic> data = kitabKiraah1Lesson6;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_6 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_7') {
        final Map<String, dynamic> data = kitabKiraah1Lesson7;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_7 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      // Genel delege: kitab_kiraah_2 için lesson_<n> formatlı textId yakalanırsa lessonNo fallback'lerine delege et
      if (bookId == 'kitab_kiraah_2') {
        final match = RegExp(r'^lesson_(\d+)$').firstMatch(textId);
        if (match != null) {
          final int n = int.tryParse(match.group(1)!) ?? -1;
          if (n > 0) {
            print('DEBUG: Catch fallback - delegating to loadLessonWords for kitab_kiraah_2 lessonNo=$n');
            return await loadLessonWords(bookId: bookId, lessonNo: n);
          }
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_8') {
        final Map<String, dynamic> data = kitabKiraah1Lesson8;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_8 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_9') {
        final Map<String, dynamic> data = kitabKiraah1Lesson9;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_9 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_10') {
        final Map<String, dynamic> data = kitabKiraah1Lesson10;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_10 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_11') {
        final Map<String, dynamic> data = kitabKiraah1Lesson11;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_11 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_12') {
        final Map<String, dynamic> data = kitabKiraah1Lesson12;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_12 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_13') {
        final Map<String, dynamic> data = kitabKiraah1Lesson13;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_13 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_14') {
        final Map<String, dynamic> data = kitabKiraah1Lesson14;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_14 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_15') {
        final Map<String, dynamic> data = kitabKiraah1Lesson15;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_15 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_16') {
        final Map<String, dynamic> data = kitabKiraah1Lesson16;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_16 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_17') {
        final Map<String, dynamic> data = kitabKiraah1Lesson17;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_17 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_18') {
        final Map<String, dynamic> data = kitabKiraah1Lesson18;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_18 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_19') {
        final Map<String, dynamic> data = kitabKiraah1Lesson19;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_19 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_20') {
        final Map<String, dynamic> data = kitabKiraah1Lesson20;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_20 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_21') {
        final Map<String, dynamic> data = kitabKiraah1Lesson21;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_21 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_22') {
        final Map<String, dynamic> data = kitabKiraah1Lesson22;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_22 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_23') {
        final Map<String, dynamic> data = kitabKiraah1Lesson23;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_23 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_24') {
        final Map<String, dynamic> data = kitabKiraah1Lesson24;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_24 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_1' && textId == 'lesson_25') {
        final Map<String, dynamic> data = kitabKiraah1Lesson25;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded text lesson_25 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_1') {
        final Map<String, dynamic> data = kitabKiraah2Lesson1;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_1 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_2') {
        final Map<String, dynamic> data = kitabKiraah2Lesson2;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_2 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_3') {
        final Map<String, dynamic> data = kitabKiraah2Lesson3;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_3 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_4') {
        final Map<String, dynamic> data = kitabKiraah2Lesson4;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_4 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_5') {
        final Map<String, dynamic> data = kitabKiraah2Lesson5;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_5 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_6') {
        final Map<String, dynamic> data = kitabKiraah2Lesson6;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_6 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_7') {
        final Map<String, dynamic> data = kitabKiraah2Lesson7;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_7 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_8') {
        final Map<String, dynamic> data = kitabKiraah2Lesson8;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_8 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_9') {
        final Map<String, dynamic> data = kitabKiraah2Lesson9;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_9 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_10') {
        final Map<String, dynamic> data = kitabKiraah2Lesson10;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_10 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_11') {
        final Map<String, dynamic> data = kitabKiraah2Lesson11;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_11 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_12') {
        final Map<String, dynamic> data = kitabKiraah2Lesson12;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_12 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_14') {
        final Map<String, dynamic> data = kitabKiraah2Lesson14;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_14 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_15') {
        final Map<String, dynamic> data = kitabKiraah2Lesson15;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_15 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_16') {
        final Map<String, dynamic> data = kitabKiraah2Lesson16;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_16 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_17') {
        final Map<String, dynamic> data = kitabKiraah2Lesson17;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_17 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_19') {
        final Map<String, dynamic> data = kitabKiraah2Lesson19;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_19 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_20') {
        final Map<String, dynamic> data = kitabKiraah2Lesson20;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_20 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_21') {
        final Map<String, dynamic> data = kitabKiraah2Lesson21;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_21 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_22') {
        final Map<String, dynamic> data = kitabKiraah2Lesson22;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_22 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_23') {
        final Map<String, dynamic> data = kitabKiraah2Lesson23;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_23 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_24') {
        final Map<String, dynamic> data = kitabKiraah2Lesson24;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_24 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_25') {
        final Map<String, dynamic> data = kitabKiraah2Lesson25;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_25 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_26') {
        final Map<String, dynamic> data = kitabKiraah2Lesson26;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_26 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_27') {
        final Map<String, dynamic> data = kitabKiraah2Lesson27;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_27 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_28') {
        final Map<String, dynamic> data = kitabKiraah2Lesson28;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_28 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_29') {
        final Map<String, dynamic> data = kitabKiraah2Lesson29;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_29 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      if (bookId == 'kitab_kiraah_2' && textId == 'lesson_30') {
        final Map<String, dynamic> data = kitabKiraah2Lesson30;
        if (data.containsKey('ders_bilgisi')) {
          final Map<String, dynamic> ders = (data['ders_bilgisi'] as Map<String, dynamic>);
          final List<dynamic> words = (ders['kelimeler'] as List<dynamic>? ) ?? const [];
          print('DEBUG: Using embedded (book 2) text lesson_30 with ' + words.length.toString() + ' words');
          return words.map((e) => BookWord.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
      return <BookWord>[];
    }
  }
}

class BookTextInfo {
  final String id; // e.g. lesson_1
  final String title; // e.g. Ders 1 — Selamlaşma ve Tanışma

  BookTextInfo({required this.id, required this.title});

  factory BookTextInfo.fromMap(Map<String, dynamic> map) {
    return BookTextInfo(
      id: (map['id'] as String?)?.trim() ?? '',
      title: (map['title'] as String?)?.trim() ?? '',
    );
  }
}


