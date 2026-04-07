import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';

class TipItem {
  final String category;
  final String title;
  final String description;

  const TipItem({required this.category, required this.title, required this.description});

  factory TipItem.fromJson(Map<String, dynamic> json) => TipItem(
    category: json['category'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );
}

final cityTourismeTipsProvider = FutureProvider<List<TipItem>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
  dio.interceptors.add(SupabaseInterceptor());

  try {
    final res = await dio.get('city_tourisme_tips', queryParameters: {
      'select': 'category,title,description',
      'ville': 'eq.$city',
      'order': 'ordre.asc',
    });
    final data = res.data as List;
    return data.map((e) => TipItem.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});
