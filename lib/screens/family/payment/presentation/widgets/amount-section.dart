import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../../../config/utilis/app_colors.dart';

class AmountSection extends StatelessWidget {
  AmountSection({super.key, required this.amount});

  int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(16), vertical: context.h(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.w(16)),
        border: Border.all(color: AppColors.borderColor.withOpacity(.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Text(
            "Amount to Pay",
            style: TextStyle(
                color: AppColors.blackColor,
                fontSize: context.sp(16),
                fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            "\$$amount",
            style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: context.sp(18),
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
