import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/admin/domain/models/admin_pin.dart';

class AdminPinService {
  final Dio _dio;

  AdminPinService({Dio? dio})
      : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch tous les pins actifs (pinned_until > maintenant).
  /// Lecture publique, pas besoin de JWT.
  Future<List<AdminPin>> fetchActivePins() async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final res = await _dio.get(
        'admin_pins',
        queryParameters: {
          'pinned_until': 'gte.$nowIso',
          'select': 'id,event_source,event_identifiant,pin_type,pinned_until,admin_email,created_at',
          'order': 'created_at.desc',
        },
      );
      final list = res.data as List<dynamic>;
      return list
          .map((e) => AdminPin.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[AdminPinService] fetchActivePins error: $e');
      return const [];
    }
  }

  /// Cree ou met a jour un pin (upsert sur unique (source, identifiant, pin_type)).
  Future<bool> pin({
    required AdminPinSource source,
    required String identifiant,
    required AdminPinType pinType,
    required DateTime pinnedUntil,
    required String accessToken,
    String? adminEmail,
  }) async {
    try {
      await _dio.post(
        'admin_pins',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
        ),
        data: {
          'event_source': source.value,
          'event_identifiant': identifiant,
          'pin_type': pinType.value,
          'pinned_until': pinnedUntil.toUtc().toIso8601String(),
          'admin_email': adminEmail,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[AdminPinService] pin error: $e');
      return false;
    }
  }

  /// Supprime un pin (match par source+identifiant+type).
  Future<bool> unpin({
    required AdminPinSource source,
    required String identifiant,
    required AdminPinType pinType,
    required String accessToken,
  }) async {
    try {
      await _dio.delete(
        'admin_pins',
        queryParameters: {
          'event_source': 'eq.${source.value}',
          'event_identifiant': 'eq.$identifiant',
          'pin_type': 'eq.${pinType.value}',
        },
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[AdminPinService] unpin error: $e');
      return false;
    }
  }
}
