import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import 'custom-button.dart';

void showSuccessDialog(
    {required String title,
    required String description,
    required BuildContext context,
    required Function onClick}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.w(20))),
      title: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.w(16), vertical: context.h(16)),
            decoration: BoxDecoration(
                color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.check_circle,
                color: Colors.green.shade600, size: context.sp(60)),
          ),
          SizedBox(height: context.h(16)),
          Text(title,
              style: TextStyle(
                  fontSize: context.sp(22), fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(description, textAlign: TextAlign.center),
      actions: [
        CustomButton(
          onClick: () {
            onClick();
          },
          text: 'Go To Login Page',
        ),
      ],
    ),
  );
}
