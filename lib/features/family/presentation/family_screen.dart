import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/family/data/animal_park_venues_data.dart';
import 'package:pulz_app/features/family/data/bowling_venues_data.dart';
import 'package:pulz_app/features/family/data/cinema_venues_data.dart';
import 'package:pulz_app/features/family/data/family_category_data.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/family/presentation/widgets/animal_park_venue_card.dart';
import 'package:pulz_app/features/family/presentation/widgets/bowling_venue_card.dart';
import 'package:pulz_app/features/family/presentation/widgets/cinema_venue_card.dart';
import 'package:pulz_app/features/family/data/escape_game_venues_data.dart';
import 'package:pulz_app/features/family/data/family_restaurant_venues_data.dart';
import 'package:pulz_app/features/family/data/laser_game_venues_data.dart';
import 'package:pulz_app/features/family/data/playground_venues_data.dart';
import 'package:pulz_app/features/family/presentation/widgets/escape_game_venue_card.dart';
import 'package:pulz_app/features/family/presentation/widgets/family_restaurant_venue_card.dart';
import 'package:pulz_app/features/family/presentation/widgets/laser_game_venue_card.dart';
import 'package:pulz_app/features/family/presentation/widgets/playground_venue_card.dart';
import 'package:pulz_app/features/family/state/family_venues_provider.dart';


class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(familyCategoryProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    return Column(
      children: [

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              modeTheme.subtitleString,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: selectedCategory == null
              ? _buildSubcategoryGrid(context, ref)
              : _buildVenueList(context, ref, selectedCategory),
        ),
      ],
    );
  }

  Widget _buildSubcategoryGrid(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final subcategories = FamilyCategoryData.allSubcategories;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: subcategories.length,
      itemBuilder: (context, index) {
        final sub = subcategories[index];
        final countAsync =
            ref.watch(familyCategoryCountProvider(sub.searchTag));
        return DaySubcategoryCard(
          emoji: '',
          label: sub.label,
          image: sub.image,
          count: countAsync.valueOrNull,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              modeTheme.primaryColor,
              modeTheme.primaryDarkColor,
            ],
          ),
          onTap: () {
            ref.read(familyCategoryProvider.notifier).state = sub.searchTag;
          },
        );
      },
    );
  }

  Widget _buildVenueList(
    BuildContext context,
    WidgetRef ref,
    String category,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final venuesAsync = ref.watch(familyVenuesProvider);

    return Column(
      children: [
        // Back button row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  ref.read(familyCategoryProvider.notifier).state = null;
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        size: 14,
                        color: modeTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Categories',
                        style: TextStyle(
                          color: modeTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: category == 'Cette Semaine'
              ? _buildGroupedVenues(ref, modeTheme)
              : category == 'Parc animalier'
                  ? _buildAnimalParksList(ref)
                  : category == 'Cinema'
                      ? _buildCinemasList(ref)
                      : category == 'Bowling'
                          ? _buildBowlingsList(ref)
                          : category == 'Laser game'
                              ? _buildLaserGamesList(ref)
                              : category == 'Escape game'
                                  ? _buildEscapeGamesList(ref)
                                  : category == 'Restaurant familial'
                                      ? _buildFamilyRestaurantsList(ref)
                                      : category == 'Aire de jeux'
                                          ? _buildPlaygroundsList(ref)
                                          : venuesAsync.when(
                  data: (venues) {
                    if (venues.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'Aucun lieu trouve pour cette categorie',
                        icon: Icons.family_restroom,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: venues.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CommerceRowCard(commerce: venues[index]),
                      ),
                    );
                  },
                  loading: () =>
                      LoadingIndicator(color: modeTheme.primaryColor),
                  error: (error, _) => AppErrorWidget(
                    message: 'Erreur lors du chargement des lieux',
                    onRetry: () => ref.invalidate(familyVenuesProvider),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBowlingsList(WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const bowlings = BowlingVenuesData.venues;
    final items = <Widget>[];

    for (final group in BowlingVenuesData.groupOrder) {
      final groupBowlings = bowlings.where((b) => b.group == group).toList();
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              const Text('\uD83C\uDFB3', style: TextStyle(fontSize: 18)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: modeTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${groupBowlings.length}',
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
      for (final bowling in groupBowlings) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: BowlingVenueCard(bowling: bowling),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  Widget _buildPlaygroundsList(WidgetRef ref) {
    const venues = PlaygroundVenuesData.venues;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: venues.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: PlaygroundVenueCard(venue: venues[index]),
      ),
    );
  }

  Widget _buildFamilyRestaurantsList(WidgetRef ref) {
    const venues = FamilyRestaurantVenuesData.venues;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: venues.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FamilyRestaurantVenueCard(venue: venues[index]),
      ),
    );
  }

  Widget _buildLaserGamesList(WidgetRef ref) {
    const venues = LaserGameVenuesData.venues;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: venues.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: LaserGameVenueCard(venue: venues[index]),
      ),
    );
  }

  Widget _buildEscapeGamesList(WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const escapeGames = EscapeGameVenuesData.venues;
    final items = <Widget>[];

    for (final group in EscapeGameVenuesData.groupOrder) {
      final groupVenues =
          escapeGames.where((e) => e.group == group).toList();
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                _escapeGroupEmoji(group),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            child: EscapeGameVenueCard(venue: venue),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  static String _escapeGroupEmoji(String group) {
    switch (group) {
      case 'Escape games a Toulouse':
        return '\u{1F510}';
      case 'Autres types d\'escape & jeux d\'evasion':
        return '\u{1F333}';
      case 'Autres escape games proches de Toulouse':
        return '\u{1F4CD}';
      default:
        return '\u{1F510}';
    }
  }

  Widget _buildCinemasList(WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const cinemas = CinemaVenuesData.venues;
    final items = <Widget>[];

    for (final group in CinemaVenuesData.groupOrder) {
      final groupCinemas = cinemas.where((c) => c.group == group).toList();
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                group == 'Cinemas independants & art'
                    ? '\uD83C\uDFAC'
                    : '\uD83C\uDFDE\uFE0F',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: modeTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${groupCinemas.length}',
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
      for (final cinema in groupCinemas) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: CinemaVenueCard(cinema: cinema),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  Widget _buildAnimalParksList(WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const parks = AnimalParkVenuesData.venues;
    final items = <Widget>[];

    for (final group in AnimalParkVenuesData.groupOrder) {
      final groupParks = parks.where((p) => p.group == group).toList();
      // Section header
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                _animalGroupEmoji(group),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: modeTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${groupParks.length}',
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
      for (final park in groupParks) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: AnimalParkVenueCard(park: park),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  static String _animalGroupEmoji(String group) {
    switch (group) {
      case 'Zoo & safari':
        return '\uD83E\uDD81';
      case 'Parcs animaliers & fermes autour de Toulouse':
        return '\uD83D\uDC10';
      case 'Parcs animaliers excursion journee':
        return '\uD83D\uDC18';
      default:
        return '\uD83D\uDC3E';
    }
  }

  Widget _buildGroupedVenues(WidgetRef ref, ModeTheme modeTheme) {
    final groupedAsync = ref.watch(familyGroupedVenuesProvider);
    return groupedAsync.when(
      data: (grouped) => _buildGroupedVenuesList(grouped, modeTheme),
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des lieux',
        onRetry: () => ref.invalidate(familyGroupedVenuesProvider),
      ),
    );
  }

  Widget _buildGroupedVenuesList(
    Map<String, List<CommerceModel>> grouped,
    ModeTheme modeTheme,
  ) {
    final subcategories = FamilyCategoryData.allSubcategories
        .where((s) => s.searchTag != 'Cette Semaine')
        .toList();

    final items = <Widget>[];
    for (final sub in subcategories) {
      final venues = grouped[sub.searchTag] ?? [];
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Text(sub.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                sub.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: modeTheme.primaryDarkColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: modeTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${venues.length}',
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
      for (final venue in venues) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: CommerceRowCard(commerce: venue),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }
}
