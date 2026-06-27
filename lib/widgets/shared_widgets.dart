import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../providers/user_provider.dart';
import '../services/post_service.dart';

// ─────────────────────── AVATAR ──────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.displayName,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.brandGreenPale,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppTheme.brandGreen,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────── CATEGORY CHIP ───────────────────────────────────────

class CategoryBadge extends StatelessWidget {
  final PostCategory category;

  const CategoryBadge({super.key, required this.category});

  Color get _color {
    switch (category) {
      case PostCategory.safetyAlert:
        return AppTheme.terracotta;
      case PostCategory.communityNotice:
        return const Color(0xFF0077B6);
      case PostCategory.event:
        return const Color(0xFF7B2D8B);
      case PostCategory.lostAndFound:
        return const Color(0xFFE9832D);
      case PostCategory.marketplace:
        return const Color(0xFF2D9A52);
      default:
        return AppTheme.brandGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────── POST CARD ───────────────────────────────────────────

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final uid = userProvider.user?.uid;
    final liked = uid != null && post.likedBy.contains(uid);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  UserAvatar(
                    photoUrl: post.authorPhotoUrl,
                    displayName: post.authorName,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        Text(
                          timeago.format(post.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.midGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CategoryBadge(category: post.category),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                post.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.charcoal,
                  height: 1.45,
                ),
              ),
            ),

            // Images
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildImageGrid(context),
            ],

            // Marketplace price
            if (post.category == PostCategory.marketplace) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  post.isFree == true
                      ? 'FREE'
                      : post.price != null
                          ? '\$${post.price!.toStringAsFixed(0)}'
                          : '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: post.isFree == true
                        ? AppTheme.brandGreen
                        : AppTheme.terracotta,
                  ),
                ),
              ),
            ],

            // Event date
            if (post.category == PostCategory.event &&
                post.eventDate != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 13, color: AppTheme.midGrey),
                    const SizedBox(width: 4),
                    Text(
                      _formatEventDate(post.eventDate!),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.midGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (post.eventLocation != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on,
                          size: 13, color: AppTheme.midGrey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          post.eventLocation!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.midGrey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
              child: Row(
                children: [
                  _ActionButton(
                    icon: liked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: post.likeCount > 0
                        ? post.likeCount.toString()
                        : '',
                    color: liked ? AppTheme.terracotta : AppTheme.midGrey,
                    onTap: onLike,
                  ),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: post.commentCount > 0
                        ? post.commentCount.toString()
                        : '',
                    color: AppTheme.midGrey,
                    onTap: onComment,
                  ),
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: '',
                    color: AppTheme.midGrey,
                    onTap: onShare,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    final urls = post.imageUrls;
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.zero),
        child: CachedNetworkImage(
          imageUrl: urls[0],
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: urls.length,
        itemBuilder: (_, i) => CachedNetworkImage(
          imageUrl: urls[i],
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _formatEventDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── LOADING SHIMMER ─────────────────────────────────────

class PostShimmer extends StatelessWidget {
  const PostShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
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
              const _ShimmerBox(width: 36, height: 36, radius: 18),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ShimmerBox(width: 120, height: 13),
                  SizedBox(height: 4),
                  _ShimmerBox(width: 80, height: 11),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ShimmerBox(width: double.infinity, height: 13),
          const SizedBox(height: 6),
          const _ShimmerBox(width: double.infinity, height: 13),
          const SizedBox(height: 6),
          const _ShimmerBox(width: 200, height: 13),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────── SUBURB HEADER ───────────────────────────────────────

class SuburbHeader extends StatelessWidget {
  final String suburb;
  final String state;

  const SuburbHeader({super.key, required this.suburb, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppTheme.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.brandGreenPale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on,
                color: AppTheme.brandGreen, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suburb,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.charcoal,
                ),
              ),
              Text(
                state,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.midGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── EMPTY STATE ─────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.brandGreenPale,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.brandGreen),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.midGrey,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
