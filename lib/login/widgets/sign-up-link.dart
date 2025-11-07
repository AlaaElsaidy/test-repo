import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';
import '../../../config/utilis/app_colors.dart';
import '../../config/router/routes.dart';

Widget buildSignUpLink(BuildContext context) {
  return Center(
    child: RichText(
      text: TextSpan(
        style: TextStyle(fontSize: context.sp(16)),
        children: [
          const TextSpan(
            text: "Don't have an account? ",
            style: TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.gray500),
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.signUp);
              },
              child: Text(
                'Sign up',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(16),
                  color: AppColors.tealDark,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
