import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/ads/ads_controller.dart';
import 'core/ads/ads_gateway.dart';
import 'core/storage/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('1: Flutter initialized');

  await initializeDateFormatting();
  debugPrint('2: Date formatting initialized');

  await Get.putAsync<StorageService>(
    () => StorageService().initialize(),
    permanent: true,
  );

  // This integration has Android IDs only. UMP starts after the first frame,
  // without delaying app startup or initializing ads before consent permits.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    Get.put(AdsController(GoogleAdsGateway()), permanent: true);
  }
  runApp(const IslamicCompanionApp());
  debugPrint('4: runApp called');
}
