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
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/culture/data/culture_category_data.dart';
import 'package:pulz_app/features/culture/data/gallery_venues_data.dart';
import 'package:pulz_app/features/culture/data/library_venues_data.dart';
import 'package:pulz_app/features/culture/data/monument_venues_data.dart';
import 'package:pulz_app/features/culture/data/museum_venues_data.dart';
import 'package:pulz_app/features/culture/data/dance_venues_data.dart';
import 'package:pulz_app/features/culture/data/theatre_venues_data.dart';
import 'package:pulz_app/features/culture/presentation/widgets/dance_venue_card.dart';
import 'package:pulz_app/features/culture/presentation/widgets/library_venue_card.dart';
import 'package:pulz_app/features/culture/presentation/widgets/monument_venue_card.dart';
import 'package:pulz_app/features/culture/presentation/widgets/museum_venue_card.dart';
import 'package:pulz_app/features/culture/presentation/widgets/theatre_venue_card.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/culture/state/culture_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';


class CultureScreen extends ConsumerWidget {
  const CultureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(cultureCategoryProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    return Column(
      children: [

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
    final subcategories = CultureCategoryData.allSubcategories;

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
            ref.watch(cultureCategoryCountProvider(sub.searchTag));
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
            ref.read(modeSubcategoriesProvider.notifier).select('culture', sub.searchTag);
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

    return Column(
      children: [
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
                  ref.read(modeSubcategoriesProvider.notifier).select('culture', null);
                  ref.read(dateRangeFilterProvider.notifier).state =
                      const DateRangeFilter();
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
          child: category == 'Musee'
              ? _buildMuseumVenuesList(ref)
              : category == 'Theatre'
                  ? _buildTheatreVenuesList(ref)
                  : category == 'Danse'
                      ? _buildDanceVenuesList(ref)
                      : category == "Galerie d'art"
                          ? _buildGalleryVenuesList()
                          : category == 'Monument historique'
                              ? _buildMonumentVenuesList(ref)
                              : category == 'Bibliotheque'
                                  ? _buildLibraryVenuesList(ref)
                                  : category == 'Visites guidees'
                                      ? _buildGuidedToursList(ref, modeTheme)
                                      : category == 'Exposition'
                                          ? _buildMeettEventsList(ref, modeTheme)
                                          : category == 'A venir'
                                  ? _buildCetteSemaineEventsList(ref, modeTheme)
                                  : _buildCommerceVenuesList(ref, modeTheme),
        ),
      ],
    );
  }

  Widget _buildMuseumVenuesList(WidgetRef ref) {
    const museums = MuseumVenuesData.venues;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: museums.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: MuseumVenueCard(museum: museums[index]),
      ),
    );
  }

  Widget _buildTheatreVenuesList(WidgetRef ref) {
    const theatres = TheatreVenuesData.venues;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: theatres.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TheatreVenueCard(theatre: theatres[index]),
      ),
    );
  }

  Widget _buildDanceVenuesList(WidgetRef ref) {
    const dances = DanceVenuesData.venues;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dances.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DanceVenueCard(dance: dances[index]),
      ),
    );
  }

  Widget _buildGalleryVenuesList() {
    const galleries = GalleryVenuesData.venues;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: galleries.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: CommerceRowCard(commerce: galleries[index]),
      ),
    );
  }

  Widget _buildLibraryVenuesList(WidgetRef ref) {
    const libraries = LibraryVenuesData.venues;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: libraries.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: LibraryVenueCard(library: libraries[index]),
      ),
    );
  }

  Widget _buildMonumentVenuesList(WidgetRef ref) {
    const monuments = MonumentVenuesData.venues;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: monuments.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: MonumentVenueCard(monument: monuments[index]),
      ),
    );
  }

  Widget _buildGuidedToursList(WidgetRef ref, ModeTheme modeTheme) {
    final eventsAsync = ref.watch(cultureGuidedToursProvider);
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucune visite guidee a venir',
            icon: Icons.tour,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: events.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EventRowCard(event: events[index]),
          ),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des visites guidees',
        onRetry: () => ref.invalidate(cultureGuidedToursProvider),
      ),
    );
  }

  Widget _buildMeettEventsList(WidgetRef ref, ModeTheme modeTheme) {
    final eventsAsync = ref.watch(cultureMeettEventsProvider);
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucune exposition a venir',
            icon: Icons.art_track,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: events.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EventRowCard(event: events[index]),
          ),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des expositions',
        onRetry: () => ref.invalidate(cultureMeettEventsProvider),
      ),
    );
  }

  Widget _buildCetteSemaineEventsList(WidgetRef ref, ModeTheme modeTheme) {
    final museumAsync = ref.watch(cultureMuseumEventsProvider);
    final theatreState = ref.watch(cultureTheatreEventsProgressiveProvider);
    final userEvents = ref.watch(cultureUserEventsProvider);

    return museumAsync.when(
      data: (museumEvents) {
        final allEvents = [
          ...userEvents,
          ...museumEvents,
          ...theatreState.events,
        ];
        if (allEvents.isEmpty && theatreState.isLoading) {
          return LoadingIndicator(color: modeTheme.primaryColor);
        }
        if (allEvents.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucun evenement culturel a venir',
            icon: Icons.event,
          );
        }
        return Column(
          children: [
            Expanded(
              child: _buildGroupedCultureEventsList(allEvents, modeTheme, ref),
            ),
            if (theatreState.isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: modeTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des evenements culturels',
        onRetry: () {
          ref.invalidate(cultureMuseumEventsProvider);
          ref.invalidate(cultureTheatreEventsProvider);
        },
      ),
    );
  }

  Widget _buildGroupedCultureEventsList(
    List<Event> events,
    ModeTheme modeTheme,
    WidgetRef ref,
  ) {
    final filter = ref.watch(dateRangeFilterProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group events by date
    final grouped = <String, List<Event>>{};
    for (final e in events) {
      final dateKey = e.dateDebut.isNotEmpty ? e.dateDebut.substring(0, 10) : '';
      final parsed = DateTime.tryParse(dateKey);
      if (parsed != null && !filter.isInRange(parsed)) continue;
      // Filtrer les evenements passes
      final fin = DateTime.tryParse(e.dateFin) ?? parsed;
      if (fin != null && fin.isBefore(today)) continue;
      grouped.putIfAbsent(dateKey, () => []).add(e);
    }

    final sortedDates = grouped.keys.toList()..sort();

    final items = <Widget>[];
    for (final dateKey in sortedDates) {
      final eventsForDate = grouped[dateKey]!;
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
                  '${eventsForDate.length}',
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
      for (final event in eventsForDate) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: EventRowCard(event: event),
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

  Widget _buildCommerceVenuesList(WidgetRef ref, ModeTheme modeTheme) {
    final venuesAsync = ref.watch(cultureVenuesProvider);
    return venuesAsync.when(
      data: (venues) {
        if (venues.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucun lieu culturel trouve pour cette categorie',
            icon: Icons.museum,
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
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des lieux culturels',
        onRetry: () => ref.invalidate(cultureVenuesProvider),
      ),
    );
  }
}
