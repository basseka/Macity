import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Service qui lit les points touristiques depuis la table
/// `touristic_points_toulouse` de Supabase.
class TouristicPointsSupabaseService {
  final Dio _dio;

  TouristicPointsSupabaseService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch active touristic points, optionally filtered by [categorie].
  Future<List<CommerceModel>> fetchPoints({String? categorie}) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'order': 'nom.asc',
    };
    if (categorie != null) {
      params['categorie'] = 'eq.$categorie';
    }

    final response = await _dio.get(
      'touristic_points_toulouse',
      queryParameters: params,
    );
    final data = response.data as List;
    return data
        .map((e) => _mapToCommerce(e as Map<String, dynamic>))
        .toList();
  }

  static CommerceModel _mapToCommerce(Map<String, dynamic> json) {
    return CommerceModel(
      nom: json['nom'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      siteWeb: json['site_web'] as String? ?? '',
      lienMaps: json['lien_maps'] as String? ?? '',
      photo: json['photo'] as String? ?? 'assets/images/pochette_visite.png',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}
