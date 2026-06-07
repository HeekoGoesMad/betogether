import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/friend_request_model.dart';

/// Repository for managing friend relationships via Firestore.
///
/// Collections used:
/// - `users` — user profiles with `friends[]` array
/// - `friendRequests` — pending/accepted/rejected requests
class FriendRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FriendRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  /// Search users by username prefix.
  ///
  /// Returns up to 10 matching users, excluding the current user.
  Future<List<UserModel>> searchByUsername(String query) async {
    if (query.isEmpty) return [];
    final uid = _currentUid;
    if (uid == null) return [];

    final originalQuery = query.trim();
    final lowercaseQuery = originalQuery.toLowerCase();
    final sentenceCaseQuery = originalQuery.isNotEmpty
        ? originalQuery.substring(0, 1).toUpperCase() + originalQuery.substring(1).toLowerCase()
        : originalQuery;

    final searchTerms = {lowercaseQuery, originalQuery, sentenceCaseQuery};

    try {
      final List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = [];
      for (final term in searchTerms) {
        futures.add(_firestore
            .collection('users')
            .where('username', isGreaterThanOrEqualTo: term)
            .where('username', isLessThanOrEqualTo: '$term\uf8ff')
            .limit(10)
            .get());
      }

      final snapshots = await Future.wait(futures);
      final Map<String, UserModel> uniqueUsers = {};

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          try {
            final user = UserModel.fromFirestore(doc);
            if (user.uid != uid) {
              uniqueUsers[user.uid] = user;
            }
          } catch (_) {
            // Ignore malformed user docs parsing error
          }
        }
      }

      return uniqueUsers.values.take(10).toList();
    } catch (_) {
      return [];
    }
  }

  /// Send a friend request to another user.
  ///
  /// Creates a doc in `friendRequests` collection.
  /// Returns the request ID or null if failed.
  Future<String?> sendFriendRequest(String toUid) async {
    final uid = _currentUid;
    if (uid == null || uid == toUid) return null;

    // Check if already friends
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final friends = List<String>.from(userDoc.data()?['friends'] ?? []);
    if (friends.contains(toUid)) return null;

    // Check if request already exists
    final existing = await _firestore
        .collection('friendRequests')
        .where('fromUid', isEqualTo: uid)
        .where('toUid', isEqualTo: toUid)
        .limit(1)
        .get();

    // Get sender's profile
    final senderDoc = await _firestore.collection('users').doc(uid).get();
    final senderData = senderDoc.data() ?? {};

    // Get receiver's profile
    final receiverDoc = await _firestore.collection('users').doc(toUid).get();
    final receiverData = receiverDoc.data() ?? {};

    String? requestId;

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final status = doc.data()['status'];
      if (status == FriendRequestStatus.pending.name) {
        return null;
      }
      // If rejected, update to pending
      await doc.reference.update({'status': FriendRequestStatus.pending.name});
      requestId = doc.id;
    } else {
      final request = FriendRequestModel(
        id: '',
        fromUid: uid,
        toUid: toUid,
        fromName: senderData['displayName'] as String? ?? '',
        fromPhotoUrl: senderData['photoUrl'] as String? ?? '',
        toName: receiverData['displayName'] as String? ?? '',
        toPhotoUrl: receiverData['photoUrl'] as String? ?? '',
        status: FriendRequestStatus.pending,
      );

      final docRef = await _firestore
          .collection('friendRequests')
          .add(request.toFirestore());
      requestId = docRef.id;
    }

    // Send push notification if token exists
    final String? recipientToken = receiverData['fcmToken'] as String?;
    if (recipientToken != null && recipientToken.isNotEmpty) {
      final senderName = senderData['displayName'] as String? ?? 'Someone';
      NotificationService.sendNotification(
        recipientToken: recipientToken,
        title: 'New Friend Request',
        body: '$senderName sent you a friend request!',
        data: {
          'type': 'friend_request',
          'fromUid': uid,
        },
      );
    }

    return requestId;
  }

  /// Accept a friend request.
  ///
  /// Updates request status and adds both users to each other's friends array.
  /// Uses a batch write for atomicity.
  Future<bool> acceptRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();
      if (!requestDoc.exists) return false;

      final request = FriendRequestModel.fromFirestore(requestDoc);

      final batch = _firestore.batch();

      // Update request status
      batch.update(
        _firestore.collection('friendRequests').doc(requestId),
        {'status': FriendRequestStatus.accepted.name},
      );

      // Add to sender's friends list
      batch.update(
        _firestore.collection('users').doc(request.fromUid),
        {
          'friends': FieldValue.arrayUnion([request.toUid]),
        },
      );

      // Add to receiver's friends list
      batch.update(
        _firestore.collection('users').doc(request.toUid),
        {
          'friends': FieldValue.arrayUnion([request.fromUid]),
        },
      );

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reject a friend request.
  Future<bool> rejectRequest(String requestId) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .update({'status': FriendRequestStatus.rejected.name});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a friend from both users' friend lists.
  Future<bool> removeFriend(String friendUid) async {
    final uid = _currentUid;
    if (uid == null) return false;

    try {
      final batch = _firestore.batch();

      batch.update(
        _firestore.collection('users').doc(uid),
        {
          'friends': FieldValue.arrayRemove([friendUid]),
        },
      );

      batch.update(
        _firestore.collection('users').doc(friendUid),
        {
          'friends': FieldValue.arrayRemove([uid]),
        },
      );

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stream of incoming pending friend requests for current user.
  Stream<List<FriendRequestModel>> getPendingRequests() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('friendRequests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of current user's friend UIDs.
  Stream<List<String>> getFriendUids() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data() ?? {};
      final friendsRaw = data['friends'];
      if (friendsRaw is List) {
        return friendsRaw.map((e) => e.toString()).toList();
      }
      return <String>[];
    });
  }

  /// Stream of current user's friends as UserModel list.
  Stream<List<UserModel>> getFriendsList() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return <UserModel>[];
      final data = doc.data() ?? {};
      final friendsRaw = data['friends'];
      final List<String> friendUids = [];
      if (friendsRaw is List) {
        friendUids.addAll(friendsRaw.map((e) => e.toString()));
      }

      if (friendUids.isEmpty) return <UserModel>[];

      // Fetch friends in batches of 10 (Firestore 'whereIn' limit)
      final friends = <UserModel>[];
      for (int i = 0; i < friendUids.length; i += 10) {
        final batch = friendUids.sublist(
            i, i + 10 > friendUids.length ? friendUids.length : i + 10);
        try {
          final snapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          for (final doc in snapshot.docs) {
            try {
              friends.add(UserModel.fromFirestore(doc));
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing friend doc ${doc.id}: $e');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching batch of friends: $e');
          }
        }
      }
      return friends;
    });
  }

  /// Get the current user's profile.
  Future<UserModel?> getCurrentUser() async {
    final uid = _currentUid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}
