import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/utils/date_formatter.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';

import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/night/data/night_category_data.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';

class NightScreen extends ConsumerWidget {
  const NightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(nightCategoryProvider);
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
    final subcategories = NightCategoryData.allSubcategories;

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
            ref.watch(nightCategoryCountProvider(sub.searchTag));
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
            ref.read(nightCategoryProvider.notifier).state = sub.searchTag;
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
    final venuesAsync = ref.watch(nightVenuesProvider);

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
                  ref.read(nightCategoryProvider.notifier).state = null;
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
          child: category == 'A venir'
              ? _buildUserEventsList(ref)
              : venuesAsync.when(
                  data: (venues) {
                    // Filter matching user events for this subcategory
                    final matchingEvents = ref.watch(nightUserEventsProvider).where((e) {
                      final cat = e.categorie.toLowerCase();
                      final tag = category.toLowerCase();
                      return cat.contains(tag) || tag.contains(cat);
                    }).toList();

                    if (venues.isEmpty && matchingEvents.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'Aucun commerce trouve pour cette categorie',
                        icon: Icons.nightlife,
                      );
                    }
                    final items = <Widget>[
                      ...matchingEvents.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EventRowCard(event: e),
                      )),
                      ...venues.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CommerceRowCard(commerce: v),
                      )),
                    ];
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: items,
                    );
                  },
                  loading: () =>
                      LoadingIndicator(color: modeTheme.primaryColor),
                  error: (error, _) => AppErrorWidget(
                    message: 'Erreur lors du chargement des commerces',
                    onRetry: () => ref.invalidate(nightVenuesProvider),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserEventsList(WidgetRef ref) {
    final userEvents = ref.watch(nightUserEventsProvider);
    final nineClubAsync = ref.watch(nineClubEventsProvider);
    final etoileAsync = ref.watch(etoileEventsProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    // Filtre J+7 glissant.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(const Duration(days: 7));
    bool isThisWeek(Event e) {
      final d = DateTime.tryParse(e.dateDebut);
      return d != null && !d.isBefore(today) && d.isBefore(limit);
    }

    final scrapedEvents = <Event>[
      ...nineClubAsync.valueOrNull ?? [],
      ...etoileAsync.valueOrNull ?? [],
    ].where(isThisWeek).toList();
    final allEvents = <Event>[
      ...userEvents.where(isThisWeek),
      ...scrapedEvents,
    ];
    // Trier par date.
    allEvents.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    // Afficher un loader seulement si pas encore d'events du tout.
    final isLoading = nineClubAsync.isLoading || etoileAsync.isLoading;
    if (allEvents.isEmpty && isLoading) {
      return LoadingIndicator(color: modeTheme.primaryColor);
    }

    if (allEvents.isEmpty) {
      return const EmptyStateWidget(
        message: 'Aucun evenement pour le moment.\nAjoute un evenement avec le bouton +',
        icon: Icons.nightlife,
      );
    }
    return _buildDateGroupedEventsList(allEvents, modeTheme);
  }

  Widget _buildDateGroupedEventsList(List<Event> events, ModeTheme modeTheme) {
    final grouped = <String, List<Event>>{};
    for (final e in events) {
      final dateKey = e.dateDebut.isNotEmpty ? e.dateDebut.substring(0, 10) : '';
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
              const Text('\uD83D\uDCC5', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      children: items,
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
