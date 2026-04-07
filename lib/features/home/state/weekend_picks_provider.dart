import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';

class WeekendPick {
  final String identifiant;
  final String resume;
  final String titre;
  final String photoUrl;
  final String date;
  final String horaires;
  final String lieu;
  final String categorie;
  final bool isMatch;

  const WeekendPick({
    required this.identifiant,
    required this.resume,
    required this.titre,
    required this.photoUrl,
    required this.date,
    required this.horaires,
    required this.lieu,
    required this.categorie,
    this.isMatch = false,
  });

  factory WeekendPick.fromJson(Map<String, dynamic> json) {
    return WeekendPick(
      identifiant: json['identifiant'] as String? ?? '',
      resume: json['resume'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
      date: json['date'] as String? ?? '',
      horaires: json['horaires'] as String? ?? '',
      lieu: json['lieu'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      isMatch: json['is_match'] as bool? ?? false,
    );
  }
}

String _weekStart() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: (now.weekday - 1) % 7));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

final weekendPicksProvider = FutureProvider<List<WeekendPick>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
  dio.interceptors.add(SupabaseInterceptor());

  try {
    final response = await dio.get(
      'weekend_picks',
      queryParameters: {
        'select': 'picks',
        'ville': 'eq.$city',
        'week_start': 'eq.${_weekStart()}',
        'limit': '1',
      },
    );

    final data = response.data as List;
    if (data.isEmpty) return [];

    final picks = data[0]['picks'] as List;
    return picks
        .map((p) => WeekendPick.fromJson(p as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
