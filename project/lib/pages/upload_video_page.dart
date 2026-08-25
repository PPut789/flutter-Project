import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/place_repository.dart';
import '../data/video_repository.dart';
import '../models/place_model.dart';
import '../widgets/app_chrome.dart';

class UploadVideoPage extends StatefulWidget {
  const UploadVideoPage({super.key});

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _mapsController = TextEditingController();

  XFile? selectedVideo;
  Place? selectedPlace;
  bool useGoogleMaps = false;
  bool isUploading = false;
  bool isChangingPlace = false;
  String placeQuery = '';
  late final Future<List<Place>> placesFuture;

  @override
  void initState() {
    super.initState();
    placesFuture = PlaceRepository.loadPlaces();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _searchController.dispose();
    _mapsController.dispose();
    super.dispose();
  }

  bool get canUpload {
    final hasLocation = useGoogleMaps
        ? _mapsController.text.trim().isNotEmpty
        : selectedPlace != null;
    return selectedVideo != null && hasLocation && !isUploading;
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    setState(() {
      selectedVideo = video;
    });
  }

  Future<void> _upload() async {
    final file = selectedVideo;
    if (file == null || !canUpload) return;

    setState(() {
      isUploading = true;
    });

    try {
      await VideoRepository.uploadVideo(
        file: file,
        caption: _captionController.text,
        selectedPlace: useGoogleMaps ? null : selectedPlace,
        googleMapsUrl: useGoogleMaps ? _mapsController.text : '',
        googlePlaceName: '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot upload video: $error')));
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  List<Place> _filterPlaces(List<Place> places) {
    final query = _normalize(placeQuery);
    if (query.isEmpty) {
      if (selectedPlace != null) return [selectedPlace!];
      return const <Place>[];
    }

    return places
        .where((place) {
          return [
            place.name,
            place.nameEn,
            place.province,
            place.region,
            place.category,
            place.type,
          ].map(_normalize).any((value) => value.contains(query));
        })
        .take(20)
        .toList();
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const MinimalHeader(title: 'อัปโหลดวิดีโอ'),
            Expanded(
              child: FutureBuilder<List<Place>>(
                future: placesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Cannot load places: ${snapshot.error}'),
                      ),
                    );
                  }

                  final places = snapshot.data ?? const <Place>[];
                  final filteredPlaces = _filterPlaces(places);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      _VideoPickerBox(
                        fileName: selectedVideo?.name,
                        onTap: isUploading ? null : _pickVideo,
                      ),
                      const SizedBox(height: 22),
                      const _SectionTitle(
                        title: 'ระบุสถานที่',
                        subtitle: 'เลือกสถานที่ในแอปหรือใช้ลิงก์ Google Maps',
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.place_outlined),
                            label: Text('In app'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.map_outlined),
                            label: Text('Google Maps'),
                          ),
                        ],
                        selected: {useGoogleMaps},
                        onSelectionChanged: isUploading
                            ? null
                            : (value) {
                                setState(() {
                                  useGoogleMaps = value.first;
                                });
                              },
                      ),
                      const SizedBox(height: 14),
                      if (useGoogleMaps) ...[
                        TextField(
                          controller: _mapsController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'วางลิงก์ Google Maps',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.link_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ] else ...[
                        if (selectedPlace != null && !isChangingPlace)
                          _SelectedPlaceCard(
                            place: selectedPlace!,
                            onChange: isUploading
                                ? null
                                : () {
                                    setState(() {
                                      isChangingPlace = true;
                                      _searchController.clear();
                                      placeQuery = '';
                                    });
                                  },
                          )
                        else ...[
                          TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                placeQuery = value;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'ค้นหาสถานที่...',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (placeQuery.trim().isEmpty)
                            const SizedBox.shrink()
                          else if (filteredPlaces.isEmpty)
                            const _NoPlaceResults()
                          else
                            ...filteredPlaces.map((place) {
                              final isSelected =
                                  selectedPlace?.documentId == place.documentId;
                              return _PlaceOption(
                                place: place,
                                isSelected: isSelected,
                                onTap: isUploading
                                    ? null
                                    : () {
                                        setState(() {
                                          selectedPlace = place;
                                          isChangingPlace = false;
                                          _searchController.clear();
                                          placeQuery = '';
                                        });
                                      },
                              );
                            }),
                        ],
                      ],
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'คำบรรยาย',
                        subtitle: 'เขียนคำอธิบายสั้นๆ สำหรับวิดีโอนี้',
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _captionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'อธิบายวิดีโอของคุณ...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryActionButton(
                        label: isUploading
                            ? 'กำลังอัปโหลด...'
                            : 'อัปโหลดวิดีโอ',
                        isLoading: isUploading,
                        icon: Icons.cloud_upload_outlined,
                        onPressed: canUpload ? _upload : null,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPickerBox extends StatelessWidget {
  final String? fileName;
  final VoidCallback? onTap;

  const _VideoPickerBox({required this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCFAFD),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: appBorder, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_rounded, color: appTextMuted, size: 36),
              const SizedBox(height: 10),
              Text(
                fileName == null ? 'เลือกไฟล์วิดีโอ' : fileName!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: appTextMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Color(0xFF6B626E))),
      ],
    );
  }
}

class _NoPlaceResults extends StatelessWidget {
  const _NoPlaceResults();

  @override
  Widget build(BuildContext context) {
    return const _SmallHintCard(
      icon: Icons.search_off_outlined,
      text: 'No places match this search.',
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback? onChange;

  const _SelectedPlaceCard({required this.place, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1DDF5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: appPurple, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${place.province}, ${place.region}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: appTextMuted),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('เปลี่ยน')),
        ],
      ),
    );
  }
}

class _SmallHintCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallHintCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E0EC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF710078), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF6B626E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceOption extends StatelessWidget {
  final Place place;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PlaceOption({
    required this.place,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? const Color(0xFFEEDCF2) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${place.province}, ${place.region}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B626E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF710078)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
