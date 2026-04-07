import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';

class SportInfo {
  final String category;
  final String title;
  final String description;

  const SportInfo({required this.category, required this.title, required this.description});

  factory SportInfo.fromJson(Map<String, dynamic> json) => SportInfo(
    category: json['category'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );
}

final citySportInfoProvider = FutureProvider<List<SportInfo>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
  dio.interceptors.add(SupabaseInterceptor());

  try {
    final res = await dio.get('city_sport_info', queryParameters: {
      'select': 'category,title,description',
      'ville': 'eq.$city',
      'order': 'ordre.asc',
    });
    final data = res.data as List;
    return data.map((e) => SportInfo.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

/// Resume court pour le haut du hub sport
final sportSummaryProvider = Provider<String>((ref) {
  final infos = ref.watch(citySportInfoProvider).valueOrNull ?? [];
  if (infos.isEmpty) return '';
  final equipes = infos.where((i) => i.category == 'equipe').map((i) => i.title).toList();
  final actus = infos.where((i) => i.category == 'actu').toList();
  if (equipes.isEmpty) return '';
  final resume = '${equipes.join(', ')}${actus.isNotEmpty ? ' — ${actus.first.title}' : ''}';
  return resume;
});
