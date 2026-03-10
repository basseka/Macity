import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Service qui lit les etablissements depuis la table `etablissements` de Supabase.
class EtablissementsSupabaseService {
  final Dio _dio;

  EtablissementsSupabaseService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch active etablissements filtered by [rubrique].
  Future<List<CommerceModel>> fetchByRubrique(String rubrique) async {
    final response = await _dio.get(
      'etablissements',
      queryParameters: {
        'select': '*',
        'is_active': 'eq.true',
        'rubrique': 'eq.$rubrique',
        'order': 'nom.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => _mapToCommerce(e as Map<String, dynamic>, rubrique))
        .toList();
  }

  static CommerceModel _mapToCommerce(
    Map<String, dynamic> json,
    String rubrique,
  ) {
    final photo = (json['photo'] as String?) ?? '';
    return CommerceModel(
      nom: json['nom'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      ville: json['ville'] as String? ?? 'Toulouse',
      telephone: json['telephone'] as String? ?? '',
      horaires: json['horaires'] as String? ?? '',
      siteWeb: json['site_web'] as String? ?? '',
      lienMaps: json['lien_maps'] as String? ?? '',
      photo: photo.isNotEmpty ? photo : _defaultPhoto(rubrique),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  static String _defaultPhoto(String rubrique) => switch (rubrique) {
        'nuit' => 'assets/images/pochette_nuit.png',
        'famille' => 'assets/images/pochette_famille.png',
        'culture' => 'assets/images/pochette_culture.png',
        'food' => 'assets/images/pochette_food.png',
        _ => 'assets/images/pochette_autre.png',
      };
}
