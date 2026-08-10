import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _theme(
    brightness: Brightness.light,
    scaffold: AppColors.cream,
    surface: AppColors.warmWhite,
    text: AppColors.ink,
    muted: AppColors.mutedInk,
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    scaffold: AppColors.night,
    surface: AppColors.nightSurface,
    text: const Color(0xFFF2F5F1),
    muted: const Color(0xFFA7B9B4),
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color text,
    required Color muted,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: brightness,
      primary: brightness == Brightness.light
          ? AppColors.emerald
          : const Color(0xFF83C7B4),
      secondary: AppColors.sand,
      surface: surface,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'sans-serif',
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(bodyColor: text, displayColor: text)
          .copyWith(
            displaySmall: base.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
            headlineSmall: base.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(color: muted),
          ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.55),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light
            ? AppColors.ink
            : const Color(0xFFE8F1ED),
        contentTextStyle: TextStyle(
          color: brightness == Brightness.light ? Colors.white : AppColors.ink,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
