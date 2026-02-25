import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/culture/data/culture_category_data.dart';
import 'package:pulz_app/features/culture/data/museum_events_toulouse_service.dart';
import 'package:pulz_app/features/culture/data/guided_tours_toulouse_service.dart';
import 'package:pulz_app/features/culture/data/meett_exhibitor_service.dart';
import 'package:pulz_app/features/culture/data/theatre_sorano_scraper.dart';
import 'package:pulz_app/features/culture/data/theatre_pont_neuf_scraper.dart';
import 'package:pulz_app/features/culture/data/cave_poesie_scraper.dart';
import 'package:pulz_app/features/culture/data/theatre_garonne_scraper.dart';
import 'package:pulz_app/features/culture/data/theatre_cite_scraper.dart';
import 'package:pulz_app/features/culture/data/theatre_capitole_scraper.dart';
import 'package:pulz_app/features/culture/data/theatre_grand_rond_scraper.dart';
import 'package:pulz_app/features/culture/data/grenier_theatre_scraper.dart';
import 'package:pulz_app/features/culture/data/three_t_scraper.dart';
import 'package:pulz_app/features/culture/data/theatre_du_pave_scraper.dart';
import 'package:pulz_app/features/culture/data/fil_a_plomb_scraper.dart';
import 'package:pulz_app/features/culture/data/theatre_mazades_scraper.dart';
import 'package:pulz_app/features/culture/data/theatre_violette_scraper.dart';
import 'package:pulz_app/features/culture/data/dance_venues_data.dart';
import 'package:pulz_app/features/culture/data/gallery_venues_data.dart';
import 'package:pulz_app/features/culture/data/library_venues_data.dart';
import 'package:pulz_app/features/culture/data/monument_venues_data.dart';
import 'package:pulz_app/features/culture/data/museum_venues_data.dart';
import 'package:pulz_app/features/culture/data/theatre_venues_data.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/core/database/app_database.dart';

final cultureCategoryProvider = StateProvider<String?>((ref) => null);

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

final cultureMuseumEventsProvider = FutureProvider<List<Event>>((ref) async {
  return MuseumEventsToulouseService().fetchUpcomingMuseumEvents();
});

/// Visites guidees depuis l'API Office de Tourisme + curate.
final cultureGuidedToursProvider = FutureProvider<List<Event>>((ref) async {
  return GuidedToursToulouseService().fetchUpcomingGuidedTours();
});

/// Expositions / salons du MEETT.
final cultureMeettEventsProvider = FutureProvider<List<Event>>((ref) async {
  return MeettExhibitorService().fetchExhibitions();
});

/// Theatre Sorano — programmation scrapee.
final theatreSoranoEventsProvider = FutureProvider<List<Event>>((ref) async {
  return TheatreSoranoScraper.fetchUpcomingEvents();
});

/// Theatre du Pont Neuf — programmation scrapee.
final theatrePontNeufEventsProvider = FutureProvider<List<Event>>((ref) async {
  return TheatrePontNeufScraper.fetchUpcomingEvents();
});

/// Cave Poesie Rene Gouzenne — programmation scrapee.
final cavePoesieEventsProvider = FutureProvider<List<Event>>((ref) async {
  return CavePoesieScraper.fetchUpcomingEvents();
});

/// Theatre Garonne — programmation scrapee.
final theatreGaronneEventsProvider = FutureProvider<List<Event>>((ref) async {
  return TheatreGaronneScraper.fetchUpcomingEvents();
});

/// Theatre de la Cite — programmation scrapee.
final theatreCiteEventsProvider = FutureProvider<List<Event>>((ref) async {
  return TheatreCiteScraper.fetchUpcomingEvents();
});

/// Theatre du Capitole — programmation via API REST.
final theatreCapitoleEventsProvider = FutureProvider<List<Event>>((ref) async {
  return TheatreCapitoleScraper.fetchUpcomingEvents();
});

/// Theatre du Grand Rond — programmation scrapee.
final theatreGrandRondEventsProvider = FutureProvider<List<Event>>((ref) async {
  return TheatreGrandRondScraper.fetchUpcomingEvents();
});

/// Grenier Theatre — programmation scrapee.
final grenierTheatreEventsProvider = FutureProvider<List<Event>>((ref) async {
  return GrenierTheatreScraper.fetchUpcomingEvents();
});

/// 3T Cafe Theatre — programmation via API REST + scraping HTML.
final threeTEventsProvider = FutureProvider<List<Event>>((ref) async {
  return ThreeTScraper.fetchUpcomingEvents();
});

/// Theatre du Pave — programmation via API Tribe Events Calendar.
final theatreDuPaveEventsProvider = FutureProvider<List<Event>>((ref) async {
  return TheatreDuPaveScraper.fetchUpcomingEvents();
});

/// Theatre le Fil a Plomb — programmation scrapee.
final filAPlombEventsProvider = FutureProvider<List<Event>>((ref) async {
  return FilAPlombScraper.fetchUpcomingEvents();
});

/// Theatre des Mazades — programmation scrapee via JSON-LD.
final theatreMazadesEventsProvider = FutureProvider<List<Event>>((ref) async {
  return TheatreMazadesScraper.fetchUpcomingEvents();
});

/// Theatre de la Violette — programmation scrapee via seances HTML.
final theatreVioletteEventsProvider = FutureProvider<List<Event>>((ref) async {
  return TheatreVioletteScraper.fetchUpcomingEvents();
});

/// Combine les 13 scrapers theatre en une seule liste.
final cultureTheatreEventsProvider = FutureProvider<List<Event>>((ref) async {
  final results = await Future.wait([
    ref.watch(theatreSoranoEventsProvider.future),
    ref.watch(theatrePontNeufEventsProvider.future),
    ref.watch(cavePoesieEventsProvider.future),
    ref.watch(theatreGaronneEventsProvider.future),
    ref.watch(theatreCiteEventsProvider.future),
    ref.watch(theatreCapitoleEventsProvider.future),
    ref.watch(theatreGrandRondEventsProvider.future),
    ref.watch(grenierTheatreEventsProvider.future),
    ref.watch(threeTEventsProvider.future),
    ref.watch(theatreDuPaveEventsProvider.future),
    ref.watch(filAPlombEventsProvider.future),
    ref.watch(theatreMazadesEventsProvider.future),
    ref.watch(theatreVioletteEventsProvider.future),
  ]);
  final all = <Event>[
    for (final r in results) ...r,
  ];
  all.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
  return all;
});

/// Mapping venue ID → nom du lieu utilise dans les scrapers.
const _venueIdToLieuNom = <String, String>{
  'theatre_de_la_cite': 'Theatre de la Cite',
  'sorano_theatre': 'Sorano',
  'theatre_garonne': 'Garonne',
  'la_cave_poesie': 'Cave Poesie',
  'theatre_du_pont_neuf': 'Pont Neuf',
  'theatre_du_capitole': 'Capitole',
  'theatre_du_grand_rond': 'Grand Rond',
  'grenier_theatre': 'Grenier',
  'cafe_theatre_les_3t': '3T',
  'theatre_du_pave': 'Pave',
  'theatre_le_fil_a_plomb': 'Fil a Plomb',
  'theatre_des_mazades': 'Mazades',
  'theatre_de_la_violette': 'Violette',
};

/// Events filtres pour une salle de theatre donnee.
final theatreVenueEventsProvider =
    FutureProvider.family<List<Event>, String>((ref, venueId) async {
  final keyword = _venueIdToLieuNom[venueId];
  if (keyword == null) return [];

  final allEvents = await ref.watch(cultureTheatreEventsProvider.future);
  return allEvents
      .where((e) => e.lieuNom.toLowerCase().contains(keyword.toLowerCase()))
      .toList();
});

final cultureCategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  if (searchTag == 'Musee') {
    return MuseumVenuesData.venues.length;
  }
  if (searchTag == 'Theatre') {
    return TheatreVenuesData.venues.length;
  }
  if (searchTag == 'Danse') {
    return DanceVenuesData.venues.length;
  }
  if (searchTag == "Galerie d'art") {
    return GalleryVenuesData.venues.length;
  }
  if (searchTag == 'Monument historique') {
    return MonumentVenuesData.venues.length;
  }
  if (searchTag == 'Bibliotheque') {
    return LibraryVenuesData.venues.length;
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
