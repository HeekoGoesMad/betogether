import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/firebase_service.dart';
import '../repositories/location_repository.dart';

/// Provider for the location repository.
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(database: FirebaseService.database);
});

/// Provider for the current user's GPS position (stream).
final currentLocationProvider = StreamProvider<Position?>((ref) {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  );
});

/// Provider for friend locations from Realtime Database.
///
/// Requires [friendUidsProvider] to know which friends to stream.
final friendLocationsProvider =
    StreamProvider.family<Map<String, UserLocation>, List<String>>(
  (ref, friendUids) {
    final repo = ref.watch(locationRepositoryProvider);
    return repo.streamFriendLocations(friendUids);
  },
);

/// Provider for the current viewer count (how many friends are watching you).
final viewerCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(locationRepositoryProvider);
  return repo.streamViewerCount();
});

/// Whether the map screen is currently visible (controls GPS frequency).
final mapVisibleProvider = StateProvider<bool>((ref) => false);

/// Provider to stream a single friend's location/presence status.
final singleFriendLocationProvider =
    StreamProvider.family<UserLocation?, String>((ref, friendUid) {
  final repo = ref.watch(locationRepositoryProvider);
  return repo.streamFriendLocation(friendUid);
});

/// Tab index provider for HomeScreen navigation.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for centering/focusing the map camera on a specific LatLng coordinate.
final mapFocusTargetProvider = StateProvider<LatLng?>((ref) => null);
