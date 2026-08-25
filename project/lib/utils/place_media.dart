import '../models/place_model.dart';

List<String> placeImageCandidates(Place place) {
  final candidates = <String>[
    ...place.images.where((url) => !_isExpiredGooglePlacesUrl(url)),
    ..._youtubeThumbnails(place),
  ];

  return candidates.where((url) => url.trim().isNotEmpty).toSet().toList();
}

bool _isExpiredGooglePlacesUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;

  return uri.host == 'lh3.googleusercontent.com' &&
      (uri.path.startsWith('/place-photos/') ||
          uri.path.startsWith('/places/'));
}

Iterable<String> _youtubeThumbnails(Place place) sync* {
  final urls = <String>{
    ...place.youtubeUrls,
    if (place.youtubeUrl.isNotEmpty) place.youtubeUrl,
  };

  for (final url in urls) {
    final videoId = _youtubeVideoId(url);
    if (videoId != null) {
      yield 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
  }
}

String? _youtubeVideoId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;

  if (uri.host.endsWith('youtu.be')) {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }

  if (uri.host.contains('youtube.com')) {
    final queryId = uri.queryParameters['v'];
    if (queryId != null && queryId.isNotEmpty) return queryId;

    final segments = uri.pathSegments;
    if (segments.length >= 2 &&
        (segments.first == 'embed' || segments.first == 'shorts')) {
      return segments[1];
    }
  }

  return null;
}
