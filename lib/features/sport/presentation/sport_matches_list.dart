import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/utils/date_formatter.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/presentation/sport_back_button.dart';
import 'package:pulz_app/features/sport/presentation/widgets/match_row_card.dart';
import 'package:pulz_app/features/sport/state/sport_matches_provider.dart';

/// Liste de matchs pour une sous-categorie donnee.
class SportMatchesList extends ConsumerWidget {
  final String subcategory;

  const SportMatchesList({super.key, required this.subcategory});

  static const _matchsChildren = {
    'Rugby', 'Football', 'Basketball', 'Handball',
  };

  static const _eventsChildren = {
    'A venir', 'Boxe', 'Natation', 'Courses a pied', 'Stage de danse', 'Boxe matchs',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final matchesAsync = ref.watch(sportMatchesProvider);

    final String backLabel;
    final VoidCallback onBack;

    if (_matchsChildren.contains(subcategory)) {
      backLabel = 'Matchs';
      onBack = () {
        ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Matchs');
        ref.read(dateRangeFilterProvider.notifier).state = const DateRangeFilter();
      };
    } else if (_eventsChildren.contains(subcategory)) {
      backLabel = 'Events';
      onBack = () {
        ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Events');
        ref.read(dateRangeFilterProvider.notifier).state = const DateRangeFilter();
      };
    } else {
      backLabel = 'Categories';
      onBack = () {
        ref.read(modeSubcategoriesProvider.notifier).select('sport', null);
        ref.read(dateRangeFilterProvider.notifier).state = const DateRangeFilter();
      };
    }

    final displayTitle = subcategory == 'Boxe matchs'
        ? 'Gala / Matchs'
        : subcategory == 'Tennis events'
            ? 'Tennis'
            : subcategory == 'Tour de France'
                ? 'Tour de France ${DateTime.now().year}'
                : subcategory == 'JO 2028'
                    ? 'JO 2028'
                    : subcategory;

    return Column(
      children: [
        SportBackButton(
          title: displayTitle,
          label: backLabel,
          onBack: onBack,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: matchesAsync.when(
            data: (matches) {
              if (matches.isEmpty) {
                return const EmptyStateWidget(
                  message: 'Aucun match trouve pour cette categorie',
                  icon: Icons.sports,
                );
              }
              if (subcategory == 'A venir') {
                return _buildGroupedList(matches, modeTheme, ref);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: matches.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: MatchRowCard(match: matches[index]),
                ),
              );
            },
            loading: () => LoadingIndicator(color: modeTheme.primaryColor),
            error: (error, _) => AppErrorWidget(
              message: 'Erreur lors du chargement des matchs',
              onRetry: () => ref.invalidate(sportMatchesProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedList(List<SupabaseMatch> matches, dynamic modeTheme, WidgetRef ref) {
    final filter = ref.watch(dateRangeFilterProvider);
    final grouped = <String, List<SupabaseMatch>>{};

    for (final m in matches) {
      final dateKey = m.date.isNotEmpty ? m.date.substring(0, 10) : '';
      final parsed = DateTime.tryParse(dateKey);
      if (parsed != null && !filter.isInRange(parsed)) continue;
      grouped.putIfAbsent(dateKey, () => []).add(m);
    }

    final sortedDates = grouped.keys.toList()..sort();
    final items = <Widget>[];

    for (final dateKey in sortedDates) {
      final matchesForDate = grouped[dateKey]!;
      final parsed = DateTime.tryParse(dateKey);
      final dateLabel = parsed != null
          ? _capitalize(DateFormatter.formatRelative(parsed))
          : dateKey;

      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(dateLabel, style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15,
                color: modeTheme.primaryDarkColor,
              )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: modeTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${matchesForDate.length}', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: modeTheme.primaryColor,
                )),
              ),
            ],
          ),
        ),
      );
      for (final match in matchesForDate) {
        items.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: MatchRowCard(match: match),
        ));
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
}
