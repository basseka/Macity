import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/culture/data/dance_venues_data.dart';

/// Service qui lit les venues sport depuis la table `sport_venues` de Supabase.
class SportVenuesSupabaseService {
  final Dio _dio;

  SportVenuesSupabaseService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch active sport venues, optionally filtered by [sportType] and [ville].
  Future<List<CommerceModel>> fetchVenues({String? sportType, String? ville}) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'order': 'nom.asc',
    };
    if (sportType != null) {
      params['sport_type'] = 'eq.$sportType';
    }
    if (ville != null) {
      params['ville'] = 'ilike.$ville';
    }

    final response = await _dio.get(
      'sport_venues',
      queryParameters: params,
    );
    final data = response.data as List;
    return data.map((e) => _mapToCommerce(e as Map<String, dynamic>)).toList();
  }

  /// Fetch dance venues with their groupe field.
  Future<List<DanceVenue>> fetchDanceVenues({String? ville}) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'sport_type': 'eq.danse',
    };
    if (ville != null) {
      params['ville'] = 'ilike.$ville';
    }

    // Essayer avec tri par groupe d'abord, fallback sans si colonne absente
    try {
      final response = await _dio.get(
        'sport_venues',
        queryParameters: {...params, 'order': 'groupe.asc,nom.asc'},
      );
      final data = response.data as List;
      return data
          .map((e) => _mapToDanceVenue(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final response = await _dio.get(
        'sport_venues',
        queryParameters: {...params, 'order': 'nom.asc'},
      );
      final data = response.data as List;
      return data
          .map((e) => _mapToDanceVenue(e as Map<String, dynamic>))
          .toList();
    }
  }

  static CommerceModel _mapToCommerce(Map<String, dynamic> json) {
    return CommerceModel(
      nom: json['nom'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      siteWeb: json['site_web'] as String? ?? '',
      lienMaps: json['lien_maps'] as String? ?? '',
      photo: json['photo'] as String? ?? 'assets/images/pochette_autre.png',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  static DanceVenue _mapToDanceVenue(Map<String, dynamic> json) {
    final nom = json['nom'] as String? ?? '';
    final groupe = json['groupe'] as String? ?? '';
    return DanceVenue(
      id: '${nom.hashCode}_$groupe',
      name: nom,
      description: json['categorie'] as String? ?? '',
      category: json['categorie'] as String? ?? '',
      group: groupe,
      city: json['ville'] as String? ?? '',
      horaires: '',
      websiteUrl: (json['site_web'] as String?)?.isNotEmpty == true
          ? json['site_web'] as String
          : null,
      image: json['photo'] as String? ?? 'assets/images/pochette_autre.png',
    );
  }
}
