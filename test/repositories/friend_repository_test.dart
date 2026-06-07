import 'package:flutter_test/flutter_test.dart';
import 'package:betogether/features/map/repositories/location_repository.dart';

void main() {
  group('UserLocation', () {
    test('fromMap creates location with all fields', () {
      final data = {
        'lat': 37.7749,
        'lng': -122.4194,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'isOnline': true,
      };

      final location = UserLocation.fromMap('user_1', data);

      expect(location.uid, 'user_1');
      expect(location.lat, closeTo(37.7749, 0.0001));
      expect(location.lng, closeTo(-122.4194, 0.0001));
      expect(location.isOnline, isTrue);
    });

    test('fromMap handles missing fields', () {
      final location = UserLocation.fromMap('user_1', {});

      expect(location.uid, 'user_1');
      expect(location.lat, 0.0);
      expect(location.lng, 0.0);
      expect(location.lastUpdated, 0);
      expect(location.isOnline, isFalse);
    });

    test('fromMap handles int coordinates', () {
      final data = {'lat': 37, 'lng': -122};
      final location = UserLocation.fromMap('u', data);

      expect(location.lat, 37.0);
      expect(location.lng, -122.0);
    });

    test('toMap produces correct output', () {
      final location = UserLocation(
        uid: 'user_1',
        lat: 40.7128,
        lng: -74.0060,
        lastUpdated: 1717000000000,
        isOnline: true,
      );

      final map = location.toMap();

      expect(map['lat'], 40.7128);
      expect(map['lng'], -74.0060);
      expect(map['lastUpdated'], 1717000000000);
      expect(map['isOnline'], isTrue);
    });

    test('isStale returns true for old locations', () {
      final staleLocation = UserLocation(
        uid: 'user_1',
        lat: 0,
        lng: 0,
        lastUpdated:
            DateTime.now().millisecondsSinceEpoch - (6 * 60 * 1000), // 6 min ago
        isOnline: true,
      );

      expect(staleLocation.isStale, isTrue);
    });

    test('isStale returns false for recent locations', () {
      final freshLocation = UserLocation(
        uid: 'user_1',
        lat: 0,
        lng: 0,
        lastUpdated:
            DateTime.now().millisecondsSinceEpoch - (2 * 60 * 1000), // 2 min ago
        isOnline: true,
      );

      expect(freshLocation.isStale, isFalse);
    });

    test('isStale boundary at 5 minutes', () {
      final atBoundary = UserLocation(
        uid: 'user_1',
        lat: 0,
        lng: 0,
        lastUpdated:
            DateTime.now().millisecondsSinceEpoch - (5 * 60 * 1000 + 100),
        isOnline: true,
      );

      expect(atBoundary.isStale, isTrue);
    });
  });
}
