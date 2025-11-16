import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../../../config/utilis/app_colors.dart';

class CardPreview extends StatelessWidget {
  CardPreview(
      {super.key,
      required this.expiry,
      required this.holder,
      required this.masked});

  String masked;
  String expiry;
  String holder;

  @override
  Widget build(BuildContext context) {
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
              offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              top: -context.w(30),
              left: -context.w(20),
              child: _innerCircle(context.w(140))),
          Positioned(
              bottom: -context.w(40),
              right: -context.w(30),
              child: _innerCircle(context.w(180))),
          Padding(
            padding: EdgeInsets.all(context.w(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  masked,
                  style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 2,
                      fontSize: context.sp(18),
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(height: context.h(10)),
                Row(
                  children: [
                    Expanded(child: _cardMeta("Cardholder", holder)),
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
}

Widget _innerCircle(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white.withOpacity(.12)),
    );

Widget _cardMeta(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12)),
      const SizedBox(height: 2),
      Text(value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800)),
    ],
  );
}
