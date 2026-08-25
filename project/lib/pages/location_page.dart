import 'package:flutter/material.dart';

import '../models/recommendation_preferences.dart';
import '../utils/app_routes.dart';
import '../widgets/app_chrome.dart';
import 'interest_page.dart';

class LocationPage extends StatefulWidget {
  final RecommendationPreferences? initialPreferences;

  const LocationPage({super.key, this.initialPreferences});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final Map<String, List<String>> provincesByRegion = const {
    "ภาคเหนือ": [
      "กำแพงเพชร",
      "ตาก",
      "นครสวรรค์",
      "น่าน",
      "พะเยา",
      "พิจิตร",
      "พิษณุโลก",
      "ลำปาง",
      "ลำพูน",
      "สุโขทัย",
      "อุตรดิตถ์",
      "อุทัยธานี",
      "เชียงราย",
      "เชียงใหม่",
      "เพชรบูรณ์",
      "แพร่",
      "แม่ฮ่องสอน",
    ],
    "ภาคใต้": [
      "กระบี่",
      "ชุมพร",
      "ตรัง",
      "นครศรีธรรมราช",
      "นราธิวาส",
      "ปัตตานี",
      "พังงา",
      "พัทลุง",
      "ภูเก็ต",
      "ยะลา",
      "ระนอง",
      "สงขลา",
      "สตูล",
      "สุราษฎร์ธานี",
    ],
  };

  final List<String> selectedRegions = [];
  final List<String> selectedProvinces = [];

  @override
  void initState() {
    super.initState();
    final preferences = widget.initialPreferences;
    if (preferences == null) return;

    selectedRegions.addAll(preferences.regions);
    selectedProvinces.addAll(preferences.provinces);
  }

  List<String> get visibleProvinces {
    return selectedRegions
        .expand((region) => provincesByRegion[region] ?? const <String>[])
        .toSet()
        .toList()
      ..sort();
  }

  bool get canContinue => selectedRegions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.initialPreferences != null)
              const MinimalHeader(title: "เลือกพื้นที่ท่องเที่ยว")
            else
              const Padding(
                padding: EdgeInsets.fromLTRB(28, 24, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "เลือกพื้นที่ท่องเที่ยว",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ภูมิภาคที่สนใจ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: provincesByRegion.keys.map((region) {
                        final isSelected = selectedRegions.contains(region);
                        final provinceCount =
                            provincesByRegion[region]?.length ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RegionCard(
                            region: region,
                            provinceCount: provinceCount,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedRegions.remove(region);
                                  selectedProvinces.removeWhere(
                                    (province) =>
                                        provincesByRegion[region]?.contains(
                                          province,
                                        ) ??
                                        false,
                                  );
                                } else {
                                  selectedRegions.add(region);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "จังหวัดที่สนใจ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: visibleProvinces.map((province) {
                        final isSelected = selectedProvinces.contains(province);
                        return SizedBox(
                          width: (MediaQuery.sizeOf(context).width - 64) / 4,
                          child: _ProvinceChip(
                            province: province,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedProvinces.remove(province);
                                } else {
                                  selectedProvinces.add(province);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    PrimaryActionButton(
                      label: "ถัดไป",
                      onPressed: canContinue
                          ? () {
                              Navigator.push(
                                context,
                                smoothRoute(
                                  InterestPage(
                                    selectedRegions: selectedRegions,
                                    selectedProvinces: selectedProvinces,
                                    initialPreferences:
                                        widget.initialPreferences,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionCard extends StatelessWidget {
  final String region;
  final int provinceCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegionCard({
    required this.region,
    required this.provinceCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNorth = region == "ภาคเหนือ";
    final accentColor = const Color(0xFF710078);
    final icon = isNorth ? Icons.terrain_outlined : Icons.waves_outlined;
    final subtitle = isNorth
        ? "ภูเขา อากาศเย็น วัฒนธรรมล้านนา"
        : "ทะเล เกาะสวย อาหารรสจัด";

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8F1FA) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE2DDE7),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F0F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: accentColor),
          ],
        ),
      ),
    );
  }
}

class _ProvinceChip extends StatelessWidget {
  final String province;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProvinceChip({
    required this.province,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFF6EDF8) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? appPurple : appBorder,
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Text(
            province,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? appPurple : Colors.black87,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
