import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/gaming/data/gaming_category_data.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/features/family/data/family_venues_supabase_service.dart';
import 'package:pulz_app/features/family/presentation/widgets/family_venue_row_card.dart';

/// Lieux curés d'une catégorie Gaming : table venues (mode gaming), et pour
/// « Escape game » les fiches de la rubrique Famille (family_venues), qui ont
/// les vraies pochettes. Sans ça, la catégorie retombait sur la recherche
/// externe, sans photo, d'où la pochette générique (2026-10-21).
Future<List<CommerceModel>> _curatedGamingVenues(String city, String tag) async {
  try {
    final venues = await VenuesSupabaseService().fetchVenues(
      mode: 'gaming', ville: city, category: tag,
    );
    if (venues.isNotEmpty) return venues;
  } catch (_) {}
  if (tag == 'Escape game') {
    try {
      final family = await FamilyVenuesSupabaseService()
          .fetchVenues(category: tag, ville: city);
      return family.map(FamilyVenueRowCard.toCommerce).toList();
    } catch (_) {}
  }
  return const [];
}

/// Evenements utilisateur filtres pour la rubrique "gaming".
final gamingUserEventsProvider = Provider<List<Event>>((ref) {
  final city = ref.watch(selectedCityProvider);
  final allUserEvents = ref.watch(userEventsProvider);
  return allUserEvents
      .where((ue) =>
          ue.rubrique == 'gaming' &&
          ue.ville.toLowerCase() == city.toLowerCase())
      .map((ue) => ue.toEvent())
      .toList();
});

int _gamingUserCount(List<Event> events, String searchTag) {
  if (searchTag == 'A venir') return events.length;
  return events.where((e) {
    final cat = e.categorie.toLowerCase();
    final tag = searchTag.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).length;
}

final gamingCategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final city = ref.watch(selectedCityProvider);
  final userEvents = ref.watch(gamingUserEventsProvider);
  final uc = _gamingUserCount(userEvents, searchTag);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  if (searchTag == 'A venir') {
    final allTags = GamingCategoryData.allSubcategories
        .where((s) => s.searchTag != 'A venir')
        .map((s) => s.searchTag);
    var total = 0;
    for (final tag in allTags) {
      // Chercher dans les lieux curés Supabase d'abord
      final sv = await _curatedGamingVenues(city, tag);
      if (sv.isNotEmpty) { total += sv.length; continue; }
      final venues = await repository.searchByVille(ville: city, query: tag);
      total += venues.length;
    }
    return total + uc;
  }
  // Chercher dans les lieux curés Supabase d'abord
  final sv = await _curatedGamingVenues(city, searchTag);
  if (sv.isNotEmpty) return sv.length + uc;
  final venues = await repository.searchByVille(ville: city, query: searchTag);
  return venues.length + uc;
});

final gamingVenuesProvider = FutureProvider.autoDispose<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final category = ref.watch(gamingCategoryProvider);

  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  if (category == 'A venir') {
    final allTags = GamingCategoryData.allSubcategories
        .where((s) => s.searchTag != 'A venir')
        .map((s) => s.searchTag);
    final all = <CommerceModel>[];
    for (final tag in allTags) {
      final curated = await _curatedGamingVenues(city, tag);
      all.addAll(curated.isNotEmpty
          ? curated
          : await repository.searchByVille(ville: city, query: tag));
    }
    return all;
  }
  // Catégories curées (venues gaming, Famille pour les escape games)
  if (category != null) {
    final venues = await _curatedGamingVenues(city, category);
    if (venues.isNotEmpty) return venues;
  }
  return repository.searchByVille(ville: city, query: category);
});

/// Provider groupé par searchTag pour l'affichage "A venir".
final gamingGroupedVenuesProvider =
    FutureProvider.autoDispose<Map<String, List<CommerceModel>>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  final grouped = <String, List<CommerceModel>>{};
  for (final sub in GamingCategoryData.allSubcategories) {
    if (sub.searchTag == 'A venir') continue;
    final curated = await _curatedGamingVenues(city, sub.searchTag);
    grouped[sub.searchTag] = curated.isNotEmpty
        ? curated
        : await repository.searchByVille(ville: city, query: sub.searchTag);
  }
  return grouped;
});
