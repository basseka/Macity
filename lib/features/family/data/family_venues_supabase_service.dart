import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/family/domain/models/family_venue.dart';

/// Service qui lit les venues famille depuis la table `family_venues` de Supabase.
class FamilyVenuesSupabaseService {
  final Dio _dio;

  FamilyVenuesSupabaseService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch all active venues, optionally filtered by [category].
  Future<List<FamilyVenue>> fetchVenues({String? category}) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'order': 'groupe.asc,name.asc',
    };
    if (category != null) {
      params['category'] = 'eq.$category';
    }

    final response = await _dio.get(
      'family_venues',
      queryParameters: params,
    );
    final data = response.data as List;
    return data
        .map((e) => FamilyVenue.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Count active venues per category.
  Future<int> countByCategory(String category) async {
    final response = await _dio.get(
      'family_venues',
      queryParameters: {
        'select': 'id',
        'is_active': 'eq.true',
        'category': 'eq.$category',
      },
      options: Options(headers: {'Prefer': 'count=exact'}),
    );
    final count = response.headers.value('content-range');
    if (count != null) {
      final parts = count.split('/');
      if (parts.length == 2 && parts[1] != '*') {
        return int.tryParse(parts[1]) ?? 0;
      }
    }
    return (response.data as List).length;
  }

  /// Get distinct group names for a category (for section headers).
  Future<List<String>> fetchGroupsForCategory(String category) async {
    final venues = await fetchVenues(category: category);
    final groups = <String>[];
    for (final v in venues) {
      if (v.groupe.isNotEmpty && !groups.contains(v.groupe)) {
        groups.add(v.groupe);
      }
    }
    return groups;
  }
}
