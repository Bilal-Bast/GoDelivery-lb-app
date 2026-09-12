import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================
  // GoDelivery Brand Colors
  // ============================================================

  static const Color primaryColor = Color(0xFFFF6B35); // Orange
  static const Color secondaryColor = Color(0xFF004E89); // Deep blue
  static const Color accentColor = Color(0xFF1B998B); // Teal

  static const Color successColor = Color(0xFF27AE60);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color infoColor = Color(0xFF3498DB);

  // Backgrounds
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE5E7EB);

  // Text
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);

  // ============================================================
  // Light Theme
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: backgroundColor,

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: cardColor,
        error: errorColor,
      ),

      // ----------------------------------------------------------
      // App Bar
      // ----------------------------------------------------------

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: textDark,
          size: 24,
        ),
      ),

      // ----------------------------------------------------------
      // Input Fields
      // ----------------------------------------------------------

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: dividerColor,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: dividerColor,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: errorColor,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: errorColor,
            width: 2,
          ),
        ),

        hintStyle: const TextStyle(
          color: textHint,
          fontSize: 14,
        ),

        labelStyle: const TextStyle(
          color: textLight,
          fontSize: 14,
        ),
      ),

      // ----------------------------------------------------------
      // Elevated Buttons
      // ----------------------------------------------------------

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,

          minimumSize: const Size(0, 50),

          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          elevation: 0,

          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // Outlined Buttons
      // ----------------------------------------------------------

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,

          minimumSize: const Size(0, 50),

          side: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // Text Buttons
      // ----------------------------------------------------------

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,

          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),

          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // Cards
      // ----------------------------------------------------------

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,

        margin: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: dividerColor,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // Divider
      // ----------------------------------------------------------

      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // ----------------------------------------------------------
      // Icons
      // ----------------------------------------------------------

      iconTheme: const IconThemeData(
        color: textLight,
        size: 24,
      ),

      // ----------------------------------------------------------
      // Text
      // ----------------------------------------------------------

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),

        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),

        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),

        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),

        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),

        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),

        bodyLarge: TextStyle(
          fontSize: 16,
          color: textDark,
        ),

        bodyMedium: TextStyle(
          fontSize: 14,
          color: textDark,
        ),

        bodySmall: TextStyle(
          fontSize: 12,
          color: textLight,
        ),

        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // Dark Theme
  // ============================================================

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF111827);
    const darkSurface = Color(0xFF1F2937);
    const darkBorder = Color(0xFF374151);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: darkSurface,
        error: errorColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
          side: BorderSide(
            color: darkBorder,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: darkBorder,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: darkBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Spacing
  // ============================================================

  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;

  // ============================================================
  // Border Radius
  // ============================================================

  static const double radiusSmall = 6;
  static const double radiusMedium = 10;
  static const double radiusLarge = 14;
  static const double radiusXLarge = 20;
}
