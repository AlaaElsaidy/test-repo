import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../config/router/routes.dart';
import '../../../config/utilis/app_colors.dart';

Widget buildSignUpLink(BuildContext context) {
  final isAr =
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';
  String tr(String en, String ar) => isAr ? ar : en;

  return Center(
    child: RichText(
      text: TextSpan(
        style: TextStyle(fontSize: context.sp(16)),
        children: [
          TextSpan(
            text: tr("Don't have an account? ",
                'ليس لديك حساب؟ '),
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.gray500),
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.signUp);
              },
              child: Text(
                tr('Sign up', 'إنشاء حساب'),
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
