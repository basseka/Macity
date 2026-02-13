import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
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

/// Evenements utilisateur filtres pour la rubrique "family".
final familyUserEventsProvider = Provider<List<Event>>((ref) {
  final city = ref.watch(selectedCityProvider);
  final allUserEvents = ref.watch(userEventsProvider);
  return allUserEvents
      .where((ue) =>
          ue.rubrique == 'family' &&
          ue.ville.toLowerCase() == city.toLowerCase())
      .map((ue) => ue.toEvent())
      .toList();
});

int _familyUserCount(List<Event> events, String searchTag) {
  if (searchTag == 'Cette Semaine') return events.length;
  return events.where((e) {
    final cat = e.categorie.toLowerCase();
    final tag = searchTag.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).length;
}

final familyCategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final city = ref.watch(selectedCityProvider);
  final userEvents = ref.watch(familyUserEventsProvider);
  final uc = _familyUserCount(userEvents, searchTag);
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
    return total + uc;
  }
  if (searchTag == "Parc d'attractions") {
    return ParkVenuesData.venues.length + uc;
  }
  if (searchTag == 'Parc animalier') {
    return AnimalParkVenuesData.venues.length + uc;
  }
  if (searchTag == 'Cinema') {
    return CinemaVenuesData.venues.length + uc;
  }
  if (searchTag == 'Bowling') {
    return BowlingVenuesData.venues.length + uc;
  }
  if (searchTag == 'Laser game') {
    return LaserGameVenuesData.venues.length + uc;
  }
  if (searchTag == 'Escape game') {
    return EscapeGameVenuesData.venues.length + uc;
  }
  if (searchTag == 'Restaurant familial') {
    return FamilyRestaurantVenuesData.venues.length + uc;
  }
  if (searchTag == 'Aire de jeux') {
    return PlaygroundVenuesData.venues.length + uc;
  }
  final venues = await repository.searchByVille(ville: city, query: searchTag);
  return venues.length + uc;
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
