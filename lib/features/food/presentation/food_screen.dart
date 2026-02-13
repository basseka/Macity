import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/empty_state_widget.dart';
import 'package:pulz_app/core/widgets/error_widget.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/day/presentation/widgets/day_subcategory_card.dart';
import 'package:pulz_app/features/food/data/food_category_data.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
import 'package:pulz_app/features/food/presentation/widgets/restaurant_venue_card.dart';
import 'package:pulz_app/features/day/presentation/widgets/event_row_card.dart';
import 'package:pulz_app/features/food/state/food_venues_provider.dart';


class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(foodCategoryProvider);
    final modeTheme = ref.watch(modeThemeProvider);

    return Column(
      children: [

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
          child: selectedCategory == null
              ? _buildSubcategoryGrid(context, ref)
              : _buildVenueList(context, ref, selectedCategory),
        ),
      ],
    );
  }

  Widget _buildSubcategoryGrid(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final subcategories = FoodCategoryData.allSubcategories;

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
            ref.watch(foodCategoryCountProvider(sub.searchTag));
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
            ref.read(foodCategoryProvider.notifier).state = sub.searchTag;
          },
        );
      },
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
                    fontSize: 16,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  ref.read(foodCategoryProvider.notifier).state = null;
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
          child: category == 'Cette Semaine'
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
    const restaurants = RestaurantVenuesData.venues;
    final items = <Widget>[];

    for (final group in RestaurantVenuesData.groupOrder) {
      final groupVenues =
          restaurants.where((r) => r.group == group).toList();
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                _restaurantGroupEmoji(group),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: modeTheme.primaryDarkColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: modeTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${groupVenues.length}',
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
      for (final venue in groupVenues) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: RestaurantVenueCard(venue: venue),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: items,
    );
  }

  static String _restaurantGroupEmoji(String group) {
    switch (group) {
      case 'Experiences uniques':
        return '\u{1F3AD}';
      case 'Ambiances insolites / thematiques':
        return '\u{1F377}';
      case 'Creativite culinaire':
        return '\u{1F37D}\u{FE0F}';
      case 'Concepts originaux a proximite':
        return '\u{1F4A1}';
      default:
        return '\u{1F37D}\u{FE0F}';
    }
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
    final subcategories = FoodCategoryData.allSubcategories
        .where((s) => s.searchTag != 'Cette Semaine')
        .toList();
    final userEvents = ref.watch(foodUserEventsProvider);

    final items = <Widget>[];

    if (userEvents.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              const Text('\uD83D\uDCC5', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Evenements',
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
                  '${userEvents.length}',
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
      for (final event in userEvents) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: EventRowCard(event: event),
          ),
        );
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
}
