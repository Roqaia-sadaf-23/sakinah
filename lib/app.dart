import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/localization/app_translations.dart';
import 'core/routing/app_pages.dart';
import 'core/routing/app_routes.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class IslamicCompanionApp extends StatelessWidget {
  const IslamicCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    final themeController = Get.put(ThemeController(storage), permanent: true);

    return Obx(
      () => GetMaterialApp(
        title: 'Islamic Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.themeMode.value,
        translations: AppTranslations(),
        locale: themeController.locale.value,
        fallbackLocale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: AppRoutes.home,
        getPages: AppPages.pages,
        defaultTransition: Transition.fadeIn,
      ),
    );
  }
}
