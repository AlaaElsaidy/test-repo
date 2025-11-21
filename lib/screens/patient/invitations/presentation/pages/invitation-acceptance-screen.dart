import 'package:alzcare/config/router/routes.dart';
import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:alzcare/config/shared/widgets/error-dialoge.dart';
import 'package:alzcare/config/shared/widgets/loading.dart';
import 'package:alzcare/config/shared/widgets/custom-button.dart';
import 'package:alzcare/core/models/invitation-model.dart';
import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/auth-service.dart';
import 'package:alzcare/core/supabase/invitation-service.dart';
import 'package:alzcare/core/supabase/patient-family-service.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:alzcare/screens/patient/invitations/data/invitation-repo.dart';
import 'package:alzcare/screens/patient/invitations/presentation/cubit/invitation_cubit.dart';
import 'package:alzcare/screens/patient/invitations/presentation/cubit/invitation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alzcare/config/utilis/app_colors.dart';

class InvitationAcceptanceScreen extends StatefulWidget {
  final String? invitationCode;

  const InvitationAcceptanceScreen({
    super.key,
    this.invitationCode,
  });

  @override
  State<InvitationAcceptanceScreen> createState() => _InvitationAcceptanceScreenState();
}

class _InvitationAcceptanceScreenState extends State<InvitationAcceptanceScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFallbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  InvitationModel? _invitationDetails;
  String? _patientUid;
  bool _isCreatingAccount = false;
  bool _isFetchingInvite = false;
  late final InvitationCubit _invitationCubit;

  @override
  void initState() {
    super.initState();
    _invitationCubit = InvitationCubit(
      InvitationRepo(
        InvitationService(),
        PatientFamilyService(),
        UserService(),
        AuthService(),
        PatientService(),
      ),
    );
    if (widget.invitationCode != null) {
      _codeController.text = widget.invitationCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchInvitation(widget.invitationCode!);
      });
    }
    _patientUid = SharedPrefsHelper.getString("patientUid");
  }

  @override
  void dispose() {
    _invitationCubit.close();
    _codeController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFallbackController.dispose();
    super.dispose();
  }

  void _fetchInvitation(String code) {
    setState(() {
      _isFetchingInvite = true;
    });
    _invitationCubit.getInvitationByCode(code);
  }

  Future<void> _createPatientAccount() async {
    final invitation = _invitationDetails;
    if (invitation == null) {
      showErrorDialog(
        context: context,
        error: "Please fetch the invitation details first.",
        title: "Missing Invitation",
      );
      return;
    }

    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final email = invitation.patientEmail ?? _emailFallbackController.text.trim();

    if (name.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showErrorDialog(
        context: context,
        error: "Name and password are required.",
        title: "Incomplete Form",
      );
      return;
    }

    if (password != confirmPassword) {
      showErrorDialog(
        context: context,
        error: "Passwords do not match.",
        title: "Password Error",
      );
      return;
    }

    if (email.isEmpty) {
      showErrorDialog(
        context: context,
        error: "This invitation does not include an email. Please enter one.",
        title: "Email Required",
      );
      return;
    }

    setState(() => _isCreatingAccount = true);
    final authService = AuthService();
    final patientService = PatientService();

    try {
      final response = await authService.signUp(
        email: email,
        password: password,
        name: name,
        role: 'patient',
      );

      final user = response.user;
      if (user == null) {
        throw Exception("Unable to create account. Please try again.");
      }

      await SharedPrefsHelper.saveString("patientUid", user.id);
      await SharedPrefsHelper.saveString("userId", user.id);

      await patientService.addPatient(
        patientId: user.id,
        age: 0,
        name: name,
        gender: 'Male',
      );

      setState(() {
        _patientUid = user.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! You can now accept the invitation.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      showErrorDialog(
        context: context,
        error: e.toString(),
        title: "Account Creation Failed",
      );
    } finally {
      setState(() => _isCreatingAccount = false);
    }
  }

  Future<void> _handleAcceptInvitation() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _codeController.text.trim().toUpperCase();
    final patientUid = _patientUid;

    if (patientUid == null) {
      showErrorDialog(
        context: context,
        error:
            "No patient account detected. Please create your account from this invitation before accepting.",
        title: "Account Required",
      );
      return;
    }

    await _invitationCubit.acceptInvitation(
          invitationCode: code,
          patientId: patientUid,
        );
  }

  Future<void> _handleRejectInvitation() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      showErrorDialog(
        context: context,
        error: "Please enter invitation code",
        title: "Error",
      );
      return;
    }
    await _invitationCubit.rejectInvitation(code);
  }

  Widget _buildInvitationDetails() {
    final invitation = _invitationDetails;
    if (invitation == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.only(top: context.h(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invitation Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Status', value: invitation.status),
            _DetailRow(
              label: 'Family Member ID',
              value: invitation.familyMemberId ?? 'Not provided',
            ),
            _DetailRow(
              label: 'Email',
              value: invitation.patientEmail ??
                  (_patientUid != null ? 'Linked to your account' : 'Not provided'),
            ),
            _DetailRow(
              label: 'Phone',
              value: invitation.patientPhone ?? 'Not provided',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  invitation.isExpired ? Icons.warning : Icons.pending,
                  color: invitation.isExpired ? Colors.red : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    invitation.isExpired
                        ? 'This invitation has expired. Ask your family member to send a new one.'
                        : 'This invitation expires on ${invitation.expiresAt.toLocal().toString().split(" ").first}.',
                    style: TextStyle(
                      color: invitation.isExpired ? Colors.red : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCreationForm() {
    if (_patientUid != null) return const SizedBox.shrink();
    if (_invitationDetails == null) {
      return Padding(
        padding: EdgeInsets.only(top: context.h(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Need an account?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Fetch invitation details first to start account creation.'),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.only(top: context.h(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Patient Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete the fields below to set up your patient account before accepting the invitation.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            if (_invitationDetails?.patientEmail == null)
              TextField(
                controller: _emailFallbackController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              )
            else
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email),
                  hintText: _invitationDetails!.patientEmail,
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreatingAccount ? null : _createPatientAccount,
                icon: _isCreatingAccount
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add),
                label: Text(
                  _isCreatingAccount ? 'Creating account...' : 'Create Account',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _invitationCubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Accept Invitation',
            style: TextStyle(
              color: const Color(0xFF0E3E3B),
              fontWeight: FontWeight.w700,
              fontSize: context.sp(20),
            ),
          ),
        ),
        body: BlocListener<InvitationCubit, InvitationState>(
          listener: (context, state) {
            if (state is InvitationFailure) {
              showErrorDialog(
                context: context,
                error: state.errorMessage,
                title: "Error",
              );
              if (_isFetchingInvite) {
                setState(() => _isFetchingInvite = false);
              }
            } else if (state is InvitationAccepted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invitation accepted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.patientMain,
                (route) => false,
              );
            } else if (state is InvitationRejected) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invitation rejected'),
                  backgroundColor: Colors.orange,
                ),
              );
              Navigator.pop(context);
            } else if (state is InvitationSuccess) {
              setState(() {
                _invitationDetails = state.invitation;
                _isFetchingInvite = false;
              });
            }
          },
          child: BlocBuilder<InvitationCubit, InvitationState>(
            builder: (context, state) {
              if (state is InvitationLoading) {
                return const Center(child: LoadingPage());
              }

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.w(18)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: context.h(40)),
                      Text(
                        'Enter Invitation Code',
                        style: TextStyle(
                          fontSize: context.sp(24),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0E3E3B),
                        ),
                      ),
                      SizedBox(height: context.h(8)),
                      Text(
                        'Please enter the invitation code you received',
                        style: TextStyle(
                          fontSize: context.sp(14),
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: context.h(32)),
                      TextFormField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: 'Invitation Code',
                          hintText: 'Enter code',
                          prefixIcon: const Icon(Icons.vpn_key),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter invitation code';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: context.h(16)),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isFetchingInvite
                              ? null
                              : () {
                                  final code = _codeController.text.trim();
                                  if (code.isEmpty) {
                                    showErrorDialog(
                                      context: context,
                                      error: "Please enter invitation code first",
                                      title: "Missing code",
                                    );
                                    return;
                                  }
                                  _fetchInvitation(code.toUpperCase());
                                },
                          icon: _isFetchingInvite
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: Text(
                            _isFetchingInvite ? 'Looking up...' : 'Fetch Invitation Details',
                          ),
                        ),
                      ),
                      _buildInvitationDetails(),
                      _buildAccountCreationForm(),
                      SizedBox(height: context.h(32)),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          onClick: _handleAcceptInvitation,
                          text: "Accept Invitation",
                        ),
                      ),
                      SizedBox(height: context.h(16)),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _handleRejectInvitation,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: context.h(16)),
                            side: BorderSide(color: AppColors.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Reject",
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: context.sp(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
