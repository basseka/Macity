import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/night/data/night_bars_data.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

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

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Evenements scrapes des clubs de nuit (Nine Club + Etoile) depuis la DB.
final nightScrapedEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'night',
    dateGte: _todayStr(),
    ville: city,
  );
});

/// Filtre les events pour ne garder que ceux a venir (>= aujourd'hui).
List<Event> _upcomingOnly(List<Event> events) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return events.where((e) {
    final d = DateTime.tryParse(e.dateDebut);
    return d != null && !d.isBefore(today);
  }).toList();
}

int _nightUserCount(List<Event> userEvents, List<Event> scrapedEvents, String searchTag) {
  if (searchTag == 'A venir') {
    return _upcomingOnly(userEvents).length + _upcomingOnly(scrapedEvents).length;
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
  final scrapedEvents = ref.watch(nightScrapedEventsProvider).valueOrNull ?? [];
  final uc = _nightUserCount(userEvents, scrapedEvents, searchTag);
  if (searchTag == 'A venir') {
    return uc;
  }
  if (_curatedTags.contains(searchTag)) {
    final city = ref.watch(selectedCityProvider);
    try {
      final count = await VenuesSupabaseService().countVenues(
        mode: 'night', ville: city, category: searchTag,
      );
      return count + uc;
    } catch (_) {
      return NightBarsData.toulouseBars
          .where((b) => b.categorie == searchTag)
          .length + uc;
    }
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
    try {
      final venues = await VenuesSupabaseService().fetchVenues(
        mode: 'night', ville: city, category: category,
      );
      if (venues.isNotEmpty) return venues;
    } catch (_) {}
    // Fallback statique
    return NightBarsData.toulouseBars
        .where((b) => b.categorie == category)
        .toList();
  }

  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  return repository.searchByVille(ville: city, query: category);
});
