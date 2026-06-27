import 'package:cloud_firestore/cloud_firestore.dart';

// ──────────────────────────────── USER MODEL ────────────────────────────────

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String suburb;
  final String state;
  final bool isAdmin;
  final bool isSuspended;
  final bool isBanned;
  final DateTime createdAt;
  final List<String> fcmTokens;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.suburb,
    required this.state,
    this.isAdmin = false,
    this.isSuspended = false,
    this.isBanned = false,
    required this.createdAt,
    this.fcmTokens = const [],
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: d['email'] ?? '',
      displayName: d['displayName'] ?? '',
      photoUrl: d['photoUrl'],
      suburb: d['suburb'] ?? '',
      state: d['state'] ?? '',
      isAdmin: d['isAdmin'] ?? false,
      isSuspended: d['isSuspended'] ?? false,
      isBanned: d['isBanned'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmTokens: List<String>.from(d['fcmTokens'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'suburb': suburb,
        'state': state,
        'isAdmin': isAdmin,
        'isSuspended': isSuspended,
        'isBanned': isBanned,
        'createdAt': Timestamp.fromDate(createdAt),
        'fcmTokens': fcmTokens,
      };

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? suburb,
    String? state,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        suburb: suburb ?? this.suburb,
        state: state ?? this.state,
        isAdmin: isAdmin,
        isSuspended: isSuspended,
        isBanned: isBanned,
        createdAt: createdAt,
        fcmTokens: fcmTokens,
      );
}

// ──────────────────────────────── POST MODEL ────────────────────────────────

enum PostCategory {
  general,
  communityNotice,
  event,
  lostAndFound,
  marketplace,
  safetyAlert,
}

extension PostCategoryExt on PostCategory {
  String get label {
    switch (this) {
      case PostCategory.general:
        return 'General';
      case PostCategory.communityNotice:
        return 'Community Notice';
      case PostCategory.event:
        return 'Event';
      case PostCategory.lostAndFound:
        return 'Lost & Found';
      case PostCategory.marketplace:
        return 'Marketplace';
      case PostCategory.safetyAlert:
        return 'Safety Alert';
    }
  }

  static PostCategory fromString(String s) {
    switch (s) {
      case 'communityNotice':
        return PostCategory.communityNotice;
      case 'event':
        return PostCategory.event;
      case 'lostAndFound':
        return PostCategory.lostAndFound;
      case 'marketplace':
        return PostCategory.marketplace;
      case 'safetyAlert':
        return PostCategory.safetyAlert;
      default:
        return PostCategory.general;
    }
  }
}

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String suburb;
  final String state;
  final String content;
  final List<String> imageUrls;
  final PostCategory category;
  final int likeCount;
  final int commentCount;
  final List<String> likedBy;
  final bool isReported;
  final bool isRemoved;
  final DateTime createdAt;
  final DateTime? editedAt;

  // Marketplace extras
  final double? price;
  final String? marketplaceCategory;
  final bool? isFree;

  // Event extras
  final DateTime? eventDate;
  final String? eventLocation;
  final String? eventCategory;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.suburb,
    required this.state,
    required this.content,
    this.imageUrls = const [],
    required this.category,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedBy = const [],
    this.isReported = false,
    this.isRemoved = false,
    required this.createdAt,
    this.editedAt,
    this.price,
    this.marketplaceCategory,
    this.isFree,
    this.eventDate,
    this.eventLocation,
    this.eventCategory,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? '',
      authorPhotoUrl: d['authorPhotoUrl'],
      suburb: d['suburb'] ?? '',
      state: d['state'] ?? '',
      content: d['content'] ?? '',
      imageUrls: List<String>.from(d['imageUrls'] ?? []),
      category: PostCategoryExt.fromString(d['category'] ?? 'general'),
      likeCount: d['likeCount'] ?? 0,
      commentCount: d['commentCount'] ?? 0,
      likedBy: List<String>.from(d['likedBy'] ?? []),
      isReported: d['isReported'] ?? false,
      isRemoved: d['isRemoved'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (d['editedAt'] as Timestamp?)?.toDate(),
      price: d['price']?.toDouble(),
      marketplaceCategory: d['marketplaceCategory'],
      isFree: d['isFree'],
      eventDate: (d['eventDate'] as Timestamp?)?.toDate(),
      eventLocation: d['eventLocation'],
      eventCategory: d['eventCategory'],
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'suburb': suburb,
        'state': state,
        'content': content,
        'imageUrls': imageUrls,
        'category': category.name,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'likedBy': likedBy,
        'isReported': isReported,
        'isRemoved': isRemoved,
        'createdAt': Timestamp.fromDate(createdAt),
        'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
        'price': price,
        'marketplaceCategory': marketplaceCategory,
        'isFree': isFree,
        'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
        'eventLocation': eventLocation,
        'eventCategory': eventCategory,
      };
}

// ─────────────────────────────── COMMENT MODEL ──────────────────────────────

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final String? parentCommentId;
  final int likeCount;
  final List<String> likedBy;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.parentCommentId,
    this.likeCount = 0,
    this.likedBy = const [],
    required this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: d['postId'] ?? '',
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? '',
      authorPhotoUrl: d['authorPhotoUrl'],
      content: d['content'] ?? '',
      parentCommentId: d['parentCommentId'],
      likeCount: d['likeCount'] ?? 0,
      likedBy: List<String>.from(d['likedBy'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'content': content,
        'parentCommentId': parentCommentId,
        'likeCount': likeCount,
        'likedBy': likedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ──────────────────────────── NOTIFICATION MODEL ────────────────────────────

enum NotificationType {
  like,
  comment,
  reply,
  announcement,
  eventReminder,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? postId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.postId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: d['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => NotificationType.announcement,
      ),
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      postId: d['postId'],
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'postId': postId,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─────────────────────────────── SUBURB MODEL ───────────────────────────────

class SuburbEntry {
  final String name;
  final String state;
  final String postcode;

  SuburbEntry({
    required this.name,
    required this.state,
    required this.postcode,
  });

  String get fullLabel => '$name, $state $postcode';
}

// ──────────────────────────────── REPORT MODEL ──────────────────────────────

class Report {
  final String id;
  final String reportedBy;
  final String contentId;
  final String contentType; // 'post' | 'comment' | 'user'
  final String reason;
  final DateTime createdAt;
  final bool isResolved;

  Report({
    required this.id,
    required this.reportedBy,
    required this.contentId,
    required this.contentType,
    required this.reason,
    required this.createdAt,
    this.isResolved = false,
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      reportedBy: d['reportedBy'] ?? '',
      contentId: d['contentId'] ?? '',
      contentType: d['contentType'] ?? '',
      reason: d['reason'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isResolved: d['isResolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'reportedBy': reportedBy,
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
        'createdAt': Timestamp.fromDate(createdAt),
        'isResolved': isResolved,
      };
}
