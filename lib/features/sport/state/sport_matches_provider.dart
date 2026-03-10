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
  // Seule Toulouse est implémentée pour l'instant
  final city = ref.watch(selectedCityProvider);
  if (city.toLowerCase() != 'toulouse') return 0;

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
  final repository = SportRepository();
  final matches =
      await repository.fetchSupabaseMatches(sport: searchTag, ville: city);

  // Compter aussi les user events sport
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final userCount = userEvents.where((ue) {
    if (ue.rubrique != 'sport') return false;
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
    if (searchTag == 'A venir') {
      final eventDate = DateTime.tryParse(ue.date);
      if (eventDate == null) return false;
      return !eventDate.isBefore(today);
    }
    final cat = ue.categorie.toLowerCase();
    final tag = searchTag.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).length;

  if (searchTag == 'A venir') {
    return matches.where(_isKnownSport).length + userCount;
  }
  return matches.length + userCount;
});

final sportMatchesProvider = FutureProvider<List<SupabaseMatch>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  // Seule Toulouse est implémentée pour l'instant
  if (city.toLowerCase() != 'toulouse') return [];

  final rawSubcategory = ref.watch(sportSubcategoryProvider);
  // 'Boxe matchs' → query 'Boxe' in DB
  final subcategory = rawSubcategory == 'Boxe matchs' ? 'Boxe' : rawSubcategory;

  final repository = SportRepository();
  final matches = await repository.fetchSupabaseMatches(
    sport: subcategory,
    ville: city,
  );

  // Merge user events sport
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final matchingUserEvents = userEvents.where((ue) {
    if (ue.rubrique != 'sport') return false;
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
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

  // Pour "A venir", exclure les matchs catégorisés "Autres"
  if (subcategory == 'A venir') {
    return [...matchingUserEvents, ...matches.where(_isKnownSport)];
  }
  return [...matchingUserEvents, ...matches];
});

/// Retourne true si le match appartient à un sport connu.
bool _isKnownSport(SupabaseMatch m) {
  final s = m.sport.toLowerCase();
  if (s.contains('rugby')) return true;
  if (s.contains('football')) return true;
  if (s.contains('basket')) return true;
  if (s.contains('handball') || s.contains('hand')) return true;
  if (s.contains('boxe')) return true;
  if (s.contains('natation')) return true;
  if (s.contains('course')) return true;
  return false;
}
