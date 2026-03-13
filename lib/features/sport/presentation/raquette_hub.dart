import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/data/sport_category_data.dart';
import 'package:pulz_app/features/sport/presentation/sport_back_button.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';

/// Sous-grille Raquette : Tennis, Padel, Squash, Ping-pong, Badminton.
class RaquetteHub extends ConsumerWidget {
  const RaquetteHub({super.key});

  static const _tagToSportType = <String, String>{
    'Tennis': 'tennis',
    'Padel': 'padel',
    'Squash': 'squash',
    'Ping-pong': 'ping-pong',
    'Badminton': 'badminton',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const subs = SportCategoryData.raquetteSubcategories;

    return Column(
      children: [
        SportBackButton(
          title: 'Raquette',
          label: 'Sport',
          onBack: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', null),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: subs.length,
              itemBuilder: (context, index) {
                final sub = subs[index];
                final sportType = _tagToSportType[sub.searchTag];
                final countAsync = sportType != null
                    ? ref.watch(sportVenuesProvider(sportType))
                    : const AsyncValue.data([]);
                final count = countAsync.valueOrNull?.length;
                return DaySubcategoryCard(
                  emoji: '',
                  label: sub.label,
                  image: sub.image,
                  count: count,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
                  ),
                  onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', sub.searchTag),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
