import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../providers/user_provider.dart';
import '../widgets/shared_widgets.dart';
import '../utils/app_theme.dart';

// ─────────────────────── NOTIFICATIONS ───────────────────────────────────────

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snap.data?.docs
                  .map((d) => AppNotification.fromFirestore(d))
                  .toList() ??
              [];

          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: "You're all caught up",
              subtitle: "We'll notify you when something new happens.",
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (_, i) {
              final n = notifications[i];
              return _NotifTile(notification: n);
            },
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notification;

  const _NotifTile({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.chat_bubble;
      case NotificationType.reply:
        return Icons.reply;
      case NotificationType.eventReminder:
        return Icons.event;
      default:
        return Icons.notifications;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.like:
        return AppTheme.terracotta;
      case NotificationType.comment:
      case NotificationType.reply:
        return AppTheme.brandGreen;
      default:
        return const Color(0xFF0077B6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead ? null : AppTheme.brandGreenPale.withOpacity(0.3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _iconColor.withOpacity(0.1),
          child: Icon(_icon, color: _iconColor, size: 20),
        ),
        title: Text(notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.w400 : FontWeight.w600,
              fontSize: 14,
            )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body,
                style: const TextStyle(fontSize: 13, color: AppTheme.midGrey)),
            Text(timeago.format(notification.createdAt),
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.midGrey)),
          ],
        ),
        onTap: notification.postId != null
            ? () {
                // Mark as read
                FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(notification.id)
                    .update({'isRead': true});
                context.push('/post/${notification.postId}');
              }
            : null,
      ),
    );
  }
}

// ─────────────────────── PROFILE ─────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _uploadingPhoto = false;

  bool get _isOwnProfile {
    final myUid = context.read<UserProvider>().user?.uid;
    return widget.userId == null || widget.userId == myUid;
  }

  Future<void> _changePhoto(AppUser user) async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance.ref('avatars/${user.uid}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': url});
      await context.read<UserProvider>().refreshUser();
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUser = context.watch<UserProvider>().user;
    final uid = widget.userId ?? myUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: _isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
              ]
            : null,
      ),
      body: uid == null
          ? const Center(child: Text('No user'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final AppUser? profileUser =
                    snap.data!.exists ? AppUser.fromFirestore(snap.data!) : null;
                if (profileUser == null) return const Center(child: Text('User not found'));

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        color: AppTheme.white,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                UserAvatar(
                                  photoUrl: profileUser.photoUrl,
                                  displayName: profileUser.displayName,
                                  radius: 40,
                                ),
                                if (_isOwnProfile)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _changePhoto(profileUser),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.brandGreen,
                                          shape: BoxShape.circle,
                                        ),
                                        child: _uploadingPhoto
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppTheme.white))
                                            : const Icon(Icons.camera_alt,
                                                size: 14,
                                                color: AppTheme.white),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profileUser.displayName,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.charcoal),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on,
                                    size: 14, color: AppTheme.midGrey),
                                const SizedBox(width: 2),
                                Text(
                                  '${profileUser.suburb}, ${profileUser.state}',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppTheme.midGrey),
                                ),
                              ],
                            ),
                            if (profileUser.isAdmin) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.terracotta.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Community Admin',
                                  style: TextStyle(
                                      color: AppTheme.terracotta,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Posts
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: const [
                            Text('Posts',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppTheme.charcoal)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .where('authorId', isEqualTo: uid)
                            .where('isRemoved', isEqualTo: false)
                            .orderBy('createdAt', descending: true)
                            .limit(20)
                            .snapshots(),
                        builder: (_, snap) {
                          final posts = snap.data?.docs
                                  .map((d) => Post.fromFirestore(d))
                                  .toList() ??
                              [];
                          if (posts.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No posts yet.',
                                  style: TextStyle(color: AppTheme.midGrey)),
                            );
                          }
                          return Column(
                            children: posts
                                .map((p) => PostCard(
                                      post: p,
                                      onTap: () =>
                                          context.push('/post/${p.id}'),
                                    ))
                                .toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────── SETTINGS ────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (user != null) ...[
            const SizedBox(height: 12),
            _SectionHeader('Account'),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Display name',
              subtitle: user.displayName,
              onTap: () => _editName(context, user),
            ),
            _SettingsTile(
              icon: Icons.location_on_outlined,
              title: 'Suburb',
              subtitle: '${user.suburb}, ${user.state}',
              onTap: () => context.push('/select-suburb-edit'),
            ),
            _SettingsTile(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: user.email,
            ),

            const SizedBox(height: 12),
            _SectionHeader('Notifications'),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Push notifications',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: AppTheme.brandGreen,
              ),
            ),

            if (user.isAdmin) ...[
              const SizedBox(height: 12),
              _SectionHeader('Admin'),
              _SettingsTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin dashboard',
                onTap: () => context.push('/admin'),
              ),
            ],

            const SizedBox(height: 12),
            _SectionHeader('More'),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About My Suburb',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy policy',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of service',
              onTap: () {},
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await userProvider.signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, color: AppTheme.terracotta),
                label: const Text('Sign out',
                    style: TextStyle(color: AppTheme.terracotta)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.terracotta),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  void _editName(BuildContext context, AppUser user) {
    final ctrl = TextEditingController(text: user.displayName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'displayName': ctrl.text.trim()});
              await context.read<UserProvider>().refreshUser();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.midGrey,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.brandGreen, size: 22),
        title: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppTheme.midGrey))
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: AppTheme.midGrey)
                : null),
        onTap: onTap,
      ),
    );
  }
}
