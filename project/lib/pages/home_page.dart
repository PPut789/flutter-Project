import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/history_repository.dart';
import '../data/place_repository.dart';
import '../data/recommendation_repository.dart';
import '../models/place_model.dart';
import '../models/recommendation_preferences.dart';
import 'detail_page.dart';
import 'location_page.dart';
import 'profile_page.dart';
import 'tiktok_page.dart';

class HomePage extends StatefulWidget {
  final RecommendationPreferences preferences;

  const HomePage({super.key, required this.preferences});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchText = '';
  int currentTabIndex = 0;
  late final TextEditingController searchController;
  late final Future<_HomeData> homeDataFuture;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    homeDataFuture = _loadHomeData();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F8),
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

          if (currentTabIndex == 2) {
            return TikTokPage(places: allPlaces);
          }

          if (currentTabIndex == 3) {
            return const ProfilePage();
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HomeHeader(
                  controller: searchController,
                  username: username,
                  searchText: searchText,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isSearching ? "Search Results" : "Recommended",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _ResultCountPill(count: places.length),
                    ],
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
                          return _PlaceCard(place: places[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTabIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LocationPage(initialPreferences: widget.preferences),
              ),
            );
            return;
          }

          setState(() {
            currentTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: "Home"),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            label: "Preferences",
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            label: "TikTok",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Future<_HomeData> _loadHomeData() async {
    final allPlaces = await PlaceRepository.loadPlaces();
    try {
      final recommendedPlaces = await RecommendationRepository.recommendPlaces(
        preferences: widget.preferences,
        places: allPlaces,
      );
      return _HomeData(
        allPlaces: allPlaces,
        recommendedPlaces: recommendedPlaces,
      );
    } catch (error) {
      debugPrint('Recommendation API unavailable, using fallback: $error');
      return _HomeData(
        allPlaces: allPlaces,
        recommendedPlaces: _fallbackRecommendation(allPlaces),
      );
    }
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

  List<Place> _fallbackRecommendation(List<Place> places) {
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
            .map((place) => _ScoredPlace(place, _scorePlace(place)))
            .where((item) => item.score > 0)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

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

  int _scorePlace(Place place) {
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

    return score;
  }
}

class _HomeHeader extends StatelessWidget {
  final TextEditingController controller;
  final String username;
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const _HomeHeader({
    required this.controller,
    required this.username,
    required this.searchText,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF281634),
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 26),
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
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white12,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search destinations...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchText.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear search',
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCountPill extends StatelessWidget {
  final int count;

  const _ResultCountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8E0EC)),
      ),
      child: Text(
        '$count places',
        style: const TextStyle(
          color: Color(0xFF710078),
          fontWeight: FontWeight.w800,
          fontSize: 12,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isSearching
            ? 'No attractions match your search.'
            : 'No attractions match your preferences.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;

  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E0EC)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await HistoryRepository.addViewedPlace(place);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailPage(place: place)),
          );
        },
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
                  child: _PlaceImage(
                    imagePath: place.images.isNotEmpty
                        ? place.images.first
                        : 'assets/images/maya_bay.jpg',
                    height: 210,
                    width: double.infinity,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _CardBadge(text: place.category),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _ImageCountBadge(count: place.images.length),
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
                      _MetaPill(
                        icon: Icons.category_outlined,
                        text: place.type,
                      ),
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
                  if (place.tags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: place.tags.take(3).map((tag) {
                        return _TagPill(text: tag);
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final String text;

  const _CardBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
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

class _ImageCountBadge extends StatelessWidget {
  final int count;

  const _ImageCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
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
        color: const Color(0xFFF7F3F8),
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

class _TagPill extends StatelessWidget {
  final String text;

  const _TagPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF286B5E),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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
  final double height;
  final double width;

  const _PlaceImage({
    required this.imagePath,
    required this.height,
    required this.width,
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
