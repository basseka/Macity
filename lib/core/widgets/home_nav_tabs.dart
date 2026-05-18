import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

/// Onglet actif courant dans la nav secondaire.
///
/// Chaque tab pointe vers une des pages "mode" (routes /mode/xxx) qui sont
/// egalement accessibles depuis l'Explorer.
enum HomeNavTab { food, famille, sport, culture, night }

/// Couleurs pastel par catégorie : fond clair + icône saturée.
class _TileColors {
  final Color bg;
  final Color icon;
  const _TileColors(this.bg, this.icon);
}

const _tileColorsByTab = <HomeNavTab, _TileColors>{
  HomeNavTab.food: _TileColors(Color(0xFFD8F2E3), Color(0xFF0F3D2E)),
  HomeNavTab.famille: _TileColors(Color(0xFFFCEFC7), Color(0xFFF2A20C)),
  HomeNavTab.sport: _TileColors(Color(0xFFFCE3E3), Color(0xFFE5484D)),
  HomeNavTab.culture: _TileColors(Color(0xFFEADDFB), Color(0xFF9333EA)),
  HomeNavTab.night: _TileColors(Color(0xFFD7E8F8), Color(0xFF3B9FE0)),
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
          const slots = 5;
          final slotWidth = constraints.maxWidth / slots;
          final tile = (slotWidth * 0.66).clamp(46.0, 58.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _btn(context, ref, HomeNavTab.food,
                  Icons.restaurant_rounded, 'Food', tile),
              _btn(context, ref, HomeNavTab.famille,
                  Icons.family_restroom_rounded, 'Famille', tile),
              _btn(context, ref, HomeNavTab.sport,
                  Icons.sports_soccer_rounded, 'Sport', tile),
              _btn(context, ref, HomeNavTab.culture,
                  Icons.theater_comedy_rounded, 'Culture', tile),
              _btn(context, ref, HomeNavTab.night,
                  Icons.nightlife_rounded, 'Night', tile),
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
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: AppColors.isLightTheme
                  ? const Color(0xFF1A0F2E)
                  : const Color(0xFFF5F0FF),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, WidgetRef ref, HomeNavTab tab) {
    // On synchronise aussi le currentMode (utilise par AppShell, back button,
    // etc.) pour que la nav bar du bas et le pop route sachent ou on est.
    final mode = switch (tab) {
      HomeNavTab.food    => 'food',
      HomeNavTab.famille => 'family',
      HomeNavTab.sport   => 'sport',
      HomeNavTab.culture => 'culture',
      HomeNavTab.night   => 'night',
    };
    ref.read(currentModeProvider.notifier).setMode(mode);
    context.go('/mode/$mode');
  }
}
