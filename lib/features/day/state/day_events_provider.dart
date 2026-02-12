import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/data/event_repository.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';

final daySubcategoryProvider = StateProvider<String?>((ref) => null);

/// Count provider per subcategory (used for badge on grid cards).
/// Inclut les événements API + les événements utilisateur correspondants.
final daySubcategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final city = ref.watch(selectedCityProvider);
  final repository = EventRepository();
  var apiEvents =
      await repository.fetchEvents(city: city, subcategory: searchTag);

  // Pour "Cette Semaine", exclure les événements catégorisés "Autres"
  if (searchTag == 'Cette Semaine') {
    apiEvents = apiEvents.where(_isKnownCategory).toList();
  }

  // Compter aussi les user events qui correspondent
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));

  final matchingUserCount = userEvents.where((ue) {
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;

    if (searchTag == 'Cette Semaine') {
      final eventDate = DateTime.tryParse(ue.date);
      if (eventDate == null) return false;
      return !eventDate.isBefore(weekStart) && eventDate.isBefore(weekEnd);
    }

    return ue.categorie.toLowerCase() == searchTag.toLowerCase();
  }).length;

  return apiEvents.length + matchingUserCount;
});

final dayEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final subcategory = ref.watch(daySubcategoryProvider);
  if (subcategory == null) return [];

  final repository = EventRepository();
  var apiEvents = await repository.fetchEvents(city: city, subcategory: subcategory);

  // Pour "Cette Semaine", exclure les événements catégorisés "Autres"
  if (subcategory == 'Cette Semaine') {
    apiEvents = apiEvents.where(_isKnownCategory).toList();
  }

  // Merge local user events
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));

  final matchingUserEvents = userEvents.where((ue) {
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;

    if (subcategory == 'Cette Semaine') {
      // Show all user events whose date falls in the current week
      final eventDate = DateTime.tryParse(ue.date);
      if (eventDate == null) return false;
      return !eventDate.isBefore(weekStart) && eventDate.isBefore(weekEnd);
    }

    // Match by categorie (subcategory name)
    return ue.categorie.toLowerCase() == subcategory.toLowerCase();
  }).toList();

  // User events first, then API events
  final userConverted = matchingUserEvents.map((ue) => ue.toEvent()).toList();
  return [...userConverted, ...apiEvents];
});

/// Retourne true si l'événement appartient à une catégorie connue (pas "Autres").
bool _isKnownCategory(Event e) {
  final cat = e.categorie.toLowerCase();
  final type = e.type.toLowerCase();
  if (cat.contains('concert') || type.contains('concert')) return true;
  if (cat.contains('festival') || type.contains('festival')) return true;
  if (cat.contains('opera') || type.contains('opera')) return true;
  if (cat.contains('spectacle') || type.contains('spectacle')) return true;
  if (cat.contains('dj') || type.contains('dj')) return true;
  if (cat.contains('showcase') || type.contains('showcase')) return true;
  return false;
}
