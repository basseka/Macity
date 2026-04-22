import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
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
import 'package:pulz_app/features/gaming/data/gaming_category_data.dart';
import 'package:pulz_app/features/gaming/presentation/gaming_hub_grid.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/gaming/state/gaming_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';


class GamingScreen extends ConsumerWidget {
  const GamingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(gamingCategoryProvider);

    return Column(
      children: [

        const SizedBox(height: 12),

        Expanded(
          child: selectedCategory == null
              ? const GamingHubGrid()
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
    final venuesAsync = ref.watch(gamingVenuesProvider);

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
                  ref.read(modeSubcategoriesProvider.notifier).select('gaming', null);
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
              ? _buildGroupedVenues(context, ref, modeTheme)
              : venuesAsync.when(
                  data: (venues) {
                    if (venues.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'Aucun lieu trouve pour cette categorie',
                        icon: Icons.sports_esports,
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
                  loading: () =>
                      LoadingIndicator(color: modeTheme.primaryColor),
                  error: (error, _) => AppErrorWidget(
                    message: 'Erreur lors du chargement des lieux',
                    onRetry: () => ref.invalidate(gamingVenuesProvider),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildGroupedVenues(BuildContext context, WidgetRef ref, ModeTheme modeTheme) {
    final groupedAsync = ref.watch(gamingGroupedVenuesProvider);
    return groupedAsync.when(
      data: (grouped) => _buildGroupedVenuesList(context, grouped, modeTheme, ref),
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des lieux',
        onRetry: () => ref.invalidate(gamingGroupedVenuesProvider),
      ),
    );
  }

  Widget _buildGroupedVenuesList(
    BuildContext context,
    Map<String, List<CommerceModel>> grouped,
    ModeTheme modeTheme,
    WidgetRef ref,
  ) {
    final filter = ref.watch(dateRangeFilterProvider);
    final subcategories = GamingCategoryData.allSubcategories
        .where((s) => s.searchTag != 'A venir')
        .toList();
    final userEvents = ref.watch(gamingUserEventsProvider).where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      return d == null || filter.isInRange(d);
    }).toList();

    final items = <Widget>[
      const DateRangeChipBar(),
      const SizedBox(height: 4),
    ];

    // User events grouped by date
    if (userEvents.isNotEmpty) {
      final dateGrouped = <String, List<Event>>{};
      for (final e in userEvents) {
        final dateKey = e.dateDebut.isNotEmpty ? e.dateDebut.substring(0, 10) : '';
        dateGrouped.putIfAbsent(dateKey, () => []).add(e);
      }
      final sortedDates = dateGrouped.keys.toList()..sort();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      for (final dateKey in sortedDates) {
        final eventsForDate = dateGrouped[dateKey]!;
        final parsed = DateTime.tryParse(dateKey);
        String dateLabel;
        if (parsed != null) {
          final d = DateTime(parsed.year, parsed.month, parsed.day);
          if (d == today) {
            dateLabel = "Aujourd'hui";
          } else if (d == tomorrow) {
            dateLabel = 'Demain';
          } else {
            dateLabel = _capitalize(
              DateFormat('EEEE d MMMM', 'fr_FR').format(parsed),
            );
          }
        } else {
          dateLabel = dateKey;
        }

        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDim,
              ),
            ),
          ),
        );
        for (final event in eventsForDate) {
          items.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: CommunityEventCard(
                title: event.titre,
                date: event.dateDebut,
                time: event.horaires,
                location: event.lieuNom,
                photoUrl: event.photoPath,
                tag: event.categorie.isNotEmpty ? event.categorie : null,
                isFree: event.isFree,
                hasVideo: event.videoUrl != null && event.videoUrl!.isNotEmpty,
                onTap: () => EventFullscreenPopup.show(context, event, 'assets/images/pochette_default.jpg'),
              ),
            ),
          );
        }
      }
    }

    for (final sub in subcategories) {
      final venues = grouped[sub.searchTag] ?? [];
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            child: CommerceRowCard(commerce: venue),
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
