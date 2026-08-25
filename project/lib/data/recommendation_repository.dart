import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_model.dart';
import '../models/recommendation_preferences.dart';

class RecommendationRepository {
  static const String _defaultBaseUrl = 'http://127.0.0.1:8000';
  static const String _baseUrl = String.fromEnvironment(
    'RECOMMENDATION_API_URL',
    defaultValue: _defaultBaseUrl,
  );

  static Future<List<Place>> recommendPlaces({
    required RecommendationPreferences preferences,
    required List<Place> places,
    Set<int> excludeSourceRows = const {},
    List<String> historyKeywords = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/recommend'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'regions': preferences.regions,
        'provinces': preferences.provinces,
        'categories': preferences.categories,
        'types': preferences.types,
        'activities': preferences.activities,
        'keywords': historyKeywords,
        'exclude_source_rows': excludeSourceRows.toList(),
        'limit': 120,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Recommendation API returned ${response.statusCode}.');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map<String, dynamic> || json['results'] is! List) {
      throw Exception('Recommendation API returned invalid data.');
    }

    final results = json['results'] as List<dynamic>;
    final placesBySourceRow = <int, Place>{};
    for (final place in places) {
      final sourceRow = place.sourceRow;
      if (sourceRow != null) {
        placesBySourceRow[sourceRow] = place;
      }
    }

    final rankedPlaces = <Place>[];
    for (final result in results) {
      if (result is! Map<String, dynamic>) continue;
      final sourceRow = result['sourceRow'];
      if (sourceRow is! int) continue;

      final place = placesBySourceRow[sourceRow];
      if (place != null) {
        rankedPlaces.add(place);
      }
    }

    return rankedPlaces;
  }
}
