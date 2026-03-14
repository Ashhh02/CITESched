import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // FORMAL & UNIFORM DESIGN SYSTEM COLORS
  // NO DEVIATION ALLOWED

  // Primary Header Color - Maroon
  static const Color primaryColor = Color(0xFF800000); // Maroon

  // Background Color - White
  static const Color backgroundColor = Color(0xFFFFFFFF); // White

  // Text Foreground Color - Black
  static const Color textPrimary = Color(0xFF000000); // Black
  static const Color textSecondary = Color(0xFF000000); // Black (no greys)

  // Outline / Borders - Black
  static const Color borderColor = Color(0xFF000000); // Black
  static const Color surfaceColor = Color(0xFFFFFFFF); // White

  // Utility Colors
  static const Color errorColor = Color(0xFFD32F2F); // Professional Red
  static const Color lightGreyHover = Color(
    0xFFF5F5F5,
  ); // Very light grey for hover only

  // Aliases for compatibility
  static const Color maroon = primaryColor;
  static const Color white = backgroundColor;
  static const Color black = textPrimary;
  static const Color startBackground = backgroundColor;
  static const Color serverpodDarkGrey = surfaceColor;

  // Theme Data - FORMAL ACADEMIC APPEARANCE
  static TextTheme _buildTextTheme({
    required Color textColor,
    required Color labelColor,
  }) {
    final base =
        GoogleFonts.robotoTextTheme(ThemeData.light(useMaterial3: true).textTheme);
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            inherit: true,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          displayMedium: base.displayMedium?.copyWith(
            inherit: true,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          displaySmall: base.displaySmall?.copyWith(
            inherit: true,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            inherit: true,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            inherit: true,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            inherit: true,
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: textColor,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            inherit: true,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: textColor,
          ),
          bodySmall: base.bodySmall?.copyWith(
            inherit: true,
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: textColor,
          ),
          labelLarge: base.labelLarge?.copyWith(
            inherit: true,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        )
        .apply(
          bodyColor: textColor,
          displayColor: textColor,
        );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),

      // Text Theme - CONSISTENT FONT FAMILY
      textTheme: _buildTextTheme(
        textColor: textPrimary,
        labelColor: Colors.white,
      ),

      // Input Decoration Theme - BLACK OUTLINED TEXTFIELDS
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        hintStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),

      // Elevated Button Theme - MAROON BACKGROUND, BLACK TEXT
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: const BorderSide(color: borderColor, width: 1),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme - WHITE BACKGROUND, BLACK BORDER, BLACK TEXT
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // AppBar Theme - MAROON HEADER
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Card Theme - WHITE BACKGROUND, BLACK BORDER
      cardTheme: CardThemeData(
        color: backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider Theme - BLACK
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),

      // Table Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(backgroundColor),
        headingRowHeight: 48,
        dataRowHeight: 48,
        horizontalMargin: 0,
        columnSpacing: 12,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        headingTextStyle: GoogleFonts.roboto(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primaryColor,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF1E293B),
      textTheme: _buildTextTheme(
        textColor: const Color(0xFFE2E8F0),
        labelColor: const Color(0xFFE2E8F0),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF475569), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF475569), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}
