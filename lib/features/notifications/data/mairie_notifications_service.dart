import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

class MairieNotification {
  final int id;
  final String ville;
  final String title;
  final String body;
  final String? photoUrl;
  final String? linkUrl;
  final DateTime createdAt;

  const MairieNotification({
    required this.id,
    required this.ville,
    required this.title,
    required this.body,
    this.photoUrl,
    this.linkUrl,
    required this.createdAt,
  });

  factory MairieNotification.fromJson(Map<String, dynamic> json) {
    return MairieNotification(
      id: json['id'] as int,
      ville: json['ville'] as String,
      title: json['title'] as String,
      body: (json['body'] as String?) ?? '',
      photoUrl: json['photo_url'] as String?,
      linkUrl: json['link_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class MairieNotificationsService {
  final Dio _dio;

  MairieNotificationsService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Récupère le link_url d'une notification par son id.
  Future<String?> fetchLinkUrl(int notifId) async {
    final response = await _dio.get(
      'mairie_notifications',
      queryParameters: {
        'id': 'eq.$notifId',
        'select': 'link_url',
        'limit': '1',
      },
    );
    final data = response.data as List;
    if (data.isEmpty) return null;
    return (data[0] as Map<String, dynamic>)['link_url'] as String?;
  }

  Future<List<MairieNotification>> fetchForCity(String ville) async {
    // Normalize: "Toulouse (31000)" → "Toulouse"
    final cityName = ville.contains('(')
        ? ville.substring(0, ville.indexOf('(')).trim()
        : ville.trim();

    final response = await _dio.get(
      'mairie_notifications',
      queryParameters: {
        'ville': 'ilike.%$cityName%',
        'select': '*',
        'order': 'created_at.desc',
        'limit': '50',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => MairieNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Charge les notifications pour plusieurs villes.
  Future<List<MairieNotification>> fetchForCities(List<String> villes) async {
    if (villes.isEmpty) return [];

    // Construire le filtre OR pour chaque ville
    final patterns = villes.map((v) {
      final cityName = v.contains('(')
          ? v.substring(0, v.indexOf('(')).trim()
          : v.trim();
      return 'ville.ilike.%$cityName%';
    }).join(',');

    final response = await _dio.get(
      'mairie_notifications',
      queryParameters: {
        'or': '($patterns)',
        'select': '*',
        'order': 'created_at.desc',
        'limit': '50',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => MairieNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
