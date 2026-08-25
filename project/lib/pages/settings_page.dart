import 'package:flutter/material.dart';

import '../data/history_repository.dart';
import '../data/user_repository.dart';
import '../models/app_settings.dart';
import '../widgets/app_chrome.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppSettings settings = const AppSettings();
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final loadedSettings = await UserRepository.loadAppSettings(refresh: true);
    if (!mounted) return;
    setState(() {
      settings = loadedSettings;
      isLoading = false;
    });
  }

  Future<void> _updateSettings(AppSettings nextSettings) async {
    final previousSettings = settings;
    setState(() {
      settings = nextSettings;
      isSaving = true;
    });

    try {
      await UserRepository.saveAppSettings(nextSettings);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        settings = previousSettings;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot save settings: $error')));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const AppConfirmDialog(
        icon: Icons.delete_outline_rounded,
        title: 'ล้างประวัติ?',
        message: 'ลบสถานที่ทั้งหมดจากประวัติการเข้าชมของคุณ',
        confirmLabel: 'ล้างประวัติ',
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;

    try {
      await HistoryRepository.clearHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Viewing history cleared')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot clear history: $error')));
    }
  }

  Future<void> _resetSettings() async {
    const defaultSettings = AppSettings();
    await _updateSettings(defaultSettings);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings reset')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            MinimalHeader(
              title: 'การตั้งค่า',
              actions: [
                if (isSaving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                      children: [
                        const _SectionTitle(title: 'การเล่นวิดีโอ'),
                        _SettingsSwitchTile(
                          title: 'เล่นวิดีโออัตโนมัติ',
                          value: settings.autoplayVideos,
                          onChanged: isSaving
                              ? null
                              : (value) => _updateSettings(
                                  settings.copyWith(autoplayVideos: value),
                                ),
                        ),
                        _SettingsSwitchTile(
                          title: 'เริ่มวิดีโอแบบปิดเสียง',
                          value: settings.startVideosMuted,
                          onChanged: isSaving
                              ? null
                              : (value) => _updateSettings(
                                  settings.copyWith(startVideosMuted: value),
                                ),
                        ),
                        const _SectionTitle(title: 'ความเป็นส่วนตัวและประวัติ'),
                        _SettingsSwitchTile(
                          title: 'บันทึกประวัติการเข้าชม',
                          value: settings.saveViewingHistory,
                          onChanged: isSaving
                              ? null
                              : (value) => _updateSettings(
                                  settings.copyWith(saveViewingHistory: value),
                                ),
                        ),
                        _SettingsActionTile(
                          title: 'ล้างประวัติการเข้าชม',
                          onTap: _clearHistory,
                          isDestructive: true,
                        ),
                        const _SectionTitle(title: 'แอปพลิเคชัน'),
                        _SettingsActionTile(
                          title: 'คืนค่าการตั้งค่าเริ่มต้น',
                          onTap: isSaving ? null : _resetSettings,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: appPurpleSoft,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6D6070),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTileLayout(
      title: title,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      onTap: onChanged == null ? null : () => onChanged!(!value),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsActionTile({
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : Colors.black87;

    return _SettingsTileLayout(
      title: title,
      color: color,
      onTap: onTap,
      trailing: const SizedBox.shrink(),
    );
  }
}

class _SettingsTileLayout extends StatelessWidget {
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color color;

  const _SettingsTileLayout({
    required this.title,
    required this.trailing,
    required this.onTap,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}
