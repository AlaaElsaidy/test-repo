import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:alzcare/config/shared/valdation/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../../config/shared/widgets/custom-text-form.dart';
import '../../../../../config/shared/widgets/field-wrapper.dart';
import '../../../../../config/utilis/app_colors.dart';

class CardInputSection extends StatelessWidget {
  CardInputSection(
      {super.key,
      required this.nameController,
      required this.cardFormEditController,
      required this.onCardChange,
      required this.onChange,
      required this.saveCard});

  TextEditingController nameController;
  CardFormEditController? cardFormEditController;
  Function onCardChange;
  Function onChange;
  bool saveCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(16), vertical: context.h(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.w(22)),
        border: Border.all(color: AppColors.borderColor.withOpacity(.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Cardholder Name",
              style: TextStyle(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E5753))),
          SizedBox(height: context.h(8)),
          FieldWrapper(
            icon: Icons.person_outline_rounded,
            child: CustomTextForm(
              hintText: "Full name",
              textEditingController: nameController,
              validator: (String? v) {
                nameValidator(v);
              },
            ),
          ),
          SizedBox(height: context.h(14)),
          Text("Card Details",
              style: TextStyle(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E5753))),
          SizedBox(height: context.h(8)),
          FieldWrapper(
            icon: Icons.credit_card_rounded,
            showBorder: true,
            child: CardFormField(
              controller: cardFormEditController,
              enablePostalCode: true,
              onCardChanged: (details) {
                onChange(details);
              },
              style: CardFormStyle(
                textColor: const Color(0xFF163E39),
                placeholderColor: const Color(0xFF9ABFBA),
                backgroundColor: Colors.transparent,
                cursorColor: AppColors.primaryColor,
                fontSize: context.sp(15).toInt(),
                borderRadius: 0,
                borderWidth: 0,
                borderColor: Colors.transparent,
                textErrorColor: Colors.red,
              ),
            ),
          ),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              Checkbox(
                value: saveCard,
                onChanged: (v) => onChange(v),
                activeColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.w(6))),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Text(
                "Save card for future payments",
                style: TextStyle(
                    color: const Color(0xFF2E5753),
                    fontWeight: FontWeight.w700,
                    fontSize: context.sp(13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
