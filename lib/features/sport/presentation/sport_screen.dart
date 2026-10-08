import 'package:flutter/material.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/core/l10n/labels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_masthead.dart';
import 'package:pulz_app/core/widgets/rubrique/refine_filters.dart';
import 'package:pulz_app/core/widgets/rubrique/rubrique_landing_view.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/data/fitness_chains.dart';
import 'package:pulz_app/features/sport/presentation/widgets/chain_salles_sheet.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';
import 'package:pulz_app/features/sport/presentation/boxe_events_grid.dart';
import 'package:pulz_app/features/sport/presentation/complexe_sportif_hub.dart';
import 'package:pulz_app/features/sport/presentation/dance_venues_list.dart';
import 'package:pulz_app/features/sport/presentation/marathon_hub.dart';
import 'package:pulz_app/features/sport/presentation/marathon_race_info.dart';
import 'package:pulz_app/features/sport/presentation/match_events_hub.dart';
import 'package:pulz_app/features/sport/presentation/raquette_hub.dart';
import 'package:pulz_app/features/sport/presentation/sport_fullscreen_map.dart';
import 'package:pulz_app/features/sport/presentation/sport_home_matches_section.dart';
import 'package:pulz_app/features/sport/presentation/sport_news_section.dart';
import 'package:pulz_app/features/sport/presentation/sport_hub_grid.dart';
import 'package:pulz_app/features/sport/presentation/widgets/refine_map_section.dart';
import 'package:pulz_app/features/sport/presentation/sport_matches_list.dart';
import 'package:pulz_app/features/sport/presentation/sport_venues_list.dart';

class SportScreen extends ConsumerWidget {
  const SportScreen({super.key});

  // Sous-categories qui ont un bouton Carte
  static const _venueMapTags = <String, String>{
    'Golf': 'Golf carte',
    'Salle de fitness': 'Fitness carte',
    'Salles de boxe': 'Boxe salles carte',
    'Terrain de football': 'Football carte',
    'Terrain de basketball': 'Basketball carte',
    'Piscine': 'Piscine carte',
    'Tennis': 'Tennis carte',
    'Padel': 'Padel carte',
    'Squash': 'Squash carte',
    'Ping-pong': 'Ping-pong carte',
    'Badminton': 'Badminton carte',
  };

  // Map searchTag → sport_type pour les sous-types raquette
  static const _raquetteTagToSportType = <String, String>{
    'Tennis': 'tennis',
    'Padel': 'padel',
    'Squash': 'squash',
    'Ping-pong': 'ping-pong',
    'Badminton': 'badminton',
  };

  // Tags des courses marathon
  static const _marathonChildren = {
    'Marathon info', 'Semi-Marathon info', '10K info',
    'Marathon relais info', 'Course Enfants info',
  };

  static const _sport = RubriqueTheme(
    accent: Color(0xFFA020F0), // violet
    accent2: Color(0xFFBE56F5),
  );

  RubriqueConfig _config(BuildContext context, WidgetRef ref) {
    return RubriqueConfig(
      theme: _sport,
      eyebrowLeft: context.l10n.rubriqueEyebrow,
      eyebrowRight: 'ACTIVE',
      title: context.l10n.sportTitle,
      subtitle: context.l10n.sportSubtitle,
      sectionTitle: context.l10n.sportSectionTitle,
      chips: [
        RubriqueChip(context.l10n.sportChipGroupClasses, Icons.fitness_center_rounded, 'fitness'),
        RubriqueChip(context.l10n.sportChipWeights, Icons.sports_gymnastics_rounded, 'muscu'),
        RubriqueChip(context.l10n.sportChipGentle, Icons.self_improvement_rounded, 'gym-douce'),
        RubriqueChip(context.l10n.sportCatBoxing, Icons.sports_mma_rounded, 'boxe'),
        RubriqueChip(context.l10n.sportCatFootball, Icons.sports_soccer_rounded,
            'terrain-football'),
        RubriqueChip(context.l10n.sportChipBasket, Icons.sports_basketball_rounded,
            'terrain-basketball'),
        RubriqueChip(context.l10n.sportChipPool, Icons.pool_rounded, 'piscine'),
        RubriqueChip('Golf', Icons.golf_course_rounded, 'golf'),
      ],
      rubriqueKey: 'sport',
      bannerTitle: context.l10n.sportBannerTitle,
      bannerSubtitle: context.l10n.sportBannerSubtitle,
      bannerCta: context.l10n.commonDiscover,
      onBack: () => context.go('/home'),
      // Section « Affinez votre recherche » : tous les lieux sport de la ville
      // (indépendant du chip du haut) + carte, filtrés par quartier.
      refineItemsBuilder: (ref) =>
          ref.watch(sportAllVenuesProvider).whenData(
                (venues) => venues
                    .map((c) => RubriqueItem(
                          title: c.nom,
                          subtitle: [
                            if (c.categorie.isNotEmpty) c.categorie,
                            if (c.quartier.isNotEmpty) c.quartier,
                          ].join(' · '),
                          photoUrl: c.photo,
                          isVerified: c.isVerified,
                          isPartner: c.isPartner,
                          commerce: c,
                          onTap: (ctx) =>
                              CommerceRowCard.showDetailSheet(ctx, c),
                        ))
                    .toList(),
              ),
      refineChipsBuilder: quartierChips,
      refineMapBuilder: (ctx, all, visible) => RefineMapSection(
        all: all,
        visible: visible,
        accentColor: '#A020F0', // accent Sport
        title: context.l10n.sportMapTitle,
      ),
      extraSections: (ctx) => const [SportHomeMatchesSection()],
      extraSectionsBottom: (ctx) => const [SportNewsSection()],
      itemsBuilder: (ref, chipKey) {
        return ref.watch(sportVenuesProvider(chipKey)).whenData((list) {
          RubriqueItem itemForVenue(CommerceModel c) => RubriqueItem(
                title: c.nom,
                subtitle: [
                  if (c.categorie.isNotEmpty) c.categorie,
                  if (c.ville.isNotEmpty) c.ville,
                ].join(' · '),
                photoUrl: c.photo,
                isVerified: c.isVerified,
                isPartner: c.isPartner,
                commerce: c,
                onTap: (ctx) => CommerceRowCard.showDetailSheet(ctx, c),
              );
          // Cours Co (fitness) + Muscu : une seule carte par chaine (Basic-Fit,
          // Fitness Park, Interval, Clark Powell, Movida, On Air). Tap ->
          // feuille listant toutes les salles de la chaine avec leur localisation.
          if (chipKey != 'fitness' && chipKey != 'muscu') {
            return list.map(itemForVenue).toList();
          }
          final chainPhotos =
              ref.watch(fitnessChainPhotosProvider).valueOrNull ??
                  const <String, String>{};
          return groupFitnessVenues(list).map((e) {
            return switch (e) {
              SingleVenueEntry(:final venue) => itemForVenue(venue),
              ChainGroupEntry(:final chain, :final salles) => RubriqueItem(
                  title: chain.name,
                  subtitle: context.l10n.sportGymCount(salles.length),
                  photoUrl: chainPhotos[chain.token] ?? '',
                  commerce: null,
                  onTap: (ctx) =>
                      showChainSallesSheet(ctx, chain, salles,
                          coverUrl: chainPhotos[chain.token]),
                ),
            };
          }).toList();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(sportSubcategoryProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    // Cartes plein ecran (sans chrome editorial)
    if (SportFullscreenMap.isMapTag(sub)) {
      return SportFullscreenMap(mapTag: sub!);
    }

    if (sub == null) {
      return RubriqueLandingView(config: _config(context, ref));
    }

    return Container(
      color: EditorialColors.ink,
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: EditorialMasthead(
              kicker: sub == null
                  ? context.l10n.sportKickerHome
                  : '${context.l10n.rubriqueSport} · ${sportCategoryLabel(context, sub)}',
              title: sub == null
                  ? context.l10n.rubriqueSport
                  : sportCategoryLabel(context, sub),
              accent: RubricColors.sport,
              blurb: sub == null
                  ? context.l10n.sportBlurb
                  : null,
              onBack: sub == null
                  ? () => context.go('/home')
                  : () => ref
                      .read(modeSubcategoriesProvider.notifier)
                      .select('sport', null),
            ),
          ),
        ],
        body: _resolve(ref, modeTheme.primaryColor, sub),
      ),
    );
  }

  Widget _resolve(WidgetRef ref, Color accent, String? sub) {
    if (sub == null) return const SportHubGrid();

    return switch (sub) {
      'Matchs' => const MatchEventsHub(hubType: MatchHubType.matchs),
      'Events' => const MatchEventsHub(hubType: MatchHubType.events),
      'Complexe sportif' => const ComplexeSportifHub(),
      'Marathon' => const MarathonHub(),
      'Raquette' => const RaquetteHub(),
      'Boxe' => const SportEventsGrid(title: 'Boxe', fallbackImage: 'assets/images/pochette_boxe.webp', emptyIcon: Icons.sports_mma),
      'Natation' => const SportEventsGrid(title: 'Natation', fallbackImage: 'assets/images/pochette_natation.jpg', emptyIcon: Icons.pool),
      'Courses a pied' => const SportEventsGrid(title: 'Courses a pied', fallbackImage: 'assets/images/pochette_courseapied.webp', emptyIcon: Icons.directions_run),
      'Competition' => const SportEventsGrid(title: 'Competition', fallbackImage: 'assets/images/pochette_competition.webp', emptyIcon: Icons.emoji_events),
      'Stage de danse' => const SportEventsGrid(title: 'Stage de danse', fallbackImage: 'assets/images/pochette_stagedanse.webp', emptyIcon: Icons.music_note),
      'Danse' => _wrapVenuesRefresh(ref, accent, const DanceVenuesList()),
      // Venues avec sport_type direct
      'Salle de fitness' => _wrapVenuesRefresh(ref, accent, SportVenuesList(sportType: 'fitness', displayTitle: 'Salle de fitness', mapTag: _venueMapTags['Salle de fitness'])),
      'Salles de boxe' => _wrapVenuesRefresh(ref, accent, SportVenuesList(sportType: 'boxe', displayTitle: 'Salles de boxe', mapTag: _venueMapTags['Salles de boxe'])),
      'Terrain de football' => _wrapVenuesRefresh(ref, accent, SportVenuesList(sportType: 'terrain-football', displayTitle: 'Terrain de football', mapTag: _venueMapTags['Terrain de football'])),
      'Terrain de basketball' => _wrapVenuesRefresh(ref, accent, SportVenuesList(sportType: 'terrain-basketball', displayTitle: 'Terrain de basketball', mapTag: _venueMapTags['Terrain de basketball'])),
      'Piscine' => _wrapVenuesRefresh(ref, accent, SportVenuesList(sportType: 'piscine', displayTitle: 'Piscine', mapTag: _venueMapTags['Piscine'])),
      'Golf' => _wrapVenuesRefresh(ref, accent, SportVenuesList(sportType: 'golf', displayTitle: 'Golf', mapTag: _venueMapTags['Golf'])),
      // Sous-types raquette
      'Tennis' || 'Padel' || 'Squash' || 'Ping-pong' || 'Badminton' =>
        _wrapVenuesRefresh(ref, accent, _buildRaquetteVenues(sub)),
      // Marathon race info
      _ when _marathonChildren.contains(sub) => MarathonRaceInfo(subcategory: sub),
      // Matchs (Rugby, Football, Basketball, etc.)
      _ => SportMatchesList(subcategory: sub),
    };
  }

  Widget _buildRaquetteVenues(String tag) {
    final sportType = _raquetteTagToSportType[tag] ?? tag.toLowerCase();
    return SportVenuesList(
      sportType: sportType,
      displayTitle: tag,
      mapTag: _venueMapTags[tag],
      backLabel: 'Sport',
      backTarget: '',
    );
  }

  /// Enveloppe une liste de venues sport dans un pull-to-refresh qui invalide
  /// les providers (autoDispose) pour forcer un refetch depuis Supabase.
  Widget _wrapVenuesRefresh(WidgetRef ref, Color color, Widget child) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sportVenuesProvider);
        ref.invalidate(racketAllVenuesProvider);
        ref.invalidate(danceVenuesProvider);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      color: color,
      child: child,
    );
  }
}
