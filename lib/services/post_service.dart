import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // ── Feed ──────────────────────────────────────────────────────────────────

  Stream<List<Post>> feedStream({
    required String suburb,
    required String state,
    PostCategory? category,
    DocumentSnapshot? lastDoc,
  }) {
    Query query = _db
        .collection('posts')
        .where('suburb', isEqualTo: suburb)
        .where('state', isEqualTo: state)
        .where('isRemoved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.feedPageSize);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map((d) => Post.fromFirestore(d)).toList(),
        );
  }

  Future<List<Post>> fetchFeedPage({
    required String suburb,
    required String state,
    PostCategory? category,
    DocumentSnapshot? lastDoc,
  }) async {
    Query query = _db
        .collection('posts')
        .where('suburb', isEqualTo: suburb)
        .where('state', isEqualTo: state)
        .where('isRemoved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.feedPageSize);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snap = await query.get();
    return snap.docs.map((d) => Post.fromFirestore(d)).toList();
  }

  // ── Single post ───────────────────────────────────────────────────────────

  Stream<Post?> postStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((d) => d.exists ? Post.fromFirestore(d) : null);
  }

  // ── Create post ───────────────────────────────────────────────────────────

  Future<String> createPost({
    required AppUser author,
    required String content,
    required PostCategory category,
    List<File> images = const [],
    double? price,
    String? marketplaceCategory,
    bool isFree = false,
    DateTime? eventDate,
    String? eventLocation,
    String? eventCategory,
  }) async {
    final postId = _uuid.v4();

    // Upload images
    final imageUrls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final ref = _storage.ref('posts/$postId/image_$i.jpg');
      await ref.putFile(images[i]);
      imageUrls.add(await ref.getDownloadURL());
    }

    final post = Post(
      id: postId,
      authorId: author.uid,
      authorName: author.displayName,
      authorPhotoUrl: author.photoUrl,
      suburb: author.suburb,
      state: author.state,
      content: content,
      imageUrls: imageUrls,
      category: category,
      createdAt: DateTime.now(),
      price: price,
      marketplaceCategory: marketplaceCategory,
      isFree: isFree,
      eventDate: eventDate,
      eventLocation: eventLocation,
      eventCategory: eventCategory,
    );

    await _db.collection('posts').doc(postId).set(post.toMap());
    return postId;
  }

  // ── Edit post ─────────────────────────────────────────────────────────────

  Future<void> editPost(String postId, String newContent) async {
    await _db.collection('posts').doc(postId).update({
      'content': newContent,
      'editedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Delete / remove ───────────────────────────────────────────────────────

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).update({'isRemoved': true});
  }

  // ── Like ──────────────────────────────────────────────────────────────────

  Future<void> toggleLike(String postId, String userId, bool currentlyLiked) async {
    final ref = _db.collection('posts').doc(postId);
    if (currentlyLiked) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  // ── Report ────────────────────────────────────────────────────────────────

  Future<void> reportPost({
    required String postId,
    required String reportedBy,
    required String reason,
  }) async {
    final report = Report(
      id: _uuid.v4(),
      reportedBy: reportedBy,
      contentId: postId,
      contentType: 'post',
      reason: reason,
      createdAt: DateTime.now(),
    );
    await _db.collection('reports').doc(report.id).set(report.toMap());
    await _db.collection('posts').doc(postId).update({'isReported': true});
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  Stream<List<Comment>> commentsStream(String postId) {
    return _db
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => Comment.fromFirestore(d)).toList());
  }

  Future<void> addComment({
    required AppUser author,
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    final commentId = _uuid.v4();
    final comment = Comment(
      id: commentId,
      postId: postId,
      authorId: author.uid,
      authorName: author.displayName,
      authorPhotoUrl: author.photoUrl,
      content: content,
      parentCommentId: parentCommentId,
      createdAt: DateTime.now(),
    );
    final batch = _db.batch();
    batch.set(_db.collection('comments').doc(commentId), comment.toMap());
    batch.update(_db.collection('posts').doc(postId), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> toggleCommentLike(
      String commentId, String userId, bool currentlyLiked) async {
    final ref = _db.collection('comments').doc(commentId);
    if (currentlyLiked) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  // ── Marketplace ───────────────────────────────────────────────────────────

  Future<List<Post>> fetchMarketplacePosts({
    required String suburb,
    required String state,
    String? category,
    DocumentSnapshot? lastDoc,
  }) async {
    Query query = _db
        .collection('posts')
        .where('suburb', isEqualTo: suburb)
        .where('state', isEqualTo: state)
        .where('category', isEqualTo: PostCategory.marketplace.name)
        .where('isRemoved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(AppConstants.feedPageSize);

    if (category != null && category != 'All') {
      query = query.where('marketplaceCategory', isEqualTo: category);
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snap = await query.get();
    return snap.docs.map((d) => Post.fromFirestore(d)).toList();
  }

  // ── Events ────────────────────────────────────────────────────────────────

  Future<List<Post>> fetchUpcomingEvents({
    required String suburb,
    required String state,
  }) async {
    final snap = await _db
        .collection('posts')
        .where('suburb', isEqualTo: suburb)
        .where('state', isEqualTo: state)
        .where('category', isEqualTo: PostCategory.event.name)
        .where('isRemoved', isEqualTo: false)
        .where('eventDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('eventDate')
        .limit(50)
        .get();
    return snap.docs.map((d) => Post.fromFirestore(d)).toList();
  }

  // ── Lost & Found ──────────────────────────────────────────────────────────

  Future<List<Post>> fetchLostAndFound({
    required String suburb,
    required String state,
  }) async {
    final snap = await _db
        .collection('posts')
        .where('suburb', isEqualTo: suburb)
        .where('state', isEqualTo: state)
        .where('category', isEqualTo: PostCategory.lostAndFound.name)
        .where('isRemoved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => Post.fromFirestore(d)).toList();
  }
}
