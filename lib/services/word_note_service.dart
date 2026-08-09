import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class WordNoteService {
  static final WordNoteService _instance = WordNoteService._internal();
  factory WordNoteService() => _instance;
  WordNoteService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // Kelime için özel veri belgesi
  DocumentReference? _getWordDataRef(String word) {
    if (!_auth.isSignedIn) return null;
    return _firestore
        .collection('users')
        .doc(_auth.userId!)
        .collection('saved_words')
        .doc(word);
  }

  // Notu kaydet
  Future<void> saveWordNote(String word, String noteText) async {
    if (!_auth.isSignedIn) return;
    try {
      final docRef = _getWordDataRef(word);
      if (docRef == null) return;
      
      await docRef.set({
        'note': noteText,
        'noteUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[WordNoteService] saveWordNote error: $e');
    }
  }

  // Özel örnek kaydet
  Future<void> addCustomExample(String word, Map<String, dynamic> example) async {
    if (!_auth.isSignedIn) return;
    try {
      final docRef = _getWordDataRef(word);
      if (docRef == null) return;
      
      await docRef.set({
        'customExamples': FieldValue.arrayUnion([
          {
            ...example,
            'addedAt': DateTime.now().millisecondsSinceEpoch,
          }
        ]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[WordNoteService] addCustomExample error: $e');
    }
  }

  // Kelimenin verisini dinle (Not ve Örnekler için)
  Stream<DocumentSnapshot>? streamWordData(String word) {
    if (!_auth.isSignedIn) return null;
    final docRef = _getWordDataRef(word);
    return docRef?.snapshots();
  }
}
