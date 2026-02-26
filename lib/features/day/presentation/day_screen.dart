import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/core/utils/date_formatter.dart';
import 'package:pulz_app/features/day/data/day_category_data.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/day/state/day_events_provider.dart';
import 'package:pulz_app/features/day/state/day_subcategory_provider.dart';


class DayScreen extends ConsumerWidget {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSubcategory = ref.watch(selectedDaySubcategoryProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    return Column(
      children: [

        const SizedBox(height: 12),

        // Content
        Expanded(
          child: selectedSubcategory == null
              ? _buildSubcategoryGrid(context, ref)
              : _buildEventsList(context, ref, selectedSubcategory),
        ),
      ],
    );
  }

  Widget _buildSubcategoryGrid(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const subcategories = DayCategoryData.subcategories;

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
            ref.watch(daySubcategoryCountProvider(sub.searchTag));
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
            ref.read(selectedDaySubcategoryProvider.notifier).state =
                sub.searchTag;
            ref.read(daySubcategoryProvider.notifier).state =
                sub.searchTag;
          },
        );
      },
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
                    fontSize: 16,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  ref.read(selectedDaySubcategoryProvider.notifier).state =
                      null;
                  ref.read(daySubcategoryProvider.notifier).state = null;
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
                        'Retour',
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

    // Group events by date
    final grouped = <String, List<Event>>{};
    for (final e in events) {
      final label = _categoryLabel(e);
      if (label == 'Autres') continue;
      final dateKey = e.dateDebut.isNotEmpty ? e.dateDebut.substring(0, 10) : '';
      final parsed = DateTime.tryParse(dateKey);
      if (parsed != null && !filter.isInRange(parsed)) continue;
      grouped.putIfAbsent(dateKey, () => []).add(e);
    }

    // Sort date keys chronologically
    final sortedDates = grouped.keys.toList()..sort();

    final items = <Widget>[];
    for (final dateKey in sortedDates) {
      final eventsForDate = grouped[dateKey]!;
      final parsed = DateTime.tryParse(dateKey);
      final dateLabel = parsed != null
          ? _capitalize(DateFormatter.formatRelative(parsed))
          : dateKey;

      // Date section header
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
      // Event cards for this date
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
