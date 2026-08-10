import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/storage_keys.dart';
import '../storage/storage_service.dart';

class ThemeController extends GetxController {
  ThemeController(this._storage)
    : themeMode = Rx<ThemeMode>(
        _storage.readString(StorageKeys.themeMode) == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
      locale = Rx<Locale>(
        Locale(_storage.readString(StorageKeys.locale) ?? 'en'),
      );

  final StorageService _storage;
  final Rx<ThemeMode> themeMode;
  final Rx<Locale> locale;

  bool get isDark => themeMode.value == ThemeMode.dark;
  bool get isArabic => locale.value.languageCode == 'ar';

  Future<void> toggleTheme() async {
    themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
    Get.changeThemeMode(themeMode.value);
    await _storage.writeString(
      StorageKeys.themeMode,
      themeMode.value == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> toggleLocale() async {
    locale.value = Locale(isArabic ? 'en' : 'ar');
    Get.updateLocale(locale.value);
    await _storage.writeString(StorageKeys.locale, locale.value.languageCode);
  }
}
