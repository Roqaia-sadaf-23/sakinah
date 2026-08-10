import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/qibla/domain/services/qibla_calculator.dart';

void main() {
  const calculator = QiblaCalculator();

  group('QiblaCalculator', () {
    test('calculates the initial great-circle bearing from Riyadh', () {
      final bearing = calculator.bearingFrom(
        latitude: 24.7136,
        longitude: 46.6753,
      );

      expect(bearing, closeTo(243.7979, 0.001));
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
    });

    test('uses the shortest signed turn across north', () {
      expect(calculator.signedDifference(target: 10, current: 350), 20);
      expect(calculator.signedDifference(target: 350, current: 10), -20);
    });
  });
}
