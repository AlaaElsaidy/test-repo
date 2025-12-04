import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../../../config/utilis/app_colors.dart';

Widget buildSignInLink(BuildContext context) {
  final isAr =
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';
  String tr(String en, String ar) => isAr ? ar : en;

  return Center(
    child: RichText(
      text: TextSpan(
        style: TextStyle(fontFamily: 'Open Sans', fontSize: context.sp(16)),
        children: [
          TextSpan(
            text: tr('Already have an account? ', 'هل لديك حساب بالفعل؟ '),
            style: const TextStyle(
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
                tr('Sign in', 'تسجيل الدخول'),
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
