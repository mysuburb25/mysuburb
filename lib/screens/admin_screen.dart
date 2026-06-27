import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: AppTheme.terracotta, size: 20),
            const SizedBox(width: 8),
            const Text('Admin Dashboard'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.brandGreen,
          unselectedLabelColor: AppTheme.midGrey,
          indicatorColor: AppTheme.brandGreen,
          tabs: const [
            Tab(text: 'Reports'),
            Tab(text: 'Users'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportsTab(db: _db),
          _UsersTab(db: _db),
          _StatsTab(db: _db),
        ],
      ),
    );
  }
}

// ─────────────────────── REPORTS TAB ─────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  final FirebaseFirestore db;

  const _ReportsTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('reports')
          .where('isResolved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snap.data?.docs
                .map((d) => Report.fromFirestore(d))
                .toList() ??
            [];

        if (reports.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No open reports',
            subtitle: 'All reports have been resolved.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (_, i) => _ReportCard(
            report: reports[i],
            onResolve: () async {
              await db
                  .collection('reports')
                  .doc(reports[i].id)
                  .update({'isResolved': true});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report marked as resolved.')),
                );
              }
            },
            onRemoveContent: () async {
              if (reports[i].contentType == 'post') {
                await db.collection('posts').doc(reports[i].contentId).update({
                  'isRemoved': true,
                });
              } else if (reports[i].contentType == 'comment') {
                await db.collection('comments').doc(reports[i].contentId).delete();
              }
              await db
                  .collection('reports')
                  .doc(reports[i].id)
                  .update({'isResolved': true});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content removed.')),
                );
              }
            },
          ),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onResolve;
  final VoidCallback onRemoveContent;

  const _ReportCard({
    required this.report,
    required this.onResolve,
    required this.onRemoveContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.terracotta.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.terracotta.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.contentType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.terracotta,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(report.createdAt),
                style: const TextStyle(fontSize: 11, color: AppTheme.midGrey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Reason: ${report.reason}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.charcoal,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Content ID: ${report.contentId.substring(0, 12)}...',
            style: const TextStyle(fontSize: 12, color: AppTheme.midGrey),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onResolve,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.brandGreen,
                    side: const BorderSide(color: AppTheme.brandGreen),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Dismiss', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRemoveContent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.terracotta,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    'Remove content',
                    style: TextStyle(fontSize: 13, color: AppTheme.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ─────────────────────── USERS TAB ───────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  final FirebaseFirestore db;

  const _UsersTab({required this.db});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: widget.db
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var users = snap.data?.docs
                      .map((d) => AppUser.fromFirestore(d))
                      .toList() ??
                  [];

              if (_search.isNotEmpty) {
                users = users
                    .where((u) =>
                        u.displayName.toLowerCase().contains(_search) ||
                        u.email.toLowerCase().contains(_search) ||
                        u.suburb.toLowerCase().contains(_search))
                    .toList();
              }

              if (users.isEmpty) {
                return const Center(
                    child: Text('No users found.',
                        style: TextStyle(color: AppTheme.midGrey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: users.length,
                itemBuilder: (_, i) => _AdminUserTile(
                  user: users[i],
                  onToggleSuspend: () async {
                    await widget.db.collection('users').doc(users[i].uid).update({
                      'isSuspended': !users[i].isSuspended,
                    });
                  },
                  onToggleBan: () async {
                    final confirm = await _confirmDialog(
                      context,
                      users[i].isBanned ? 'Unban user?' : 'Ban user?',
                      users[i].isBanned
                          ? 'This will restore their access.'
                          : 'This will permanently remove their access.',
                    );
                    if (confirm == true) {
                      await widget.db
                          .collection('users')
                          .doc(users[i].uid)
                          .update({'isBanned': !users[i].isBanned});
                    }
                  },
                  onToggleAdmin: () async {
                    await widget.db.collection('users').doc(users[i].uid).update({
                      'isAdmin': !users[i].isAdmin,
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<bool?> _confirmDialog(
      BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }
}

class _AdminUserTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onToggleSuspend;
  final VoidCallback onToggleBan;
  final VoidCallback onToggleAdmin;

  const _AdminUserTile({
    required this.user,
    required this.onToggleSuspend,
    required this.onToggleBan,
    required this.onToggleAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: user.isBanned
            ? AppTheme.terracotta.withOpacity(0.05)
            : user.isSuspended
                ? const Color(0xFFFFF3CD)
                : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isBanned
              ? AppTheme.terracotta.withOpacity(0.3)
              : AppTheme.lightGrey,
        ),
      ),
      child: ListTile(
        leading: UserAvatar(
          photoUrl: user.photoUrl,
          displayName: user.displayName,
          radius: 20,
        ),
        title: Row(
          children: [
            Text(
              user.displayName,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoal),
            ),
            if (user.isAdmin) ...const [
              SizedBox(width: 6),
              Icon(Icons.verified, size: 14, color: AppTheme.brandGreen),
            ],
            if (user.isBanned) ...const [
              SizedBox(width: 6),
              Icon(Icons.block, size: 14, color: AppTheme.terracotta),
            ],
            if (user.isSuspended && !user.isBanned) ...const [
              SizedBox(width: 6),
              Icon(Icons.pause_circle, size: 14, color: Color(0xFFF59E0B)),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email,
                style: const TextStyle(fontSize: 12, color: AppTheme.midGrey)),
            Text('${user.suburb}, ${user.state}',
                style: const TextStyle(fontSize: 11, color: AppTheme.midGrey)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.midGrey),
          onSelected: (v) {
            if (v == 'suspend') onToggleSuspend();
            if (v == 'ban') onToggleBan();
            if (v == 'admin') onToggleAdmin();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'suspend',
              child: Text(user.isSuspended ? 'Unsuspend' : 'Suspend'),
            ),
            PopupMenuItem(
              value: 'ban',
              child: Text(
                user.isBanned ? 'Unban' : 'Ban',
                style: TextStyle(
                  color: user.isBanned ? AppTheme.charcoal : AppTheme.terracotta,
                ),
              ),
            ),
            PopupMenuItem(
              value: 'admin',
              child: Text(user.isAdmin ? 'Remove admin' : 'Make admin'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── STATS TAB ───────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final FirebaseFirestore db;

  const _StatsTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Platform overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<AggregateQuerySnapshot>(
          stream: Stream.fromFuture(db.collection('users').count().get()),
          builder: (_, snap) => _StatCard(
            icon: Icons.people_outline,
            label: 'Total users',
            value: snap.data?.count?.toString() ?? '—',
            color: AppTheme.brandGreen,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<AggregateQuerySnapshot>(
          stream: Stream.fromFuture(db.collection('posts')
              .where('isRemoved', isEqualTo: false)
              .count()
              .get()),
          builder: (_, snap) => _StatCard(
            icon: Icons.article_outlined,
            label: 'Total posts',
            value: snap.data?.count?.toString() ?? '—',
            color: const Color(0xFF0077B6),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<AggregateQuerySnapshot>(
          stream: Stream.fromFuture(
              db.collection('reports').where('isResolved', isEqualTo: false).count().get()),
          builder: (_, snap) => _StatCard(
            icon: Icons.flag_outlined,
            label: 'Open reports',
            value: snap.data?.count?.toString() ?? '—',
            color: AppTheme.terracotta,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<AggregateQuerySnapshot>(
          stream: Stream.fromFuture(db.collection('posts')
              .where('category', isEqualTo: 'marketplace')
              .where('isRemoved', isEqualTo: false)
              .count()
              .get()),
          builder: (_, snap) => _StatCard(
            icon: Icons.storefront_outlined,
            label: 'Marketplace listings',
            value: snap.data?.count?.toString() ?? '—',
            color: const Color(0xFF2D9A52),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<AggregateQuerySnapshot>(
          stream: Stream.fromFuture(
              db.collection('users').where('isBanned', isEqualTo: true).count().get()),
          builder: (_, snap) => _StatCard(
            icon: Icons.block_outlined,
            label: 'Banned users',
            value: snap.data?.count?.toString() ?? '—',
            color: const Color(0xFF6B7280),
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'Recent activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: db
              .collection('posts')
              .where('isRemoved', isEqualTo: false)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (_, snap) {
            final posts = snap.data?.docs
                    .map((d) => Post.fromFirestore(d))
                    .toList() ??
                [];
            if (posts.isEmpty) {
              return const Text('No recent posts.',
                  style: TextStyle(color: AppTheme.midGrey));
            }
            return Column(
              children: posts.map((p) => _RecentPostTile(post: p)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppTheme.midGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentPostTile extends StatelessWidget {
  final Post post;

  const _RecentPostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Row(
        children: [
          UserAvatar(
            photoUrl: post.authorPhotoUrl,
            displayName: post.authorName,
            radius: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
                Text(
                  post.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.midGrey),
                ),
              ],
            ),
          ),
          CategoryBadge(category: post.category),
        ],
      ),
    );
  }
}
