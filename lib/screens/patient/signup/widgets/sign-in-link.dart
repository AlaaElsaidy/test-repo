import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../../config/utilis/app_colors.dart';

Widget buildSignInLink(BuildContext context) {
  return Center(
    child: RichText(
      text: TextSpan(
        style: TextStyle(fontFamily: 'Open Sans', fontSize: context.sp(16)),
        children: [
          const TextSpan(
            text: "Already have an account? ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.lightGray,
            ),
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Text(
                'Sign in',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(16),
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
