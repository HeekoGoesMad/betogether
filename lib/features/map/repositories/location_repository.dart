import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Location data for a user on the map.
class UserLocation {
  final String uid;
  final double lat;
  final double lng;
  final int lastUpdated;
  final bool isOnline;

  const UserLocation({
    required this.uid,
    required this.lat,
    required this.lng,
    required this.lastUpdated,
    this.isOnline = false,
  });

  factory UserLocation.fromMap(String uid, Map<dynamic, dynamic> data) {
    return UserLocation(
      uid: uid,
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: (data['lastUpdated'] as num?)?.toInt() ?? 0,
      isOnline: data['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'lastUpdated': lastUpdated,
      'isOnline': isOnline,
    };
  }

  /// Whether this location is stale (> 5 minutes old).
  bool get isStale {
    final age = DateTime.now().millisecondsSinceEpoch - lastUpdated;
    return age > 5 * 60 * 1000; // 5 minutes
  }
}

/// Repository for managing live GPS locations via Firebase Realtime Database.
///
/// RTDB schema:
/// ```
/// locations/{uid}/
///   lat: double
///   lng: double
///   lastUpdated: int (epoch ms)
///   isOnline: bool
///   viewers/{viewerUid}: true
/// ```
class LocationRepository {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  LocationRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _db = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  /// Update current user's location in RTDB.
  Future<void> updateMyLocation(double lat, double lng) async {
    final uid = _currentUid;
    if (uid == null) return;

    await _db.ref('locations/$uid').update({
      'lat': lat,
      'lng': lng,
      'lastUpdated': ServerValue.timestamp,
      'isOnline': true,
    });
  }

  /// Set current user as offline.
  Future<void> setOffline() async {
    final uid = _currentUid;
    if (uid == null) return;
    await _db.ref('locations/$uid/isOnline').set(false);
  }

  /// Set current user as online.
  Future<void> setOnline() async {
    final uid = _currentUid;
    if (uid == null) return;
    await _db.ref('locations/$uid/isOnline').set(true);
  }

  /// Setup onDisconnect handler to auto-set offline when connection drops.
  Future<void> setupPresence() async {
    final uid = _currentUid;
    if (uid == null) return;
    await _db.ref('locations/$uid/isOnline').onDisconnect().set(false);
    await _db.ref('locations/$uid/isOnline').set(true);
  }

  /// Stream a specific friend's location.
  Stream<UserLocation?> streamFriendLocation(String friendUid) {
    return _db.ref('locations/$friendUid').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return UserLocation.fromMap(friendUid, data);
    });
  }

  /// Stream locations for all friends.
  ///
  /// Returns a map of friendUid → UserLocation.
  Stream<Map<String, UserLocation>> streamFriendLocations(
      List<String> friendUids) {
    if (friendUids.isEmpty) return Stream.value({});

    // Combine individual friend streams
    final streams = friendUids
        .map((uid) => streamFriendLocation(uid)
            .map((loc) => MapEntry(uid, loc)))
        .toList();

    return _combineStreams(streams, friendUids);
  }

  Stream<Map<String, UserLocation>> _combineStreams(
    List<Stream<MapEntry<String, UserLocation?>>> streams,
    List<String> friendUids,
  ) {
    final latest = <String, UserLocation>{};

    // Use a StreamController to merge all friend location streams
    final controller = StreamController<Map<String, UserLocation>>();
    final subscriptions = <StreamSubscription>[];

    for (final stream in streams) {
      final sub = stream.listen((entry) {
        if (entry.value != null) {
          latest[entry.key] = entry.value!;
        } else {
          latest.remove(entry.key);
        }
        controller.add(Map.from(latest));
      });
      subscriptions.add(sub);
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  /// Register that current user is viewing [targetUid]'s location.
  ///
  /// This triggers the target user to activate more frequent GPS updates.
  Future<void> registerViewing(String targetUid) async {
    final uid = _currentUid;
    if (uid == null) return;
    await _db.ref('locations/$targetUid/viewers/$uid').set(true);
    // Auto-remove on disconnect
    await _db.ref('locations/$targetUid/viewers/$uid').onDisconnect().remove();
  }

  /// Unregister viewing of [targetUid]'s location.
  Future<void> unregisterViewing(String targetUid) async {
    final uid = _currentUid;
    if (uid == null) return;
    await _db.ref('locations/$targetUid/viewers/$uid').remove();
  }

  /// Stream the count of users currently viewing current user's location.
  Stream<int> streamViewerCount() {
    final uid = _currentUid;
    if (uid == null) return Stream.value(0);

    return _db.ref('locations/$uid/viewers').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return data?.length ?? 0;
    });
  }

  /// Clear all location data for current user (on logout).
  Future<void> clearMyLocation() async {
    final uid = _currentUid;
    if (uid == null) return;
    await _db.ref('locations/$uid').remove();
  }
}
