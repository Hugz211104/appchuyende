import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Light Mode Colors (Restored Original Class for compatibility)
class AppColors {
  static const Color primary = Color(0xFF007AFF);
  static const Color secondary = Color(0xFF34C759);
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF8A8A8E);
  static const Color error = Color(0xFFFF3B30);
  static const Color divider = Color(0xFFE5E5EA);
}

// --- Dark Mode Colors ---
const Color darkPrimary = Color(0xFF0A84FF);
const Color darkSecondary = Color(0xFF30D158);
const Color darkBackground = Color(0xFF000000);
const Color darkSurface = Color(0xFF1C1C1E);
const Color darkTextPrimary = Color(0xFFFFFFFF);
const Color darkTextSecondary = Color(0xFF8E8E93);
const Color darkError = Color(0xFFFF453A);
const Color darkDivider = Color(0xFF38383A);

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: AppColors.background,
      surface: AppColors.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
    dividerColor: AppColors.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.surface,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
      ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      background: darkBackground,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: darkTextPrimary,
      onSurface: darkTextPrimary,
      error: darkError,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: darkTextPrimary, displayColor: darkTextPrimary),
    dividerColor: darkDivider,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: darkTextPrimary),
    ),
    cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: darkSurface,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkTextSecondary,
      ),
  );
}
