enum AppErrorType {
  network,
  timeout,
  invalidResponse,
  locationServicesDisabled,
  locationPermissionDenied,
  locationPermissionPermanentlyDenied,
  locationUnavailable,
  sensorUnavailable,
  sensor,
  storage,
  unknown,
}

class AppException implements Exception {
  const AppException(this.type, [this.cause]);

  final AppErrorType type;
  final Object? cause;

  String get localizationKey => switch (type) {
    AppErrorType.network => 'network_error',
    AppErrorType.timeout => 'timeout_error',
    AppErrorType.locationServicesDisabled => 'location_services_disabled',
    AppErrorType.locationPermissionDenied => 'location_permission_denied',
    AppErrorType.locationPermissionPermanentlyDenied =>
      'location_permission_permanently_denied',
    AppErrorType.locationUnavailable => 'location_unavailable',
    AppErrorType.sensorUnavailable => 'compass_unavailable',
    AppErrorType.sensor => 'compass_error',
    _ => 'prayer_times_error',
  };
}
