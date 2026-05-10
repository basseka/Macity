import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/home/state/boosted_events_provider.dart';
import 'package:pulz_app/features/reported_events/data/city_centers.dart';
import 'package:pulz_app/features/reported_events/data/permanent_fake_stories.dart';
import 'package:pulz_app/features/reported_events/presentation/map_live_page.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';

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
            child: _MapLivePill(
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

/// Pill "Map Live" speciale : compte le nombre de stories live disponibles
/// (fakes permanents + reels filtres par ville), affiche le badge total et
/// fait clignoter la pill en jaune quand il y a du contenu.
class _MapLivePill extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  const _MapLivePill({required this.onTap});

  @override
  ConsumerState<_MapLivePill> createState() => _MapLivePillState();
}

class _MapLivePillState extends ConsumerState<_MapLivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blinkAnim;

  static const _yellow   = Color(0xFFFBBF24);
  static const _yellowHi = Color(0xFFFDE68A);
  static const _yellowLo = Color(0x33FBBF24);

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
          final borderColor = hasContent
              ? Color.lerp(_yellowLo, _yellow, t)!
              : HomeQuickPills._accentLo;
          final glow = hasContent ? 0.18 + 0.45 * t : 0.13;
          return Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: HomeQuickPills._surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: hasContent ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasContent ? _yellow : HomeQuickPills._accent)
                      .withValues(alpha: glow),
                  blurRadius: hasContent ? 14 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fiber_manual_record,
                  size: 12,
                  color: hasContent
                      ? Color.lerp(_yellow, _yellowHi, t)
                      : const Color(0xFFF472B6),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Map Live',
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
                if (hasContent) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _yellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$total',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.0,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
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
