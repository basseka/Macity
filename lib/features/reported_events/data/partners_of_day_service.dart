import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Une rubrique « du jour » : son titre d'encart + la liste de ses partenaires
/// (dans la ville sélectionnée), triée par display_priority décroissant.
class PartnerRubrique {
  final String key;    // food, family, culture, sport, night, evasion
  final String title;  // « Le restaurant du jour », …
  final List<CommerceModel> partners;
  const PartnerRubrique(this.key, this.title, this.partners);
}

/// Ordre d'affichage des 6 encarts sous « En direct autour de vous ».
const _rubriqueTitles = <String, String>{
  'food': 'Le restaurant du jour',
  'family': "L'activité du jour",
  'culture': 'Le point culture',
  'sport': 'Le moment Sport',
  'night': 'Le club du jour',
  'evasion': 'Le moment évasion',
};

/// Récupère, pour la ville sélectionnée, les partenaires de chaque rubrique
/// depuis sa table canonique (là où l'admin les marque = là où l'app lit).
final partnersOfDayProvider =
    FutureProvider.autoDispose<List<PartnerRubrique>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  // Nom de ville « propre » pour le ILIKE (retire un éventuel « (31000) »).
  final cityBase = city.split('(').first.trim();
  final like = '*$cityBase*';

  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
    ..interceptors.add(SupabaseInterceptor());

  Future<List<CommerceModel>> q(
    String table,
    Map<String, String> filters,
    CommerceModel Function(Map<String, dynamic>) map, {
    String cityCol = 'ville',
  }) async {
    try {
      final res = await dio.get<dynamic>(table, queryParameters: {
        'is_partner': 'eq.true',
        'is_active': 'eq.true',
        cityCol: 'ilike.$like',
        'order': 'display_priority.desc',
        ...filters,
      });
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => map(e.cast<String, dynamic>()))
          .where((c) => c.nom.isNotEmpty)
          .toList();
    } on DioException {
      return const [];
    }
  }

  String s(dynamic v) => (v as String?)?.trim() ?? '';
  double d(dynamic v) => (v as num?)?.toDouble() ?? 0;
  List<String> photos(dynamic v) => (v is List)
      ? v.whereType<String>().where((p) => p.isNotEmpty).toList()
      : const [];

  final results = await Future.wait([
    // Food → etablissements (rubrique food) — pas de colonne `description`.
    q('etablissements', {
      'select':
          'id,nom,adresse,ville,categorie,photo,photos,video_url,latitude,longitude,site_web,telephone',
      'rubrique': 'eq.food',
    }, (e) => CommerceModel(
          nom: s(e['nom']),
          adresse: s(e['adresse']),
          ville: s(e['ville']),
          categorie: s(e['categorie']),
          photo: s(e['photo']),
          photos: photos(e['photos']),
          videoUrl: s(e['video_url']),
          latitude: d(e['latitude']),
          longitude: d(e['longitude']),
          siteWeb: s(e['site_web']),
          telephone: s(e['telephone']),
          isPartner: true,
          sourceTable: 'etablissements',
          sourceId: (e['id'] as num?)?.toInt(),
        )),
    // Famille → family_venues
    q('family_venues', {
      'select':
          'id,name,adresse,ville,category,photo,latitude,longitude,description,website_url,telephone',
    }, (e) => CommerceModel(
          nom: s(e['name']),
          adresse: s(e['adresse']),
          ville: s(e['ville']),
          categorie: s(e['category']),
          photo: s(e['photo']),
          latitude: d(e['latitude']),
          longitude: d(e['longitude']),
          description: s(e['description']),
          siteWeb: s(e['website_url']),
          telephone: s(e['telephone']),
          isPartner: true,
          sourceTable: 'family_venues',
          sourceId: (e['id'] as num?)?.toInt(),
        )),
    // Culture → venues (mode culture)
    q('venues', {
      'select':
          'id,name,adresse,ville,category,photo,photos,video_url,latitude,longitude',
      'mode': 'eq.culture',
    }, (e) => CommerceModel(
          nom: s(e['name']),
          adresse: s(e['adresse']),
          ville: s(e['ville']),
          categorie: s(e['category']),
          photo: s(e['photo']),
          photos: photos(e['photos']),
          videoUrl: s(e['video_url']),
          latitude: d(e['latitude']),
          longitude: d(e['longitude']),
          isPartner: true,
          sourceTable: 'venues',
          sourceId: (e['id'] as num?)?.toInt(),
        )),
    // Sport → sport_venues
    q('sport_venues', {
      'select':
          'id,nom,adresse,ville,categorie,sport_type,photo,photos,video_url,latitude,longitude,description,site_web,telephone',
    }, (e) => CommerceModel(
          nom: s(e['nom']),
          adresse: s(e['adresse']),
          ville: s(e['ville']),
          categorie: s(e['categorie']).isNotEmpty
              ? s(e['categorie'])
              : s(e['sport_type']),
          photo: s(e['photo']),
          photos: photos(e['photos']),
          videoUrl: s(e['video_url']),
          latitude: d(e['latitude']),
          longitude: d(e['longitude']),
          description: s(e['description']),
          siteWeb: s(e['site_web']),
          telephone: s(e['telephone']),
          isPartner: true,
          sourceTable: 'sport_venues',
          sourceId: (e['id'] as num?)?.toInt(),
        )),
    // Night → venues (mode night)
    q('venues', {
      'select':
          'id,name,adresse,ville,category,photo,photos,video_url,latitude,longitude',
      'mode': 'eq.night',
    }, (e) => CommerceModel(
          nom: s(e['name']),
          adresse: s(e['adresse']),
          ville: s(e['ville']),
          categorie: s(e['category']),
          photo: s(e['photo']),
          photos: photos(e['photos']),
          videoUrl: s(e['video_url']),
          latitude: d(e['latitude']),
          longitude: d(e['longitude']),
          isPartner: true,
          sourceTable: 'venues',
          sourceId: (e['id'] as num?)?.toInt(),
        )),
    // Évasion → evasion_venues (filtré par hub_ville)
    q('evasion_venues', {
      'select':
          'id,nom,adresse,ville,description,site_web,telephone,photo,photos,video_url,latitude,longitude',
    }, cityCol: 'hub_ville', (e) => CommerceModel(
          nom: s(e['nom']),
          adresse: s(e['adresse']),
          ville: s(e['ville']),
          categorie: 'Évasion',
          photo: s(e['photo']),
          photos: photos(e['photos']),
          videoUrl: s(e['video_url']),
          latitude: d(e['latitude']),
          longitude: d(e['longitude']),
          description: s(e['description']),
          siteWeb: s(e['site_web']),
          telephone: s(e['telephone']),
          isPartner: true,
          sourceTable: 'evasion_venues',
          sourceId: (e['id'] as num?)?.toInt(),
        )),
  ]);

  final byKey = <String, List<CommerceModel>>{
    'food': results[0],
    'family': results[1],
    'culture': results[2],
    'sport': results[3],
    'night': results[4],
    'evasion': results[5],
  };

  // Ordre fixe des encarts ; on ne garde que les rubriques ayant ≥1 partenaire.
  return _rubriqueTitles.entries
      .map((t) => PartnerRubrique(t.key, t.value, byKey[t.key] ?? const []))
      .where((r) => r.partners.isNotEmpty)
      .toList();
});
