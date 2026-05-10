import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/home/state/boosted_events_provider.dart';
import 'package:pulz_app/features/reported_events/presentation/map_live_page.dart';

/// Onglet actif dans la rangee de carrousels boostes affiches dans le
/// greeting block du home (juste au-dessus des nav tabs neon).
enum BoostedCarouselTab { featured, top }

/// Provider de l'onglet courant. Par defaut [featured] (= "A la une").
final boostedCarouselTabProvider =
    StateProvider<BoostedCarouselTab>((_) => BoostedCarouselTab.featured);

/// Rangee de 3 pilules raccourcis : "A la une" / "Top" / "Map Live".
/// S'affiche au-dessus de [HomeNavTabs] dans le greeting block du home.
///
/// Style aligne sur la palette neon des nav tabs (purple #A855F7 + surface
/// #1A0E2E) mais en pill compacte (hauteur ~30) plutot qu'en cercle.
class HomeQuickPills extends ConsumerWidget {
  const HomeQuickPills({super.key});

  static const _surface  = Color(0xFF1A0E2E);
  static const _accent   = Color(0xFFA855F7);
  static const _accentLo = Color(0x33A855F7);
  static const _accentHi = Color(0xFFC77DFF);
  static const _textHi   = Color(0xFFF5F0FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(boostedCarouselTabProvider);
    // Pre-warm les deux providers boostes des l'affichage des pills, pour
    // que le swap "A la une" <-> "Top" soit instantane sans re-fetch.
    ref.watch(boostedEventsProvider);
    ref.watch(boostedP2EventsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _Pill(
              icon: Icons.star_rounded,
              label: 'À la une',
              isActive: tab == BoostedCarouselTab.featured,
              onTap: () => ref.read(boostedCarouselTabProvider.notifier).state =
                  BoostedCarouselTab.featured,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Pill(
              icon: Icons.trending_up_rounded,
              label: 'Top',
              isActive: tab == BoostedCarouselTab.top,
              onTap: () => ref.read(boostedCarouselTabProvider.notifier).state =
                  BoostedCarouselTab.top,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Pill(
              icon: Icons.fiber_manual_record,
              iconColor: const Color(0xFFF472B6),
              label: 'Map Live',
              isActive: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MapLivePage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool isActive;

  const _Pill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: HomeQuickPills._surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? HomeQuickPills._accent
                : HomeQuickPills._accentLo,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? const [
                  BoxShadow(color: Color(0x66A855F7), blurRadius: 14),
                  BoxShadow(color: Color(0x33A855F7), blurRadius: 26),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x22A855F7),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 12,
              color: iconColor ?? HomeQuickPills._accentHi,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.05,
                  color: HomeQuickPills._textHi,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
