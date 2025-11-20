import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/auth-service.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:alzcare/login/data/login%20repo.dart';
import 'package:alzcare/login/presentation/cubit/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/router/routes.dart';
import '../../../config/shared/valdation/validator.dart';
import '../../../config/shared/widgets/custom-button.dart';
import '../../../config/shared/widgets/custom-text-form.dart';
import '../../../config/shared/widgets/decore-circle.dart';
import '../../../config/shared/widgets/error-dialoge.dart';
import '../../../config/shared/widgets/field-wrapper.dart';
import '../../../config/shared/widgets/loading.dart';
import '../../../config/utilis/app_colors.dart';
import '../../../screens/family/signup/data/userModel.dart';
import '../widgets/sign-up-link.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (context) => LoginCubit(LoginRepo(AuthService(), UserService())),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: BlocListener<LoginCubit, LoginState>(
          listener: (context, state) async {
            if (state is LoginFailure) {
              showErrorDialog(
                  context: context,
                  error: state.errorMessage,
                  title: "Login Failed!");
            }
            if (state is LoginSuccess) {
              print(state.authResponse.user!.id);
              await SharedPrefsHelper.saveString(
                  "userId", state.authResponse.user!.id);
              await BlocProvider.of<LoginCubit>(context)
                  .getUser(userId: state.authResponse.user!.id);
            }
            if (state is GetUserFailure) {
              showErrorDialog(
                  context: context,
                  error: state.errorMessage,
                  title: "Login Failed!");
            }
            if (state is GetUserSuccess) {
              var user = UserModel.fromJson(state.user!);
              if (user.role == "patient") {
                await SharedPrefsHelper.saveString(
                    "patientUid", state.user!['id']);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.patientDetails,
                  (route) => false,
                );
              } else if (user.role == "family") {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.familyMain,
                  (route) => false,
                );
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.doctorMain,
                  (route) => false,
                );
              }
            }
          },
          child: BlocBuilder<LoginCubit, LoginState>(
            builder: (context, state) {
              return Stack(
                children: [
                  // Decorative circles
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
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: context.h(16)),
                            Text(
                              'Welcome Back!',
                              style: TextStyle(
                                color: const Color(0xFF0E3E3B),
                                fontWeight: FontWeight.w800,
                                fontSize: context.sp(28),
                              ),
                            ),
                            SizedBox(height: context.h(6)),
                            Text(
                              'Sign in with your email',
                              style: TextStyle(
                                color: const Color(0xFF7EA9A3),
                                fontWeight: FontWeight.w600,
                                fontSize: context.sp(14),
                              ),
                            ),
                            SizedBox(height: context.h(50)),

                            // Card with form
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
                                  key: _formKey,
                                  autovalidateMode: AutovalidateMode.onUnfocus,
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

                                      // Email
                                      Text(
                                        'Email Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.sp(14),
                                          color: const Color(0xFF2E5753),
                                          letterSpacing: context.sp(-0.2),
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

                                      // Password
                                      Text(
                                        'Password',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.sp(14),
                                          color: const Color(0xFF2E5753),
                                          letterSpacing: context.sp(-0.2),
                                        ),
                                      ),
                                      SizedBox(height: context.h(8)),
                                      FieldWrapper(
                                        icon: Icons.lock_outline_rounded,
                                        child: CustomTextForm(
                                          textEditingController:
                                              _passwordController,
                                          // No validation on login password for now
                                          validator: (_) => null,
                                          hintText: "••••••••",
                                          textInputType: TextInputType.text,
                                          secure: true,
                                        ),
                                      ),

                                      SizedBox(height: context.h(12)),

                                      // Remember + Forgot password
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (val) {
                                              setState(() =>
                                                  _rememberMe = val ?? false);
                                            },
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            activeColor: AppColors.primaryColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                context.w(6),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Remember me',
                                            style: TextStyle(
                                              color: const Color(0xFF2E5753),
                                              fontSize: context.sp(14),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () {
                                              // TODO: go to forget password page
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              'Forgot password?',
                                              style: TextStyle(
                                                color: AppColors.primaryColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: context.sp(14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: context.h(12)),

                                      // Login button
                                      SizedBox(
                                        width: double.infinity,
                                        child: CustomButton(
                                          onClick: () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              await BlocProvider.of<LoginCubit>(
                                                      context)
                                                  .login(
                                                      email:
                                                          _emailController.text,
                                                      password:
                                                          _passwordController
                                                              .text);
                                            }
                                          },
                                          text: state is GetUserLoading ||
                                                  state is LoginLoading
                                              ? "Loading..."
                                              : "Login",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: context.h(16)),
                            buildSignUpLink(context),
                            SizedBox(height: context.h(8)),
                          ],
                        ),
                        if (state is GetUserLoading || state is LoginLoading?)
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
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
