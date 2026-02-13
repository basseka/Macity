import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/sport/data/fitness_venues_data.dart';
import 'package:pulz_app/features/sport/data/sport_repository.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

final sportSubcategoryProvider = StateProvider<String?>((ref) => null);

final sportSubcategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  if (searchTag == 'Salle de fitness') {
    return FitnessVenuesData.venues.length;
  }
  final city = ref.watch(selectedCityProvider);
  final repository = SportRepository();
  final matches =
      await repository.fetchSupabaseMatches(sport: searchTag, ville: city);

  // Compter aussi les user events sport
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));

  final userCount = userEvents.where((ue) {
    if (ue.rubrique != 'sport') return false;
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
    if (searchTag == 'Cette Semaine') {
      final eventDate = DateTime.tryParse(ue.date);
      if (eventDate == null) return false;
      return !eventDate.isBefore(weekStart) && eventDate.isBefore(weekEnd);
    }
    final cat = ue.categorie.toLowerCase();
    final tag = searchTag.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).length;

  if (searchTag == 'Cette Semaine') {
    return matches.where(_isKnownSport).length + userCount;
  }
  return matches.length + userCount;
});

final sportMatchesProvider = FutureProvider<List<SupabaseMatch>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final subcategory = ref.watch(sportSubcategoryProvider);

  final repository = SportRepository();
  final matches = await repository.fetchSupabaseMatches(
    sport: subcategory,
    ville: city,
  );

  // Merge user events sport
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));

  final matchingUserEvents = userEvents.where((ue) {
    if (ue.rubrique != 'sport') return false;
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
    if (subcategory == 'Cette Semaine') {
      final eventDate = DateTime.tryParse(ue.date);
      if (eventDate == null) return false;
      return !eventDate.isBefore(weekStart) && eventDate.isBefore(weekEnd);
    }
    if (subcategory == null) return true;
    final cat = ue.categorie.toLowerCase();
    final tag = subcategory.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).map((ue) => ue.toSupabaseMatch()).toList();

  // Pour "Cette Semaine", exclure les matchs catégorisés "Autres"
  if (subcategory == 'Cette Semaine') {
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
