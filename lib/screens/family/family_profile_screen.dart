import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/shared/widgets/error-dialoge.dart';
import '../../core/models/invitation-model.dart';
import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../core/supabase/auth-service.dart';
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
  String? _currentInvitationCode;
  String? _currentInvitationLink;
  late final InvitationCubit _invitationsCubit;
  List<InvitationModel> _sentInvitations = [];
  bool _isFetchingInvites = false;
  String? _invitesError;

  @override
  void initState() {
    super.initState();
    _invitationsCubit = InvitationCubit(
      InvitationRepo(
        InvitationService(),
        PatientFamilyService(),
        UserService(),
        AuthService(),
        PatientService(),
      ),
    );
    _loadInvitations();
  }

  @override
  void dispose() {
    _invitationsCubit.close();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _buildInviteMessage(String name) {
    final code = _currentInvitationCode ?? '';
    final deepLink =
        _currentInvitationLink ?? (code.isNotEmpty ? 'alzcare://invite?code=$code' : 'alzcare://invite');

    final friendlyName = name.isEmpty ? '' : '$name, ';

    return 'Hi ${friendlyName}you have been invited to join as a patient.\n'
        'Invitation code: $code\n'
        'Tap this link after installing the app: $deepLink\n'
        'If the link does not open the app, open AlzCare manually, go to “Accept Invitation”, and enter the code above.';
  }

  Future<void> _loadInvitations() async {
    final familyUid =
        SharedPrefsHelper.getString("familyUid") ?? SharedPrefsHelper.getString("userId");

    if (familyUid == null) {
      setState(() {
        _invitesError = "Family member ID not found";
        _isFetchingInvites = false;
      });
      return;
    }

    setState(() {
      _isFetchingInvites = true;
      _invitesError = null;
    });

    await _invitationsCubit.getInvitationsByFamilyMember(familyUid);
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
            AuthService(),
            PatientService(),
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
              _currentInvitationCode = state.invitation.invitationCode;
              _currentInvitationLink =
                  'alzcare://invite?code=${state.invitation.invitationCode}';
              Navigator.pop(ctx);
              _openInviteShareSheet(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
              );
              _loadInvitations();
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
                            labelText: 'Email *',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegex.hasMatch(v.trim())) {
                              return 'Invalid email';
                            }
                            return null;
                          },
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
                              final name = nameCtrl.text.trim();

                              if (email.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Email is required'),
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
                                    patientEmail: email,
                                    patientPhone: finalPhone,
                                    patientName: name,
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
                final code = _currentInvitationCode;
                final link = _currentInvitationLink;

                if (code == null || code.isEmpty || link == null) {
                  _showSnack('No invitation data available');
                  return;
                }

                Clipboard.setData(
                  ClipboardData(
                    text:
                        'Invitation code: $code\nOpen after installing the app: $link',
                  ),
                );
                _showSnack('Invitation info copied');
              },
            ),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Copy code only'),
              onTap: () {
                Navigator.pop(context);
                if (_currentInvitationCode == null ||
                    _currentInvitationCode!.isEmpty) {
                  _showSnack('No invitation code available');
                  return;
                }
                Clipboard.setData(
                  ClipboardData(text: _currentInvitationCode!),
                );
                _showSnack('Code copied');
              },
            ),
            ListTile(
              leading: Icon(Icons.chat_bubble_outline, color: Colors.green.shade700),
              title: const Text('Send code via WhatsApp'),
              onTap: () {
                Navigator.pop(context);
                if (_currentInvitationCode == null ||
                    _currentInvitationCode!.isEmpty) {
                  _showSnack('No invitation code available');
                  return;
                }
                final codeMessage = 'Invitation code: ${_currentInvitationCode!}';
                _sendWhatsApp(phone, codeMessage);
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationsCard() {
    Widget content;

    if (_isFetchingInvites) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_invitesError != null) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _invitesError!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadInvitations,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_sentInvitations.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No invitations sent yet.',
              style: TextStyle(color: AppTheme.gray600),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openInviteDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Invite a patient'),
            ),
          ],
        ),
      );
    } else {
      content = Column(
        children: List.generate(_sentInvitations.length, (index) {
          final invite = _sentInvitations[index];
          final initials = _codeInitials(invite.invitationCode);
          final statusColor = _statusColor(invite.status);

          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.teal50,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppTheme.teal600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(invite.patientEmail ?? invite.patientPhone ?? 'Patient'),
                subtitle: Text('Code: ${invite.invitationCode}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        invite.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invite.createdAt.toLocal().toString().split(' ').first}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.gray500),
                    ),
                  ],
                ),
              ),
              if (index != _sentInvitations.length - 1)
                const Divider(height: 24, thickness: 0.5),
            ],
          );
        }),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Invitations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.teal900,
                  ),
                ),
                IconButton(
                  onPressed: _loadInvitations,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                )
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return AppTheme.teal600;
    }
  }

  String _codeInitials(String code) {
    if (code.isEmpty) return '--';
    return code.length <= 2 ? code : code.substring(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _invitationsCubit,
      child: BlocListener<InvitationCubit, InvitationState>(
        listener: (context, state) {
          if (state is InvitationsListSuccess) {
            setState(() {
              _sentInvitations = state.invitations;
              _isFetchingInvites = false;
              _invitesError = null;
            });
          } else if (state is InvitationFailure && _isFetchingInvites) {
            setState(() {
              _invitesError = state.errorMessage;
              _isFetchingInvites = false;
            });
          }
        },
        child: SafeArea(
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
            _buildInvitationsCard(),
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
