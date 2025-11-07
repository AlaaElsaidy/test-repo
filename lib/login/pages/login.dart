import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../config/shared/valdation/validator.dart';
import '../../config/router/routes.dart';
import '../../config/shared/widgets/custom-button.dart';
import '../../config/shared/widgets/custom-text-form.dart';
import '../../config/utilis/app_colors.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -width * 0.25,
            left: -width * 0.15,
            child: _decorCircle(size: width * 0.7),
          ),
          Positioned(
            bottom: -width * 0.3,
            right: -width * 0.2,
            child: _decorCircle(size: width * 0.9),
          ),

          // Content
          SafeArea(
            child: Column(
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
                        color: AppColors.borderColor.withOpacity(.5),
                      ),
                      borderRadius: BorderRadius.circular(context.w(22)),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          _fieldWrapper(
                            context,
                            icon: Icons.email_outlined,
                            child: CustomTextForm(
                              maxLength: 40,
                              textEditingController: _emailController,
                              validator: (v) => emailValidator(v),
                              hintText: "example@mail.com",
                              textInputType: TextInputType.emailAddress,
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
                          _fieldWrapper(
                            context,
                            icon: Icons.lock_outline_rounded,
                            child: CustomTextForm(
                              textEditingController: _passwordController,
                              validator: (v) => passwordValidator(v),
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
                                  setState(() => _rememberMe = val ?? false);
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                activeColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
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
                                      MaterialTapTargetSize.shrinkWrap,
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
                              onClick: () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.home,
                                    (route) => false,
                                  );
                                }
                              },
                              text: "Login",
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
          ),
        ],
      ),
    );
  }

  // Decorative circle widget
  Widget _decorCircle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.20),
            const Color(0xFF06B6D4).withOpacity(0.20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.10),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }

  // Wrapper for input fields with icon and decoration
  Widget _fieldWrapper(
    BuildContext context, {
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FEFD),
        borderRadius: BorderRadius.circular(context.w(16)),
        border: Border.all(color: const Color(0xFFE6F1EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.w(10)),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: context.sp(18),
              color: AppColors.tealDark,
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(child: child),
        ],
      ),
    );
  }
}
