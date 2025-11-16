import 'package:flutter/material.dart';

import '../../utilis/app_colors.dart';

class DecorCircle extends StatelessWidget {
  DecorCircle({super.key, required this.size});

  double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.20),
            const Color(0xFF06B6D4).withOpacity(0.20)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.10),
              blurRadius: 40,
              spreadRadius: 8)
        ],
      ),
    );
  }
}
