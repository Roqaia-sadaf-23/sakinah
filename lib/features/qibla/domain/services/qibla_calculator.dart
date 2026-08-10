import 'dart:math' as math;

class QiblaCalculator {
  const QiblaCalculator();

  static const kaabaLatitude = 21.4225;
  static const kaabaLongitude = 39.8262;

  double bearingFrom({required double latitude, required double longitude}) {
    final userLatitude = _toRadians(latitude);
    final kaabaLatitudeRadians = _toRadians(kaabaLatitude);
    final longitudeDifference = _toRadians(kaabaLongitude - longitude);

    final y = math.sin(longitudeDifference) * math.cos(kaabaLatitudeRadians);
    final x =
        math.cos(userLatitude) * math.sin(kaabaLatitudeRadians) -
        math.sin(userLatitude) *
            math.cos(kaabaLatitudeRadians) *
            math.cos(longitudeDifference);

    return normalizeDegrees(_toDegrees(math.atan2(y, x)));
  }

  double signedDifference({required double target, required double current}) =>
      (target - current + 540) % 360 - 180;

  double normalizeDegrees(double degrees) => (degrees % 360 + 360) % 360;

  double _toRadians(double degrees) => degrees * math.pi / 180;

  double _toDegrees(double radians) => radians * 180 / math.pi;
}
