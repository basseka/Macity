import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';
import 'package:pulz_app/features/sport/data/supabase_api_service.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

class TodayEventsData {
  final List<Event> events;
  final List<SupabaseMatch> matches;

  const TodayEventsData({required this.events, required this.matches});
}

/// Aggrege tous les evenements et matchs sur 30 jours glissants.
final todayTomorrowEventsProvider =
    FutureProvider<TodayEventsData>((ref) async {
  final city = ref.watch(selectedCityProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final endDate = today.add(const Duration(days: 30));
  final todayStr = _fmt(today);
  final endDateStr = _fmt(endDate);

  // Preferences utilisateur : liste vide = tout afficher
  final userPrefs = await ref.watch(userPreferencesProvider.future);
  final hasPrefs = userPrefs.isNotEmpty;

  final scraperService = ScrapedEventsSupabaseService();
  final matchService = SupabaseApiService();

  // Fetch uniquement les rubriques qui correspondent aux preferences
  final wantDay = !hasPrefs || userPrefs.contains('day');
  final wantCulture = !hasPrefs || userPrefs.contains('culture');
  final wantNight = !hasPrefs || userPrefs.contains('night');
  final wantSport = !hasPrefs || userPrefs.contains('sport');
  final wantFamily = !hasPrefs || userPrefs.contains('family');
  final wantFood = !hasPrefs || userPrefs.contains('food');

  List<Event> dayEvents = [];
  List<Event> cultureEvents = [];
  List<Event> nightEvents = [];
  List<Event> familyEvents = [];
  List<Event> foodEvents = [];
  List<SupabaseMatch> matches = [];

  try {
    final futures = <Future>[];
    if (wantDay) {
      futures.add(scraperService.fetchEvents(rubrique: 'day', dateGte: todayStr, ville: city, limit: 50));
    }
    if (wantCulture) {
      // Limit bumped to 300 pour couvrir les ~150-300 events cinéma/jour
      // (16 cinémas × 10-15 films × J+1) + le reste de la rubrique culture.
      futures.add(scraperService.fetchEvents(rubrique: 'culture', dateGte: todayStr, ville: city, limit: 300));
    }
    if (wantNight) {
      futures.add(scraperService.fetchEvents(rubrique: 'night', dateGte: todayStr, ville: city, limit: 50));
    }
    if (wantFamily) {
      futures.add(scraperService.fetchEvents(rubrique: 'family', dateGte: todayStr, ville: city, limit: 50));
    }
    if (wantFood) {
      futures.add(scraperService.fetchEvents(rubrique: 'food', dateGte: todayStr, ville: city, limit: 50));
    }
    if (wantSport) {
      futures.add(matchService.fetchMatches(
        ville: city,
        dateGte: todayStr,
        dateLt: endDateStr,
      ));
    }

    final results = await Future.wait(futures);
    var i = 0;
    if (wantDay) dayEvents = results[i++] as List<Event>;
    if (wantCulture) cultureEvents = results[i++] as List<Event>;
    if (wantNight) nightEvents = results[i++] as List<Event>;
    if (wantFamily) familyEvents = results[i++] as List<Event>;
    if (wantFood) foodEvents = results[i++] as List<Event>;
    if (wantSport) matches = results[i++] as List<SupabaseMatch>;
  } catch (e) {
    debugPrint('[weekEvents] error: $e');
  }

  // Filtrer les events pour les 30 prochains jours
  final allEvents = [...dayEvents, ...cultureEvents, ...nightEvents, ...familyEvents, ...foodEvents];
  final filtered = allEvents.where((e) {
    final d = DateTime.tryParse(e.dateDebut);
    if (d == null) return false;
    final dateOnly = DateTime(d.year, d.month, d.day);
    if (dateOnly.isBefore(today) || !dateOnly.isBefore(endDate)) return false;
    // Si event aujourd'hui AVEC horaires : cacher si toutes les séances sont
    // déjà passées (utile surtout pour les films cinéma qui ont des horaires
    // agrégés "14h30, 17h00, 20h30"). Les events sans horaires restent affichés.
    if (dateOnly == today && _allShowingsPast(e.horaires, now)) return false;
    return true;
  }).toList();

  // Ajouter les user events de la semaine
  final userEvents = ref.watch(userEventsProvider);
  final userFiltered = userEvents.where((ue) {
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
    final d = DateTime.tryParse(ue.date);
    if (d == null) return false;
    final dateOnly = DateTime(d.year, d.month, d.day);
    return !dateOnly.isBefore(today) && dateOnly.isBefore(endDate);
  }).map((ue) => ue.toEvent()).toList();

  filtered.addAll(userFiltered);

  // Trier par date
  filtered.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

  return TodayEventsData(events: filtered, matches: matches);
});

/// Tous les events a venir sans limite de jours (pour le sheet filtre par categorie).
final allFutureEventsProvider =
    FutureProvider<TodayEventsData>((ref) async {
  final city = ref.watch(selectedCityProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayStr = _fmt(today);

  final scraperService = ScrapedEventsSupabaseService();

  List<Event> dayEvents = [];
  List<Event> cultureEvents = [];
  List<Event> nightEvents = [];

  try {
    final results = await Future.wait([
      scraperService.fetchEvents(rubrique: 'day', dateGte: todayStr, ville: city, limit: 100),
      scraperService.fetchEvents(rubrique: 'culture', dateGte: todayStr, ville: city, limit: 80),
      scraperService.fetchEvents(rubrique: 'night', dateGte: todayStr, ville: city, limit: 80),
    ]);
    dayEvents = results[0];
    cultureEvents = results[1];
    nightEvents = results[2];
  } catch (e) {
    debugPrint('[allFutureEvents] error: $e');
  }

  final allEvents = [...dayEvents, ...cultureEvents, ...nightEvents];
  final filtered = allEvents.where((e) {
    final d = DateTime.tryParse(e.dateDebut);
    if (d == null) return false;
    final dateOnly = DateTime(d.year, d.month, d.day);
    if (dateOnly.isBefore(today)) return false;
    // Si event aujourd'hui AVEC horaires : cacher si toutes les séances
    // sont déjà passées. Les events sans horaires restent affichés.
    if (dateOnly == today && _allShowingsPast(e.horaires, now)) return false;
    return true;
  }).toList();

  // User events
  final userEvents = ref.watch(userEventsProvider);
  final userFiltered = userEvents.where((ue) {
    if (ue.ville.toLowerCase() != city.toLowerCase()) return false;
    final d = DateTime.tryParse(ue.date);
    if (d == null) return false;
    return !DateTime(d.year, d.month, d.day).isBefore(today);
  }).map((ue) => ue.toEvent()).toList();

  filtered.addAll(userFiltered);
  filtered.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

  return TodayEventsData(events: filtered, matches: []);
});

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Parse une chaîne type "14h30, 17h00, 20h30" et retourne `true` si toutes
/// les séances listées sont strictement dans le passé par rapport à [now].
/// Si [raw] est vide ou ne contient aucun horaire parsable, retourne `false`
/// (on ne filtre pas — les events sans horaires restent visibles).
bool _allShowingsPast(String raw, DateTime now) {
  if (raw.isEmpty) return false;
  final re = RegExp(r'(\d{1,2})h(\d{2})');
  final matches = re.allMatches(raw).toList();
  if (matches.isEmpty) return false;
  for (final m in matches) {
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final showTime = DateTime(now.year, now.month, now.day, h, min);
    if (!showTime.isBefore(now)) return false; // au moins une séance future
  }
  return true; // toutes passées
}
