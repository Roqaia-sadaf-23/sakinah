import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/errors/app_exception.dart';
import 'package:sakinah/core/localization/app_translations.dart';
import 'package:sakinah/core/location/location_data.dart';
import 'package:sakinah/core/location/location_service.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/qibla/domain/repositories/compass_repository.dart';
import 'package:sakinah/features/qibla/domain/services/qibla_calculator.dart';
import 'package:sakinah/features/qibla/presentation/controllers/qibla_controller.dart';
import 'package:sakinah/features/qibla/presentation/pages/qibla_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('loads location and exposes live relative Qibla direction', () async {
    final compass = _ControlledCompassRepository();
    final controller = _controller(compass: compass);
    addTearDown(controller.onClose);
    addTearDown(compass.close);

    await controller.load();
    compass.add(const CompassReading(heading: 200, accuracy: 15));
    await _nextEventLoop();

    expect(controller.status.value, QiblaViewStatus.ready);
    expect(controller.qiblaBearing.value, closeTo(243.7979, 0.001));
    expect(controller.heading.value, 200);
    expect(controller.directionDifference.value, closeTo(43.7979, 0.001));
    expect(controller.compassStatus.value, QiblaCompassStatus.available);
    expect(controller.isAligned, isFalse);
  });

  test('detects alignment and low-accuracy calibration state', () async {
    final compass = _ControlledCompassRepository();
    final controller = _controller(compass: compass);
    addTearDown(controller.onClose);
    addTearDown(compass.close);

    await controller.load();
    compass.add(
      CompassReading(heading: controller.qiblaBearing.value - 2, accuracy: 45),
    );
    await _nextEventLoop();

    expect(controller.isAligned, isTrue);
    expect(controller.needsCalibration, isTrue);
  });

  for (final errorCase in <(AppErrorType, String, bool)>[
    (
      AppErrorType.locationServicesDisabled,
      'qibla_location_services_disabled',
      true,
    ),
    (
      AppErrorType.locationPermissionDenied,
      'qibla_location_permission_denied',
      false,
    ),
    (
      AppErrorType.locationPermissionPermanentlyDenied,
      'qibla_location_permission_permanently_denied',
      true,
    ),
    (AppErrorType.locationUnavailable, 'qibla_location_unavailable', false),
  ]) {
    test('handles ${errorCase.$1.name} without starting compass', () async {
      final compass = _ControlledCompassRepository();
      final controller = _controller(
        compass: compass,
        locationError: AppException(errorCase.$1),
      );
      addTearDown(controller.onClose);
      addTearDown(compass.close);

      await controller.load();

      expect(controller.status.value, QiblaViewStatus.error);
      expect(controller.errorKey.value, errorCase.$2);
      expect(controller.canOpenSettings, errorCase.$3);
      expect(compass.listenCount, 0);
    });
  }

  test('keeps north bearing visible when compass is unavailable', () async {
    final controller = _controller(
      compass: _ErrorCompassRepository(
        const AppException(AppErrorType.sensorUnavailable),
      ),
    );
    addTearDown(controller.onClose);

    await controller.load();
    await _nextEventLoop();

    expect(controller.status.value, QiblaViewStatus.ready);
    expect(controller.location.value, isNotNull);
    expect(controller.qiblaBearing.value, closeTo(243.7979, 0.001));
    expect(controller.heading.value, isNull);
    expect(controller.isAligned, isFalse);
    expect(controller.compassStatus.value, QiblaCompassStatus.unavailable);
    expect(controller.compassErrorKey.value, 'compass_unavailable');
  });

  test('cancels the compass subscription when closed', () async {
    final compass = _ControlledCompassRepository();
    final controller = _controller(compass: compass);
    await controller.load();

    expect(compass.hasListener, isTrue);
    controller.onClose();
    await _nextEventLoop();

    expect(compass.hasListener, isFalse);
    expect(compass.cancelCount, 1);
    await compass.close();
  });

  test('reload replaces rather than duplicates compass subscription', () async {
    final compass = _ControlledCompassRepository();
    final controller = _controller(compass: compass);
    addTearDown(controller.onClose);
    addTearDown(compass.close);

    await controller.load();
    await controller.load();

    expect(compass.listenCount, 2);
    expect(compass.cancelCount, 1);
    expect(compass.hasListener, isTrue);
  });

  testWidgets('Qibla page is localized and safe on a narrow cached layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(280, 620);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final compass = _ControlledCompassRepository();
    addTearDown(compass.close);
    final controller = QiblaController(
      _FakeLocationService(location: _riyadh(isCached: true)),
      compass,
      const QiblaCalculator(),
    );
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('ar'),
        home: const QiblaPage(),
      ),
    );
    await tester.pump();
    expect(
      tester.takeException(),
      isNull,
      reason: 'The north-referenced layout overflowed before a sensor event.',
    );
    expect(find.text('اتجاه القبلة من الشمال'), findsOneWidget);
    expect(
      find.text('حرك الهاتف على شكل رقم 8 لمعايرة البوصلة.'),
      findsOneWidget,
    );
    compass.add(const CompassReading(heading: 200, accuracy: 15));
    await tester.pump();

    expect(find.text('اتجاه القبلة'), findsWidgets);
    expect(find.text('يتم استخدام الموقع المحفوظ'), findsOneWidget);
    expect(find.text('اتجاه الجهاز'), findsOneWidget);
    final exception = tester.takeException();
    expect(
      exception,
      isNull,
      reason: exception is FlutterError ? exception.toStringDeep() : null,
    );
  });

  testWidgets('Qibla bearing remains usable without a compass sensor', (
    tester,
  ) async {
    final controller = QiblaController(
      _FakeLocationService(location: _riyadh()),
      _ErrorCompassRepository(
        const AppException(AppErrorType.sensorUnavailable),
      ),
      const QiblaCalculator(),
    );
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const QiblaPage(),
      ),
    );
    await tester.pump();

    expect(find.text('Qibla direction from North'), findsOneWidget);
    expect(find.text('244°'), findsOneWidget);
    expect(find.text('Current heading'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(
      find.textContaining('compass sensor is not available'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

QiblaController _controller({
  required CompassRepository compass,
  AppException? locationError,
}) => QiblaController(
  _FakeLocationService(
    location: locationError == null ? _riyadh() : null,
    error: locationError,
  ),
  compass,
  const QiblaCalculator(),
);

LocationData _riyadh({bool isCached = false}) => LocationData(
  latitude: 24.7136,
  longitude: 46.6753,
  city: 'Riyadh',
  country: 'Saudi Arabia',
  capturedAt: DateTime(2026, 8, 31),
  isCached: isCached,
);

Future<void> _nextEventLoop() => Future<void>.delayed(Duration.zero);

class _ControlledCompassRepository implements CompassRepository {
  _ControlledCompassRepository() {
    _controller = StreamController<CompassReading>.broadcast(
      onListen: () => listenCount++,
      onCancel: () => cancelCount++,
    );
  }

  late final StreamController<CompassReading> _controller;
  int listenCount = 0;
  int cancelCount = 0;

  bool get hasListener => _controller.hasListener;

  void add(CompassReading reading) => _controller.add(reading);

  Future<void> close() => _controller.close();

  @override
  Stream<CompassReading> get readings => _controller.stream;
}

class _ErrorCompassRepository implements CompassRepository {
  const _ErrorCompassRepository(this.error);

  final Object error;

  @override
  Stream<CompassReading> get readings => Stream.error(error);
}

class _FakeLocationService extends LocationService {
  _FakeLocationService({required this.location, this.error})
    : super(_MemoryStorageService());

  final LocationData? location;
  final AppException? error;

  @override
  Future<LocationData> getCurrentLocation() async {
    final locationError = error;
    if (locationError != null) throw locationError;
    return location!;
  }
}

class _MemoryStorageService extends StorageService {
  @override
  String? readString(String key) => null;

  @override
  Future<bool> writeString(String key, String value) async => true;
}
