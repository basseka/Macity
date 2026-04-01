import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/food/data/food_category_data.dart';
import 'package:pulz_app/features/food/data/restaurant_supabase_service.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart' show RestaurantVenue;
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

/// Evenements utilisateur filtres pour la rubrique "food".
final foodUserEventsProvider = Provider<List<Event>>((ref) {
  final city = ref.watch(selectedCityProvider);
  final allUserEvents = ref.watch(userEventsProvider);
  return allUserEvents
      .where((ue) =>
          ue.rubrique == 'food' &&
          ue.ville.toLowerCase() == city.toLowerCase())
      .map((ue) => ue.toEvent())
      .toList();
});

int _foodUserCount(List<Event> events, String searchTag) {
  if (searchTag == 'A venir') return events.length;
  return events.where((e) {
    final cat = e.categorie.toLowerCase();
    final tag = searchTag.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).length;
}

final foodCategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final city = ref.watch(selectedCityProvider);
  final userEvents = ref.watch(foodUserEventsProvider);
  final uc = _foodUserCount(userEvents, searchTag);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  if (searchTag == 'A venir') {
    final allTags = FoodCategoryData.allSubcategories
        .where((s) => s.searchTag != 'A venir')
        .map((s) => s.searchTag);
    var total = 0;
    for (final tag in allTags) {
      final venues = await repository.searchByVille(ville: city, query: tag);
      total += venues.length;
    }
    return total + uc;
  }
  if (searchTag == 'Restaurant') {
    final restaurants = await RestaurantSupabaseService().fetchRestaurants(ville: city);
    if (restaurants.isNotEmpty) return restaurants.length;
    // Fallback sur la table venues (donnees OSM)
    try {
      final count = await VenuesSupabaseService().countVenues(
        mode: 'food', ville: city, category: searchTag,
      );
      return count + uc;
    } catch (_) {}
    return uc;
  }
  if (searchTag == 'Guinguette' || searchTag == 'Buffets' || searchTag == 'Salon de the' || searchTag == 'Brunch' || searchTag == 'Spa hammam' || searchTag == 'Massage' || searchTag == 'Yoga meditation') {
    final theme = searchTag == 'Buffets' ? 'Buffet' : searchTag;
    final restaurants = await RestaurantSupabaseService().fetchRestaurants(ville: city);
    return restaurants.where((r) => r.theme.toLowerCase() == theme.toLowerCase()).length;
  }
  final venues = await repository.searchByVille(ville: city, query: searchTag);
  return venues.length + uc;
});

final foodVenuesProvider = FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final category = ref.watch(foodCategoryProvider);

  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  if (category == 'A venir') {
    final allTags = FoodCategoryData.allSubcategories
        .where((s) => s.searchTag != 'A venir')
        .map((s) => s.searchTag);
    final all = <CommerceModel>[];
    for (final tag in allTags) {
      final venues = await repository.searchByVille(ville: city, query: tag);
      all.addAll(venues);
    }
    if (all.isEmpty) {
      // Fallback OSM
      try {
        return await VenuesSupabaseService().fetchVenues(mode: 'food', ville: city);
      } catch (_) {}
    }
    return all;
  }
  final local = await repository.searchByVille(ville: city, query: category);
  if (local.isNotEmpty) return local;
  // Fallback OSM
  try {
    return await VenuesSupabaseService().fetchVenues(
      mode: 'food', ville: city, category: category,
    );
  } catch (_) {}
  return local;
});

/// Restaurants depuis Supabase (avec theme/quartier/style), filtres par ville.
final restaurantsSupabaseProvider =
    FutureProvider<List<RestaurantVenue>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return RestaurantSupabaseService().fetchRestaurants(ville: city);
});

/// Provider groupé par searchTag pour l'affichage "A venir".
final foodGroupedVenuesProvider =
    FutureProvider<Map<String, List<CommerceModel>>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  final grouped = <String, List<CommerceModel>>{};
  for (final sub in FoodCategoryData.allSubcategories) {
    if (sub.searchTag == 'A venir') continue;
    grouped[sub.searchTag] =
        await repository.searchByVille(ville: city, query: sub.searchTag);
  }
  return grouped;
});
