import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

/// Lieu partenaire (nom + coordonnées + formule). Sur la Map Live :
///  - pin vert (Premium / Gold) ou orange (Classique, ou partenaire sans
///    formule) pour chaque partenaire ;
///  - une story faite CHEZ un partenaire garde ses couleurs de story (pin
///    rose foncé + nom) et remplace le pin vert / orange.
class PartnerLocation {
  final String name;
  final double lat;
  final double lng;

  /// `premium`, `gold`, `classique` ou null (partenaire marqué à la main).
  final String? tier;

  /// Table source et id : servent à ouvrir la fiche au tap sur le pin.
  final String table;
  final int id;

  const PartnerLocation(
    this.name,
    this.lat,
    this.lng, {
    this.tier,
    this.table = '',
    this.id = 0,
  });

  /// Formule payante haute (Premium / Gold) : pin vert ; sinon orange.
  bool get isTopTier => tier == 'premium' || tier == 'gold';
}

/// Charge tous les partenaires actifs des 5 rubriques (venues Night/Culture,
/// etablissements Food, family_venues, sport_venues, evasion_venues) avec
/// `is_partner = true` et des coordonnées valides. Peu nombreux (curés à la
/// main) : un seul fetch caché suffit.
final partnerLocationsProvider =
    FutureProvider<List<PartnerLocation>>((ref) async {
  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
    ..interceptors.add(SupabaseInterceptor());

  List<PartnerLocation> parse(dynamic data, String table, String nameKey) {
    if (data is! List) return const [];
    final out = <PartnerLocation>[];
    for (final e in data) {
      if (e is! Map) continue;
      final lat = (e['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (e['longitude'] as num?)?.toDouble() ?? 0;
      final name = (e[nameKey] as String?)?.trim() ?? '';
      if (name.isEmpty || (lat == 0 && lng == 0)) continue;
      out.add(PartnerLocation(
        name,
        lat,
        lng,
        tier: (e['partner_tier'] as String?)?.trim().toLowerCase(),
        table: table,
        id: (e['id'] as num?)?.toInt() ?? 0,
      ),);
    }
    return out;
  }

  // Une table en erreur ne doit pas priver la carte des autres.
  Future<List<PartnerLocation>> load(String table, String nameKey) async {
    try {
      final res = await dio.get<dynamic>(table, queryParameters: {
        'select': 'id,$nameKey,latitude,longitude,partner_tier',
        'is_partner': 'eq.true',
        'is_active': 'eq.true',
      },);
      return parse(res.data, table, nameKey);
    } on DioException {
      return const [];
    }
  }

  final results = await Future.wait([
    load('venues', 'name'),
    load('etablissements', 'nom'),
    load('family_venues', 'name'),
    load('sport_venues', 'nom'),
    load('evasion_venues', 'nom'),
  ]);
  return [for (final r in results) ...r];
});
