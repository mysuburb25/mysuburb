import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../services/post_service.dart';
import '../providers/user_provider.dart';
import '../widgets/shared_widgets.dart';
import '../utils/app_theme.dart';

// ─────────────────────── MARKETPLACE ─────────────────────────────────────────

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _postService = PostService();
  List<Post> _listings = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    setState(() => _loading = true);
    final posts = await _postService.fetchMarketplacePosts(
      suburb: user.suburb,
      state: user.state,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
    if (mounted) setState(() { _listings = posts; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/create-post'),
            tooltip: 'Sell something',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: AppConstants.marketplaceCategories.map((cat) {
                final sel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.brandGreen : AppTheme.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel
                                ? AppTheme.brandGreen
                                : AppTheme.lightGrey),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          color: sel ? AppTheme.white : AppTheme.charcoal,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _listings.isEmpty
                    ? EmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'Nothing for sale yet',
                        subtitle:
                            'List something you no longer need and give it a new home.',
                        actionLabel: 'List an item',
                        onAction: () => context.push('/create-post'),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _listings.length,
                          itemBuilder: (_, i) =>
                              _ListingCard(post: _listings[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Post post;

  const _ListingCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: post.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: post.imageUrls[0],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppTheme.sand),
                      )
                    : Container(
                        color: AppTheme.sand,
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              size: 40, color: AppTheme.lightGrey),
                        ),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.charcoal),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.isFree == true
                        ? 'FREE'
                        : post.price != null
                            ? '\$${post.price!.toStringAsFixed(0)}'
                            : 'Contact seller',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: post.isFree == true
                          ? AppTheme.brandGreen
                          : AppTheme.terracotta,
                    ),
                  ),
                  Text(
                    timeago.format(post.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.midGrey),
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

// ─────────────────────── EVENTS ──────────────────────────────────────────────

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _postService = PostService();
  List<Post> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    setState(() => _loading = true);
    final posts = await _postService.fetchUpcomingEvents(
      suburb: user.suburb,
      state: user.state,
    );
    if (mounted) setState(() { _events = posts; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/create-post'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? EmptyState(
                  icon: Icons.event_outlined,
                  title: 'No upcoming events',
                  subtitle:
                      'Know about a local event? Share it with your neighbours.',
                  actionLabel: 'Add an event',
                  onAction: () => context.push('/create-post'),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: _events.length,
                    itemBuilder: (_, i) => _EventCard(post: _events[i]),
                  ),
                ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Post post;

  const _EventCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final d = post.eventDate;
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];

    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            if (d != null)
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.brandGreen,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(15)),
                ),
                child: Column(
                  children: [
                    Text(
                      months[d.month - 1].toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1),
                    ),
                    Text(
                      d.day.toString(),
                      style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${d.hour}:${d.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          color: AppTheme.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.eventCategory != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B2D8B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post.eventCategory!,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7B2D8B),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      post.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.charcoal),
                    ),
                    if (post.eventLocation != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 13, color: AppTheme.midGrey),
                          const SizedBox(width: 2),
                          Text(post.eventLocation!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.midGrey)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        UserAvatar(
                            photoUrl: post.authorPhotoUrl,
                            displayName: post.authorName,
                            radius: 10),
                        const SizedBox(width: 4),
                        Text(post.authorName,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.midGrey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── LOST & FOUND ────────────────────────────────────────

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  final _postService = PostService();
  List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    setState(() => _loading = true);
    final posts = await _postService.fetchLostAndFound(
      suburb: user.suburb,
      state: user.state,
    );
    if (mounted) setState(() { _posts = posts; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(
        title: const Text('Lost & Found'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/create-post'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? EmptyState(
                  icon: Icons.search_outlined,
                  title: 'Nothing lost or found',
                  subtitle:
                      'Lost a pet or found something? Let your neighbours know.',
                  actionLabel: 'Post now',
                  onAction: () => context.push('/create-post'),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: _posts.length,
                    itemBuilder: (_, i) {
                      final post = _posts[i];
                      return PostCard(
                        post: post,
                        onTap: () => context.push('/post/${post.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}
