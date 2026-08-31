class CompassReading {
  const CompassReading({required this.heading, required this.accuracy});

  final double? heading;
  final double? accuracy;
}

abstract interface class CompassRepository {
  Stream<CompassReading> get readings;
}
