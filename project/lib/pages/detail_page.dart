import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/place_model.dart';
import '../widgets/youtube_embed_view.dart';

class DetailPage extends StatefulWidget {
  final Place place;

  const DetailPage({super.key, required this.place});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int currentImageIndex = 0;
  int scrollResetToken = 0;
  final Set<String> failedImageUrls = {};

  void _selectImage(int index, int imageCount) {
    setState(() {
      currentImageIndex = index.clamp(0, imageCount - 1);
    });
  }

  void _showPreviousImage(int imageCount) {
    if (imageCount <= 1) return;
    final nextIndex = currentImageIndex == 0
        ? imageCount - 1
        : currentImageIndex - 1;
    _selectImage(nextIndex, imageCount);
  }

  void _showNextImage(int imageCount) {
    if (imageCount <= 1) return;
    final nextIndex = currentImageIndex == imageCount - 1
        ? 0
        : currentImageIndex + 1;
    _selectImage(nextIndex, imageCount);
  }

  @override
  Widget build(BuildContext context) {
    final rawImages = widget.place.images.isNotEmpty
        ? widget.place.images
        : ['assets/images/maya_bay.jpg'];
    final images = rawImages
        .where((image) => !failedImageUrls.contains(image))
        .toList();
    final youtubeUrls = widget.place.youtubeUrls.isNotEmpty
        ? widget.place.youtubeUrls
        : [if (widget.place.youtubeUrl.isNotEmpty) widget.place.youtubeUrl];
    final displayImages = images.isNotEmpty
        ? images
        : ['assets/images/maya_bay.jpg'];

    if (currentImageIndex >= displayImages.length) {
      currentImageIndex = displayImages.length - 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F8),
      appBar: AppBar(
        title: Text(
          widget.place.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFFF7F3F8),
      ),

      body: NotificationListener<ScrollStartNotification>(
        onNotification: (notification) {
          setState(() {
            scrollResetToken++;
          });
          return false;
        },
        child: ListView(
          children: [
            Column(
              children: [
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < 0) {
                      _showNextImage(displayImages.length);
                    } else if (velocity > 0) {
                      _showPreviousImage(displayImages.length);
                    }
                  },
                  child: Stack(
                    children: [
                      _PlaceImage(
                        imagePath: displayImages[currentImageIndex],
                        height: 320,
                        width: double.infinity,
                        onLoadError: () {
                          final imagePath = displayImages[currentImageIndex];
                          if (!imagePath.startsWith('http')) return;
                          setState(() {
                            failedImageUrls.add(imagePath);
                          });
                        },
                      ),
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xAA000000)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroBadge(text: widget.place.category),
                            const SizedBox(height: 10),
                            Text(
                              widget.place.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                height: 1.12,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(blurRadius: 12, color: Colors.black54),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "${widget.place.province}, ${widget.place.region}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (displayImages.length > 1) ...[
                        Positioned(
                          left: 12,
                          top: 0,
                          bottom: 0,
                          child: _ImageNavButton(
                            icon: Icons.chevron_left,
                            onTap: () =>
                                _showPreviousImage(displayImages.length),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 0,
                          bottom: 0,
                          child: _ImageNavButton(
                            icon: Icons.chevron_right,
                            onTap: () => _showNextImage(displayImages.length),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${currentImageIndex + 1}/${displayImages.length}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 76,

                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,

                    itemCount: displayImages.length,

                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _selectImage(index, displayImages.length);
                        },

                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),

                          decoration: BoxDecoration(
                            border: Border.all(
                              color: currentImageIndex == index
                                  ? const Color(0xFF710078)
                                  : Colors.transparent,

                              width: 3,
                            ),

                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),

                            child: _PlaceImage(
                              imagePath: displayImages[index],

                              width: 92,
                              height: 70,
                              onLoadError: () {
                                final imagePath = displayImages[index];
                                if (!imagePath.startsWith('http')) return;
                                setState(() {
                                  failedImageUrls.add(imagePath);
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                        icon: Icons.category_outlined,
                        text: widget.place.type,
                      ),
                      _InfoPill(
                        icon: Icons.explore_outlined,
                        text: widget.place.activity,
                      ),
                      _InfoPill(
                        icon: Icons.photo_library_outlined,
                        text: '${displayImages.length} photos',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (youtubeUrls.isNotEmpty) ...[
                    _DetailSectionCard(
                      title: 'Travel Videos',
                      icon: Icons.play_circle_outline,
                      child: _YouTubeSection(
                        youtubeUrls: youtubeUrls,
                        scrollResetToken: scrollResetToken,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  _DetailSectionCard(
                    title: 'About',
                    icon: Icons.notes_outlined,
                    child: Text(
                      widget.place.description,
                      style: const TextStyle(fontSize: 16, height: 1.55),
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (widget.place.tags.isNotEmpty)
                    _DetailSectionCard(
                      title: 'Tags',
                      icon: Icons.local_offer_outlined,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.place.tags.map((tag) {
                          return _DetailTag(text: tag);
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,

                    child: FilledButton.icon(
                      onPressed: () {
                        _openGoogleMaps(context);
                      },

                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF710078),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),

                      icon: const Icon(Icons.map_outlined),

                      label: const Text("Open in Google Maps"),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final query = widget.place.name.isNotEmpty
        ? widget.place.name
        : widget.place.location;

    final Uri url;
    if (widget.place.latitude != null && widget.place.longitude != null) {
      url = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query':
            '${widget.place.name} ${widget.place.latitude},${widget.place.longitude}',
      });
    } else {
      url = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': query,
      });
    }

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot open Google Maps")));
    }
  }
}

class _HeroBadge extends StatelessWidget {
  final String text;

  const _HeroBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8E0EC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF710078)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E0EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF710078).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF710078), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  final String text;

  const _DetailTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF286B5E),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _YouTubeSection extends StatefulWidget {
  final List<String> youtubeUrls;
  final int scrollResetToken;

  const _YouTubeSection({
    required this.youtubeUrls,
    required this.scrollResetToken,
  });

  @override
  State<_YouTubeSection> createState() => _YouTubeSectionState();
}

class _YouTubeSectionState extends State<_YouTubeSection> {
  int currentVideoIndex = 0;
  late final PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _showVideo(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _showPreviousVideo() {
    if (widget.youtubeUrls.length <= 1) return;
    final nextIndex = currentVideoIndex == 0
        ? widget.youtubeUrls.length - 1
        : currentVideoIndex - 1;
    _showVideo(nextIndex);
  }

  void _showNextVideo() {
    if (widget.youtubeUrls.length <= 1) return;
    final nextIndex = currentVideoIndex == widget.youtubeUrls.length - 1
        ? 0
        : currentVideoIndex + 1;
    _showVideo(nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: pageController,
            itemCount: widget.youtubeUrls.length,
            onPageChanged: (index) {
              setState(() {
                currentVideoIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final url = widget.youtubeUrls[index];

              return _YouTubeCard(
                url: url,
                index: index,
                total: widget.youtubeUrls.length,
                scrollResetToken: widget.scrollResetToken,
              );
            },
          ),
        ),
        if (widget.youtubeUrls.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _VideoNavButton(
                icon: Icons.chevron_left,
                onTap: _showPreviousVideo,
              ),
              const SizedBox(width: 10),
              Text(
                "${currentVideoIndex + 1} / ${widget.youtubeUrls.length}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              ...List.generate(widget.youtubeUrls.length, (index) {
                final isSelected = currentVideoIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF710078)
                        : const Color(0xFFD8CDD9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
              const SizedBox(width: 10),
              _VideoNavButton(icon: Icons.chevron_right, onTap: _showNextVideo),
            ],
          ),
        ],
      ],
    );
  }
}

class _VideoNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _VideoNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton.filled(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF710078),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _YouTubeCard extends StatefulWidget {
  final String url;
  final int index;
  final int total;
  final int scrollResetToken;

  const _YouTubeCard({
    required this.url,
    required this.index,
    required this.total,
    required this.scrollResetToken,
  });

  @override
  State<_YouTubeCard> createState() => _YouTubeCardState();
}

class _YouTubeCardState extends State<_YouTubeCard> {
  YoutubePlayerController? controller;
  String? videoId;
  bool isPlayerVisible = false;

  @override
  void initState() {
    super.initState();
    videoId = YoutubePlayerController.convertUrlToId(widget.url);
  }

  @override
  void didUpdateWidget(covariant _YouTubeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _closePlayer();
      videoId = YoutubePlayerController.convertUrlToId(widget.url);
    }

    if (oldWidget.scrollResetToken != widget.scrollResetToken) {
      _closePlayer();
    }
  }

  @override
  void dispose() {
    _closePlayer();
    super.dispose();
  }

  void _openPlayer() {
    if (videoId == null) return;

    setState(() {
      isPlayerVisible = true;
      if (!kIsWeb) {
        controller = YoutubePlayerController.fromVideoId(
          videoId: videoId!,
          autoPlay: true,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: false,
            playsInline: true,
            strictRelatedVideos: true,
          ),
        );
      }
    });
  }

  void _closePlayer() {
    controller?.close();
    controller = null;
    isPlayerVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = videoId == null
        ? ''
        : YoutubePlayerController.getThumbnail(videoId: videoId!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: videoId == null
            ? _YouTubeFallbackThumbnail(
                thumbnailUrl: thumbnailUrl,
                index: widget.index,
                onTap: null,
              )
            : !isPlayerVisible
            ? _YouTubeFallbackThumbnail(
                thumbnailUrl: thumbnailUrl,
                index: widget.index,
                onTap: _openPlayer,
              )
            : kIsWeb
            ? YouTubeEmbedView(url: widget.url)
            : YoutubePlayer(
                key: ValueKey(videoId),
                controller: controller!,
                aspectRatio: 16 / 9,
                backgroundColor: Colors.black87,
                autoFullScreen: false,
                enableFullScreenOnVerticalDrag: false,
                keepAlive: false,
              ),
      ),
    );
  }
}

class _YouTubeFallbackThumbnail extends StatelessWidget {
  final String thumbnailUrl;
  final int index;
  final VoidCallback? onTap;

  const _YouTubeFallbackThumbnail({
    required this.thumbnailUrl,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailUrl.isNotEmpty)
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(color: Colors.black87);
              },
            ),
          const DecoratedBox(decoration: BoxDecoration(color: Colors.black38)),
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Text(
              'YouTube Video ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceImage extends StatelessWidget {
  final String imagePath;
  final double height;
  final double width;
  final VoidCallback? onLoadError;

  const _PlaceImage({
    required this.imagePath,
    required this.height,
    required this.width,
    this.onLoadError,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onLoadError?.call();
          });
          return Image.asset(
            'assets/images/maya_bay.jpg',
            height: height,
            width: width,
            fit: BoxFit.cover,
          );
        },
      );
    }

    return Image.asset(
      imagePath,
      height: height,
      width: width,
      fit: BoxFit.cover,
    );
  }
}

class _ImageNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ImageNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
