import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/food/data/food_category_data.dart';
import 'package:pulz_app/features/food/data/restaurant_supabase_service.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
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
    return RestaurantVenuesData.venues.length + uc;
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
    return all;
  }
  return repository.searchByVille(ville: city, query: category);
});

/// Restaurants depuis Supabase (avec theme/quartier/style).
/// Fallback sur les donnees statiques si erreur.
final restaurantsSupabaseProvider =
    FutureProvider<List<RestaurantVenue>>((ref) async {
  try {
    final venues = await RestaurantSupabaseService().fetchRestaurants();
    debugPrint('[restaurantsSupabase] fetched ${venues.length} restaurants from Supabase');
    if (venues.isNotEmpty) return venues;
  } catch (e) {
    debugPrint('[restaurantsSupabase] error: $e');
  }
  debugPrint('[restaurantsSupabase] using static fallback');
  return RestaurantVenuesData.venues;
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
