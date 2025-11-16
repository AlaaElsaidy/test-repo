import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../../../config/utilis/app_colors.dart';
import '../../data/doctorModel.dart';

class DoctorCardSimple extends StatelessWidget {
  const DoctorCardSimple({
    super.key,
    required this.doctor,
    required this.selected,
    required this.onTap,
  });

  final Doctor doctor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const onlineColor = Color(0xFF22C55E);

    return InkWell(
      borderRadius: BorderRadius.circular(context.w(18)),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(14),
        ),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primaryColor.withOpacity(.05) : Colors.white,
          borderRadius: BorderRadius.circular(context.w(18)),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor
                : AppColors.borderColor.withOpacity(.5),
            width: selected ? 1.6 : 1,
          ),
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
            // Avatar + حالة متصل
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: context.w(56),
                  height: context.w(56),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(.20),
                        const Color(0xFF06B6D4).withOpacity(.20),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: context.w(48),
                      height: context.w(48),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primaryColor,
                        size: context.w(26),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9ABFBA),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          doctor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF163E39),
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: context.w(6)),
                      Icon(Icons.verified_rounded,
                          size: context.sp(18), color: AppColors.primaryColor),
                    ],
                  ),
                  SizedBox(height: context.h(6)),
                  Row(
                    children: [
                      _ratingRow(doctor.rating, context),
                      SizedBox(width: context.w(10)),
                      _metaChip(
                          "${doctor.years} yrs", Icons.badge_outlined, context),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: context.w(8)),

            _selectionBadge(selected, context),
          ],
        ),
      ),
    );
  }

  Widget _ratingRow(double rating, BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Row(
      children: [
        ...List.generate(
          5,
          (i) {
            if (i < full) {
              return Icon(Icons.star, size: 16, color: Colors.amber[600]);
            } else if (i == full && hasHalf) {
              return Icon(Icons.star_half, size: 16, color: Colors.amber[600]);
            } else {
              return Icon(Icons.star_border,
                  size: context.sp(16), color: Colors.amber[600]);
            }
          },
        ),
      ],
    );
  }

  Widget _metaChip(String label, IconData icon, BuildContext context) {
    const c = AppColors.primaryColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: c.withOpacity(.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          SizedBox(width: context.w(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: context.sp(11.5),
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionBadge(bool selected, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(6),
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryColor.withOpacity(.12)
            : const Color(0xFFF3FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primaryColor.withOpacity(.4)
              : AppColors.primaryColor.withOpacity(.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: selected ? AppColors.primaryColor : const Color(0xFF9ABFBA),
          ),
          SizedBox(width: context.w(6)),
          Text(
            selected ? "Selected" : "Select",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: context.sp(12.5),
              color:
                  selected ? AppColors.primaryColor : const Color(0xFF2E5753),
            ),
          ),
        ],
      ),
    );
  }
}
