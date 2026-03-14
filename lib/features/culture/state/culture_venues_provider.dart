import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/culture/data/culture_category_data.dart';
import 'package:pulz_app/features/culture/data/library_venues_data.dart';
import 'package:pulz_app/features/culture/data/library_venues_data.dart' show LibraryVenue;
import 'package:pulz_app/features/culture/data/monument_venues_data.dart' show MonumentVenue;
import 'package:pulz_app/features/culture/data/museum_venues_data.dart';
import 'package:pulz_app/features/culture/data/theatre_venues_data.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';

/// Evenements utilisateur filtres pour la rubrique "culture".
final cultureUserEventsProvider = Provider<List<Event>>((ref) {
  final city = ref.watch(selectedCityProvider);
  final allUserEvents = ref.watch(userEventsProvider);
  return allUserEvents
      .where((ue) =>
          ue.rubrique == 'culture' &&
          ue.ville.toLowerCase() == city.toLowerCase(),)
      .map((ue) => ue.toEvent())
      .toList();
});

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Tous les evenements culture scrapes (theatres + musees + visites + MEETT).
final cultureScrapedEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'culture',
    dateGte: _todayStr(),
    ville: city,
  );
});

/// Museum events : filtre les scrapes par source museum_toulouse.
final cultureMuseumEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'culture',
    source: 'museum_toulouse',
    dateGte: _todayStr(),
    ville: city,
  );
});

/// Visites guidees depuis la base.
final cultureGuidedToursProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'culture',
    source: 'guided_tours',
    dateGte: _todayStr(),
    ville: city,
  );
});

/// Expositions / salons du MEETT.
final cultureMeettEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'culture',
    source: 'meett',
    dateGte: _todayStr(),
    ville: city,
  );
});

/// Combine tous les theatre events depuis la base scraped_events.
/// Exclut les sources non-theatre (musees, visites, MEETT, balma) via filtre DB.
final cultureTheatreEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'culture',
    dateGte: _todayStr(),
    sourceNotIn: ['museum_toulouse', 'guided_tours', 'meett', 'balma_events'],
    ville: city,
  );
});

/// Theatre events agrégés progressivement — maintenant une seule requete DB.
final cultureTheatreEventsProgressiveProvider =
    Provider<({List<Event> events, bool isLoading})>((ref) {
  final async = ref.watch(cultureTheatreEventsProvider);
  return async.when(
    data: (events) => (events: events, isLoading: false),
    loading: () => (events: <Event>[], isLoading: true),
    error: (_, __) => (events: <Event>[], isLoading: false),
  );
});

/// Gallery venues depuis la table `venues` de Supabase, filtrees par ville.
final galleryVenuesSupabaseProvider =
    FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  try {
    final service = VenuesSupabaseService();
    return await service.fetchVenues(mode: 'culture', ville: city, category: "Galerie d'art");
  } catch (e) {
    return <CommerceModel>[];
  }
});

/// Library venues depuis la table `venues` de Supabase, filtrees par ville.
final libraryVenuesSupabaseProvider =
    FutureProvider<List<LibraryVenue>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  try {
    final service = VenuesSupabaseService();
    return await service.fetchLibraryVenues(ville: city);
  } catch (e) {
    return <LibraryVenue>[];
  }
});

/// Monument venues depuis la table `venues` de Supabase, filtrees par ville.
final monumentVenuesSupabaseProvider =
    FutureProvider<List<MonumentVenue>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  try {
    final service = VenuesSupabaseService();
    return await service.fetchMonumentVenues(ville: city);
  } catch (e) {
    return <MonumentVenue>[];
  }
});

/// Museum venues depuis la table `venues` de Supabase, filtrees par ville.
final museumVenuesSupabaseProvider =
    FutureProvider<List<MuseumVenue>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  try {
    final service = VenuesSupabaseService();
    return await service.fetchMuseumVenues(ville: city);
  } catch (e) {
    return <MuseumVenue>[];
  }
});

/// Theatre venues depuis la table `venues` de Supabase, filtrees par ville.
final theatreVenuesSupabaseProvider =
    FutureProvider<List<TheatreVenue>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  try {
    final service = VenuesSupabaseService();
    return await service.fetchTheatreVenues(ville: city);
  } catch (e) {
    return <TheatreVenue>[];
  }
});

/// Mapping venue ID → source ID pour filtrer par salle de theatre.
const _venueIdToSource = <String, String>{
  'theatre_de_la_cite': 'theatre_cite',
  'sorano_theatre': 'theatre_sorano',
  'theatre_garonne': 'theatre_garonne',
  'la_cave_poesie': 'cave_poesie',
  'theatre_du_pont_neuf': 'theatre_pont_neuf',
  'theatre_du_capitole': 'theatre_capitole',
  'theatre_du_grand_rond': 'theatre_grand_rond',
  'grenier_theatre': 'grenier_theatre',
  'cafe_theatre_les_3t': 'three_t',
  'theatre_du_pave': 'theatre_du_pave',
  'theatre_le_fil_a_plomb': 'fil_a_plomb',
  'theatre_des_mazades': 'mazades',
  'theatre_de_la_violette': 'theatre_violette',
  'theatre_de_poche': 'theatre_de_poche',
  'theatre_du_chien_blanc': 'theatre_chien_blanc',
  'theatre_de_la_brique_rouge': 'briquerouge',
  'nouveau_theatre_jules_julien': 'theatre_jules_julien',
};

/// Events filtres pour une salle de theatre donnee (par source ID).
final theatreVenueEventsProvider =
    FutureProvider.family<List<Event>, String>((ref, venueId) async {
  final sourceId = _venueIdToSource[venueId];
  if (sourceId == null) return [];

  final city = ref.watch(selectedCityProvider);
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'culture',
    source: sourceId,
    dateGte: _todayStr(),
    ville: city,
  );
});

/// Theatre sélectionné pour afficher sa programmation.
final selectedTheatreIdProvider = StateProvider<String?>((ref) => null);

final cultureCategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  if (searchTag == 'Musee') {
    final venues = await ref.watch(museumVenuesSupabaseProvider.future);
    return venues.length;
  }
  if (searchTag == 'Theatre') {
    final venues = await ref.watch(theatreVenuesSupabaseProvider.future);
    return venues.length;
  }
  if (searchTag == 'Danse') {
    final venues = await ref.watch(danceVenuesProvider.future);
    return venues.length;
  }
  if (searchTag == "Galerie d'art") {
    final venues = await ref.watch(galleryVenuesSupabaseProvider.future);
    return venues.length;
  }
  if (searchTag == 'Monument historique') {
    final venues = await ref.watch(monumentVenuesSupabaseProvider.future);
    return venues.length;
  }
  if (searchTag == 'Bibliotheque') {
    final venues = await ref.watch(libraryVenuesSupabaseProvider.future);
    return venues.length;
  }
  if (searchTag == 'Visites guidees') {
    final events = await ref.watch(cultureGuidedToursProvider.future);
    final uc = ref.watch(cultureUserEventsProvider).where((e) {
      final cat = e.categorie.toLowerCase();
      return cat.contains('visite');
    }).length;
    return events.length + uc;
  }
  if (searchTag == 'Exposition') {
    final events = await ref.watch(cultureMeettEventsProvider.future);
    final uc = ref.watch(cultureUserEventsProvider).where((e) {
      final cat = e.categorie.toLowerCase();
      return cat.contains('expo');
    }).length;
    return events.length + uc;
  }
  if (searchTag == 'A venir') {
    final events = await ref.watch(cultureMuseumEventsProvider.future);
    final theatreEvents = await ref.watch(cultureTheatreEventsProvider.future);
    final userCount = ref.watch(cultureUserEventsProvider).length;
    return events.where(_isKnownCultureCategory).length +
        theatreEvents.length +
        userCount;
  }
  // Ajouter les user events pour cette sous-categorie
  final userCount = ref.watch(cultureUserEventsProvider).where((e) {
    final cat = e.categorie.toLowerCase();
    final tag = searchTag.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).length;
  final city = ref.watch(selectedCityProvider);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  final venues = await repository.searchByVille(ville: city, query: searchTag);
  return venues.length + userCount;
});

final cultureVenuesProvider = FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final category = ref.watch(cultureCategoryProvider);

  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  if (category == 'A venir') {
    final allCategories = CultureCategoryData.allSubcategories
        .where((s) => s.searchTag != 'A venir')
        .map((s) => s.searchTag);
    final all = <CommerceModel>[];
    for (final tag in allCategories) {
      final venues = await repository.searchByVille(ville: city, query: tag);
      all.addAll(venues);
    }
    return all;
  }
  return repository.searchByVille(ville: city, query: category);
});

/// Retourne true si l'événement appartient à une catégorie culture connue.
bool _isKnownCultureCategory(Event e) {
  final cat = e.categorie.toLowerCase();
  final type = e.type.toLowerCase();
  if (cat.contains('exposition') || type.contains('exposition')) return true;
  if (cat.contains('visite') || type.contains('visite')) return true;
  if (cat.contains('vernissage') || type.contains('vernissage')) return true;
  if (cat.contains('atelier') || type.contains('atelier')) return true;
  if (cat.contains('animation') || type.contains('animation')) return true;
  return false;
}
