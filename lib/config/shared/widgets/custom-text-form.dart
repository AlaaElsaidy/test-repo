import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utilis/app_colors.dart';

class CustomTextForm extends StatelessWidget {
  CustomTextForm(
      {super.key,
      this.hintText,
      this.textInputType,
      this.secure = false,
      this.suffix,
      this.onChange,
      required this.textEditingController,
      required this.validator,
      this.maxLength,
      this.hintTextColor,
      this.hintTextSize,
      this.hintTextWeight});

  String? hintText;
  Color? hintTextColor;
  double? hintTextSize;
  FontWeight? hintTextWeight;
  TextInputType? textInputType;
  bool secure;
  TextEditingController textEditingController;
  String? Function(String?) validator;
  Widget? suffix;
  void Function(String)? onChange;
  int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: validator,
      style: TextStyle(
          fontWeight: hintTextWeight,
          fontSize: hintTextSize,
          color: hintTextColor),
      maxLength: maxLength,
      onChanged: onChange,
      controller: textEditingController,
      keyboardType: textInputType ?? TextInputType.text,
      obscureText: secure,
      cursorColor: AppColors.primaryColor,
      decoration: InputDecoration(
        counterText: '',
        suffix: suffix,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(20),
          vertical: context.h(20),
        ),
        filled: true,
        fillColor: AppColors.filledColor,
        hintText: hintText ?? "",
        hintStyle: GoogleFonts.openSans(
            color: hintTextColor ?? AppColors.darkGrey,
            fontSize: hintTextSize ?? context.sp(16),
            fontWeight: hintTextWeight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.w(10)),
          borderSide: BorderSide(
            color: AppColors.borderColor,
            width: context.w(1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.w(10)),
          borderSide: BorderSide(
            color: AppColors.borderColor,
            width: context.w(1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.w(10)),
          borderSide: BorderSide(
            color: AppColors.primaryColor,
            width: context.w(1),
          ),
        ),
      ),
    );
  }
}
