import 'package:flutter/material.dart';

class AppTheme {
  // ── Professor palette (professional, clean) ──────────────────────────────
  static const Color profPrimary = Color(0xFF1A237E);
  static const Color profSecondary = Color(0xFF0288D1);
  static const Color profAccent = Color(0xFF00BCD4);
  static const Color profBackground = Color(0xFFF5F7FA);
  static const Color profSurface = Color(0xFFFFFFFF);
  static const Color profSuccess = Color(0xFF2E7D32);
  static const Color profWarning = Color(0xFFF57F17);
  static const Color profError = Color(0xFFC62828);

  // ── Student/Galactic palette ──────────────────────────────────────────────
  static const Color galaxyDeep = Color(0xFF0A0E27);
  static const Color galaxyMid = Color(0xFF1A1E3C);
  static const Color galaxyPurple = Color(0xFF7C3AED);
  static const Color galaxyViolet = Color(0xFFB45AF2);
  static const Color galaxyCyan = Color(0xFF06B6D4);
  static const Color galaxyPink = Color(0xFFEC4899);
  static const Color galaxyStar = Color(0xFFFBBF24);
  static const Color galaxyGreen = Color(0xFF10B981);

  static ThemeData professorTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: profPrimary,
        brightness: Brightness.light,
      ).copyWith(
        primary: profPrimary,
        secondary: profSecondary,
        surface: profSurface,
        error: profError,
      ),
      scaffoldBackgroundColor: profBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: profPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: profSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: profPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F2F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: profPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF5C6BC0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: profPrimary),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: profPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF424242)),
        labelSmall: TextStyle(fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  static ThemeData studentTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: galaxyPurple,
        brightness: Brightness.dark,
      ).copyWith(
        primary: galaxyPurple,
        secondary: galaxyCyan,
        surface: galaxyMid,
        error: galaxyPink,
      ),
      scaffoldBackgroundColor: galaxyDeep,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: galaxyMid,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: galaxyPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFCDD6F4)),
        labelSmall: TextStyle(fontSize: 11, color: Color(0xFF89B4FA)),
      ),
    );
  }
}
