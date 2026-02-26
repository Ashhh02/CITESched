import 'package:flutter/material.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';
import 'app_header.dart';

/// Standard Page Layout
/// Enforces consistent page structure across all modules:
/// - Maroon Header Section (Top)
/// - Hero Section Title
/// - Content Card Section
/// - Table or Form Section
/// - Action Buttons Section
class StandardPageLayout extends StatelessWidget {
  final String headerTitle;
  final String heroTitle;
  final String? heroSubtitle;
  final List<Widget> contentSections;
  final List<Widget>? actionButtons;
  final Widget? leading;
  final List<Widget>? headerActions;
  final VoidCallback? onBackPressed;

  const StandardPageLayout({
    Key? key,
    required this.headerTitle,
    required this.heroTitle,
    this.heroSubtitle,
    required this.contentSections,
    this.actionButtons,
    this.leading,
    this.headerActions,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: headerTitle,
        leading: leading,
        actions: headerActions,
        onBackPressed: onBackPressed,
      ),
      backgroundColor: DesignSystem.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              color: DesignSystem.backgroundColor,
              padding: const EdgeInsets.all(DesignSystem.spacing24),
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
                    heroTitle,
                    style: DesignSystem.heroTitle,
                  ),
                  if (heroSubtitle != null) ...[
                    const SizedBox(height: DesignSystem.spacing8),
                    Text(
                      heroSubtitle!,
                      style: DesignSystem.heroSubtitle,
                    ),
                  ],
                ],
              ),
            ),

            // Content Sections
            Padding(
              padding: const EdgeInsets.all(DesignSystem.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: contentSections
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key < contentSections.length - 1
                              ? DesignSystem.spacing24
                              : DesignSystem.spacing24,
                        ),
                        child: entry.value,
                      ),
                    )
                    .toList(),
              ),
            ),

            // Action Buttons
            if (actionButtons != null && actionButtons!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(DesignSystem.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Divider(
                      color: DesignSystem.borderColor,
                      thickness: 1,
                      height: DesignSystem.spacing16,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: DesignSystem.spacing16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: actionButtons!
                            .asMap()
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  right: entry.key < actionButtons!.length - 1
                                      ? DesignSystem.spacing12
                                      : 0,
                                ),
                                child: entry.value,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Simple Page Layout
/// For simpler pages with less structure
class SimplePageLayout extends StatelessWidget {
  final String headerTitle;
  final Widget body;
  final Widget? leading;
  final List<Widget>? headerActions;
  final VoidCallback? onBackPressed;

  const SimplePageLayout({
    Key? key,
    required this.headerTitle,
    required this.body,
    this.leading,
    this.headerActions,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: headerTitle,
        leading: leading,
        actions: headerActions,
        onBackPressed: onBackPressed,
      ),
      backgroundColor: DesignSystem.backgroundColor,
      body: body,
    );
  }
}
