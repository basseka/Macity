import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';

import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/sport/data/fitness_venues_data.dart';
import 'package:pulz_app/features/sport/data/sport_category_data.dart';
import 'package:pulz_app/features/sport/presentation/widgets/fitness_venue_card.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/presentation/widgets/match_row_card.dart';
import 'package:pulz_app/features/sport/state/sport_matches_provider.dart';

class SportScreen extends ConsumerWidget {
  const SportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSubcategory = ref.watch(sportSubcategoryProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    return Column(
      children: [

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              modeTheme.subtitleString,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: selectedSubcategory == null
              ? _buildSubcategoryGrid(context, ref)
              : _buildMatchList(context, ref, selectedSubcategory),
        ),
      ],
    );
  }

  Widget _buildSubcategoryGrid(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final subcategories = SportCategoryData.allSubcategories;

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
            ref.watch(sportSubcategoryCountProvider(sub.searchTag));
        return DaySubcategoryCard(
          emoji: '',
          label: sub.label,
          image: sub.image,
          count: countAsync.valueOrNull,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              modeTheme.primaryColor,
              modeTheme.primaryDarkColor,
            ],
          ),
          onTap: () {
            ref.read(sportSubcategoryProvider.notifier).state = sub.searchTag;
          },
        );
      },
    );
  }

  Widget _buildMatchList(
    BuildContext context,
    WidgetRef ref,
    String subcategory,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final isFitness = subcategory == 'Salle de fitness';

    return Column(
      children: [
        // Back button row
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
                  ref.read(sportSubcategoryProvider.notifier).state = null;
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

        Expanded(
          child: isFitness
              ? _buildFitnessVenuesList()
              : _buildMatchesContent(ref, modeTheme, subcategory),
        ),
      ],
    );
  }

  Widget _buildMatchesContent(
    WidgetRef ref,
    ModeTheme modeTheme,
    String subcategory,
  ) {
    final matchesAsync = ref.watch(sportMatchesProvider);
    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucun match trouve pour cette categorie',
            icon: Icons.sports,
          );
        }
        if (subcategory == 'Cette Semaine') {
          return _buildGroupedMatchesList(matches, modeTheme);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: matches.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MatchRowCard(match: matches[index]),
          ),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des matchs',
        onRetry: () => ref.invalidate(sportMatchesProvider),
      ),
    );
  }

  Widget _buildGroupedMatchesList(
    List<SupabaseMatch> matches,
    ModeTheme modeTheme,
  ) {
    // Group by sport label (exclude "Autres")
    final grouped = <String, List<SupabaseMatch>>{};
    for (final m in matches) {
      final label = _sportLabel(m);
      if (label == 'Autres') continue;
      grouped.putIfAbsent(label, () => []).add(m);
    }

    // Ordre d'affichage fixe — toutes les rubriques, même vides
    const displayOrder = [
      'Rugby',
      'Football',
      'Basketball',
      'Handball',
      'Boxe',
      'Natation',
      'Course a pied',
    ];

    final items = <Widget>[];
    for (final key in displayOrder) {
      final matchesForKey = grouped[key] ?? [];
      // Section header
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Text(
                _sportEmoji(key),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                key,
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
                  '${matchesForKey.length}',
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
      // Match cards
      for (final match in matchesForKey) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: MatchRowCard(match: match),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  static String _sportLabel(SupabaseMatch m) {
    final s = m.sport.toLowerCase();
    if (s.contains('rugby')) return 'Rugby';
    if (s.contains('football')) return 'Football';
    if (s.contains('basket')) return 'Basketball';
    if (s.contains('handball') || s.contains('hand')) return 'Handball';
    if (s.contains('boxe')) return 'Boxe';
    if (s.contains('natation')) return 'Natation';
    if (s.contains('course')) return 'Course a pied';
    return 'Autres';
  }

  static String _sportEmoji(String label) {
    switch (label) {
      case 'Rugby':
        return '\uD83C\uDFC9';
      case 'Football':
        return '\u26BD';
      case 'Basketball':
        return '\uD83C\uDFC0';
      case 'Handball':
        return '\uD83E\uDD3E';
      case 'Boxe':
        return '\uD83E\uDD4A';
      case 'Natation':
        return '\uD83C\uDFCA';
      case 'Course a pied':
        return '\uD83C\uDFC3';
      default:
        return '\uD83C\uDFC6';
    }
  }

  Widget _buildFitnessVenuesList() {
    final venues = FitnessVenuesData.venues;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: venues.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FitnessVenueCard(commerce: venues[index]),
      ),
    );
  }
}
