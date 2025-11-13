import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String uid;
  final String? displayName;
  final String? photoUrl;
  final String? role;
  final DateTime fetchedAt;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.role,
    required this.fetchedAt,
  });

  Map<String, String?> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'role': role,
    'fetchedAt': fetchedAt.millisecondsSinceEpoch.toString(),
  };

  static UserProfile fromMap(Map<String, String?> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      role: map['role'],
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(int.tryParse(map['fetchedAt'] ?? '0') ?? 0),
    );
  }
}

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._();
  factory UserProfileService() => _instance;
  UserProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, UserProfile> _memoryCache = <String, UserProfile>{};
  static const Duration ttl = Duration(minutes: 10);
  static const int maxEntries = 500;

  bool _isFresh(UserProfile p) => DateTime.now().difference(p.fetchedAt) < ttl;

  UserProfile? getCached(String uid) {
    final p = _memoryCache[uid];
    if (p != null && _isFresh(p)) return p;
    return null;
  }

  Future<UserProfile> getProfile(String uid) async {
    final cached = _memoryCache[uid];
    if (cached != null && _isFresh(cached)) return cached;

    // Try disk cache (best-effort)
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('profile_$uid');
      if (raw != null) {
        final parts = raw.split('\u0001');
        if (parts.length >= 4) {
          final p = UserProfile(
            uid: uid,
            displayName: parts[0].isEmpty ? null : parts[0],
            photoUrl: parts[1].isEmpty ? null : parts[1],
            role: parts[2].isEmpty ? null : parts[2],
            fetchedAt: DateTime.fromMillisecondsSinceEpoch(int.tryParse(parts[3]) ?? 0),
          );
          if (_isFresh(p)) {
            _memoryCache[uid] = p;
            return p;
          }
        }
      }
    } catch (_) {}

    // Fetch from Firestore
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final p = UserProfile(
      uid: uid,
      displayName: (data['username'] as String?) ?? (data['displayName'] as String?),
      photoUrl: data['photoUrl'] as String?,
      role: data['role'] as String?,
      fetchedAt: DateTime.now(),
    );

    _insertIntoMemory(p);
    _saveToDisk(p);
    return p;
  }

  Future<void> preloadProfiles(Iterable<String> uids) async {
    final toFetch = <String>[];
    for (final uid in uids) {
      final c = _memoryCache[uid];
      if (c == null || !_isFresh(c)) {
        toFetch.add(uid);
      }
    }
    if (toFetch.isEmpty) return;

    // Batch fetch individually to keep it simple and robust
    await Future.wait(toFetch.map(getProfile), eagerError: false);
  }

  void _insertIntoMemory(UserProfile p) {
    if (_memoryCache.length >= maxEntries) {
      // Simple eviction: remove oldest
      String? oldestKey;
      DateTime oldest = DateTime.now();
      _memoryCache.forEach((k, v) {
        if (v.fetchedAt.isBefore(oldest)) {
          oldest = v.fetchedAt;
          oldestKey = k;
        }
      });
      if (oldestKey != null) {
        _memoryCache.remove(oldestKey);
      }
    }
    _memoryCache[p.uid] = p;
  }

  Future<void> _saveToDisk(UserProfile p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = '${p.displayName ?? ''}\u0001${p.photoUrl ?? ''}\u0001${p.role ?? ''}\u0001${p.fetchedAt.millisecondsSinceEpoch}';
      await prefs.setString('profile_${p.uid}', raw);
    } catch (_) {}
  }
}
