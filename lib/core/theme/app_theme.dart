import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF6945);
  static const Color secondaryColor = Color(0xFF17243B);
  static const Color accentColor = Color(0xFF2AA89B);
  static const Color successColor = Color(0xFF168568);
  static const Color warningColor = Color(0xFFF2A93B);
  static const Color errorColor = Color(0xFFD94D57);
  static const Color infoColor = Color(0xFF3B82C4);

  static const Color backgroundColor = Color(0xFFF8F7F5);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE9E7E3);
  static const Color textDark = Color(0xFF17243B);
  static const Color textLight = Color(0xFF667085);
  static const Color textHint = Color(0xFF98A2B3);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: cardColor,
      error: errorColor,
      brightness: Brightness.light,
    );
    final rounded16 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        prefixIconColor: textLight,
        suffixIconColor: textLight,
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
        labelStyle: const TextStyle(color: textLight, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 54),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: rounded16,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: secondaryColor,
          side: const BorderSide(color: dividerColor),
          shape: rounded16,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: dividerColor),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: cardColor,
        indicatorColor: primaryColor.withValues(alpha: .13),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? primaryColor
                  : textLight,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? primaryColor
                  : textLight,
            )),
      ),
      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: textDark),
        headlineMedium: TextStyle(fontSize: 28, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -.8, color: textDark),
        headlineSmall: TextStyle(fontSize: 23, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -.5, color: textDark),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.3, color: textDark),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textDark),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: textDark),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: textDark),
        bodySmall: TextStyle(fontSize: 12, height: 1.4, color: textLight),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101827),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          primary: primaryColor,
          secondary: const Color(0xFFB8C5D9),
          tertiary: accentColor,
          surface: const Color(0xFF192335),
          error: errorColor,
        ),
      );

  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
}
