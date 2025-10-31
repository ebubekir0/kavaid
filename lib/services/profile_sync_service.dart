import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ProfileSyncService {
  static final ProfileSyncService _instance = ProfileSyncService._internal();
  factory ProfileSyncService() => _instance;
  ProfileSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcı profil resmi güncellendiğinde tüm mesajlarındaki profil resmini güncelle
  Future<void> updateUserPhotoInMessages(String userId, String newPhotoUrl) async {
    try {
      debugPrint('🔄 [ProfileSync] Kullanıcının mesajlarındaki profil resmi güncelleniyor...');

      // Community chat mesajlarını güncelle
      final batch = _firestore.batch();
      
      // Kullanıcının tüm mesajlarını bul
      final messagesQuery = await _firestore
          .collection('community_chat')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('📨 [ProfileSync] ${messagesQuery.docs.length} mesaj bulundu');

      // Her mesajı güncelle
      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'userPhotoUrl': newPhotoUrl,
          'photoUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Batch'i commit et
      await batch.commit();
      
      debugPrint('✅ [ProfileSync] ${messagesQuery.docs.length} mesaj güncellendi');
      
    } catch (e) {
      debugPrint('❌ [ProfileSync] Mesaj güncelleme hatası: $e');
    }
  }

  /// Kullanıcı adı güncellendiğinde tüm mesajlarındaki kullanıcı adını güncelle
  Future<void> updateUsernameInMessages(String userId, String newUsername) async {
    try {
      debugPrint('🔄 [ProfileSync] Kullanıcının mesajlarındaki kullanıcı adı güncelleniyor...');

      // Community chat mesajlarını güncelle
      final batch = _firestore.batch();
      
      // Kullanıcının tüm mesajlarını bul
      final messagesQuery = await _firestore
          .collection('community_chat')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('📨 [ProfileSync] ${messagesQuery.docs.length} mesaj bulundu');

      // Her mesajı güncelle
      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {
          'userName': newUsername,
          'usernameUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Batch'i commit et
      await batch.commit();
      
      debugPrint('✅ [ProfileSync] ${messagesQuery.docs.length} mesajdaki kullanıcı adı güncellendi');
      
    } catch (e) {
      debugPrint('❌ [ProfileSync] Kullanıcı adı güncelleme hatası: $e');
    }
  }

  /// Kullanıcı profilindeki değişiklikleri dinle ve mesajları otomatik güncelle
  void startListeningToProfileChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      // Son güncelleme zamanlarını kontrol et
      final photoUpdatedAt = data['photoUpdatedAt'] as Timestamp?;
      final usernameUpdatedAt = data['usernameUpdatedAt'] as Timestamp?;

      // Son 10 saniye içinde güncellenmişse mesajları da güncelle
      final now = DateTime.now();
      final tenSecondsAgo = now.subtract(const Duration(seconds: 10));

      // Profil resmi güncellenmişse
      if (photoUpdatedAt != null && 
          photoUpdatedAt.toDate().isAfter(tenSecondsAgo)) {
        final photoUrl = data['photoUrl'] as String?;
        if (photoUrl != null && photoUrl.isNotEmpty) {
          await updateUserPhotoInMessages(user.uid, photoUrl);
        }
      }

      // Kullanıcı adı güncellenmişse
      if (usernameUpdatedAt != null && 
          usernameUpdatedAt.toDate().isAfter(tenSecondsAgo)) {
        final username = data['username'] as String?;
        if (username != null && username.isNotEmpty) {
          await updateUsernameInMessages(user.uid, username);
        }
      }
    });
  }
}
