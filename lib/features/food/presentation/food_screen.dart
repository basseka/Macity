import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/editorial_tokens.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_event_tile.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_masthead.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/food/presentation/restaurant_detail_sheet.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/food/data/food_category_data.dart';
import 'package:pulz_app/features/food/presentation/food_hub_grid.dart';
import 'package:pulz_app/features/food/presentation/food_restaurants_fullscreen_map.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
import 'package:pulz_app/features/food/state/food_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';


class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(foodCategoryProvider);

    // Carte plein ecran (sans chrome editorial)
    if (selectedCategory != null &&
        FoodRestaurantsFullscreenMap.isMapTag(selectedCategory)) {
      return const FoodRestaurantsFullscreenMap();
    }

    return Container(
      color: EditorialColors.ink,
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: EditorialMasthead(
              kicker: selectedCategory == null
                  ? 'Rubrique · Plaisirs'
                  : 'Food · $selectedCategory',
              title: selectedCategory ?? 'Food',
              accent: RubricColors.food,
              blurb: selectedCategory == null
                  ? 'Restaurants, brunchs, marches — la carte gourmande de la ville.'
                  : null,
              onBack: selectedCategory == null
                  ? () => context.go('/home')
                  : () {
                      ref
                          .read(modeSubcategoriesProvider.notifier)
                          .select('food', null);
                      ref.read(dateRangeFilterProvider.notifier).state =
                          const DateRangeFilter();
                    },
            ),
          ),
        ],
        body: selectedCategory == null
            ? const FoodHubGrid()
            : _buildVenueList(context, ref, selectedCategory),
      ),
    );
  }

  Widget _buildVenueList(
    BuildContext context,
    WidgetRef ref,
    String category,
  ) {
    final modeTheme = ref.watch(modeThemeProvider);
    final venuesAsync = ref.watch(foodVenuesProvider);

    final isAvenir = category == 'A venir';

    return Column(
      children: [
        if (!isAvenir) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (category == 'Restaurant') ...[
                  InkWell(
                    onTap: () => ref
                        .read(modeSubcategoriesProvider.notifier)
                        .select('food', FoodRestaurantsFullscreenMap.mapTag),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: modeTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me, size: 14, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Carte',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    category,
                    textAlign: TextAlign.center,
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
        ],

        Expanded(
          child: category == 'A venir'
              ? _buildGroupedVenues(ref, modeTheme)
              : (category == 'Restaurant' || category == 'Guinguette' || category == 'Buffets' || category == 'Salon de the' || category == 'Brunch' || category == 'Spa hammam' || category == 'Massage' || category == 'Yoga meditation')
                  ? _buildRestaurantsList(ref, category: category, presetTheme: _presetThemeForCategory(category), placeholderAsset: _placeholderForCategory(category))
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

  static String? _presetThemeForCategory(String category) {
    switch (category) {
      case 'Guinguette': return 'Guinguette';
      case 'Buffets': return 'Buffet';
      case 'Salon de the': return 'Salon de the';
      case 'Brunch': return 'Brunch';
      case 'Spa hammam': return 'Spa hammam';
      case 'Massage': return 'Massage';
      case 'Yoga meditation': return 'Yoga meditation';
      default: return null;
    }
  }

  static String _placeholderForCategory(String category) {
    switch (category) {
      case 'Guinguette':
        return 'assets/images/pochette_guinguette.png';
      case 'Buffets':
        return 'assets/images/pochette_buffet.png';
      case 'Salon de the':
        return 'assets/images/pochette_salondethe.jpg';
      case 'Brunch':
        return 'assets/images/pochette_brunch.jpg';
      case 'Spa hammam':
        return 'assets/images/pochette_spa&hammam.png';
      case 'Massage':
        return 'assets/images/pochette_spa&hammam.png';
      case 'Yoga meditation':
        return 'assets/images/pochette_yoga.jpg';
      default:
        return 'assets/images/pochette_restaurant.jpg';
    }
  }

  Widget _buildRestaurantsList(WidgetRef ref, {required String category, String? presetTheme, String placeholderAsset = 'assets/images/pochette_restaurant.jpg'}) {
    final modeTheme = ref.watch(modeThemeProvider);
    // Toujours recharger depuis Supabase quand on ouvre la carte Restaurant
    final restaurantsAsync = ref.watch(restaurantsSupabaseProvider);

    return restaurantsAsync.when(
      data: (venues) {
        final filtered = presetTheme != null
            ? venues.where((r) => r.theme.toLowerCase() == presetTheme.toLowerCase()).toList()
            : venues;
        return _buildRestaurantsFiltered(ref, filtered, modeTheme, category: category, hideThemeFilter: presetTheme != null, placeholderAsset: placeholderAsset);
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (_, __) => _buildRestaurantsFiltered(
          ref, <RestaurantVenue>[], modeTheme, category: category),
    );
  }

  /// Convertit un RestaurantVenue en CommerceModel pour partager
  /// CommerceRowCard avec les autres rubriques (Night/Clubs notamment).
  /// La `categorie` est passee depuis la sous-rubrique courante pour que
  /// le fallback image de CommerceRowCard pointe sur la bonne pochette.
  static CommerceModel _restaurantToCommerce(RestaurantVenue v, String categorie) {
    final parsedId = int.tryParse(v.id);
    return CommerceModel(
      nom: v.name,
      adresse: v.adresse,
      latitude: v.latitude,
      longitude: v.longitude,
      horaires: v.horaires,
      categorie: categorie,
      lienMaps: v.lienMaps,
      telephone: v.telephone,
      avis: v.description,
      photo: v.photo,
      siteWeb: v.websiteUrl,
      isVerified: v.isVerified,
      sourceId: parsedId,
      sourceTable: parsedId == null ? null : 'etablissement',
    );
  }

  Future<void> _refreshRestaurants() async {
    ref.invalidate(restaurantsSupabaseProvider);
    // Attendre que le provider recharge
    await ref.read(restaurantsSupabaseProvider.future);
  }

  Widget _buildRestaurantsFiltered(
      WidgetRef ref, List<RestaurantVenue> allVenues, modeTheme, {required String category, bool hideThemeFilter = false, String placeholderAsset = 'assets/images/pochette_restaurant.jpg'}) {

    if (allVenues.isEmpty) {
      return Center(
        child: Text(
          'Aucun restaurant',
          style: TextStyle(fontSize: 13, color: AppColors.textFaint),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshRestaurants,
      color: modeTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          // Compteur en header
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${allVenues.length} restaurant${allVenues.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          // Liste de cartes restaurant
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CommerceRowCard(
                    commerce: _restaurantToCommerce(allVenues[index], category),
                    imageAsset: allVenues[index].photo.isEmpty ? placeholderAsset : null,
                    // Restaurant : route vers la fiche dediee avec CTA Reserver,
                    // au lieu du sheet generique ItemDetailSheet.
                    onTap: () => RestaurantDetailSheet.show(
                      context,
                      allVenues[index],
                    ),
                  ),
                ),
                childCount: allVenues.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
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
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: DateRangeChipBar(),
      ),
      const SizedBox(height: 4),
    ];

    // User events grouped by date — style editorial Day-aligned
    if (userEvents.isNotEmpty) {
      final dateGrouped = <DateTime, List<Event>>{};
      for (final e in userEvents) {
        final d = DateTime.tryParse(e.dateDebut);
        if (d == null) continue;
        final dateOnly = DateTime(d.year, d.month, d.day);
        dateGrouped.putIfAbsent(dateOnly, () => []).add(e);
      }
      final sortedDates = dateGrouped.keys.toList()..sort();

      for (final day in sortedDates) {
        final eventsForDate = dateGrouped[day]!;
        items.add(editorialDateHeader(
          editorialDayLabel(day),
          RubricColors.food,
          count: eventsForDate.length,
        ));
        for (final event in eventsForDate) {
          items.add(editorialEventTileFromEvent(
            context,
            event,
            RubricColors.food,
          ));
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
              if (sub.emoji.isNotEmpty) ...[
                Text(sub.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
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

}

class _RestaurantGridTile extends StatelessWidget {
  final RestaurantVenue venue;

  const _RestaurantGridTile({required this.venue});

  bool get _hasNetworkPhoto => venue.photo.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond : photo réseau si dispo, sinon asset local
          if (_hasNetworkPhoto)
            CachedNetworkImage(
              imageUrl: venue.photo,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey.shade800),
              errorWidget: (_, __, ___) => Image.asset(
                'assets/images/pochette_food.png',
                fit: BoxFit.cover,
                cacheWidth: 300,
              ),
            )
          else
            Image.asset(
              'assets/images/pochette_food.png',
              fit: BoxFit.cover,
              cacheWidth: 300,
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

  static const _defaultRestaurantPhotos = [
    'assets/images/plat-01.png',
    'assets/images/plat-02.png',
    'assets/images/plat-03.png',
    'assets/images/plat-04.png',
    'assets/images/plat-05.png',
    'assets/images/plat-06.png',
  ];

  void _openDetail(BuildContext context) {
    // Delegate au helper centralise pour avoir le bouton "Reserver" + badge
    // de reservations actives sur tous les points d'entree de la fiche.
    RestaurantDetailSheet.show(context, venue);
  }
}
