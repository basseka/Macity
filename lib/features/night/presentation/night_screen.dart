import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';

import 'package:pulz_app/core/widgets/community_event_card.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/night/presentation/night_hub_grid.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

class NightScreen extends ConsumerWidget {
  const NightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(nightCategoryProvider);

    return Column(
      children: [

        const SizedBox(height: 12),

        Expanded(
          child: selectedCategory == null
              ? const NightHubGrid()
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
                    fontSize: 12,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  ref.read(modeSubcategoriesProvider.notifier).select('night', null);
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
              ? _buildUserEventsList(context, ref)
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

  Widget _buildUserEventsList(BuildContext context, WidgetRef ref) {
    final userEvents = ref.watch(nightUserEventsProvider);
    final scrapedAsync = ref.watch(nightScrapedEventsProvider);
    final modeTheme = ref.watch(modeThemeProvider);
    final filter = ref.watch(dateRangeFilterProvider);

    // Filtre : uniquement les events a venir (>= aujourd'hui) + filtre temporel.
    bool isInRange(Event e) {
      final d = DateTime.tryParse(e.dateDebut);
      return d != null && filter.isInRange(d);
    }

    final scrapedEvents = (scrapedAsync.valueOrNull ?? []).where(isInRange).toList();
    final allEvents = <Event>[
      ...userEvents.where(isInRange),
      ...scrapedEvents,
    ];
    // Trier par date.
    allEvents.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    // Afficher un loader seulement si pas encore d'events du tout.
    if (allEvents.isEmpty && scrapedAsync.isLoading) {
      return LoadingIndicator(color: modeTheme.primaryColor);
    }

    if (allEvents.isEmpty) {
      return const Column(
        children: [
          DateRangeChipBar(),
          Expanded(
            child: EmptyStateWidget(
              message: 'Aucun evenement pour le moment.\nAjoute un evenement avec le bouton +',
              icon: Icons.nightlife,
            ),
          ),
        ],
      );
    }
    return _buildDateGroupedEventsList(allEvents, modeTheme, context);
  }

  Widget _buildDateGroupedEventsList(List<Event> events, ModeTheme modeTheme, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final grouped = <DateTime, List<Event>>{};
    for (final e in events) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) continue;
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
              onTap: () => EventFullscreenPopup.show(
                context, event, 'assets/images/pochette_default.png',
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
