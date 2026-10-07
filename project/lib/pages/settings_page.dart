import 'package:flutter/material.dart';

import '../data/history_repository.dart';
import '../data/user_repository.dart';
import '../models/app_settings.dart';
import '../widgets/app_chrome.dart';

const _settingsBg = Color(0xFFEAF5FB);
const _settingsPrimary = Color(0xFF76ADD1);
const _settingsPrimaryDark = Color(0xFF3A6384);
const _settingsMuted = Color(0xFF7A93A7);
const _settingsLine = Color(0xFFE4EDF3);
const _settingsDanger = Color(0xFFD66D6D);
const _settingsIconBg = Color(0xFFEFF6FA);

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
      backgroundColor: _settingsBg,
      body: SafeArea(
        child: ColoredBox(
          color: _settingsBg,
          child: Column(
            children: [
              _SettingsHeader(
                isSaving: isSaving,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        children: [
                          _SettingsGroup(
                            title: 'การเล่นวิดีโอ',
                            children: [
                              _SettingsSwitchTile(
                                icon: Icons.play_circle_outline_rounded,
                                iconColor: const Color(0xFF5B93AF),
                                title: 'เล่นวิดีโออัตโนมัติ',
                                value: settings.autoplayVideos,
                                onChanged: isSaving
                                    ? null
                                    : (value) => _updateSettings(
                                        settings.copyWith(
                                          autoplayVideos: value,
                                        ),
                                      ),
                              ),
                              _SettingsSwitchTile(
                                icon: Icons.volume_off_outlined,
                                iconColor: const Color(0xFF69A8A4),
                                title: 'เริ่มวิดีโอแบบปิดเสียง',
                                value: settings.startVideosMuted,
                                onChanged: isSaving
                                    ? null
                                    : (value) => _updateSettings(
                                        settings.copyWith(
                                          startVideosMuted: value,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _SettingsGroup(
                            title: 'ความเป็นส่วนตัวและประวัติ',
                            children: [
                              _SettingsSwitchTile(
                                icon: Icons.history_rounded,
                                iconColor: const Color(0xFF8D80B8),
                                title: 'บันทึกประวัติการเข้าชม',
                                value: settings.saveViewingHistory,
                                onChanged: isSaving
                                    ? null
                                    : (value) => _updateSettings(
                                        settings.copyWith(
                                          saveViewingHistory: value,
                                        ),
                                      ),
                              ),
                              _SettingsActionTile(
                                icon: Icons.delete_outline_rounded,
                                iconColor: _settingsDanger,
                                title: 'ล้างประวัติการเข้าชม',
                                onTap: _clearHistory,
                                isDestructive: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _SettingsGroup(
                            title: 'แอปพลิเคชัน',
                            children: [
                              _SettingsActionTile(
                                icon: Icons.restart_alt_rounded,
                                iconColor: const Color(0xFFB49A56),
                                title: 'คืนค่าการตั้งค่าเริ่มต้น',
                                onTap: isSaving ? null : _resetSettings,
                              ),
                            ],
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

class _SettingsHeader extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onBack;

  const _SettingsHeader({required this.isSaving, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _settingsPrimaryDark,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'การตั้งค่า',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _settingsPrimaryDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'จัดการการใช้งานและความเป็นส่วนตัว',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _settingsMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isSaving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: _settingsPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _settingsPrimaryDark.withValues(alpha: 0.07),
                blurRadius: 22,
                spreadRadius: -10,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    endIndent: 20,
                    color: _settingsLine,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTileLayout(
      icon: icon,
      iconColor: iconColor,
      title: title,
      trailing: Switch.adaptive(
        value: value,
        activeThumbColor: _settingsPrimaryDark,
        activeTrackColor: _settingsPrimary.withValues(alpha: 0.35),
        onChanged: onChanged,
      ),
      onTap: onChanged == null ? null : () => onChanged!(!value),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? _settingsDanger : _settingsPrimaryDark;

    return _SettingsTileLayout(
      icon: icon,
      iconColor: iconColor,
      title: title,
      color: color,
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color.withValues(alpha: 0.74),
        size: 26,
      ),
    );
  }
}

class _SettingsTileLayout extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color color;

  const _SettingsTileLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const SizedBox(width: 20),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: _settingsIconBg,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            trailing,
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}
