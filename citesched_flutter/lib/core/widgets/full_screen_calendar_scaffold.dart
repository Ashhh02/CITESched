import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FullScreenCalendarScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? backgroundColor;

  const FullScreenCalendarScaffold({
    super.key,
    required this.title,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final maroonColor = const Color(0xFF720045);
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
