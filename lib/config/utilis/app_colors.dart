import 'package:flutter/material.dart';

class AppColors {
  static const Color darkGrey = Color.fromRGBO(0, 0, 0, .5);
  static const Color hintText = Color(0xff6F7384);
  static const Color filledColor = Color(0x4CD9D9D9);
  static const Color borderColor = Color(0x4C858585);
  static const Color primaryColor = Color(0xFF14B8A6);
  static const Color secondaryColor = Color(0xff83B9FF);
  static const Color lightGray = Color(0xff858585);
  static const Color blackColor = Color(0xff000000);
  static const Color whiteColor = Color(0xffffffff);
  static const Color blackTextColor = Color(0xff222B45);
  static const Color semiWhiteColor = Color(0xfff2f2f2);
  static const Color redColor = Color(0xffF30000);
  static const Color greenColor = Color(0xff00c04b);

  ///////////////////////////////////////////////////////////
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

  // Gradients
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
}
