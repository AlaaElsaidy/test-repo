import 'package:flutter/material.dart';

import '../utilis/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'OpenSans',
    scaffoldBackgroundColor: Colors.white,
    appBarTheme:
        const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: AppColors.primaryColor,
      selectionHandleColor: AppColors.primaryColor,
    ),
  );
  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: Colors.black,
    fontFamily: 'OpenSans',
  );
}
