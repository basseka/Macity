import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/data/sport_category_data.dart';
import 'package:pulz_app/features/sport/presentation/sport_back_button.dart';
import 'package:pulz_app/features/sport/state/sport_matches_provider.dart';

enum MatchHubType { matchs, events }

/// Sous-grille Matchs ou Events selon le hubType.
class MatchEventsHub extends ConsumerWidget {
  const MatchEventsHub({super.key, required this.hubType});

  final MatchHubType hubType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final subcategories = hubType == MatchHubType.matchs
        ? SportCategoryData.matchSubcategories
        : SportCategoryData.eventSubcategories;
    final title = hubType == MatchHubType.matchs ? 'Matchs' : 'Events';

    return Column(
      children: [
        SportBackButton(
          title: title,
          label: 'Categories',
          onBack: () {
            ref.read(modeSubcategoriesProvider.notifier).select('sport', null);
            ref.read(dateRangeFilterProvider.notifier).state = const DateRangeFilter();
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final sub = subcategories[index];
              final countAsync = ref.watch(sportSubcategoryCountProvider(sub.searchTag));
              return DaySubcategoryCard(
                emoji: '', label: sub.label, image: sub.image,
                count: countAsync.valueOrNull,
                blink: sub.label == 'Calendrier',
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
                ),
                onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', sub.searchTag),
              );
            },
          ),
        ),
      ],
    );
  }
}
