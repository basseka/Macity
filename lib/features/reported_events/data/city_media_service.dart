import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';

/// Média local (journal / radio) mis en avant pour une ville hub.
class CityMedia {
  final int id;
  final String ville;
  final String type; // journal | radio
  final String nom;
  final String logoUrl;
  final String url;
  final Color bgColor;

  const CityMedia({
    required this.id,
    required this.ville,
    required this.type,
    required this.nom,
    required this.logoUrl,
    required this.url,
    required this.bgColor,
  });

  factory CityMedia.fromJson(Map<String, dynamic> j) => CityMedia(
        id: (j['id'] as num?)?.toInt() ?? 0,
        ville: (j['ville'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'journal',
        nom: (j['nom'] as String?) ?? '',
        logoUrl: (j['logo_url'] as String?) ?? '',
        url: (j['url'] as String?) ?? '',
        bgColor: _parseColor(j['bg_color'] as String?),
      );

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFFFFFFF);
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v == null ? const Color(0xFFFFFFFF) : Color(v);
  }
}

/// Médias (journal + radio) actifs de la ville sélectionnée (vide si aucun).
final cityMediaProvider =
    FutureProvider.autoDispose<List<CityMedia>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final cityBase = city.split('(').first.trim();
  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
      ..interceptors.add(SupabaseInterceptor());
    final res = await dio.get<dynamic>('city_media', queryParameters: {
      'select': '*',
      'is_active': 'eq.true',
      'ville': 'ilike.*$cityBase*',
      'order': 'display_order.asc,type.asc',
    });
    final data = res.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => CityMedia.fromJson(e.cast<String, dynamic>()))
        .where((m) => m.nom.isNotEmpty)
        .toList();
  } on DioException {
    return const [];
  }
});
