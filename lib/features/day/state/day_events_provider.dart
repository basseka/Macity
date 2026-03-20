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

  // "A venir" dans day = tous les events scraped + communautaires
  if (searchTag == 'A venir') {
    final repository = EventRepository();
    final scrapedEvents = await repository.fetchEvents(city: city, subcategory: 'A venir');
    final communityCount = ref.watch(dayCommunityCountProvider);
    return scrapedEvents.length + communityCount;
  }

  final repository = EventRepository();
  final apiEvents =
      await repository.fetchEvents(city: city, subcategory: searchTag);

  // Compter aussi les user events qui correspondent
  final userEvents = ref.watch(userEventsProvider);
  final matchingUserCount = userEvents.where((ue) {
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
    return ue.categorie.toLowerCase() == searchTag.toLowerCase();
  }).length;

  return apiEvents.length + matchingUserCount;
});

/// Nombre d'events day créés par la communauté (user_events, rubrique day).
final dayCommunityCountProvider = Provider<int>((ref) {
  final city = ref.watch(selectedCityProvider);
  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return userEvents.where((ue) {
    if (ue.rubrique != 'day') return false;
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
    final eventDate = DateTime.tryParse(ue.date);
    if (eventDate == null) return false;
    return !eventDate.isBefore(today);
  }).length;
});

final dayEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final subcategory = ref.watch(daySubcategoryProvider);
  if (subcategory == null) return [];

  final userEvents = ref.watch(userEventsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // "A venir" = tous les events scraped (avec/sans photo) + communautaires
  if (subcategory == 'A venir') {
    final repository = EventRepository();
    final scrapedEvents = await repository.fetchEvents(city: city, subcategory: 'A venir');

    final communityEvents = userEvents
        .where((ue) {
          if (ue.rubrique != 'day') return false;
          if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
          final eventDate = DateTime.tryParse(ue.date);
          if (eventDate == null) return false;
          return !eventDate.isBefore(today);
        })
        .map((ue) => ue.toEvent())
        .toList();

    return [...communityEvents, ...scrapedEvents];
  }

  final repository = EventRepository();
  final apiEvents = await repository.fetchEvents(city: city, subcategory: subcategory);

  final matchingUserEvents = userEvents.where((ue) {
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
    return ue.categorie.toLowerCase() == subcategory.toLowerCase();
  }).toList();

  final userConverted = matchingUserEvents.map((ue) => ue.toEvent()).toList();
  return [...userConverted, ...apiEvents];
});

/// Events filtrés par salle (lieuNom contient le keyword).
/// Utilise la sous-catégorie courante (Concert, DJ set, Spectacle, etc.).
final dayVenueEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final venueKeyword = ref.watch(selectedConcertVenueProvider);
  final subcategory = ref.watch(daySubcategoryProvider);
  if (venueKeyword == null || subcategory == null) return [];

  final repository = EventRepository();
  return repository.fetchEvents(
    city: city,
    subcategory: subcategory,
    lieuNom: venueKeyword,
  );
});

/// Count des events par salle (générique, fonctionne pour toutes les catégories).
final concertVenueCountProvider =
    FutureProvider.family<int, String>((ref, keyword) async {
  final city = ref.watch(selectedCityProvider);
  final subcategory = ref.watch(daySubcategoryProvider);
  if (subcategory == null) return 0;

  final repository = EventRepository();
  final events = await repository.fetchEvents(
    city: city,
    subcategory: subcategory,
    lieuNom: keyword,
  );
  return events.length;
});

/// Retourne true si l'événement appartient à une catégorie connue (pas "Autres").
