import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/user_repository.dart';
import '../utils/app_routes.dart';
import '../widgets/app_chrome.dart';
import 'about_app_page.dart';
import 'history_page.dart';
import 'login_page.dart';
import 'my_videos_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfilePage({super.key, this.onBack});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool isUploadingPhoto = false;
  String? localPhotoUrl;

  Future<void> _changeProfilePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 86,
    );
    if (image == null) return;

    setState(() {
      isUploadingPhoto = true;
    });

    try {
      final photoUrl = await UserRepository.updateProfilePhoto(image);
      if (!mounted) return;
      setState(() {
        localPhotoUrl = photoUrl;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot update profile photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    UserRepository.clearCachedSettings();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      smoothRoute(const LoginPage()),
      (route) => false,
    );
  }

  void _goBack() {
    final callback = widget.onBack;
    if (callback != null) {
      callback();
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final email = user?.email?.trim();
    final photoUrl = localPhotoUrl ?? user?.photoURL;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
          children: [
            MinimalHeader(title: 'โปรไฟล์ของฉัน', onBack: _goBack),
            const SizedBox(height: 46),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ProfileHeader(
                photoUrl: photoUrl,
                displayName: displayName?.isNotEmpty == true
                    ? displayName!
                    : 'คุณนักเดินทาง',
                email: email?.isNotEmpty == true ? email! : 'ไม่มีอีเมล',
                isUploadingPhoto: isUploadingPhoto,
                onChangePhoto: isUploadingPhoto ? null : _changeProfilePhoto,
              ),
            ),
            const SizedBox(height: 36),
            _ProfileMenuTile(
              icon: Icons.history_rounded,
              title: 'ประวัติการเข้าชม',
              onTap: () {
                Navigator.push(context, smoothRoute(const HistoryPage()));
              },
            ),
            _ProfileMenuTile(
              icon: Icons.video_library_outlined,
              title: 'วิดีโอของฉัน',
              onTap: () {
                Navigator.push(context, smoothRoute(const MyVideosPage()));
              },
            ),
            const _ProfileSectionGap(),
            _ProfileMenuTile(
              icon: Icons.info_outline_rounded,
              title: 'เกี่ยวกับแอป',
              onTap: () {
                Navigator.push(context, smoothRoute(const AboutAppPage()));
              },
            ),
            _ProfileMenuTile(
              icon: Icons.settings_outlined,
              title: 'การตั้งค่า',
              onTap: () {
                Navigator.push(context, smoothRoute(const SettingsPage()));
              },
            ),
            const _ProfileSectionGap(),
            _ProfileMenuTile(
              icon: Icons.logout_rounded,
              title: 'ออกจากระบบ',
              isDestructive: true,
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String email;
  final bool isUploadingPhoto;
  final VoidCallback? onChangePhoto;

  const _ProfileHeader({
    required this.photoUrl,
    required this.displayName,
    required this.email,
    required this.isUploadingPhoto,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _EditableProfileAvatar(
          photoUrl: photoUrl,
          isUploading: isUploadingPhoto,
          onTap: onChangePhoto,
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: appTextMuted),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onChangePhoto,
          style: OutlinedButton.styleFrom(
            foregroundColor: appPurple,
            side: const BorderSide(color: appBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Text(
            isUploadingPhoto ? 'กำลังอัปโหลด...' : 'เปลี่ยนรูปโปรไฟล์',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final bool isUploading;
  final VoidCallback? onTap;

  const _EditableProfileAvatar({
    required this.photoUrl,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Colors.white,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? const CircleAvatar(
                    radius: 42,
                    backgroundColor: Color(0xFFEADDEE),
                    child: Icon(
                      Icons.person_outline,
                      color: Color(0xFF7B2B83),
                      size: 42,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          right: -2,
          bottom: 4,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 28,
                height: 28,
                child: isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(7),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.photo_camera_outlined,
                        color: Colors.black,
                        size: 18,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive
        ? Colors.redAccent
        : const Color(0xFF766D79);
    final textColor = isDestructive ? Colors.redAccent : Colors.black87;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: appBorder, width: 0.8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18.5),
        child: Row(
          children: [
            SizedBox(width: 38, child: Icon(icon, color: iconColor, size: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: iconColor),
          ],
        ),
      ),
    );
  }
}

class _ProfileSectionGap extends StatelessWidget {
  const _ProfileSectionGap();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: appPurpleSoft, child: SizedBox(height: 8));
  }
}
