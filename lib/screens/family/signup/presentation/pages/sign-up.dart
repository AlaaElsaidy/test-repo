import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:alzcare/config/shared/widgets/error-dialoge.dart';
import 'package:alzcare/config/shared/widgets/loading.dart';
import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/auth-service.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/router/routes.dart';
import '../../../../../config/shared/valdation/validator.dart';
import '../../../../../config/shared/widgets/custom-button.dart';
import '../../../../../config/shared/widgets/custom-text-form.dart';
import '../../../../../config/shared/widgets/decore-circle.dart';
import '../../../../../config/shared/widgets/field-wrapper.dart';
import '../../../../../config/utilis/app_colors.dart';
import '../../bloc/sign_up_cubit.dart';
import '../../data/family-model.dart';
import '../../data/signup-repo.dart';
import '../../data/userModel.dart';
import '../widgets/sign-in-link.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: -width * 0.25,
            left: -width * 0.15,
            child: DecorCircle(size: width * 0.7),
          ),
          Positioned(
            bottom: -width * 0.3,
            right: -width * 0.2,
            child: DecorCircle(size: width * 0.9),
          ),

          // Content
          SafeArea(
            child: BlocProvider(
              create: (context) =>
                  SignUpCubit(SignUpRepo(AuthService(), FamilyMemberService())),
              child: BlocListener<SignUpCubit, SignUpState>(
                listener: (context, state) async {
                  if (state is SignUpSuccess) {
                    await SharedPrefsHelper.saveString(
                        "familyUid", state.authResponse.user!.id);
                    FamilyMemberModel familyMemberModel = FamilyMemberModel(
                        id: state.authResponse.user!.id,
                        name: _nameController.text,
                        email: _emailController.text);
                    await BlocProvider.of<SignUpCubit>(context)
                        .addFamily(familyMemberModel);
                  } else if (state is SignUpFailure) {
                    showErrorDialog(
                        context: context,
                        error: state.errorMessage,
                        title: "Register Failed");
                  }
                  if (state is AddFamilySuccess) {
                    Navigator.pushReplacementNamed(
                        context, AppRoutes.doctorSelection);
                  }
                  if (state is AddFamilyFailure) {
                    showErrorDialog(
                        context: context,
                        error: state.errorMessage,
                        title: "Register Failed");
                  }
                },
                child: BlocBuilder<SignUpCubit, SignUpState>(
                  builder: (context, state) {
                    return Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: context.h(16)),
                            Text(
                              'Create Account',
                              style: TextStyle(
                                color: const Color(0xFF0E3E3B),
                                fontWeight: FontWeight.w800,
                                fontSize: context.sp(28),
                              ),
                            ),
                            SizedBox(height: context.h(6)),
                            Text(
                              'Sign up with your email',
                              style: TextStyle(
                                color: const Color(0xFF7EA9A3),
                                fontWeight: FontWeight.w600,
                                fontSize: context.sp(14),
                              ),
                            ),
                            SizedBox(height: context.h(28)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(18),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(18),
                                  vertical: context.h(20),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        AppColors.borderColor.withOpacity(.5),
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(context.w(22)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  autovalidateMode: AutovalidateMode.onUnfocus,
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Account Information',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: context.sp(18),
                                          color: const Color(0xFF0E3E3B),
                                          letterSpacing: context.sp(-0.3),
                                        ),
                                      ),
                                      SizedBox(height: context.h(18)),

                                      // Full Name
                                      Text(
                                        'Full Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.sp(14),
                                          color: const Color(0xFF2E5753),
                                        ),
                                      ),
                                      SizedBox(height: context.h(8)),
                                      FieldWrapper(
                                        icon: Icons.person_outline_rounded,
                                        child: CustomTextForm(
                                          textEditingController:
                                              _nameController,
                                          validator: (v) => nameValidator(v),
                                          hintText: "Enter your name",
                                          textInputType: TextInputType.name,
                                        ),
                                      ),

                                      SizedBox(height: context.h(16)),

                                      Text(
                                        'Email Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.sp(14),
                                          color: const Color(0xFF2E5753),
                                        ),
                                      ),
                                      SizedBox(height: context.h(8)),
                                      FieldWrapper(
                                        icon: Icons.email_outlined,
                                        child: CustomTextForm(
                                          maxLength: 40,
                                          textEditingController:
                                              _emailController,
                                          validator: (v) => emailValidator(v),
                                          hintText: "example@mail.com",
                                          textInputType:
                                              TextInputType.emailAddress,
                                        ),
                                      ),

                                      SizedBox(height: context.h(16)),

                                      Text(
                                        'Password',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.sp(14),
                                          color: const Color(0xFF2E5753),
                                        ),
                                      ),
                                      SizedBox(height: context.h(8)),
                                      FieldWrapper(
                                        icon: Icons.lock_outline_rounded,
                                        child: CustomTextForm(
                                          textEditingController:
                                              _passwordController,
                                          validator: (v) =>
                                              passwordValidator(v),
                                          hintText: "Enter your password",
                                          textInputType: TextInputType.text,
                                          secure: true,
                                        ),
                                      ),

                                      SizedBox(height: context.h(16)),

                                      Text(
                                        'Confirm Password',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.sp(14),
                                          color: const Color(0xFF2E5753),
                                        ),
                                      ),
                                      SizedBox(height: context.h(8)),
                                      FieldWrapper(
                                        icon: Icons.lock_reset_rounded,
                                        child: CustomTextForm(
                                          textEditingController:
                                              _confirmPasswordController,
                                          validator: (v) =>
                                              confirmPasswordValidator(
                                            v,
                                            _passwordController.text,
                                          ),
                                          hintText: "Re-enter your password",
                                          textInputType: TextInputType.text,
                                          secure: true,
                                        ),
                                      ),

                                      SizedBox(height: context.h(22)),

                                      SizedBox(
                                        width: double.infinity,
                                        child: CustomButton(
                                          onClick: () {
                                            FocusScope.of(context).unfocus();
                                            if (_formKey.currentState!
                                                .validate()) {
                                              UserModel userModel = UserModel(
                                                  email: _emailController.text,
                                                  name: _nameController.text);
                                              BlocProvider.of<SignUpCubit>(
                                                      context)
                                                  .signUp(userModel,
                                                      _passwordController.text);
                                            }
                                          },
                                          text: state is SignUpLoading ||
                                                  state is AddFamilyLoading
                                              ? "Loading..."
                                              : "Signup",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: context.h(16)),
                            // Already have an account? Sign in
                            buildSignInLink(context),
                            SizedBox(height: context.h(8)),
                          ],
                        ),
                        if (state is SignUpLoading || state is AddFamilyLoading)
                          Positioned.fill(
                            child: AbsorbPointer(
                              absorbing: true,
                              child: Container(
                                color: Colors.black.withOpacity(0.1),
                                child: const Center(child: LoadingPage()),
                              ),
                            ),
                          )
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
