import 'dart:math';

class Haversine {
  Haversine._();

  static const double _earthRadiusMeters = 6371000;

  /// Calculate distance in meters between two GPS coordinates
  static double distanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Distance en km entre deux points.
  static double km(double lat1, double lon1, double lat2, double lon2) =>
      distanceInMeters(lat1, lon1, lat2, lon2) / 1000;

  /// Filtre PostgREST `and=(...)` du rectangle qui contient le cercle de
  /// [radiusKm] autour du point (à affiner ensuite avec [km]).
  static String bboxFilter(double lat, double lon, double radiusKm) {
    final dLat = radiusKm / 111.32;
    final dLon = radiusKm / (111.32 * cos(_toRadians(lat)));
    return '(latitude.gte.${lat - dLat},latitude.lte.${lat + dLat},'
        'longitude.gte.${lon - dLon},longitude.lte.${lon + dLon})';
  }

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
