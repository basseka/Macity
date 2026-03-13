import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/core/utils/date_formatter.dart';
import 'package:pulz_app/features/day/data/day_category_data.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/day/presentation/widgets/fete_musique_map_view.dart';
import 'package:pulz_app/features/day/state/day_events_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';


class DayScreen extends ConsumerWidget {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSubcategory = ref.watch(selectedDaySubcategoryProvider);
    final selectedVenue = ref.watch(selectedConcertVenueProvider);
    final selectedDjsetVenue = ref.watch(selectedDjsetVenueProvider);
    final selectedSpectacleVenue = ref.watch(selectedSpectacleVenueProvider);

    Widget content;
    if (selectedSubcategory == null) {
      content = _buildSubcategoryGrid(context, ref);
    } else if (selectedSubcategory == 'Concert' && selectedVenue == null) {
      content = _buildVenueGrid(context, ref);
    } else if (selectedSubcategory == 'Concert' && selectedVenue != null) {
      content = _buildVenueEventsList(context, ref, selectedVenue);
    } else if (selectedSubcategory == 'DJ set' && selectedDjsetVenue == null) {
      content = _buildDjsetVenueGrid(context, ref);
    } else if (selectedSubcategory == 'DJ set' && selectedDjsetVenue != null) {
      content = _buildDjsetVenueEventsList(context, ref, selectedDjsetVenue);
    } else if (selectedSubcategory == 'Spectacle' && selectedSpectacleVenue == null) {
      content = _buildSpectacleVenueGrid(context, ref);
    } else if (selectedSubcategory == 'Spectacle' && selectedSpectacleVenue != null) {
      content = _buildSpectacleVenueEventsList(context, ref, selectedSpectacleVenue);
    } else if (selectedSubcategory == 'Fete musique') {
      content = _buildFeteMusiqueMap(context, ref);
    } else {
      content = _buildEventsList(context, ref, selectedSubcategory);
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildSubcategoryGrid(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final subcategories = DayCategoryData.subcategories;

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
            ref.watch(daySubcategoryCountProvider(sub.searchTag));
        final isFeteMusique = sub.searchTag == 'Fete musique';
        return DaySubcategoryCard(
          emoji: '',
          label: sub.label,
          image: sub.image,
          count: isFeteMusique ? null : countAsync.valueOrNull,
          blink: false,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              modeTheme.primaryColor,
              modeTheme.primaryDarkColor,
            ],
          ),
          onTap: () {
                    ref.read(selectedConcertVenueProvider.notifier).state = null;
                    ref.read(selectedDjsetVenueProvider.notifier).state = null;
                    ref.read(selectedSpectacleVenueProvider.notifier).state = null;
                    ref.read(modeSubcategoriesProvider.notifier).select('day', sub.searchTag);
                  },
        );
      },
    );
  }

  Widget _buildVenueGrid(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const venues = DayCategoryData.concertVenues;

    return Column(
      children: [
        // Back to subcategories
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Concert',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildBackButton(ref, modeTheme, onTap: () {
                ref.read(modeSubcategoriesProvider.notifier).select('day', null);
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: venues.length,
            itemBuilder: (context, index) {
              final venue = venues[index];
              final countAsync =
                  ref.watch(concertVenueCountProvider(venue.searchKeyword));
              return DaySubcategoryCard(
                emoji: '',
                label: venue.label,
                image: venue.image,
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
                  ref.read(selectedConcertVenueProvider.notifier).state =
                      venue.searchKeyword;
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVenueEventsList(
    BuildContext context,
    WidgetRef ref,
    String venueKeyword,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final eventsAsync = ref.watch(dayVenueEventsProvider);

    // Find venue label for display
    final venue = DayCategoryData.concertVenues.firstWhere(
      (v) => v.searchKeyword == venueKeyword,
      orElse: () => DayCategoryData.concertVenues.first,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  venue.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildBackButton(ref, modeTheme, onTap: () {
                ref.read(selectedConcertVenueProvider.notifier).state = null;
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucun evenement trouve pour cette salle',
                  icon: Icons.event_busy,
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
              message: 'Erreur lors du chargement des evenements',
              onRetry: () => ref.invalidate(dayVenueEventsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDjsetVenueGrid(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const venues = DayCategoryData.djsetVenues;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'DJ Set',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildBackButton(ref, modeTheme, onTap: () {
                ref.read(modeSubcategoriesProvider.notifier).select('day', null);
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: venues.length,
            itemBuilder: (context, index) {
              final venue = venues[index];
              final countAsync =
                  ref.watch(djsetVenueCountProvider(venue.searchKeyword));
              return DaySubcategoryCard(
                emoji: '',
                label: venue.label,
                image: venue.image,
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
                  ref.read(selectedDjsetVenueProvider.notifier).state =
                      venue.searchKeyword;
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpectacleVenueGrid(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const venues = DayCategoryData.spectacleVenues;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Spectacle',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildBackButton(ref, modeTheme, onTap: () {
                ref.read(modeSubcategoriesProvider.notifier).select('day', null);
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: venues.length,
            itemBuilder: (context, index) {
              final venue = venues[index];
              final countAsync =
                  ref.watch(spectacleVenueCountProvider(venue.searchKeyword));
              return DaySubcategoryCard(
                emoji: '',
                label: venue.label,
                image: venue.image,
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
                  ref.read(selectedSpectacleVenueProvider.notifier).state =
                      venue.searchKeyword;
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpectacleVenueEventsList(
    BuildContext context,
    WidgetRef ref,
    String venueKeyword,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final eventsAsync = ref.watch(daySpectacleVenueEventsProvider);

    final venue = DayCategoryData.spectacleVenues.firstWhere(
      (v) => v.searchKeyword == venueKeyword,
      orElse: () => DayCategoryData.spectacleVenues.first,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  venue.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildBackButton(ref, modeTheme, onTap: () {
                ref.read(selectedSpectacleVenueProvider.notifier).state = null;
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucun evenement trouve pour cette salle',
                  icon: Icons.event_busy,
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
              message: 'Erreur lors du chargement des evenements',
              onRetry: () => ref.invalidate(daySpectacleVenueEventsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDjsetVenueEventsList(
    BuildContext context,
    WidgetRef ref,
    String venueKeyword,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final eventsAsync = ref.watch(dayDjsetVenueEventsProvider);

    final venue = DayCategoryData.djsetVenues.firstWhere(
      (v) => v.searchKeyword == venueKeyword,
      orElse: () => DayCategoryData.djsetVenues.first,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  venue.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildBackButton(ref, modeTheme, onTap: () {
                ref.read(selectedDjsetVenueProvider.notifier).state = null;
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucun evenement trouve pour cette salle',
                  icon: Icons.event_busy,
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
              message: 'Erreur lors du chargement des evenements',
              onRetry: () => ref.invalidate(dayDjsetVenueEventsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(WidgetRef ref, ModeTheme modeTheme, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
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
              'Retour',
              style: TextStyle(
                color: modeTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeteMusiqueMap(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ref.read(modeSubcategoriesProvider.notifier).select('day', null);
      },
      child: const FeteMusiqueMapView(),
    );
  }

  Widget _buildEventsList(
    BuildContext context,
    WidgetRef ref,
    String subcategory,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final eventsAsync = ref.watch(dayEventsProvider);

    return Column(
      children: [
        // Back to subcategories
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subcategory,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildBackButton(ref, modeTheme, onTap: () {
                ref.read(modeSubcategoriesProvider.notifier).select('day', null);
                ref.read(dateRangeFilterProvider.notifier).state =
                    const DateRangeFilter();
              }),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Events list
        Expanded(
          child: eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucun evenement trouve pour cette categorie',
                  icon: Icons.event_busy,
                );
              }
              if (subcategory == 'A venir') {
                return _buildGroupedEventsList(events, modeTheme, ref);
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
              message: 'Erreur lors du chargement des evenements',
              onRetry: () => ref.invalidate(dayEventsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedEventsList(List<Event> events, ModeTheme modeTheme, WidgetRef ref) {
    final filter = ref.watch(dateRangeFilterProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Filtrer et grouper par jour
    final dayGroups = <DateTime, List<Event>>{};
    for (final e in events) {
      final label = _categoryLabel(e);
      if (label == 'Autres') continue;
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) continue;
      final dateOnly = DateTime(d.year, d.month, d.day);
      if (!filter.isInRange(dateOnly)) continue;
      dayGroups.putIfAbsent(dateOnly, () => []).add(e);
    }

    if (dayGroups.isEmpty) {
      return const EmptyStateWidget(
        message: 'Aucun evenement trouve',
        icon: Icons.event_busy,
      );
    }

    final sortedDays = dayGroups.keys.toList()..sort();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: CustomScrollView(
        slivers: [
          for (final day in sortedDays) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day == today
                                ? "Aujourd'hui"
                                : day == tomorrow
                                    ? 'Demain'
                                    : _capitalize(DateFormat('EEEE', 'fr_FR').format(day)),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE d MMMM', 'fr_FR').format(day),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E8C).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dayGroups[day]!.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE91E8C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _EventGridTile(event: dayGroups[day]![index]),
                  childCount: dayGroups[day]!.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _categoryLabel(Event e) {
    final cat = e.categorie.toLowerCase();
    final type = e.type.toLowerCase();
    if (cat.contains('concert') || type.contains('concert')) return 'Concerts';
    if (cat.contains('festival') || type.contains('festival')) return 'Festivals';
    if (cat.contains('opera') || type.contains('opera')) return 'Opera';
    if (cat.contains('spectacle') || type.contains('spectacle')) return 'Spectacles';
    if (cat.contains('dj') || type.contains('dj')) return 'DJ Sets';
    if (cat.contains('showcase') || type.contains('showcase')) return 'Showcases';
    return 'Autres';
  }
}

// ── Grid tile style Instagram (identique au TodayEventsSheet) ──
class _EventGridTile extends StatelessWidget {
  final Event event;

  const _EventGridTile({required this.event});

  static const _categoryImages = <String, String>{
    'concert': 'assets/images/pochette_concert.png',
    'festival': 'assets/images/pochette_festival.png',
    'opera': 'assets/images/pochette_spectacle.png',
    'spectacle': 'assets/images/pochette_spectacle.png',
    'theatre': 'assets/images/pochette_theatre.png',
    'dj': 'assets/images/pochette_discotheque.png',
    'showcase': 'assets/images/pochette_concert.png',
  };

  String _resolvePochette() {
    final cat = event.categorie.toLowerCase();
    final type = event.type.toLowerCase();
    for (final entry in _categoryImages.entries) {
      if (cat.contains(entry.key) || type.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'assets/images/pochette_concert.png';
  }

  @override
  Widget build(BuildContext context) {
    final hasNet = event.photoPath != null &&
        event.photoPath!.isNotEmpty &&
        event.photoPath!.startsWith('http');
    final pochette = _resolvePochette();
    final parsed = DateTime.tryParse(event.dateDebut);
    final dateLabel = parsed != null ? DateFormat('dd/MM', 'fr_FR').format(parsed) : '';

    return GestureDetector(
      onTap: () => EventFullscreenPopup.show(context, event, pochette),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (hasNet)
            CachedNetworkImage(
              imageUrl: event.photoPath!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Image.asset(pochette, fit: BoxFit.cover),
              errorWidget: (_, __, ___) => Image.asset(pochette, fit: BoxFit.cover),
            )
          else
            Image.asset(
              pochette,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
            ),

          // Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),

          // Badge
          if (event.isFree)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E8C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'GRATUIT',
                  style: GoogleFonts.poppins(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Titre + date
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.titre,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    dateLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: Colors.white60,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
