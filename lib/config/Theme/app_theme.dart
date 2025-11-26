import 'package:flutter/material.dart';

import '../utilis/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'OpenSans',
    scaffoldBackgroundColor: Color(0xffffffff),
    appBarTheme:
        const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: AppColors.primaryColor,
      selectionHandleColor: AppColors.primaryColor,
    ),
  );
  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: Color(0xFF111827),
    fontFamily: 'OpenSans',
  );
}
