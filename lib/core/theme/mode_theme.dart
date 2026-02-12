import 'package:flutter/painting.dart';

class ModeTheme {
  final Color chipColor;
  final LinearGradient toolbarGradient;
  final LinearGradient searchBtnGradient;
  final LinearGradient cityCardGradient;
  final LinearGradient cardImageGradient;
  final Color backgroundColor;
  final Color cardColor;
  final Color primaryColor;
  final Color primaryDarkColor;
  final Color primaryLightColor;
  final Color chipBgColor;
  final Color chipTextColor;
  final Color chipStrokeColor;
  final Color fabColor;
  final String welcomeString;
  final String subtitleString;
  final String hintString;

  const ModeTheme({
    required this.chipColor,
    required this.toolbarGradient,
    required this.searchBtnGradient,
    required this.cityCardGradient,
    required this.cardImageGradient,
    required this.backgroundColor,
    required this.cardColor,
    required this.primaryColor,
    required this.primaryDarkColor,
    required this.primaryLightColor,
    required this.chipBgColor,
    required this.chipTextColor,
    required this.chipStrokeColor,
    required this.fabColor,
    required this.welcomeString,
    required this.subtitleString,
    required this.hintString,
  });

  // ── DAY MODE ──
  static const day = ModeTheme(
    chipColor: Color(0xFF7B2D8E),
    toolbarGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4A1259), Color(0xFF7B2D8E), Color(0xFFE91E8C)],
    ),
    searchBtnGradient: LinearGradient(
      colors: [Color(0xFF7B2D8E), Color(0xFF4A1259)],
    ),
    cityCardGradient: LinearGradient(
      colors: [Color(0xFF7B2D8E), Color(0xFF4A1259)],
    ),
    cardImageGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x007B2D8E), Color(0xCC4A1259)],
    ),
    backgroundColor: Color(0xFFF8F0FA),
    cardColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFF7B2D8E),
    primaryDarkColor: Color(0xFF4A1259),
    primaryLightColor: Color(0xFFF0D6F7),
    chipBgColor: Color(0xFFF0D6F7),
    chipTextColor: Color(0xFF4A1259),
    chipStrokeColor: Color(0xFFE91E8C),
    fabColor: Color(0xFF7B2D8E),
    welcomeString: "Hey, c'est MaCity",
    subtitleString: 'Trouve tous les concerts et spectacles de ta ville',
    hintString: "Qu'est-ce que tu cherches ?",
  );

  // ── SPORT MODE ── (couleurs vertes)
  static const sport = ModeTheme(
    chipColor: Color(0xFF65A830),
    toolbarGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3D7A1E), Color(0xFF65A830), Color(0xFF86EFAC)],
    ),
    searchBtnGradient: LinearGradient(
      colors: [Color(0xFF65A830), Color(0xFF4D8C1E)],
    ),
    cityCardGradient: LinearGradient(
      colors: [Color(0xFF65A830), Color(0xFF3D7A1E)],
    ),
    cardImageGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x0065A830), Color(0xCC3D7A1E)],
    ),
    backgroundColor: Color(0xFFF7FBF2),
    cardColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFF65A830),
    primaryDarkColor: Color(0xFF3D7A1E),
    primaryLightColor: Color(0xFFECFCCB),
    chipBgColor: Color(0xFFECFCCB),
    chipTextColor: Color(0xFF3D7A1E),
    chipStrokeColor: Color(0xFF86EFAC),
    fabColor: Color(0xFF65A830),
    welcomeString: 'Mode Sport',
    subtitleString: 'Trouve tous les evenements sportifs dans ta ville',
    hintString: '',
  );

  // ── CULTURE MODE ── (couleurs cyan)
  static const culture = ModeTheme(
    chipColor: Color(0xFF0891B2),
    toolbarGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF004D5F), Color(0xFF0891B2), Color(0xFF22D3EE)],
    ),
    searchBtnGradient: LinearGradient(
      colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
    ),
    cityCardGradient: LinearGradient(
      colors: [Color(0xFF0891B2), Color(0xFF004D5F)],
    ),
    cardImageGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x000891B2), Color(0xCC004D5F)],
    ),
    backgroundColor: Color(0xFFEFF9FB),
    cardColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFF0891B2),
    primaryDarkColor: Color(0xFF004D5F),
    primaryLightColor: Color(0xFFCFFAFE),
    chipBgColor: Color(0xFFCFFAFE),
    chipTextColor: Color(0xFF004D5F),
    chipStrokeColor: Color(0xFF22D3EE),
    fabColor: Color(0xFF0891B2),
    welcomeString: 'Mode Culture & Arts',
    subtitleString: 'Musees, expos, galeries et patrimoine',
    hintString: 'Musee, expo, galerie...',
  );

  // ── FAMILY MODE ── (couleurs ambre/orange)
  static const family = ModeTheme(
    chipColor: Color(0xFFD97706),
    toolbarGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF92400E), Color(0xFFD97706), Color(0xFFFBBF24)],
    ),
    searchBtnGradient: LinearGradient(
      colors: [Color(0xFFD97706), Color(0xFFB45309)],
    ),
    cityCardGradient: LinearGradient(
      colors: [Color(0xFFD97706), Color(0xFF92400E)],
    ),
    cardImageGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00D97706), Color(0xCC92400E)],
    ),
    backgroundColor: Color(0xFFFFFBEB),
    cardColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFFD97706),
    primaryDarkColor: Color(0xFF92400E),
    primaryLightColor: Color(0xFFFEF3C7),
    chipBgColor: Color(0xFFFEF3C7),
    chipTextColor: Color(0xFF92400E),
    chipStrokeColor: Color(0xFFFBBF24),
    fabColor: Color(0xFFD97706),
    welcomeString: 'Mode En Famille',
    subtitleString: 'Sorties et activites en famille',
    hintString: 'Parc, cinema, bowling...',
  );

  // ── FOOD MODE ──
  static const food = ModeTheme(
    chipColor: Color(0xFFE11D48),
    toolbarGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9F1239), Color(0xFFE11D48), Color(0xFFFB7185)],
    ),
    searchBtnGradient: LinearGradient(
      colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
    ),
    cityCardGradient: LinearGradient(
      colors: [Color(0xFFE11D48), Color(0xFF9F1239)],
    ),
    cardImageGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00E11D48), Color(0xCC9F1239)],
    ),
    backgroundColor: Color(0xFFFFF1F2),
    cardColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFFE11D48),
    primaryDarkColor: Color(0xFF9F1239),
    primaryLightColor: Color(0xFFFFE4E6),
    chipBgColor: Color(0xFFFFE4E6),
    chipTextColor: Color(0xFF9F1239),
    chipStrokeColor: Color(0xFFFB7185),
    fabColor: Color(0xFFE11D48),
    welcomeString: 'Mode Food & lifestyle',
    subtitleString: 'Restaurants, cafes, brunchs et bien-etre',
    hintString: 'Restaurant, cafe, boulangerie...',
  );

  // ── GAMING MODE ──
  static const gaming = ModeTheme(
    chipColor: Color(0xFF6366F1),
    toolbarGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3730A3), Color(0xFF6366F1), Color(0xFFA5B4FC)],
    ),
    searchBtnGradient: LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    ),
    cityCardGradient: LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF3730A3)],
    ),
    cardImageGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x006366F1), Color(0xCC3730A3)],
    ),
    backgroundColor: Color(0xFFEEF2FF),
    cardColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFF6366F1),
    primaryDarkColor: Color(0xFF3730A3),
    primaryLightColor: Color(0xFFE0E7FF),
    chipBgColor: Color(0xFFE0E7FF),
    chipTextColor: Color(0xFF3730A3),
    chipStrokeColor: Color(0xFFA5B4FC),
    fabColor: Color(0xFF6366F1),
    welcomeString: 'Mode Gaming & pop culture',
    subtitleString: 'Jeux video, manga, comics et conventions',
    hintString: 'Gaming, manga, comics...',
  );

  // ── NIGHT MODE ── (ambiance nocturne eclaircie)
  static const night = ModeTheme(
    chipColor: Color(0xFF9333EA),
    toolbarGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2D1B69), Color(0xFF4C2889), Color(0xFF7C3AED)],
    ),
    searchBtnGradient: LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFF581C87)],
    ),
    cityCardGradient: LinearGradient(
      colors: [Color(0xFF6D28D9), Color(0xFF3B1A6E)],
    ),
    cardImageGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00581C87), Color(0xBB2D1B69)],
    ),
    backgroundColor: Color(0xFFF3EEFF),
    cardColor: Color(0xFFFFFFFF),
    primaryColor: Color(0xFF7C3AED),
    primaryDarkColor: Color(0xFF4C2889),
    primaryLightColor: Color(0xFFEDE5FF),
    chipBgColor: Color(0xFFEDE5FF),
    chipTextColor: Color(0xFF4C2889),
    chipStrokeColor: Color(0xFF9333EA),
    fabColor: Color(0xFF7C3AED),
    welcomeString: '',
    subtitleString: 'Trouve les spots ouverts ce soir',
    hintString: 'Bar, club, epicerie de nuit...',
  );

  static ModeTheme fromModeName(String mode) {
    switch (mode) {
      case 'day':
        return day;
      case 'sport':
        return sport;
      case 'culture':
        return culture;
      case 'family':
        return family;
      case 'food':
        return food;
      case 'gaming':
        return gaming;
      case 'night':
        return night;
      default:
        return day;
    }
  }
}
