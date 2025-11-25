import 'dart:convert';

class CustomWordList {
  final String id;
  final String name;
  final DateTime createdAt;

  CustomWordList({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomWordList.fromMap(Map<String, dynamic> map) {
    return CustomWordList(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomWordList.fromJson(String source) => CustomWordList.fromMap(json.decode(source));
}
