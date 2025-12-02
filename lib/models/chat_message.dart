import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String message;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? phoneNumber;
  final DateTime timestamp;
  final bool isDeleted;
  final DateTime? deletedAt;
  
  // Reply (yanıt) bilgileri
  final String? replyToId;
  final String? replyToUserName;
  final String? replyToMessage;

  ChatMessage({
    required this.id,
    required this.message,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.phoneNumber,
    required this.timestamp,
    this.isDeleted = false,
    this.deletedAt,
    this.replyToId,
    this.replyToUserName,
    this.replyToMessage,
  });

  // Reply var mı kontrolü
  bool get hasReply => replyToId != null && replyToId!.isNotEmpty;

  // Firestore'dan ChatMessage oluştur
  factory ChatMessage.fromMap(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      message: data['message'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonim',
      userPhotoUrl: data['photoUrl'] ?? data['userPhotoUrl'], // Hem photoUrl hem userPhotoUrl destekle
      phoneNumber: data['phoneNumber'],
      // Sunucu zamanı henüz çözülmediyse, clientSentAt'i (yerel) kullan
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() 
          ?? (data['clientSentAt'] as Timestamp?)?.toDate()
          ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: data['deletedAt'] != null 
          ? (data['deletedAt'] as Timestamp).toDate() 
          : null,
      // Reply bilgileri
      replyToId: data['replyToId'],
      replyToUserName: data['replyToUserName'],
      replyToMessage: data['replyToMessage'],
    );
  }

  // Firestore'a kaydetmek için Map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'phoneNumber': phoneNumber,
      'timestamp': FieldValue.serverTimestamp(),
      'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }
}
