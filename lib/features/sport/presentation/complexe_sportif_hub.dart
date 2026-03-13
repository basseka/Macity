import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/data/sport_category_data.dart';
import 'package:pulz_app/features/sport/presentation/sport_back_button.dart';
import 'package:pulz_app/features/sport/state/sport_matches_provider.dart';

/// Sous-grille Complexe sportif : Fitness, Boxe, Piscine, etc.
class ComplexeSportifHub extends ConsumerWidget {
  const ComplexeSportifHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    const subcategories = SportCategoryData.complexeSportifSubcategories;

    return Column(
      children: [
        SportBackButton(
          title: 'Complexe',
          label: 'Sport',
          onBack: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', null),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final sub = subcategories[index];
              final countAsync = ref.watch(sportSubcategoryCountProvider(sub.searchTag));
              return DaySubcategoryCard(
                emoji: '', label: sub.label, image: sub.image,
                count: countAsync.valueOrNull,
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
