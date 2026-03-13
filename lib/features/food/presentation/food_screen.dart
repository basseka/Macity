import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/utils/date_formatter.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/food/data/food_category_data.dart';
import 'package:pulz_app/features/food/presentation/food_hub_grid.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/food/state/food_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';


class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  // Filtres restaurant
  int _filterTab = 0; // 0=Theme, 1=Quartier, 2=Style
  String _selectedTheme = 'Tous';
  String _selectedQuartier = 'Tous';
  String _selectedStyle = 'Tous';

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(foodCategoryProvider);

    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: selectedCategory == null
              ? const FoodHubGrid()
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
    final venuesAsync = ref.watch(foodVenuesProvider);

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
                  ref.read(modeSubcategoriesProvider.notifier).select('food', null);
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
              ? _buildGroupedVenues(ref, modeTheme)
              : category == 'Restaurant'
                  ? _buildRestaurantsList(ref)
                  : venuesAsync.when(
                  data: (venues) {
                    if (venues.isEmpty) {
                      return const EmptyStateWidget(
                        message: 'Aucun lieu trouve pour cette categorie',
                        icon: Icons.restaurant,
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
                    onRetry: () => ref.invalidate(foodVenuesProvider),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRestaurantsList(WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    // Toujours recharger depuis Supabase quand on ouvre la carte Restaurant
    final restaurantsAsync = ref.watch(restaurantsSupabaseProvider);

    return restaurantsAsync.when(
      data: (venues) => _buildRestaurantsFiltered(ref, venues, modeTheme),
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (_, __) => _buildRestaurantsFiltered(
          ref, RestaurantVenuesData.venues, modeTheme),
    );
  }

  Future<void> _refreshRestaurants() async {
    ref.invalidate(restaurantsSupabaseProvider);
    // Attendre que le provider recharge
    await ref.read(restaurantsSupabaseProvider.future);
  }

  Widget _buildRestaurantsFiltered(
      WidgetRef ref, List<RestaurantVenue> allVenues, modeTheme) {

    // Filtrer selon le filtre actif
    final filtered = allVenues.where((r) {
      if (_selectedTheme != 'Tous' && r.theme != _selectedTheme) return false;
      if (_selectedQuartier != 'Tous' && r.quartier != _selectedQuartier) return false;
      if (_selectedStyle != 'Tous' && r.style != _selectedStyle) return false;
      return true;
    }).toList();

    // Options du filtre actif
    List<String> currentOptions;
    String currentValue;
    void Function(String) onSelect;

    switch (_filterTab) {
      case 0:
        currentOptions = RestaurantVenuesData.themes;
        currentValue = _selectedTheme;
        onSelect = (v) => setState(() => _selectedTheme = v);
      case 1:
        currentOptions = RestaurantVenuesData.quartiers;
        currentValue = _selectedQuartier;
        onSelect = (v) => setState(() => _selectedQuartier = v);
      default:
        currentOptions = RestaurantVenuesData.styles;
        currentValue = _selectedStyle;
        onSelect = (v) => setState(() => _selectedStyle = v);
    }

    if (filtered.isEmpty) {
      return Column(
        children: [
          _buildFilterHeader(modeTheme, currentOptions, currentValue, onSelect),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Text(
                'Aucun restaurant pour ce filtre',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshRestaurants,
      color: modeTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          // Onglets + chips + compteur en header
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildFilterHeader(modeTheme, currentOptions, currentValue, onSelect),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filtered.length} restaurant${filtered.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          // Grille Instagram 3 colonnes
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _RestaurantGridTile(venue: filtered[index]),
                childCount: filtered.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(
    dynamic modeTheme,
    List<String> currentOptions,
    String currentValue,
    void Function(String) onSelect,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterTab('Theme', 0, modeTheme.primaryColor),
              const SizedBox(width: 8),
              _buildFilterTab('Quartier', 1, modeTheme.primaryColor),
              const SizedBox(width: 8),
              _buildFilterTab('Style', 2, modeTheme.primaryColor),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: currentOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final option = currentOptions[index];
              final isSelected = option == currentValue;
              return GestureDetector(
                onTap: () => onSelect(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? modeTheme.primaryColor
                        : modeTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : modeTheme.primaryDarkColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label, int index, Color primaryColor) {
    final isActive = _filterTab == index;
    return GestureDetector(
      onTap: () => setState(() => _filterTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? primaryColor : primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedVenues(WidgetRef ref, ModeTheme modeTheme) {
    final groupedAsync = ref.watch(foodGroupedVenuesProvider);
    return groupedAsync.when(
      data: (grouped) => _buildGroupedVenuesList(grouped, modeTheme, ref),
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (error, _) => AppErrorWidget(
        message: 'Erreur lors du chargement des lieux',
        onRetry: () => ref.invalidate(foodGroupedVenuesProvider),
      ),
    );
  }

  Widget _buildGroupedVenuesList(
    Map<String, List<CommerceModel>> grouped,
    ModeTheme modeTheme,
    WidgetRef ref,
  ) {
    final filter = ref.watch(dateRangeFilterProvider);
    final subcategories = FoodCategoryData.allSubcategories
        .where((s) => s.searchTag != 'A venir')
        .toList();
    final userEvents = ref.watch(foodUserEventsProvider).where((e) {
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

      for (final dateKey in sortedDates) {
        final eventsForDate = dateGrouped[dateKey]!;
        final parsed = DateTime.tryParse(dateKey);
        final dateLabel = parsed != null
            ? _capitalize(DateFormatter.formatRelative(parsed))
            : dateKey;

        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: modeTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${eventsForDate.length}',
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
        for (final event in eventsForDate) {
          items.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: EventRowCard(event: event),
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

// ── Tuile grille restaurant (style Instagram) ──
class _RestaurantGridTile extends StatelessWidget {
  final RestaurantVenue venue;

  const _RestaurantGridTile({required this.venue});

  static const _themeImages = <String, String>{
    'asiatique': 'assets/images/pochette_food.png',
    'japonais': 'assets/images/pochette_food.png',
    'italien': 'assets/images/pochette_food.png',
    'orientale': 'assets/images/pochette_food.png',
    'africain': 'assets/images/pochette_food.png',
    'indien': 'assets/images/pochette_food.png',
    'mexicain': 'assets/images/pochette_food.png',
  };

  String get _pochette {
    final t = venue.theme.toLowerCase();
    return _themeImages[t] ?? 'assets/images/pochette_food.png';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond
          Image.asset(
            _pochette,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: Colors.grey.shade900),
          ),

          // Gradient bas
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
          ),

          // Badge theme en haut a droite
          if (venue.theme.isNotEmpty)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2D8E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  venue.theme,
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Badge quartier en haut a gauche
          if (venue.quartier.isNotEmpty)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 8, color: Colors.white70),
                    const SizedBox(width: 2),
                    Text(
                      venue.quartier,
                      style: GoogleFonts.inter(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Nom + style en bas
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (venue.style.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    venue.style,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: Colors.white60,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: venue.name,
        emoji: '\u{1F37D}\u{FE0F}',
        infos: [
          if (venue.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, venue.description),
          if (venue.theme.isNotEmpty)
            DetailInfoItem(Icons.restaurant_menu, 'Theme: ${venue.theme}'),
          if (venue.style.isNotEmpty)
            DetailInfoItem(Icons.style, 'Style: ${venue.style}'),
          if (venue.quartier.isNotEmpty)
            DetailInfoItem(Icons.location_city, 'Quartier: ${venue.quartier}'),
          if (venue.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, venue.horaires),
          if (venue.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, venue.adresse),
          if (venue.telephone.isNotEmpty)
            DetailInfoItem(Icons.phone_outlined, venue.telephone),
        ],
        primaryAction: venue.websiteUrl.isNotEmpty
            ? DetailAction(
                icon: Icons.language, label: 'Site web', url: venue.websiteUrl)
            : null,
        secondaryActions: [
          if (venue.lienMaps.isNotEmpty)
            DetailAction(
                icon: Icons.map_outlined, label: 'Maps', url: venue.lienMaps),
          if (venue.telephone.isNotEmpty)
            DetailAction(
                icon: Icons.phone_outlined,
                label: 'Appeler',
                url: 'tel:${venue.telephone.replaceAll(' ', '')}'),
        ],
        shareText:
            '${venue.name}\n${venue.adresse}\n${venue.telephone.isNotEmpty ? '${venue.telephone}\n' : ''}${venue.websiteUrl}\n\nDecouvre sur MaCity',
      ),
    );
  }
}
