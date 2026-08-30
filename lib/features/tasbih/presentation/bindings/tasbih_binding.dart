import 'package:get/get.dart';

import '../../../../core/storage/storage_service.dart';
import '../controllers/tasbih_controller.dart';

class TasbihBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TasbihController>()) {
      Get.lazyPut(() => TasbihController(Get.find<StorageService>()));
    }
  }
}
