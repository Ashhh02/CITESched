import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FullScreenCalendarScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? backgroundColor;
  final double maxWidth;
  final bool useMaxWidthConstraint;

  const FullScreenCalendarScaffold({
    super.key,
    required this.title,
    required this.child,
    this.backgroundColor,
    this.maxWidth = 1200,
    this.useMaxWidthConstraint = true,
  });

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF720045);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: maroonColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: useMaxWidthConstraint
              ? Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: child,
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: child,
                ),
        ),
      ),
    );
  }
}
