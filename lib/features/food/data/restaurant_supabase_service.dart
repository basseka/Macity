import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
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
        'order': 'nom.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => _mapToVenue(e as Map<String, dynamic>))
        .toList();
  }

  static RestaurantVenue _mapToVenue(Map<String, dynamic> json) {
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
    );
  }
}
