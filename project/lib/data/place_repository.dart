import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/place_model.dart';

class PlaceRepository {
  static Future<List<Place>>? _placesFuture;

  static Future<List<Place>> loadPlaces() async {
    return _placesFuture ??= _fetchPlaces();
  }

  static Future<List<Place>> refreshPlaces() async {
    _placesFuture = _fetchPlaces();
    return _placesFuture!;
  }

  static Future<List<Place>> _fetchPlaces() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('attractions')
        .orderBy('sourceRow')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Place.fromJson({...data, 'documentId': doc.id});
    }).toList();
  }
}
