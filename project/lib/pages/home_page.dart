import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/history_repository.dart';
import '../data/local_recommendation_service.dart';
import '../data/place_repository.dart';
import '../data/place_search_service.dart';
import '../data/recommendation_repository.dart';
import '../data/user_repository.dart';
import '../models/app_settings.dart';
import '../models/place_model.dart';
import '../models/recommendation_preferences.dart';
import '../utils/app_routes.dart';
import '../utils/place_media.dart';
import '../widgets/app_chrome.dart';
import '../widgets/resolved_place_image.dart';
import 'detail_page.dart';
import 'location_page.dart';
import 'profile_page.dart';
import 'tiktok_page.dart';
import 'upload_video_page.dart';

const _homeBg = Color(0xFFD5EDFC);
const _homeBlue = Color(0xFF76ADD1);
const _homeBlueDark = Color(0xFF3A6384);
const _homeMuted = Color(0xFF7A93A7);
const _homeLine = Color(0xFFBFD1DF);

class HomePage extends StatefulWidget {
  final RecommendationPreferences preferences;
  final int initialTabIndex;

  const HomePage({
    super.key,
    required this.preferences,
    this.initialTabIndex = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchText = '';
  late int currentTabIndex;
  late final TextEditingController searchController;
  late final Future<_HomeData> homeDataFuture;
  late final Future<AppSettings> appSettingsFuture;

  @override
  void initState() {
    super.initState();
    currentTabIndex = widget.initialTabIndex;
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
    return Scaffold(
      backgroundColor: _homeBg,
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
          final additionalPlaces = places.length > 1
              ? places.sublist(1)
              : <Place>[];

          if (currentTabIndex == 3) {
            return VideoPage(places: allPlaces);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              const _HomeMainBackground(),
              CustomScrollView(
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
                  if (showSectionTitle)
                    SliverToBoxAdapter(
                      child: _HomeSectionHeader(
                        title: isSearching
                            ? 'ผลการค้นหา'
                            : 'สถานที่แนะนำสำหรับคุณ',
                        showViewAll: false,
                      ),
                    ),
                  if (!isSearching && places.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _FeaturedPlaceCard(
                          place: places.first,
                          onTap: () => _openPlaceDetail(places.first),
                        ),
                      ),
                    ),
                    if (additionalPlaces.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _HomeSectionHeader(
                          title: 'สถานที่แนะนำเพิ่มเติม',
                          showViewAll: true,
                          topPadding: 12,
                          onViewAll: () {
                            Navigator.push(
                              context,
                              smoothRoute(
                                AdditionalPlacesPage(
                                  title: 'สถานที่แนะนำเพิ่มเติม',
                                  places: additionalPlaces,
                                  onOpenPlace: _openPlaceDetail,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 220,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: additionalPlaces.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final place = additionalPlaces[index];
                              return _AdditionalPlaceCard(
                                place: place,
                                onTap: () => _openPlaceDetail(place),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  ] else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _TravelBottomNav(
        selectedIndex: currentTabIndex,
        onSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              smoothRoute(LocationPage(initialPreferences: widget.preferences)),
            );
            return;
          }

          if (index == 2) {
            Navigator.push(context, smoothRoute(const UploadVideoPage()));
            return;
          }

          if (index == 4) {
            Navigator.push(context, smoothRoute(const ProfilePage()));
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
        recommendedPlaces: LocalRecommendationService.rotateRecommendationOrder(
          recommendedPlaces,
          widget.preferences,
        ),
      );
    } catch (error) {
      debugPrint('Recommendation API unavailable, using fallback: $error');
      return _HomeData(
        allPlaces: allPlaces,
        recommendedPlaces: LocalRecommendationService.rotateRecommendationOrder(
          LocalRecommendationService.fallbackRecommendation(
            places: allPlaces,
            preferences: widget.preferences,
            historyBoost: historyBoost,
          ),
          widget.preferences,
        ),
      );
    }
  }

  List<Place> _displayPlaces(_HomeData homeData) {
    final query = PlaceSearchService.normalizeSearchText(searchText);

    if (query.isNotEmpty) {
      return PlaceSearchService.search(homeData.allPlaces, query);
    }

    return homeData.recommendedPlaces;
  }

  Future<void> _openPlaceDetail(Place place) async {
    final settings = await UserRepository.loadAppSettings(refresh: true);
    if (settings.saveViewingHistory) {
      await HistoryRepository.addViewedPlace(place);
    }
    if (!mounted) return;
    Navigator.push(context, smoothRoute(DetailPage(place: place)));
  }
}

class AdditionalPlacesPage extends StatefulWidget {
  final String title;
  final List<Place> places;
  final Future<void> Function(Place place) onOpenPlace;

  const AdditionalPlacesPage({
    super.key,
    required this.title,
    required this.places,
    required this.onOpenPlace,
  });

  @override
  State<AdditionalPlacesPage> createState() => _AdditionalPlacesPageState();
}

class _AdditionalPlacesPageState extends State<AdditionalPlacesPage> {
  late final TextEditingController searchController;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Place> get filteredPlaces {
    final query = PlaceSearchService.normalizeSearchText(searchText);
    if (query.isEmpty) return widget.places;
    return PlaceSearchService.search(widget.places, query);
  }

  @override
  Widget build(BuildContext context) {
    final places = filteredPlaces;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFF),
      body: SafeArea(
        child: AppPastelBackground(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  child: Row(
                    children: [
                      RoundBackButton(
                        onPressed: () => Navigator.pop(context),
                        backgroundColor: Colors.white.withValues(alpha: 0.86),
                        foregroundColor: const Color(0xFF171817),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.places.length} สถานที่',
                              style: const TextStyle(
                                color: Color(0xFF6B7E8C),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: _AdditionalSearchField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    onClear: () {
                      searchController.clear();
                      setState(() {
                        searchText = '';
                      });
                    },
                  ),
                ),
              ),
              if (places.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'ไม่พบสถานที่ที่ตรงกับคำค้นหา',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7E8C),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: places.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return _WideAdditionalPlaceCard(
                        place: place,
                        onTap: () async {
                          await widget.onOpenPlace(place);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdditionalSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _AdditionalSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7ECF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'ค้นหาสถานที่ จังหวัด หรือประเภท',
          hintStyle: const TextStyle(
            color: Color(0xFF7C8A94),
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF7EC8E3),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF6B7E8C),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _WideAdditionalPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _WideAdditionalPlaceCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageCandidates = placeImageCandidates(place);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 124,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD7ECF7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
                child: _PlaceImage(
                  imagePath: imageCandidates.isNotEmpty
                      ? imageCandidates.first
                      : '',
                  placeName: place.name,
                  width: 118,
                  height: 124,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFF6B7E8C),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${place.province} • ${place.region}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6B7E8C),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _SoftCategoryChip(text: place.category),
                          _SoftCategoryChip(text: place.type),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _homeBlueDark.withValues(alpha: 0.16)),
        ),
        boxShadow: [
          BoxShadow(
            color: _homeBlueDark.withValues(alpha: 0.16),
            blurRadius: 16,
            spreadRadius: -3,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
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

class _HomeMainBackground extends StatelessWidget {
  const _HomeMainBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: _homeBg);
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
    const activeColor = _homeBlueDark;
    const inactiveColor = Color(0xFF6F7C88);
    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 40,
            height: 30,
            decoration: BoxDecoration(
              color: isSelected ? _homeBlueDark.withValues(alpha: 0.16) : null,
              borderRadius: BorderRadius.circular(999),
              border: isSelected
                  ? Border.all(color: _homeBlueDark.withValues(alpha: 0.18))
                  : null,
            ),
            child: Icon(icon, color: color, size: isSelected ? 22 : 21),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
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
    const buttonColor = _homeBlueDark;

    return Material(
      color: buttonColor,
      shape: const CircleBorder(),
      elevation: 10,
      shadowColor: buttonColor.withValues(alpha: 0.38),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
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
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 8,
        20,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _WelcomeBadge(username: username),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "สวัสดี, $username",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _homeBlueDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "พร้อมออกไปค้นหาสถานที่ใหม่หรือยัง?",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _homeBlueDark,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: "ค้นหาสถานที่ท่องเที่ยว...",
                hintStyle: const TextStyle(
                  color: Color(0xFF9AAEC0),
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6D8396),
                ),
                suffixIcon: searchText.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close_rounded),
                        color: _homeMuted,
                        tooltip: 'ล้างคำค้นหา',
                      ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.86),
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: _homeBlue, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBadge extends StatelessWidget {
  final String username;

  const _WelcomeBadge({required this.username});

  @override
  Widget build(BuildContext context) {
    final trimmed = username.trim();
    final initial = trimmed.isEmpty
        ? 'U'
        : trimmed.substring(0, 1).toUpperCase();

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _homeBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _homeBlue.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  final String title;
  final bool showViewAll;
  final double topPadding;
  final VoidCallback? onViewAll;

  const _HomeSectionHeader({
    required this.title,
    required this.showViewAll,
    this.topPadding = 8,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 8),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              color: _homeBlue,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: _homeBlue.withValues(alpha: 0.28),
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _homeBlueDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                height: 1.1,
              ),
            ),
          ),
          if (showViewAll) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onViewAll,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ดูทั้งหมด',
                        style: TextStyle(
                          color: _homeBlueDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _homeBlueDark,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeaturedPlaceCard extends StatefulWidget {
  final Place place;
  final VoidCallback onTap;

  const _FeaturedPlaceCard({required this.place, required this.onTap});

  @override
  State<_FeaturedPlaceCard> createState() => _FeaturedPlaceCardState();
}

class _FeaturedPlaceCardState extends State<_FeaturedPlaceCard> {
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
        borderRadius: BorderRadius.circular(18),
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          _setPressed(false);
          widget.onTap();
        },
        child: Container(
          height: 210,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _homeLine.withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: _homeBlueDark.withValues(alpha: isPressed ? 0.08 : 0.16),
                blurRadius: isPressed ? 12 : 24,
                offset: Offset(0, isPressed ? 4 : 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.16),
                        Colors.black.withValues(alpha: 0.62),
                      ],
                      stops: const [0.42, 0.70, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${place.province} • ${place.region}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _OverlayChip(text: place.category),
                          _OverlayChip(text: place.type),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdditionalPlaceCard extends StatefulWidget {
  final Place place;
  final VoidCallback onTap;

  const _AdditionalPlaceCard({required this.place, required this.onTap});

  @override
  State<_AdditionalPlaceCard> createState() => _AdditionalPlaceCardState();
}

class _AdditionalPlaceCardState extends State<_AdditionalPlaceCard> {
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
      scale: isPressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          _setPressed(false);
          widget.onTap();
        },
        child: Container(
          width: 168,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _homeLine.withValues(alpha: 0.60)),
            boxShadow: [
              BoxShadow(
                color: _homeBlueDark.withValues(alpha: isPressed ? 0.04 : 0.10),
                blurRadius: isPressed ? 8 : 16,
                offset: Offset(0, isPressed ? 2 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlaceImage(
                  imagePath: imageCandidates.isNotEmpty
                      ? imageCandidates.first
                      : '',
                  placeName: place.name,
                  height: 112,
                  width: double.infinity,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1.18,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place.province,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _homeMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SoftCategoryChip(text: place.category),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: _SoftCategoryChip(text: place.type),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  final String text;

  const _OverlayChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final tone = _preferenceToneFor(text);
    return Container(
      constraints: const BoxConstraints(maxWidth: 156),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.accent.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: tone.accent.withValues(alpha: 0.26),
            blurRadius: 8,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: tone.text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SoftCategoryChip extends StatelessWidget {
  final String text;

  const _SoftCategoryChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final tone = _preferenceToneFor(text);
    final isShortLabel = text.length <= 10;
    return Container(
      constraints: const BoxConstraints(maxWidth: 116),
      alignment: isShortLabel ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.accent.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: tone.accent.withValues(alpha: 0.20),
            blurRadius: 6,
            spreadRadius: -2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isShortLabel ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: tone.text,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PreferenceTone {
  final Color background;
  final Color accent;
  final Color text;

  const _PreferenceTone({
    required this.background,
    required this.accent,
    required this.text,
  });
}

_PreferenceTone _preferenceToneFor(String label) {
  final accent = _preferenceAccentFor(label);

  return _PreferenceTone(
    background: Color.lerp(Colors.white, accent, 0.36)!,
    accent: accent,
    text: Color.lerp(_homeBlueDark, accent, 0.52)!,
  );
}

Color _preferenceAccentFor(String label) {
  if (label.contains("ธรรมชาติ")) {
    return const Color(0xFF3AA6C8);
  }
  if (label.contains("ภูเขา") ||
      label.contains("เดินป่า") ||
      label.contains("อุทยาน")) {
    return const Color(0xFF3E9F83);
  }
  if (label.contains("หมู่เกาะ")) {
    return const Color(0xFF1FAEAF);
  }
  if (label.contains("น้ำตก") ||
      label.contains("แม่น้ำ") ||
      label.contains("ทะเลสาบ") ||
      label.contains("ทะเล") ||
      label.contains("ชายหาด") ||
      label.contains("เกาะ") ||
      label.contains("เล่นน้ำ")) {
    return const Color(0xFF22A9D6);
  }
  if (label.contains("จุดชมวิว") || label.contains("ชมวิว")) {
    return const Color(0xFFD6A431);
  }
  if (label.contains("วัฒนธรรม") ||
      label.contains("ประวัติศาสตร์") ||
      label.contains("โบราณ") ||
      label.contains("วัด") ||
      label.contains("พิพิธภัณฑ์") ||
      label.contains("ไหว้พระ")) {
    return const Color(0xFF8E78D6);
  }
  if (label.contains("ตลาด") || label.contains("ช้อป")) {
    return const Color(0xFFC9903B);
  }
  if (label.contains("พักผ่อน") ||
      label.contains("สปา") ||
      label.contains("สุขภาพ")) {
    return const Color(0xFF54BFA9);
  }
  if (label.contains("ถ่ายรูป") ||
      label.contains("กิจกรรม") ||
      label.contains("ธีมปาร์ค")) {
    return const Color(0xFFD76FA2);
  }
  if (label.contains("สวนสัตว์") ||
      label.contains("ไร่") ||
      label.contains("สวน")) {
    return const Color(0xFF72A94B);
  }
  if (label.contains("ชุมชน")) {
    return const Color(0xFF4F9BD6);
  }
  if (label.contains("น้ำพุร้อน")) {
    return const Color(0xFFD47A52);
  }
  return const Color(0xFF4A8FBD);
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
        borderRadius: BorderRadius.circular(16),
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
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _homeLine.withValues(alpha: 0.64)),
            boxShadow: [
              BoxShadow(
                color: _homeBlueDark.withValues(alpha: isPressed ? 0.04 : 0.10),
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
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Hero(
                      tag: _placeHeroTag(place),
                      child: _PlaceImage(
                        imagePath: imageCandidates.isNotEmpty
                            ? imageCandidates.first
                            : '',
                        placeName: place.name,
                        height: 196,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.08),
                          ],
                        ),
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
                        color: _homeBlueDark,
                        fontSize: 20,
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
                      style: const TextStyle(color: _homeMuted, height: 1.45),
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
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF7EC8E3)),
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
    return ResolvedPlaceImage(
      imagePath: imagePath,
      placeName: placeName,
      height: height,
      width: width,
    );
  }
}
