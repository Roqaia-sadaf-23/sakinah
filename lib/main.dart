import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/storage/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await Get.putAsync<StorageService>(
    () => StorageService().initialize(),
    permanent: true,
  );
  runApp(const IslamicCompanionApp());
}
