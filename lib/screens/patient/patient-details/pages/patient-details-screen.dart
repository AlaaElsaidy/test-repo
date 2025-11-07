import 'dart:io';
import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/router/routes.dart';
import '../../../../config/shared/valdation/validator.dart';
import '../../../../config/shared/widgets/custom-button.dart';
import '../../../../config/shared/widgets/custom-text-form.dart';
import '../../../../config/utilis/app_colors.dart';
import '../widgets/date-time-widget.dart';
import '../widgets/gender-drop-down.dart';
import '../widgets/top-details-widget.dart';

class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({Key? key}) : super(key: key);

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? imageFile;
  String _selectedGender = 'Male';
  DateTime dateTime = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: -width * 0.25,
            left: -width * 0.15,
            child: _decorCircle(size: width * 0.7),
          ),
          Positioned(
            bottom: -width * 0.30,
            right: -width * 0.20,
            child: _decorCircle(size: width * 0.9),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: context.w(18)).copyWith(
                top: context.h(16),
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + context.h(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top profile area (avatar picker)
                  TopDetailsWidget(
                    onTap: () async {
                      final picked =
                          await pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => imageFile = picked);
                      }
                    },
                    imageFile: imageFile,
                  ),

                  SizedBox(height: context.h(14)),

                  // Form card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(18),
                      vertical: context.h(20),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.w(22)),
                      border: Border.all(
                          color: AppColors.borderColor.withOpacity(.5)),
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
                            'Basic Information',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: context.sp(16),
                              color: const Color(0xFF0E3E3B),
                            ),
                          ),
                          SizedBox(height: context.h(16)),

                          // Name
                          Text(
                            'Full Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.sp(14),
                              color: const Color(0xFF2E5753),
                            ),
                          ),
                          SizedBox(height: context.h(8)),
                          _fieldWrapper(
                            context,
                            icon: Icons.person_outline_rounded,
                            child: CustomTextForm(
                              textEditingController: _nameController,
                              validator: (v) => nameValidator(v),
                              hintText: "Enter your name",
                              textInputType: TextInputType.name,
                            ),
                          ),

                          SizedBox(height: context.h(14)),

                          // Row: Date of birth + Gender (same look/feel)
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: dateTime,
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                      builder: (context, child) => Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: AppColors.primaryColor,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black,
                                          ),
                                          dialogBackgroundColor: Colors.white,
                                        ),
                                        child: child!,
                                      ),
                                    );
                                    if (picked != null) {
                                      setState(() => dateTime = picked);
                                    }
                                  },
                                  child: _tileWrapper(
                                    context,
                                    child: DateTimeWidget(dateTime: dateTime),
                                  ),
                                ),
                              ),
                              SizedBox(width: context.w(10)),
                              Expanded(
                                child: _tileWrapper(
                                  context,
                                  child: GenderDropDown(
                                    selectedGender: _selectedGender,
                                    onChange: (String? value) {
                                      if (value != null) {
                                        setState(() => _selectedGender = value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: context.h(14)),

                          // Phone
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.sp(14),
                              color: const Color(0xFF2E5753),
                            ),
                          ),
                          SizedBox(height: context.h(8)),
                          _fieldWrapper(
                            context,
                            icon: Icons.phone_outlined,
                            child: CustomTextForm(
                              textEditingController: _phoneController,
                              validator: _phoneValidatorLocal,
                              hintText: "Enter your phone number",
                              textInputType: TextInputType.phone,
                            ),
                          ),

                          SizedBox(height: context.h(18)),

                          // Home Location
                          Text(
                            'Home Location',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.sp(16),
                              color: const Color(0xFF0E3E3B),
                            ),
                          ),
                          SizedBox(height: context.h(8)),
                          _tileWrapper(
                            context,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primaryColor.withOpacity(.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                SizedBox(width: context.w(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Set your home location',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: context.sp(14),
                                          color: const Color(0xFF163E39),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Choose on map (optional)',
                                        style: TextStyle(
                                          fontSize: context.sp(12),
                                          color: const Color(0xFF7EA9A3),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    // TODO: Navigate to map picker
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: AppColors.primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.w(12),
                                      vertical: context.h(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Pick',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: context.h(22)),

                          // Next button
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              onClick: () {
                                FocusScope.of(context).unfocus();
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pushNamed(
                                      context, AppRoutes.service);
                                }
                              },
                              text: "Next",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: context.h(20)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Local phone validator (لو ما عندك واحد جاهز في validator.dart)
  String? _phoneValidatorLocal(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
    final digits = v.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 7 || digits.length > 15)
      return 'Enter a valid phone number';
    return null;
  }

  // Decorative circle (same style used on login/signup)
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

  // Generic tile wrapper (for date/gender/location blocks)
  Widget _tileWrapper(BuildContext context, {required Widget child}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(12),
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
      child: child,
    );
  }

  // Input field wrapper (same as login/signup)
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

  Future<File?> pickImage({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }
}
