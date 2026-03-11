import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/family/data/family_category_data.dart';
import 'package:pulz_app/features/family/data/family_venues_supabase_service.dart';
import 'package:pulz_app/features/family/domain/models/family_venue.dart';

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

final _familyServiceProvider = Provider((_) => FamilyVenuesSupabaseService());

/// Evenements scrapes depuis la base (source balma_events).
final balmaEventsProvider = FutureProvider<List<Event>>((ref) async {
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'culture',
    source: 'balma_events',
    dateGte: _todayStr(),
  );
});

/// Evenements utilisateur filtres pour la rubrique "family".
final familyUserEventsProvider = Provider<List<Event>>((ref) {
  final city = ref.watch(selectedCityProvider);
  final allUserEvents = ref.watch(userEventsProvider);
  return allUserEvents
      .where((ue) =>
          ue.rubrique == 'family' &&
          ue.ville.toLowerCase() == city.toLowerCase(),)
      .map((ue) => ue.toEvent())
      .toList();
});

int _familyUserCount(List<Event> events, String searchTag) {
  if (searchTag == 'A venir') return events.length;
  return events.where((e) {
    final cat = e.categorie.toLowerCase();
    final tag = searchTag.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).length;
}

/// Nombre de lieux par categorie (pour les badges sur la grille).
final familyCategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final userEvents = ref.watch(familyUserEventsProvider);
  final uc = _familyUserCount(userEvents, searchTag);
  final service = ref.read(_familyServiceProvider);

  if (searchTag == 'A venir') {
    final allTags = FamilyCategoryData.allSubcategories
        .where((s) => s.searchTag != 'A venir')
        .map((s) => s.searchTag);
    var total = 0;
    for (final tag in allTags) {
      total += await service.countByCategory(tag);
    }
    final balmaEvents = ref.watch(balmaEventsProvider).valueOrNull ?? [];
    return total + uc + balmaEvents.length;
  }

  final count = await service.countByCategory(searchTag);
  return count + uc;
});

/// Venues Supabase pour la categorie selectionnee.
final familySupabaseVenuesProvider =
    FutureProvider.family<List<FamilyVenue>, String>((ref, category) async {
  final service = ref.read(_familyServiceProvider);
  return service.fetchVenues(category: category);
});

/// Toutes les venues Supabase, groupees par categorie (pour "A venir").
final familyAllVenuesGroupedProvider =
    FutureProvider<Map<String, List<FamilyVenue>>>((ref) async {
  final service = ref.read(_familyServiceProvider);
  final grouped = <String, List<FamilyVenue>>{};
  for (final sub in FamilyCategoryData.allSubcategories) {
    if (sub.searchTag == 'A venir') continue;
    grouped[sub.searchTag] = await service.fetchVenues(category: sub.searchTag);
  }
  return grouped;
});
