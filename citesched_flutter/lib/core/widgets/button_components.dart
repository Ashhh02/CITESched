import 'package:flutter/material.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';

/// Primary Button Component
/// Maroon background, white text, black outline
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  const PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(
      horizontal: DesignSystem.spacing24,
    ),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? DesignSystem.headerColor : Colors.grey,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.borderRadiusSmall),
            side: const BorderSide(
              color: DesignSystem.borderColor,
              width: 1,
            ),
          ),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Secondary Button Component
/// White background, black border, black text
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  const SecondaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
    this.width,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(
      horizontal: DesignSystem.spacing24,
    ),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignSystem.textColor,
          side: const BorderSide(
            color: DesignSystem.borderColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.borderRadiusSmall),
          ),
          padding: padding,
        ),
        child: Text(label),
      ),
    );
  }
}

/// Button Group Component
/// Horizontal layout for multiple buttons with consistent spacing
class ButtonGroup extends StatelessWidget {
  final List<Widget> buttons;
  final MainAxisAlignment alignment;
  final double spacing;

  const ButtonGroup({
    Key? key,
    required this.buttons,
    this.alignment = MainAxisAlignment.center,
    this.spacing = DesignSystem.spacing12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignSystem.spacing16),
      child: Row(
        mainAxisAlignment: alignment,
        children: buttons
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  right: entry.key < buttons.length - 1 ? spacing : 0,
                ),
                child: entry.value,
              ),
            )
            .toList(),
      ),
    );
  }
}
