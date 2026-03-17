import 'package:flutter/material.dart';

class AdminHeaderContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry borderRadius;
  final Color primaryColor;
  final Color secondaryColor;
  final List<BoxShadow>? boxShadow;

  const AdminHeaderContainer({
    super.key,
    required this.child,
    required this.primaryColor,
    this.secondaryColor = const Color(0xFF8e005b),
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: borderRadius,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
      ),
      child: child,
    );
  }
}
