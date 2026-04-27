import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/community_event_card.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_masthead.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/core/widgets/venue_image.dart';
import 'package:pulz_app/features/culture/presentation/culture_hub_grid.dart';
import 'package:pulz_app/features/culture/data/museum_venues_data.dart' show MuseumVenue;
import 'package:pulz_app/features/culture/presentation/widgets/dance_venue_card.dart';
import 'package:pulz_app/features/culture/presentation/widgets/library_venue_card.dart';
import 'package:pulz_app/features/culture/presentation/widgets/monument_venue_card.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/culture/state/culture_venues_provider.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';


class CultureScreen extends ConsumerWidget {
  const CultureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(cultureCategoryProvider);

    return Container(
      color: EditorialColors.ink,
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: EditorialMasthead(
              kicker: selectedCategory == null
                  ? 'Rubrique · Cite'
                  : 'Culture · $selectedCategory',
              title: selectedCategory ?? 'Culture',
              accent: RubricColors.culture,
              blurb: selectedCategory == null
                  ? 'Cinema, theatre, expositions, danse — l\'agenda culturel.'
                  : null,
              onBack: selectedCategory == null
                  ? () => context.go('/explorer')
                  : () {
                      ref
                          .read(modeSubcategoriesProvider.notifier)
                          .select('culture', null);
                      ref.read(dateRangeFilterProvider.notifier).state =
                          const DateRangeFilter();
                    },
            ),
          ),
        ],
        body: selectedCategory == null
            ? const CultureHubGrid()
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

    return Column(
      children: [
        Expanded(
          child: category == 'Musee'
              ? _buildMuseumVenuesList(ref)
              : category == 'Theatre'
                  ? _buildTheatreVenuesList(ref)
                  : category == 'Danse'
                      ? _buildDanceVenuesList(ref, modeTheme)
                      : category == "Galerie d'art"
                          ? _buildGalleryVenuesList(ref, modeTheme)
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
    final modeTheme = ref.watch(modeThemeProvider);
    final venuesAsync = ref.watch(museumVenuesSupabaseProvider);

    return venuesAsync.when(
      data: (museums) {
        if (museums.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucun musee trouve',
            icon: Icons.museum,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemCount: museums.length,
          itemBuilder: (context, index) =>
              _MuseumGridCard(museum: museums[index]),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des musees',
        onRetry: () => ref.invalidate(museumVenuesSupabaseProvider),
      ),
    );
  }

  // Liste plate de tous les events theatre + bouton "Filtrer par salle"
  // (meme pattern que Concert/Spectacle/DJ Set dans le mode Day).
  Widget _buildTheatreVenuesList(WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final selectedVenue = ref.watch(selectedTheatreVenueProvider);
    final eventsState = ref.watch(cultureTheatreEventsProgressiveProvider);
    final events = eventsState.events;

    if (eventsState.isLoading && events.isEmpty) {
      return Center(child: LoadingIndicator(color: modeTheme.primaryColor));
    }
    if (events.isEmpty) {
      return const EmptyStateWidget(
        message: 'Aucun evenement theatre a venir',
        icon: Icons.theater_comedy,
      );
    }

    final filtered = selectedVenue == null
        ? events
        : events.where((e) => e.lieuNom == selectedVenue).toList();

    return Column(
      children: [
        _TheatreFilterBar(
          selectedVenue: selectedVenue,
          accent: modeTheme.primaryColor,
          onTap: () => _showTheatreVenueFilterSheet(
            ref, events, selectedVenue, modeTheme.primaryColor,
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyStateWidget(
                  message: 'Aucun evenement pour ce filtre',
                  icon: Icons.event_busy,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EventRowCard(event: filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  void _showTheatreVenueFilterSheet(
    WidgetRef ref,
    List<Event> events,
    String? currentSelection,
    Color accent,
  ) {
    final byVenue = <String, int>{};
    for (final e in events) {
      if (e.lieuNom.isEmpty) continue;
      byVenue[e.lieuNom] = (byVenue[e.lieuNom] ?? 0) + 1;
    }
    final venues = byVenue.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        if (c != 0) return c;
        return a.key.compareTo(b.key);
      });

    showModalBottomSheet<void>(
      context: ref.context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: EditorialColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 6),
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: EditorialColors.dividerStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                child: Row(
                  children: [
                    const Text(
                      '✦',
                      style: TextStyle(color: EditorialColors.magenta, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Filtrer par salle',
                      style: TextStyle(
                        color: EditorialColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (currentSelection != null)
                      GestureDetector(
                        onTap: () {
                          ref.read(selectedTheatreVenueProvider.notifier).state = null;
                          Navigator.of(sheetCtx).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Effacer',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: EditorialColors.dividerSoft),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: EdgeInsets.zero,
                  itemCount: venues.length + 1,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: EditorialColors.dividerSoft,
                    indent: 20,
                    endIndent: 20,
                  ),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _TheatreVenueRow(
                        label: 'Toutes les salles',
                        count: events.length,
                        selected: currentSelection == null,
                        accent: accent,
                        onTap: () {
                          ref.read(selectedTheatreVenueProvider.notifier).state = null;
                          Navigator.of(sheetCtx).pop();
                        },
                      );
                    }
                    final entry = venues[i - 1];
                    return _TheatreVenueRow(
                      label: entry.key,
                      count: entry.value,
                      selected: currentSelection == entry.key,
                      accent: accent,
                      onTap: () {
                        ref.read(selectedTheatreVenueProvider.notifier).state = entry.key;
                        Navigator.of(sheetCtx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDanceVenuesList(WidgetRef ref, ModeTheme modeTheme) {
    final venuesAsync = ref.watch(danceVenuesProvider);
    return venuesAsync.when(
      data: (venues) {
        if (venues.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucune salle de danse trouvee',
            icon: Icons.music_note,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: venues.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DanceVenueCard(dance: venues[index]),
          ),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des salles de danse',
        onRetry: () => ref.invalidate(danceVenuesProvider),
      ),
    );
  }

  Widget _buildGalleryVenuesList(WidgetRef ref, ModeTheme modeTheme) {
    final venuesAsync = ref.watch(galleryVenuesSupabaseProvider);

    return venuesAsync.when(
      data: (galleries) {
        if (galleries.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucune galerie trouvee',
            icon: Icons.palette,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: galleries.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GalleryCard(gallery: galleries[index]),
          ),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des galeries',
        onRetry: () => ref.invalidate(galleryVenuesSupabaseProvider),
      ),
    );
  }

  Widget _buildLibraryVenuesList(WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final venuesAsync = ref.watch(libraryVenuesSupabaseProvider);

    return venuesAsync.when(
      data: (libraries) {
        if (libraries.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucune bibliotheque trouvee',
            icon: Icons.local_library,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: libraries.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LibraryVenueCard(library: libraries[index]),
          ),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des bibliotheques',
        onRetry: () => ref.invalidate(libraryVenuesSupabaseProvider),
      ),
    );
  }

  Widget _buildMonumentVenuesList(WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final venuesAsync = ref.watch(monumentVenuesSupabaseProvider);

    return venuesAsync.when(
      data: (monuments) {
        if (monuments.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucun monument trouve',
            icon: Icons.account_balance,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: monuments.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MonumentVenueCard(monument: monuments[index]),
          ),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des monuments',
        onRetry: () => ref.invalidate(monumentVenuesSupabaseProvider),
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
    final spectacleAsync = ref.watch(cultureSpectacleEventsProvider);
    final userEvents = ref.watch(cultureUserEventsProvider);

    return museumAsync.when(
      data: (museumEvents) {
        final spectacleEvents = spectacleAsync.valueOrNull ?? [];
        final allEvents = [
          ...userEvents,
          ...museumEvents,
          ...theatreState.events,
          ...spectacleEvents,
        ];
        if (allEvents.isEmpty && (theatreState.isLoading || spectacleAsync.isLoading)) {
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
    final tomorrow = today.add(const Duration(days: 1));

    final grouped = <DateTime, List<Event>>{};
    for (final e in events) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) continue;
      final dateOnly = DateTime(d.year, d.month, d.day);
      if (!filter.isInRange(dateOnly)) continue;
      final fin = DateTime.tryParse(e.dateFin) ?? d;
      if (fin.isBefore(today)) continue;
      grouped.putIfAbsent(dateOnly, () => []).add(e);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return Builder(
      builder: (context) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const DateRangeChipBar(),
          const SizedBox(height: 8),
          for (final day in sortedDays) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                day == today
                    ? "Aujourd'hui"
                    : day == tomorrow
                        ? 'Demain'
                        : _capitalize(DateFormat('EEEE d MMMM', 'fr_FR').format(day)),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDim,
                ),
              ),
            ),
            for (final event in grouped[day]!) ...[
              CommunityEventCard(
                title: event.titre,
                date: event.dateDebut,
                time: event.horaires,
                location: event.lieuNom,
                photoUrl: event.photoPath,
                tag: event.categorie.isNotEmpty ? event.categorie : null,
                isFree: event.isFree,
                hasVideo: event.videoUrl != null && event.videoUrl!.isNotEmpty,
                onTap: () => EventFullscreenPopup.show(
                  context, event, 'assets/images/pochette_culture_art.png',
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
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

class _TheatreFilterBar extends StatelessWidget {
  final String? selectedVenue;
  final Color accent;
  final VoidCallback onTap;

  const _TheatreFilterBar({
    required this.selectedVenue,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selectedVenue != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.12)
                : EditorialColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? accent : EditorialColors.dividerSoft,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 14, color: active ? accent : EditorialColors.textDim),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  active ? selectedVenue! : 'Filtrer par salle',
                  style: TextStyle(
                    color: active ? accent : EditorialColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                active ? Icons.close : Icons.expand_more,
                size: 14,
                color: active ? accent : EditorialColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TheatreVenueRow extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _TheatreVenueRow({
    required this.label,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? accent : EditorialColors.text,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                color: selected ? accent : EditorialColors.textDim,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check, size: 14, color: accent),
            ],
          ],
        ),
      ),
    );
  }
}

class _MuseumGridCard extends ConsumerWidget {
  final MuseumVenue museum;

  const _MuseumGridCard({required this.museum});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VenueImage(imageUrl: museum.image, defaultAsset: 'assets/images/pochette_musee.png'),
                  if (museum.hasOnlineTicket)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BILLETS',
                          style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            museum.name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: modeTheme.primaryDarkColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: museum.name,
        emoji: '',
        imageAsset: museum.image,
        infos: [
          if (museum.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, museum.description),
          if (museum.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, museum.horaires),
          if (museum.city.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, museum.city),
        ],
        primaryAction: museum.websiteUrl.isNotEmpty
            ? DetailAction(icon: Icons.language, label: 'Site web', url: museum.websiteUrl)
            : null,
        shareText: '${museum.name}\n${museum.description}\n${museum.city}\n${museum.websiteUrl}\n\nDecouvre sur MaCity',
      ),
    );
  }
}

class _GalleryCard extends ConsumerWidget {
  final CommerceModel gallery;

  const _GalleryCard({required this.gallery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final image = gallery.photo.isNotEmpty
        ? gallery.photo
        : 'assets/images/pochette_culture_art.png';

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: VenueImage(imageUrl: image),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gallery.nom,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: modeTheme.primaryDarkColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (gallery.horaires.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 13, color: modeTheme.primaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                gallery.horaires,
                                style: TextStyle(fontSize: 11, color: AppColors.textDim),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (gallery.siteWeb.isNotEmpty)
                            GestureDetector(
                              onTap: () => _openUrl(gallery.siteWeb),
                              child: Icon(Icons.language, color: modeTheme.primaryColor, size: 16),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _share(),
                            child: Icon(Icons.share_outlined, color: AppColors.textFaint, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    final image = gallery.photo.isNotEmpty
        ? gallery.photo
        : 'assets/images/pochette_culture_art.png';
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: gallery.nom,
        emoji: '',
        imageAsset: image,
        infos: [
          if (gallery.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, gallery.horaires),
          if (gallery.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, gallery.adresse),
          if (gallery.telephone.isNotEmpty)
            DetailInfoItem(Icons.phone_outlined, gallery.telephone),
        ],
        primaryAction: gallery.siteWeb.isNotEmpty
            ? DetailAction(icon: Icons.language, label: 'Site web', url: gallery.siteWeb)
            : null,
        secondaryActions: [
          if (gallery.lienMaps.isNotEmpty)
            DetailAction(icon: Icons.map_outlined, label: 'Maps', url: gallery.lienMaps),
          if (gallery.telephone.isNotEmpty)
            DetailAction(
              icon: Icons.phone_outlined,
              label: 'Appeler',
              url: 'tel:${gallery.telephone.replaceAll(' ', '')}',
            ),
        ],
        shareText: '${gallery.nom}\n${gallery.adresse}\n${gallery.horaires}\n${gallery.siteWeb}\n\nDecouvre sur MaCity',
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _share() {
    final buffer = StringBuffer();
    buffer.writeln(gallery.nom);
    if (gallery.adresse.isNotEmpty) buffer.writeln(gallery.adresse);
    if (gallery.horaires.isNotEmpty) buffer.writeln(gallery.horaires);
    if (gallery.siteWeb.isNotEmpty) buffer.writeln(gallery.siteWeb);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
