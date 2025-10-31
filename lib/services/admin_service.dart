import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Kurucu email
  static const String FOUNDER_EMAIL = 'ebubekir@gmail.com';
  
  // Cache
  final Map<String, String> _userRoleCache = {}; // userId -> role
  bool _chatEnabled = true;
  
  // Kullanıcı kurucu mu kontrol et
  bool isFounder() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.email?.toLowerCase() == FOUNDER_EMAIL.toLowerCase();
  }
  
  // Geriye uyumluluk için admin kontrolü (kurucu olarak)
  bool isAdmin() {
    return isFounder();
  }
  
  // Kullanıcı moderatör mü kontrol et
  Future<bool> isModerator(String userId) async {
    // Cache'de varsa kullan
    if (_userRoleCache.containsKey(userId)) {
      return _userRoleCache[userId] == 'moderator';
    }
    
    // Firestore'dan kontrol et
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final role = doc.data()?['role'] as String?;
      _userRoleCache[userId] = role ?? 'user';
      return role == 'moderator';
    } catch (e) {
      return false;
    }
  }
  
  // Kullanıcının rolünü al
  Future<String> getUserRole(String userId) async {
    // Kurucu kontrolü
    final user = await _firestore.collection('users').doc(userId).get();
    final userEmail = user.data()?['email'] as String?;
    if (userEmail?.toLowerCase() == FOUNDER_EMAIL.toLowerCase()) {
      return 'founder';
    }
    
    // Cache'de varsa kullan
    if (_userRoleCache.containsKey(userId)) {
      return _userRoleCache[userId]!;
    }
    
    // Firestore'dan kontrol et
    try {
      final role = user.data()?['role'] as String?;
      final userRole = role ?? 'user';
      _userRoleCache[userId] = userRole;
      return userRole;
    } catch (e) {
      return 'user';
    }
  }
  
  // Kullanıcı yönetici mi (kurucu veya moderatör)
  Future<bool> isStaff(String userId) async {
    if (isFounder()) return true;
    return await isModerator(userId);
  }
  
  // Kullanıcı yetki kontrolü - kimler kimi yönetebilir
  Future<bool> canManageUser(String managerId, String targetUserId) async {
    final managerRole = await getUserRole(managerId);
    final targetRole = await getUserRole(targetUserId);
    
    // Kurucu herkesi yönetebilir
    if (managerRole == 'founder') return true;
    
    // Moderatör sadece üyeleri yönetebilir
    if (managerRole == 'moderator' && targetRole == 'user') return true;
    
    return false;
  }
  
  // Moderatör ata (sadece kurucu)
  Future<void> assignModerator(String email) async {
    if (!isFounder()) {
      throw Exception('Bu işlem için kurucu yetkisi gereklidir.');
    }
    
    try {
      print('📧 [FOUNDER] Moderatör atama başladı: $email');
      
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();
      
      print('🔍 [ADMIN] Kullanıcı sorgusu yapıldı, sonuç sayısı: ${userQuery.docs.length}');
      
      if (userQuery.docs.isEmpty) {
        print('❌ [ADMIN] Kullanıcı bulunamadı: $email');
        throw Exception('Kullanıcı bulunamadı. Bu email ile kayıtlı kullanıcı yok.');
      }
      
      final userId = userQuery.docs.first.id;
      final username = userQuery.docs.first.data()['username'] as String?;
      print('👤 [ADMIN] Kullanıcı bulundu: $username (ID: $userId)');
      
      await _firestore.collection('users').doc(userId).update({
        'role': 'moderator',
        'moderatorSince': FieldValue.serverTimestamp(),
      });
      print('✅ [ADMIN] Firestore güncellendi');
      
      _userRoleCache[userId] = 'moderator';
      print('💾 [ADMIN] Cache güncellendi');
      
      // Log kaydet
      await _logModerationAction(
        action: 'assign_moderator',
        targetUserId: userId,
        details: 'Email: $email, Kullanıcı: ${username ?? "Bilinmiyor"}',
      );
      print('📝 [ADMIN] Log kaydedildi');
      print('🎉 [ADMIN] Moderatör atama tamamlandı: $username');
    } catch (e) {
      print('❌ [ADMIN] Moderatör atama hatası: $e');
      rethrow;
    }
  }
  
  // Moderatör kaldır (sadece kurucu)
  Future<void> removeModerator(String email) async {
    if (!isFounder()) {
      throw Exception('Bu işlem için kurucu yetkisi gereklidir.');
    }
    
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();
      
      if (userQuery.docs.isEmpty) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      final userId = userQuery.docs.first.id;
      final username = userQuery.docs.first.data()['username'] as String?;
      
      await _firestore.collection('users').doc(userId).update({
        'role': FieldValue.delete(),
        'moderatorSince': FieldValue.delete(),
      });
      
      _userRoleCache.remove(userId);
      
      // Log kaydet
      await _logModerationAction(
        action: 'remove_moderator',
        targetUserId: userId,
        details: 'Email: $email, Kullanıcı: ${username ?? "Bilinmiyor"}',
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Kullanıcıyı sustur (yetki kontrolü ile)
  Future<void> muteUser(String userId, Duration duration) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('Giriş yapmanız gereklidir.');
    }
    
    final canManage = await canManageUser(currentUserId, userId);
    if (!canManage) {
      throw Exception('Bu kullanıcıyı susturmak için yetkiniz bulunmamaktadır.');
    }
    
    final muteUntil = DateTime.now().add(duration);
    await _firestore.collection('users').doc(userId).update({
      'mutedUntil': Timestamp.fromDate(muteUntil),
    });
    
    // Log kaydet
    await _logModerationAction(
      action: 'mute',
      targetUserId: userId,
      details: 'Süre: ${duration.inMinutes} dakika',
    );
  }
  
  // Kullanıcıyı engelle (yetki kontrolü ile)
  Future<void> banUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('Giriş yapmanız gereklidir.');
    }
    
    final canManage = await canManageUser(currentUserId, userId);
    if (!canManage) {
      throw Exception('Bu kullanıcıyı engellemek için yetkiniz bulunmamaktadır.');
    }
    
    await _firestore.collection('users').doc(userId).update({
      'banned': true,
      'bannedAt': FieldValue.serverTimestamp(),
    });
    
    // Log kaydet
    await _logModerationAction(
      action: 'ban',
      targetUserId: userId,
      details: 'Kullanıcı kalıcı olarak engellendi',
    );
  }
  
  // Kullanıcının engellini kaldır
  Future<void> unbanUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'banned': false,
      'bannedAt': FieldValue.delete(),
    });
  }
  
  // Kullanıcı susturulmuş mu kontrol et
  Future<bool> isUserMuted(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final mutedUntil = doc.data()?['mutedUntil'] as Timestamp?;
      
      if (mutedUntil == null) return false;
      
      return mutedUntil.toDate().isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }
  
  // Kullanıcı engellenmiş mi kontrol et
  Future<bool> isUserBanned(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['banned'] == true;
    } catch (e) {
      return false;
    }
  }
  
  // Chat'i durdur/devam ettir
  Future<void> setChatEnabled(bool enabled) async {
    await _firestore.collection('settings').doc('chat').set({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _chatEnabled = enabled;
  }
  
  // Chat aktif mi kontrol et
  Future<bool> isChatEnabled() async {
    try {
      final doc = await _firestore.collection('settings').doc('chat').get();
      final enabled = doc.data()?['enabled'] as bool?;
      _chatEnabled = enabled ?? true;
      return _chatEnabled;
    } catch (e) {
      return true;
    }
  }
  
  // Kurucu email'ini al  
  String? get adminEmail => FOUNDER_EMAIL;
  
  // Kurucu email'ini al (yeni isim)
  String? get founderEmail => FOUNDER_EMAIL;
  
  // Mevcut kullanıcı email
  String? get currentUserEmail => _auth.currentUser?.email;
  
  // Mevcut kullanıcı ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Moderasyon aksiyonu logla
  Future<void> _logModerationAction({
    required String action,
    required String targetUserId,
    String? details,
    String? messageId,
  }) async {
    try {
      final moderatorId = _auth.currentUser?.uid;
      if (moderatorId == null) return;
      
      // Hedef kullanıcı bilgilerini al
      final targetUserDoc = await _firestore.collection('users').doc(targetUserId).get();
      final targetUsername = targetUserDoc.data()?['username'] as String?;
      final targetEmail = targetUserDoc.data()?['email'] as String?;
      
      // Moderatör bilgilerini al
      final moderatorDoc = await _firestore.collection('users').doc(moderatorId).get();
      final moderatorUsername = moderatorDoc.data()?['username'] as String?;
      final moderatorEmail = moderatorDoc.data()?['email'] as String?;
      
      await _firestore.collection('moderation_logs').add({
        'action': action,
        'moderatorId': moderatorId,
        'moderatorUsername': moderatorUsername,
        'moderatorEmail': moderatorEmail,
        'targetUserId': targetUserId,
        'targetUsername': targetUsername,
        'targetEmail': targetEmail,
        'messageId': messageId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Log kaydetme hatası: $e');
    }
  }
  
  
  // Moderasyon loglarını getir (son 100)
  Stream<QuerySnapshot> getModerationLogs({int limit = 100}) {
    return _firestore
        .collection('moderation_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
  
  // Moderatör listesini getir
  Stream<QuerySnapshot> getModerators() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'moderator')
        .snapshots();
  }
  
  // Mesaj silme logu kaydet
  Future<void> logMessageDeletion({
    required String messageId,
    required String messageContent,
    required String messageOwnerId,
    required String deletedBy,
    bool isMultipleDelete = false,
  }) async {
    try {
      // Mesaj sahibi bilgilerini al
      final messageOwnerDoc = await _firestore.collection('users').doc(messageOwnerId).get();
      final messageOwnerUsername = messageOwnerDoc.data()?['username'] as String? ?? 'Bilinmiyor';
      final messageOwnerEmail = messageOwnerDoc.data()?['email'] as String? ?? '';
      
      // Silen kişi bilgilerini al
      final deleterDoc = await _firestore.collection('users').doc(deletedBy).get();
      final deleterUsername = deleterDoc.data()?['username'] as String? ?? 'Bilinmiyor';
      final deleterEmail = deleterDoc.data()?['email'] as String? ?? '';
      final deleterRole = deleterDoc.data()?['role'] as String? ?? 'user';
      
      await _firestore.collection('message_deletion_logs').add({
        'messageId': messageId,
        'messageContent': messageContent.length > 100 
            ? '${messageContent.substring(0, 100)}...' 
            : messageContent,
        'messageOwnerId': messageOwnerId,
        'messageOwnerUsername': messageOwnerUsername,
        'messageOwnerEmail': messageOwnerEmail,
        'deletedBy': deletedBy,
        'deleterUsername': deleterUsername,
        'deleterEmail': deleterEmail,
        'deleterRole': deleterRole,
        'isMultipleDelete': isMultipleDelete,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print('📝 [LOG] Mesaj silme kaydı oluşturuldu: $deleterUsername -> $messageOwnerUsername');
    } catch (e) {
      print('❌ [LOG] Mesaj silme logu kaydetme hatası: $e');
    }
  }
  
  // Mesaj silme loglarını getir
  Stream<QuerySnapshot> getMessageDeletionLogs({int limit = 50}) {
    return _firestore
        .collection('message_deletion_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
  
  // Tüm mesajları sil (sadece kurucu)
  Future<void> deleteAllMessages() async {
    if (!isFounder()) {
      throw Exception('Sadece kurucu tüm mesajları silebilir');
    }
    
    // Tüm mesajları sil
    final batch = _firestore.batch();
    final messages = await _firestore.collection('community_chat').get();
    
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    
    // Log kaydet
    await _logModerationAction(
      action: 'delete_all_messages',
      targetUserId: 'system',
      details: 'Tüm topluluk mesajları silindi (${messages.docs.length} mesaj)',
    );
  }
}
