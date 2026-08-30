import 'package:get/get.dart';

import '../../../../core/storage/storage_service.dart';
import '../../data/datasources/azkar_local_data_source.dart';
import '../../data/repositories/azkar_repository_impl.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../../domain/usecases/get_azkar_categories.dart';
import '../controllers/azkar_controller.dart';

class AzkarBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AzkarLocalDataSource>()) {
      Get.lazyPut<AzkarLocalDataSource>(AssetAzkarLocalDataSource.new);
    }
    if (!Get.isRegistered<AzkarRepository>()) {
      Get.lazyPut<AzkarRepository>(
        () => AzkarRepositoryImpl(
          Get.find<AzkarLocalDataSource>(),
          Get.find<StorageService>(),
        ),
      );
    }
    if (!Get.isRegistered<GetAzkarCategories>()) {
      Get.lazyPut(() => GetAzkarCategories(Get.find<AzkarRepository>()));
    }
    if (!Get.isRegistered<AzkarController>()) {
      Get.lazyPut(
        () => AzkarController(
          Get.find<GetAzkarCategories>(),
          Get.find<AzkarRepository>(),
        ),
      );
    }
  }
}
