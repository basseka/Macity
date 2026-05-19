import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens design — handoff "Rubrique Food" (hi-fi, mai 2026).
/// Style éditorial chaleureux : papier crème + vert sapin + accents néon.
/// Famille typo unique : Poppins.
class FoodTokens {
  // ─── Couleurs ──────────────────────────────────────────────────────────
  static const bg       = Color(0xFFF6F1E6); // cream paper (Scaffold)
  static const surface  = Color(0xFFFFFFFF);
  static const ink      = Color(0xFF0B1410); // texte primaire / base sombre
  static const inkSoft  = Color(0xFF2A332D);
  static const muted    = Color(0xFF6B6F66);
  static const dim      = Color(0xFF9CA095);
  static const stroke   = Color(0x1A0B1410); // rgba(11,20,16,0.10)
  static const hairline = Color(0x0F0B1410); // rgba(11,20,16,0.06)

  static const forest   = Color(0xFF0F3D2E); // CTA primaire / état actif
  static const forest2  = Color(0xFF1A5A45);
  static const teal     = Color(0xFF2BAB9A); // FAB, coup de cœur, dot accent
  static const pink     = Color(0xFFE64A8F); // eyebrow RUBRIQUE
  static const dark     = Color(0xFF142019); // fond carte inspiration sombre
  static const amber    = Color(0xFFF2B548); // étoile note
  static const red      = Color(0xFFFF4D5E); // dot live vidéo

  // ─── Typo (Poppins) ────────────────────────────────────────────────────
  static TextStyle heroTitle() => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: -1,
        height: 0.95,
        color: Colors.white,
      );

  static TextStyle sectionHeader({Color color = ink, double fontSize = 14}) =>
      GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.1,
        color: color,
      );

  static TextStyle cardName({Color color = Colors.white}) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
        height: 1.05,
        color: color,
      );

  static TextStyle bannerTitle() => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: ink,
      );

  static TextStyle body({Color? color}) => GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color ?? muted,
      );

  static TextStyle chip({required Color color, FontWeight w = FontWeight.w500}) =>
      GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: w,
        height: 1,
        color: color,
      );

  static TextStyle meta({Color? color, FontWeight w = FontWeight.w500}) =>
      GoogleFonts.poppins(
        fontSize: 11.5,
        fontWeight: w,
        height: 1.3,
        color: color ?? muted,
      );

  static TextStyle eyebrow() => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        height: 1,
        color: pink,
      );

  static TextStyle tinyTag({
    Color color = Colors.white,
    double size = 9.5,
    double spacing = 0.8,
    FontWeight w = FontWeight.w700,
  }) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: w,
        letterSpacing: spacing,
        height: 1,
        color: color,
      );

  // ─── Rayons ────────────────────────────────────────────────────────────
  static const rPill = 999.0;
  static const rCard = 20.0;
  static const rInspiration = 18.0;
  static const rIconTile = 12.0;

  // ─── Ombres ────────────────────────────────────────────────────────────
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0A0B1410), blurRadius: 0, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x590B1410),
      blurRadius: 32,
      spreadRadius: -22,
      offset: Offset(0, 18),
    ),
  ];

  static const banner = <BoxShadow>[
    BoxShadow(color: Color(0x0A0B1410), blurRadius: 0, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x660B1410),
      blurRadius: 28,
      spreadRadius: -22,
      offset: Offset(0, 14),
    ),
  ];

  static const mini = <BoxShadow>[
    BoxShadow(
      color: Color(0x730B1410),
      blurRadius: 24,
      spreadRadius: -16,
      offset: Offset(0, 12),
    ),
  ];

  static List<BoxShadow> ctaPill() => const [
        BoxShadow(
          color: Color(0x800F3D2E),
          blurRadius: 14,
          spreadRadius: -6,
          offset: Offset(0, 6),
        ),
      ];
}
