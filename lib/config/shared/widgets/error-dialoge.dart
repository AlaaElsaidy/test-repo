import 'package:flutter/material.dart';

import 'custom-button.dart';

void showErrorDialog(
    {required String title,
    required String error,
    required BuildContext context}) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
        ],
      ),
      content: Text(error, textAlign: TextAlign.center),
      actions: [
        CustomButton(
          onClick: () {
            Navigator.pop(dialogContext);
          },
          text: 'Try Again',
        ),
      ],
    ),
  );
}
