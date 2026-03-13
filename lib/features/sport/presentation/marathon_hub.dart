import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/presentation/sport_back_button.dart';

/// Sous-grille Marathon : Marathon, Semi, 10K, Relais, Enfants.
class MarathonHub extends ConsumerWidget {
  const MarathonHub({super.key});

  static const _races = [
    ('Marathon', 'Marathon info'),
    ('Semi-Marathon', 'Semi-Marathon info'),
    ('10K', '10K info'),
    ('Marathon relais', 'Marathon relais info'),
    ('Course Enfants', 'Course Enfants info'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
    );

    return Column(
      children: [
        SportBackButton(
          title: 'Marathon de Toulouse ${DateTime.now().year}',
          label: 'Sport',
          onBack: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', null),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.1,
              children: [
                for (final (label, tag) in _races)
                  DaySubcategoryCard(
                    emoji: '',
                    label: label,
                    image: 'assets/images/pochette_course.png',
                    gradient: gradient,
                    onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', tag),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
