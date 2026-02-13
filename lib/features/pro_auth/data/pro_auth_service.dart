import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/pro_auth/domain/models/pro_profile.dart';

class ProAuthService {
  final Dio _restDio;
  final Dio _authDio;

  ProAuthService({Dio? restDio, Dio? authDio})
      : _restDio = restDio ?? _createRestDio(),
        _authDio = authDio ?? _createAuthDio();

  static Dio _createRestDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  static Dio _createAuthDio() {
    return DioClient.withBaseUrl('${SupabaseConfig.supabaseUrl}/auth/v1/');
  }

  // ─────────────────────────────────────────
  // Supabase Auth (GoTrue REST API)
  // ─────────────────────────────────────────

  static const _authHeaders = {
    'apikey': SupabaseConfig.supabaseAnonKey,
    'Content-Type': 'application/json',
  };

  /// Inscription via Supabase Auth + creation du profil pro.
  /// Retourne ({ProProfile profile, String accessToken, String refreshToken}).
  Future<({ProProfile profile, String accessToken, String refreshToken})>
      register({
    required String email,
    required String password,
    required String nom,
    required String type,
    required String telephone,
  }) async {
    // 1. Creer le compte Supabase Auth
    final authRes = await _authDio.post(
      'signup',
      data: {'email': email, 'password': password},
      options: Options(headers: _authHeaders),
    );

    final authData = authRes.data as Map<String, dynamic>;
    final user = authData['user'] as Map<String, dynamic>?;
    final userId = user?['id'] as String?;
    final accessToken = authData['access_token'] as String? ?? '';
    final refreshToken = authData['refresh_token'] as String? ?? '';

    if (userId == null || userId.isEmpty) {
      throw Exception('Inscription echouee : aucun utilisateur cree');
    }

    // 2. Creer le profil pro (avec le token de l'utilisateur)
    final profileRes = await _restDio.post(
      'pro_profiles',
      data: {
        'user_id': userId,
        'nom': nom,
        'type': type,
        'email': email,
        'telephone': telephone,
      },
      options: Options(
        headers: {
          'Prefer': 'return=representation',
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    final data = profileRes.data as List;
    final profile =
        ProProfile.fromSupabaseJson(data.first as Map<String, dynamic>);

    return (
      profile: profile,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// Connexion via Supabase Auth + recuperation du profil pro.
  Future<({ProProfile profile, String accessToken, String refreshToken})?>
      login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Authentifier
      final authRes = await _authDio.post(
        'token?grant_type=password',
        data: {'email': email, 'password': password},
        options: Options(headers: _authHeaders),
      );

      final authData = authRes.data as Map<String, dynamic>;
      final user = authData['user'] as Map<String, dynamic>;
      final userId = user['id'] as String;
      final accessToken = authData['access_token'] as String;
      final refreshToken = authData['refresh_token'] as String;

      // 2. Recuperer le profil pro
      final profileRes = await _restDio.get(
        'pro_profiles',
        queryParameters: {
          'user_id': 'eq.$userId',
          'select': '*',
        },
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      final data = profileRes.data as List;
      if (data.isEmpty) return null;

      final profile =
          ProProfile.fromSupabaseJson(data.first as Map<String, dynamic>);

      return (
        profile: profile,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return null; // Identifiants invalides
      }
      rethrow;
    }
  }

  /// Rafraichit le token d'acces.
  Future<({String accessToken, String refreshToken})?> refreshToken(
    String currentRefreshToken,
  ) async {
    try {
      final res = await _authDio.post(
        'token?grant_type=refresh_token',
        data: {'refresh_token': currentRefreshToken},
        options: Options(headers: _authHeaders),
      );
      final data = res.data as Map<String, dynamic>;
      return (
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
    } catch (e) {
      debugPrint('[ProAuth] refreshToken error: $e');
      return null;
    }
  }

  /// Recupere le profil pro depuis Supabase pour un user_id donne.
  Future<ProProfile?> fetchProfile(String userId, String accessToken) async {
    try {
      final response = await _restDio.get(
        'pro_profiles',
        queryParameters: {
          'user_id': 'eq.$userId',
          'select': '*',
        },
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      final data = response.data as List;
      if (data.isEmpty) return null;
      return ProProfile.fromSupabaseJson(data.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[ProAuth] fetchProfile error: $e');
      return null;
    }
  }
}
