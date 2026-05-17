import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/home/state/boosted_events_provider.dart';
import 'package:pulz_app/features/likes/presentation/liked_places_bottom_sheet.dart';
import 'package:pulz_app/features/reported_events/data/city_centers.dart';
import 'package:pulz_app/features/reported_events/data/permanent_fake_stories.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';

/// Onglet actif dans la rangee de carrousels boostes affiches dans le
/// greeting block du home (juste au-dessus des nav tabs neon).
enum BoostedCarouselTab { featured, top }

/// Provider de l'onglet courant. Par defaut [featured] (= "A la une").
final boostedCarouselTabProvider =
    StateProvider<BoostedCarouselTab>((_) => BoostedCarouselTab.featured);

/// Rangee de 3 pilules raccourcis : "A la une" / "Top" / "Mes favoris".
/// S'affiche au-dessus de [HomeNavTabs] dans le greeting block du home.
///
/// "A la une" et "Top" sont des toggles du carrousel boost (cf
/// [boostedCarouselTabProvider]). "Mes favoris" est une action :
/// ouvre la bottom sheet [LikedPlacesBottomSheet].
///
/// La pill "Map Live" a ete deplacee dans le BrandRow (a droite). Cf.
/// [MapLivePill] (toujours dans ce fichier, expose publiquement).
///
/// Style aligne sur la palette neon des nav tabs (purple #A855F7 + surface
/// #1A0E2E) mais en pill compacte (hauteur ~30) plutot qu'en cercle.
class HomeQuickPills extends ConsumerWidget {
  const HomeQuickPills({super.key});

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
              icon: Icons.favorite_rounded,
              label: 'Mes favoris',
              isActive: false,
              onTap: () => showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const LikedPlacesBottomSheet(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill "Map Live" speciale : compte le nombre de stories live disponibles
/// (fakes permanents + reels filtres par ville), affiche le badge total et
/// fait clignoter la pill en jaune quand il y a du contenu.
class MapLivePill extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  const MapLivePill({super.key, required this.onTap});

  @override
  ConsumerState<MapLivePill> createState() => MapLivePillState();
}

class MapLivePillState extends ConsumerState<MapLivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blinkAnim;

  static const _yellow   = Color(0xFFFBBF24);
  static const _yellowHi = Color(0xFFFDE68A);

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _blinkAnim = CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Compte = 3 fakes permanents + reels filtres par ville selectionnee.
    final feed = ref.watch(reportedEventsFeedProvider).valueOrNull ?? const [];
    final city = ref.watch(selectedCityProvider);
    final bbox = CityCenters.boundingBox(city);
    final realCount = bbox != null
        ? feed
            .where((e) =>
                e.lat >= bbox.minLat &&
                e.lat <= bbox.maxLat &&
                e.lng >= bbox.minLng &&
                e.lng <= bbox.maxLng)
            .length
        : feed.length;
    final total = realCount + permanentFakeStories().length;
    final hasContent = total > 0;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _blinkAnim,
        builder: (_, __) {
          // Interpole l'opacite du glow jaune pour faire pulser quand il
          // y a du contenu. Sinon : pill statique avec accent violet.
          final t = hasContent ? _blinkAnim.value : 0.0;
          return Container(
            height: 32,
            padding: const EdgeInsets.fromLTRB(10, 0, 7, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0x141A0F2E),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Point jaune pulsant
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasContent
                        ? Color.lerp(_yellow, _yellowHi, t)
                        : const Color(0xFFD6D2C8),
                    boxShadow: hasContent
                        ? [
                            BoxShadow(
                              color: _yellow.withValues(alpha: 0.5 + 0.3 * t),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Map Live',
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: const Color(0xFF1A0F2E),
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  constraints: const BoxConstraints(minWidth: 19),
                  height: 19,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.magenta,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$total',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: isActive ? null : const Color(0xFFFFFFFF),
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFFF3D8B), Color(0xFFFF6FB0)],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? null
              : Border.all(color: const Color(0x141A0F2E), width: 1),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.magenta.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x12000000),
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
              size: 13,
              color: isActive
                  ? Colors.white
                  : (iconColor ?? AppColors.magenta),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF1A0F2E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
