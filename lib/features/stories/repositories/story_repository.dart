import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../shared/models/story_model.dart';

/// Repository for managing stories via Firestore + Cloudinary.
///
/// Stories expire after 24 hours. Images are compressed and uploaded
/// to Cloudinary; metadata is stored in Firestore.
class StoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const _uuid = Uuid();

  StoryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  /// Upload a story image and create Firestore document.
  ///
  /// [imageBytes] — raw image bytes (will be compressed before upload)
  /// [caption] — optional story caption
  ///
  /// Returns the created [StoryModel] or null if failed.
  Future<StoryModel?> uploadStory(
    Uint8List imageBytes, {
    String caption = '',
  }) async {
    final uid = _currentUid;
    if (uid == null) return null;

    try {
      final storyId = _uuid.v4();

      // Upload compressed image to Cloudinary
      final uploadResult = await CloudinaryService.uploadStoryImage(
        imageBytes,
        storyId: storyId,
      );
      if (uploadResult == null) return null;

      // Get owner profile info
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      final now = DateTime.now();
      final story = StoryModel(
        storyId: storyId,
        ownerId: uid,
        ownerName: userData['displayName'] as String? ?? '',
        ownerPhotoUrl: userData['photoUrl'] as String? ?? '',
        imageUrl: uploadResult.secureUrl,
        cloudinaryPublicId: uploadResult.publicId,
        caption: caption,
        viewedBy: [],
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      );

      await _firestore
          .collection('stories')
          .doc(storyId)
          .set(story.toFirestore());

      return story;
    } catch (e) {
      return null;
    }
  }

  /// Stream of non-expired stories from friends.
  ///
  /// [friendUids] — list of friend UIDs to fetch stories for.
  Stream<List<StoryModel>> getFriendStories(List<String> friendUids) {
    if (friendUids.isEmpty) return Stream.value([]);

    // Firestore 'whereIn' limit is 30
    final uids = friendUids.length > 30
        ? friendUids.sublist(0, 30)
        : friendUids;

    return _firestore
        .collection('stories')
        .where('ownerId', whereIn: uids)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromFirestore(doc))
            .where((story) => !story.isExpired) // Double-check client-side
            .toList());
  }

  /// Stream of current user's own stories.
  Stream<List<StoryModel>> getMyStories() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('stories')
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromFirestore(doc))
            .toList());
  }

  /// Mark a story as viewed by the current user.
  Future<void> markAsViewed(String storyId) async {
    final uid = _currentUid;
    if (uid == null) return;

    await _firestore.collection('stories').doc(storyId).update({
      'viewedBy': FieldValue.arrayUnion([uid]),
    });
  }

  /// Delete a story (Firestore doc removal).
  Future<bool> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
