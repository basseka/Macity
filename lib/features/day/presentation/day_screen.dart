import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/domain/models/app_category.dart';
import 'package:pulz_app/core/state/categories_provider.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/community_event_card.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/fete_musique_map_view.dart';
import 'package:pulz_app/features/day/state/day_events_provider.dart';
import 'package:pulz_app/features/day/presentation/shared_with_me_sheet.dart';
import 'package:pulz_app/features/day/state/shared_events_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

class DayScreen extends ConsumerWidget {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSubcategory = ref.watch(selectedDaySubcategoryProvider);
    final selectedVenue = ref.watch(selectedConcertVenueProvider);

    Widget content;
    if (selectedSubcategory == null) {
      content = _buildSubcategoryGrid(context, ref);
    } else if (selectedSubcategory == 'Fete musique') {
      content = _buildFeteMusiqueMap(context, ref);
    } else if (selectedVenue != null) {
      content = _buildVenueEventsList(context, ref, selectedVenue, selectedSubcategory);
    } else {
      // Vérifie si cette catégorie a des venues enfants
      final childrenAsync = ref.watch(
        groupChildrenProvider((mode: 'day', groupe: selectedSubcategory)),
      );
      content = childrenAsync.when(
        data: (children) {
          if (children.isNotEmpty) {
            return _buildVenueGrid(context, ref, selectedSubcategory, children);
          }
          return _buildEventsList(context, ref, selectedSubcategory);
        },
        loading: () => LoadingIndicator(color: ref.watch(modeThemeProvider).primaryColor),
        error: (_, __) => _buildEventsList(context, ref, selectedSubcategory),
      );
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
    final catsAsync = ref.watch(modeRootCategoriesProvider('day'));

    return catsAsync.when(
      data: (subcategories) {
        final others = subcategories.where((c) => c.searchTag != 'A venir').toList();
        final hasAvenir = subcategories.any((c) => c.searchTag == 'A venir');
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
        );

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (hasAvenir) ...[
              _DayAvenirBanner(gradient: gradient, ref: ref),
              const SizedBox(height: 14),
            ],
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemCount: others.length,
              itemBuilder: (context, index) {
                final sub = others[index];
                final isFeteMusique = sub.searchTag == 'Fete musique';
                final countAsync =
                    ref.watch(daySubcategoryCountProvider(sub.searchTag));
                return DaySubcategoryCard(
                  emoji: '',
                  label: sub.label,
                  image: sub.imageUrl.isNotEmpty ? sub.imageUrl : null,
                  count: isFeteMusique ? null : countAsync.valueOrNull,
                  blink: false,
                  isScraped: true,
                  gradient: gradient,
                  onTap: () {
                    ref.read(selectedConcertVenueProvider.notifier).state = null;
                    ref.read(modeSubcategoriesProvider.notifier).select('day', sub.searchTag);
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des categories',
        onRetry: () => ref.invalidate(modeRootCategoriesProvider('day')),
      ),
    );
  }

  Widget _buildVenueGrid(
    BuildContext context,
    WidgetRef ref,
    String subcategory,
    List<AppCategory> venues,
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
              final keyword = venue.meta('venue_keyword') ?? venue.searchTag;
              final countAsync = ref.watch(concertVenueCountProvider(keyword));
              return DaySubcategoryCard(
                emoji: '',
                label: venue.label,
                image: venue.imageUrl.isNotEmpty ? venue.imageUrl : null,
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
                  ref.read(selectedConcertVenueProvider.notifier).state = keyword;
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
    String subcategory,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final eventsAsync = ref.watch(dayVenueEventsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  venueKeyword,
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: events.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
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
      child: FeteMusiqueMapView(ville: ref.watch(selectedCityProvider)),
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
                return _buildGroupedEventsList(context, events, modeTheme, ref);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: events.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
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

  Widget _buildGroupedEventsList(BuildContext context, List<Event> events, ModeTheme modeTheme, WidgetRef ref) {
    final filter = ref.watch(dateRangeFilterProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final filtered = events.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) return false;
      return filter.isInRange(DateTime(d.year, d.month, d.day));
    }).toList()
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        message: 'Aucun evenement trouve',
        icon: Icons.event_busy,
      );
    }

    // Group by date
    final grouped = <DateTime, List<Event>>{};
    for (final e in filtered) {
      final d = DateTime.tryParse(e.dateDebut)!;
      final dateOnly = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(dateOnly, () => []).add(e);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return ListView(
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
              style: GoogleFonts.inter(
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
                context, event, 'assets/images/pochette_concert.png',
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _DayAvenirBanner extends StatelessWidget {
  final LinearGradient gradient;
  final WidgetRef ref;

  const _DayAvenirBanner({required this.gradient, required this.ref});

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(daySubcategoryCountProvider('A venir')).valueOrNull;

    return GestureDetector(
      onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('day', 'A venir'),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/pochette_cettesemaine.jpg',
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, size: 10, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A venir',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (count != null && count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedWithMeBanner extends ConsumerWidget {
  final WidgetRef ref;
  const _SharedWithMeBanner({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedAsync = ref.watch(sharedWithMeProvider);
    final count = sharedAsync.valueOrNull?.length ?? 0;

    // Ne pas afficher si aucun event partage ou en cours de chargement
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => SharedWithMeSheet.show(context),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Partages avec moi',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
