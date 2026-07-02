import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Resout une fiche (n'importe quelle categorie) a partir d'un `sourceTable`
/// + `id`, pour le deep link macity.app/lieu/{table}/{id}.
///
/// Couvre les 4 tables sources de l'app : `etablissements` (Food/Famille/
/// Culture/Night), `venues`, `sport_venues`, `family_venues`. Le partage de
/// fiche emet le `sourceTable` SINGULIER (convention reviews/claim) ; on le
/// reconvertit en nom de table PLURIEL ici.
class LieuDeeplinkService {
  final Dio _dio;

  LieuDeeplinkService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// sourceTable (singulier, tel qu'emis dans le partage) → table REST.
  static const Map<String, String> _tableMap = {
    'etablissement': 'etablissements',
    'etablissements': 'etablissements',
    'venue': 'venues',
    'venues': 'venues',
    'sport_venues': 'sport_venues',
    'sport_venue': 'sport_venues',
    'family_venue': 'family_venues',
    'family_venues': 'family_venues',
  };

  Future<CommerceModel?> fetchById(String sourceTable, int id) async {
    final table = _tableMap[sourceTable];
    if (table == null) return null;

    try {
      final response = await _dio.get(
        table,
        queryParameters: {'select': '*', 'id': 'eq.$id', 'limit': '1'},
      );
      final data = response.data as List;
      if (data.isEmpty) return null;
      return _mapToCommerce(data.first as Map<String, dynamic>, sourceTable, id);
    } catch (_) {
      return null;
    }
  }

  /// Mapper generique : gere les deux conventions de colonnes
  /// (`name`/`nom`, `category`/`categorie`, `website_url`/`site_web`).
  static CommerceModel _mapToCommerce(
    Map<String, dynamic> json,
    String sourceTable,
    int id,
  ) {
    String s(String a, [String? b]) {
      final va = json[a];
      if (va is String && va.isNotEmpty) return va;
      if (b != null) {
        final vb = json[b];
        if (vb is String && vb.isNotEmpty) return vb;
      }
      return '';
    }

    final rawPhotos = json['photos'];
    final photos = (rawPhotos is List)
        ? rawPhotos.map((e) => e.toString()).where((p) => p.isNotEmpty).toList()
        : <String>[];

    // sourceTable singulier attendu par les reviews/claim cote detail.
    final singular = sourceTable.endsWith('s') && sourceTable != 'sport_venues'
        ? sourceTable.substring(0, sourceTable.length - 1)
        : sourceTable;

    return CommerceModel(
      nom: s('name', 'nom'),
      categorie: s('category', 'categorie'),
      adresse: s('adresse'),
      ville: s('ville'),
      telephone: s('telephone'),
      horaires: s('horaires'),
      siteWeb: s('website_url', 'site_web'),
      lienMaps: s('lien_maps'),
      photo: s('photo'),
      photos: photos,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      videoUrl: s('video_url'),
      isVerified: json['is_verified'] as bool? ?? false,
      sourceId: id,
      sourceTable: singular,
      description: s('description'),
    );
  }
}
