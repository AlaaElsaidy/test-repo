import 'dart:math';

import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

class ScreenSizerUtility {
  static late double designWidth;
  static late double designHeight;

  static void init({
    required double designWidth,
    required double designHeight,
  }) {
    ScreenSizerUtility.designWidth = designWidth;
    ScreenSizerUtility.designHeight = designHeight;
  }

  static double resizeWidth(BuildContext context, double width) {
    double deviceWidth = MediaQuery.sizeOf(context).width;
    return width * (deviceWidth / designWidth);
  }

  static double resizeHeight(BuildContext context, double height) {
    double deviceHeight = MediaQuery.sizeOf(context).height;
    return height * (deviceHeight / designHeight);
  }

  static double resizeText(BuildContext context, double fontSize) {
    double deviceWidth = MediaQuery.sizeOf(context).width;
    double deviceHeight = MediaQuery.sizeOf(context).height;
    double deviceDiagonal = sqrt(pow(deviceWidth, 2) + pow(deviceHeight, 2));

    double designDiagonal = sqrt(pow(designWidth, 2) + pow(designHeight, 2));

    return fontSize * (deviceDiagonal / designDiagonal);
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= Breakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > Breakpoints.mobile &&
      MediaQuery.of(context).size.width <= Breakpoints.tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > Breakpoints.tablet;
}
