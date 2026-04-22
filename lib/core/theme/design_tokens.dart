// Design tokens — MaCity redesign (Claude v1)
// Pose par le handoff design-claude-v1. Ne pas utiliser tant que le theme
// n'est pas active (voir Phase 1).

import 'package:flutter/material.dart';

class AppColors {
  // Surfaces
  static const bg          = Color(0xFF0A0514);
  static const bgSecondary = Color(0xFF120823);
  static const surface     = Color(0xFF1A0F2E);
  static const surfaceHi   = Color(0xFF241640);

  // Text
  static const text      = Color(0xFFF5F0FF);
  static const textDim   = Color(0xFFB5A8D0);
  static const textFaint = Color(0xFF7A6E95);

  // Brand
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

  // Lines
  static const line       = Color(0x12FFFFFF); // ~7% white
  static const lineStrong = Color(0x24FFFFFF); // ~14% white
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
