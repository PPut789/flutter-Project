import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/place_model.dart';
import 'detail_page.dart';

class TikTokPage extends StatelessWidget {
  final List<Place> places;

  const TikTokPage({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    final videoPlaces = places
        .where(
          (place) => place.videoUrls.isNotEmpty || place.tiktokUrls.isNotEmpty,
        )
        .toList();

    if (videoPlaces.isEmpty) {
      return const _EmptyTikTokState();
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: videoPlaces.length,
      itemBuilder: (context, index) {
        return _TikTokFeedItem(place: videoPlaces[index]);
      },
    );
  }
}

class _TikTokFeedItem extends StatefulWidget {
  final Place place;

  const _TikTokFeedItem({required this.place});

  @override
  State<_TikTokFeedItem> createState() => _TikTokFeedItemState();
}

class _TikTokFeedItemState extends State<_TikTokFeedItem> {
  late final VideoPlayerController _controller;
  bool hasVideoError = false;

  static const fallbackVideoPath = 'assets/video/prototype_tiktok_feed.mp4';

  @override
  void initState() {
    super.initState();
    _controller = _createController()
      ..setLooping(true)
      ..setVolume(1)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {});
            _controller.play();
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() {
              hasVideoError = true;
            });
          });
  }

  VideoPlayerController _createController() {
    final videoUrl = widget.place.videoUrls.firstOrNull;
    final uri = videoUrl == null ? null : Uri.tryParse(videoUrl);

    if (uri != null && uri.hasScheme) {
      return VideoPlayerController.networkUrl(uri);
    }

    return VideoPlayerController.asset(fallbackVideoPath);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () {
                if (!_controller.value.isInitialized) return;
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: _VideoSurface(
                controller: _controller,
                hasError: hasVideoError,
              ),
            ),
            _VideoGradient(),
            Positioned(
              left: 20,
              right: 92,
              bottom: 28,
              child: _PlaceSummary(place: place),
            ),
            Positioned(
              right: 16,
              bottom: 34,
              child: _ActionRail(
                place: place,
                tiktokUrl: place.tiktokUrls.firstOrNull,
              ),
            ),
            if (_controller.value.isInitialized && !_controller.value.isPlaying)
              const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 82,
                  shadows: [Shadow(blurRadius: 18, color: Colors.black54)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  final VideoPlayerController controller;
  final bool hasError;

  const _VideoSurface({required this.controller, required this.hasError});

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return const _VideoErrorState();
    }

    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _VideoErrorState extends StatelessWidget {
  const _VideoErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 42),
            SizedBox(height: 10),
            Text(
              'Cannot load this video',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.08),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.78),
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}

class _PlaceSummary extends StatelessWidget {
  final Place place;

  const _PlaceSummary({required this.place});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            place.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${place.province}, ${place.region}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: place.tags.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionRail extends StatelessWidget {
  final Place place;
  final String? tiktokUrl;

  const _ActionRail({required this.place, required this.tiktokUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundActionButton(
          icon: Icons.place_outlined,
          label: 'Place',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailPage(place: place)),
            );
          },
        ),
        if (tiktokUrl?.isNotEmpty == true) ...[
          const SizedBox(height: 18),
          _RoundActionButton(
            icon: Icons.open_in_new,
            label: 'TikTok',
            onTap: () => _openTikTok(context),
          ),
        ],
      ],
    );
  }

  Future<void> _openTikTok(BuildContext context) async {
    final url = tiktokUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open TikTok link')));
    }
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.22),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 54,
              height: 54,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
          ),
        ),
      ],
    );
  }
}

class _EmptyTikTokState extends StatelessWidget {
  const _EmptyTikTokState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F3F8),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Text(
        'No TikTok videos yet',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
