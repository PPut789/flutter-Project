import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/history_repository.dart';
import '../data/place_repository.dart';
import '../data/recommendation_repository.dart';
import '../data/user_repository.dart';
import '../models/app_settings.dart';
import '../models/place_model.dart';
import '../models/recommendation_preferences.dart';
import '../utils/app_routes.dart';
import '../utils/place_media.dart';
import '../widgets/app_chrome.dart';
import '../widgets/place_image_placeholder.dart';
import 'detail_page.dart';
import 'location_page.dart';
import 'profile_page.dart';
import 'tiktok_page.dart';
import 'upload_video_page.dart';

class HomePage extends StatefulWidget {
  final RecommendationPreferences preferences;

  const HomePage({super.key, required this.preferences});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _recommendationRotationStep = 24;
  static final Map<String, int> _recommendationOffsets = {};

  String searchText = '';
  int currentTabIndex = 0;
  late final TextEditingController searchController;
  late final Future<_HomeData> homeDataFuture;
  late final Future<AppSettings> appSettingsFuture;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    homeDataFuture = _loadHomeData();
    appSettingsFuture = UserRepository.loadAppSettings();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : user?.email ?? 'Username';
    final photoUrl = user?.photoURL;

    final isProfileTab = currentTabIndex == 4;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      body: FutureBuilder<_HomeData>(
        future: homeDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Cannot load attraction data: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final homeData = snapshot.data ?? const _HomeData.empty();
          final isSearching = searchText.trim().isNotEmpty;
          final places = _displayPlaces(homeData);
          final allPlaces = homeData.allPlaces;
          final showSectionTitle = !(isSearching && places.isEmpty);

          if (currentTabIndex == 3) {
            return VideoPage(places: allPlaces);
          }

          if (currentTabIndex == 4) {
            return ProfilePage(
              onBack: () {
                setState(() {
                  currentTabIndex = 0;
                });
              },
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HomeHeader(
                  controller: searchController,
                  username: username,
                  photoUrl: photoUrl,
                  searchText: searchText,
                  onProfileTap: () {
                    setState(() {
                      currentTabIndex = 4;
                    });
                  },
                  onSearchChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  onClearSearch: () {
                    searchController.clear();
                    setState(() {
                      searchText = '';
                    });
                  },
                ),
              ),
              if (showSectionTitle)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      isSearching ? "ผลการค้นหา" : "สถานที่แนะนำสำหรับคุณ",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                sliver: places.isEmpty
                    ? SliverToBoxAdapter(
                        child: _EmptyPlaceState(isSearching: isSearching),
                      )
                    : SliverList.builder(
                        itemCount: places.length,
                        itemBuilder: (context, index) {
                          return _PlaceCard(
                            place: places[index],
                            settingsFuture: appSettingsFuture,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: isProfileTab
          ? null
          : _TravelBottomNav(
              selectedIndex: currentTabIndex,
              onSelected: (index) {
                if (index == 1) {
                  Navigator.push(
                    context,
                    smoothRoute(
                      LocationPage(initialPreferences: widget.preferences),
                    ),
                  );
                  return;
                }

                if (index == 2) {
                  Navigator.push(context, smoothRoute(const UploadVideoPage()));
                  return;
                }

                setState(() {
                  currentTabIndex = index;
                });
              },
            ),
    );
  }

  Future<_HomeData> _loadHomeData() async {
    final allPlaces = await PlaceRepository.loadPlaces();
    final historyBoost = await HistoryRepository.loadPreferenceBoost();
    try {
      final viewedSourceRows = await HistoryRepository.loadViewedSourceRows();
      final recommendedPlaces = await RecommendationRepository.recommendPlaces(
        preferences: widget.preferences,
        places: allPlaces,
        excludeSourceRows: viewedSourceRows,
        historyKeywords: historyBoost.keywords,
      );
      return _HomeData(
        allPlaces: allPlaces,
        recommendedPlaces: _rotateRecommendationOrder(recommendedPlaces),
      );
    } catch (error) {
      debugPrint('Recommendation API unavailable, using fallback: $error');
      return _HomeData(
        allPlaces: allPlaces,
        recommendedPlaces: _rotateRecommendationOrder(
          _fallbackRecommendation(allPlaces, historyBoost),
        ),
      );
    }
  }

  List<Place> _rotateRecommendationOrder(List<Place> places) {
    if (places.length <= 1) return places;

    final key = _recommendationKey();
    final currentOffset = _recommendationOffsets[key] ?? 0;
    final offset = currentOffset % places.length;
    _recommendationOffsets[key] =
        (currentOffset + _recommendationRotationStep) % places.length;

    if (offset == 0) return List<Place>.from(places);
    return [...places.skip(offset), ...places.take(offset)];
  }

  String _recommendationKey() {
    List<String> sorted(List<String> values) => [...values]..sort();

    return jsonEncode({
      'regions': sorted(widget.preferences.regions),
      'provinces': sorted(widget.preferences.provinces),
      'categories': sorted(widget.preferences.categories),
      'types': sorted(widget.preferences.types),
      'activities': sorted(widget.preferences.activities),
    });
  }

  List<Place> _displayPlaces(_HomeData homeData) {
    final query = _normalizeSearchText(searchText);

    if (query.isNotEmpty) {
      final searchedPlaces =
          homeData.allPlaces
              .where((place) => _matchesSearch(place, query))
              .toList()
            ..sort((a, b) {
              final rankCompare = _searchRank(
                a,
                query,
              ).compareTo(_searchRank(b, query));
              if (rankCompare != 0) {
                return rankCompare;
              }
              return a.name.compareTo(b.name);
            });

      return searchedPlaces;
    }

    return homeData.recommendedPlaces;
  }

  List<Place> _fallbackRecommendation(
    List<Place> places,
    HistoryPreferenceBoost historyBoost,
  ) {
    final scoredPlaces =
        places
            .where((place) {
              if (!widget.preferences.regions.contains(place.region)) {
                return false;
              }

              if (widget.preferences.provinces.isNotEmpty &&
                  !widget.preferences.provinces.contains(place.province)) {
                return false;
              }

              return true;
            })
            .map(
              (place) => _ScoredPlace(place, _scorePlace(place, historyBoost)),
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

  String _normalizeSearchText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _matchesSearch(Place place, String query) {
    return _searchFields(place).any((field) => field.contains(query));
  }

  int _searchRank(Place place, String query) {
    final name = _normalizeSearchText(place.name);
    if (name == query) return 0;
    if (name.startsWith(query)) return 1;
    if (name.contains(query)) return 2;
    if (_normalizeSearchText(place.province).contains(query)) return 3;
    if (_normalizeSearchText(place.type).contains(query)) return 4;
    if (_normalizeSearchText(place.activity).contains(query)) return 5;
    return 6;
  }

  List<String> _searchFields(Place place) {
    return [
      place.name,
      place.province,
      place.region,
      place.category,
      place.type,
      place.activity,
      place.description,
    ].map(_normalizeSearchText).toList();
  }

  int _scorePlace(Place place, HistoryPreferenceBoost historyBoost) {
    var score = 0;

    if (widget.preferences.categories.contains(place.category)) {
      score += 3;
    }

    if (widget.preferences.types.contains(place.type)) {
      score += 3;
    }

    for (final activity in widget.preferences.activities) {
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
}

class _TravelBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _TravelBottomNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: Row(
            children: [
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.home_outlined,
                  label: 'หน้าแรก',
                  isSelected: selectedIndex == 0,
                  onTap: () => onSelected(0),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.explore_outlined,
                  label: 'ความสนใจ',
                  isSelected: selectedIndex == 1,
                  onTap: () => onSelected(1),
                ),
              ),
              Expanded(
                child: Center(child: _AddNavButton(onTap: () => onSelected(2))),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.smart_display_outlined,
                  label: 'วิดีโอ',
                  isSelected: selectedIndex == 3,
                  onTap: () => onSelected(3),
                ),
              ),
              Expanded(
                child: _BottomNavItem(
                  icon: Icons.person_outline,
                  label: 'โปรไฟล์',
                  isSelected: selectedIndex == 4,
                  onTap: () => onSelected(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? appPurple : const Color(0xFF7A707D);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 40,
            height: 26,
            decoration: BoxDecoration(
              color: isSelected ? appPurple.withValues(alpha: 0.13) : null,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddNavButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddNavButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: appPurple,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: appPurple.withValues(alpha: 0.34),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final TextEditingController controller;
  final String username;
  final String? photoUrl;
  final String searchText;
  final VoidCallback onProfileTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const _HomeHeader({
    required this.controller,
    required this.username,
    required this.photoUrl,
    required this.searchText,
    required this.onProfileTap,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: appBorder, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 22,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ยินดีต้อนรับ",
                      style: TextStyle(
                        color: appPurple,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              _HomeProfileButton(photoUrl: photoUrl, onTap: onProfileTap),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: "ค้นหาสถานที่ท่องเที่ยว...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchText.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close),
                      tooltip: 'ล้างคำค้นหา',
                    ),
              filled: true,
              fillColor: const Color(0xFFF9F8FA),
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: appBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: appBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeProfileButton extends StatelessWidget {
  final String? photoUrl;
  final VoidCallback onTap;

  const _HomeProfileButton({required this.photoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();

    return Material(
      color: const Color(0xFFF2EAF5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: CircleAvatar(
          radius: 23,
          backgroundColor: const Color(0xFFF2EAF5),
          backgroundImage: imageUrl != null && imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : null,
          child: imageUrl == null || imageUrl.isEmpty
              ? const Icon(Icons.person_outline, color: appPurple, size: 24)
              : null,
        ),
      ),
    );
  }
}

class _EmptyPlaceState extends StatelessWidget {
  final bool isSearching;

  const _EmptyPlaceState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: isSearching ? Icons.search_off_rounded : Icons.explore_off_rounded,
      title: isSearching ? 'ไม่พบผลการค้นหา' : 'ยังไม่มีสถานที่แนะนำ',
      message: isSearching
          ? 'ลองเปลี่ยนคำค้นหา หรือค้นหาด้วยชื่อจังหวัดและประเภทสถานที่'
          : 'ลองปรับความสนใจของคุณเพื่อค้นหาสถานที่ใหม่',
    );
  }
}

class _PlaceCard extends StatefulWidget {
  final Place place;
  final Future<AppSettings> settingsFuture;

  const _PlaceCard({required this.place, required this.settingsFuture});

  @override
  State<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<_PlaceCard> {
  bool isPressed = false;

  void _setPressed(bool value) {
    if (isPressed == value) return;
    setState(() {
      isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final imageCandidates = placeImageCandidates(place);

    return AnimatedScale(
      scale: isPressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTap: () async {
          _setPressed(false);
          final settings = await UserRepository.loadAppSettings(refresh: true);
          if (settings.saveViewingHistory) {
            await HistoryRepository.addViewedPlace(place);
          }
          if (!context.mounted) return;
          Navigator.push(context, smoothRoute(DetailPage(place: place)));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE8E0EC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isPressed ? 0.05 : 0.08),
                blurRadius: isPressed ? 8 : 16,
                offset: Offset(0, isPressed ? 3 : 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: Hero(
                      tag: _placeHeroTag(place),
                      child: _PlaceImage(
                        imagePath: imageCandidates.isNotEmpty
                            ? imageCandidates.first
                            : '',
                        placeName: place.name,
                        height: 210,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          icon: Icons.location_on_outlined,
                          text: place.province,
                        ),
                        _MetaPill(icon: Icons.map_outlined, text: place.region),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      place.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4D4652),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _placeHeroTag(Place place) {
  return 'place-image-${place.documentId.isNotEmpty ? place.documentId : place.id}';
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF710078)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ScoredPlace {
  final Place place;
  final int score;

  const _ScoredPlace(this.place, this.score);
}

class _HomeData {
  final List<Place> allPlaces;
  final List<Place> recommendedPlaces;

  const _HomeData({required this.allPlaces, required this.recommendedPlaces});

  const _HomeData.empty() : allPlaces = const [], recommendedPlaces = const [];
}

class _PlaceImage extends StatelessWidget {
  final String imagePath;
  final String placeName;
  final double height;
  final double width;

  const _PlaceImage({
    required this.imagePath,
    required this.placeName,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return PlaceImagePlaceholder(
        placeName: placeName,
        height: height,
        width: width,
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return PlaceImagePlaceholder(
            placeName: placeName,
            height: height,
            width: width,
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
