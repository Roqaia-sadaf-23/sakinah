import 'package:flutter/material.dart';

abstract final class QuranTextStyle {
  /// Bundled rather than resolved from the platform so Uthmani combining marks
  /// have the same metrics and shaping on every supported device.
  static const fontFamily = 'NotoNaskhArabic';
  static const _fallbacks = <String>['Noto Naskh Arabic', 'sans-serif'];

  static TextStyle of({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.9,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallbacks,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    leadingDistribution: TextLeadingDistribution.proportional,
    color: color,
  );

  static StrutStyle strut(double fontSize) => StrutStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallbacks,
    fontSize: fontSize,
    height: 1.9,
    leadingDistribution: TextLeadingDistribution.proportional,
  );

  static const textHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
    leadingDistribution: TextLeadingDistribution.proportional,
  );
}
