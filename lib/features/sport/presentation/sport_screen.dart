import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/utils/date_formatter.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';

import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/sport/data/sport_category_data.dart';
import 'package:pulz_app/features/sport/presentation/widgets/fitness_venue_card.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/presentation/widgets/venues_map_view.dart';
import 'package:pulz_app/features/sport/presentation/widgets/match_row_card.dart';
import 'package:pulz_app/features/sport/state/sport_matches_provider.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

class SportScreen extends ConsumerWidget {
  const SportScreen({super.key});

  // Tags des cartes plein écran
  static const _mapTags = {
    'Golf carte': 'Golf',
    'Fitness carte': 'Salle de fitness',
    'Boxe salles carte': 'Salles de boxe',
    'Football carte': 'Terrain de football',
    'Basketball carte': 'Terrain de basketball',
    'Piscine carte': 'Piscine',
    'Raquette carte': 'Raquette',
    'Tennis carte': 'Tennis',
    'Padel carte': 'Padel',
    'Squash carte': 'Squash',
    'Ping-pong carte': 'Ping-pong',
    'Badminton carte': 'Badminton',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSubcategory = ref.watch(sportSubcategoryProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    // Cartes plein écran (sans barre titre)
    if (selectedSubcategory != null && _mapTags.containsKey(selectedSubcategory)) {
      final backTo = _mapTags[selectedSubcategory]!;
      return _buildFullscreenMap(ref, modeTheme, selectedSubcategory, backTo);
    }

    return Column(
      children: [

        const SizedBox(height: 12),

        Expanded(
          child: selectedSubcategory == null
              ? _buildSubcategoryGrid(context, ref)
              : _buildMatchList(context, ref, selectedSubcategory),
        ),
      ],
    );
  }

  // Map tag → sport_type pour Supabase
  static const _mapTagToSportType = <String, String>{
    'Golf carte': 'golf',
    'Fitness carte': 'fitness',
    'Boxe salles carte': 'boxe',
    'Football carte': 'terrain-football',
    'Basketball carte': 'terrain-basketball',
    'Piscine carte': 'piscine',
    'Tennis carte': 'tennis',
    'Padel carte': 'padel',
    'Squash carte': 'squash',
    'Ping-pong carte': 'ping-pong',
    'Badminton carte': 'badminton',
  };

  Widget _buildFullscreenMap(WidgetRef ref, ModeTheme modeTheme, String mapTag, String backTo) {
    // Raquette carte = combinaison de tous les sous-types
    final AsyncValue<List<CommerceModel>> venuesAsync;
    if (mapTag == 'Raquette carte') {
      venuesAsync = ref.watch(racketAllVenuesProvider);
    } else {
      final sportType = _mapTagToSportType[mapTag];
      venuesAsync = sportType != null
          ? ref.watch(sportVenuesProvider(sportType))
          : const AsyncValue.data([]);
    }

    final title = switch (mapTag) {
      'Golf carte' => 'Golf le plus proche',
      'Fitness carte' => 'Salle la plus proche',
      'Boxe salles carte' => 'Salle la plus proche',
      'Football carte' => 'Terrain le plus proche',
      'Basketball carte' => 'Terrain le plus proche',
      'Piscine carte' => 'Piscine la plus proche',
      'Raquette carte' => 'Club le plus proche',
      'Tennis carte' => 'Club de tennis le plus proche',
      'Padel carte' => 'Club de padel le plus proche',
      'Squash carte' => 'Salle de squash la plus proche',
      'Ping-pong carte' => 'Club de ping-pong le plus proche',
      'Badminton carte' => 'Club de badminton le plus proche',
      _ => 'Le plus proche',
    };

    final color = switch (mapTag) {
      'Golf carte' => '#228B22',
      'Fitness carte' => '#E53935',
      'Boxe salles carte' => '#D84315',
      'Football carte' => '#4CAF50',
      'Basketball carte' => '#FF9800',
      'Piscine carte' => '#0288D1',
      'Raquette carte' => '#1565C0',
      'Tennis carte' => '#1565C0',
      'Padel carte' => '#1565C0',
      'Squash carte' => '#1565C0',
      'Ping-pong carte' => '#1565C0',
      'Badminton carte' => '#1565C0',
      _ => '#228B22',
    };

    return venuesAsync.when(
      data: (venues) => Stack(
        children: [
          VenuesMapView(
            venues: venues,
            title: title,
            accentColor: color,
          ),
          _buildListButton(ref, modeTheme, backTo),
        ],
      ),
      loading: () => Stack(
        children: [
          LoadingIndicator(color: modeTheme.primaryColor),
          _buildListButton(ref, modeTheme, backTo),
        ],
      ),
      error: (_, __) => Stack(
        children: [
          const Center(child: Text('Erreur de chargement')),
          _buildListButton(ref, modeTheme, backTo),
        ],
      ),
    );
  }

  Widget _buildListButton(WidgetRef ref, ModeTheme modeTheme, String backTo) {
    return Positioned(
      top: 8,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(modeSubcategoriesProvider.notifier).select('sport', backTo);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: modeTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list, size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Liste',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoryGrid(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.1,
        children: [
          DaySubcategoryCard(
            emoji: '',
            label: 'Match/Events',
            image: 'assets/images/home_bg_sport.png',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                modeTheme.primaryColor,
                modeTheme.primaryDarkColor,
              ],
            ),
            onTap: () {
              ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Match/Events');
            },
          ),
          DaySubcategoryCard(
            emoji: '',
            label: 'Complexe sportif',
            image: 'assets/images/shell_sport_fitness.png',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                modeTheme.primaryColor,
                modeTheme.primaryDarkColor,
              ],
            ),
            onTap: () {
              ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Complexe sportif');
            },
          ),
          DaySubcategoryCard(
            emoji: '',
            label: 'Marathon de Toulouse ${DateTime.now().year}',
            image: 'assets/images/pochette_course.png',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                modeTheme.primaryColor,
                modeTheme.primaryDarkColor,
              ],
            ),
            onTap: () {
              ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Marathon');
            },
          ),
          DaySubcategoryCard(
            emoji: '',
            label: 'Tour de France ${DateTime.now().year}',
            image: 'assets/images/pochette_course.png',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                modeTheme.primaryColor,
                modeTheme.primaryDarkColor,
              ],
            ),
            onTap: () {
              ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Tour de France');
            },
          ),
          DaySubcategoryCard(
            emoji: '',
            label: 'Tennis',
            image: 'assets/images/pochette_autre.png',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                modeTheme.primaryColor,
                modeTheme.primaryDarkColor,
              ],
            ),
            onTap: () {
              ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Tennis events');
            },
          ),
          DaySubcategoryCard(
            emoji: '',
            label: 'JO 2028',
            image: 'assets/images/pochette_autre.png',
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                modeTheme.primaryColor,
                modeTheme.primaryDarkColor,
              ],
            ),
            onTap: () {
              ref.read(modeSubcategoriesProvider.notifier).select('sport', 'JO 2028');
            },
          ),
        ],
      ),
    );
  }

  // Sous-catégories qui ont un bouton Carte
  static const _venueMapTags = <String, String>{
    'Golf': 'Golf carte',
    'Salle de fitness': 'Fitness carte',
    'Salles de boxe': 'Boxe salles carte',
    'Terrain de football': 'Football carte',
    'Terrain de basketball': 'Basketball carte',
    'Piscine': 'Piscine carte',
    'Raquette': 'Raquette carte',
    'Tennis': 'Tennis carte',
    'Padel': 'Padel carte',
    'Squash': 'Squash carte',
    'Ping-pong': 'Ping-pong carte',
    'Badminton': 'Badminton carte',
  };

  Widget _buildMatchList(
    BuildContext context,
    WidgetRef ref,
    String subcategory,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final isMatchEventsHub = subcategory == 'Match/Events';
    final isComplexeHub = subcategory == 'Complexe sportif';
    final isMarathon = subcategory == 'Marathon';
    final isTourDeFrance = subcategory == 'Tour de France';
    final isTennisEvents = subcategory == 'Tennis events';
    final isJO = subcategory == 'JO 2028';
    final isFitness = subcategory == 'Salle de fitness';
    final isBoxeSalles = subcategory == 'Salles de boxe';
    final isFootball = subcategory == 'Terrain de football';
    final isBasketball = subcategory == 'Terrain de basketball';
    final isPiscine = subcategory == 'Piscine';
    final isGolf = subcategory == 'Golf';
    final isRaquetteHub = subcategory == 'Raquette';
    const raquetteTags = {'Tennis', 'Padel', 'Squash', 'Ping-pong', 'Badminton'};
    final isRaquetteSub = raquetteTags.contains(subcategory);

    // Sous-catégories rattachées au hub Match/Events
    const matchEventChildren = {
      'A venir', 'Rugby', 'Football', 'Basketball', 'Handball',
      'Boxe', 'Natation', 'Courses a pied',
    };
    // Sous-catégories rattachées au hub Complexe sportif
    const complexeChildren = {
      'Salle de fitness', 'Salles de boxe', 'Terrain de football',
      'Terrain de basketball', 'Piscine', 'Golf', 'Raquette',
    };

    // Determine back target
    final String backLabel;
    final VoidCallback onBack;
    if (isMatchEventsHub || isComplexeHub || isMarathon || isTourDeFrance || isTennisEvents || isJO) {
      backLabel = 'Categories';
      onBack = () {
        ref.read(modeSubcategoriesProvider.notifier).select('sport', null);
        ref.read(dateRangeFilterProvider.notifier).state =
            const DateRangeFilter();
      };
    } else if (isBoxeSalles) {
      backLabel = 'Complexe sportif';
      onBack = () {
        ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Complexe sportif');
      };
    } else if (isRaquetteSub) {
      backLabel = 'Raquette';
      onBack = () {
        ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Raquette');
      };
    } else if (matchEventChildren.contains(subcategory)) {
      backLabel = 'Match/Events';
      onBack = () {
        ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Match/Events');
        ref.read(dateRangeFilterProvider.notifier).state =
            const DateRangeFilter();
      };
    } else if (complexeChildren.contains(subcategory)) {
      backLabel = 'Complexe sportif';
      onBack = () {
        ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Complexe sportif');
      };
    } else {
      backLabel = 'Categories';
      onBack = () {
        ref.read(modeSubcategoriesProvider.notifier).select('sport', null);
        ref.read(dateRangeFilterProvider.notifier).state =
            const DateRangeFilter();
      };
    }

    // Display title
    final displayTitle = isMatchEventsHub
        ? 'Match/Events'
        : isComplexeHub
            ? 'Complexe sportif'
            : isMarathon
                ? 'Marathon de Toulouse ${DateTime.now().year}'
                : isTourDeFrance
                    ? 'Tour de France ${DateTime.now().year}'
                    : isTennisEvents
                        ? 'Tennis'
                        : isJO
                            ? 'JO 2028'
                            : isBoxeSalles
                ? 'Salles de boxe'
                : subcategory == 'Boxe matchs'
                    ? 'Gala / Matchs'
                    : isRaquetteHub
                        ? 'Raquette'
                        : isGolf
                            ? 'Golf'
                            : subcategory;

    // Has a map button?
    final mapTag = _venueMapTags[subcategory];

    return Column(
      children: [
        // Back button row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              // Bouton carte
              if (mapTag != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ref.read(modeSubcategoriesProvider.notifier).select('sport', mapTag);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: modeTheme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Carte',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              InkWell(
                onTap: onBack,
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
                        backLabel,
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
          child: isMatchEventsHub
              ? _buildMatchEventsHub(ref, modeTheme)
              : isComplexeHub
                  ? _buildComplexeSportifHub(ref, modeTheme)
                  : isMarathon
                      ? _buildMatchesContent(ref, modeTheme, 'Marathon')
                      : isTourDeFrance
                          ? _buildMatchesContent(ref, modeTheme, 'Tour de France')
                          : isTennisEvents
                              ? _buildMatchesContent(ref, modeTheme, 'Tennis')
                              : isJO
                                  ? _buildMatchesContent(ref, modeTheme, 'JO 2028')
                                  : isFitness
                      ? _buildAsyncVenuesList(ref, modeTheme, 'fitness')
                      : isBoxeSalles
                          ? _buildAsyncVenuesList(ref, modeTheme, 'boxe')
                          : isFootball
                              ? _buildAsyncVenuesList(ref, modeTheme, 'terrain-football')
                              : isBasketball
                                  ? _buildAsyncVenuesList(ref, modeTheme, 'terrain-basketball')
                                  : isPiscine
                                      ? _buildAsyncVenuesList(ref, modeTheme, 'piscine')
                                      : isGolf
                                          ? _buildAsyncVenuesList(ref, modeTheme, 'golf')
                                          : isRaquetteHub
                                              ? _buildRaquetteHub(ref, modeTheme)
                                              : isRaquetteSub
                                                  ? _buildRacketVenuesList(ref, modeTheme, subcategory)
                                                  : _buildMatchesContent(
                                                      ref,
                                                      modeTheme,
                                                      subcategory == 'Boxe matchs' ? 'Boxe' : subcategory,
                                                    ),
        ),
      ],
    );
  }

  Widget _buildMatchEventsHub(WidgetRef ref, ModeTheme modeTheme) {
    final subcategories = SportCategoryData.matchSubcategories;

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
            ref.watch(sportSubcategoryCountProvider(sub.searchTag));
        return DaySubcategoryCard(
          emoji: '',
          label: sub.label,
          image: sub.image,
          count: countAsync.valueOrNull,
          blink: sub.label == 'A venir',
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              modeTheme.primaryColor,
              modeTheme.primaryDarkColor,
            ],
          ),
          onTap: () {
            ref.read(modeSubcategoriesProvider.notifier).select('sport', sub.searchTag);
          },
        );
      },
    );
  }

  Widget _buildComplexeSportifHub(WidgetRef ref, ModeTheme modeTheme) {
    const subcategories = SportCategoryData.complexeSportifSubcategories;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: subcategories.length,
      itemBuilder: (context, index) {
        final sub = subcategories[index];
        final countAsync =
            ref.watch(sportSubcategoryCountProvider(sub.searchTag));
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
            ref.read(modeSubcategoriesProvider.notifier).select('sport', sub.searchTag);
          },
        );
      },
    );
  }

  Widget _buildMatchesContent(
    WidgetRef ref,
    ModeTheme modeTheme,
    String subcategory,
  ) {
    final matchesAsync = ref.watch(sportMatchesProvider);
    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucun match trouve pour cette categorie',
            icon: Icons.sports,
          );
        }
        if (subcategory == 'A venir') {
          return _buildGroupedMatchesList(matches, modeTheme, ref);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: matches.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: MatchRowCard(match: matches[index]),
          ),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des matchs',
        onRetry: () => ref.invalidate(sportMatchesProvider),
      ),
    );
  }

  Widget _buildGroupedMatchesList(
    List<SupabaseMatch> matches,
    ModeTheme modeTheme,
    WidgetRef ref,
  ) {
    final filter = ref.watch(dateRangeFilterProvider);

    // Group matches by date
    final grouped = <String, List<SupabaseMatch>>{};
    for (final m in matches) {
      final dateKey = m.date.isNotEmpty ? m.date.substring(0, 10) : '';
      final parsed = DateTime.tryParse(dateKey);
      if (parsed != null && !filter.isInRange(parsed)) continue;
      grouped.putIfAbsent(dateKey, () => []).add(m);
    }

    final sortedDates = grouped.keys.toList()..sort();

    final items = <Widget>[];
    for (final dateKey in sortedDates) {
      final matchesForDate = grouped[dateKey]!;
      final parsed = DateTime.tryParse(dateKey);
      final dateLabel = parsed != null
          ? _capitalize(DateFormatter.formatRelative(parsed))
          : dateKey;

      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                dateLabel,
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
                  '${matchesForDate.length}',
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
      for (final match in matchesForDate) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: MatchRowCard(match: match),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        const DateRangeChipBar(),
        const SizedBox(height: 4),
        ...items,
      ],
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // Map searchTag → sport_type pour les sous-types raquette
  static const _raquetteTagToSportType = <String, String>{
    'Tennis': 'tennis',
    'Padel': 'padel',
    'Squash': 'squash',
    'Ping-pong': 'ping-pong',
    'Badminton': 'badminton',
  };

  Widget _buildRaquetteHub(WidgetRef ref, ModeTheme modeTheme) {
    const subs = SportCategoryData.raquetteSubcategories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: subs.length,
        itemBuilder: (context, index) {
          final sub = subs[index];
          final sportType = _raquetteTagToSportType[sub.searchTag];
          final countAsync = sportType != null
              ? ref.watch(sportVenuesProvider(sportType))
              : const AsyncValue<List<CommerceModel>>.data([]);
          final count = countAsync.valueOrNull?.length;
          return DaySubcategoryCard(
            emoji: '',
            label: sub.label,
            image: sub.image,
            count: count,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                modeTheme.primaryColor,
                modeTheme.primaryDarkColor,
              ],
            ),
            onTap: () {
              ref.read(modeSubcategoriesProvider.notifier).select('sport', sub.searchTag);
            },
          );
        },
      ),
    );
  }

  Widget _buildRacketVenuesList(WidgetRef ref, ModeTheme modeTheme, String tag) {
    final sportType = _raquetteTagToSportType[tag] ?? tag.toLowerCase();
    return _buildAsyncVenuesList(ref, modeTheme, sportType);
  }

  Widget _buildAsyncVenuesList(WidgetRef ref, ModeTheme modeTheme, String sportType) {
    final venuesAsync = ref.watch(sportVenuesProvider(sportType));
    return venuesAsync.when(
      data: (venues) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: venues.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FitnessVenueCard(commerce: venues[index]),
        ),
      ),
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des venues',
        onRetry: () => ref.invalidate(sportVenuesProvider(sportType)),
      ),
    );
  }
}
