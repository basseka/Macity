import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/home/state/paginated_feed_provider.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

/// Parse l'heure de debut depuis un string horaire.
/// Supporte : "20h00", "20h", "14h30 - 22h00", "20:00", "a partir de 19h".
int? _parseStartHour(String horaires) {
  if (horaires.isEmpty) return null;
  final match = RegExp(r'(\d{1,2})\s*[hH:]\s*(\d{0,2})').firstMatch(horaires);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

// ── "Que faire maintenant" ──

class RightNowData {
  final List<Event> todayEvents;
  final List<SupabaseMatch> todayMatches;
  final List<CommerceModel> hotVenues;

  const RightNowData({
    this.todayEvents = const [],
    this.todayMatches = const [],
    this.hotVenues = const [],
  });
}

final rightNowProvider = FutureProvider<RightNowData>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final now = DateTime.now();
  final todayStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final tomorrowStr = () {
    final t = now.add(const Duration(days: 1));
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }();

  final scraperService = ScrapedEventsSupabaseService();
  final venuesService = VenuesSupabaseService();

  // Events d'aujourd'hui (toutes rubriques, date = today)
  List<Event> todayEvents = [];
  try {
    final (fetchedEvents, _) = await scraperService.fetchAllEvents(
      dateGte: todayStr,
      ville: city,
      limit: 20,
    );
    todayEvents = fetchedEvents;
    // Garder seulement les events d'aujourd'hui dont l'heure n'est pas passee
    final currentHour = now.hour;
    todayEvents = todayEvents.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) return false;
      final dateOnly = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (dateOnly != todayStr) return false;
      // Parser l'heure depuis horaires (ex: "20h00", "14h30 - 22h00")
      final h = _parseStartHour(e.horaires);
      // Si pas d'heure parsable, garder l'event (on ne sait pas)
      if (h == null) return true;
      // Garder si l'event commence dans les prochaines heures ou est en cours
      // (heure de debut >= maintenant - 2h)
      return h >= currentHour - 2;
    }).toList();
  } catch (e) {
    debugPrint('[RightNow] events error: $e');
  }

  // Matchs d'aujourd'hui pas encore termines
  List<SupabaseMatch> todayMatches = [];
  try {
    final feedState = ref.read(paginatedFeedProvider);
    todayMatches = feedState.matches.where((m) {
      if (!m.date.startsWith(todayStr)) return false;
      final h = _parseStartHour(m.heure);
      if (h == null) return true;
      return h >= now.hour - 2;
    }).toList();
  } catch (_) {}

  // Lieux animes (display_count > 0)
  List<CommerceModel> hotVenues = [];
  try {
    hotVenues = await venuesService.fetchHotVenues(ville: city, limit: 10);
  } catch (e) {
    debugPrint('[RightNow] venues error: $e');
  }

  return RightNowData(
    todayEvents: todayEvents,
    todayMatches: todayMatches,
    hotVenues: hotVenues,
  );
});

// ── "Autour de moi" ──

class NearbyParams {
  final double lat;
  final double lon;
  final String? category;

  const NearbyParams({required this.lat, required this.lon, this.category});

  @override
  bool operator ==(Object other) =>
      other is NearbyParams && lat == other.lat && lon == other.lon && category == other.category;

  @override
  int get hashCode => Object.hash(lat, lon, category);
}

final nearbyProvider =
    FutureProvider.family<List<CommerceModel>, NearbyParams>((ref, params) async {
  final city = ref.watch(selectedCityProvider);
  final venuesService = VenuesSupabaseService();

  // Charger tous les venues de la ville
  final venues = await venuesService.fetchAllVenues(
    ville: city,
    category: params.category,
  );

  // Calculer les distances
  final withDistance = venues.map((v) {
    final dist = Haversine.distanceInMeters(
      params.lat,
      params.lon,
      v.latitude,
      v.longitude,
    ).round();
    return v.copyWith(
      distanceMetres: dist,
      distance: Haversine.formatDistance(dist.toDouble()),
    );
  }).toList();

  // Trier par distance, garder les 30 plus proches
  withDistance.sort((a, b) => a.distanceMetres.compareTo(b.distanceMetres));
  return withDistance.take(30).toList();
});

/// Obtenir la position GPS avec permission.
Future<Position?> getCurrentPosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  if (permission == LocationPermission.deniedForever) return null;

  // Position rapide d'abord
  final lastKnown = await Geolocator.getLastKnownPosition();
  if (lastKnown != null) return lastKnown;

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}
