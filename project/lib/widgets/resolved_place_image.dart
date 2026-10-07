import 'package:flutter/material.dart';

import '../utils/place_media.dart';
import 'place_image_placeholder.dart';

class ResolvedPlaceImage extends StatelessWidget {
  final String imagePath;
  final String placeName;
  final double height;
  final double width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final VoidCallback? onLoadError;

  const ResolvedPlaceImage({
    super.key,
    required this.imagePath,
    required this.placeName,
    required this.height,
    required this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onLoadError,
  });

  @override
  Widget build(BuildContext context) {
    final source = normalizePlaceImageSource(imagePath);
    final child = _buildImage(source);

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _buildImage(String source) {
    if (source.isEmpty) return _placeholder();

    if (isAssetPlaceImage(source)) {
      return Image.asset(source, height: height, width: width, fit: fit);
    }

    return FutureBuilder<String?>(
      future: resolvePlaceImageUrl(source),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _placeholder();
          }
          _notifyLoadError();
          return _placeholder();
        }

        return Image.network(
          url,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            _notifyLoadError();
            return _placeholder();
          },
        );
      },
    );
  }

  Widget _placeholder() {
    return PlaceImagePlaceholder(
      placeName: placeName,
      height: height,
      width: width,
    );
  }

  void _notifyLoadError() {
    if (onLoadError == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => onLoadError?.call());
  }
}
