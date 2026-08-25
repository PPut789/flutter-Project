import 'package:flutter/material.dart';

import '../data/history_repository.dart';
import '../models/place_model.dart';
import '../utils/app_routes.dart';
import '../utils/place_media.dart';
import '../widgets/app_chrome.dart';
import '../widgets/place_image_placeholder.dart';
import 'detail_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Future<void> _clearHistory(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const AppConfirmDialog(
        icon: Icons.delete_outline_rounded,
        title: 'ล้างประวัติ?',
        message: 'ลบสถานที่ทั้งหมดจากประวัติการเข้าชมของคุณ',
        confirmLabel: 'ล้างประวัติ',
        isDestructive: true,
      ),
    );

    if (confirm != true) return;
    await HistoryRepository.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<HistoryItem>>(
                stream: HistoryRepository.watchHistory(),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <HistoryItem>[];

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Column(
                      children: [
                        MinimalHeader(title: 'ประวัติการเข้าชม'),
                        Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        const MinimalHeader(title: 'ประวัติการเข้าชม'),
                        Expanded(
                          child: EmptyStateCard(
                            icon: Icons.error_outline,
                            title: 'โหลดประวัติไม่ได้',
                            message: '${snapshot.error}',
                          ),
                        ),
                      ],
                    );
                  }

                  if (items.isEmpty) {
                    return const Column(
                      children: [
                        MinimalHeader(title: 'ประวัติการเข้าชม'),
                        Expanded(
                          child: EmptyStateCard(
                            icon: Icons.history_rounded,
                            title: 'ยังไม่มีประวัติการเข้าชม',
                            message: 'สถานที่ที่คุณเปิดดูจะแสดงอยู่ที่นี่',
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      MinimalHeader(
                        title: 'ประวัติการเข้าชม',
                        actions: [
                          IconButton(
                            tooltip: 'ล้างประวัติ',
                            onPressed: () => _clearHistory(context),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: items.length + 1,
                          separatorBuilder: (context, index) =>
                              const Divider(color: appBorder, height: 1),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _HistorySummary(count: items.length);
                            }
                            return _HistoryTile(item: items[index - 1]);
                          },
                        ),
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

class _HistorySummary extends StatelessWidget {
  final int count;

  const _HistorySummary({required this.count});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: appPurpleSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: appBorder),
        ),
        child: Text(
          'เข้าชม $count สถานที่',
          style: const TextStyle(
            color: appPurple,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;

  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final place = item.place;

    return InkWell(
      onTap: () {
        Navigator.push(context, smoothRoute(DetailPage(place: place)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _HistoryImage(place: place),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${place.province} • ${place.region}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: appTextMuted),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatViewedAt(item.viewedAt),
                    style: const TextStyle(color: appTextMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  String _formatViewedAt(DateTime? value) {
    if (value == null) return 'ล่าสุด';
    final now = DateTime.now();
    final date = DateTime(value.year, value.month, value.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(date).inDays;
    if (difference == 0) return 'วันนี้';
    if (difference == 1) return 'เมื่อวาน';
    return '${value.day}/${value.month}/${value.year}';
  }
}

class _HistoryImage extends StatelessWidget {
  final Place place;

  const _HistoryImage({required this.place});

  @override
  Widget build(BuildContext context) {
    final imageCandidates = placeImageCandidates(place);
    final imagePath = imageCandidates.isNotEmpty ? imageCandidates.first : '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imagePath.isEmpty
          ? PlaceImagePlaceholder(placeName: place.name, width: 64, height: 64)
          : imagePath.startsWith('http')
          ? Image.network(
              imagePath,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  PlaceImagePlaceholder(
                    placeName: place.name,
                    width: 64,
                    height: 64,
                  ),
            )
          : Image.asset(imagePath, width: 64, height: 64, fit: BoxFit.cover),
    );
  }
}
