import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/shared/widgets/error-dialoge.dart';
import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../core/supabase/invitation-service.dart';
import '../../core/supabase/patient-family-service.dart';
import '../../core/supabase/supabase-service.dart';
import '../../screens/patient/invitations/data/invitation-repo.dart';
import '../../screens/patient/invitations/presentation/cubit/invitation_cubit.dart';
import '../../screens/patient/invitations/presentation/cubit/invitation_state.dart';
import '../../theme/app_theme.dart';

class FamilyProfileScreen extends StatefulWidget {
  const FamilyProfileScreen({super.key});

  @override
  State<FamilyProfileScreen> createState() => _FamilyProfileScreenState();
}

class _FamilyProfileScreenState extends State<FamilyProfileScreen> {
  String? _currentInvitationLink;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _buildInviteMessage(String name) {
    final link = _currentInvitationLink ?? 'https://alzcare.app/invite';
    return 'Hi ${name.isEmpty ? '' : name}, you have been invited to join as a patient. Join using this link: $link';
  }

  // WhatsApp invite
  Future<void> _sendWhatsApp(String? phone, String message) async {
    if (phone == null || phone.trim().isEmpty) {
      _showSnack('Please provide a phone number');
      return;
    }
    
    // Extract digits only and ensure +2 prefix
    String phoneNumber = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // If phone already has country code (starts with 2), use it, otherwise add +2
    if (!phoneNumber.startsWith('2')) {
      phoneNumber = '2$phoneNumber';
    }
    
    if (phoneNumber.isEmpty || phoneNumber.length < 10) {
      _showSnack('Please provide a valid phone number');
      return;
    }

    final encoded = Uri.encodeComponent(message);
    final nativeUri = Uri.parse('whatsapp://send?phone=$phoneNumber&text=$encoded');

    if (await canLaunchUrl(nativeUri)) {
      final ok = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      if (!ok) {
        final webUri = Uri.parse('https://wa.me/$phoneNumber?text=$encoded');
        if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
          _showSnack('Could not open WhatsApp');
        }
      }
    } else {
      final webUri = Uri.parse('https://wa.me/$phoneNumber?text=$encoded');
      if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        _showSnack('Could not open WhatsApp');
      }
    }
  }

  // Send email
  Future<void> _sendEmail(String? email, String subject, String body) async {
    if (email == null || email.trim().isEmpty) {
      _showSnack('Please provide an email address');
      return;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      _showSnack('Please provide a valid email address');
      return;
    }

    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final mailtoUri = Uri.parse('mailto:$email?subject=$encodedSubject&body=$encodedBody');

    if (await canLaunchUrl(mailtoUri)) {
      await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open email client');
    }
  }

  void _openInviteDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => BlocProvider(
        create: (context) => InvitationCubit(
          InvitationRepo(
            InvitationService(),
            PatientFamilyService(),
            UserService(),
          ),
        ),
        child: BlocListener<InvitationCubit, InvitationState>(
          listener: (context, state) {
            if (state is InvitationFailure) {
              Navigator.pop(ctx);
              showErrorDialog(
                context: context,
                error: state.errorMessage,
                title: "Error",
              );
            } else if (state is InvitationSuccess) {
              _currentInvitationLink =
                  'https://alzcare.app/invite?code=${state.invitation.invitationCode}';
              Navigator.pop(ctx);
              _openInviteShareSheet(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
              );
            }
          },
          child: BlocBuilder<InvitationCubit, InvitationState>(
            builder: (context, state) {
              return AlertDialog(
                title: const Text('Invite a Patient'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Patient Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Phone (optional)',
                            prefixIcon: Icon(Icons.phone),
                            hintText: 'Enter phone number',
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            // Remove any non-digit characters except what user types
                            final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                            if (digits.isNotEmpty && value != digits) {
                              phoneCtrl.value = TextEditingValue(
                                text: digits,
                                selection: TextSelection.collapsed(offset: digits.length),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email (optional)',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Invalid email';
                              }
                            }
                            return null;
                          },
                        ),
                        if (phoneCtrl.text.trim().isEmpty &&
                            emailCtrl.text.trim().isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Please provide either phone or email',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: state is InvitationLoading
                        ? null
                        : () {
                            if (formKey.currentState!.validate()) {
                              final phone = phoneCtrl.text.trim();
                              final email = emailCtrl.text.trim();

                              if (phone.isEmpty && email.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please provide either phone or email'),
                                  ),
                                );
                                return;
                              }

                              final familyUid = SharedPrefsHelper.getString("familyUid") ??
                                  SharedPrefsHelper.getString("userId");
                              if (familyUid == null) {
                                Navigator.pop(ctx);
                                showErrorDialog(
                                  context: context,
                                  error: "Family member ID not found",
                                  title: "Error",
                                );
                                return;
                              }

                              // Add +2 prefix to phone number automatically
                              String? finalPhone = phone.isNotEmpty 
                                  ? (phone.startsWith('+2') ? phone : '+2$phone')
                                  : null;
                              
                              context.read<InvitationCubit>().createInvitationFromFamily(
                                    familyMemberId: familyUid,
                                    patientEmail: email.isNotEmpty ? email : null,
                                    patientPhone: finalPhone,
                                  );
                            }
                          },
                    icon: state is InvitationLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: const Text('Continue'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openInviteShareSheet({
    required String name,
    String? phone,
    String? email,
  }) {
    final message = _buildInviteMessage(name);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sms),
              title: const Text('Send via SMS'),
              onTap: () {
                Navigator.pop(context);
                _showSnack('SMS feature coming soon');
              },
            ),
            ListTile(
              leading: Icon(Icons.chat, color: Colors.green.shade700),
              title: const Text('WhatsApp'),
              onTap: () {
                Navigator.pop(context);
                _sendWhatsApp(phone, message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send email'),
              onTap: () {
                Navigator.pop(context);
                if (email != null && email.isNotEmpty) {
                  _sendEmail(
                    email,
                    'Invitation to Join AlzCare',
                    message,
                  );
                } else {
                  _showSnack('Email address is required to send email');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy link'),
              onTap: () {
                Navigator.pop(context);
                if (_currentInvitationLink != null) {
                  Clipboard.setData(ClipboardData(text: _currentInvitationLink!));
                  _showSnack('Link copied to clipboard');
                } else {
                  _showSnack('No invitation link available');
                }
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.tealGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: AppTheme.teal500,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: AppTheme.teal600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Emily Smith',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Daughter & Primary Caregiver',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFCFFAFE),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Caring for Margaret Smith',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Patient Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Patient Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal900,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View Profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.teal50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.teal600,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Margaret Smith',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.teal900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '72 years old',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.gray600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Early Alzheimer\'s Stage',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.teal600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal900,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: '+1 (555) 987-6543',
                      color: AppTheme.teal500,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: 'emily.smith@email.com',
                      color: AppTheme.cyan500,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Doctor Contact Card
            Card(
              color: AppTheme.cyan50,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.cyan500,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doctor Contact',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.teal900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Dr. Sarah Johnson',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.cyan600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.phone,
                        color: AppTheme.cyan600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Invite Patient Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _openInviteDialog,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text(
                  'Invite Patient',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.gray500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.teal900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
