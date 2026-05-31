import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/recommendation_preferences.dart';

class UserRepository {
  static DocumentReference<Map<String, dynamic>>? _userDocument() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  static Future<RecommendationPreferences?> loadPreferences() async {
    final document = _userDocument();
    if (document == null) return null;

    try {
      final snapshot = await document.get();
      final data = snapshot.data();
      final preferencesData = data?['preferences'];

      if (preferencesData is! Map) return null;

      final preferences = RecommendationPreferences.fromJson(
        Map<String, dynamic>.from(preferencesData),
      );

      return preferences.isComplete ? preferences : null;
    } on FirebaseException {
      return null;
    }
  }

  static Future<void> savePreferences(
    RecommendationPreferences preferences,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final document = _userDocument();
    if (user == null || document == null) return;

    await document.set({
      'displayName': user.displayName,
      'email': user.email,
      'preferences': preferences.toJson(),
      'preferencesUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
