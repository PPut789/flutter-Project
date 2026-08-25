import 'package:flutter/material.dart';

import '../data/user_repository.dart';
import '../models/recommendation_preferences.dart';
import '../utils/app_routes.dart';
import '../widgets/app_chrome.dart';
import 'home_page.dart';

class InterestPage extends StatefulWidget {
  final List<String> selectedRegions;
  final List<String> selectedProvinces;
  final RecommendationPreferences? initialPreferences;

  const InterestPage({
    super.key,
    required this.selectedRegions,
    required this.selectedProvinces,
    this.initialPreferences,
  });

  @override
  State<InterestPage> createState() => _InterestPageState();
}

class _InterestPageState extends State<InterestPage> {
  List<String> categories = [
    "ธรรมชาติ",
    "ประวัติศาสตร์และวัฒนธรรม",
    "กิจกรรมพิเศษ/นันทนาการ",
  ];

  List<String> selectedCategories = [];

  List<String> types = [
    "ภูเขา",
    "น้ำตก",
    "จุดชมวิว",
    "ทะเลสาบ",
    "แม่น้ำและคลอง",
    "หมู่เกาะ",
    "อุทยานแห่งชาติ",
    "โบราณสถาน",
    "วัดและศาสนสถาน",
    "พิพิธภัณฑ์",
    "ชุมชน",
    "ตลาด/ช้อปปิ้ง",
    "สวนสัตว์",
    "ธีมปาร์ค",
    "ไร่และสวน",
    "สุขภาพและสปา",
    "น้ำพุร้อน",
  ];

  List<String> selectedTypes = [];

  List<String> activities = [
    "เดินป่า",
    "ชมวิว",
    "ถ่ายรูป",
    "พักผ่อน",
    "เล่นน้ำ",
    "ช้อปปิ้ง",
    "เรียนรู้วัฒนธรรม",
    "ไหว้พระ",
  ];

  List<String> selectedActivities = [];
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final preferences = widget.initialPreferences;
    if (preferences == null) return;

    selectedCategories.addAll(preferences.categories);
    selectedTypes.addAll(preferences.types);
    selectedActivities.addAll(preferences.activities);
  }

  bool get canGenerate =>
      selectedCategories.isNotEmpty &&
      selectedTypes.isNotEmpty &&
      selectedActivities.isNotEmpty;

  Future<void> _generateRecommendation() async {
    final preferences = RecommendationPreferences(
      regions: widget.selectedRegions,
      provinces: widget.selectedProvinces,
      categories: selectedCategories,
      types: selectedTypes,
      activities: selectedActivities,
    );

    setState(() {
      isSaving = true;
    });

    try {
      await UserRepository.savePreferences(preferences);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot save preferences. Please check Firestore rules.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      smoothRoute(HomePage(preferences: preferences)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const MinimalHeader(title: "เลือกความสนใจ"),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    //Chip ตัวเลือกของ Category
                    const Text(
                      "หมวดหมู่",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _InterestOptionGrid(
                      values: categories,
                      selectedValues: selectedCategories,
                      iconForValue: _categoryIcon,
                      onChanged: (category, selected) {
                        setState(() {
                          if (selected) {
                            selectedCategories.add(category);
                          } else {
                            selectedCategories.remove(category);
                          }
                        });
                      },
                    ),

                    //Chip ตัวเลือกของ Type
                    const SizedBox(height: 24),

                    const Text(
                      "ประเภทสถานที่",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _InterestOptionGrid(
                      values: types,
                      selectedValues: selectedTypes,
                      iconForValue: _typeIcon,
                      onChanged: (type, selected) {
                        setState(() {
                          if (selected) {
                            selectedTypes.add(type);
                          } else {
                            selectedTypes.remove(type);
                          }
                        });
                      },
                    ),

                    //Chip ตัวเลือกของ Activity
                    const SizedBox(height: 24),

                    const Text(
                      "กิจกรรม",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _InterestOptionGrid(
                      values: activities,
                      selectedValues: selectedActivities,
                      iconForValue: _activityIcon,
                      onChanged: (activity, selected) {
                        setState(() {
                          if (selected) {
                            selectedActivities.add(activity);
                          } else {
                            selectedActivities.remove(activity);
                          }
                        });
                      },
                    ),
                    //Chip ปุ่มเจนสถานที่ท่องเที่ยว
                    const SizedBox(height: 30),
                    PrimaryActionButton(
                      label: "ค้นหาสถานที่ท่องเที่ยว",
                      isLoading: isSaving,
                      onPressed: canGenerate
                          ? isSaving
                                ? null
                                : _generateRecommendation
                          : null,
                    ),

                    if (!canGenerate) ...[
                      const SizedBox(height: 12),
                      const Text(
                        "กรุณาเลือกอย่างน้อย 1 หมวดหมู่ 1 ประเภทสถานที่ และ 1 กิจกรรม",
                        style: TextStyle(color: appTextMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String value) {
    if (value.contains("ธรรมชาติ")) return Icons.landscape_outlined;
    if (value.contains("ประวัติศาสตร์")) return Icons.account_balance_outlined;
    return Icons.celebration_outlined;
  }

  IconData _typeIcon(String value) {
    if (value.contains("ภูเขา")) return Icons.terrain_outlined;
    if (value.contains("น้ำตก")) return Icons.waterfall_chart_outlined;
    if (value.contains("จุดชมวิว")) return Icons.visibility_outlined;
    if (value.contains("ทะเลสาบ")) return Icons.water_outlined;
    if (value.contains("แม่น้ำ")) return Icons.water_outlined;
    if (value.contains("หมู่เกาะ")) return Icons.beach_access_outlined;
    if (value.contains("อุทยาน")) return Icons.park_outlined;
    if (value.contains("โบราณ")) return Icons.account_balance_outlined;
    if (value.contains("วัด")) return Icons.temple_buddhist_outlined;
    if (value.contains("พิพิธภัณฑ์")) return Icons.museum_outlined;
    if (value.contains("ชุมชน")) return Icons.groups_outlined;
    if (value.contains("ตลาด")) return Icons.storefront_outlined;
    if (value.contains("สวนสัตว์")) return Icons.pets_outlined;
    if (value.contains("ธีมปาร์ค")) return Icons.attractions_outlined;
    if (value.contains("ไร่")) return Icons.local_florist_outlined;
    if (value.contains("สปา")) return Icons.spa_outlined;
    if (value.contains("น้ำพุร้อน")) return Icons.hot_tub_outlined;
    return Icons.place_outlined;
  }

  IconData _activityIcon(String value) {
    if (value.contains("เดินป่า")) return Icons.hiking_outlined;
    if (value.contains("ชมวิว")) return Icons.visibility_outlined;
    if (value.contains("ถ่ายรูป")) return Icons.photo_camera_outlined;
    if (value.contains("พักผ่อน")) return Icons.weekend_outlined;
    if (value.contains("เล่นน้ำ")) return Icons.pool_outlined;
    if (value.contains("ช้อปปิ้ง")) return Icons.shopping_bag_outlined;
    if (value.contains("วัฒนธรรม")) return Icons.diversity_3_outlined;
    if (value.contains("ไหว้พระ")) return Icons.temple_buddhist_outlined;
    return Icons.interests_outlined;
  }
}

class _InterestOptionGrid extends StatelessWidget {
  final List<String> values;
  final List<String> selectedValues;
  final IconData Function(String value) iconForValue;
  final void Function(String value, bool selected) onChanged;

  const _InterestOptionGrid({
    required this.values,
    required this.selectedValues,
    required this.iconForValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) {
        final value = values[index];
        final isSelected = selectedValues.contains(value);
        return _InterestOptionTile(
          label: value,
          icon: iconForValue(value),
          isSelected: isSelected,
          onTap: () => onChanged(value, !isSelected),
        );
      },
    );
  }
}

class _InterestOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestOptionTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.025 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF4E8F7) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFB65DC0)
                    : const Color(0xFFE8E0EC),
                width: isSelected ? 1.6 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF710078).withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 30 : 28,
                        height: isSelected ? 30 : 28,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF710078).withValues(alpha: 0.12)
                              : const Color(0xFFF7F3F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? const Color(0xFF710078)
                              : Colors.black54,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF710078)
                              : Colors.black87,
                          fontSize: 10.5,
                          height: 1.10,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            key: ValueKey('selected'),
                            color: Color(0xFF710078),
                            size: 18,
                          )
                        : const SizedBox(
                            key: ValueKey('unselected'),
                            width: 18,
                            height: 18,
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
