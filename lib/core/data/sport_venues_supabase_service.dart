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
      'order': 'display_priority.desc,nom.asc',
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

  /// Photos de pochette par chaine (table `fitness_chains`).
  /// Renvoie token -> photo_url (seulement les chaines avec une photo non vide).
  Future<Map<String, String>> fetchChainPhotos() async {
    final response = await _dio.get(
      'fitness_chains',
      queryParameters: const {'select': 'token,photo_url'},
    );
    final data = response.data as List;
    final map = <String, String>{};
    for (final e in data) {
      final m = e as Map<String, dynamic>;
      final token = m['token'] as String?;
      final url = m['photo_url'] as String?;
      if (token != null && url != null && url.isNotEmpty) {
        map[token] = url;
      }
    }
    return map;
  }

  static CommerceModel _mapToCommerce(Map<String, dynamic> json) {
    final photosRaw = json['photos'];
    final photos = photosRaw is List
        ? photosRaw.whereType<String>().where((s) => s.isNotEmpty).toList()
        : <String>[];
    return CommerceModel(
      nom: json['nom'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      quartier: json['quartier'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      siteWeb: json['site_web'] as String? ?? '',
      lienMaps: json['lien_maps'] as String? ?? '',
      photo: (json['photo'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      videoUrl: json['video_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      horaires: json['horaires'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      photos: photos,
      sourceId: (json['id'] as num?)?.toInt(),
      sourceTable: 'sport_venues',
    );
  }

  static DanceVenue _mapToDanceVenue(Map<String, dynamic> json) {
    final nom = json['nom'] as String? ?? '';
    final categorie = json['categorie'] as String? ?? '';
    final groupe = json['groupe'] as String? ?? categorie;
    return DanceVenue(
      id: '${nom.hashCode}_$groupe',
      name: nom,
      description: categorie,
      category: categorie,
      group: groupe,
      city: json['ville'] as String? ?? '',
      horaires: '',
      websiteUrl: (json['site_web'] as String?)?.isNotEmpty == true
          ? json['site_web'] as String
          : null,
      image: json['photo'] as String? ?? 'assets/images/pochette_autre.jpg',
    );
  }
}
