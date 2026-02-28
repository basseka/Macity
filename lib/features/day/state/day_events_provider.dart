import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/data/event_repository.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

/// Salle de concert sélectionnée (keyword) — null = grille des salles.
final selectedConcertVenueProvider = StateProvider<String?>((ref) => null);

/// Count provider per subcategory (used for badge on grid cards).
/// Inclut les événements API + les événements utilisateur correspondants.
final daySubcategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final city = ref.watch(selectedCityProvider);
  final repository = EventRepository();
  var apiEvents =
      await repository.fetchEvents(city: city, subcategory: searchTag);

  // Pour "A venir", exclure les événements catégorisés "Autres"
  if (searchTag == 'A venir') {
    apiEvents = apiEvents.where(_isKnownCategory).toList();
  }

  // Compter aussi les user events qui correspondent
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final matchingUserCount = userEvents.where((ue) {
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;

    if (searchTag == 'A venir') {
      final eventDate = DateTime.tryParse(ue.date);
      if (eventDate == null) return false;
      return !eventDate.isBefore(today);
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

  // Pour "A venir", exclure les événements catégorisés "Autres"
  if (subcategory == 'A venir') {
    apiEvents = apiEvents.where(_isKnownCategory).toList();
  }

  // Merge local user events
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final matchingUserEvents = userEvents.where((ue) {
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;

    if (subcategory == 'A venir') {
      final eventDate = DateTime.tryParse(ue.date);
      if (eventDate == null) return false;
      return !eventDate.isBefore(today);
    }

    // Match by categorie (subcategory name)
    return ue.categorie.toLowerCase() == subcategory.toLowerCase();
  }).toList();

  // User events first, then API events
  final userConverted = matchingUserEvents.map((ue) => ue.toEvent()).toList();
  return [...userConverted, ...apiEvents];
});

/// Events filtrés par salle de concert (lieuNom contient le keyword).
final dayVenueEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final venueKeyword = ref.watch(selectedConcertVenueProvider);
  if (venueKeyword == null) return [];

  final repository = EventRepository();
  return repository.fetchEvents(
    city: city,
    subcategory: 'Concert',
    lieuNom: venueKeyword,
  );
});

/// Count des events par salle de concert.
final concertVenueCountProvider =
    FutureProvider.family<int, String>((ref, keyword) async {
  final city = ref.watch(selectedCityProvider);
  final repository = EventRepository();
  final events = await repository.fetchEvents(
    city: city,
    subcategory: 'Concert',
    lieuNom: keyword,
  );
  return events.length;
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
  if (cat.contains('stand up') || type.contains('stand up')) return true;
  return false;
}
