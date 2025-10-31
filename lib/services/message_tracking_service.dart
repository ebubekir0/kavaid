import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageTrackingService {
  static final MessageTrackingService _instance = MessageTrackingService._internal();
  factory MessageTrackingService() => _instance;
  MessageTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mesajın okunduğunu kaydet
  Future<void> markMessageAsRead(String messageId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Kullanıcının bu mesajı daha önce okuyup okumadığını kontrol et
      final existingRead = await _firestore
          .collection('message_reads')
          .where('messageId', isEqualTo: messageId)
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      // Eğer daha önce okumamışsa kaydet
      if (existingRead.docs.isEmpty) {
        await _firestore.collection('message_reads').add({
          'messageId': messageId,
          'userId': currentUser.uid,
          'readAt': FieldValue.serverTimestamp(),
          'userEmail': currentUser.email,
        });

        print('👁️ [MessageTracking] Mesaj okundu: $messageId by ${currentUser.uid}');
      }
    } catch (e) {
      print('❌ [MessageTracking] Mesaj okuma kayıt hatası: $e');
    }
  }

  /// Belirli bir mesajı okuyan kullanıcı sayısını al
  Future<int> getReadCount(String messageId) async {
    try {
      final snapshot = await _firestore
          .collection('message_reads')
          .where('messageId', isEqualTo: messageId)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('❌ [MessageTracking] Okuma sayısı alma hatası: $e');
      return 0;
    }
  }

  /// Belirli bir mesajı okuyan kullanıcıları al
  Future<List<Map<String, dynamic>>> getMessageReaders(String messageId) async {
    try {
      final snapshot = await _firestore
          .collection('message_reads')
          .where('messageId', isEqualTo: messageId)
          .orderBy('readAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'],
          'userEmail': data['userEmail'],
          'readAt': data['readAt'] as Timestamp?,
        };
      }).toList();
    } catch (e) {
      print('❌ [MessageTracking] Okuyucu listesi alma hatası: $e');
      return [];
    }
  }

  /// Belirli bir kullanıcının mesajlarının toplam okuma sayılarını al
  Future<Map<String, int>> getUserMessageReadCounts(String userId) async {
    try {
      // Kullanıcının mesajlarını al
      final messagesSnapshot = await _firestore
          .collection('community_chat')
          .where('userId', isEqualTo: userId)
          .get();

      Map<String, int> readCounts = {};
      
      for (final messageDoc in messagesSnapshot.docs) {
        final messageId = messageDoc.id;
        final count = await getReadCount(messageId);
        readCounts[messageId] = count;
      }

      return readCounts;
    } catch (e) {
      print('❌ [MessageTracking] Kullanıcı mesaj okuma sayıları alma hatası: $e');
      return {};
    }
  }

  /// Mesajları okuma sayısı stream'i ile dinle
  Stream<int> watchReadCount(String messageId) {
    return _firestore
        .collection('message_reads')
        .where('messageId', isEqualTo: messageId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Kullanıcının okunmamış mesaj sayısını al (opsiyonel özellik)
  Future<int> getUnreadMessagesCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    try {
      // Tüm mesajları al
      final allMessagesSnapshot = await _firestore
          .collection('community_chat')
          .get();
      
      final totalMessages = allMessagesSnapshot.docs.length;

      // Kullanıcının okuduğu mesajları al
      final readMessagesSnapshot = await _firestore
          .collection('message_reads')
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      
      final readMessages = readMessagesSnapshot.docs.length;

      return totalMessages - readMessages;
    } catch (e) {
      print('❌ [MessageTracking] Okunmamış mesaj sayısı alma hatası: $e');
      return 0;
    }
  }

  /// Kullanıcının son aktiflik zamanını güncelle (online tracking için)
  Future<void> updateUserLastSeen() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ [MessageTracking] Son görülme güncelleme hatası: $e');
    }
  }

  /// Kullanıcı adı seçme zamanını kaydet
  Future<void> recordUsernameSelection(String username) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'username': username,
        'usernameSetAt': FieldValue.serverTimestamp(),
      });

      print('🏷️ [MessageTracking] Kullanıcı adı kaydedildi: $username');
    } catch (e) {
      print('❌ [MessageTracking] Kullanıcı adı kayıt hatası: $e');
    }
  }
}
