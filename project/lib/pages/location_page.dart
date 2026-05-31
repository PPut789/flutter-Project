import 'package:flutter/material.dart';

import '../models/recommendation_preferences.dart';
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Where do you want to go?"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Region",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Column(
                children: provincesByRegion.keys.map((region) {
                  final isSelected = selectedRegions.contains(region);
                  final provinceCount = provincesByRegion[region]?.length ?? 0;

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
                "Province",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                selectedRegions.isEmpty
                    ? "Select at least one region first."
                    : "Province is optional. Choose one or more if you want to narrow the results.",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: visibleProvinces.map((province) {
                  return FilterChip(
                    label: Text(province),
                    selected: selectedProvinces.contains(province),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedProvinces.add(province);
                        } else {
                          selectedProvinces.remove(province);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InterestPage(
                                selectedRegions: selectedRegions,
                                selectedProvinces: selectedProvinces,
                                initialPreferences: widget.initialPreferences,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Text("Continue"),
                ),
              ),
            ],
          ),
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
    final accentColor = isNorth
        ? const Color(0xFF2E7D32)
        : const Color(0xFF0277BD);
    final icon = isNorth ? Icons.terrain_outlined : Icons.waves_outlined;
    final subtitle = isNorth
        ? "Mountains, temples, old towns"
        : "Beaches, islands, coastal cities";

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE2DDE7),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
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
                  const SizedBox(height: 6),
                  Text(
                    "$provinceCount provinces available",
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isSelected
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey("selected"),
                      color: accentColor,
                    )
                  : const Icon(
                      Icons.circle_outlined,
                      key: ValueKey("unselected"),
                      color: Colors.grey,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
