import 'package:flutter/material.dart';
import 'package:pulz_app/core/l10n/labels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

/// Onglet actif courant dans la nav secondaire.
///
/// Chaque tab pointe vers une des pages "mode" (routes /mode/xxx) qui sont
/// egalement accessibles depuis l'Explorer.
enum HomeNavTab { food, famille, sport, culture, night, evasion }

/// Couleurs pastel par catégorie : fond clair + icône saturée.
class _TileColors {
  final Color bg;
  final Color icon;
  const _TileColors(this.bg, this.icon);
}

const _tileColorsByTab = <HomeNavTab, _TileColors>{
  HomeNavTab.food: _TileColors(Color(0xFFD8F2E9), Color(0xFF2BAB9A)),
  HomeNavTab.famille: _TileColors(Color(0xFFFCEFC7), Color(0xFFF2A20C)),
  HomeNavTab.sport: _TileColors(Color(0xFFF1E4FF), Color(0xFFA020F0)),
  HomeNavTab.culture: _TileColors(Color(0xFFFFE1F1), Color(0xFFFF2DAA)),
  HomeNavTab.night: _TileColors(Color(0xFFDCE0EC), Color(0xFF060B2B)),
  // Ambre (= accent Tourisme/Évasion), distinct du jaune Famille.
  HomeNavTab.evasion: _TileColors(Color(0xFFF7E6D0), Color(0xFFB45309)),
};

/// Rangée de 5 tuiles catégories pastel (carré arrondi + label dessous).
/// Tap → navigue vers /mode/xxx (et synchronise currentMode).
class HomeNavTabs extends ConsumerWidget {
  final HomeNavTab? active;

  const HomeNavTabs({super.key, this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const slots = 6;
          final slotWidth = constraints.maxWidth / slots;
          final tile = (slotWidth * 0.66).clamp(46.0, 58.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _btn(context, ref, HomeNavTab.food,
                  Icons.restaurant_rounded, rubriqueLabel(context, 'food'), tile, slotWidth),
              _btn(context, ref, HomeNavTab.famille,
                  Icons.family_restroom_rounded, rubriqueLabel(context, 'family'), tile, slotWidth),
              _btn(context, ref, HomeNavTab.culture,
                  Icons.theater_comedy_rounded, rubriqueLabel(context, 'culture'), tile, slotWidth),
              _btn(context, ref, HomeNavTab.sport,
                  Icons.sports_soccer_rounded, rubriqueLabel(context, 'sport'), tile, slotWidth),
              _btn(context, ref, HomeNavTab.night,
                  Icons.nightlife_rounded, rubriqueLabel(context, 'night'), tile, slotWidth),
              _btn(context, ref, HomeNavTab.evasion,
                  Icons.flight_takeoff_rounded, rubriqueLabel(context, 'tourisme'), tile, slotWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _btn(
    BuildContext context,
    WidgetRef ref,
    HomeNavTab tab,
    IconData icon,
    String label,
    double size,
    double slotWidth,
  ) {
    final colors = _tileColorsByTab[tab]!;
    final iconSize = size * 0.44;
    final fontSize = (size * 0.21).clamp(9.5, 11.0);
    return GestureDetector(
      onTap: () => _navigate(context, ref, tab),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: iconSize, color: colors.icon),
          ),
          const SizedBox(height: 5),
          // Largeur bornee + scaleDown : un libelle long (ex. "Escapadas",
          // "Deporte" en espagnol) retrecit au lieu de deborder sur le voisin.
          SizedBox(
            // Largeur d'une colonne (6 colonnes) : la rangee ne deborde jamais.
            width: slotWidth - 4,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: AppColors.isLightTheme
                      ? const Color(0xFF1A0F2E)
                      : const Color(0xFFF5F0FF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, WidgetRef ref, HomeNavTab tab) {
    // Évasion : écran autonome (hors ShellRoute), route dédiée. Il amorce
    // lui-même le mode (tourisme) pour le bandeau vidéo.
    if (tab == HomeNavTab.evasion) {
      context.go('/evasion');
      return;
    }
    // On synchronise aussi le currentMode (utilise par AppShell, back button,
    // etc.) pour que la nav bar du bas et le pop route sachent ou on est.
    final mode = switch (tab) {
      HomeNavTab.food    => 'food',
      HomeNavTab.famille => 'family',
      HomeNavTab.sport   => 'sport',
      HomeNavTab.culture => 'culture',
      HomeNavTab.night   => 'night',
      HomeNavTab.evasion => 'tourisme', // inatteignable (traité ci-dessus)
    };
    ref.read(currentModeProvider.notifier).setMode(mode);
    context.go('/mode/$mode');
  }
}
