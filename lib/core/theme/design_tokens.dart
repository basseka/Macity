// Design tokens — MaCity redesign (Claude v1)
// Pose par le handoff design-claude-v1. Ne pas utiliser tant que le theme
// n'est pas active (voir Phase 1).

import 'package:flutter/material.dart';

class AppColors {
  // ─── Mode clair / sombre (POC theme) ────────────────────────────────────
  // Bascule globale. ModeShell met a jour ce flag selon le mode courant :
  // Night = false (dark), tous les autres modes = true (light).
  // Les getters bg/surface/text/line dependent de ce flag. Les couleurs
  // brand (magenta/violet/etc.) restent les memes dans les 2 themes.
  static bool isLightTheme = false;

  // ─── Surfaces ──────────────────────────────────────────────────────────
  static Color get bg =>
      isLightTheme ? const Color(0xFFFAFAF7) : const Color(0xFF0A0514);
  static Color get bgSecondary =>
      isLightTheme ? const Color(0xFFF1EEE9) : const Color(0xFF120823);
  static Color get surface =>
      isLightTheme ? const Color(0xFFD8D8D8) : const Color(0xFF1A0F2E);
  static Color get surfaceHi =>
      isLightTheme ? const Color(0xFFC8C8C8) : const Color(0xFF241640);

  // ─── Texte ─────────────────────────────────────────────────────────────
  static Color get text =>
      isLightTheme ? const Color(0xFF1A0F2E) : const Color(0xFFF5F0FF);
  static Color get textDim =>
      isLightTheme ? const Color(0xFF4A4063) : const Color(0xFFB5A8D0);
  static Color get textFaint =>
      isLightTheme ? const Color(0xFF8A819F) : const Color(0xFF7A6E95);

  // ─── Lines (inversees en clair : noir transparent au lieu de blanc) ──
  static Color get line =>
      isLightTheme ? const Color(0x401A0F2E) : const Color(0x12FFFFFF);
  static Color get lineStrong =>
      isLightTheme ? const Color(0x661A0F2E) : const Color(0x24FFFFFF);

  // ─── Brand (inchange dans les 2 themes) ──────────────────────────────
  static const magenta = Color(0xFFFF3D8B);
  static const violet = Color(0xFFA855F7);
  static const purpleDeep = Color(0xFF6B1FB3);
  static const cyan = Color(0xFF22D3EE);

  // Categories
  static const catNight = Color(0xFFA855F7);
  static const catFood = Color(0xFFFB923C);
  static const catCult = Color(0xFF22D3EE);
  static const catSport = Color(0xFF22C55E);
  static const catFiesta = Color(0xFFEF4444);

  // ─── Bouton "Quoi faire ce soir" (ciel de nuit, fixe, hors theme) ─────
  // Volontairement independant de isLightTheme : c'est le seul element
  // nocturne d'un ecran Home par ailleurs clair, son contraste vient de la.
  static const tonightShadow = Color(0xFF4C1D95);

  // ─── Feed liste "Les bons plans" (fixe, hors theme, cf FEED_LISTE.md) ──
  static const feedBg = Color(0xFFFFFFFF);
  static const feedText = Color(0xFF15121C);
  static const feedTextSecondary = Color(0xFF4A4458);
  static const feedDivider = Color(0x1F15121C);
  static const feedPriceFree = Color(0xFF0E8A4F);
  static const feedProBadge = Color(0xFF1F3A6E);
  static const feedFriendsBadge = Color(0xFF8B3FD4);
  static const feedLiveBg = Color(0xFFF4247C);

  static const feedTagFood = Color(0xFFFFD93D);
  static const feedTagNight = Color(0xFFC4B5FD);
  static const feedTagCulture = Color(0xFFA5F3E4);
  static const feedTagSport = Color(0xFFBFDBFE);
  static const feedTagFamily = Color(0xFFFED7AA);
  static const feedTagEvasion = Color(0xFFFBCFE8);

  // ─── Pastille neon "Quoi faire ce soir" (fixe, hors theme, cf PASTILLE_NEON.md)
  static const neonBg = Color(0xFF160C2E);
  static const neonPink = Color(0xFFF4247C);
  static const neonCyan = Color(0xFF22D3EE);
}

class AppRadius {
  static const chip = 999.0;
  static const iconBtn = 14.0;
  static const input = 16.0;
  static const card = 20.0;
  static const hero = 22.0;
  static const tabBar = 22.0;
  static const brand = 12.0;
}

class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.magenta, AppColors.violet, AppColors.purpleDeep],
    stops: [0.0, 0.6, 1.0],
  );

  static const editorial = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.magenta, Color(0xFFFBBF24)],
  );

  // Subtle card bottom shade
  static const cardShade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xF20A0514)],
    stops: [0.3, 1.0],
  );

  // Bouton "Quoi faire ce soir" : fond ciel de nuit + degrade chaud du mot
  // "ce soir ?" (voir BOUTON_CE_SOIR.md). Couleurs fixes, hors theme.
  static const tonightSky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1040),
      Color(0xFF4C1D95),
      Color(0xFFA21CAF),
      Color(0xFFF4247C)
    ],
    stops: [0.0, 0.42, 0.78, 1.0],
  );
  static const tonightAccentText = LinearGradient(
    colors: [Color(0xFFFFD88A), Color(0xFFFF9EC4)],
  );
}

class AppShadows {
  static List<BoxShadow> neon(Color c, {double blur = 20, double y = 8}) => [
        BoxShadow(
            color: c.withOpacity(0.5), blurRadius: blur, offset: Offset(0, y)),
      ];

  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static List<BoxShadow> pinGlow(Color c) => [
        BoxShadow(color: c.withOpacity(0.9), blurRadius: 20, spreadRadius: 2),
      ];
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
}
