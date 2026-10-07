import 'package:flutter/material.dart';

import '../data/user_repository.dart';
import '../models/recommendation_preferences.dart';
import '../utils/app_routes.dart';
import 'home_page.dart';

const _interestBg = Color(0xFF012059);
const _interestPanelTint = Color(0xFFEAF5FB);
const _interestInk = Color(0xFF263F52);
const _interestMuted = Color(0xFF7A93A7);
const _interestPrimary = Color(0xFF76ADD1);
const _interestPrimaryDark = Color(0xFF3A6384);
const _interestLine = Color(0xFFBFD1DF);

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
      backgroundColor: _interestBg,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _InterestScenicBackground(),
            Column(
              children: [
                _InterestHeader(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "เลือกสิ่งที่คุณชอบ เพื่อให้เราแนะนำสถานที่ที่เหมาะกับคุณ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InterestContentPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _InterestSectionHeader(
                                title: "ความสนใจหลัก",
                                icon: Icons.favorite_rounded,
                              ),
                              const SizedBox(height: 10),
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
                              const SizedBox(height: 18),
                              const _InterestSectionHeader(
                                title: "ประเภทสถานที่",
                                icon: Icons.place_rounded,
                                trailing: "เลือกได้หลายข้อ",
                              ),
                              const SizedBox(height: 10),
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
                              const SizedBox(height: 18),
                              const _InterestSectionHeader(
                                title: "กิจกรรมที่ชอบ",
                                icon: Icons.star_rounded,
                                trailing: "เลือกได้หลายข้อ",
                              ),
                              const SizedBox(height: 10),
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
                              const SizedBox(height: 14),
                              _InterestSelectionSummary(
                                count:
                                    selectedCategories.length +
                                    selectedTypes.length +
                                    selectedActivities.length,
                                onClear: () {
                                  setState(() {
                                    selectedCategories.clear();
                                    selectedTypes.clear();
                                    selectedActivities.clear();
                                  });
                                },
                              ),
                              if (!canGenerate) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  "เลือกอย่างน้อย 1 หมวดหมู่ 1 ประเภทสถานที่ และ 1 กิจกรรม",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _interestMuted,
                                    fontSize: 11.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InterestNextButton(
                          label: "ถัดไป",
                          isLoading: isSaving,
                          onPressed: canGenerate
                              ? isSaving
                                    ? null
                                    : _generateRecommendation
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

class _InterestScenicBackground extends StatelessWidget {
  const _InterestScenicBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: _interestBg);
  }
}

class _InterestHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _InterestHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: _interestPrimaryDark,
            iconSize: 18,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.86),
              fixedSize: const Size(38, 38),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "เลือกความสนใจ",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 9,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestContentPanel extends StatelessWidget {
  final Widget child;

  const _InterestContentPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.72),
            blurRadius: 3,
            spreadRadius: -1,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InterestSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? trailing;

  const _InterestSectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: _interestPrimaryDark,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _interestPrimaryDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _interestPrimary, width: 1.15),
              boxShadow: [
                BoxShadow(
                  color: _interestPrimaryDark.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: _interestPrimaryDark,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _InterestSelectionSummary extends StatelessWidget {
  final int count;
  final VoidCallback onClear;

  const _InterestSelectionSummary({required this.count, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _interestPanelTint.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: _interestPrimary,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              count > 0
                  ? "คุณได้เลือกไปแล้ว $count รายการ"
                  : "ยังไม่ได้เลือกรายการ",
              style: const TextStyle(
                color: _interestPrimaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: count > 0 ? onClear : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: count > 0
                        ? _interestPrimaryDark
                        : _interestMuted.withValues(alpha: 0.55),
                    size: 15,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    "ล้างทั้งหมด",
                    style: TextStyle(
                      color: count > 0
                          ? _interestPrimaryDark
                          : _interestMuted.withValues(alpha: 0.55),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.08,
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
    final accentColor = _accentColorFor(label);
    final tileFill = _tileFillFor(label, isSelected);
    final iconBgColor = Color.lerp(
      Colors.white,
      accentColor,
      isSelected ? 0.36 : 0.28,
    )!;
    final iconColor = Color.lerp(_interestPrimaryDark, accentColor, 0.68)!;

    return AnimatedScale(
      scale: isSelected ? 1.025 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
            decoration: BoxDecoration(
              color: tileFill,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : Color.lerp(tileFill, accentColor, 0.55)!,
                width: isSelected ? 1.9 : 1.35,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(
                    alpha: isSelected ? 0.20 : 0.11,
                  ),
                  blurRadius: isSelected ? 11 : 7,
                  spreadRadius: -1.5,
                  offset: Offset(0, isSelected ? 5 : 3),
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
                        width: 41,
                        height: 41,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.96),
                              iconBgColor,
                              Color.lerp(iconBgColor, accentColor, 0.36)!,
                            ],
                            stops: const [0, 0.58, 1],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Color.lerp(Colors.white, accentColor, 0.28)!,
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.82),
                              blurRadius: 4,
                              spreadRadius: -1,
                              offset: const Offset(-2, -2),
                            ),
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.28),
                              blurRadius: 11,
                              spreadRadius: -1,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: _interestPrimaryDark.withValues(
                                alpha: 0.16,
                              ),
                              blurRadius: 8,
                              spreadRadius: -3,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 23,
                          weight: 700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? _interestPrimaryDark
                              : _interestInk,
                          fontSize: 10,
                          height: 1.12,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: isSelected
                        ? Container(
                            key: ValueKey('selected'),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          )
                        : Container(
                            key: ValueKey('unselected'),
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color.lerp(
                                  _interestLine,
                                  accentColor,
                                  0.34,
                                )!,
                                width: 1.15,
                              ),
                            ),
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

Color _tileFillFor(String label, bool isSelected) {
  final accent = _accentColorFor(label);
  final amount = isSelected ? 0.30 : 0.21;
  return Color.lerp(Colors.white, accent, amount)!;
}

Color _accentColorFor(String label) {
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

class _InterestNextButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _InterestNextButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FractionallySizedBox(
        alignment: Alignment.center,
        widthFactor: 0.66,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: onPressed == null
                ? null
                : const LinearGradient(
                    colors: [_interestPrimary, _interestPrimaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: onPressed == null
                ? Colors.white.withValues(alpha: 0.80)
                : null,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: onPressed == null ? _interestLine : _interestPrimaryDark,
            ),
            boxShadow: [
              if (onPressed != null)
                BoxShadow(
                  color: _interestPrimary.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
            ],
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: _interestMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, size: 22),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
