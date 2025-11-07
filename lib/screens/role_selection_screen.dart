import 'package:alzcare/config/router/routes.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightGradient,
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
                  const Text(
                    'AlzCare',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.teal900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compassionate Care for Alzheimer\'s Patients',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                        const Text(
                          'Select Your Role',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal900,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Patient Button
                        _RoleButton(
                          icon: Icons.person,
                          label: 'Patient Portal',
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Doctor Button
                        _RoleButton(
                          icon: Icons.medical_services,
                          label: 'Doctor Portal',
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Family Button
                        _RoleButton(
                          icon: Icons.family_restroom,
                          label: 'Family Member Portal',
                          onPressed: () {
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
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
