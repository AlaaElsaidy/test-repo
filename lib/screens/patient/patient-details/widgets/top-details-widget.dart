import 'dart:io';
import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../../config/utilis/app_colors.dart';

class TopDetailsWidget extends StatelessWidget {
  const TopDetailsWidget({
    super.key,
    required this.onTap,
    this.imageFile,
  });

  final VoidCallback onTap;
  final File? imageFile;

  @override
  Widget build(BuildContext context) {
    final radius = context.sp(22);
    final headerH = context.h(230);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: headerH,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.borderColor.withOpacity(.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: context.sp(18),
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
            vertical: context.h(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // العنوان
              Text(
                'Enter your loved one details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.tealDark,
                  fontWeight: FontWeight.w800,
                  fontSize: context.sp(18),
                ),
              ),
              SizedBox(height: context.h(6)),
              Text(
                "Please fill in the patient’s personal information carefully to help us provide accurate care and support",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF7EA9A3),
                  fontWeight: FontWeight.w600,
                  fontSize: context.sp(12.5),
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: onTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: context.w(92),
                      height: context.w(92),
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
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: imageFile != null
                                ? Image.file(imageFile!, fit: BoxFit.cover)
                                : Icon(
                                    Icons.person_rounded,
                                    size: context.w(40),
                                    color:
                                        AppColors.primaryColor.withOpacity(.6),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: context.w(6),
                      bottom: context.w(6),
                      child: Container(
                        width: context.w(34),
                        height: context.h(34),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: context.sp(10),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: context.sp(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.h(12)),
            ],
          ),
        ),
      ),
    );
  }
}
