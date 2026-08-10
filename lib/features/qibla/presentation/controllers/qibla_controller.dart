import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/location/location_data.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/repositories/compass_repository.dart';
import '../../domain/services/qibla_calculator.dart';

enum QiblaViewStatus { loading, ready, error }

class QiblaController extends GetxController {
  QiblaController(
    this._locationService,
    this._compassRepository,
    this._calculator,
  );

  static const alignmentTolerance = 3.0;
  static const _smoothingFactor = 0.18;
  static const _sensorWaitDuration = Duration(seconds: 6);

  final LocationService _locationService;
  final CompassRepository _compassRepository;
  final QiblaCalculator _calculator;

  final status = QiblaViewStatus.loading.obs;
  final location = Rxn<LocationData>();
  final qiblaBearing = 0.0.obs;
  final heading = 0.0.obs;
  final continuousHeading = 0.0.obs;
  final directionDifference = 0.0.obs;
  final errorKey = ''.obs;

  StreamSubscription<double?>? _headingSubscription;
  Timer? _sensorTimer;
  bool _hasHeading = false;

  bool get isAligned => directionDifference.value.abs() <= alignmentTolerance;

  bool get shouldTurnRight => directionDifference.value > 0;

  bool get canOpenSettings => {
    'qibla_location_services_disabled',
    'qibla_location_permission_permanently_denied',
  }.contains(errorKey.value);

  String get locationLabel {
    final value = location.value?.displayName ?? '';
    return value.isEmpty ? 'location_unknown'.tr : value;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    await _headingSubscription?.cancel();
    _sensorTimer?.cancel();
    _hasHeading = false;
    status.value = QiblaViewStatus.loading;
    errorKey.value = '';

    try {
      final currentLocation = await _locationService.getCurrentLocation();
      location.value = currentLocation;
      qiblaBearing.value = _calculator.bearingFrom(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
      );
      _listenToHeading();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> openRelevantSettings() async {
    if (errorKey.value == 'qibla_location_services_disabled') {
      await _locationService.openLocationSettings();
    } else {
      await _locationService.openAppSettings();
    }
  }

  void _listenToHeading() {
    _sensorTimer = Timer(_sensorWaitDuration, () {
      if (!_hasHeading) {
        _showError(const AppException(AppErrorType.sensorUnavailable));
      }
    });

    try {
      _headingSubscription = _compassRepository.headingStream.listen(
        _onHeading,
        onError: _showError,
        cancelOnError: false,
      );
    } catch (error) {
      _showError(error);
    }
  }

  void _onHeading(double? rawHeading) {
    if (rawHeading == null || !rawHeading.isFinite) {
      _showError(const AppException(AppErrorType.sensorUnavailable));
      return;
    }

    final normalized = _calculator.normalizeDegrees(rawHeading);
    if (!_hasHeading) {
      _hasHeading = true;
      _sensorTimer?.cancel();
      continuousHeading.value = normalized;
      heading.value = normalized;
      status.value = QiblaViewStatus.ready;
    } else {
      final currentNormalized = _calculator.normalizeDegrees(
        continuousHeading.value,
      );
      final delta = _calculator.signedDifference(
        target: normalized,
        current: currentNormalized,
      );
      continuousHeading.value += delta * _smoothingFactor;
      heading.value = _calculator.normalizeDegrees(continuousHeading.value);
    }

    directionDifference.value = _calculator.signedDifference(
      target: qiblaBearing.value,
      current: heading.value,
    );
  }

  void _showError(Object error) {
    _sensorTimer?.cancel();
    final exception = error is AppException
        ? error
        : AppException(AppErrorType.sensor, error);
    errorKey.value = switch (exception.type) {
      AppErrorType.locationServicesDisabled =>
        'qibla_location_services_disabled',
      AppErrorType.locationPermissionDenied =>
        'qibla_location_permission_denied',
      AppErrorType.locationPermissionPermanentlyDenied =>
        'qibla_location_permission_permanently_denied',
      AppErrorType.locationUnavailable => 'qibla_location_unavailable',
      _ => exception.localizationKey,
    };
    status.value = QiblaViewStatus.error;
  }

  @override
  void onClose() {
    _sensorTimer?.cancel();
    _headingSubscription?.cancel();
    super.onClose();
  }
}
