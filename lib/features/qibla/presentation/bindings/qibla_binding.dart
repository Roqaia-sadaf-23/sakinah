import 'package:get/get.dart';

import '../../../../core/location/location_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../data/repositories/device_compass_repository.dart';
import '../../domain/repositories/compass_repository.dart';
import '../../domain/services/qibla_calculator.dart';
import '../controllers/qibla_controller.dart';

class QiblaBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LocationService>()) {
      Get.lazyPut(() => LocationService(Get.find<StorageService>()));
    }
    Get.lazyPut<CompassRepository>(DeviceCompassRepository.new);
    Get.lazyPut(QiblaCalculator.new);
    Get.lazyPut(
      () => QiblaController(
        Get.find<LocationService>(),
        Get.find<CompassRepository>(),
        Get.find<QiblaCalculator>(),
      ),
    );
  }
}
