import 'package:flutter_compass/flutter_compass.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/compass_repository.dart';

class DeviceCompassRepository implements CompassRepository {
  @override
  Stream<CompassReading> get readings {
    final events = FlutterCompass.events;
    if (events == null) {
      return Stream<CompassReading>.error(
        const AppException(AppErrorType.sensorUnavailable),
      );
    }
    return events.map(
      (event) =>
          CompassReading(heading: event.heading, accuracy: event.accuracy),
    );
  }
}
