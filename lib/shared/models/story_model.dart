import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a temporary story shared with friends.
///
/// Stored in Firestore `stories` collection.
/// [imageUrl] is a Cloudinary HTTPS URL.
/// Stories expire after 24 hours.
class StoryModel {
  final String storyId;
  final String ownerId;
  final String ownerName;
  final String ownerPhotoUrl;
  final String imageUrl;
  final String cloudinaryPublicId;
  final String caption;
  final List<String> viewedBy;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const StoryModel({
    required this.storyId,
    required this.ownerId,
    this.ownerName = '',
    this.ownerPhotoUrl = '',
    required this.imageUrl,
    this.cloudinaryPublicId = '',
    this.caption = '',
    this.viewedBy = const [],
    this.createdAt,
    this.expiresAt,
  });

  /// Whether this story has expired (past its 24h window).
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Whether this story has been viewed by [userId].
  bool isViewedBy(String userId) => viewedBy.contains(userId);

  /// Duration remaining before expiry.
  Duration? get timeRemaining {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Create from Firestore document snapshot.
  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StoryModel.fromMap(data, storyId: doc.id);
  }

  /// Create from a Map (useful for testing).
  factory StoryModel.fromMap(Map<String, dynamic> data, {String? storyId}) {
    return StoryModel(
      storyId: storyId ?? data['storyId'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      ownerPhotoUrl: data['ownerPhotoUrl'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      cloudinaryPublicId: data['cloudinaryPublicId'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      viewedBy: List<String>.from(data['viewedBy'] as List? ?? []),
      createdAt: _parseTimestamp(data['createdAt']),
      expiresAt: _parseTimestamp(data['expiresAt']),
    );
  }

  /// Convert to Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      'storyId': storyId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'imageUrl': imageUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'caption': caption,
      'viewedBy': viewedBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'expiresAt': expiresAt != null
          ? Timestamp.fromDate(expiresAt!)
          : Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
    };
  }

  /// Convert to plain Map (useful for testing without FieldValue).
  Map<String, dynamic> toMap() {
    return {
      'storyId': storyId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'imageUrl': imageUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'caption': caption,
      'viewedBy': viewedBy,
      'createdAt': createdAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  StoryModel copyWith({
    String? storyId,
    String? ownerId,
    String? ownerName,
    String? ownerPhotoUrl,
    String? imageUrl,
    String? cloudinaryPublicId,
    String? caption,
    List<String>? viewedBy,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return StoryModel(
      storyId: storyId ?? this.storyId,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
      caption: caption ?? this.caption,
      viewedBy: viewedBy ?? this.viewedBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'StoryModel(storyId: $storyId, owner: $ownerId, expired: $isExpired)';
}
