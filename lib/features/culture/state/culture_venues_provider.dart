import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/culture/data/culture_category_data.dart';
import 'package:pulz_app/features/culture/data/museum_events_toulouse_service.dart';
import 'package:pulz_app/features/culture/data/guided_tours_toulouse_service.dart';
import 'package:pulz_app/features/culture/data/meett_exhibitor_service.dart';
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
          ue.ville.toLowerCase() == city.toLowerCase())
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
  if (searchTag == 'Cette Semaine') {
    final events = await ref.watch(cultureMuseumEventsProvider.future);
    final userCount = ref.watch(cultureUserEventsProvider).length;
    return events.where(_isKnownCultureCategory).length + userCount;
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
  if (category == 'Cette Semaine') {
    final allCategories = CultureCategoryData.allSubcategories
        .where((s) => s.searchTag != 'Cette Semaine')
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
