import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/reported_events/data/city_centers.dart';
import 'package:pulz_app/features/reported_events/data/reported_events_service.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';

/// Singleton du service.
final reportedEventsServiceProvider = Provider<ReportedEventsService>(
  (_) => ReportedEventsService(),
);

/// Feed des signalements actifs (publies, non expires) dans la zone de la
/// ville selectionnee, **tries par distance au centre ville croissante**
/// (les plus proches en premier).
///
/// Le service utilise un bounding box (~25-30 km) autour du centre de la
/// ville pour inclure la metropole entiere — Toulouse couvre Montrabe, Balma,
/// Colomiers, etc. mais pas Paris.
///
/// A invalider via `ref.invalidate(reportedEventsFeedProvider)` apres un
/// signalement ou un pull-to-refresh.
final reportedEventsFeedProvider = FutureProvider<List<ReportedEvent>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final svc = ref.watch(reportedEventsServiceProvider);
  final events = await svc.fetchActive(ville: city);

  // Tri par proximite au centre de la ville (haversine).
  // Si la ville n'est pas dans CityCenters, on garde l'ordre par defaut (date).
  final center = CityCenters.center(city);
  if (center != null && events.length > 1) {
    events.sort((a, b) {
      final da = _haversineKm(center.lat, center.lng, a.lat, a.lng);
      final db = _haversineKm(center.lat, center.lng, b.lat, b.lng);
      return da.compareTo(db);
    });
  }
  return events;
});

/// Distance haversine en kilometres entre deux points GPS.
double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0; // rayon Terre en km
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _toRad(double deg) => deg * math.pi / 180;
