import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../data/user_repository.dart';
import '../utils/app_routes.dart';
import '../widgets/app_chrome.dart';
import 'about_app_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'location_page.dart';
import 'my_videos_page.dart';
import 'settings_page.dart';
import 'start_page.dart';
import 'upload_video_page.dart';

const _profileBg = Color(0xFF012059);
const _profilePrimary = Color(0xFF76ADD1);
const _profilePrimaryDark = Color(0xFF3A6384);
const _profileMuted = Color(0xFF7A93A7);
const _profileLine = Color(0xFFE4EDF3);
const _profileDanger = Color(0xFFD66D6D);
const _profileIconBg = Color(0xFFEFF6FA);

class ProfilePage extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfilePage({super.key, this.onBack});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool isUploadingPhoto = false;
  bool isSigningOut = false;
  String? localPhotoUrl;
  late Future<String> profilePhotoFuture;

  @override
  void initState() {
    super.initState();
    profilePhotoFuture = UserRepository.loadProfilePhotoUrl();
  }

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
        profilePhotoFuture = Future.value(photoUrl);
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
    if (isSigningOut) return;
    setState(() {
      isSigningOut = true;
    });

    UserRepository.clearCachedSettings();
    try {
      await FirebaseAuth.instance.signOut();

      try {
        await GoogleSignIn.instance.signOut().timeout(
          const Duration(seconds: 3),
        );
      } catch (_) {
        // Firebase sign-out is the source of truth for app navigation.
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isSigningOut = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถออกจากระบบได้: $error')));
      return;
    }
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushAndRemoveUntil(smoothRoute(const StartPage()), (route) => false);
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

  Future<void> _openHomeTab(int tabIndex) async {
    final preferences = await UserRepository.loadPreferences();
    if (!mounted) return;

    if (preferences == null) {
      Navigator.pushReplacement(context, smoothRoute(const LocationPage()));
      return;
    }

    Navigator.pushReplacement(
      context,
      smoothRoute(
        HomePage(preferences: preferences, initialTabIndex: tabIndex),
      ),
    );
  }

  Future<void> _openPreferences() async {
    final preferences = await UserRepository.loadPreferences();
    if (!mounted) return;
    Navigator.push(
      context,
      smoothRoute(LocationPage(initialPreferences: preferences)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final email = user?.email?.trim();

    return Scaffold(
      backgroundColor: _profileBg,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _ProfileImageBackground()),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 760;

                return Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, isCompact ? 6 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileTopBar(onBack: _goBack, isCompact: isCompact),
                      SizedBox(height: isCompact ? 8 : 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FutureBuilder<String>(
                          future: profilePhotoFuture,
                          builder: (context, snapshot) {
                            final loadedPhotoUrl = snapshot.data?.trim();
                            final photoUrl =
                                localPhotoUrl ??
                                (loadedPhotoUrl?.isNotEmpty == true
                                    ? loadedPhotoUrl
                                    : user?.photoURL);

                            return _ProfileHeader(
                              photoUrl: photoUrl,
                              displayName: displayName?.isNotEmpty == true
                                  ? displayName!
                                  : 'คุณนักเดินทาง',
                              email: email?.isNotEmpty == true
                                  ? email!
                                  : 'ไม่มีอีเมล',
                              isUploadingPhoto: isUploadingPhoto,
                              isCompact: isCompact,
                              onChangePhoto: isUploadingPhoto
                                  ? null
                                  : _changeProfilePhoto,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: isCompact ? 16 : 28),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'บัญชีของฉัน',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 6 : 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ProfileMenuGroup(
                          isCompact: isCompact,
                          children: [
                            _ProfileMenuTile(
                              icon: Icons.history_rounded,
                              title: 'ประวัติการเข้าชม',
                              iconColor: const Color(0xFF5B93AF),
                              isCompact: isCompact,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  smoothRoute(const HistoryPage()),
                                );
                              },
                            ),
                            _ProfileMenuTile(
                              icon: Icons.videocam_outlined,
                              title: 'วิดีโอของฉัน',
                              iconColor: const Color(0xFF69A8A4),
                              isCompact: isCompact,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  smoothRoute(const MyVideosPage()),
                                );
                              },
                            ),
                            _ProfileMenuTile(
                              icon: Icons.info_outline_rounded,
                              title: 'เกี่ยวกับแอป',
                              iconColor: const Color(0xFF8D80B8),
                              isCompact: isCompact,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  smoothRoute(const AboutAppPage()),
                                );
                              },
                            ),
                            _ProfileMenuTile(
                              icon: Icons.settings_outlined,
                              title: 'การตั้งค่า',
                              iconColor: const Color(0xFFB49A56),
                              isCompact: isCompact,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  smoothRoute(const SettingsPage()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompact ? 8 : 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _LogoutTile(
                          title: isSigningOut
                              ? 'กำลังออกจากระบบ...'
                              : 'ออกจากระบบ',
                          isCompact: isCompact,
                          onTap: _signOut,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ProfileBottomNav(
        selectedIndex: 4,
        onSelected: (index) {
          if (index == 0) {
            _openHomeTab(0);
            return;
          }

          if (index == 1) {
            _openPreferences();
            return;
          }

          if (index == 2) {
            Navigator.push(context, smoothRoute(const UploadVideoPage()));
            return;
          }

          if (index == 3) {
            _openHomeTab(3);
          }
        },
      ),
    );
  }
}

class _ProfileImageBackground extends StatelessWidget {
  const _ProfileImageBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: _profileBg, child: SizedBox.expand());
  }
}

class _ProfileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ProfileBottomNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _profilePrimaryDark.withValues(alpha: 0.16)),
        ),
        boxShadow: [
          BoxShadow(
            color: _profilePrimaryDark.withValues(alpha: 0.16),
            blurRadius: 16,
            spreadRadius: -3,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
          child: Row(
            children: [
              Expanded(
                child: _ProfileBottomNavItem(
                  icon: Icons.home_outlined,
                  label: 'หน้าแรก',
                  isSelected: selectedIndex == 0,
                  onTap: () => onSelected(0),
                ),
              ),
              Expanded(
                child: _ProfileBottomNavItem(
                  icon: Icons.explore_outlined,
                  label: 'ความสนใจ',
                  isSelected: selectedIndex == 1,
                  onTap: () => onSelected(1),
                ),
              ),
              Expanded(
                child: Center(
                  child: _ProfileAddNavButton(onTap: () => onSelected(2)),
                ),
              ),
              Expanded(
                child: _ProfileBottomNavItem(
                  icon: Icons.smart_display_outlined,
                  label: 'วิดีโอ',
                  isSelected: selectedIndex == 3,
                  onTap: () => onSelected(3),
                ),
              ),
              Expanded(
                child: _ProfileBottomNavItem(
                  icon: Icons.person_outline,
                  label: 'โปรไฟล์',
                  isSelected: selectedIndex == 4,
                  onTap: () => onSelected(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileBottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = _profilePrimaryDark;
    const inactiveColor = Color(0xFF6F7C88);
    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 40,
            height: 30,
            decoration: BoxDecoration(
              color: isSelected
                  ? _profilePrimaryDark.withValues(alpha: 0.16)
                  : null,
              borderRadius: BorderRadius.circular(999),
              border: isSelected
                  ? Border.all(
                      color: _profilePrimaryDark.withValues(alpha: 0.18),
                    )
                  : null,
            ),
            child: Icon(icon, color: color, size: isSelected ? 22 : 21),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAddNavButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileAddNavButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const buttonColor = _profilePrimaryDark;

    return Material(
      color: buttonColor,
      shape: const CircleBorder(),
      elevation: 10,
      shadowColor: buttonColor.withValues(alpha: 0.38),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final bool isCompact;

  const _ProfileTopBar({required this.onBack, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        isCompact ? 14 : 24,
        20,
        isCompact ? 8 : 12,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: SizedBox(
                width: isCompact ? 30 : 38,
                height: isCompact ? 30 : 38,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: isCompact ? 16 : 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'โปรไฟล์ของฉัน',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 20 : 23,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 9,
                    offset: const Offset(0, 2),
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

class _ProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String email;
  final bool isUploadingPhoto;
  final bool isCompact;
  final VoidCallback? onChangePhoto;

  const _ProfileHeader({
    required this.photoUrl,
    required this.displayName,
    required this.email,
    required this.isUploadingPhoto,
    required this.isCompact,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        isCompact ? 12 : 22,
        18,
        isCompact ? 14 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _EditableProfileAvatar(
            photoUrl: photoUrl,
            isUploading: isUploadingPhoto,
            isCompact: isCompact,
            onTap: onChangePhoto,
          ),
          SizedBox(height: isCompact ? 8 : 12),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _profilePrimaryDark,
              fontSize: isCompact ? 19 : 23,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: isCompact ? 5 : 8),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 10.5 : 12.5,
              color: _profileMuted.withValues(alpha: 0.76),
            ),
          ),
          SizedBox(height: isCompact ? 8 : 14),
          FilledButton.icon(
            onPressed: onChangePhoto,
            icon: Icon(
              isUploadingPhoto ? Icons.hourglass_top_rounded : Icons.edit,
              size: 17,
            ),
            label: Text(isUploadingPhoto ? 'กำลังอัปโหลด...' : 'แก้ไขโปรไฟล์'),
            style: FilledButton.styleFrom(
              foregroundColor: _profilePrimaryDark,
              backgroundColor: appSkySoft,
              minimumSize: Size(148, isCompact ? 32 : 38),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              visualDensity: VisualDensity.compact,
              textStyle: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isCompact ? 14 : 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final bool isUploading;
  final bool isCompact;
  final VoidCallback? onTap;

  const _EditableProfileAvatar({
    required this.photoUrl,
    required this.isUploading,
    required this.isCompact,
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
            radius: isCompact ? 32 : 48,
            backgroundColor: _profileIconBg,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Icon(
                    Icons.person_outline,
                    color: _profilePrimaryDark,
                    size: isCompact ? 31 : 46,
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
                width: 30,
                height: 30,
                child: isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(7),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.photo_camera_outlined,
                        color: _profilePrimary,
                        size: 17,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuGroup extends StatelessWidget {
  final bool isCompact;
  final List<_ProfileMenuTile> children;

  const _ProfileMenuGroup({required this.isCompact, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
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
                endIndent: 24,
                color: _profileLine,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final bool isCompact;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: isCompact ? 57 : 70,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: isCompact ? 40 : 48,
                  height: isCompact ? 40 : 48,
                  decoration: const BoxDecoration(
                    color: _profileIconBg,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: isCompact ? 22 : 25,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _profilePrimaryDark,
                      fontSize: isCompact ? 17 : 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _profileMuted.withValues(alpha: 0.62),
                  size: isCompact ? 23 : 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final String title;
  final bool isCompact;
  final VoidCallback onTap;

  const _LogoutTile({
    required this.title,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: isCompact ? 48 : 58,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _profilePrimaryDark.withValues(alpha: 0.05),
                blurRadius: 18,
                spreadRadius: -10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: _profileDanger,
                size: isCompact ? 23 : 26,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _profileDanger,
                    fontSize: isCompact ? 16 : 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _profileDanger,
                size: isCompact ? 23 : 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
