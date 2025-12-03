import 'package:alzcare/config/router/routes.dart';
import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.tealGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Memora',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.teal900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'رعاية رحيمة لمرضى الزهايمر'
                        : 'Compassionate Care for Alzheimer\'s Patients',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.teal600,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Role Selection Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.teal500.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'اختر دورك' : 'Select Your Role',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal900,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Patient Button
                        _RoleButton(
                          icon: Icons.person,
                          label: isAr ? 'بوابة المريض' : 'Patient Portal',
                          onPressed: () {
                            SharedPrefsHelper.saveString('selectedRole', 'patient');
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Doctor Button
                        _RoleButton(
                          icon: Icons.medical_services,
                          label: isAr ? 'بوابة الطبيب' : 'Doctor Portal',
                          onPressed: () {
                            SharedPrefsHelper.saveString('selectedRole', 'doctor');
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Family Button
                        _RoleButton(
                          icon: Icons.family_restroom,
                          label:
                              isAr ? 'بوابة أفراد العائلة' : 'Family Member Portal',
                          onPressed: () {
                            SharedPrefsHelper.saveString('selectedRole', 'family');
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.teal500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22 * textScale),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14 * textScale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
