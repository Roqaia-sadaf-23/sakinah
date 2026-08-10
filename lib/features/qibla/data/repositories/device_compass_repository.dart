import 'package:flutter_compass/flutter_compass.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/compass_repository.dart';

class DeviceCompassRepository implements CompassRepository {
  @override
  Stream<double?> get headingStream {
    final events = FlutterCompass.events;
    if (events == null) {
      return Stream<double?>.error(
        const AppException(AppErrorType.sensorUnavailable),
      );
    }
    return events.map((event) => event.heading);
  }
}
