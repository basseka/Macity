import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/family/data/family_category_data.dart';
import 'package:pulz_app/features/family/data/animal_park_venues_data.dart';
import 'package:pulz_app/features/family/data/bowling_venues_data.dart';
import 'package:pulz_app/features/family/data/cinema_venues_data.dart';
import 'package:pulz_app/features/family/data/escape_game_venues_data.dart';
import 'package:pulz_app/features/family/data/family_restaurant_venues_data.dart';
import 'package:pulz_app/features/family/data/laser_game_venues_data.dart';
import 'package:pulz_app/features/family/data/park_venues_data.dart';
import 'package:pulz_app/features/family/data/playground_venues_data.dart';
import 'package:pulz_app/core/database/app_database.dart';

final familyCategoryProvider = StateProvider<String?>((ref) => null);

final familyCategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final city = ref.watch(selectedCityProvider);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  if (searchTag == 'Cette Semaine') {
    final allTags = FamilyCategoryData.allSubcategories
        .where((s) => s.searchTag != 'Cette Semaine')
        .map((s) => s.searchTag);
    var total = 0;
    for (final tag in allTags) {
      final venues = await repository.searchByVille(ville: city, query: tag);
      total += venues.length;
    }
    return total;
  }
  if (searchTag == "Parc d'attractions") {
    return ParkVenuesData.venues.length;
  }
  if (searchTag == 'Parc animalier') {
    return AnimalParkVenuesData.venues.length;
  }
  if (searchTag == 'Cinema') {
    return CinemaVenuesData.venues.length;
  }
  if (searchTag == 'Bowling') {
    return BowlingVenuesData.venues.length;
  }
  if (searchTag == 'Laser game') {
    return LaserGameVenuesData.venues.length;
  }
  if (searchTag == 'Escape game') {
    return EscapeGameVenuesData.venues.length;
  }
  if (searchTag == 'Restaurant familial') {
    return FamilyRestaurantVenuesData.venues.length;
  }
  if (searchTag == 'Aire de jeux') {
    return PlaygroundVenuesData.venues.length;
  }
  final venues = await repository.searchByVille(ville: city, query: searchTag);
  return venues.length;
});

final familyVenuesProvider = FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final category = ref.watch(familyCategoryProvider);

  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  if (category == "Parc d'attractions") {
    return ParkVenuesData.venues.toList();
  }
  if (category == 'Cette Semaine') {
    final allTags = FamilyCategoryData.allSubcategories
        .where((s) => s.searchTag != 'Cette Semaine')
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

/// Provider groupé par searchTag pour l'affichage "Cette Semaine".
final familyGroupedVenuesProvider =
    FutureProvider<Map<String, List<CommerceModel>>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  final grouped = <String, List<CommerceModel>>{};
  for (final sub in FamilyCategoryData.allSubcategories) {
    if (sub.searchTag == 'Cette Semaine') continue;
    grouped[sub.searchTag] =
        await repository.searchByVille(ville: city, query: sub.searchTag);
  }
  return grouped;
});
