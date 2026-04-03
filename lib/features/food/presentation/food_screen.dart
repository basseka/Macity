import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/state/date_range_filter_provider.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/utils/date_formatter.dart';
import 'package:pulz_app/core/widgets/community_event_card.dart';
import 'package:pulz_app/core/widgets/date_range_chip_bar.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
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
              : (category == 'Restaurant' || category == 'Guinguette' || category == 'Buffets' || category == 'Salon de the' || category == 'Brunch' || category == 'Spa hammam' || category == 'Massage' || category == 'Yoga meditation')
                  ? _buildRestaurantsList(ref, presetTheme: _presetThemeForCategory(category), placeholderAsset: _placeholderForCategory(category))
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

  Widget _buildRestaurantsList(WidgetRef ref, {String? presetTheme, String placeholderAsset = 'assets/images/pochette_restaurant.jpg'}) {
    final modeTheme = ref.watch(modeThemeProvider);
    // Toujours recharger depuis Supabase quand on ouvre la carte Restaurant
    final restaurantsAsync = ref.watch(restaurantsSupabaseProvider);

    return restaurantsAsync.when(
      data: (venues) {
        final filtered = presetTheme != null
            ? venues.where((r) => r.theme.toLowerCase() == presetTheme.toLowerCase()).toList()
            : venues;
        return _buildRestaurantsFiltered(ref, filtered, modeTheme, hideThemeFilter: presetTheme != null, placeholderAsset: placeholderAsset);
      },
      loading: () => LoadingIndicator(color: modeTheme.primaryColor),
      error: (_, __) => _buildRestaurantsFiltered(
          ref, <RestaurantVenue>[], modeTheme),
    );
  }

  Future<void> _refreshRestaurants() async {
    ref.invalidate(restaurantsSupabaseProvider);
    // Attendre que le provider recharge
    await ref.read(restaurantsSupabaseProvider.future);
  }

  Widget _buildRestaurantsFiltered(
      WidgetRef ref, List<RestaurantVenue> allVenues, modeTheme, {bool hideThemeFilter = false, String placeholderAsset = 'assets/images/pochette_restaurant.jpg'}) {

    // Filtrer selon le filtre actif (comparaison insensible a la casse)
    final filtered = allVenues.where((r) {
      if (!hideThemeFilter && _selectedTheme != 'Tous' &&
          r.theme.toLowerCase() != _selectedTheme.toLowerCase()) return false;
      if (_selectedQuartier != 'Tous' &&
          r.quartier.toLowerCase() != _selectedQuartier.toLowerCase()) return false;
      if (_selectedStyle != 'Tous' &&
          r.style.toLowerCase() != _selectedStyle.toLowerCase()) return false;
      return true;
    }).toList();

    // Options du filtre actif
    List<String> currentOptions;
    String currentValue;
    void Function(String) onSelect;

    final effectiveFilterTab = hideThemeFilter && _filterTab == 0 ? 1 : _filterTab;
    switch (effectiveFilterTab) {
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
          _buildFilterHeader(modeTheme, currentOptions, currentValue, onSelect, hideThemeTab: hideThemeFilter),
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
                _buildFilterHeader(modeTheme, currentOptions, currentValue, onSelect, hideThemeTab: hideThemeFilter),
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
          // Liste de cartes restaurant
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RestaurantRowCard(venue: filtered[index], placeholderAsset: placeholderAsset),
                ),
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
    {bool hideThemeTab = false}
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (!hideThemeTab) ...[
                _buildFilterTab('Theme', 0, modeTheme.primaryColor),
                const SizedBox(width: 8),
              ],
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
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final tomorrowStr =
          DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

      for (final dateKey in sortedDates) {
        final eventsForDate = dateGrouped[dateKey]!;
        final String dateLabel;
        if (dateKey == todayStr) {
          dateLabel = "Aujourd'hui";
        } else if (dateKey == tomorrowStr) {
          dateLabel = 'Demain';
        } else {
          final parsed = DateTime.tryParse(dateKey);
          dateLabel = parsed != null
              ? _capitalize(DateFormat('EEEE d MMMM', 'fr_FR').format(parsed))
              : dateKey;
        }

        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        );
        for (final event in eventsForDate) {
          items.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: CommunityEventCard(
                title: event.titre,
                date: event.dateDebut,
                time: event.horaires,
                location: event.lieuNom,
                photoUrl: event.photoPath,
                tag: event.categorie.isNotEmpty ? event.categorie : null,
                isFree: event.isFree,
                hasVideo: event.videoUrl != null && event.videoUrl!.isNotEmpty,
                onTap: () => EventFullscreenPopup.show(
                    context, event, 'assets/images/pochette_default.jpg'),
              ),
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

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Carte restaurant en liste (style "A venir") ──
class _RestaurantRowCard extends StatelessWidget {
  final RestaurantVenue venue;
  final String placeholderAsset;
  const _RestaurantRowCard({required this.venue, this.placeholderAsset = 'assets/images/pochette_restaurant.jpg'});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: venue.photo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: venue.photo,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 10),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    venue.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (venue.quartier.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 10, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            venue.quartier,
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (venue.horaires.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 10, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            venue.horaires,
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Tags a droite
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 70),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (venue.theme.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2D8E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        venue.theme,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7B2D8E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (venue.style.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        venue.style,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      placeholderAsset,
      fit: BoxFit.cover,
      cacheWidth: 300,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF0F0F5),
        child: const Icon(Icons.restaurant, size: 24, color: Colors.grey),
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
    final photos = <String>[];
    if (venue.photo.isNotEmpty && venue.photo.startsWith('http')) {
      photos.add(venue.photo);
    }
    for (final p in _defaultRestaurantPhotos) {
      if (photos.length >= 6) break;
      if (!photos.contains(p)) photos.add(p);
    }

    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: venue.name,
        emoji: '',
        imageAsset: venue.photo.isNotEmpty && !venue.photo.startsWith('http') ? venue.photo : 'assets/images/pochette_restaurant.jpg',
        imageUrl: venue.photo.isNotEmpty && venue.photo.startsWith('http') ? venue.photo : null,
        photoGallery: photos,
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

// ── Tuile grille restaurant (style Instagram, gardee pour reference) ──
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
    final photos = <String>[];
    if (venue.photo.isNotEmpty && venue.photo.startsWith('http')) {
      photos.add(venue.photo);
    }
    for (final p in _defaultRestaurantPhotos) {
      if (photos.length >= 6) break;
      if (!photos.contains(p)) photos.add(p);
    }

    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: venue.name,
        emoji: '',
        imageAsset: venue.photo.isNotEmpty && !venue.photo.startsWith('http') ? venue.photo : 'assets/images/pochette_restaurant.jpg',
        imageUrl: venue.photo.isNotEmpty && venue.photo.startsWith('http') ? venue.photo : null,
        photoGallery: photos,
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
