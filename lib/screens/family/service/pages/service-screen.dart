import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../../config/router/routes.dart';
import '../../../../config/shared/widgets/custom-button.dart';
import '../../../../config/utilis/app_colors.dart';
import '../../../../gen/assets.gen.dart';
import '../widgets/service-item.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final int price = 150; // باكدج كاملة: Doctor + Mentor (سعر ثابت)

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
              padding: EdgeInsets.symmetric(horizontal: context.w(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Your Care Package",
                    style: TextStyle(
                      color: const Color(0xFF0E3E3B),
                      fontSize: context.sp(26),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Text(
                    "Doctor + Mentor included",
                    style: TextStyle(
                      color: const Color(0xFF7EA9A3),
                      fontWeight: FontWeight.w600,
                      fontSize: context.sp(14),
                    ),
                  ),
                  SizedBox(height: context.h(24)),

                  // كارد الباكدج الوحيدة
                  ServiceItem(
                    title: "Full Package",
                    price: "$price\$",
                    path: Assets.images.png.both.path,
                    features: const [
                      "Doctor follow-ups",
                      "Mentor sessions",
                      "24/7 support",
                      "Reminders & tracking",
                    ],
                  ),

                  SizedBox(height: context.h(28)),

                  // السعر النهائي
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(16),
                      vertical: context.h(14),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.w(16)),
                      border: Border.all(
                        color: AppColors.borderColor.withOpacity(.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Total Price",
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: context.sp(18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "$price\$",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: context.sp(18),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: context.h(20)),

                  // زر التالي
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onClick: () {
                        Navigator.pushNamed(context, AppRoutes.doctorSelection);
                      },
                      text: "Next",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
