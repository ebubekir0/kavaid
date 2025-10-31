import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Chat için ayrı database instance'ı
  late final FirebaseFirestore _chatFirestore;
  bool _initialized = false;

  // Chat database'ini başlat
  Future<void> _initializeChatDatabase() async {
    if (_initialized) return;
    
    try {
      // Aynı projede farklı database kullan
      _chatFirestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(), // Mevcut app
        databaseId: 'chat-db', // Yeni database ID'si
      );
      
      _initialized = true;
      debugPrint('✅ Chat Database başlatıldı: chat-db');
    } catch (e) {
      debugPrint('❌ Chat Database başlatma hatası: $e');
      // Fallback: Ana database kullan
      _chatFirestore = FirebaseFirestore.instance;
      _initialized = true;
      debugPrint('⚠️ Ana database kullanılıyor (fallback)');
    }
  }

  Future<FirebaseFirestore> get firestore async {
    await _initializeChatDatabase();
    return _chatFirestore;
  }
  final AuthService _authService = AuthService();
  
  static const String _generalChatId = 'general_chat';

  // Genel sohbet mesajlarını dinle
  Stream<List<ChatMessage>> getGeneralChatMessages() async* {
    final firestore = await this.firestore;
    yield* firestore
        .collection('chats')
        .doc(_generalChatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Mesaj gönder
  Future<void> sendMessage(String content) async {
    if (!_authService.isSignedIn || content.trim().isEmpty) return;

    try {
      final firestore = await this.firestore;
      final message = ChatMessage(
        id: '',
        content: content.trim(),
        senderId: _authService.userId!,
        senderName: _authService.displayName ?? 'Anonim',
        senderPhotoUrl: _authService.photoUrl,
        timestamp: DateTime.now(),
      );

      await firestore
          .collection('chats')
          .doc(_generalChatId)
          .collection('messages')
          .add(message.toFirestore());

      debugPrint('✅ Mesaj gönderildi: $content');
    } catch (e) {
      debugPrint('❌ Mesaj gönderilemedi: $e');
      rethrow;
    }
  }

  // Mesajı sil (sadece kendi mesajları)
  Future<void> deleteMessage(String messageId) async {
    if (!_authService.isSignedIn) return;

    try {
      final firestore = await this.firestore;
      final messageDoc = await firestore
          .collection('chats')
          .doc(_generalChatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (messageDoc.exists && 
          messageDoc.data()?['senderId'] == _authService.userId) {
        await messageDoc.reference.delete();
        debugPrint('✅ Mesaj silindi: $messageId');
      }
    } catch (e) {
      debugPrint('❌ Mesaj silinemedi: $e');
    }
  }
}
