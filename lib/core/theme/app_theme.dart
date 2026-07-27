import 'package:flutter/material.dart';

class AppTheme {
  // ── Professor palette (professional, clean) ──────────────────────────────
  // Não são mais `const`: o modo noturno do professor troca os valores
  // dessas variáveis em tempo real (ver [applyProfessorDarkMode]), então
  // toda a tela do professor — que referencia essas cores diretamente —
  // se re-pinta sozinha sem precisar editar cada tela uma por uma.
  static Color profPrimary = _profLightPrimary;
  static Color profSecondary = _profLightSecondary;
  static Color profAccent = _profLightAccent;
  static Color profBackground = _profLightBackground;
  static Color profSurface = _profLightSurface;
  static Color profSuccess = _profLightSuccess;
  static Color profWarning = _profLightWarning;
  static Color profError = _profLightError;
  static Color profOnSurface = _profLightOnSurface;
  static bool professorDarkMode = false;

  // Paleta clara (padrão)
  static const Color _profLightPrimary = Color(0xFF1A237E);
  static const Color _profLightSecondary = Color(0xFF0288D1);
  static const Color _profLightAccent = Color(0xFF00BCD4);
  static const Color _profLightBackground = Color(0xFFF5F7FA);
  static const Color _profLightSurface = Color(0xFFFFFFFF);
  static const Color _profLightSuccess = Color(0xFF2E7D32);
  static const Color _profLightWarning = Color(0xFFF57F17);
  static const Color _profLightError = Color(0xFFC62828);
  static const Color _profLightOnSurface = Color(0xFF1F1F1F);

  // Paleta do modo noturno — mesma identidade (azul/ciano), só que clara o
  // bastante pra ter contraste confortável sobre um fundo escuro.
  static const Color _profDarkPrimary = Color(0xFF9FA8DA);
  static const Color _profDarkSecondary = Color(0xFF4FC3F7);
  static const Color _profDarkAccent = Color(0xFF4DD0E1);
  static const Color _profDarkBackground = Color(0xFF12141F);
  static const Color _profDarkSurface = Color(0xFF1C1F2E);
  static const Color _profDarkSuccess = Color(0xFF66BB6A);
  static const Color _profDarkWarning = Color(0xFFFFB74D);
  static const Color _profDarkError = Color(0xFFEF5350);
  static const Color _profDarkOnSurface = Color(0xFFECEFF7);

  /// Liga/desliga o modo noturno do professor. Atualiza todas as cores
  /// `AppTheme.profX` de uma vez — quem chamar isso deve, em seguida,
  /// disparar um rebuild do app (o `SettingsController` já faz isso).
  static void applyProfessorDarkMode(bool dark) {
    professorDarkMode = dark;
    profPrimary = dark ? _profDarkPrimary : _profLightPrimary;
    profSecondary = dark ? _profDarkSecondary : _profLightSecondary;
    profAccent = dark ? _profDarkAccent : _profLightAccent;
    profBackground = dark ? _profDarkBackground : _profLightBackground;
    profSurface = dark ? _profDarkSurface : _profLightSurface;
    profSuccess = dark ? _profDarkSuccess : _profLightSuccess;
    profWarning = dark ? _profDarkWarning : _profLightWarning;
    profError = dark ? _profDarkError : _profLightError;
    profOnSurface = dark ? _profDarkOnSurface : _profLightOnSurface;
  }

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
    final brightness = professorDarkMode ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: profPrimary,
        brightness: brightness,
      ).copyWith(
        primary: profPrimary,
        secondary: profSecondary,
        surface: profSurface,
        onSurface: profOnSurface,
        error: profError,
      ),
      scaffoldBackgroundColor: profBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: profPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
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
        fillColor: professorDarkMode ? profSurface : const Color(0xFFF0F2F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: profPrimary, width: 2),
        ),
        labelStyle: TextStyle(color: professorDarkMode ? profOnSurface.withOpacity(0.7) : const Color(0xFF5C6BC0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: profPrimary),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: profPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: profOnSurface),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: profOnSurface),
        bodyMedium: TextStyle(fontSize: 14, color: profOnSurface.withOpacity(0.85)),
        labelSmall: TextStyle(fontSize: 11, letterSpacing: 0.5, color: profOnSurface.withOpacity(0.7)),
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
