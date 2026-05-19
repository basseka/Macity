import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_event_tile.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_masthead.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/core/widgets/rubrique/rubrique_landing_view.dart';
import 'package:pulz_app/features/family/data/family_category_data.dart';
import 'package:pulz_app/features/family/presentation/family_hub_grid.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/family/presentation/widgets/family_venue_row_card.dart';
import 'package:pulz_app/features/family/state/family_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';


class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  static const _famille = RubriqueTheme(
    accent: Color(0xFFF2A20C), // orange doré (= tuile home Famille)
    accent2: Color(0xFFF7BE4A),
  );

  IconData _iconFor(String tag) {
    switch (tag) {
      case 'Parc d\'attractions':
        return Icons.attractions_rounded;
      case 'Aire de jeux':
        return Icons.child_friendly_rounded;
      case 'Parc animalier':
        return Icons.pets_rounded;
      case 'Ferme pedagogique':
        return Icons.agriculture_rounded;
      case 'Cinema':
        return Icons.movie_rounded;
      case 'Bowling':
        return Icons.sports_rounded;
      case 'Laser game':
        return Icons.sports_esports_rounded;
      case 'Escape game':
        return Icons.lock_rounded;
      case 'Patinoire':
        return Icons.ice_skating_rounded;
      case 'Aquarium':
        return Icons.water_rounded;
      case 'Restaurant familial':
        return Icons.restaurant_rounded;
      default:
        return Icons.family_restroom_rounded;
    }
  }

  RubriqueConfig _config(BuildContext context, WidgetRef ref) {
    final chips = FamilyCategoryData.allSubcategories
        .where((s) => s.searchTag != 'A venir')
        .map((s) =>
            RubriqueChip(s.label, _iconFor(s.searchTag), s.searchTag))
        .toList();
    return RubriqueConfig(
      theme: _famille,
      eyebrowLeft: 'RUBRIQUE',
      eyebrowRight: 'EN TRIBU',
      title: 'Famille.',
      subtitle: 'Cinéma, parcs, ateliers — sortir avec les enfants.',
      sectionTitle: 'À faire en famille',
      chips: chips,
      rubriqueKey: 'family',
      bannerTitle: 'Des souvenirs à créer en tribu.',
      bannerSubtitle: 'Les meilleures sorties enfants vous attendent.',
      bannerCta: 'Découvrir',
      onBack: () => context.go('/home'),
      itemsBuilder: (ref, chipKey) {
        final async = ref.watch(familySupabaseVenuesProvider(chipKey));
        return async.whenData((venues) => venues
            .map((v) => RubriqueItem(
                  title: v.name,
                  subtitle: [
                    if (v.category.isNotEmpty) v.category,
                    if (v.ville.isNotEmpty) v.ville,
                  ].join(' · '),
                  photoUrl: v.photo,
                  isVerified: v.isVerified,
                  onTap: (ctx) => ItemDetailSheet.show(
                    ctx,
                    ItemDetailSheet(
                      title: v.name,
                      imageUrl: v.photo.startsWith('http') ? v.photo : null,
                      description: v.description,
                      isVerified: v.isVerified,
                      infos: [
                        if (v.adresse.isNotEmpty)
                          DetailInfoItem(
                              Icons.location_on_outlined, v.adresse),
                        if (v.horaires.isNotEmpty)
                          DetailInfoItem(
                              Icons.access_time_rounded, v.horaires),
                        if (v.tarif.isNotEmpty)
                          DetailInfoItem(
                              Icons.euro_rounded, v.tarif),
                      ],
                      primaryAction: v.websiteUrl.isNotEmpty
                          ? DetailAction(
                              icon: Icons.public_rounded,
                              label: 'Site web',
                              url: v.websiteUrl)
                          : null,
                      secondaryActions: [
                        if (v.lienMaps.isNotEmpty)
                          DetailAction(
                              icon: Icons.map_rounded,
                              label: 'Itinéraire',
                              url: v.lienMaps),
                        if (v.telephone.isNotEmpty)
                          DetailAction(
                              icon: Icons.phone_rounded,
                              label: 'Appeler',
                              url: 'tel:${v.telephone}'),
                      ],
                    ),
                  ),
                ))
            .toList());
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(familyCategoryProvider);

    if (selectedCategory == null) {
      return RubriqueLandingView(config: _config(context, ref));
    }

    return Container(
      color: EditorialColors.ink,
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: EditorialMasthead(
              kicker: selectedCategory == null
                  ? 'Rubrique · En tribu'
                  : 'Famille · $selectedCategory',
              title: selectedCategory ?? 'Famille',
              accent: RubricColors.family,
              blurb: selectedCategory == null
                  ? 'Cinema, parcs, ateliers — sortir avec les enfants.'
                  : null,
              onBack: selectedCategory == null
                  ? () => context.go('/home')
                  : () {
                      ref
                          .read(modeSubcategoriesProvider.notifier)
                          .select('family', null);
                      ref.read(dateRangeFilterProvider.notifier).state =
                          const DateRangeFilter();
                    },
            ),
          ),
        ],
        body: selectedCategory == null
            ? const FamilyHubGrid()
            : _buildVenueList(context, ref, selectedCategory),
      ),
    );
  }

  Widget _buildVenueList(
    BuildContext context,
    WidgetRef ref,
    String category,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    return category == 'A venir'
        ? _buildGroupedVenues(context, ref, modeTheme)
        : _buildCategoryVenues(ref, category, modeTheme);
  }

  /// Affiche les venues d'une categorie depuis Supabase, groupees par groupe.
  Widget _buildCategoryVenues(WidgetRef ref, String category, ModeTheme modeTheme) {
    final venuesAsync = ref.watch(familySupabaseVenuesProvider(category));

    return venuesAsync.when(
      data: (venues) {
        if (venues.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucun lieu trouve pour cette categorie',
            icon: Icons.family_restroom,
          );
        }

        // Grouper par groupe si les venues ont des groupes
        final hasGroups = venues.any((v) => v.groupe.isNotEmpty);
        if (!hasGroups) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: venues.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FamilyVenueRowCard(venue: venues[index]),
            ),
          );
        }

        // Affichage groupe
        final groupOrder = <String>[];
        for (final v in venues) {
          if (v.groupe.isNotEmpty && !groupOrder.contains(v.groupe)) {
            groupOrder.add(v.groupe);
          }
        }

        final items = <Widget>[];
        for (final group in groupOrder) {
          final groupVenues = venues.where((v) => v.groupe == group).toList();
          items.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Text(
                    _groupEmoji(category, group),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: modeTheme.primaryDarkColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: modeTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${groupVenues.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: modeTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          for (final venue in groupVenues) {
            items.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: FamilyVenueRowCard(venue: venue),
              ),
            );
          }
        }

        // Venues sans groupe
        final noGroupVenues = venues.where((v) => v.groupe.isEmpty).toList();
        for (final venue in noGroupVenues) {
          items.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: FamilyVenueRowCard(venue: venue),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: items,
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des lieux',
        onRetry: () => ref.invalidate(familySupabaseVenuesProvider(category)),
      ),
    );
  }

  static String _groupEmoji(String category, String group) {
    switch (category) {
      case 'Cinema':
        return group.contains('independant') ? '\uD83C\uDFAC' : '\uD83C\uDFDE\uFE0F';
      case 'Bowling':
        return '\uD83C\uDFB3';
      case 'Escape game':
        if (group.contains('Autres types')) return '\u{1F333}';
        if (group.contains('proches')) return '\u{1F4CD}';
        return '\u{1F510}';
      case 'Parc animalier':
        if (group.contains('Zoo')) return '\uD83E\uDD81';
        if (group.contains('excursion')) return '\uD83D\uDC18';
        return '\uD83D\uDC10';
      default:
        return '\uD83D\uDCCD';
    }
  }

  Widget _buildGroupedVenues(BuildContext context, WidgetRef ref, ModeTheme modeTheme) {
    final userEvents = ref.watch(familyUserEventsProvider);
    final scrapedAsync = ref.watch(familyScrapedEventsProvider);
    final filter = ref.watch(dateRangeFilterProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Combiner events communauté + scraped
    final scrapedEvents = scrapedAsync.valueOrNull ?? [];
    final allEvents = [...userEvents, ...scrapedEvents];

    final filtered = allEvents.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) return false;
      final dateOnly = DateTime(d.year, d.month, d.day);
      if (dateOnly.isBefore(today)) return false;
      return filter.isInRange(dateOnly);
    }).toList()
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    if (filtered.isEmpty) {
      return scrapedAsync.isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : const EmptyStateWidget(
              message: 'Aucun evenement famille pour le moment',
              icon: Icons.family_restroom,
            );
    }

    final grouped = <DateTime, List<Event>>{};
    for (final e in filtered) {
      final d = DateTime.tryParse(e.dateDebut)!;
      final dateOnly = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(dateOnly, () => []).add(e);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: DateRangeChipBar(),
        ),
        const SizedBox(height: 4),
        for (final day in sortedDays) ...[
          editorialDateHeader(
            editorialDayLabel(day),
            RubricColors.family,
            count: grouped[day]!.length,
          ),
          for (final event in grouped[day]!)
            editorialEventTileFromEvent(
              context,
              event,
              RubricColors.family,
            ),
        ],
      ],
    );
  }
}
