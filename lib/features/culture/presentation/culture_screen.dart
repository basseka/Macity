import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/community_event_card.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/utils/date_formatter.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/core/widgets/venue_image.dart';
import 'package:pulz_app/features/culture/presentation/culture_hub_grid.dart';
import 'package:pulz_app/features/culture/data/museum_venues_data.dart' show MuseumVenue;
import 'package:pulz_app/features/culture/data/theatre_venues_data.dart' show TheatreVenue;
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

    return Column(
      children: [

        const SizedBox(height: 12),

        Expanded(
          child: selectedCategory == null
              ? const CultureHubGrid()
              : _buildVenueList(context, ref, selectedCategory),
        ),
      ],
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
                    fontSize: 12,
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
                        'Culture',
                        style: TextStyle(
                          color: modeTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
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

  Widget _buildTheatreVenuesList(WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final selectedId = ref.watch(selectedTheatreIdProvider);
    final venuesAsync = ref.watch(theatreVenuesSupabaseProvider);

    return venuesAsync.when(
      data: (theatres) {
        if (selectedId != null) {
          final theatre = theatres.cast<TheatreVenue?>().firstWhere(
            (t) => t!.id == selectedId,
            orElse: () => null,
          );
          if (theatre != null) {
            return _TheatreProgrammation(theatre: theatre);
          }
        }

        if (theatres.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucun theatre trouve',
            icon: Icons.theater_comedy,
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
          itemCount: theatres.length,
          itemBuilder: (context, index) =>
              _TheatreGridCard(theatre: theatres[index]),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des theatres',
        onRetry: () => ref.invalidate(theatreVenuesSupabaseProvider),
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
                  color: Colors.grey.shade600,
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

class _TheatreGridCard extends ConsumerWidget {
  final TheatreVenue theatre;

  const _TheatreGridCard({required this.theatre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final eventsAsync = ref.watch(theatreVenueEventsProvider(theatre.id));
    final eventCount = eventsAsync.whenOrNull(data: (e) => e.length) ?? 0;

    return GestureDetector(
      onTap: () => ref.read(selectedTheatreIdProvider.notifier).state = theatre.id,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VenueImage(imageUrl: theatre.image, defaultAsset: 'assets/images/pochette_theatre.png'),
                  if (theatre.hasOnlineTicket)
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
                  // ── Badge compteur events ──
                  if (eventCount > 0)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: modeTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$eventCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            theatre.name,
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

}

class _TheatreProgrammation extends ConsumerWidget {
  final TheatreVenue theatre;

  const _TheatreProgrammation({required this.theatre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final eventsAsync = ref.watch(theatreVenueEventsProvider(theatre.id));

    return Column(
      children: [
        // Header with theatre image, name, and back button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: VenueImage(imageUrl: theatre.image, defaultAsset: 'assets/images/pochette_theatre.png'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  theatre.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: modeTheme.primaryDarkColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => ref.read(selectedTheatreIdProvider.notifier).state = null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios, size: 14, color: modeTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Theatres',
                        style: TextStyle(
                          color: modeTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Events grid 3 colonnes
        Expanded(
          child: eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucun spectacle a venir',
                  icon: Icons.theater_comedy,
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.6,
                ),
                itemCount: events.length,
                itemBuilder: (context, index) => _TheatreEventCard(
                  event: events[index],
                  theatreImage: theatre.image,
                ),
              );
            },
            loading: () => LoadingIndicator(color: modeTheme.primaryColor),
            error: (error, _) => AppErrorWidget(
              message: 'Erreur lors du chargement de la programmation',
              onRetry: () => ref.invalidate(theatreVenueEventsProvider(theatre.id)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TheatreEventCard extends StatelessWidget {
  final Event event;
  final String theatreImage;

  const _TheatreEventCard({required this.event, required this.theatreImage});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = event.photoPath != null && event.photoPath!.isNotEmpty;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: event.photoPath!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _fallbackImage(),
                errorWidget: (_, __, ___) => _fallbackImage(),
              )
            else
              _fallbackImage(),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.titre,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.datesAffichageHoraires.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        event.datesAffichageHoraires,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withValues(alpha: 0.9),
                          shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return VenueImage(imageUrl: theatreImage, defaultAsset: 'assets/images/pochette_theatre.png');
  }

  void _openDetail(BuildContext context) {
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: event.titre,
        imageAsset: theatreImage.isNotEmpty ? theatreImage : 'assets/images/pochette_theatre.png',
        imageUrl: event.photoPath,
        infos: [
          if (event.descriptifCourt.isNotEmpty)
            DetailInfoItem(Icons.info_outline, event.descriptifCourt),
          if (event.datesAffichageHoraires.isNotEmpty)
            DetailInfoItem(Icons.calendar_today, event.datesAffichageHoraires),
          if (event.lieuNom.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, event.lieuNom),
          if (event.tarifNormal.isNotEmpty)
            DetailInfoItem(Icons.euro, event.tarifNormal),
        ],
        primaryAction: event.reservationUrl.isNotEmpty
            ? DetailAction(
                icon: Icons.confirmation_number_outlined,
                label: 'Billetterie',
                url: event.reservationUrl,
              )
            : null,
        shareText: '${event.titre}\n${event.datesAffichageHoraires}\n${event.lieuNom}\n\nDecouvre sur MaCity',
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
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
                            child: Icon(Icons.share_outlined, color: Colors.grey.shade400, size: 16),
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
