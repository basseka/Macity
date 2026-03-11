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
import 'package:pulz_app/features/family/data/family_category_data.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/family/domain/models/family_venue.dart';
import 'package:pulz_app/features/family/presentation/widgets/family_venue_row_card.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/family/state/family_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';


class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(familyCategoryProvider);

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
    final subcategories = FamilyCategoryData.allSubcategories;

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
            ref.watch(familyCategoryCountProvider(sub.searchTag));
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
            ref.read(modeSubcategoriesProvider.notifier).select('family', sub.searchTag);
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
                    fontSize: 12,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  ref.read(modeSubcategoriesProvider.notifier).select('family', null);
                  ref.read(dateRangeFilterProvider.notifier).state =
                      const DateRangeFilter();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios, size: 14, color: modeTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Categories',
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
          child: category == 'A venir'
              ? _buildGroupedVenues(ref, modeTheme)
              : _buildCategoryVenues(ref, category, modeTheme),
        ),
      ],
    );
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

  Widget _buildGroupedVenues(WidgetRef ref, ModeTheme modeTheme) {
    final groupedAsync = ref.watch(familyAllVenuesGroupedProvider);
    final balmaAsync = ref.watch(balmaEventsProvider);
    return groupedAsync.when(
      data: (grouped) => _buildGroupedVenuesList(
        grouped,
        modeTheme,
        ref,
        balmaEvents: balmaAsync.valueOrNull ?? [],
      ),
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des lieux',
        onRetry: () {
          ref.invalidate(familyAllVenuesGroupedProvider);
          ref.invalidate(balmaEventsProvider);
        },
      ),
    );
  }

  Widget _buildGroupedVenuesList(
    Map<String, List<FamilyVenue>> grouped,
    ModeTheme modeTheme,
    WidgetRef ref, {
    List<Event> balmaEvents = const [],
  }) {
    final filter = ref.watch(dateRangeFilterProvider);
    final subcategories = FamilyCategoryData.allSubcategories
        .where((s) => s.searchTag != 'A venir')
        .toList();
    final userEvents = ref.watch(familyUserEventsProvider);

    final allEvents = [...userEvents, ...balmaEvents].where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      return d == null || filter.isInRange(d);
    }).toList();

    final items = <Widget>[
      const DateRangeChipBar(),
      const SizedBox(height: 4),
    ];

    if (allEvents.isNotEmpty) {
      final dateGrouped = <String, List<Event>>{};
      for (final e in allEvents) {
        final dateKey = e.dateDebut.isNotEmpty ? e.dateDebut.substring(0, 10) : '';
        dateGrouped.putIfAbsent(dateKey, () => []).add(e);
      }
      final sortedDates = dateGrouped.keys.toList()..sort();

      for (final dateKey in sortedDates) {
        final eventsForDate = dateGrouped[dateKey]!;
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
    }

    for (final sub in subcategories) {
      final venues = grouped[sub.searchTag] ?? [];
      if (venues.isEmpty) continue;
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            child: FamilyVenueRowCard(venue: venue),
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
