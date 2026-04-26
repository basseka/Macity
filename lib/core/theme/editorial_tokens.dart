import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens design — handoff "MaCity Coherence" v1.0 (Avril 2026).
///
/// Palette violette saturee, accents magenta + or. Trois familles typo :
/// Inter (sans), PlayfairDisplay italic (un mot d'accent par titre),
/// JetBrainsMono uppercase (eyebrows + meta).
///
/// La signature couleur par rubrique (RubricColors) est conservee — c'est ce
/// qui permet a l'utilisateur d'identifier ou il est dans l'app. Ces couleurs
/// ne servent que d'accent (eyebrow + soulignement card) ; le cadre reste
/// magenta/or partout.
class EditorialColors {
  // Surfaces — palette handoff
  static const bg            = Color(0xFF14081F); // bg.canvas
  static const bgSoft        = Color(0xFF1B0D2E); // bg.screen
  static const surface       = Color(0xFF251339); // surface.1
  static const surfaceHi     = Color(0xFF2E1A47); // surface.2
  static const stroke        = Color(0x12FFFFFF); // border.subtle (~7% white)

  // Texte
  static const text          = Color(0xFFF5E9FF); // text.primary
  static const textDim       = Color(0xFFB9A6CF); // text.secondary
  static const textMute      = Color(0xFF7C6A92); // text.tertiary

  // Accents signatures
  static const magenta       = Color(0xFFEC3E8D); // accent.primary
  static const magentaDeep   = Color(0xFFC026D3); // accent.gradStart
  static const pink          = Color(0xFFFF5FA8); // accent.gradEnd
  static const gold          = Color(0xFFF4C84A); // accent.italic

  // Accents thematiques (utilises par les eyebrows de cards rubriques)
  static const orange        = Color(0xFFFB923C); // tag.plaisirs
  static const green         = Color(0xFF4ADE80); // tag.active
  static const cyan          = Color(0xFF67E8F9); // tag.famille

  static const free          = Color(0xFF4ADE80); // prix Gratuit (= green)

  // Aliases retro-compatibles (a virer apres migration complete)
  static const ink           = bg;
  static const paper         = text;
  static const paperMuted    = textDim;
  static const dividerSoft   = surface;
  static const dividerStrong = Color(0x24FFFFFF);
}

/// Couleur d'accent par rubrique. Conservee du design d'origine — chaque
/// rubrique garde sa signature pour la reconnaissance visuelle.
class RubricColors {
  static const day      = Color(0xFF7048E8); // violet (concerts)
  static const night    = Color(0xFFD6336C); // pink
  static const food     = Color(0xFF0B7285); // teal
  static const sport    = Color(0xFF2B8A3E); // green
  static const culture  = Color(0xFFA61E4D); // maroon
  static const family   = Color(0xFFC2410C); // orange
  static const gaming   = Color(0xFF0D9488); // teal-cyan
  static const tourisme = Color(0xFFB45309); // amber

  static const _byId = <String, Color>{
    'day': day,
    'night': night,
    'food': food,
    'sport': sport,
    'culture': culture,
    'family': family,
    'gaming': gaming,
    'tourisme': tourisme,
  };

  static Color of(String rubricId) => _byId[rubricId] ?? day;
}

/// Gradient signature CTA primaire (magenta-deep -> pink, 135deg).
class EditorialGradients {
  static const cta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [EditorialColors.magentaDeep, EditorialColors.pink],
  );
}

/// Espacement (echelle 4-pt). Padding lateral ecran = 20 (non negociable).
class EditorialSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const screen = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 48.0;
}

/// Rayons.
class EditorialRadius {
  static const sm = 6.0;
  static const logo = 10.0;
  static const search = 12.0;
  static const card = 16.0;
  static const pill = 999.0;
}

/// Typographie — Inter (sans) + PlayfairDisplay italic (1 mot d'accent par
/// titre) + JetBrainsMono uppercase (eyebrows / meta).
class EditorialText {
  // ─── Inter (sans) ──────────────────────────────────────────────
  /// Titre display 36px (section header, hero...).
  static TextStyle displayTitle({Color color = EditorialColors.text}) =>
      GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.6,
        color: color,
      );

  /// Titre header de ville ("Toulouse").
  static TextStyle cityHeader({Color color = EditorialColors.text}) =>
      GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.4,
        color: color,
      );

  /// Titre de carte (eyebrow + ce titre).
  static TextStyle cardTitle({Color color = EditorialColors.text}) =>
      GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: color,
      );

  /// Corps de texte par defaut.
  static TextStyle body({Color color = EditorialColors.text}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  /// Labels de filtres / chips.
  static TextStyle chip({required Color color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ─── PlayfairDisplay italic (or, accent) ───────────────────────
  /// Phrase italique signature ("Toutes les rubriques."). Mot dore.
  static TextStyle heroLine({Color color = EditorialColors.gold}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        height: 1.15,
        letterSpacing: -0.4,
        color: color,
      );

  /// Variante taille 22 pour SectionHeader (1 mot italique apres prefixe).
  static TextStyle sectionItalic({Color color = EditorialColors.gold}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        height: 1.15,
        letterSpacing: -0.3,
        color: color,
      );

  // ─── JetBrainsMono uppercase (eyebrows / meta) ─────────────────
  /// Eyebrow standard ("ÇA BOUGE MAINTENANT", "GUIDE DES SORTIES...").
  /// Magenta par defaut, sinon textMute.
  static TextStyle eyebrow({
    Color color = EditorialColors.magenta,
    double size = 11,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: color,
      );

  /// Meta (date, heure, identifiant). Plus petit, moins espace.
  static TextStyle meta({Color color = EditorialColors.textDim}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.8,
        color: color,
      );

  // ─── Compat / specifiques (reutilises par les rows event) ──────
  /// Titre d'event dans une row (Inter 14/16 selon featured).
  static TextStyle eventTitle({bool featured = false}) => GoogleFonts.inter(
        fontSize: featured ? 16 : 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.2,
        color: EditorialColors.text,
      );

  /// Sous-titre italique (description courte).
  static TextStyle subtitleItalic() => GoogleFonts.playfairDisplay(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        height: 1.4,
        color: EditorialColors.textDim,
      );

  /// Blurb italique (sous le titre hero).
  static TextStyle blurbItalic() => GoogleFonts.playfairDisplay(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        height: 1.45,
        color: EditorialColors.textDim,
      );

  /// Date overlay (jour gros sur vignette event).
  static TextStyle dateOverlayDay() => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.0,
        color: EditorialColors.text,
      );

  /// Prix payant.
  static TextStyle pricePaid() => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: EditorialColors.text,
      );

  /// Prix gratuit (vert).
  static TextStyle priceFree() => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: EditorialColors.free,
      );

  // ─── Aliases retro-compat (a deprecier apres migration) ────────
  /// Alias deprecie : utiliser `displayTitle` ou `cardTitle`.
  static TextStyle heroTitle(Color _) => displayTitle();

  /// Alias deprecie.
  static TextStyle homeHeroTitle() => displayTitle();

  /// Alias deprecie : utiliser `cardTitle`.
  static TextStyle catCardTitle() => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.15,
        color: EditorialColors.text,
      );

  /// Alias deprecie : utiliser `cardTitle` ou `displayTitle`.
  static TextStyle groupHeaderTitle() => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: -0.36,
        color: EditorialColors.text,
      );

  /// Alias deprecie : utiliser `eyebrow`.
  static TextStyle kicker({
    Color color = EditorialColors.textDim,
    double size = 10,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: size * 0.16,
        color: color,
      );

  /// Alias deprecie : utiliser `chip`.
  static TextStyle filterChip({required Color color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: color,
      );
}
