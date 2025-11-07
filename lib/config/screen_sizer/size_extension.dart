import 'package:flutter/material.dart';

import 'screen_sizer_utility.dart';

extension ScreenLayOut on BuildContext {
  double w(double width) => ScreenSizerUtility.resizeWidth(this, width);

  double h(double height) => ScreenSizerUtility.resizeHeight(this, height);

  double sp(double fontSize) => ScreenSizerUtility.resizeText(this, fontSize);

  bool get isDesktopAndTablet => ScreenSizerUtility.isDesktop(this);

  bool get isTablet => ScreenSizerUtility.isTablet(this);

  bool get isMobile => ScreenSizerUtility.isMobile(this);
}
