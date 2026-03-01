import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopWideBreakpoint = 1400.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isSmallerThanDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 12;
    if (width < tabletBreakpoint) return 16;
    if (width < desktopWideBreakpoint) return 24;
    return 32;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final h = horizontalPadding(context);
    final width = MediaQuery.of(context).size.width;
    final v = width < mobileBreakpoint ? 12.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  static double calendarHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final base = width < mobileBreakpoint ? 420.0 : 520.0;
    return (height * 0.65).clamp(base, 760.0);
  }

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < tabletBreakpoint) return width;
    return 1400;
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveHelper.tabletBreakpoint) {
          return desktop;
        } else if (constraints.maxWidth >= ResponsiveHelper.mobileBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
