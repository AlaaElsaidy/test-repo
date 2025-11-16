import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import 'custom-button.dart';

void showErrorDialog(
    {required String title,
    required String error,
    required BuildContext context}) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.w(20))),
      title: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: context.sp(60)),
          SizedBox(height: context.h(16)),
          Text(title,
              style: TextStyle(
                  fontSize: context.sp(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
        ],
      ),
      content: Text(error, textAlign: TextAlign.center),
      actions: [
        CustomButton(onClick: () => Navigator.pop(context), text: 'Try Again'),
      ],
    ),
  );
}
