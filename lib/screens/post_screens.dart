import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/post_service.dart';
import '../providers/user_provider.dart';
import '../widgets/shared_widgets.dart';
import '../utils/app_theme.dart';

// ─────────────────────── POST DETAIL ─────────────────────────────────────────

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postService = PostService();
  final _commentCtrl = TextEditingController();
  String? _replyToId;
  String? _replyToName;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment(AppUser user) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    await _postService.addComment(
      author: user,
      postId: widget.postId,
      content: text,
      parentCommentId: _replyToId,
    );
    _commentCtrl.clear();
    setState(() { _replyToId = null; _replyToName = null; });
  }

  Future<void> _reportPost(String postId, String uid) async {
    String? reason;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this post?'),
            const SizedBox(height: 12),
            ...['Inappropriate content', 'Spam', 'Misinformation', 'Harassment'].map(
              (r) => RadioListTile<String>(
                title: Text(r),
                value: r,
                groupValue: reason,
                onChanged: (v) => setState(() => reason = v),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: reason != null
                ? () async {
                    await _postService.reportPost(
                        postId: postId, reportedBy: uid, reason: reason!);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post reported. Thank you.')),
                      );
                    }
                  }
                : null,
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(
        title: const Text('Post'),
        leading: BackButton(color: AppTheme.charcoal),
      ),
      body: StreamBuilder<Post?>(
        stream: _postService.postStream(widget.postId),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final post = snap.data;
          if (post == null) return const Center(child: Text('Post not found'));

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    // Post content
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              UserAvatar(
                                photoUrl: post.authorPhotoUrl,
                                displayName: post.authorName,
                                radius: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post.authorName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: AppTheme.charcoal)),
                                    Text(timeago.format(post.createdAt),
                                        style: const TextStyle(
                                            fontSize: 12, color: AppTheme.midGrey)),
                                  ],
                                ),
                              ),
                              CategoryBadge(category: post.category),
                              if (user != null) ...[
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_horiz,
                                      color: AppTheme.midGrey),
                                  onSelected: (v) async {
                                    if (v == 'report') {
                                      await _reportPost(post.id, user.uid);
                                    } else if (v == 'delete' &&
                                        post.authorId == user.uid) {
                                      await _postService.deletePost(post.id);
                                      if (context.mounted) context.pop();
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (post.authorId == user.uid)
                                      const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(children: [
                                            Icon(Icons.delete_outline,
                                                color: AppTheme.terracotta),
                                            SizedBox(width: 8),
                                            Text('Delete post'),
                                          ])),
                                    const PopupMenuItem(
                                        value: 'report',
                                        child: Row(children: [
                                          Icon(Icons.flag_outlined,
                                              color: AppTheme.midGrey),
                                          SizedBox(width: 8),
                                          Text('Report post'),
                                        ])),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(post.content,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.charcoal,
                                  height: 1.5)),
                          if (post.imageUrls.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...post.imageUrls.map(
                              (url) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (post.category == PostCategory.marketplace &&
                              (post.price != null || post.isFree == true)) ...[
                            const SizedBox(height: 10),
                            Text(
                              post.isFree == true
                                  ? 'FREE'
                                  : '\$${post.price!.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: post.isFree == true
                                    ? AppTheme.brandGreen
                                    : AppTheme.terracotta,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: user != null
                                    ? () => _postService.toggleLike(post.id,
                                        user.uid, post.likedBy.contains(user.uid))
                                    : null,
                                child: Row(
                                  children: [
                                    Icon(
                                      user != null && post.likedBy.contains(user.uid)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 20,
                                      color: user != null &&
                                              post.likedBy.contains(user.uid)
                                          ? AppTheme.terracotta
                                          : AppTheme.midGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('${post.likeCount} likes',
                                        style: const TextStyle(
                                            color: AppTheme.midGrey,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text('${post.commentCount} comments',
                                  style: const TextStyle(
                                      color: AppTheme.midGrey, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Comments section
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text('Comments',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppTheme.charcoal)),
                    ),

                    StreamBuilder<List<Comment>>(
                      stream: _postService.commentsStream(widget.postId),
                      builder: (_, cSnap) {
                        final comments = cSnap.data ?? [];
                        if (comments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('No comments yet. Be the first!',
                                style: TextStyle(color: AppTheme.midGrey)),
                          );
                        }
                        return Column(
                          children: comments.map((c) => _CommentTile(
                            comment: c,
                            onReply: () => setState(() {
                              _replyToId = c.id;
                              _replyToName = c.authorName;
                            }),
                            currentUserId: user?.uid,
                            onLike: user != null
                                ? () => _postService.toggleCommentLike(
                                    c.id, user.uid, c.likedBy.contains(user.uid))
                                : null,
                          )).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Comment input
              if (user != null)
                Container(
                  padding: EdgeInsets.fromLTRB(
                      16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
                  color: AppTheme.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_replyToName != null) ...[
                        Row(
                          children: [
                            Text('Replying to $_replyToName',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.brandGreen,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() {
                                _replyToId = null;
                                _replyToName = null;
                              }),
                              child: const Icon(Icons.close,
                                  size: 14, color: AppTheme.midGrey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        children: [
                          UserAvatar(
                              photoUrl: user.photoUrl,
                              displayName: user.displayName,
                              radius: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _commentCtrl,
                              decoration: InputDecoration(
                                hintText: 'Add a comment…',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                      color: AppTheme.lightGrey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                      color: AppTheme.lightGrey),
                                ),
                              ),
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _submitComment(user),
                            icon: const Icon(Icons.send_rounded,
                                color: AppTheme.brandGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback onReply;
  final String? currentUserId;
  final VoidCallback? onLike;

  const _CommentTile({
    required this.comment,
    required this.onReply,
    this.currentUserId,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final liked =
        currentUserId != null && comment.likedBy.contains(currentUserId);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          comment.parentCommentId != null ? 40 : 16, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
              photoUrl: comment.authorPhotoUrl,
              displayName: comment.authorName,
              radius: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(comment.authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.charcoal)),
                      const SizedBox(width: 6),
                      Text(timeago.format(comment.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.midGrey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.content,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.charcoal,
                          height: 1.35)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onLike,
                        child: Row(
                          children: [
                            Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                size: 14,
                                color: liked
                                    ? AppTheme.terracotta
                                    : AppTheme.midGrey),
                            if (comment.likeCount > 0) ...[
                              const SizedBox(width: 2),
                              Text('${comment.likeCount}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppTheme.midGrey)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onReply,
                        child: const Text('Reply',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.brandGreen,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
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

// ─────────────────────── CREATE POST ─────────────────────────────────────────

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _postService = PostService();
  final _picker = ImagePicker();

  PostCategory _category = PostCategory.general;
  List<File> _images = [];
  bool _isFree = false;
  String? _marketplaceCategory;
  String? _eventCategory;
  DateTime? _eventDate;
  bool _loading = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() => _images = [
            ..._images,
            ...picked.map((x) => File(x.path))
          ].take(5).toList());
    }
  }

  Future<void> _post(AppUser user) async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _postService.createPost(
        author: user,
        content: _contentCtrl.text.trim(),
        category: _category,
        images: _images,
        price: _category == PostCategory.marketplace && !_isFree
            ? double.tryParse(_priceCtrl.text)
            : null,
        marketplaceCategory: _marketplaceCategory,
        isFree: _category == PostCategory.marketplace ? _isFree : false,
        eventDate: _category == PostCategory.event ? _eventDate : null,
        eventLocation: _category == PostCategory.event
            ? _locationCtrl.text.trim()
            : null,
        eventCategory: _eventCategory,
      );
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('New post'),
        leading: BackButton(color: AppTheme.charcoal),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _loading || _contentCtrl.text.trim().isEmpty
                  ? null
                  : () => _post(user),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.white))
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Author row
            Row(
              children: [
                UserAvatar(
                    photoUrl: user.photoUrl,
                    displayName: user.displayName,
                    radius: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(user.suburb,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.midGrey)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Category picker
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: PostCategory.values.map((cat) {
                  final sel = _category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.brandGreen : AppTheme.sand,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? AppTheme.brandGreen
                                : AppTheme.lightGrey,
                          ),
                        ),
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: sel ? AppTheme.white : AppTheme.charcoal,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Main text
            TextField(
              controller: _contentCtrl,
              maxLines: null,
              minLines: 5,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText:
                    "What's happening in your neighbourhood?",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
              style: const TextStyle(
                  fontSize: 16, color: AppTheme.charcoal, height: 1.5),
            ),

            // Marketplace extras
            if (_category == PostCategory.marketplace) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      enabled: !_isFree,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _isFree,
                        activeColor: AppTheme.brandGreen,
                        onChanged: (v) =>
                            setState(() => _isFree = v ?? false),
                      ),
                      const Text('Free'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _marketplaceCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: AppConstants.marketplaceCategories
                    .where((c) => c != 'All')
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _marketplaceCategory = v),
              ),
            ],

            // Event extras
            if (_category == PostCategory.event) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today,
                    color: AppTheme.brandGreen),
                title: Text(
                  _eventDate != null
                      ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year} ${_eventDate!.hour}:${_eventDate!.minute.toString().padLeft(2, '0')}'
                      : 'Set event date & time',
                  style: TextStyle(
                    color: _eventDate != null
                        ? AppTheme.charcoal
                        : AppTheme.midGrey,
                    fontWeight: _eventDate != null
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() => _eventDate = DateTime(
                          date.year, date.month, date.day,
                          time.hour, time.minute));
                    }
                  }
                },
              ),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _eventCategory,
                decoration:
                    const InputDecoration(labelText: 'Event type'),
                items: AppConstants.eventCategories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _eventCategory = v),
              ),
            ],

            const Divider(height: 24),

            // Images
            if (_images.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_images[i],
                            width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _images.removeAt(i)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(Icons.close,
                                size: 14, color: AppTheme.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Toolbar
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_outlined,
                      color: AppTheme.brandGreen),
                  onPressed: _images.length < 5 ? _pickImages : null,
                  tooltip: 'Add photo',
                ),
                Text(
                  _images.isEmpty
                      ? 'Add photos'
                      : '${_images.length}/5 photos',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.midGrey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
