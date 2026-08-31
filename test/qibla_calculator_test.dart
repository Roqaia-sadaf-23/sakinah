import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/qibla/domain/services/qibla_calculator.dart';

void main() {
  const calculator = QiblaCalculator();

  group('QiblaCalculator', () {
    test('calculates the bearing from Makkah city center', () {
      final bearing = calculator.bearingFrom(
        latitude: 21.3891,
        longitude: 39.8579,
      );

      expect(bearing, closeTo(318.5409, 0.001));
    });

    test('calculates the initial great-circle bearing from Riyadh', () {
      final bearing = calculator.bearingFrom(
        latitude: 24.7136,
        longitude: 46.6753,
      );

      expect(bearing, closeTo(243.7979, 0.001));
    });

    test('calculates the initial great-circle bearing from Madinah', () {
      final bearing = calculator.bearingFrom(
        latitude: 24.4672,
        longitude: 39.6024,
      );

      expect(bearing, closeTo(176.0835, 0.001));
    });

    test('calculates bearings in different hemispheres', () {
      final london = calculator.bearingFrom(
        latitude: 51.5074,
        longitude: -0.1278,
      );
      final newYork = calculator.bearingFrom(
        latitude: 40.7128,
        longitude: -74.0060,
      );

      expect(london, closeTo(118.9872, 0.001));
      expect(newYork, closeTo(58.4817, 0.001));
    });

    test('normalizes bearings into the zero-to-360 range', () {
      expect(calculator.normalizeDegrees(-10), 350);
      expect(calculator.normalizeDegrees(370), 10);

      for (final coordinates in [
        (latitude: 21.3891, longitude: 39.8579),
        (latitude: 24.7136, longitude: 46.6753),
        (latitude: 24.4672, longitude: 39.6024),
        (latitude: 51.5074, longitude: -0.1278),
        (latitude: 40.7128, longitude: -74.0060),
      ]) {
        final bearing = calculator.bearingFrom(
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
        );
        expect(bearing, greaterThanOrEqualTo(0));
        expect(bearing, lessThan(360));
      }
    });

    test('uses the shortest signed turn across north', () {
      expect(calculator.signedDifference(target: 10, current: 350), 20);
      expect(calculator.signedDifference(target: 350, current: 10), -20);
      expect(calculator.signedDifference(target: 359, current: 1), -2);
      expect(calculator.signedDifference(target: 1, current: 359), 2);
    });
  });
}
