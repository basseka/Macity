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
  static Color get bg => isLightTheme
      ? const Color(0xFFFAFAF7)
      : const Color(0xFF0A0514);
  static Color get bgSecondary => isLightTheme
      ? const Color(0xFFF1EEE9)
      : const Color(0xFF120823);
  static Color get surface => isLightTheme
      ? const Color(0xFFD8D8D8)
      : const Color(0xFF1A0F2E);
  static Color get surfaceHi => isLightTheme
      ? const Color(0xFFC8C8C8)
      : const Color(0xFF241640);

  // ─── Texte ─────────────────────────────────────────────────────────────
  static Color get text => isLightTheme
      ? const Color(0xFF1A0F2E)
      : const Color(0xFFF5F0FF);
  static Color get textDim => isLightTheme
      ? const Color(0xFF4A4063)
      : const Color(0xFFB5A8D0);
  static Color get textFaint => isLightTheme
      ? const Color(0xFF8A819F)
      : const Color(0xFF7A6E95);

  // ─── Lines (inversees en clair : noir transparent au lieu de blanc) ──
  static Color get line => isLightTheme
      ? const Color(0x401A0F2E)
      : const Color(0x12FFFFFF);
  static Color get lineStrong => isLightTheme
      ? const Color(0x661A0F2E)
      : const Color(0x24FFFFFF);

  // ─── Brand (inchange dans les 2 themes) ──────────────────────────────
  static const magenta    = Color(0xFFFF3D8B);
  static const violet     = Color(0xFFA855F7);
  static const purpleDeep = Color(0xFF6B1FB3);
  static const cyan       = Color(0xFF22D3EE);

  // Categories
  static const catNight  = Color(0xFFA855F7);
  static const catFood   = Color(0xFFFB923C);
  static const catCult   = Color(0xFF22D3EE);
  static const catSport  = Color(0xFF22C55E);
  static const catFiesta = Color(0xFFEF4444);
}

class AppRadius {
  static const chip    = 999.0;
  static const iconBtn = 14.0;
  static const input   = 16.0;
  static const card    = 20.0;
  static const hero    = 22.0;
  static const tabBar  = 22.0;
  static const brand   = 12.0;
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
}

class AppShadows {
  static List<BoxShadow> neon(Color c, {double blur = 20, double y = 8}) => [
        BoxShadow(color: c.withOpacity(0.5), blurRadius: blur, offset: Offset(0, y)),
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
