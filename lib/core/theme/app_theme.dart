import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Colors
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        surfaceContainer: AppColors.surfaceContainer,
        error: AppColors.error,
      ),
      
      // Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 57, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(fontSize: 45, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
      
      /*
      // Cards - Commented out due to Flutter version compatibility issue (CardTheme vs CardThemeData)
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      
      // Dialogs - Commented out due to Flutter version compatibility issue
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      */
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          elevation: 2,
        ),
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade700),
      ),
    );
  }
}
