import 'dart:convert';
import 'word_model.dart';

class CustomWord {
  final String id;
  final String arabic;
  final String turkish;
  final String? harekeliKelime; // Harekeli Arapça kelime
  final Map<String, dynamic>? wordData; // Tüm WordModel verileri
  final DateTime createdAt;
  final String? listId; // Hangi listeye ait olduğu

  CustomWord({
    required this.id,
    required this.arabic,
    required this.turkish,
    this.harekeliKelime,
    this.wordData,
    required this.createdAt,
    this.listId,
  });

  /// WordModel'den CustomWord oluştur
  factory CustomWord.fromWordModel(WordModel word, String id, String listId) {
    return CustomWord(
      id: id,
      arabic: word.kelime,
      turkish: word.anlam ?? '',
      harekeliKelime: word.harekeliKelime,
      wordData: word.toJson(),
      createdAt: DateTime.now(),
      listId: listId,
    );
  }

  /// CustomWord'den WordModel oluştur
  WordModel toWordModel() {
    if (wordData != null) {
      return WordModel.fromJson(wordData!);
    }
    // Eski veriler için fallback
    return WordModel(
      kelime: arabic,
      harekeliKelime: harekeliKelime ?? arabic,
      anlam: turkish,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'arabic': arabic,
      'turkish': turkish,
      'harekeliKelime': harekeliKelime,
      'wordData': wordData,
      'createdAt': createdAt.toIso8601String(),
      'listId': listId,
    };
  }

  factory CustomWord.fromMap(Map<String, dynamic> map) {
    return CustomWord(
      id: map['id'] ?? '',
      arabic: map['arabic'] ?? '',
      turkish: map['turkish'] ?? '',
      harekeliKelime: map['harekeliKelime'],
      wordData: map['wordData'] != null 
          ? Map<String, dynamic>.from(map['wordData']) 
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      listId: map['listId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomWord.fromJson(String source) => CustomWord.fromMap(json.decode(source));
}
