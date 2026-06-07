import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a friend request.
enum FriendRequestStatus { pending, accepted, rejected }

/// Model for a friend request between two users.
///
/// Stored in Firestore `friendRequests` collection.
class FriendRequestModel {
  final String id;
  final String fromUid;
  final String toUid;
  final String fromName;
  final String fromPhotoUrl;
  final String toName;
  final String toPhotoUrl;
  final FriendRequestStatus status;
  final DateTime? createdAt;

  const FriendRequestModel({
    required this.id,
    required this.fromUid,
    required this.toUid,
    this.fromName = '',
    this.fromPhotoUrl = '',
    this.toName = '',
    this.toPhotoUrl = '',
    this.status = FriendRequestStatus.pending,
    this.createdAt,
  });

  /// Create from Firestore document snapshot.
  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendRequestModel.fromMap(data, id: doc.id);
  }

  /// Create from a Map (useful for testing).
  factory FriendRequestModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return FriendRequestModel(
      id: id ?? data['id'] as String? ?? '',
      fromUid: data['fromUid'] as String? ?? '',
      toUid: data['toUid'] as String? ?? '',
      fromName: data['fromName'] as String? ?? '',
      fromPhotoUrl: data['fromPhotoUrl'] as String? ?? '',
      toName: data['toName'] as String? ?? '',
      toPhotoUrl: data['toPhotoUrl'] as String? ?? '',
      status: _parseStatus(data['status']),
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  /// Convert to Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      'fromUid': fromUid,
      'toUid': toUid,
      'fromName': fromName,
      'fromPhotoUrl': fromPhotoUrl,
      'toName': toName,
      'toPhotoUrl': toPhotoUrl,
      'status': status.name,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Convert to plain Map (useful for testing without FieldValue).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUid': fromUid,
      'toUid': toUid,
      'fromName': fromName,
      'fromPhotoUrl': fromPhotoUrl,
      'toName': toName,
      'toPhotoUrl': toPhotoUrl,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool get isPending => status == FriendRequestStatus.pending;
  bool get isAccepted => status == FriendRequestStatus.accepted;
  bool get isRejected => status == FriendRequestStatus.rejected;

  static FriendRequestStatus _parseStatus(dynamic value) {
    if (value is String) {
      return FriendRequestStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => FriendRequestStatus.pending,
      );
    }
    return FriendRequestStatus.pending;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'FriendRequestModel(id: $id, from: $fromUid, to: $toUid, status: ${status.name})';
}
