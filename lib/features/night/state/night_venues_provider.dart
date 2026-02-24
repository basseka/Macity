import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/night/data/night_bars_data.dart';
import 'package:pulz_app/features/night/data/etoile_scraper.dart';
import 'package:pulz_app/features/night/data/nine_club_scraper.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';

final nightCategoryProvider = StateProvider<String?>((ref) => null);

/// Tags qui utilisent les donnees curatees au lieu de la base locale.
const _curatedTags = {'Bar de nuit', 'Bar a cocktails', 'Pub', 'Club Discotheque', 'Epicerie de nuit', 'Tabac de nuit', 'Hotel', 'SOS Apero'};

/// Evenements utilisateur filtres pour la rubrique "night".
final nightUserEventsProvider = Provider<List<Event>>((ref) {
  final city = ref.watch(selectedCityProvider);
  final allUserEvents = ref.watch(userEventsProvider);
  return allUserEvents
      .where((ue) =>
          ue.rubrique == 'night' &&
          ue.ville.toLowerCase() == city.toLowerCase())
      .map((ue) => ue.toEvent())
      .toList();
});

/// Evenements scrapes du Nine Club (async).
final nineClubEventsProvider = FutureProvider<List<Event>>((ref) async {
  return NineClubScraper.fetchUpcomingEvents();
});

/// Evenements scrapes de L'Etoile Toulouse (async).
final etoileEventsProvider = FutureProvider<List<Event>>((ref) async {
  return EtoileScraper.fetchUpcomingEvents();
});

/// Filtre les events pour ne garder que ceux dans les 7 prochains jours.
List<Event> _thisWeekOnly(List<Event> events) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final limit = today.add(const Duration(days: 7));
  return events.where((e) {
    final d = DateTime.tryParse(e.dateDebut);
    return d != null && !d.isBefore(today) && d.isBefore(limit);
  }).toList();
}

int _nightUserCount(List<Event> userEvents, List<Event> scrapedEvents, String searchTag) {
  if (searchTag == 'A venir') {
    return _thisWeekOnly(userEvents).length + _thisWeekOnly(scrapedEvents).length;
  }
  return userEvents.where((e) {
    final cat = e.categorie.toLowerCase();
    final tag = searchTag.toLowerCase();
    return cat.contains(tag) || tag.contains(cat);
  }).length;
}

final nightCategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final userEvents = ref.watch(nightUserEventsProvider);
  final scrapedEvents = <Event>[
    ...ref.watch(nineClubEventsProvider).valueOrNull ?? [],
    ...ref.watch(etoileEventsProvider).valueOrNull ?? [],
  ];
  final uc = _nightUserCount(userEvents, scrapedEvents, searchTag);
  if (searchTag == 'A venir') {
    return uc;
  }
  if (_curatedTags.contains(searchTag)) {
    return NightBarsData.toulouseBars
        .where((b) => b.categorie == searchTag)
        .length + uc;
  }
  final city = ref.watch(selectedCityProvider);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  final venues = await repository.searchByVille(ville: city, query: searchTag);
  return venues.length + uc;
});

final nightVenuesProvider = FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final category = ref.watch(nightCategoryProvider);

  if (_curatedTags.contains(category)) {
    return NightBarsData.toulouseBars
        .where((b) => b.categorie == category)
        .toList();
  }

  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  return repository.searchByVille(ville: city, query: category);
});
