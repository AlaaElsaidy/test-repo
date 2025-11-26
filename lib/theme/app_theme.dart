import 'package:flutter/material.dart';

class AppTheme {
  static const Color tealPrimary = Color(0xFF14B8A6);
  static const Color tealDark = Color(0xFF0D9488);
  static const Color cyanPrimary = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFF22D3EE);

  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal200 = Color(0xFF99F6E4);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal900 = Color(0xFF134E4A);

  static const Color cyan50 = Color(0xFFECFEFF);
  static const Color cyan100 = Color(0xFFCFFAFE);
  static const Color cyan500 = Color(0xFF06B6D4);
  static const Color cyan600 = Color(0xFF0891B2);

  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray900 = Color(0xFF111827);

  static const LinearGradient tealGradient = LinearGradient(
    colors: [teal500, cyan500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [cyan50, Colors.white, teal50],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [
      Color(0xFF0B1120),
      Color(0xFF0F172A),
      Color(0xFF111827),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

// static final ThemeData lightTheme = ThemeData(
//   useMaterial3: true,
//   colorScheme: ColorScheme.fromSeed(
//     seedColor: tealPrimary,
//     brightness: Brightness.light,
//   ).copyWith(
//     primary: tealPrimary,
//     secondary: cyanPrimary,
//     surface: Colors.white,
//     background: gray50,
//   ),
//   fontFamily: 'System',
//
//   // AppBar Theme
//   appBarTheme: const AppBarTheme(
//     elevation: 0,
//     centerTitle: true,
//     backgroundColor: Colors.transparent,
//     foregroundColor: teal900,
//     systemOverlayStyle: SystemUiOverlayStyle.dark,
//   ),
//
//   cardTheme: const CardThemeData(
//     elevation: 2,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.all(Radius.circular(16)),
//     ),
//     clipBehavior: Clip.antiAlias,
//   ),
//
//   // Button Themes
//   elevatedButtonTheme: ElevatedButtonThemeData(
//     style: ElevatedButton.styleFrom(
//       elevation: 0,
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//     ),
//   ),
//
//   // Input Decoration
//   inputDecorationTheme: const InputDecorationTheme(
//     filled: true,
//     fillColor: gray100,
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.all(Radius.circular(16)),
//       borderSide: BorderSide.none,
//     ),
//     contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//   ),
// );
}