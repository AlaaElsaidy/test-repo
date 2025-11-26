import 'package:flutter/material.dart';

class ProfileSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color shadowColor;
  final double elevation;
  final BorderRadius borderRadius;

  const ProfileSectionCard({
    super.key,
    required this.child,
    required this.color,
    required this.shadowColor,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 8,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shadowColor: shadowColor,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
