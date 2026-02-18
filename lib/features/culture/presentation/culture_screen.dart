import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              modeTheme.primaryColor,
              modeTheme.primaryDarkColor,
            ],
          ),
          onTap: () {
            ref.read(cultureCategoryProvider.notifier).state = sub.searchTag;
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
                  ref.read(cultureCategoryProvider.notifier).state = null;
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
                                          : category == 'Cette Semaine'
                                  ? _buildMuseumEventsList(ref, modeTheme)
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
    final modeTheme = ref.watch(modeThemeProvider);
    const libraries = LibraryVenuesData.venues;
    final items = <Widget>[];

    for (final group in LibraryVenuesData.groupOrder) {
      final groupLibraries =
          libraries.where((l) => l.group == group).toList();
      // Section header
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                group == 'Mediatheques centrales'
                    ? '\uD83D\uDCDA'
                    : '\uD83E\uDD13',
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
                  '${groupLibraries.length}',
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
      for (final lib in groupLibraries) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: LibraryVenueCard(library: lib),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  Widget _buildMonumentVenuesList(WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const monuments = MonumentVenuesData.venues;
    final items = <Widget>[];

    for (final group in MonumentVenuesData.groupOrder) {
      final groupMonuments =
          monuments.where((m) => m.group == group).toList();
      // Section header
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                _monumentGroupEmoji(group),
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
                  '${groupMonuments.length}',
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
      for (final monument in groupMonuments) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: MonumentVenueCard(monument: monument),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  static String _monumentGroupEmoji(String group) {
    switch (group) {
      case 'Hotels particuliers':
        return '\uD83C\uDFDB\uFE0F';
      case 'Urbanisme & vestiges historiques':
        return '\uD83C\uDFF0';
      case 'Autres elements inscrits':
        return '\u26EA';
      default:
        return '\uD83D\uDCCC';
    }
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

  Widget _buildMuseumEventsList(WidgetRef ref, ModeTheme modeTheme) {
    final eventsAsync = ref.watch(cultureMuseumEventsProvider);
    final userEvents = ref.watch(cultureUserEventsProvider);
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty && userEvents.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucun evenement musee a venir',
            icon: Icons.museum,
          );
        }
        return _buildGroupedCultureEventsList([...userEvents, ...events], modeTheme);
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des evenements musees',
        onRetry: () => ref.invalidate(cultureMuseumEventsProvider),
      ),
    );
  }

  Widget _buildGroupedCultureEventsList(
    List<Event> events,
    ModeTheme modeTheme,
  ) {
    // Group events by culture category label (exclude "Autres")
    final grouped = <String, List<Event>>{};
    for (final e in events) {
      final label = _cultureCategoryLabel(e);
      if (label == 'Autres') continue;
      grouped.putIfAbsent(label, () => []).add(e);
    }

    // Ordre d'affichage fixe — toutes les rubriques, même vides
    const displayOrder = [
      'Expositions',
      'Visites guidees',
      'Vernissages',
      'Ateliers',
      'Animations culturelles',
    ];

    final items = <Widget>[];
    for (final key in displayOrder) {
      final eventsForKey = grouped[key] ?? [];
      // Section header
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Text(
                _cultureCategoryEmoji(key),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                key,
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
                  '${eventsForKey.length}',
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
      // Event cards
      for (final event in eventsForKey) {
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
      children: items,
    );
  }

  static String _cultureCategoryLabel(Event e) {
    final cat = e.categorie.toLowerCase();
    final type = e.type.toLowerCase();
    if (cat.contains('exposition') || type.contains('exposition')) {
      return 'Expositions';
    }
    if (cat.contains('visite') || type.contains('visite')) {
      return 'Visites guidees';
    }
    if (cat.contains('vernissage') || type.contains('vernissage')) {
      return 'Vernissages';
    }
    if (cat.contains('atelier') || type.contains('atelier')) {
      return 'Ateliers';
    }
    if (cat.contains('animation') || type.contains('animation')) {
      return 'Animations culturelles';
    }
    return 'Autres';
  }

  static String _cultureCategoryEmoji(String label) {
    switch (label) {
      case 'Expositions':
        return '\uD83D\uDDBC\uFE0F';
      case 'Visites guidees':
        return '\uD83E\uDDED';
      case 'Vernissages':
        return '\uD83C\uDF7E';
      case 'Ateliers':
        return '\uD83C\uDFA8';
      case 'Animations culturelles':
        return '\uD83C\uDFAD';
      default:
        return '\uD83D\uDCCC';
    }
  }

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
