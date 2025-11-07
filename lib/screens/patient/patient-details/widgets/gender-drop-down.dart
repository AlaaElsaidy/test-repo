import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../../config/utilis/app_colors.dart';

class GenderDropDown extends StatelessWidget {
  GenderDropDown({
    super.key,
    required this.selectedGender,
    required this.onChange,
  });

  String selectedGender;
  void Function(String?) onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.w(20)),
      decoration: BoxDecoration(
        color: AppColors.filledColor,
        borderRadius: BorderRadius.circular(context.w(10)),
        border: Border.all(color: AppColors.borderColor, width: context.w(1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedGender,
          dropdownColor: Colors.white,
          isExpanded: true,
          style: TextStyle(
            fontSize: context.sp(14),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.lightGray,
            size: context.w(24),
          ),
          items: ['Male', 'Female'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }
}
