import 'package:flutter/material.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';

/// Form Section Component
/// Container for grouping related form fields
/// Implements formal form design with black borders
class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const FormSection({
    Key? key,
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.all(DesignSystem.spacing16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DesignSystem.backgroundColor,
        border: Border.all(
          color: DesignSystem.borderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(DesignSystem.borderRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: DesignSystem.spacing16),
            child: Text(
              title,
              style: DesignSystem.sectionTitle,
            ),
          ),
          ...children.asMap().entries.map((entry) {
            final index = entry.key;
            final widget = entry.value;
            final isLast = index == children.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : DesignSystem.spacing16,
              ),
              child: widget,
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// Form Field Group Component
/// Groups label and input field
class FormField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? helperText;
  final bool isRequired;

  const FormField({
    Key? key,
    required this.label,
    required this.child,
    this.helperText,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: DesignSystem.labelText,
            ),
            if (isRequired)
              Text(
                ' *',
                style: DesignSystem.labelText.copyWith(
                  color: DesignSystem.errorColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: DesignSystem.spacing8),
        child,
        if (helperText != null) ...[
          const SizedBox(height: DesignSystem.spacing8),
          Text(
            helperText!,
            style: DesignSystem.smallText,
          ),
        ],
      ],
    );
  }
}

/// Form Divider Component
/// Black divider line for form sections
class FormDivider extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const FormDivider({
    Key? key,
    this.padding = const EdgeInsets.symmetric(vertical: DesignSystem.spacing16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Divider(
        color: DesignSystem.borderColor,
        thickness: 1,
        height: 1,
      ),
    );
  }
}
