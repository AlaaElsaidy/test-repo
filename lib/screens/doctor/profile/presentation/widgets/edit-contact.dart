import 'package:flutter/material.dart';

import '../../../../../config/utilis/app_colors.dart';
import 'build-input-field.dart';

Future<void> openEditContact({
  required BuildContext context,
  required String phone,
  required String email,
  required void Function(String phone, String email) onSave,
}) async {
  final theme = Theme.of(context);
  final bool isDarkMode = theme.brightness == Brightness.dark;
  final Color titleColor =
      isDarkMode ? theme.colorScheme.onSurface : AppColors.gray900;
  final Color labelColor = isDarkMode
      ? theme.colorScheme.onSurface.withOpacity(0.7)
      : AppColors.gray600;
  final Color borderColor = isDarkMode ? AppColors.gray600 : AppColors.gray200;
  final Color primaryColor = theme.colorScheme.primary;

  final phoneCtrl = TextEditingController(text: phone);
  final emailCtrl = TextEditingController(text: email);
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: theme.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sheetContext.l10n.editContactInfo,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 16),
            BuildInputField(
              label: sheetContext.l10n.phone,
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              icon: Icons.phone,
            ),
            const SizedBox(height: 12),
            BuildInputField(
              label: sheetContext.l10n.email,
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: labelColor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(sheetContext.l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final updatedPhone = phoneCtrl.text.trim();
                      final updatedEmail = emailCtrl.text.trim();
                      onSave(updatedPhone, updatedEmail);
                      Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: AppColors.whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(sheetContext.l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
