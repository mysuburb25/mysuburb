import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/post_service.dart';
import '../providers/user_provider.dart';
import '../widgets/shared_widgets.dart';
import '../utils/app_theme.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final _postService = PostService();
  final _scrollCtrl = ScrollController();

  List<Post> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  PostCategory? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadFeed() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() { _loading = true; _posts = []; _hasMore = true; });
    final posts = await _postService.fetchFeedPage(
      suburb: user.suburb,
      state: user.state,
      category: _filterCategory,
    );
    if (mounted) {
      setState(() {
        _posts = posts;
        _loading = false;
        _hasMore = posts.length >= AppConstants.feedPageSize;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_posts.isEmpty) return;
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() => _loadingMore = true);
    // In production, pass the last document snapshot for pagination
    // This is a simplified version
    setState(() => _loadingMore = false);
  }

  Future<void> _onLike(Post post) async {
    final uid = context.read<UserProvider>().user?.uid;
    if (uid == null) return;
    final liked = post.likedBy.contains(uid);
    await _postService.toggleLike(post.id, uid, liked);
    await _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text('My Suburb'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.brandGreen,
        onRefresh: _loadFeed,
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // Suburb info
            SliverToBoxAdapter(
              child: user != null
                  ? SuburbHeader(suburb: user.suburb, state: user.state)
                  : const SizedBox.shrink(),
            ),

            // Category filters
            SliverToBoxAdapter(child: _buildCategoryFilters()),

            // Posts
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const PostShimmer(),
                  childCount: 5,
                ),
              )
            else if (_posts.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.people_outline,
                  title: 'Nothing here yet',
                  subtitle:
                      'Be the first to share something with your neighbours in ${user?.suburb ?? 'your suburb'}.',
                  actionLabel: 'Create a post',
                  onAction: () => context.push('/create-post'),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == _posts.length) {
                      return _loadingMore
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : const SizedBox(height: 16);
                    }
                    final post = _posts[i];
                    return PostCard(
                      post: post,
                      onTap: () => context.push('/post/${post.id}'),
                      onLike: () => _onLike(post),
                      onComment: () => context.push('/post/${post.id}'),
                    );
                  },
                  childCount: _posts.length + 1,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-post'),
        backgroundColor: AppTheme.brandGreen,
        icon: const Icon(Icons.add, color: AppTheme.white),
        label: const Text(
          'Post',
          style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [null, ...PostCategory.values];
    return Container(
      height: 44,
      color: AppTheme.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = _filterCategory == cat;
          return GestureDetector(
            onTap: () {
              setState(() => _filterCategory = cat);
              _loadFeed();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppTheme.brandGreen : AppTheme.sand,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.brandGreen : AppTheme.lightGrey,
                ),
              ),
              child: Text(
                cat == null ? 'All' : cat.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppTheme.white : AppTheme.charcoal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
