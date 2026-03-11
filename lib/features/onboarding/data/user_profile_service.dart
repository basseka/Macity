import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';

class UserProfileService {
  final Dio _dio;

  UserProfileService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final userId = await UserIdentityService.getUserId();
    final response = await _dio.get(
      'user_profiles',
      queryParameters: {
        'user_id': 'eq.$userId',
        'select': '*',
      },
    );
    final data = response.data as List;
    if (data.isEmpty) return null;
    return data.first as Map<String, dynamic>;
  }

  Future<void> updatePreferences(List<String> preferences) async {
    final userId = await UserIdentityService.getUserId();
    await _dio.patch(
      'user_profiles',
      queryParameters: {'user_id': 'eq.$userId'},
      data: {
        'preferences': preferences,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<bool> hasProfile() async {
    final userId = await UserIdentityService.getUserId();
    final response = await _dio.get(
      'user_profiles',
      queryParameters: {
        'user_id': 'eq.$userId',
        'select': 'user_id',
      },
    );
    final data = response.data as List;
    return data.isNotEmpty;
  }

  Future<void> upsert({
    required String email,
    required String telephone,
    required String prenom,
    required String ville,
    required List<String> preferences,
  }) async {
    final userId = await UserIdentityService.getUserId();
    await _dio.post(
      'user_profiles',
      data: {
        'user_id': userId,
        'email': email,
        'telephone': telephone,
        'prenom': prenom,
        'ville': ville,
        'preferences': preferences,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      options: Options(
        headers: {'Prefer': 'resolution=merge-duplicates'},
      ),
    );
  }

  Future<void> updateVille(String ville) async {
    final userId = await UserIdentityService.getUserId();
    await _dio.patch(
      'user_profiles',
      queryParameters: {'user_id': 'eq.$userId'},
      data: {
        'ville': ville,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}
