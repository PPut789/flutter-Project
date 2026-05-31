import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/place_model.dart';

class HistoryRepository {
  static CollectionReference<Map<String, dynamic>>? _historyCollection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('history');
  }

  static Future<void> addViewedPlace(Place place) async {
    final collection = _historyCollection();
    if (collection == null) return;

    await collection.doc(_historyDocumentId(place)).set({
      'place': place.toJson(),
      'viewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _historyDocumentId(Place place) {
    final rawId = place.id.trim().isNotEmpty ? place.id : place.name;
    return rawId.replaceAll(RegExp(r'[/#?\[\]]'), '_');
  }

  static Stream<List<HistoryItem>> watchHistory() {
    final collection = _historyCollection();
    if (collection == null) {
      return Stream.value(const []);
    }

    return collection
        .orderBy('viewedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return HistoryItem(
              id: doc.id,
              place: Place.fromJson(
                Map<String, dynamic>.from(data['place'] as Map? ?? const {}),
              ),
              viewedAt: (data['viewedAt'] as Timestamp?)?.toDate(),
            );
          }).toList(),
        );
  }

  static Future<void> clearHistory() async {
    final collection = _historyCollection();
    if (collection == null) return;

    final snapshot = await collection.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

class HistoryItem {
  final String id;
  final Place place;
  final DateTime? viewedAt;

  const HistoryItem({
    required this.id,
    required this.place,
    required this.viewedAt,
  });
}
