import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FORMAL & UNIFORM DESIGN SYSTEM
/// Enforces strict color system and professional academic appearance
/// NO DEVIATION ALLOWED

class DesignSystem {
  // ============================================================================
  // COLORS - STRICT COLOR SYSTEM (NO DEVIATION ALLOWED)
  // ============================================================================

  // Header Color - Maroon
  static const Color headerColor = Color(0xFF720045);

  // Background Color - White
  static const Color backgroundColor = Color(0xFFFFFFFF);

  // Text Foreground Color - Black
  static const Color textColor = Color(0xFF000000);

  // Outline / Borders - Black
  static const Color borderColor = Color(0xFF000000);

  // Error Color
  static const Color errorColor = Color(0xFFD32F2F);

  // Light Grey (hover/selection only)
  static const Color lightGreyHover = Color(0xFFF5F5F5);

  // ============================================================================
  // SPACING - CONSISTENT MARGINS & PADDING
  // ============================================================================

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // ============================================================================
  // BORDER RADIUS - MINIMAL, FORMAL
  // ============================================================================

  static const double borderRadiusSmall = 2.0;
  static const double borderRadiusMedium = 4.0;
  static const double borderRadiusLarge = 8.0;

  // ============================================================================
  // HEADER DIMENSIONS
  // ============================================================================

  static const double headerHeight = 64.0;

  // ============================================================================
  // TYPOGRAPHY - CONSISTENT FONT FAMILY (ROBOTO)
  // ============================================================================

  /// Page Title - Bold, Large
  static TextStyle get pageTitle {
    return GoogleFonts.roboto(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }

  /// Hero Title - Bold, Large
  static TextStyle get heroTitle {
    return GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }

  /// Hero Subtitle - Regular, Smaller
  static TextStyle get heroSubtitle {
    return GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: textColor,
    );
  }

  /// Section Title - Bold
  static TextStyle get sectionTitle {
    return GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }

  /// Label Text
  static TextStyle get labelText {
    return GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: textColor,
    );
  }

  /// Body Text
  static TextStyle get bodyText {
    return GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: textColor,
    );
  }

  /// Small Text
  static TextStyle get smallText {
    return GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: textColor,
    );
  }

  /// Table Header Text
  static TextStyle get tableHeaderText {
    return GoogleFonts.roboto(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
  }

  /// Table Body Text
  static TextStyle get tableBodyText {
    return GoogleFonts.roboto(
      fontSize: 13,
      fontWeight: FontWeight.normal,
      color: textColor,
    );
  }

  // ============================================================================
  // BORDERS & OUTLINES
  // ============================================================================

  static const Border standardBorder = Border(
    left: BorderSide(color: borderColor, width: 1),
    right: BorderSide(color: borderColor, width: 1),
    top: BorderSide(color: borderColor, width: 1),
    bottom: BorderSide(color: borderColor, width: 1),
  );

  static const BorderSide standardBorderSide = BorderSide(
    color: borderColor,
    width: 1,
  );

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Standard box shadow (subtle black only)
  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// No shadow - use for formal/clean appearance
  static const List<BoxShadow> noShadow = [];

  /// Standard container decoration
  static BoxDecoration get standardContainerDecoration {
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(borderRadiusSmall),
    );
  }

  /// Standard table decoration
  static BoxDecoration get standardTableDecoration {
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(borderRadiusSmall),
    );
  }
}
