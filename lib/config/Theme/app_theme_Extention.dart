import 'package:alzcare/config/Theme/theme-cubit/ThemeCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension ThemeContext on BuildContext {
  bool get isDarkMode => watch<ThemeCubit>().state == ThemeMode.dark;

  Color get textColor => isDarkMode ? Colors.white : Colors.black;

  Color get surfaceColor =>
      isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB);

  Color get bgColor =>
      isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB);

  Color get borderColor =>
      isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  Color get textPrimary =>
      isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF111827);

  Color get textSecondary =>
      isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
}
