import 'dart:convert';

import '../models/place_model.dart';
import '../models/recommendation_preferences.dart';
import 'history_repository.dart';

class LocalRecommendationService {
  static const int _rotationStep = 24;
  static final Map<String, int> _offsets = {};

  static List<Place> fallbackRecommendation({
    required List<Place> places,
    required RecommendationPreferences preferences,
    required HistoryPreferenceBoost historyBoost,
  }) {
    final scoredPlaces =
        places
            .where((place) => _matchesLocation(place, preferences))
            .map(
              (place) => _ScoredPlace(
                place,
                _scorePlace(
                  place: place,
                  preferences: preferences,
                  historyBoost: historyBoost,
                ),
              ),
            )
            .where((item) => item.score > 0)
            .toList()
          ..sort((a, b) {
            final scoreCompare = b.score.compareTo(a.score);
            if (scoreCompare != 0) return scoreCompare;
            return a.place.name.compareTo(b.place.name);
          });

    return scoredPlaces.map((item) => item.place).toList();
  }

  static List<Place> rotateRecommendationOrder(
    List<Place> places,
    RecommendationPreferences preferences,
  ) {
    if (places.length <= 1) return places;

    final key = _recommendationKey(preferences);
    final currentOffset = _offsets[key] ?? 0;
    final offset = currentOffset % places.length;
    _offsets[key] = (currentOffset + _rotationStep) % places.length;

    if (offset == 0) return List<Place>.from(places);
    return [...places.skip(offset), ...places.take(offset)];
  }

  static bool _matchesLocation(
    Place place,
    RecommendationPreferences preferences,
  ) {
    if (!preferences.regions.contains(place.region)) {
      return false;
    }

    if (preferences.provinces.isNotEmpty &&
        !preferences.provinces.contains(place.province)) {
      return false;
    }

    return true;
  }

  static int _scorePlace({
    required Place place,
    required RecommendationPreferences preferences,
    required HistoryPreferenceBoost historyBoost,
  }) {
    var score = 0;

    if (preferences.categories.contains(place.category)) {
      score += 3;
    }

    if (preferences.types.contains(place.type)) {
      score += 3;
    }

    for (final activity in preferences.activities) {
      if (place.activity.contains(activity)) {
        score += 4;
      }
    }

    if (historyBoost.categories.contains(place.category)) {
      score += 2;
    }

    if (historyBoost.types.contains(place.type)) {
      score += 3;
    }

    for (final activity in historyBoost.activities) {
      if (place.activity.contains(activity)) {
        score += 2;
      }
    }

    return score;
  }

  static String _recommendationKey(RecommendationPreferences preferences) {
    List<String> sorted(List<String> values) => [...values]..sort();

    return jsonEncode({
      'regions': sorted(preferences.regions),
      'provinces': sorted(preferences.provinces),
      'categories': sorted(preferences.categories),
      'types': sorted(preferences.types),
      'activities': sorted(preferences.activities),
    });
  }
}

class _ScoredPlace {
  final Place place;
  final int score;

  const _ScoredPlace(this.place, this.score);
}
