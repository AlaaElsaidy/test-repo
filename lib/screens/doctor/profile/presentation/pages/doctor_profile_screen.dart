import 'dart:io';

import 'package:alzcare/config/Theme/app_theme_Extention.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:alzcare/screens/doctor/profile/data/profile-repo.dart';
import 'package:alzcare/screens/doctor/profile/presentation/cubit/doctor_profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../config/Theme/theme-cubit/ThemeCubit.dart';
import '../../../../../config/utilis/app_colors.dart';
import '../../../../../core/lang-cubit/lang_cubit.dart';
import '../widgets/build-input-field.dart';
import '../widgets/edit-contact.dart';
import '../widgets/info -row.dart';
import '../widgets/profile_section_card.dart';

class DoctorProfileScreen extends StatefulWidget {
  final bool requirePasswordChange;

  const DoctorProfileScreen({
    super.key,
    this.requirePasswordChange = false,
  });

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _picker = ImagePicker();
  File? _avatarFile;

  String _phone = '+1 (555) 987-6543';
  String _email = 'sarah.johnson@hospital.com';
  String _hospital = 'Springfield General Hospital';

  @override
  void initState() {
    super.initState();
    if (widget.requirePasswordChange) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showForceChangePasswordDialog();
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
      // TODO: ارفع الصورة للسيرفر واحفظ الرابط
    }
  }

  Future<void> _showForceChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure1 = true, obscure2 = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(builder: (dialogContext, setSB) {
          final titleColor = dialogContext.textPrimary;
          final labelColor = dialogContext.textSecondary;

          return AlertDialog(
            backgroundColor: dialogContext.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              dialogContext.l10n.changePasswordTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dialogContext.l10n.changePasswordMandatoryNote,
                    style: TextStyle(color: labelColor),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: obscure1,
                    decoration: _passwordDecoration(
                      context: dialogContext,
                      label: dialogContext.l10n.newPassword,
                      obscure: obscure1,
                      onToggle: () => setSB(() => obscure1 = !obscure1),
                      accentColor: dialogContext.isDarkMode
                          ? const Color(0xFF14B8A6)
                          : const Color(0xFF14B8A6), // primaryLight
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return dialogContext.l10n.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: obscure2,
                    decoration: _passwordDecoration(
                      context: dialogContext,
                      label: dialogContext.l10n.confirmPassword,
                      obscure: obscure2,
                      onToggle: () => setSB(() => obscure2 = !obscure2),
                      accentColor: dialogContext.isDarkMode
                          ? const Color(0xFF14B8A6)
                          : const Color(0xFF14B8A6), // primaryLight
                    ),
                    validator: (v) {
                      if (v != newCtrl.text) {
                        return dialogContext.l10n.passwordsDontMatch;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(foregroundColor: labelColor),
                child: Text(dialogContext.l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    // TODO: استدعاء API لتغيير الباسورد
                    if (mounted) Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dialogContext.isDarkMode
                      ? const Color(0xFF0D9488)
                      : const Color(0xFF0D9488), // primary
                  foregroundColor: dialogContext.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(dialogContext.l10n.save),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.watch<LanguageCubit>().state;
    final themeMode = context.watch<ThemeCubit>().state;
    final isDark = themeMode == ThemeMode.dark;
    final isArabic = locale.languageCode == "ar";

    return BlocProvider(
      create: (context) =>
          DoctorProfileCubit(DoctorProfileRepo(DoctorService())),
      child: BlocListener<DoctorProfileCubit, DoctorProfileState>(
        listener: (context, state) {
          //
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: BlocBuilder<DoctorProfileCubit, DoctorProfileState>(
              builder: (context, state) {
                if (state is GetDoctorDataSuccess) {
                  return SizedBox(
                    child: Text("correct"),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.tealGradient,
                        // ممكن تسيبي gradient ثابت
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: context.bgColor,
                                  backgroundImage: _avatarFile != null
                                      ? FileImage(_avatarFile!)
                                      : null,
                                  child: _avatarFile == null
                                      ? Icon(
                                          Icons.person,
                                          size: 48,
                                          color: AppColors.teal500, // tealDark
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: context.bgColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: AppColors.teal500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.doctorName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFFFFF), // أبيض ثابت
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.specialization,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.gray50,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ProfileSectionCard(
                      color: context.surfaceColor,
                      shadowColor: context.bgColor,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.contactInformation,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  openEditContact(
                                    context: context,
                                    phone: _phone,
                                    email: _email,
                                    onSave: (updatedPhone, updatedEmail) {
                                      setState(() {
                                        _phone = updatedPhone;
                                        _email = updatedEmail;
                                      });
                                    },
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      const Color(0xFF0D9488), // tealDark
                                ),
                                child: Text(l10n.edit),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InfoRow(
                            icon: Icons.phone,
                            label: l10n.phone,
                            value: _phone,
                            color: const Color(0xFF0D9488),
                          ),
                          const SizedBox(height: 14),
                          InfoRow(
                            icon: Icons.email_outlined,
                            label: l10n.email,
                            value: _email,
                            color: const Color(0xFF0D9488),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ProfileSectionCard(
                      color: context.surfaceColor,
                      shadowColor: context.bgColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: _iconBox(
                              Icon(Icons.language,
                                  color: const Color(0xFF0D9488)),
                              const Color(0xFF0D9488)
                                  .withOpacity(isDark ? 0.15 : 0.08),
                            ),
                            title: Text(
                              l10n.language,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              isArabic ? 'العربية' : 'English',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondary,
                              ),
                            ),
                            value: isArabic,
                            activeColor: const Color(0xFF0D9488),
                            onChanged: (value) {
                              final target = value ? 'ar' : 'en';
                              context
                                  .read<LanguageCubit>()
                                  .changeLanguage(target);
                            },
                          ),
                          Divider(height: 24, color: context.borderColor),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: _iconBox(
                              Icon(Icons.dark_mode_outlined,
                                  color: const Color(0xFF0D9488)),
                              const Color(0xFF0D9488).withOpacity(
                                  context.isDarkMode ? 0.15 : 0.08),
                            ),
                            title: Text(
                              l10n.darkMode,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: context.textPrimary,
                              ),
                            ),
                            value: context.isDarkMode,
                            onChanged: (_) =>
                                context.read<ThemeCubit>().toggleTheme(),
                            activeColor: const Color(0xFF0D9488),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          // tealPrimary
                          foregroundColor: context.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.logout,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required BuildContext context,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required Color accentColor,
  }) {
    final fillColor = context.bgColor;
    final borderColor = context.borderColor;
    final labelColor = context.textSecondary;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentColor),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility : Icons.visibility_off,
          color: labelColor,
        ),
        onPressed: onToggle,
      ),
    );
  }

  Widget _iconBox(Widget child, Color bg) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
