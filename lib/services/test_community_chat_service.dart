import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'admin_service.dart';

/// Test Topluluk Chat Servisi
/// Sadece kurucu (ebubekir@gmail.com) ve trabzon@gmail.com hesapları için
class TestCommunityChatService {
  static final TestCommunityChatService _instance = TestCommunityChatService._internal();
  factory TestCommunityChatService() => _instance;
  TestCommunityChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminService _adminService = AdminService();

  // Test topluluk için ayrı collection
  static const String _collectionName = 'test_community_chat';
  static const String _readCollectionName = 'test_message_reads';
  static const String _notificationCollectionName = 'test_community_notifications';

  /// Bu hesap test topluluğa erişebilir mi kontrol et
  bool canAccessTestCommunity() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final email = user.email?.toLowerCase() ?? '';
    return email == 'ebubekir@gmail.com' || email == 'trabzon@gmail.com';
  }

  /// Kurucu mu kontrol et
  bool isFounder() {
    final user = _auth.currentUser;
    return user?.email?.toLowerCase() == 'ebubekir@gmail.com';
  }

  /// Mesajları dinle (gerçek zamanlı)
  Stream<List<ChatMessage>> getMessages({int limit = 100}) {
    if (!canAccessTestCommunity()) {
      return Stream.value(<ChatMessage>[]);
    }

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

  /// Mesaj gönder
  Future<bool> sendMessage(String message, {
    Map<String, dynamic>? sharedWordList,
    String? replyToId,
    String? replyToUserName,
    String? replyToMessage,
    String? replyToUserId, // Yanıtlanan kullanıcının ID'si
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !canAccessTestCommunity()) {
        return false;
      }

      // Kullanıcı bilgilerini al
      Map<String, dynamic> userData = {};
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        userData = userDoc.data() ?? {};
      } catch (e) {
        debugPrint('⚠️ [TEST_CHAT] Kullanıcı bilgisi alınamadı: $e');
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
        'hasEveryoneTag': hasEveryoneTag, // @herkes etiketi var mı
        // Kelime listesi paylaşımı için
        if (sharedWordList != null) 'sharedWordList': sharedWordList,
        // Reply için
        if (replyToId != null) 'replyToId': replyToId,
        if (replyToUserName != null) 'replyToUserName': replyToUserName,
        if (replyToMessage != null) 'replyToMessage': replyToMessage,
        if (replyToUserId != null) 'replyToUserId': replyToUserId,
      };

      final docRef = await _firestore.collection(_collectionName).add(messageData);
      debugPrint('✅ [TEST_CHAT] Mesaj gönderildi');
      
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
      debugPrint('❌ [TEST_CHAT] Mesaj gönderme hatası: $e');
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
    
    // Tüm kullanıcıları çek (performans için cache eklenebilir)
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
    debugPrint('🔔 [NOTIF] _createNotifications çağrıldı');
    debugPrint('🔔 [NOTIF] replyToUserId: $replyToUserId');
    debugPrint('🔔 [NOTIF] mentionedUserIds: $mentionedUserIds');
    debugPrint('🔔 [NOTIF] senderId: $senderId');
    debugPrint('🔔 [NOTIF] hasEveryoneTag: $hasEveryoneTag');
    
    // Bildirim gönderilen kullanıcıları takip et (çift bildirim önleme)
    final notifiedUsers = <String>{};
    
    try {
      // @herkes etiketi varsa tüm kullanıcılara bildirim gönder
      if (hasEveryoneTag) {
        // Tüm kullanıcıları bul (test community'ye erişimi olanlar)
        final usersSnapshot = await _firestore.collection('users').get();
        
        for (final userDoc in usersSnapshot.docs) {
          final userId = userDoc.id;
          if (userId == senderId) continue; // Kendine bildirim gönderme
          
          await _firestore.collection(_notificationCollectionName).add({
            'userId': userId,
            'messageId': messageId,
            'senderId': senderId,
            'senderName': senderName,
            'type': 'everyone', // @herkes bildirimi
            'messagePreview': messageText.length > 50 
                ? '${messageText.substring(0, 50)}...' 
                : messageText,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          notifiedUsers.add(userId);
        }
        debugPrint('📢 [TEST_CHAT] @herkes bildirimi gönderildi');
      }
      
      // @kullanıcıadı mention bildirimleri
      if (mentionedUserIds != null && mentionedUserIds.isNotEmpty) {
        for (final mentionedUserId in mentionedUserIds) {
          // Zaten bildirim gönderilmişse atla
          if (notifiedUsers.contains(mentionedUserId)) continue;
          
          debugPrint('📌 [NOTIF] Mention bildirimi oluşturuluyor: $mentionedUserId');
          await _firestore.collection(_notificationCollectionName).add({
            'userId': mentionedUserId,
            'messageId': messageId,
            'senderId': senderId,
            'senderName': senderName,
            'type': 'mention', // @kullanıcıadı bildirimi
            'messagePreview': messageText.length > 50 
                ? '${messageText.substring(0, 50)}...' 
                : messageText,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          notifiedUsers.add(mentionedUserId);
          debugPrint('✅ [NOTIF] Mention bildirimi Firestore\'a yazıldı!');
        }
      }
      
      // Reply bildirimi (yanıtlanan kişiye)
      if (replyToUserId != null && replyToUserId.isNotEmpty && replyToUserId != senderId) {
        // Zaten bildirim gönderilmişse atla
        if (!notifiedUsers.contains(replyToUserId)) {
          debugPrint('💬 [NOTIF] Reply bildirimi oluşturuluyor: $replyToUserId');
          await _firestore.collection(_notificationCollectionName).add({
            'userId': replyToUserId,
            'messageId': messageId,
            'senderId': senderId,
            'senderName': senderName,
            'type': 'reply', // Yanıt bildirimi
            'messagePreview': messageText.length > 50 
                ? '${messageText.substring(0, 50)}...' 
                : messageText,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ [NOTIF] Reply bildirimi Firestore\'a yazıldı!');
        } else {
          debugPrint('⚠️ [NOTIF] Reply bildirimi atlandı - zaten mention ile bildirildi');
        }
      } else if (replyToUserId == null || replyToUserId.isEmpty) {
        debugPrint('⚠️ [NOTIF] Reply bildirimi OLUŞTURULMADI - replyToUserId: $replyToUserId');
      }
    } catch (e) {
      debugPrint('❌ [TEST_CHAT] Bildirim oluşturma hatası: $e');
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
      debugPrint('✅ [TEST_CHAT] Bildirimler okundu olarak işaretlendi');
    } catch (e) {
      debugPrint('❌ [TEST_CHAT] Bildirim işaretleme hatası: $e');
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
      '📚 Kelime Listesi Paylaşıldı: $listName ($words.length kelime)',
      sharedWordList: sharedData,
    );
  }

  /// Mesajı sil
  Future<bool> deleteMessage(String messageId, {bool isMultipleDelete = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !canAccessTestCommunity()) return false;

      final messageDoc = await _firestore.collection(_collectionName).doc(messageId).get();
      if (!messageDoc.exists) return false;

      final messageData = messageDoc.data()!;
      
      // Sadece kendi mesajını veya kurucu tüm mesajları silebilir
      if (messageData['userId'] != user.uid && !isFounder()) {
        return false;
      }

      await _firestore.collection(_collectionName).doc(messageId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': user.uid,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Tüm mesajları sil (Sadece kurucu)
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

  // Okunmuş mesajları cache'le (çift kayıt önleme)
  static final Set<String> _markedAsRead = {};

  /// Mesajın okunduğunu kaydet (mesaj sahibi hariç)
  Future<void> markMessageAsRead(String messageId, {String? messageOwnerId}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || !canAccessTestCommunity()) return;
    
    // Mesaj sahibi kendi mesajını okuduysa kaydetme
    if (messageOwnerId != null && messageOwnerId == currentUser.uid) return;

    // Local cache kontrolü - aynı oturumda tekrar kaydetme
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
      
      // Cache'e ekle
      _markedAsRead.add(cacheKey);
    } catch (e) {
      debugPrint('❌ [TEST_CHAT] Mesaj okuma kayıt hatası: $e');
    }
  }

  /// Çift kayıtları temizle (bir kerelik)
  Future<void> cleanupDuplicateReads() async {
    if (!isFounder()) return;
    
    try {
      final allReads = await _firestore.collection(_readCollectionName).get();
      
      // userId + messageId kombinasyonlarını takip et
      final Map<String, String> seen = {}; // key: combo, value: docId
      final List<String> toDelete = [];
      
      for (final doc in allReads.docs) {
        final data = doc.data();
        final combo = '${data['userId']}_${data['messageId']}';
        
        if (seen.containsKey(combo)) {
          // Duplicate - sil
          toDelete.add(doc.id);
        } else {
          seen[combo] = doc.id;
        }
      }
      
      // Duplicate'ları sil
      for (final docId in toDelete) {
        await _firestore.collection(_readCollectionName).doc(docId).delete();
      }
      
      debugPrint('🧹 [TEST_CHAT] ${toDelete.length} duplicate kayıt silindi');
    } catch (e) {
      debugPrint('❌ [TEST_CHAT] Cleanup hatası: $e');
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
    if (!isFounder()) {
      debugPrint('❌ [TEST_CHAT] getMessageReaders: Kurucu değil');
      return [];
    }

    final currentUserId = _auth.currentUser?.uid;

    try {
      debugPrint('🔍 [TEST_CHAT] getMessageReaders çağrıldı: $messageId');
      
      // orderBy kaldırıldı - composite index sorununu önlemek için
      final snapshot = await _firestore
          .collection(_readCollectionName)
          .where('messageId', isEqualTo: messageId)
          .get();

      debugPrint('📊 [TEST_CHAT] Bulunan okuma sayısı: ${snapshot.docs.length}');

      List<Map<String, dynamic>> readers = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final userEmail = data['userEmail'] as String?;
        
        // Kendini hariç tut (mesaj sahibi)
        if (userId == currentUserId) continue;
        
        debugPrint('👤 [TEST_CHAT] Okuyucu: $userEmail');
        
        // Kullanıcı bilgilerini al
        String? username;
        if (userId != null) {
          try {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            username = userDoc.data()?['username'] as String?;
          } catch (e) {
            debugPrint('⚠️ [TEST_CHAT] Kullanıcı bilgisi alınamadı: $e');
          }
        }
        
        readers.add({
          'userId': userId,
          'userEmail': userEmail ?? 'Bilinmiyor',
          'username': username ?? userEmail?.split('@').first ?? 'Bilinmiyor',
          'readAt': data['readAt'] as Timestamp?,
        });
      }
      
      // En son okuyanlar üstte olacak şekilde sırala (client-side)
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
      debugPrint('❌ [TEST_CHAT] Okuyucu listesi alma hatası: $e');
      return [];
    }
  }

  /// Kullanıcı giriş yapmış mı kontrol et
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Online durumunu güncelle
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [TEST_CHAT] Online durum güncelleme hatası: $e');
    }
  }
}
