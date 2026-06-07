import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile model for BeTogether.
///
/// Stored in Firestore `users` collection.
/// [photoUrl] is a Cloudinary HTTPS URL.
/// [friends] is a list of friend UIDs.
class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String photoUrl;
  final String email;
  final List<String> friends;
  final String friendCode;
  final String birthday;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl = '',
    this.email = '',
    this.friends = const [],
    this.friendCode = '',
    this.birthday = '',
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, uid: doc.id);
  }

  /// Create from a Map (useful for testing).
  factory UserModel.fromMap(Map<String, dynamic> data, {String? uid}) {
    List<String> parsedFriends = [];
    final friendsRaw = data['friends'];
    if (friendsRaw is List) {
      parsedFriends = friendsRaw.map((e) => e.toString()).toList();
    }

    return UserModel(
      uid: uid ?? data['uid']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      displayName: data['displayName']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      friends: parsedFriends,
      friendCode: data['friendCode']?.toString() ?? '',
      birthday: data['birthday']?.toString() ?? '',
      fcmToken: data['fcmToken']?.toString(),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Convert to Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'email': email,
      'friends': friends,
      'friendCode': friendCode,
      'birthday': birthday,
      'fcmToken': fcmToken,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert to plain Map (useful for testing without FieldValue).
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'email': email,
      'friends': friends,
      'friendCode': friendCode,
      'birthday': birthday,
      'fcmToken': fcmToken,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? photoUrl,
    String? email,
    List<String>? friends,
    String? friendCode,
    String? birthday,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      friends: friends ?? this.friends,
      friendCode: friendCode ?? this.friendCode,
      birthday: birthday ?? this.birthday,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether this user is friends with [otherUid].
  bool isFriendsWith(String otherUid) => friends.contains(otherUid);

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'UserModel(uid: $uid, username: $username)';
}
