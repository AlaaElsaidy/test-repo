import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../utilis/app_colors.dart';

class FieldWrapper extends StatelessWidget {
  FieldWrapper(
      {super.key,
      required this.icon,
      required this.child,
      this.showBorder = true});

  IconData icon;
  Widget child;
  bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(12), vertical: context.h(4)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FEFD),
        borderRadius: BorderRadius.circular(context.w(16)),
        border: showBorder ? Border.all(color: const Color(0xFFE6F1EF)) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.w(10)),
            decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(.12),
                shape: BoxShape.circle),
            child: Icon(icon, size: context.sp(18), color: AppColors.tealDark),
          ),
          SizedBox(width: context.w(12)),
          Expanded(child: child),
        ],
      ),
    );
  }
}
