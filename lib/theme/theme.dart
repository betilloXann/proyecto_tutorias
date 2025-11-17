import 'package:flutter/material.dart';

class AppTheme {
  // ================================
  // PALETA DE COLORES
  // ================================
  static const Color baseLight = Color(0xFFEEF2F7);
  static const Color basePure  = Color(0xFFF7FAFD);
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDeep  = Color(0xFFD2D9E3);

  static const Color blueSoft   = Color(0xFFA8C5E6);
  static const Color blueMedium = Color(0xFF7BA9D9);
  static const Color bluePrimary = Color(0xFF4A7FBA);
  static const Color blueDark    = Color(0xFF2F5A93);

  static const Color lavenderSoft = Color(0xFFC8C7F3);
  static const Color purpleMist   = Color(0xFFA8A6E8);
  static const Color pinkLight    = Color(0xFFF5C9D4);

  static const Color textPrimary   = Color(0xFF4A4A4A);
  static const Color textSecondary = Color(0xFF7A7A7A);
  static const Color textDisabled  = Color(0xFFB8B8B8);

  // ================================
  // SOMBRAS NEUMÓRFICAS
  // Las aplicas manualmente en containers
  // ================================
  static const List<BoxShadow> neumorphism = [
    BoxShadow(
      color: shadowDeep,
      offset: Offset(6, 6),
      blurRadius: 16,
    ),
    BoxShadow(
      color: shadowLight,
      offset: Offset(-6, -6),
      blurRadius: 16,
    ),
  ];

  // ================================
  // THEME PRINCIPAL
  // ================================
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,

      // ----------------------------
      // COLORES BASE
      // ----------------------------
      scaffoldBackgroundColor: baseLight,
      primaryColor: bluePrimary,
      hintColor: blueMedium,
      disabledColor: textDisabled,
      dividerColor: blueSoft.withOpacity(0.4),

      // ----------------------------
      // TIPOGRAFÍA
      // ----------------------------
      fontFamily: "Inter",

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ----------------------------
      // BOTONES
      // ----------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bluePrimary,
          foregroundColor: Colors.white,
          shadowColor: bluePrimary.withOpacity(0.2),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: bluePrimary,
        ),
      ),

      // ----------------------------
      // INPUTS (TextField)
      // ----------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: basePure,
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: blueSoft.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: bluePrimary,
            width: 1.6,
          ),
        ),
      ),

      // ----------------------------
      // ÍCONOS
      // ----------------------------
      iconTheme: const IconThemeData(
        color: bluePrimary,
        size: 26,
      ),

      // ----------------------------
      // APPBAR
      // ----------------------------
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: baseLight,
        foregroundColor: bluePrimary,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ----------------------------
      // CARDS
      // ----------------------------
      cardTheme: CardThemeData(
        color: baseLight,
        margin: const EdgeInsets.all(10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}
