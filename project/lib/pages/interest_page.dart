import 'package:flutter/material.dart';

import '../data/user_repository.dart';
import '../models/recommendation_preferences.dart';
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
      MaterialPageRoute(
        builder: (context) => HomePage(preferences: preferences),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Interests")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              //Chip ตัวเลือกของ Category
              const Text(
                "Category",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 10,
                runSpacing: 10,

                children: categories.map((category) {
                  return FilterChip(
                    label: Text(category),

                    selected: selectedCategories.contains(category),

                    onSelected: (bool value) {
                      setState(() {
                        if (value) {
                          selectedCategories.add(category);
                        } else {
                          selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              //Chip ตัวเลือกของ Type
              const SizedBox(height: 24),

              const Text(
                "Type",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 10,
                runSpacing: 10,

                children: types.map((type) {
                  return FilterChip(
                    label: Text(type),

                    selected: selectedTypes.contains(type),

                    onSelected: (bool value) {
                      setState(() {
                        if (value) {
                          selectedTypes.add(type);
                        } else {
                          selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              //Chip ตัวเลือกของ Activity
              const SizedBox(height: 24),

              const Text(
                "Activity",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 10,
                runSpacing: 10,

                children: activities.map((activity) {
                  return FilterChip(
                    label: Text(activity),

                    selected: selectedActivities.contains(activity),

                    onSelected: (bool value) {
                      setState(() {
                        if (value) {
                          selectedActivities.add(activity);
                        } else {
                          selectedActivities.remove(activity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              //Chip ปุ่มเจนสถานที่ท่องเที่ยว
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: canGenerate
                      ? isSaving
                            ? null
                            : _generateRecommendation
                      : null,

                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Generate Recommendation"),
                ),
              ),

              if (!canGenerate) ...[
                const SizedBox(height: 12),
                const Text(
                  "Please select at least 1 Category, 1 Type, and 1 Activity.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
