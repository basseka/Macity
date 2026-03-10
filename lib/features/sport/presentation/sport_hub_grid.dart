import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

/// Grille d'accueil Sport (niveau 0) : Match/Events, Complexe, Marathon, etc.
class SportHubGrid extends ConsumerWidget {
  const SportHubGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.1,
        children: [
          DaySubcategoryCard(
            emoji: '', label: 'Matchs',
            image: 'assets/images/pochette_matchs.png',
            gradient: gradient,
            onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Matchs'),
          ),
          DaySubcategoryCard(
            emoji: '', label: 'Events',
            image: 'assets/images/home_bg_sport.png',
            gradient: gradient,
            onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Events'),
          ),
          DaySubcategoryCard(
            emoji: '', label: 'Complexe sportif',
            image: 'assets/images/shell_sport_fitness.png',
            gradient: gradient,
            onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Complexe sportif'),
          ),
          DaySubcategoryCard(
            emoji: '', label: 'Marathon de Toulouse ${DateTime.now().year}',
            image: 'assets/images/pochette_course.png',
            gradient: gradient,
            onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Marathon'),
          ),
          DaySubcategoryCard(
            emoji: '', label: 'Tour de France ${DateTime.now().year}',
            image: 'assets/images/pochette_tourdefrance.png',
            gradient: gradient,
            onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Tour de France'),
          ),
          DaySubcategoryCard(
            emoji: '', label: 'Tennis',
            image: 'assets/images/pochette_tennis.png',
            gradient: gradient,
            onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', 'Tennis events'),
          ),
          DaySubcategoryCard(
            emoji: '', label: 'JO 2028',
            image: 'assets/images/pochette_JO.png',
            gradient: gradient,
            onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', 'JO 2028'),
          ),
        ],
      ),
    );
  }
}
