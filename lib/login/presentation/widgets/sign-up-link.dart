import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../config/router/routes.dart';
import '../../../config/utilis/app_colors.dart';

Widget buildSignUpLink(BuildContext context) {
  final isAr = Localizations.localeOf(context).languageCode == 'ar';

  return Center(
    child: RichText(
      text: TextSpan(
        style: TextStyle(fontSize: context.sp(16)),
        children: [
          TextSpan(
            text: isAr ? "ما عندكش حساب؟ " : "Don't have an account? ",
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.gray500),
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.signUp);
              },
              child: Text(
                isAr ? 'سجّل حساب جديد' : 'Sign up',
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
