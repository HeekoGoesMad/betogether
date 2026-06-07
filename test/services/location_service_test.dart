import 'package:flutter_test/flutter_test.dart';
import 'package:betogether/core/services/location_service.dart';

void main() {
  group('LocationService', () {
    group('calculateDistance', () {
      test('returns 0 for same coordinates', () {
        final distance = LocationService.calculateDistance(
          37.7749, -122.4194,
          37.7749, -122.4194,
        );
        expect(distance, closeTo(0.0, 0.1));
      });

      test('calculates short distance correctly', () {
        // Approx 1.1 km between two points in SF
        final distance = LocationService.calculateDistance(
          37.7749, -122.4194,
          37.7849, -122.4194,
        );
        expect(distance, greaterThan(1000)); // > 1km
        expect(distance, lessThan(1200)); // < 1.2km
      });

      test('calculates long distance correctly', () {
        // SF to LA is ~559 km
        final distance = LocationService.calculateDistance(
          37.7749, -122.4194,
          34.0522, -118.2437,
        );
        expect(distance, greaterThan(500000)); // > 500km
        expect(distance, lessThan(600000)); // < 600km
      });

      test('handles negative coordinates', () {
        final distance = LocationService.calculateDistance(
          -33.8688, 151.2093, // Sydney
          -37.8136, 144.9631, // Melbourne
        );
        expect(distance, greaterThan(700000)); // > 700km
        expect(distance, lessThan(900000)); // < 900km
      });
    });

    group('formatDistance', () {
      test('formats meters for short distances', () {
        expect(LocationService.formatDistance(50), '50 m');
        expect(LocationService.formatDistance(999), '999 m');
        expect(LocationService.formatDistance(0), '0 m');
      });

      test('formats kilometers for long distances', () {
        expect(LocationService.formatDistance(1000), '1.0 km');
        expect(LocationService.formatDistance(1500), '1.5 km');
        expect(LocationService.formatDistance(10200), '10.2 km');
      });

      test('formats edge case at 1000m', () {
        expect(LocationService.formatDistance(1000), '1.0 km');
      });

      test('formats sub-km as meters', () {
        expect(LocationService.formatDistance(500), '500 m');
      });
    });
  });

  group('LocationIntervals', () {
    test('active foreground is 5 seconds', () {
      expect(LocationIntervals.activeForeground, 5);
    });

    test('friend watching is 15 seconds', () {
      expect(LocationIntervals.friendWatching, 15);
    });

    test('idle heartbeat is 60 seconds', () {
      expect(LocationIntervals.idleHeartbeat, 60);
    });

    test('background is 120 seconds', () {
      expect(LocationIntervals.background, 120);
    });

    test('low battery is 180 seconds', () {
      expect(LocationIntervals.lowBattery, 180);
    });

    test('intervals increase in correct order', () {
      expect(LocationIntervals.activeForeground,
          lessThan(LocationIntervals.friendWatching));
      expect(LocationIntervals.friendWatching,
          lessThan(LocationIntervals.idleHeartbeat));
      expect(LocationIntervals.idleHeartbeat,
          lessThan(LocationIntervals.background));
      expect(LocationIntervals.background,
          lessThan(LocationIntervals.lowBattery));
    });
  });
}
