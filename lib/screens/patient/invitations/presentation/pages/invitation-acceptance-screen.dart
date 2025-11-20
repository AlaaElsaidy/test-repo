import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:alzcare/config/shared/widgets/error-dialoge.dart';
import 'package:alzcare/config/shared/widgets/loading.dart';
import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/invitation-service.dart';
import 'package:alzcare/core/supabase/patient-family-service.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:alzcare/screens/patient/invitations/data/invitation-repo.dart';
import 'package:alzcare/screens/patient/invitations/presentation/cubit/invitation_cubit.dart';
import 'package:alzcare/screens/patient/invitations/presentation/cubit/invitation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/router/routes.dart';
import '../../../../../config/shared/widgets/custom-button.dart';
import '../../../../../config/shared/widgets/custom-text-form.dart';
import '../../../../../config/shared/widgets/field-wrapper.dart';
import '../../../../../config/utilis/app_colors.dart';

class InvitationAcceptanceScreen extends StatefulWidget {
  final String? invitationCode;

  const InvitationAcceptanceScreen({
    super.key,
    this.invitationCode,
  });

  @override
  State<InvitationAcceptanceScreen> createState() =>
      _InvitationAcceptanceScreenState();
}

class _InvitationAcceptanceScreenState
    extends State<InvitationAcceptanceScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.invitationCode != null) {
      _codeController.text = widget.invitationCode!;
      // Auto-load invitation if code provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<InvitationCubit>().getInvitationByCode(widget.invitationCode!);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InvitationCubit(
        InvitationRepo(
          InvitationService(),
          PatientFamilyService(),
          UserService(),
        ),
      ),
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
                          color: const Color(0xFF0E3E3B),
                          fontWeight: FontWeight.w700,
                          fontSize: context.sp(24),
                        ),
                      ),
                      SizedBox(height: context.h(8)),
                      Text(
                        'Enter the invitation code you received to link with a family member',
                        style: TextStyle(
                          color: const Color(0xFF7EA9A3),
                          fontSize: context.sp(14),
                        ),
                      ),
                      SizedBox(height: context.h(40)),
                      FieldWrapper(
                        icon: Icons.vpn_key_outlined,
                        child: CustomTextForm(
                          textEditingController: _codeController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Invitation code is required';
                            }
                            if (v.trim().length < 6) {
                              return 'Invalid invitation code';
                            }
                            return null;
                          },
                          hintText: "Enter invitation code",
                          textInputType: TextInputType.text,
                        ),
                      ),
                      SizedBox(height: context.h(24)),
                      if (state is InvitationSuccess) ...[
                        Container(
                          padding: EdgeInsets.all(context.w(16)),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primaryColor,
                                    size: 20,
                                  ),
                                  SizedBox(width: context.w(8)),
                                  Text(
                                    'Invitation Found',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: context.sp(16),
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.h(12)),
                              Text(
                                'Status: ${state.invitation.status}',
                                style: TextStyle(
                                  fontSize: context.sp(14),
                                  color: const Color(0xFF2E5753),
                                ),
                              ),
                              if (state.invitation.isExpired)
                                Padding(
                                  padding: EdgeInsets.only(top: context.h(8)),
                                  child: Text(
                                    'This invitation has expired',
                                    style: TextStyle(
                                      fontSize: context.sp(12),
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: context.h(24)),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          onClick: () async {
                            if (_formKey.currentState!.validate()) {
                              final code = _codeController.text.trim().toUpperCase();
                              final patientUid = SharedPrefsHelper.getString("patientUid");
                              
                              if (patientUid == null) {
                                showErrorDialog(
                                  context: context,
                                  error: "Patient ID not found. Please login as a patient first.",
                                  title: "Error",
                                );
                                return;
                              }

                              await context.read<InvitationCubit>().acceptInvitation(
                                    invitationCode: code,
                                    patientId: patientUid,
                                  );
                            }
                          },
                          text: "Accept Invitation",
                        ),
                      ),
                      SizedBox(height: context.h(16)),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            final code = _codeController.text.trim().toUpperCase();
                            if (code.isEmpty) {
                              showErrorDialog(
                                context: context,
                                error: "Please enter invitation code",
                                title: "Error",
                              );
                              return;
                            }
                            await context.read<InvitationCubit>().rejectInvitation(code);
                          },
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

