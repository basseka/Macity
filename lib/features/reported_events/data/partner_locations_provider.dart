import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

/// Lieu partenaire (nom + coordonnées) — sert à repérer sur la Map Live les
/// stories faites CHEZ un partenaire (pin rose foncé + nom sous la bulle).
class PartnerLocation {
  final String name;
  final double lat;
  final double lng;
  const PartnerLocation(this.name, this.lat, this.lng);
}

/// Charge tous les partenaires (venues Night + etablissements Food) avec
/// `is_partner = true` et des coordonnées valides. Peu nombreux (curés à la
/// main) → un seul fetch caché suffit.
final partnerLocationsProvider =
    FutureProvider<List<PartnerLocation>>((ref) async {
  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
    ..interceptors.add(SupabaseInterceptor());

  List<PartnerLocation> parse(dynamic data, String nameKey) {
    if (data is! List) return const [];
    final out = <PartnerLocation>[];
    for (final e in data) {
      if (e is! Map) continue;
      final lat = (e['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (e['longitude'] as num?)?.toDouble() ?? 0;
      final name = (e[nameKey] as String?)?.trim() ?? '';
      if (name.isEmpty || (lat == 0 && lng == 0)) continue;
      out.add(PartnerLocation(name, lat, lng));
    }
    return out;
  }

  try {
    final results = await Future.wait([
      dio.get<dynamic>('venues', queryParameters: {
        'select': 'name,latitude,longitude',
        'is_partner': 'eq.true',
        'is_active': 'eq.true',
      },),
      dio.get<dynamic>('etablissements', queryParameters: {
        'select': 'nom,latitude,longitude',
        'is_partner': 'eq.true',
        'is_active': 'eq.true',
      },),
    ]);
    return [
      ...parse(results[0].data, 'name'),
      ...parse(results[1].data, 'nom'),
    ];
  } on DioException {
    return const [];
  }
});
