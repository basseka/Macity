import 'package:flutter/material.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/home/state/boosted_events_provider.dart';
import 'package:pulz_app/features/reported_events/data/city_centers.dart';
import 'package:pulz_app/features/reported_events/data/permanent_fake_stories.dart';
import 'package:pulz_app/features/tonight_quiz/presentation/tonight_quiz_sheet.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';

/// Onglet actif dans la rangee de carrousels boostes affiches dans le
/// greeting block du home (juste au-dessus des nav tabs neon).
enum BoostedCarouselTab { featured, top }

/// Provider de l'onglet courant. Par defaut [featured] (= "A la une").
final boostedCarouselTabProvider =
    StateProvider<BoostedCarouselTab>((_) => BoostedCarouselTab.featured);

/// Rangee de 4 pilules raccourcis : "A la une" / "Top" / "Ce soir" / "Offres".
/// S'affiche au-dessus de [HomeNavTabs] dans le greeting block du home.
///
/// "A la une" et "Top" sont des toggles du carrousel boost (cf
/// [boostedCarouselTabProvider]). "Ce soir" ouvre le meme questionnaire que
/// la bulle "Quoi faire ce soir" de l'accueil ([TonightQuizSheet]). "Offres" navigue vers
/// la page Explorer (/explorer).
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
      // Aligné sur les bords du bandeau sombre (marge 12). Les 4 onglets
      // tiennent toujours dans la largeur : rétrécis plutôt que coupés.
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Pill(
              icon: Icons.star_rounded,
              label: context.l10n.homeBadgeFeatured,
              isActive: tab == BoostedCarouselTab.featured,
              onTap: () => ref.read(boostedCarouselTabProvider.notifier)
                  .state = BoostedCarouselTab.featured,
            ),
            const SizedBox(width: 6),
            _Pill(
              icon: Icons.trending_up_rounded,
              label: context.l10n.homePillTop,
              isActive: tab == BoostedCarouselTab.top,
              onTap: () => ref.read(boostedCarouselTabProvider.notifier)
                  .state = BoostedCarouselTab.top,
            ),
            const SizedBox(width: 6),
            _Pill(
              icon: Icons.nightlight_round,
              label: context.l10n.homePillTonight,
              onTap: () => TonightQuizSheet.show(
                context,
                ville: ref.read(selectedCityProvider),
              ),
            ),
            const SizedBox(width: 6),
            _Pill(
              icon: Icons.card_giftcard_rounded,
              label: context.l10n.feedMenuOffers,
              isActive: false,
              onTap: () => context.go('/explorer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill "Map Live" speciale : compte le nombre de stories live disponibles
/// (fakes permanents + reels filtres par ville), affiche le badge total et
/// fait clignoter la pill en jaune quand il y a du contenu.
class MapLivePill extends ConsumerStatefulWidget {
  final VoidCallback onTap;

  /// Variante pour le bandeau sombre de la Home (piste C) : pastille
  /// translucide, texte blanc « Map Live · 14 », point jaune.
  final bool onDark;
  const MapLivePill({super.key, required this.onTap, this.onDark = false});

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
          if (widget.onDark) {
            // Fond et contour plus marqués (2026-10-21) : la pastille se
            // perdait dans le halo rose du coin haut droit du bandeau.
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0B26).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasContent
                          ? Color.lerp(const Color(0xFFFFC93C), _yellowHi, t)
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
                  const SizedBox(width: 5),
                  Text(
                    'Map Live · $total',
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
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

/// Onglet en pilule (piste C) : blanc bordé au repos, rose plein quand
/// actif. Chaque onglet a son icône (étoile, tendance, lune, cadeau),
/// rose au repos comme avant la piste C, blanche quand actif. Bordure marquée quand
/// l'onglet est sélectionné, et pendant l'appui pour « Ce soir » / « Offres »
/// qui ouvrent une autre page au lieu de rester actifs (demande 2026-10-21).
/// L'épaisseur reste la même dans tous les états pour ne pas faire bouger
/// la rangée.
class _Pill extends StatefulWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _Pill({
    required this.label,
    required this.onTap,
    this.icon,
    this.isActive = false,
  });

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _pressed = false;

  static const _pink = Color(0xFFE8177A);
  static const _dim = Color(0xFF6B5A7C);
  static const _ink = Color(0xFF2E1A45);

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final fg = isActive ? Colors.white : _dim;
    final Color borderColor;
    if (isActive) {
      borderColor = _ink;
    } else if (_pressed) {
      borderColor = _pink;
    } else {
      borderColor = const Color(0x141A0B26);
    }
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? _pink : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 11,
                color: isActive ? Colors.white : _pink,
              ),
              const SizedBox(width: 3),
            ],
            Text(
              widget.label,
              maxLines: 1,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
