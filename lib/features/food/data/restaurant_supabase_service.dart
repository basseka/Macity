import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/features/city/data/city_coordinates.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart' show RestaurantVenue;

/// Fetch les restaurants depuis la table `etablissements` avec theme/quartier/style.
class RestaurantSupabaseService {
  final Dio _dio;

  RestaurantSupabaseService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  Future<List<RestaurantVenue>> fetchRestaurants({required String ville}) async {
    final response = await _dio.get(
      'etablissements',
      queryParameters: {
        'select': '*',
        'is_active': 'eq.true',
        'rubrique': 'eq.food',
        'ville': 'ilike.$ville',
        'order': 'display_priority.desc,nom.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => _mapToVenue(e as Map<String, dynamic>))
        .toList();
  }

  /// En dessous de ce nombre de restos dans la ville, on complete avec les
  /// adresses les plus proches (rayon elargi). Les hubs bien fournis (~80
  /// restos) ne sont donc pas concernes.
  static const minResults = 20;

  /// Rayons successifs (km) essayes autour du centre-ville.
  static const radiiKm = [10.0, 25.0, 50.0];

  /// Restos de la ville, completes si besoin par les adresses les plus
  /// proches de [center] (rayon elargi par paliers jusqu'a [minResults]).
  /// Les adresses ajoutees portent `distanceFromCenterKm` et sont triees de
  /// la plus proche a la plus lointaine, apres celles de la ville.
  Future<List<RestaurantVenue>> fetchRestaurantsWithNearby({
    required String ville,
    required ({double lat, double lng})? center,
  }) async {
    final local = await fetchRestaurants(ville: ville);
    if (local.length >= minResults || center == null) return local;

    final seen = local.map((r) => r.id).toSet();
    var extras = <RestaurantVenue>[];
    for (final radius in radiiKm) {
      final around = await fetchRestaurantsAround(
        lat: center.lat, lng: center.lng, radiusKm: radius,
      );
      extras = around.where((r) => !seen.contains(r.id)).toList();
      if (local.length + extras.length >= minResults) break;
    }
    extras.sort(
      (a, b) => a.distanceFromCenterKm!.compareTo(b.distanceFromCenterKm!),
    );
    final result = [...local, ...extras];
    if (result.isNotEmpty) return result;

    // Commune sans aucun resto a 50 km (ex : Albi tant que le Tarn n'est pas
    // en base) : on montre ceux de son hub, avec leur distance.
    final hub = CityCoordinates.hubOf(ville);
    if (hub == null || hub.toLowerCase() == ville.toLowerCase()) return result;
    final hubList = await fetchRestaurants(ville: hub);
    return hubList
        .map((r) => r.withDistanceFromCenter(
              Haversine.km(center.lat, center.lng, r.latitude, r.longitude),
            ),)
        .toList()
      ..sort(
        (a, b) => a.distanceFromCenterKm!.compareTo(b.distanceFromCenterKm!),
      );
  }

  /// Restos actifs dans un rayon de [radiusKm] autour d'un point : filtre
  /// rectangulaire cote base (latitude/longitude), puis cercle exact ici.
  Future<List<RestaurantVenue>> fetchRestaurantsAround({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final response = await _dio.get(
      'etablissements',
      queryParameters: {
        'select': '*',
        'is_active': 'eq.true',
        'rubrique': 'eq.food',
        'and': Haversine.bboxFilter(lat, lng, radiusKm),
      },
    );
    final data = response.data as List;
    final result = <RestaurantVenue>[];
    for (final e in data) {
      final venue = _mapToVenue(e as Map<String, dynamic>);
      final km = Haversine.km(lat, lng, venue.latitude, venue.longitude);
      if (km <= radiusKm) result.add(venue.withDistanceFromCenter(km));
    }
    return result;
  }


  static RestaurantVenue _mapToVenue(Map<String, dynamic> json) {
    final photosRaw = json['photos'];
    final photos = photosRaw is List
        ? photosRaw.whereType<String>().where((s) => s.isNotEmpty).toList()
        : <String>[];
    final prioRaw = json['priorities'];
    final priorities = <String, int>{};
    if (prioRaw is Map) {
      for (final e in prioRaw.entries) {
        final v = e.value;
        if (v is int) {
          priorities[e.key.toString()] = v;
        } else if (v is num) {
          priorities[e.key.toString()] = v.toInt();
        } else if (v is String) {
          final n = int.tryParse(v);
          if (n != null) priorities[e.key.toString()] = n;
        }
      }
    }
    return RestaurantVenue(
      id: '${json['id'] ?? ''}',
      name: json['nom'] as String? ?? '',
      description: '',
      group: json['categorie'] as String? ?? '',
      theme: json['theme'] as String? ?? '',
      quartier: json['quartier'] as String? ?? '',
      style: json['style'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      horaires: json['horaires'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      websiteUrl: json['site_web'] as String? ?? '',
      lienMaps: json['lien_maps'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      photos: photos,
      videoUrl: json['video_url'] as String? ?? '',
      displayPriority: (json['display_priority'] as num?)?.toInt() ?? 0,
      isPartner: json['is_partner'] as bool? ?? false,
      priorities: priorities,
    );
  }
}
