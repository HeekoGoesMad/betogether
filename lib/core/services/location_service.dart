import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

/// GPS tracking intervals based on app state and battery level.
class LocationIntervals {
  /// User is actively viewing the map (own position)
  static const int activeForeground = 5;

  /// A friend is viewing this user's location
  static const int friendWatching = 15;

  /// App is open but nobody is watching
  static const int idleHeartbeat = 60;

  /// App is in background
  static const int background = 120;

  /// Battery is low (< 20%)
  static const int lowBattery = 180;
}

/// Smart location service with on-demand GPS and battery optimization.
///
/// Key strategies:
/// - Distance filter: Only emit if user moved > 10 meters
/// - Viewing awareness: Activate GPS only when friends are watching
/// - Battery awareness: Throttle GPS when battery is low
/// - Smart pause: Stop GPS when stationary
class LocationService {
  LocationService._();

  static final Battery _battery = Battery();
  static StreamSubscription<Position>? _positionSubscription;
  static Timer? _pauseTimer;
  static int _stationaryCount = 0;
  static const int _stationaryThreshold = 5;
  static const int _distanceFilterMeters = 5;

  /// Check if location services are enabled and permissions granted.
  static Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Check if location services are enabled and permissions granted silently.
  static Future<bool> checkPermissionStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission from the user.
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position (one-shot).
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get a stream of position updates with adaptive interval.
  ///
  /// [viewerCount] — number of friends currently watching this user's location.
  /// Higher viewer count = more frequent updates.
  static Stream<Position> getPositionStream({int viewerCount = 0}) {
    final interval = _getIntervalForState(viewerCount);

    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterMeters,
        intervalDuration: Duration(seconds: interval),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'BeTogether',
          notificationText: 'Sharing your location with friends',
          enableWakeLock: true,
        ),
      ),
    );
  }

  /// Calculate optimal GPS interval based on current state.
  static Future<int> getAdaptiveInterval({int viewerCount = 0}) async {
    return _getIntervalForState(viewerCount);
  }

  static int _getIntervalForState(int viewerCount) {
    if (viewerCount < 0) {
      // -1 = active foreground (user is on the map screen)
      return LocationIntervals.activeForeground;
    }
    if (viewerCount > 0) {
      return LocationIntervals.friendWatching;
    }
    return LocationIntervals.idleHeartbeat;
  }

  /// Get interval adjusted for battery level.
  static Future<int> getBatteryAwareInterval({int viewerCount = 0}) async {
    final batteryLevel = await _battery.batteryLevel;
    if (batteryLevel < 15) {
      return LocationIntervals.lowBattery;
    }
    if (batteryLevel < 20) {
      return LocationIntervals.lowBattery;
    }
    return _getIntervalForState(viewerCount);
  }

  /// Calculate distance between two points in meters.
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Format distance for display.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Start tracking with stationarity detection.
  ///
  /// If user hasn't moved in [_stationaryThreshold] consecutive readings,
  /// pause GPS until [pauseTimeout] expires or movement detected.
  static void startSmartTracking({
    required void Function(Position) onPosition,
    required void Function() onPaused,
    int viewerCount = 0,
    Duration pauseTimeout = const Duration(minutes: 5),
  }) {
    Position? lastPosition;

    _positionSubscription?.cancel();
    _positionSubscription = getPositionStream(viewerCount: viewerCount).listen(
      (position) {
        if (lastPosition != null) {
          final distance = calculateDistance(
            lastPosition!.latitude,
            lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          if (distance < _distanceFilterMeters) {
            _stationaryCount++;
            if (_stationaryCount >= _stationaryThreshold) {
              // Pause GPS — user is stationary
              _positionSubscription?.pause();
              onPaused();
              _pauseTimer = Timer(pauseTimeout, () {
                _stationaryCount = 0;
                _positionSubscription?.resume();
              });
              return;
            }
          } else {
            _stationaryCount = 0;
          }
        }

        lastPosition = position;
        onPosition(position);
      },
      onError: (e) {
        stopTracking();
      },
    );
  }

  /// Stop all location tracking.
  static void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _pauseTimer?.cancel();
    _pauseTimer = null;
    _stationaryCount = 0;
  }

  /// Check if currently tracking.
  static bool get isTracking => _positionSubscription != null;
}
