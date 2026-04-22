import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/tourisme/presentation/tourisme_hub_grid.dart';
import 'package:pulz_app/features/tourisme/state/touristic_points_provider.dart';
import 'package:pulz_app/features/sport/presentation/widgets/venues_map_view.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/tourisme/presentation/metro_tramway_map.dart';
import 'package:pulz_app/features/tourisme/presentation/transport_info_sheet.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/tourisme/state/city_tourisme_tips_provider.dart';
import 'package:pulz_app/features/home/presentation/sheets/top_picks_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class TourismeScreen extends ConsumerWidget {
  const TourismeScreen({super.key});

  static const _visiterChildren = {
    'Monument', 'Musee', 'Attraction', 'Site naturel',
    'Place', 'Lieu culturel', 'Office de tourisme', 'Quartier',
    // Legacy Toulouse
    'City tour', 'Tuk-tuk', 'Petit Train',
    'La maison de la violette', 'Le Canal',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(tourismeCategoryProvider);

    // Carte interactive plein ecran pour "Plan touristique"
    if (selectedCategory == 'Plan touristique') {
      return _buildTourismeMap(context, ref, selectedCategory!);
    }

    // Se deplacer → infos transport de la ville
    if (selectedCategory == 'Se deplacer') {
      final city = ref.watch(selectedCityProvider);
      if (city == 'Toulouse') {
        return _buildMetroTramwayMap(context, ref);
      }
      return _buildTransportView(context, ref);
    }

    // Hub "Visiter" → sous-cartes
    if (selectedCategory == 'Visiter') {
      return _buildVisiterHub(context, ref);
    }

    // Sous-carte de Visiter selectionnee
    if (selectedCategory != null && _visiterChildren.contains(selectedCategory)) {
      return _buildCategoryContent(context, ref, selectedCategory);
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        // Bouton Top incontournables
        if (selectedCategory == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => TopPicksSheet.show(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6A817), Color(0xFFE91E8C)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE6A817).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('\u2B50', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      'Top incontournables',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (selectedCategory == null) const SizedBox(height: 8),
        Expanded(
          child: selectedCategory == null
              ? const TourismeHubGrid()
              : _buildCategoryContent(context, ref, selectedCategory),
        ),
      ],
    );
  }

  Widget _buildTourismeMap(BuildContext context, WidgetRef ref, String title) {
    final modeTheme = ref.watch(modeThemeProvider);
    final pointsAsync = ref.watch(allTouristicPointsProvider);
    final showLabels = title == 'Plan touristique';

    return pointsAsync.when(
      data: (points) {
        final filtered = points.where((p) => p.categorie != 'Lieu culturel').toList();
        return Stack(
        children: [
          VenuesMapView(
            venues: filtered,
            title: title,
            accentColor: '#0284C7',
            autoLocate: false,
            initialZoom: 16,
            showLabels: showLabels,
            categoryIcons: const {
              'Monument': '\u{1F3DB}\u{FE0F}',
              'Musee': '\u{1F3A8}',
              'Place': '\u{26F2}',
              'Site naturel': '\u{1F333}',
              'Quartier': '\u{1F3D8}\u{FE0F}',
              'Metro A': '\u{1F7E5}',
              'Metro B': '\u{1F7E6}',
            },
            categoryColors: const {
              'Monument': '#D97706',
            },
          ),
          // Bouton retour
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: () {
                ref.read(modeSubcategoriesProvider.notifier).select('tourisme', null);
                ref.read(dateRangeFilterProvider.notifier).state =
                    const DateRangeFilter();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
          ),
        ],
      );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => const Center(
        child: EmptyStateWidget(
          message: 'Erreur de chargement',
          icon: Icons.error_outline,
        ),
      ),
    );
  }

  Widget _buildMetroTramwayMap(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    return Stack(
      children: [
        const MetroTramwayMap(),
        // Bouton retour
        Positioned(
          top: 12,
          left: 12,
          child: GestureDetector(
            onTap: () {
              ref.read(modeSubcategoriesProvider.notifier).select('tourisme', null);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
        ),
        // Bouton Tisseo
        Positioned(
          top: 12,
          right: 60,
          child: GestureDetector(
            onTap: () => launchUrl(Uri.parse('https://www.tisseo.fr/'), mode: LaunchMode.externalApplication),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3051B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_bus, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Tisseo.fr',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Images par categorie touristique
  static const _categoryImages = <String, String>{
    'Monument': 'assets/images/pochette_monument.jpg',
    'Musee': 'assets/images/pochette_musee.png',
    'Attraction': 'assets/images/pochette_visite.png',
    'Site naturel': 'assets/images/pochette_tourisme_toulouse.png',
    'Place': 'assets/images/pochette_tourisme_toulouse.png',
    'Lieu culturel': 'assets/images/pochette_culture_art.png',
    'Office de tourisme': 'assets/images/pochette_tourime.png',
  };

  Widget _buildVisiterHub(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final pointsAsync = ref.watch(allTouristicPointsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Visiter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: modeTheme.primaryDarkColor),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('tourisme', null),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios, size: 14, color: modeTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text('Categories', style: TextStyle(color: modeTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: pointsAsync.when(
            data: (points) {
              // Extraire les categories uniques avec leur count
              final catCounts = <String, int>{};
              for (final p in points) {
                catCounts[p.categorie] = (catCounts[p.categorie] ?? 0) + 1;
              }
              // Exclure Metro/Tram
              catCounts.remove('Metro A');
              catCounts.remove('Metro B');
              catCounts.remove('Tram');

              if (catCounts.isEmpty) {
                return const EmptyStateWidget(message: 'Aucun lieu a visiter', icon: Icons.travel_explore);
              }

              final categories = catCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.1,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final image = _categoryImages[cat.key] ?? 'assets/images/pochette_visite.png';
                  return DaySubcategoryCard(
                    emoji: '',
                    label: '${cat.key} (${cat.value})',
                    image: image,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
                    ),
                    onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('tourisme', cat.key),
                  );
                },
              );
            },
            loading: () => LoadingIndicator(color: modeTheme.primaryColor),
            error: (_, __) => const EmptyStateWidget(message: 'Erreur', icon: Icons.error_outline),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryContent(
    BuildContext context,
    WidgetRef ref,
    String category,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final isVisiterChild = _visiterChildren.contains(category);
    final backLabel = isVisiterChild ? 'Visiter' : 'Categories';

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
                  if (isVisiterChild) {
                    ref.read(modeSubcategoriesProvider.notifier).select('tourisme', 'Visiter');
                  } else {
                    ref.read(modeSubcategoriesProvider.notifier).select('tourisme', null);
                    ref.read(dateRangeFilterProvider.notifier).state =
                        const DateRangeFilter();
                  }
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
                        backLabel,
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
          child: _buildPointsList(ref, category),
        ),
      ],
    );
  }

  Widget _buildTransportView(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Se deplacer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: modeTheme.primaryDarkColor),
                ),
              ),
              InkWell(
                onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('tourisme', null),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios, size: 14, color: modeTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text('Categories', style: TextStyle(color: modeTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Expanded(child: TransportInfoView()),
      ],
    );
  }

  Widget _buildPointsList(WidgetRef ref, String category) {
    // "Activites" → tips IA depuis city_tourisme_tips
    if (category == 'Activites') {
      return _buildTipsView(ref);
    }
    final pointsAsync = ref.watch(touristicPointsProvider(category));
    final modeTheme = ref.watch(modeThemeProvider);

    return pointsAsync.when(
      data: (points) {
        if (points.isEmpty) {
          return const EmptyStateWidget(
            message: 'Aucun lieu trouve',
            icon: Icons.travel_explore,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: points.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => CommerceRowCard(commerce: points[i]),
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (_, __) => const EmptyStateWidget(message: 'Erreur de chargement', icon: Icons.error_outline),
    );
  }

  Widget _buildTipsView(WidgetRef ref) {
    final tipsAsync = ref.watch(cityTourismeTipsProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    return tipsAsync.when(
      data: (tips) {
        if (tips.isEmpty) {
          return const EmptyStateWidget(message: 'Aucune activite trouvee', icon: Icons.travel_explore);
        }

        // Grouper par categorie
        final grouped = <String, List<TipItem>>{};
        for (final t in tips) {
          grouped.putIfAbsent(t.category, () => []).add(t);
        }

        final categoryEmojis = {
          'activite': '\u{1F3AF}',
          'gastronomie': '\u{1F37D}\u{FE0F}',
          'quartier': '\u{1F3D8}\u{FE0F}',
          'excursion': '\u{1F697}',
          'bon_plan': '\u{2B50}',
          'transport': '\u{1F68C}',
        };

        final categoryLabels = {
          'activite': 'A faire',
          'gastronomie': 'Gastronomie',
          'quartier': 'Quartiers',
          'excursion': 'Excursions',
          'bon_plan': 'Bons plans',
          'transport': 'Se deplacer',
        };

        final order = ['activite', 'gastronomie', 'quartier', 'excursion', 'bon_plan', 'transport'];

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final cat in order)
              if (grouped.containsKey(cat)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(categoryEmojis[cat] ?? '', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      categoryLabels[cat] ?? cat,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: modeTheme.primaryDarkColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final tip in grouped[cat]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: modeTheme.primaryDarkColor)),
                          const SizedBox(height: 4),
                          Text(tip.description, style: TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
              ],
            const SizedBox(height: 20),
          ],
        );
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (_, __) => const EmptyStateWidget(message: 'Erreur', icon: Icons.error_outline),
    );
  }
}
