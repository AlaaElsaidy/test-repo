import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../../config/utilis/app_colors.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.flickr(
        leftDotColor: AppColors.primaryColor,
        rightDotColor: AppColors.blackColor,
        size: context.w(70),
      ),
    );
  }
}
