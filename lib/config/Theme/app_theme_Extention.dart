import 'package:flutter/material.dart';

extension TextThemeExtension on BuildContext {
  TextStyle? titleLarge({Color? color, double? size, FontWeight? weight}) =>
      Theme.of(this).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: weight,
            fontSize: size,
          );

  TextStyle? bodySmall({Color? color, double? size, FontWeight? weight}) =>
      Theme.of(this).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: weight,
            fontSize: size,
          );
}
