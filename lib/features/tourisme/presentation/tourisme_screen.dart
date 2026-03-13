import 'package:flutter/material.dart';
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
import 'package:url_launcher/url_launcher.dart';

class TourismeScreen extends ConsumerWidget {
  const TourismeScreen({super.key});

  static const _visiterChildren = {
    'City tour',
    'Tuk-tuk',
    'Petit Train',
    'La maison de la violette',
    'Le Canal',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(tourismeCategoryProvider);

    // Carte interactive plein ecran pour "Plan touristique"
    if (selectedCategory == 'Plan touristique') {
      return _buildTourismeMap(context, ref, selectedCategory!);
    }

    // Se deplacer → carte Metro & Tramway plein ecran
    if (selectedCategory == 'Se deplacer') {
      return _buildMetroTramwayMap(context, ref);
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

  Widget _buildVisiterHub(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

    const visiterCards = [
      ('City tour', 'assets/images/pochette_tourisme_toulouse.png'),
      ('Tuk-tuk', 'assets/images/pochette_tourisme_toulouse.png'),
      ('Petit Train', 'assets/images/pochette_tourisme_toulouse.png'),
      ('La maison de la violette', 'assets/images/pochette_tourisme_toulouse.png'),
      ('Le Canal', 'assets/images/pochette_tourisme_toulouse.png'),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Visiter',
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
                  ref.read(modeSubcategoriesProvider.notifier).select('tourisme', null);
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
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            itemCount: visiterCards.length,
            itemBuilder: (context, index) {
              final (label, image) = visiterCards[index];
              return DaySubcategoryCard(
                emoji: '',
                label: label,
                image: image,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    modeTheme.primaryColor,
                    modeTheme.primaryDarkColor,
                  ],
                ),
                onTap: () {
                  ref.read(modeSubcategoriesProvider.notifier).select('tourisme', label);
                },
              );
            },
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
        const Expanded(
          child: EmptyStateWidget(
            message: 'Bientot disponible',
            icon: Icons.travel_explore,
          ),
        ),
      ],
    );
  }
}
