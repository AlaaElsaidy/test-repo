import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../../config/router/routes.dart';
import '../../../../config/shared/widgets/custom-button.dart';
import '../../../../config/shared/widgets/custom-text-form.dart';
import '../../../../config/utilis/app_colors.dart';
import '../../patient-details/widgets/date-time-widget.dart';

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final _cardNumberController =
      TextEditingController(text: '1234 5678 1234 5678');
  final _nameController = TextEditingController(text: 'Sam Louis');
  final _cvvController = TextEditingController(text: '215');

  DateTime _expiry = DateTime(2029, 7);
  bool _saveCard = true;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _nameController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final amount = ModalRoute.of(context)?.settings.arguments as int? ?? 150;

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
                top: context.h(22),
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + context.h(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Payment Details",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF0E3E3B),
                      fontSize: context.sp(26),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Text(
                    "Enter your card information to proceed",
                    style: TextStyle(
                      color: const Color(0xFF7EA9A3),
                      fontWeight: FontWeight.w600,
                      fontSize: context.sp(14),
                    ),
                  ),
                  SizedBox(height: context.h(18)),

                  _cardPreview(
                    context,
                    cardNumberMasked: _maskCard(_cardNumberController.text),
                    holder: _nameController.text.isEmpty
                        ? "Cardholder"
                        : _nameController.text,
                    expiry: _formatExpiry(_expiry),
                  ),

                  SizedBox(height: context.h(22)),

                  // كارد الحقول
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(16),
                      vertical: context.h(18),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Number
                        Text(
                          "Card Number",
                          style: TextStyle(
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E5753),
                          ),
                        ),
                        SizedBox(height: context.h(8)),
                        _fieldWrapper(
                          context,
                          icon: Icons.credit_card_rounded,
                          child: CustomTextForm(
                            textEditingController: _cardNumberController,
                            validator: (v) {},
                            hintText: "1234 5678 1234 5678",
                            textInputType: TextInputType.number,
                          ),
                        ),

                        SizedBox(height: context.h(14)),

                        // Cardholder Name
                        Text(
                          "Cardholder Name",
                          style: TextStyle(
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E5753),
                          ),
                        ),
                        SizedBox(height: context.h(8)),
                        _fieldWrapper(
                          context,
                          icon: Icons.person_outline_rounded,
                          child: CustomTextForm(
                            textEditingController: _nameController,
                            validator: (v) {},
                            hintText: "Full name",
                            textInputType: TextInputType.name,
                          ),
                        ),

                        SizedBox(height: context.h(14)),

                        // Expiry + CVV
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Expiration Date",
                                    style: TextStyle(
                                      fontSize: context.sp(14),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2E5753),
                                    ),
                                  ),
                                  SizedBox(height: context.h(8)),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _expiry,
                                        firstDate: DateTime(DateTime.now().year,
                                            DateTime.now().month),
                                        lastDate: DateTime(
                                            DateTime.now().year + 20, 12, 31),
                                        builder: (context, child) => Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme:
                                                const ColorScheme.light(
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
                                      if (picked != null)
                                        setState(() => _expiry = picked);
                                    },
                                    child: _tileWrapper(
                                      context,
                                      child: DateTimeWidget(dateTime: _expiry),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: context.w(10)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "CVV",
                                    style: TextStyle(
                                      fontSize: context.sp(14),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2E5753),
                                    ),
                                  ),
                                  SizedBox(height: context.h(8)),
                                  _fieldWrapper(
                                    context,
                                    icon: Icons.lock_outline_rounded,
                                    child: CustomTextForm(
                                      maxLength: 3,
                                      secure: true,
                                      textEditingController: _cvvController,
                                      validator: (v) {},
                                      hintText: "***",
                                      textInputType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: context.h(10)),

                        Row(
                          children: [
                            Checkbox(
                              value: _saveCard,
                              onChanged: (v) =>
                                  setState(() => _saveCard = v ?? false),
                              activeColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            Text(
                              "Save card for future payments",
                              style: TextStyle(
                                color: const Color(0xFF2E5753),
                                fontWeight: FontWeight.w700,
                                fontSize: context.sp(13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: context.h(18)),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(16),
                      vertical: context.h(14),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.w(16)),
                      border: Border.all(
                          color: AppColors.borderColor.withOpacity(.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Amount to Pay",
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "$amount\$",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: context.sp(18),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: context.h(20)),

                  // زر الدفع
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onClick: () {
                        FocusScope.of(context).unfocus();
                        Navigator.pushNamedAndRemoveUntil(
                            context, AppRoutes.done, (route) => false);
                      },
                      text: "Pay",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // معاينة البطاقة (Gradient)
  Widget _cardPreview(BuildContext context,
      {required String cardNumberMasked,
      required String holder,
      required String expiry}) {
    return Container(
      height: context.h(180),
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(6)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryColor, Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.w(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -context.w(30),
            left: -context.w(20),
            child: _innerCircle(context.w(140)),
          ),
          Positioned(
            bottom: -context.w(40),
            right: -context.w(30),
            child: _innerCircle(context.w(180)),
          ),
          Padding(
            padding: EdgeInsets.all(context.w(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شعار بسيط (دائرتان مثل ماستر كارد)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _mcDot(Colors.orange),
                    SizedBox(width: context.w(10)),
                    _mcDot(Colors.redAccent),
                  ],
                ),
                const Spacer(),
                Text(
                  cardNumberMasked,
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 2,
                    fontSize: context.sp(18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.h(10)),
                Row(
                  children: [
                    Expanded(
                      child: _cardMeta("Cardholder", holder),
                    ),
                    SizedBox(width: context.w(12)),
                    _cardMeta("Expiry", expiry),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mcDot(Color c) => Container(
        width: 22,
        height: 22,
        decoration:
            BoxDecoration(color: c.withOpacity(.9), shape: BoxShape.circle),
      );

  Widget _innerCircle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(.12),
        ),
      );

  Widget _cardMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

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

  Widget _fieldWrapper(BuildContext context,
      {required IconData icon, required Widget child}) {
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
            child: Icon(icon, size: context.sp(18), color: AppColors.tealDark),
          ),
          SizedBox(width: context.w(12)),
          Expanded(child: child),
        ],
      ),
    );
  }

  String _maskCard(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return "**** **** **** ****";
    final groups = <String>[];
    for (int i = 0; i < digits.length; i += 4) {
      final end = (i + 4) > digits.length ? digits.length : i + 4;
      final part = digits.substring(i, end);
      groups.add(i + 4 < digits.length ? "****" : part.padRight(4, '*'));
    }
    return groups.join(' ');
  }

  String _formatExpiry(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return "$mm/$yy";
  }
}
