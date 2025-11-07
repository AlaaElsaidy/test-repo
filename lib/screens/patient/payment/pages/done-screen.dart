import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/router/routes.dart';
import '../../../../config/shared/widgets/custom-button.dart';
import '../../../../config/utilis/app_colors.dart';

class Done extends StatelessWidget {
  const Done({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // دوائر ديكورية خفيفة زي باقي الشاشات
          Positioned(
            top: -width * 0.25,
            left: -width * 0.15,
            child: _decorCircle(size: width * 0.7),
          ),
          Positioned(
            bottom: -width * 0.30,
            right: -width * 0.20,
            child: _decorCircle(size: width * 0.9),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(24)),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(18),
                      vertical: context.h(22),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.w(22)),
                      border: Border.all(
                          color: AppColors.borderColor.withOpacity(.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _successBadge(context),
                        SizedBox(height: context.h(16)),
                        Text(
                          "All Done!",
                          style: GoogleFonts.montserrat(
                            color: AppColors.tealDark,
                            fontSize: context.sp(26),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: context.h(8)),
                        Text(
                          "Your payment has been completed successfully.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF7EA9A3),
                            fontWeight: FontWeight.w600,
                            fontSize: context.sp(14),
                          ),
                        ),
                        SizedBox(height: context.h(30)),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            onClick: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.login,
                                (route) => false,
                              );
                            },
                            text: "Return to Login Page",
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // زر العودة
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Badge نجاح متدرّج
  Widget _successBadge(BuildContext context) {
    return Container(
      width: context.w(110),
      height: context.w(110),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(.35),
            const Color(0xFF06B6D4).withOpacity(.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: context.w(92),
          height: context.w(92),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: AppColors.primaryColor,
            size: context.w(48),
          ),
        ),
      ),
    );
  }

  // دائرة ديكورية خفيفة
  Widget _decorCircle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.20),
            const Color(0xFF06B6D4).withOpacity(0.20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.10),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}
