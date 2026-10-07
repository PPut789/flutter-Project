import 'package:flutter/material.dart';

import '../models/recommendation_preferences.dart';
import '../utils/app_routes.dart';
import 'interest_page.dart';

const _locationBg = Color(0xFF012059);
const _locationBlue = Color(0xFF76ADD1);
const _locationBlueDark = Color(0xFF3A6384);
const _locationMuted = Color(0xFF7A93A7);
const _locationLine = Color(0xFFBFD1DF);

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

    if (preferences.regions.isNotEmpty) {
      selectedRegions.add(preferences.regions.first);
    }
    selectedProvinces.addAll(preferences.provinces);
  }

  List<String> get visibleProvinces {
    return selectedRegions
        .expand((region) => provincesByRegion[region] ?? const <String>[])
        .toSet()
        .toList()
      ..sort();
  }

  bool get canContinue =>
      selectedRegions.isNotEmpty && selectedProvinces.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _locationBg,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _LocationImageBackground()),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                  child: Row(
                    children: [
                      if (widget.initialPreferences != null)
                        _RoundBackButton(onTap: () => Navigator.pop(context)),
                      if (widget.initialPreferences != null)
                        const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "เลือกพื้นที่ที่สนใจ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
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
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "เลือกสิ่งที่คุณชอบ เพื่อแนะนำสถานที่ให้เหมาะกับคุณ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _LocationGlassPanel(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                          child: Column(
                            children: provincesByRegion.keys.map((region) {
                              final isSelected = selectedRegions.contains(
                                region,
                              );
                              final provinceCount =
                                  provincesByRegion[region]?.length ?? 0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _RegionCard(
                                  region: region,
                                  provinceCount: provinceCount,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        return;
                                      }
                                      selectedRegions
                                        ..clear()
                                        ..add(region);
                                      selectedProvinces.removeWhere(
                                        (province) =>
                                            !(provincesByRegion[region]
                                                    ?.contains(province) ??
                                                false),
                                      );
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (selectedRegions.isNotEmpty) ...[
                          Expanded(
                            child: _LocationGlassPanel(
                              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "จังหวัดที่สนใจ",
                                    style: TextStyle(
                                      color: _locationBlueDark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Expanded(
                                    child: GridView.builder(
                                      padding: EdgeInsets.zero,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: visibleProvinces.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 4,
                                            mainAxisSpacing: 7,
                                            crossAxisSpacing: 7,
                                            childAspectRatio: 3.08,
                                          ),
                                      itemBuilder: (context, index) {
                                        final province =
                                            visibleProvinces[index];
                                        final isSelected = selectedProvinces
                                            .contains(province);
                                        return _ProvinceChip(
                                          province: province,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                selectedProvinces.remove(
                                                  province,
                                                );
                                              } else {
                                                selectedProvinces.add(province);
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _LocationNextButton(
                          enabled: canContinue,
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
    final accentColor = _locationBlue;
    final imagePath = isNorth
        ? 'assets/images/region_north.png'
        : 'assets/images/region_south.png';
    final subtitle = isNorth
        ? "ภูเขา อากาศเย็น วัฒนธรรมล้านนา"
        : "ทะเล เกาะสวย อาหารรสจัด";

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 132,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: isSelected ? 0.95 : 0.82),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _locationBlueDark.withValues(
                alpha: isSelected ? 0.17 : 0.08,
              ),
              blurRadius: isSelected ? 14 : 10,
              spreadRadius: -3,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: 1.06,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isNorth
                            ? const [Color(0xFFEAF5FB), Color(0xFF76ADD1)]
                            : const [Color(0xFFF8FCFF), Color(0xFFDFF1FA)],
                      ),
                    ),
                  );
                },
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    _locationBlueDark.withValues(alpha: 0.18),
                    _locationBlueDark.withValues(alpha: 0.62),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 56,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    region,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 13,
              bottom: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_rounded
                      : Icons.chevron_right_rounded,
                  color: isSelected ? Colors.white : _locationBlueDark,
                  size: 24,
                ),
              ),
            ),
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
      color: isSelected ? const Color(0xFFE5F4FB) : _locationBlueDark,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? _locationBlue.withValues(alpha: 0.55)
                  : _locationBlueDark,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _locationBlue.withValues(alpha: 0.22),
                      blurRadius: 9,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: _locationBlueDark.withValues(alpha: 0.18),
                      blurRadius: 8,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Text(
            province,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? _locationBlueDark : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationNextButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const _LocationNextButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FractionallySizedBox(
        alignment: Alignment.center,
        widthFactor: 0.66,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [_locationBlue, _locationBlueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: enabled ? null : Colors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: enabled ? _locationBlueDark : _locationLine,
            ),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: _locationBlue.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
            ],
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: _locationMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ถัดไป'),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RoundBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            Icons.arrow_back_ios_new,
            color: _locationBlueDark,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _LocationImageBackground extends StatelessWidget {
  const _LocationImageBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: _locationBg);
  }
}

class _LocationGlassPanel extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _LocationGlassPanel({required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 7,
            spreadRadius: -3,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
