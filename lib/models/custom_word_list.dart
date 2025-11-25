import 'dart:convert';

class CustomWordList {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool isDefault; // Varsayılan liste mi?

  CustomWordList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory CustomWordList.fromMap(Map<String, dynamic> map) {
    return CustomWordList(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      isDefault: map['isDefault'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomWordList.fromJson(String source) => CustomWordList.fromMap(json.decode(source));
}
