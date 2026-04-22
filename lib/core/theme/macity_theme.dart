// MacityTheme — ThemeData complet pour le redesign Claude v1.
// Active dans app.dart en Phase 1 via: theme: MacityTheme.dark().

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';

class MacityTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    final textTheme = TextTheme(
      // Greeting h1 — Geist
      displaySmall: GoogleFonts.geist(
        fontSize: 28, fontWeight: FontWeight.w400, height: 1.05,
        letterSpacing: -0.98, color: AppColors.text,
      ),
      // Section title
      headlineSmall: GoogleFonts.geist(
        fontSize: 22, fontWeight: FontWeight.w500,
        letterSpacing: -0.44, color: AppColors.text,
      ),
      // Card title
      titleMedium: GoogleFonts.geist(
        fontSize: 16, fontWeight: FontWeight.w600,
        letterSpacing: -0.24, color: AppColors.text,
      ),
      // Body
      bodyLarge: GoogleFonts.geist(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.text,
      ),
      bodyMedium: GoogleFonts.geist(
        fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textDim,
      ),
      // Eyebrow / mono
      labelSmall: GoogleFonts.geistMono(
        fontSize: 10.5, fontWeight: FontWeight.w500,
        letterSpacing: 2.1, color: AppColors.textFaint,
      ),
      // Button
      labelLarge: GoogleFonts.geist(
        fontSize: 13, fontWeight: FontWeight.w600,
        letterSpacing: -0.07, color: AppColors.text,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.magenta,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.magenta,
        secondary: AppColors.violet,
        tertiary: AppColors.cyan,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.text,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.magenta,
        labelStyle: textTheme.labelLarge!,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.magenta,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.iconBtn),
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.magenta, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium!.copyWith(color: AppColors.textFaint),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    );
  }
}
