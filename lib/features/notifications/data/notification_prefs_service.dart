import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';

class NotificationPrefs {
  final bool enabled;
  final bool remind15d;
  final bool remind1d;
  final bool remind1h;

  const NotificationPrefs({
    this.enabled = true,
    this.remind15d = true,
    this.remind1d = true,
    this.remind1h = true,
  });

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    return NotificationPrefs(
      enabled: json['enabled'] as bool? ?? true,
      remind15d: json['remind_15d'] as bool? ?? true,
      remind1d: json['remind_1d'] as bool? ?? true,
      remind1h: json['remind_1h'] as bool? ?? true,
    );
  }

  NotificationPrefs copyWith({
    bool? enabled,
    bool? remind15d,
    bool? remind1d,
    bool? remind1h,
  }) {
    return NotificationPrefs(
      enabled: enabled ?? this.enabled,
      remind15d: remind15d ?? this.remind15d,
      remind1d: remind1d ?? this.remind1d,
      remind1h: remind1h ?? this.remind1h,
    );
  }
}

class NotificationPrefsService {
  final Dio _dio;

  NotificationPrefsService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  Future<NotificationPrefs> fetch() async {
    final userId = await UserIdentityService.getUserId();
    final response = await _dio.get(
      'notification_preferences',
      queryParameters: {
        'user_id': 'eq.$userId',
        'select': '*',
      },
    );
    final data = response.data as List;
    if (data.isEmpty) return const NotificationPrefs();
    return NotificationPrefs.fromJson(data.first as Map<String, dynamic>);
  }

  Future<void> upsert(NotificationPrefs prefs) async {
    final userId = await UserIdentityService.getUserId();
    await _dio.post(
      'notification_preferences',
      data: {
        'user_id': userId,
        'enabled': prefs.enabled,
        'remind_15d': prefs.remind15d,
        'remind_1d': prefs.remind1d,
        'remind_1h': prefs.remind1h,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      options: Options(
        headers: {'Prefer': 'resolution=merge-duplicates'},
      ),
    );
  }
}
