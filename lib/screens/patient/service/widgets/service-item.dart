import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';
import '../../../../config/utilis/app_colors.dart';

class ServiceItem extends StatelessWidget {
  const ServiceItem({
    super.key,
    required this.title,
    required this.price,
    required this.path,
    required this.features,
  });

  final String title;
  final String price;
  final String path;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.w(18)),
        border: Border.all(color: AppColors.borderColor.withOpacity(.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة داخل دائرة فاتحة
          Container(
            width: context.w(64),
            height: context.w(64),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(context.w(8)),
              child: Image.asset(
                path,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: context.w(14)),

          // عنوان + مزايا + السعر
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان + بادج السعر
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppColors.blackTextColor,
                          fontSize: context.sp(18),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _pricePill(price, context),
                  ],
                ),

                SizedBox(height: context.h(10)),

                // مزايا الباكدج على شكل Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      features.map((f) => _featureChip(f, context)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricePill(String value, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(6),
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(.25)),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: context.sp(14),
        ),
      ),
    );
  }

  Widget _featureChip(String label, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(6),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: AppColors.primaryColor),
          SizedBox(width: context.w(6)),
          Text(
            label,
            style: TextStyle(
              fontSize: context.sp(12.5),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF163E39),
            ),
          ),
        ],
      ),
    );
  }
}
