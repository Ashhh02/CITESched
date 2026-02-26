import 'package:flutter/material.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';

/// Content Card Component
/// Implements formal card/container design:
/// - White background
/// - Black border
/// - No shadow or subtle black shadow only
/// - Equal padding
/// - Minimal border radius
class ContentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool withShadow;
  final Color? backgroundColor;
  final Color? borderColorOverride;

  const ContentCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignSystem.spacing16),
    this.borderRadius = DesignSystem.borderRadiusSmall,
    this.withShadow = false,
    this.backgroundColor,
    this.borderColorOverride,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? DesignSystem.backgroundColor,
        border: Border.all(
          color: borderColorOverride ?? DesignSystem.borderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: withShadow
            ? DesignSystem.subtleShadow
            : DesignSystem.noShadow,
      ),
      child: child,
    );
  }
}
