import 'package:alzcare/config/utilis/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/Theme/theme-cubit/ThemeCubit.dart';
import '../../../../../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class BuildInputField extends StatelessWidget {
  BuildInputField(
      {super.key,
      required this.label,
      required this.controller,
      this.icon,
      this.keyboardType});

  String label;
  TextEditingController controller;
  TextInputType? keyboardType;
  IconData? icon;
  static const Color _primaryColor = AppColors.tealDark;
  static const Color _labelColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final bool isDarkMode = themeMode == ThemeMode.dark;
    final Color primaryColor = Color(0xFF9CA3AF);
    final Color titleColor =
        isDarkMode ? const Color(0xFFF9FAFB) : AppColors.gray900;
    final Color labelColor =
        isDarkMode ? const Color(0xFF9CA3AF) : AppColors.gray600;
    final Color cardColor =
        isDarkMode ? const Color(0xFF1F2937) : AppColors.whiteColor;
    final Color dividerColor =
        isDarkMode ? AppColors.gray600.withOpacity(0.4) : AppColors.gray200;
    final Color shadowColor =
        (isDarkMode ? AppColors.blackColor : AppColors.gray900)
            .withOpacity(isDarkMode ? 0.2 : 0.06);
    final Color subtitleAccent =
        isDarkMode ? AppColors.cyanLight : AppColors.cyan100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: titleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            prefixIcon: icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: _primaryColor, size: 20),
                    ),
                  ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 56, minHeight: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
