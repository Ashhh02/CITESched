import 'package:flutter/material.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';

/// Hero Section Component
/// Implements formal hero section design:
/// - White background
/// - Black bold title text
/// - Black subtitle text (optional)
/// - Black bottom border line
/// - Consistent vertical spacing
class HeroSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;

  const HeroSection({
    Key? key,
    required this.title,
    this.subtitle,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DesignSystem.backgroundColor,
      padding: padding ?? const EdgeInsets.all(DesignSystem.spacing24),
      decoration: BoxDecoration(
        color: DesignSystem.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: DesignSystem.borderColor,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: DesignSystem.heroTitle,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: DesignSystem.spacing8),
            Text(
              subtitle!,
              style: DesignSystem.heroSubtitle,
            ),
          ],
        ],
      ),
    );
  }
}
