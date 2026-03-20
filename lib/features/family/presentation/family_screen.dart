import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/utils/date_formatter.dart';
import 'package:pulz_app/core/widgets/community_event_card.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/family/data/family_category_data.dart';
import 'package:pulz_app/features/family/presentation/family_hub_grid.dart';
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
              ? const FamilyHubGrid()
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
              ? _buildGroupedVenues(context, ref, modeTheme)
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

  Widget _buildGroupedVenues(BuildContext context, WidgetRef ref, ModeTheme modeTheme) {
    final userEvents = ref.watch(familyUserEventsProvider);
    final filter = ref.watch(dateRangeFilterProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Uniquement les events communautaires a venir
    final filtered = userEvents.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) return false;
      final dateOnly = DateTime(d.year, d.month, d.day);
      if (dateOnly.isBefore(today)) return false;
      return filter.isInRange(dateOnly);
    }).toList()
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        message: 'Aucun evenement communautaire pour le moment',
        icon: Icons.family_restroom,
      );
    }

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
              onTap: () => EventFullscreenPopup.show(context, event, 'assets/images/pochette_default.png'),
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
