import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/data/sport_repository.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';

// Map searchTag → sport_type pour les venues
const _tagToSportType = <String, String>{
  'Salle de fitness': 'fitness',
  'Salles de boxe': 'boxe',
  'Terrain de football': 'terrain-football',
  'Terrain de basketball': 'terrain-basketball',
  'Piscine': 'piscine',
  'Golf': 'golf',
  'Tennis': 'tennis',
  'Padel': 'padel',
  'Squash': 'squash',
  'Ping-pong': 'ping-pong',
  'Badminton': 'badminton',
};

final sportSubcategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final city = ref.watch(selectedCityProvider);

  // Venues statiques/Supabase
  final sportType = _tagToSportType[searchTag];
  if (sportType != null) {
    final venues = await ref.watch(sportVenuesProvider(sportType).future);
    return venues.length;
  }
  if (searchTag == 'Danse') {
    final venues = await ref.watch(danceVenuesProvider.future);
    return venues.length;
  }
  if (searchTag == 'Raquette') {
    final venues = await ref.watch(racketAllVenuesProvider.future);
    return venues.length;
  }
  // "A venir" = tous les matchs scraped + events communautaires
  if (searchTag == 'A venir') {
    final repository = SportRepository();
    final allMatches = await repository.fetchSupabaseMatches(ville: city);
    final userEvents = ref.watch(userEventsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final communityCount = userEvents.where((ue) {
      if (ue.rubrique != 'sport') return false;
      if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
      final eventDate = DateTime.tryParse(ue.date);
      if (eventDate == null) return false;
      return !eventDate.isBefore(today);
    }).length;
    return allMatches.length + communityCount;
  }

  final repository = SportRepository();
  final matches =
      await repository.fetchSupabaseMatches(sport: searchTag, ville: city);

  // Compter aussi les user events sport (+ culture pour Stage de danse)
  final userEvents = ref.watch(userEventsProvider);

  final userCount = userEvents.where((ue) {
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;

    // Stage de danse : accepter aussi les user events culture/danse/stage
    if (searchTag.toLowerCase().contains('stage de danse')) {
      if (ue.rubrique == 'sport' || ue.rubrique == 'culture') {
        final cat = ue.categorie.toLowerCase();
        return cat.contains('stage') || cat.contains('danse');
      }
      return false;
    }

    if (ue.rubrique != 'sport') return false;
    final cat = ue.categorie.toLowerCase();
    final tag = searchTag.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).length;

  // Handball : compter uniquement les matchs a domicile
  if (searchTag.toLowerCase().contains('hand')) {
    final homeCount = matches.where((m) {
      final dom = m.equipe1.toLowerCase();
      return dom.contains('fenix') || dom.contains('toulouse');
    }).length;
    return homeCount + userCount;
  }

  return matches.length + userCount;
});

final sportMatchesProvider = FutureProvider<List<SupabaseMatch>>((ref) async {
  final city = ref.watch(selectedCityProvider);

  final rawSubcategory = ref.watch(sportSubcategoryProvider);
  // 'Boxe matchs' → query 'Boxe' in DB
  final subcategory = rawSubcategory == 'Boxe matchs' ? 'Boxe' : rawSubcategory;

  final repository = SportRepository();
  final matches = await repository.fetchSupabaseMatches(
    sport: subcategory,
    ville: city,
  );

  // Merge user events sport (+ culture pour Stage de danse)
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final matchingUserEvents = userEvents.where((ue) {
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;

    // Stage de danse : accepter aussi les user events culture/danse/stage
    if (subcategory != null && subcategory.toLowerCase().contains('stage de danse')) {
      if (ue.rubrique == 'sport' || ue.rubrique == 'culture') {
        final cat = ue.categorie.toLowerCase();
        return cat.contains('stage') || cat.contains('danse');
      }
      return false;
    }

    if (ue.rubrique != 'sport') return false;
    if (subcategory == 'A venir') {
      final eventDate = DateTime.tryParse(ue.date);
      if (eventDate == null) return false;
      return !eventDate.isBefore(today);
    }
    if (subcategory == null) return true;
    final cat = ue.categorie.toLowerCase();
    final tag = subcategory.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).map((ue) => ue.toSupabaseMatch()).toList();

  // "A venir" = tous les matchs scraped + events communautaires
  if (subcategory == 'A venir') {
    final allMatches = await repository.fetchSupabaseMatches(ville: city);
    final merged = [...matchingUserEvents, ...allMatches];
    merged.sort(_compareByDateTime);
    return merged;
  }

  // Handball : uniquement les matchs a domicile (Fenix en equipe_dom)
  if (subcategory != null && subcategory.toLowerCase().contains('hand')) {
    final homeOnly = matches.where((m) {
      final dom = m.equipe1.toLowerCase();
      return dom.contains('fenix') || dom.contains('toulouse');
    }).toList();
    final merged = [...matchingUserEvents, ...homeOnly];
    merged.sort(_compareByDateTime);
    return merged;
  }

  final merged = [...matchingUserEvents, ...matches];
  merged.sort(_compareByDateTime);
  return merged;
});

int _compareByDateTime(SupabaseMatch a, SupabaseMatch b) {
  final dateA = DateTime.tryParse(a.date) ?? DateTime(2099);
  final dateB = DateTime.tryParse(b.date) ?? DateTime(2099);
  final cmp = dateA.compareTo(dateB);
  if (cmp != 0) return cmp;
  return a.heure.compareTo(b.heure);
}

