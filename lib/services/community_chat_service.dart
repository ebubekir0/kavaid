import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'admin_service.dart';

class CommunityChatService {
  static final CommunityChatService _instance = CommunityChatService._internal();
  factory CommunityChatService() => _instance;
  CommunityChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminService _adminService = AdminService();

  // Mesajları dinle (gerçek zamanlı)
  Stream<List<ChatMessage>> getMessages({int limit = 50}) {
    try {
      
      return _firestore
          .collection('community_chat')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        
        final messages = snapshot.docs.map((doc) {
          final data = doc.data();
          return ChatMessage.fromMap(data, doc.id);
        }).toList();
        
        return messages;
      });
    } catch (e) {
      // Hata durumunda boş liste döndür
      return Stream.value(<ChatMessage>[]);
    }
  }

  // Mesaj gönder
  Future<bool> sendMessage(String message) async {
    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        return false;
      }

      print('📝 [CHAT] Mesaj gönderiliyor: "${message.trim()}"');

      // Kullanıcı bilgilerini al
      Map<String, dynamic> userData = {};
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        userData = userDoc.data() ?? {};
        
        // Kullanıcı adı var mı kontrol et
        final username = userData['username'] as String?;
        if (username == null || username.isEmpty) {
          print('❌ [CHAT] Kullanıcı adı yok, mesaj gönderemez');
          return false;
        }
        
        // Engellenmiş mi kontrol et
        final banned = userData['banned'] as bool?;
        if (banned == true) {
          print('🚫 [CHAT] Kullanıcı engellenmiş, mesaj gönderemez');
          return false;
        }
        
        // Susturulmuş mu kontrol et
        final mutedUntil = userData['mutedUntil'] as Timestamp?;
        if (mutedUntil != null) {
          final now = DateTime.now();
          final muteEnd = mutedUntil.toDate();
          if (now.isBefore(muteEnd)) {
            final remaining = muteEnd.difference(now);
            print('🔇 [CHAT] Kullanıcı susturulmuş, kalan süre: ${remaining.inMinutes} dakika');
            return false;
          }
        }
        
      } catch (e) {
        print('⚠️ [CHAT] Kullanıcı bilgisi alınamadı: $e');
      }

      // Profil resmini al (önce Firestore, sonra Auth)
      String? photoUrl;
      try {
        photoUrl = userData['photoUrl'] as String?;
      } catch (e) {
        photoUrl = null;
      }
      photoUrl ??= user.photoURL;

      final messageData = {
        'message': message.trim(),
        'userId': user.uid,
        'userName': userData['username'] ?? 'Kullanıcı', // Sadece username kullan
        'photoUrl': photoUrl,
        // Yerel saat ile hemen gösterim için
        'clientSentAt': Timestamp.fromDate(DateTime.now()),
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': false,
      };

      await _firestore.collection('community_chat').add(messageData);

      return true;
    } catch (e) {
      print('❌ [CHAT] Mesaj gönderme hatası: $e');
      print('❌ [CHAT] Hata detayı: ${e.toString()}');
      return false;
    }
  }

  // Mesajı sil (sadece kendi mesajını silebilir)
  Future<bool> deleteMessage(String messageId, {bool isMultipleDelete = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ [CHAT_SERVICE] Kullanıcı giriş yapmamış');
        return false;
      }

      final messageDoc = await _firestore
          .collection('community_chat')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        print('❌ [CHAT_SERVICE] Mesaj bulunamadı');
        return false;
      }

      final messageData = messageDoc.data()!;
      
      // Admin veya moderatör mü kontrol et
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final role = userDoc.data()?['role'] as String?;
      final isFounder = user.email?.toLowerCase() == 'ebubekir@gmail.com';
      final isModerator = role == 'moderator';
      
      // Mesajın sahibi kurucuysa ve mevcut kullanıcı moderatörse silmeyi engelle
      final messageOwnerDoc = await _firestore.collection('users').doc(messageData['userId']).get();
      final messageOwnerEmail = messageOwnerDoc.data()?['email'] as String? ?? '';
      final isMessageFromFounder = messageOwnerEmail.toLowerCase() == 'ebubekir@gmail.com';
      
      if (isMessageFromFounder && isModerator && !isFounder) {
        print('❌ [CHAT_SERVICE] Moderatör kurucunun mesajını silemez');
        return false;
      }
      
      // Kendi mesajı DEĞİLSE ve yönetici/moderatör DEĞİLSE silemesin
      if (messageData['userId'] != user.uid && !isFounder && !isModerator) {
        print('❌ [CHAT_SERVICE] Yetkisiz silme denemesi');
        return false;
      }

      print('🗑️ [CHAT_SERVICE] Mesaj siliniyor: $messageId');
      print('📝 [CHAT_SERVICE] Mesaj içeriği: ${messageData['message']}');
      
      // Soft delete - Mesajı silindi olarak işaretle
      await _firestore
          .collection('community_chat')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': user.uid, // Kim sildi
      });
      
      // Admin log kaydet
      await _adminService.logMessageDeletion(
        messageId: messageId,
        messageContent: messageData['message'] ?? '',
        messageOwnerId: messageData['userId'] ?? '',
        deletedBy: user.uid,
        isMultipleDelete: isMultipleDelete,
      );

      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Tüm mesajları sil (Sadece kurucu)
  Future<bool> deleteAllMessages() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ [CHAT_SERVICE] Kullanıcı giriş yapmamış');
        return false;
      }

      // Sadece kurucu kontrolü
      final isFounder = user.email?.toLowerCase() == 'ebubekir@gmail.com';
      
      if (!isFounder) {
        print('❌ [CHAT_SERVICE] Sadece kurucu tüm mesajları silebilir');
        return false;
      }

      print('🧹 [CHAT_SERVICE] Tüm mesajlar siliniyor...');
      
      // Tüm mesajları al
      final querySnapshot = await _firestore
          .collection('community_chat')
          .get();
      
      // Batch write ile tüm mesajları sil
      final batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Kullanıcı giriş yapmış mı kontrol et
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Daha fazla mesaj yükle (pagination için)
  Future<List<ChatMessage>> loadMoreMessages({
    required DocumentSnapshot lastDocument,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('community_chat')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(lastDocument)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Daha fazla mesaj yükleme hatası: $e');
      return [];
    }
  }

  // Online kullanıcı sayısını güncelle
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Online durum güncelleme hatası: $e');
    }
  }

  // Online kullanıcı sayısını al
  Stream<int> getOnlineUsersCount() {
    return _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
