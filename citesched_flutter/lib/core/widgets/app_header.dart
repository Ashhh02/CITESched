import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';

/// Standard App Header Component
/// Implements formal header design requirements:
/// - Solid maroon background
/// - White/black text with strong contrast
/// - Consistent height across all screens
/// - No decorative elements or animations
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const AppHeader({
    Key? key,
    required this.title,
    this.leading,
    this.actions,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(DesignSystem.headerHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: DesignSystem.headerColor,
      foregroundColor: Colors.white,
      leading: leading,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: actions,
      centerTitle: false,
      toolbarHeight: DesignSystem.headerHeight,
    );
  }
}
