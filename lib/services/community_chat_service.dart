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

  // Collection isimleri
  static const String _collectionName = 'community_chat';
  static const String _readCollectionName = 'message_reads';
  static const String _notificationCollectionName = 'community_notifications';

  /// Kurucu mu kontrol et
  bool isFounder() {
    final user = _auth.currentUser;
    return user?.email?.toLowerCase() == 'ebubekir@gmail.com';
  }

  /// Test topluluk erişimi - artık kullanılmıyor, geriye uyumluluk için false döner
  bool canAccessTestCommunity() {
    return false; // Test topluluk sekmesi kaldırıldı
  }

  // Mesajları dinle (gerçek zamanlı)
  Stream<List<ChatMessage>> getMessages({int limit = 100}) {
    try {
      return _firestore
          .collection(_collectionName)
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
      return Stream.value(<ChatMessage>[]);
    }
  }

  /// Mesaj gönder - Reply, mention, kelime listesi paylaşımı destekli
  Future<bool> sendMessage(String message, {
    Map<String, dynamic>? sharedWordList,
    String? replyToId,
    String? replyToUserName,
    String? replyToMessage,
    String? replyToUserId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      debugPrint('📝 [CHAT] Mesaj gönderiliyor: "${message.trim()}"');

      // Kullanıcı bilgilerini al
      Map<String, dynamic> userData = {};
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        userData = userDoc.data() ?? {};
        
        // Kullanıcı adı var mı kontrol et
        final username = userData['username'] as String?;
        if (username == null || username.isEmpty) {
          debugPrint('❌ [CHAT] Kullanıcı adı yok, mesaj gönderemez');
          return false;
        }
        
        // Engellenmiş mi kontrol et
        final banned = userData['banned'] as bool?;
        if (banned == true) {
          debugPrint('🚫 [CHAT] Kullanıcı engellenmiş, mesaj gönderemez');
          return false;
        }
        
        // Susturulmuş mu kontrol et
        final mutedUntil = userData['mutedUntil'] as Timestamp?;
        if (mutedUntil != null) {
          final now = DateTime.now();
          final muteEnd = mutedUntil.toDate();
          if (now.isBefore(muteEnd)) {
            final remaining = muteEnd.difference(now);
            debugPrint('🔇 [CHAT] Kullanıcı susturulmuş, kalan süre: ${remaining.inMinutes} dakika');
            return false;
          }
        }
      } catch (e) {
        debugPrint('⚠️ [CHAT] Kullanıcı bilgisi alınamadı: $e');
      }

      String? photoUrl = userData['photoUrl'] as String? ?? user.photoURL;
      final userName = userData['username'] ?? 'Kullanıcı';
      
      // @herkes etiketi kontrolü (sadece kurucu için)
      final hasEveryoneTag = message.contains('@herkes') && isFounder();
      
      // @kullanıcıadı mention'larını tespit et
      final mentionedUserIds = await _findMentionedUsers(message, user.uid);

      final messageData = {
        'message': message.trim(),
        'userId': user.uid,
        'userName': userName,
        'photoUrl': photoUrl,
        'clientSentAt': Timestamp.fromDate(DateTime.now()),
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'hasEveryoneTag': hasEveryoneTag,
        // Kelime listesi paylaşımı için
        if (sharedWordList != null) 'sharedWordList': sharedWordList,
        // Reply için
        if (replyToId != null) 'replyToId': replyToId,
        if (replyToUserName != null) 'replyToUserName': replyToUserName,
        if (replyToMessage != null) 'replyToMessage': replyToMessage,
        if (replyToUserId != null) 'replyToUserId': replyToUserId,
      };

      final docRef = await _firestore.collection(_collectionName).add(messageData);
      debugPrint('✅ [CHAT] Mesaj gönderildi');
      
      // Bildirim oluştur
      await _createNotifications(
        messageId: docRef.id,
        senderId: user.uid,
        senderName: userName,
        messageText: message.trim(),
        hasEveryoneTag: hasEveryoneTag,
        replyToUserId: replyToUserId,
        mentionedUserIds: mentionedUserIds,
      );

      return true;
    } catch (e) {
      debugPrint('❌ [CHAT] Mesaj gönderme hatası: $e');
      return false;
    }
  }

  /// Mesajda mention edilen kullanıcıları bul
  Future<List<String>> _findMentionedUsers(String message, String senderId) async {
    final mentionedUserIds = <String>[];
    
    // @kullanıcıadı pattern'ini bul (Türkçe karakterler dahil)
    final mentionPattern = RegExp(r'@([a-zA-Z0-9_çğıöşüÇĞİÖŞÜ]+)');
    final matches = mentionPattern.allMatches(message);
    
    if (matches.isEmpty) return mentionedUserIds;
    
    // Tüm kullanıcıları çek
    final usersSnapshot = await _firestore.collection('users').get();
    
    for (final match in matches) {
      final mentionedUsername = match.group(1)?.toLowerCase();
      if (mentionedUsername == null || mentionedUsername == 'herkes') continue;
      
      // Bu username'e sahip kullanıcıyı bul
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final username = (userData['username'] as String?)?.toLowerCase();
        
        if (username == mentionedUsername && userDoc.id != senderId) {
          if (!mentionedUserIds.contains(userDoc.id)) {
            mentionedUserIds.add(userDoc.id);
            debugPrint('📌 [MENTION] Kullanıcı bulundu: @$mentionedUsername -> ${userDoc.id}');
          }
          break;
        }
      }
    }
    
    return mentionedUserIds;
  }

  /// Bildirim oluştur
  Future<void> _createNotifications({
    required String messageId,
    required String senderId,
    required String senderName,
    required String messageText,
    required bool hasEveryoneTag,
    String? replyToUserId,
    List<String>? mentionedUserIds,
  }) async {
    final notifiedUsers = <String>{};
    
    try {
      // @herkes etiketi varsa tüm kullanıcılara bildirim gönder
      if (hasEveryoneTag) {
        final usersSnapshot = await _firestore.collection('users').get();
        
        for (final userDoc in usersSnapshot.docs) {
          final userId = userDoc.id;
          if (userId == senderId) continue;
          
          await _firestore.collection(_notificationCollectionName).add({
            'userId': userId,
            'messageId': messageId,
            'senderId': senderId,
            'senderName': senderName,
            'type': 'everyone',
            'messagePreview': messageText.length > 50 
                ? '${messageText.substring(0, 50)}...' 
                : messageText,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          notifiedUsers.add(userId);
        }
        debugPrint('📢 [CHAT] @herkes bildirimi gönderildi');
      }
      
      // @kullanıcıadı mention bildirimleri
      if (mentionedUserIds != null && mentionedUserIds.isNotEmpty) {
        for (final mentionedUserId in mentionedUserIds) {
          if (notifiedUsers.contains(mentionedUserId)) continue;
          
          await _firestore.collection(_notificationCollectionName).add({
            'userId': mentionedUserId,
            'messageId': messageId,
            'senderId': senderId,
            'senderName': senderName,
            'type': 'mention',
            'messagePreview': messageText.length > 50 
                ? '${messageText.substring(0, 50)}...' 
                : messageText,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          notifiedUsers.add(mentionedUserId);
        }
      }
      
      // Reply bildirimi
      if (replyToUserId != null && replyToUserId.isNotEmpty && replyToUserId != senderId) {
        if (!notifiedUsers.contains(replyToUserId)) {
          await _firestore.collection(_notificationCollectionName).add({
            'userId': replyToUserId,
            'messageId': messageId,
            'senderId': senderId,
            'senderName': senderName,
            'type': 'reply',
            'messagePreview': messageText.length > 50 
                ? '${messageText.substring(0, 50)}...' 
                : messageText,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [CHAT] Bildirim oluşturma hatası: $e');
    }
  }

  /// Okunmamış bildirim sayısını al (Stream)
  Stream<int> getUnreadNotificationCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);
    
    return _firestore
        .collection(_notificationCollectionName)
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllNotificationsAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final snapshot = await _firestore
          .collection(_notificationCollectionName)
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [CHAT] Bildirim işaretleme hatası: $e');
    }
  }

  /// Kelime listesi paylaş
  Future<bool> shareWordList({
    required String listId,
    required String listName,
    required List<Map<String, String>> words,
  }) async {
    final sharedData = {
      'listId': listId,
      'listName': listName,
      'wordCount': words.length,
      'words': words,
      'sharedAt': FieldValue.serverTimestamp(),
    };

    return sendMessage(
      '📚 Kelime Listesi Paylaşıldı: $listName (${words.length} kelime)',
      sharedWordList: sharedData,
    );
  }

  // Mesajı sil
  Future<bool> deleteMessage(String messageId, {bool isMultipleDelete = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final messageDoc = await _firestore.collection(_collectionName).doc(messageId).get();
      if (!messageDoc.exists) return false;

      final messageData = messageDoc.data()!;
      
      // Admin/moderatör kontrolü
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final role = userDoc.data()?['role'] as String?;
      final founder = isFounder();
      final isModerator = role == 'moderator';
      
      // Mesaj sahibi kurucu ve silmeye çalışan moderatörse engelle
      final messageOwnerDoc = await _firestore.collection('users').doc(messageData['userId']).get();
      final messageOwnerEmail = messageOwnerDoc.data()?['email'] as String? ?? '';
      final isMessageFromFounder = messageOwnerEmail.toLowerCase() == 'ebubekir@gmail.com';
      
      if (isMessageFromFounder && isModerator && !founder) {
        return false;
      }
      
      // Kendi mesajı DEĞİLSE ve yönetici DEĞİLSE silemesin
      if (messageData['userId'] != user.uid && !founder && !isModerator) {
        return false;
      }

      await _firestore.collection(_collectionName).doc(messageId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': user.uid,
      });
      
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
      if (!isFounder()) return false;

      final querySnapshot = await _firestore.collection(_collectionName).get();
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

  // ==================== OKUNMA TAKİBİ ====================

  static final Set<String> _markedAsRead = {};

  /// Mesajın okunduğunu kaydet
  Future<void> markMessageAsRead(String messageId, {String? messageOwnerId}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    // Mesaj sahibi kendi mesajını okuduysa kaydetme
    if (messageOwnerId != null && messageOwnerId == currentUser.uid) return;

    final cacheKey = '${currentUser.uid}_$messageId';
    if (_markedAsRead.contains(cacheKey)) return;

    try {
      final existingRead = await _firestore
          .collection(_readCollectionName)
          .where('messageId', isEqualTo: messageId)
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (existingRead.docs.isEmpty) {
        await _firestore.collection(_readCollectionName).add({
          'messageId': messageId,
          'userId': currentUser.uid,
          'userEmail': currentUser.email,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      _markedAsRead.add(cacheKey);
    } catch (e) {
      debugPrint('❌ [CHAT] Mesaj okuma kayıt hatası: $e');
    }
  }

  /// Çift kayıtları temizle (kurucu için)
  Future<void> cleanupDuplicateReads() async {
    if (!isFounder()) return;
    
    try {
      final allReads = await _firestore.collection(_readCollectionName).get();
      
      final Map<String, String> seen = {};
      final List<String> toDelete = [];
      
      for (final doc in allReads.docs) {
        final data = doc.data();
        final combo = '${data['userId']}_${data['messageId']}';
        
        if (seen.containsKey(combo)) {
          toDelete.add(doc.id);
        } else {
          seen[combo] = doc.id;
        }
      }
      
      for (final docId in toDelete) {
        await _firestore.collection(_readCollectionName).doc(docId).delete();
      }
      
      debugPrint('🧹 [CHAT] ${toDelete.length} duplicate kayıt silindi');
    } catch (e) {
      debugPrint('❌ [CHAT] Cleanup hatası: $e');
    }
  }

  /// Mesajı okuyan kullanıcı sayısını al (Stream)
  Stream<int> watchReadCount(String messageId) {
    return _firestore
        .collection(_readCollectionName)
        .where('messageId', isEqualTo: messageId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mesajı okuyan kullanıcıları al (Sadece kurucu için)
  Future<List<Map<String, dynamic>>> getMessageReaders(String messageId) async {
    if (!isFounder()) return [];

    final currentUserId = _auth.currentUser?.uid;

    try {
      final snapshot = await _firestore
          .collection(_readCollectionName)
          .where('messageId', isEqualTo: messageId)
          .get();

      List<Map<String, dynamic>> readers = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final userEmail = data['userEmail'] as String?;
        
        if (userId == currentUserId) continue;
        
        String? username;
        if (userId != null) {
          try {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            username = userDoc.data()?['username'] as String?;
          } catch (e) {
            debugPrint('⚠️ [CHAT] Kullanıcı bilgisi alınamadı: $e');
          }
        }
        
        readers.add({
          'userId': userId,
          'userEmail': userEmail ?? 'Bilinmiyor',
          'username': username ?? userEmail?.split('@').first ?? 'Bilinmiyor',
          'readAt': data['readAt'] as Timestamp?,
        });
      }
      
      readers.sort((a, b) {
        final aTime = a['readAt'] as Timestamp?;
        final bTime = b['readAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return readers;
    } catch (e) {
      debugPrint('❌ [CHAT] Okuyucu listesi alma hatası: $e');
      return [];
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
          .collection(_collectionName)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(lastDocument)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Daha fazla mesaj yükleme hatası: $e');
      return [];
    }
  }

  // Online durumunu güncelle
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Online durum güncelleme hatası: $e');
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
