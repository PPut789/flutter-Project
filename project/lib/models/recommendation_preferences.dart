class RecommendationPreferences {
  final List<String> regions;
  final List<String> provinces;
  final List<String> categories;
  final List<String> types;
  final List<String> activities;

  const RecommendationPreferences({
    required this.regions,
    required this.provinces,
    required this.categories,
    required this.types,
    required this.activities,
  });

  factory RecommendationPreferences.fromJson(Map<String, dynamic> json) {
    return RecommendationPreferences(
      regions: List<String>.from(json['regions'] as List? ?? const []),
      provinces: List<String>.from(json['provinces'] as List? ?? const []),
      categories: List<String>.from(json['categories'] as List? ?? const []),
      types: List<String>.from(json['types'] as List? ?? const []),
      activities: List<String>.from(json['activities'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'regions': regions,
      'provinces': provinces,
      'categories': categories,
      'types': types,
      'activities': activities,
    };
  }

  bool get isComplete {
    return regions.isNotEmpty &&
        categories.isNotEmpty &&
        types.isNotEmpty &&
        activities.isNotEmpty;
  }
}
