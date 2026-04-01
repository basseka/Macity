import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
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
  final city = ref.watch(selectedCityProvider);
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'culture',
    source: 'balma_events',
    dateGte: _todayStr(),
    ville: city,
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

  final city = ref.watch(selectedCityProvider);

  // "A venir" = events communauté + scraped events famille
  if (searchTag == 'A venir') {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final userCount = userEvents.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) return false;
      return !DateTime(d.year, d.month, d.day).isBefore(today);
    }).length;
    final scrapedEvents = await ScrapedEventsSupabaseService().fetchEvents(
      rubrique: 'family',
      dateGte: _todayStr(),
      ville: city,
      requirePhoto: false,
    );
    return userCount + scrapedEvents.length;
  }

  var count = await service.countByCategory(searchTag, ville: city);
  // Fallback sur la table venues (donnees OSM)
  if (count == 0) {
    try {
      count = await VenuesSupabaseService().countVenues(
        mode: 'family', ville: city, category: searchTag,
      );
    } catch (_) {}
  }
  return count + uc;
});

/// Venues Supabase pour la categorie selectionnee, filtrees par ville.
/// Fallback sur la table venues (donnees OSM) si family_venues est vide.
final familySupabaseVenuesProvider =
    FutureProvider.family<List<FamilyVenue>, String>((ref, category) async {
  final city = ref.watch(selectedCityProvider);
  final service = ref.read(_familyServiceProvider);
  final results = await service.fetchVenues(category: category, ville: city);
  if (results.isNotEmpty) return results;

  // Fallback OSM → convertir CommerceModel en FamilyVenue
  try {
    final osmVenues = await VenuesSupabaseService().fetchVenues(
      mode: 'family', ville: city, category: category,
    );
    return osmVenues.map((c) => FamilyVenue(
      id: c.nom.hashCode,
      slug: c.nom.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      name: c.nom,
      category: category,
      adresse: c.adresse,
      ville: c.ville,
      horaires: c.horaires,
      telephone: c.telephone,
      latitude: c.latitude,
      longitude: c.longitude,
      websiteUrl: c.siteWeb,
      lienMaps: c.lienMaps,
      photo: c.photo,
    )).toList();
  } catch (_) {}
  return results;
});

/// Scraped events famille (rubrique='family') pour la ville selectionnee.
final familyScrapedEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'family',
    dateGte: _todayStr(),
    ville: city,
    requirePhoto: false,
  );
});

/// Toutes les venues Supabase, groupees par categorie (pour "A venir"), filtrees par ville.
final familyAllVenuesGroupedProvider =
    FutureProvider<Map<String, List<FamilyVenue>>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final service = ref.read(_familyServiceProvider);
  final grouped = <String, List<FamilyVenue>>{};
  for (final sub in FamilyCategoryData.allSubcategories) {
    if (sub.searchTag == 'A venir') continue;
    grouped[sub.searchTag] = await service.fetchVenues(category: sub.searchTag, ville: city);
  }
  return grouped;
});
