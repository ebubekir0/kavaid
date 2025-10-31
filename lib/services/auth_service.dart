import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'credits_service.dart';
import 'saved_words_service.dart';
import 'cloud_saved_words_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Auth state değişikliklerini dinle
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  String? get userId => currentUser?.uid;
  String? get userEmail => currentUser?.email;
  // Eski yapı: UID ile çalışır
  String? get displayName => currentUser?.displayName;
  String? get photoUrl => currentUser?.photoURL;
  bool get isGoogleSignedIn =>
      currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  // Cihaz bilgileri
  String? _currentDeviceId;
  String? _currentDeviceName;
  
  // Önceki kullanıcı ID'sini takip et
  String? _previousUserId;
  
  // Auth state değişikliklerini dinle
  void _onAuthStateChanged(User? user) async {
    final currentUserId = user?.uid;
    
    // Kullanıcı değişti mi kontrol et
    if (_previousUserId != currentUserId) {
      debugPrint('🔄 [Auth] Kullanıcı değişti: $_previousUserId -> $currentUserId');
      
      if (currentUserId != null) {
        // Yeni kullanıcı girişi - servisleri yeniden başlat
        await _reinitializeServices(user!);
      } else {
        // Kullanıcı çıkışı - servisleri temizle
        await _clearServices();
      }
      
      _previousUserId = currentUserId;
      notifyListeners();
    }
  }
  
  // Servis yeniden başlatma
  Future<void> _reinitializeServices(User user) async {
    try {
      debugPrint('🔄 [Auth] Servisler yeniden başlatılıyor...');
      
      // 0. Kullanıcı adı kontrolü ve otomatik atama
      try {
        await _ensureUsername();
        debugPrint('✅ [Auth] Kullanıcı adı kontrolü tamamlandı');
      } catch (e) {
        debugPrint('⚠️ [Auth] Kullanıcı adı kontrol hatası: $e');
      }
      
      // 1. Credits Service
      try {
        await CreditsService().initialize();
        debugPrint('✅ [Auth] CreditsService yenilendi');
      } catch (e) {
        debugPrint('⚠️ [Auth] CreditsService yenileme hatası: $e');
      }
      
      // 2. Saved Words Service
      try {
        final SavedWordsService savedWordsService = SavedWordsService();
        await savedWordsService.refresh();
        debugPrint('✅ [Auth] SavedWordsService yenilendi');
      } catch (e) {
        debugPrint('⚠️ [Auth] SavedWordsService yenileme hatası: $e');
      }
      
      // 3. Cloud Saved Words Service - Senkronizasyon
      try {
        final CloudSavedWordsService cloudService = CloudSavedWordsService();
        await cloudService.mergeSync();
        debugPrint('✅ [Auth] Cloud senkronizasyonu tamamlandı');
      } catch (e) {
        debugPrint('⚠️ [Auth] Cloud senkronizasyon hatası: $e');
      }
      
      debugPrint('✅ [Auth] Tüm servisler başarıyla yenilendi');
    } catch (e) {
      debugPrint('❌ [Auth] Servis yenileme hatası: $e');
    }
  }
  
  // Servisleri temizle
  Future<void> _clearServices() async {
    try {
      debugPrint('🧹 [Auth] Servisler temizleniyor...');
      
      // Saved Words Service temizle
      try {
        final SavedWordsService savedWordsService = SavedWordsService();
        await savedWordsService.clearAllSavedWords(); // Tüm kelimeleri temizle
        await savedWordsService.refresh();
        debugPrint('✅ [Auth] SavedWordsService temizlendi');
      } catch (e) {
        debugPrint('⚠️ [Auth] SavedWordsService temizleme hatası: $e');
      }
      
      // Credits Service temizle
      try {
        await CreditsService().initialize(); // Sıfırla
        debugPrint('✅ [Auth] CreditsService temizlendi');
      } catch (e) {
        debugPrint('⚠️ [Auth] CreditsService temizleme hatası: $e');
      }
      
      debugPrint('✅ [Auth] Servisler temizlendi');
    } catch (e) {
      debugPrint('❌ [Auth] Servis temizleme hatası: $e');
    }
  }

  // Email/şifre ile kayıt ol
  Future<User?> signUpWithEmail({required String email, required String password}) async {
    try {
      debugPrint('🔐 [Auth] Email sign-up başlatılıyor...');
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) return null;

      await _initializeDeviceInfo();
      await _checkAndUpdateDeviceSession(user.uid);
      await _updateUserData(user);
      
      // Otomatik kullanıcı adı oluştur
      await _ensureUsername();
      
      // Girişte hesap satın alım/lifetimeAdsFree durumunu eşitle
      try {
        await CreditsService().initialize();
      } catch (e) {
        debugPrint('⚠️ [Auth] Credits initialize hatası: $e');
      }
      // Kayıttan sonra otomatik giriş olmasın
      try {
        await _auth.signOut();
        debugPrint('🚪 [Auth] Kayıt sonrası otomatik giriş kapatıldı (signOut)');
      } catch (e) {
        debugPrint('⚠️ [Auth] Kayıt sonrası signOut hatası: $e');
      }
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint('❌ [Auth] Email sign-up hatası: $e');
      rethrow;
    }
  }

  // Email/şifre ile giriş yap
  Future<User?> signInWithEmail({required String email, required String password}) async {
    try {
      debugPrint('🔐 [Auth] Email sign-in başlatılıyor...');
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) return null;

      await _initializeDeviceInfo();
      await _checkAndUpdateDeviceSession(user.email!);
      await _updateUserData(user);
      
      // Otomatik kullanıcı adı kontrolü
      await _ensureUsername();
      
      // NOT: Servisler artık authStateChanges listener tarafından otomatik yenileniyor
      debugPrint('✅ [Auth] Email giriş tamamlandı, servisler otomatik yenilenecek');
      
      return user;
    } catch (e) {
      debugPrint('❌ [Auth] Email sign-in hatası: $e');
      rethrow;
    }
  }

  // Google ile giriş yap
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔐 [Auth] Google Sign-In başlatılıyor...');

      // Google Sign-In akışını başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ [Auth] Kullanıcı Google girişini iptal etti');
        return null;
      }

      // Authentication detaylarını al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'e giriş yap
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      final User? user = userCredential.user;
      if (user == null) {
        debugPrint('❌ [Auth] Firebase girişi başarısız');
        return null;
      }

      debugPrint('✅ [Auth] Giriş başarılı: ${user.email}');

      // Cihaz bilgilerini al ve kontrol et
      await _initializeDeviceInfo();
      await _checkAndUpdateDeviceSession(user.email!);

      // Kullanıcı bilgilerini Firestore'a kaydet/güncelle
      await _updateUserData(user);
      
      // Otomatik kullanıcı adı kontrolü
      await _ensureUsername();
      
      // NOT: Servisler artık authStateChanges listener tarafından otomatik yenileniyor
      debugPrint('✅ [Auth] Google giriş tamamlandı, servisler otomatik yenilenecek');

      // Cihaz reklamsız (premium) ise bu hak kullanıcı hesabına taşınsın
      try {
        final adFree = CreditsService().isLifetimeAdsFree;
        if (adFree) {
          await _firestore.collection('users').doc(user.email!).set({
            'lifetimeAdsFree': true,
          }, SetOptions(merge: true));
          debugPrint('✅ [Auth] Cihazdaki reklamsız hak kullanıcı hesabına aktarıldı');
        }
      } catch (e) {
        debugPrint('⚠️ [Auth] Reklamsız hak aktarımı başarısız: $e');
      }
      return user;
    } catch (e) {
      debugPrint('❌ [Auth] Google Sign-In hatası: $e');
      return null;
    }
  }

  // Cihaz bilgilerini başlat
  Future<void> _initializeDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _currentDeviceId = androidInfo.id;
        _currentDeviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _currentDeviceId = iosInfo.identifierForVendor;
        _currentDeviceName = '${iosInfo.name} ${iosInfo.model}';
      }
      debugPrint('📱 [Auth] Cihaz ID: $_currentDeviceId');
      debugPrint('📱 [Auth] Cihaz Adı: $_currentDeviceName');
    } catch (e) {
      debugPrint('❌ [Auth] Cihaz bilgileri alınamadı: $e');
    }
  }

  // Tek cihaz kontrolü ve oturum yönetimi
  Future<void> _checkAndUpdateDeviceSession(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        final activeDeviceId = data?['activeDeviceId'];
        final activeDeviceName = data?['activeDeviceName'];
        
        // Başka bir cihazda aktif oturum var mı?
        if (activeDeviceId != null && activeDeviceId != _currentDeviceId) {
          debugPrint('⚠️ [Auth] Başka cihazda aktif oturum var: $activeDeviceName');
          
          // Eski cihazdan çıkış yapılacağını işaretle
          await _firestore.collection('users').doc(userId).update({
            'previousDeviceId': activeDeviceId,
            'previousDeviceName': activeDeviceName,
            'sessionTransferredAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Yeni cihazı aktif olarak işaretle
      await _firestore.collection('users').doc(userId).update({
        'activeDeviceId': _currentDeviceId,
        'activeDeviceName': _currentDeviceName,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [Auth] Cihaz oturumu güncellendi');
    } catch (e) {
      debugPrint('❌ [Auth] Cihaz oturumu güncellenemedi: $e');
    }
  }

  // Kullanıcı verilerini güncelle
  Future<void> _updateUserData(User user) async {
    try {
      // UID anahtar olarak kullan
      final userRef = _firestore.collection('users').doc(user.uid);
      
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastSignInAt': FieldValue.serverTimestamp(),
        'activeDeviceId': _currentDeviceId,
        'activeDeviceName': _currentDeviceName,
      };

      // Kullanıcı ilk kez giriş yapıyorsa
      final doc = await userRef.get();
      if (!doc.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['lifetimeAdsFree'] = false; // Sadece lifetimeAdsFree
        userData['purchaseHistory'] = [];
        await userRef.set(userData);
        debugPrint('✅ [Auth] Yeni kullanıcı oluşturuldu: ${user.email}');
      } else {
        await userRef.update(userData);
        debugPrint('✅ [Auth] Kullanıcı bilgileri güncellendi: ${user.email}');
      }
    } catch (e) {
      debugPrint('❌ [Auth] Kullanıcı verileri güncellenemedi: $e');
    }
  }

  // Oturum durumunu kontrol et
  Future<bool> checkSessionValidity() async {
    if (!isSignedIn || _currentDeviceId == null) return true;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final activeDeviceId = userDoc.data()?['activeDeviceId'];
        
        // Bu cihazın oturumu hala geçerli mi?
        if (activeDeviceId != _currentDeviceId) {
          debugPrint('⚠️ [Auth] Oturum başka cihazda açıldı, çıkış yapılıyor...');
          await signOut(showMessage: true);
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('❌ [Auth] Oturum kontrolü başarısız: $e');
      return true;
    }
  }

  // Premium durumunu kontrol et
  Future<bool> checkPremiumStatus() async {
    if (!isSignedIn) return false;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['lifetimeAdsFree'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [Auth] Premium durumu kontrol edilemedi: $e');
      return false;
    }
  }

  // Premium satın alımını kaydet
  Future<void> recordPremiumPurchase(String purchaseId, double amount) async {
    if (!isSignedIn) {
      throw Exception('Satın alma için giriş yapmalısınız');
    }

    try {
      await _firestore.collection('users').doc(userId).set({
        'lifetimeAdsFree': true,
        'email': userEmail,
        'purchaseHistory': FieldValue.arrayUnion([
          {
            'purchaseId': purchaseId,
            'amount': amount,
            'purchasedAt': FieldValue.serverTimestamp(),
            'deviceId': _currentDeviceId,
            'deviceName': _currentDeviceName,
          }
        ]),
      }, SetOptions(merge: true));
      
      debugPrint('✅ [Auth] Premium satın alım kaydedildi');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [Auth] Premium satın alım kaydedilemedi: $e');
      throw e;
    }
  }

  // Çıkış yap
  Future<void> signOut({bool showMessage = false}) async {
    try {
      // Çıkış yapmadan önce kelimeleri buluta yedekle
      if (isSignedIn) {
        try {
          final CloudSavedWordsService cloudService = CloudSavedWordsService();
          await cloudService.syncUpFromLocal();
          debugPrint('✅ [Auth] Kelimeler buluta yedeklendi');
        } catch (e) {
          debugPrint('❌ [Auth] Kelimeler buluta yedeklenemedi: $e');
        }
      }
      
      // Firebase'den çıkış
      await _auth.signOut();
      
      // Google Sign-In'den çıkış
      await _googleSignIn.signOut();
      
      _currentDeviceId = null;
      _currentDeviceName = null;
      
      // NOT: Servisler artık authStateChanges listener tarafından otomatik temizleniyor
      debugPrint('✅ [Auth] Çıkış yapıldı, servisler otomatik temizlenecek');
    } catch (e) {
      debugPrint('❌ [Auth] Çıkış hatası: $e');
    }
  }

  // Auth durumu değişikliklerini dinle
  void listenAuthChanges(Function(User?) callback) {
    _auth.authStateChanges().listen(callback);
  }

  // Kullanıcı verilerini dinle
  Stream<DocumentSnapshot>? getUserDataStream() {
    if (!isSignedIn) return null;
    return _firestore.collection('users').doc(userEmail!).snapshots();
  }
  
  // Benzersiz kullanıcı adı oluştur (otomatik)
  Future<String> _generateUniqueUsername() async {
    try {
      // Rastgele 3-6 haneli sayı oluştur
      final random = (100 + (DateTime.now().millisecondsSinceEpoch % 899900)).toString();
      String username = 'kullanıcı$random';
      
      // Benzersizliği kontrol et
      int attempts = 0;
      while (attempts < 10) {
        final existingUser = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
        
        if (existingUser.docs.isEmpty) {
          debugPrint('✅ [Auth] Benzersiz kullanıcı adı oluşturuldu: $username');
          return username;
        }
        
        // Çakışma varsa yeni numara oluştur
        final newRandom = (100 + (DateTime.now().millisecondsSinceEpoch % 899900) + attempts * 1000).toString();
        username = 'kullanıcı$newRandom';
        attempts++;
      }
      
      // Son çare: UID'nin ilk 6 karakterini kullan
      username = 'kullanıcı${currentUser!.uid.substring(0, 6)}';
      debugPrint('✅ [Auth] Kullanıcı adı UID\'den oluşturuldu: $username');
      return username;
    } catch (e) {
      debugPrint('❌ [Auth] Kullanıcı adı oluşturma hatası: $e');
      // Hata durumunda timestamp kullan
      return 'kullanıcı${DateTime.now().millisecondsSinceEpoch % 1000000}';
    }
  }
  
  // Kullanıcı adını güncelle
  Future<bool> updateUsername(String newUsername) async {
    if (!isSignedIn) {
      debugPrint('❌ [Auth] Kullanıcı giriş yapmamış');
      return false;
    }
    
    try {
      // Formatı kontrol et
      final formatted = newUsername
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll(RegExp(r'[^a-z0-9çğıöşü]'), '')
          .trim();
      
      if (formatted.isEmpty || formatted.length < 3) {
        debugPrint('❌ [Auth] Geçersiz kullanıcı adı formatı');
        return false;
      }
      
      // Mevcut kullanıcı verilerini kontrol et
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final usernameChanged = data?['usernameChanged'] ?? false;
        
        // Eğer daha önce değiştirilmişse izin verme
        if (usernameChanged == true) {
          debugPrint('⚠️ [Auth] Kullanıcı adı zaten değiştirilmiş');
          return false;
        }
      }
      
      // Benzersizliği kontrol et
      final existingUser = await _firestore
          .collection('users')
          .where('username', isEqualTo: formatted)
          .limit(1)
          .get();
      
      if (existingUser.docs.isNotEmpty && existingUser.docs.first.id != userId) {
        debugPrint('❌ [Auth] Bu kullanıcı adı zaten kullanılıyor');
        return false;
      }
      
      // Kullanıcı adını güncelle
      await _firestore.collection('users').doc(userId).set({
        'username': formatted,
        'usernameChanged': true, // Değiştirildi olarak işaretle
        'usernameChangedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('✅ [Auth] Kullanıcı adı güncellendi: $formatted');
      return true;
    } catch (e) {
      debugPrint('❌ [Auth] Kullanıcı adı güncelleme hatası: $e');
      return false;
    }
  }
  
  // Kullanıcı adını kontrol et ve yoksa oluştur
  Future<void> _ensureUsername() async {
    if (!isSignedIn) return;
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists || userDoc.data()?['username'] == null) {
        // Kullanıcı adı yoksa otomatik oluştur
        final autoUsername = await _generateUniqueUsername();
        
        await _firestore.collection('users').doc(userId).set({
          'username': autoUsername,
          'usernameChanged': false, // Henüz değiştirilmedi
          'autoGenerated': true, // Otomatik oluşturuldu
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        debugPrint('✅ [Auth] Otomatik kullanıcı adı atandı: $autoUsername');
      } else {
        debugPrint('ℹ️ [Auth] Kullanıcı adı mevcut: ${userDoc.data()?['username']}');
      }
    } catch (e) {
      debugPrint('❌ [Auth] Kullanıcı adı kontrol hatası: $e');
    }
  }
}
