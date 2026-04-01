import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/culture/data/library_venues_data.dart';
import 'package:pulz_app/features/culture/data/monument_venues_data.dart';
import 'package:pulz_app/features/culture/data/museum_venues_data.dart';
import 'package:pulz_app/features/culture/data/theatre_venues_data.dart';

/// Service unifie pour la table `venues` de Supabase.
/// Remplace les multiples fichiers statiques Dart par une seule source de verite.
class VenuesSupabaseService {
  final Dio _dio;

  VenuesSupabaseService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch venues by [mode] and [ville], optionally filtered by [category] and/or [groupe].
  Future<List<CommerceModel>> fetchVenues({
    required String mode,
    required String ville,
    String? category,
    String? groupe,
  }) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'mode': 'eq.$mode',
      'ville': 'ilike.$ville*',
      'order': 'name.asc',
    };
    if (category != null) params['category'] = 'ilike.*$category*';
    if (groupe != null) params['groupe'] = 'eq.$groupe';

    final response = await _dio.get('venues', queryParameters: params);
    final data = response.data as List;
    return data.map((e) => _mapToCommerce(e as Map<String, dynamic>)).toList();
  }

  /// Count venues for a given [mode] and [ville].
  Future<int> countVenues({
    required String mode,
    required String ville,
    String? category,
  }) async {
    final params = <String, String>{
      'select': 'id',
      'is_active': 'eq.true',
      'mode': 'eq.$mode',
      'ville': 'ilike.$ville*',
    };
    if (category != null) params['category'] = 'ilike.*$category*';

    final response = await _dio.get(
      'venues',
      queryParameters: params,
      options: Options(headers: {'Prefer': 'count=exact', 'Range-Unit': 'items', 'Range': '0-0'}),
    );
    final contentRange = response.headers.value('content-range') ?? '';
    final total = contentRange.split('/').last;
    return int.tryParse(total) ?? 0;
  }

  /// Fetch distinct categories for a given [mode] and [ville].
  Future<List<String>> fetchCategories({
    required String mode,
    required String ville,
  }) async {
    final response = await _dio.get(
      'venues',
      queryParameters: {
        'select': 'category',
        'is_active': 'eq.true',
        'mode': 'eq.$mode',
        'ville': 'ilike.$ville*',
        'order': 'category.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => (e as Map<String, dynamic>)['category'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Fetch theatre venues as [TheatreVenue] objects, filtered by [ville].
  Future<List<TheatreVenue>> fetchTheatreVenues({required String ville}) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'mode': 'eq.culture',
      'category': 'eq.Theatre',
      'ville': 'ilike.$ville*',
      'order': 'name.asc',
    };

    final response = await _dio.get('venues', queryParameters: params);
    final data = response.data as List;
    return data.map((e) => _mapToTheatreVenue(e as Map<String, dynamic>)).toList();
  }

  static TheatreVenue _mapToTheatreVenue(Map<String, dynamic> json) {
    final photo = (json['photo'] as String?) ?? '';
    return TheatreVenue(
      id: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      city: json['ville'] as String? ?? 'Toulouse',
      horaires: json['horaires'] as String? ?? '',
      ticketUrl: (json['ticket_url'] as String?)?.isNotEmpty == true
          ? json['ticket_url'] as String
          : null,
      websiteUrl: (json['website_url'] as String?)?.isNotEmpty == true
          ? json['website_url'] as String
          : null,
      hasOnlineTicket: json['has_online_ticket'] as bool? ?? false,
      image: photo.isNotEmpty ? photo : 'assets/images/pochette_theatre.png',
    );
  }

  /// Fetch museum venues as [MuseumVenue] objects, filtered by [ville].
  Future<List<MuseumVenue>> fetchMuseumVenues({required String ville}) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'mode': 'eq.culture',
      'category': 'eq.Musee',
      'ville': 'ilike.$ville*',
      'order': 'name.asc',
    };

    final response = await _dio.get('venues', queryParameters: params);
    final data = response.data as List;
    return data.map((e) => _mapToMuseumVenue(e as Map<String, dynamic>)).toList();
  }

  static MuseumVenue _mapToMuseumVenue(Map<String, dynamic> json) {
    final photo = (json['photo'] as String?) ?? '';
    return MuseumVenue(
      id: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['groupe'] as String? ?? '',
      city: json['ville'] as String? ?? 'Toulouse',
      horaires: json['horaires'] as String? ?? '',
      ticketUrl: (json['ticket_url'] as String?)?.isNotEmpty == true
          ? json['ticket_url'] as String
          : null,
      websiteUrl: json['website_url'] as String? ?? '',
      hasOnlineTicket: json['has_online_ticket'] as bool? ?? false,
      image: photo.isNotEmpty ? photo : 'assets/images/pochette_musee.png',
    );
  }

  /// Fetch monument venues as [MonumentVenue] objects, filtered by [ville].
  Future<List<MonumentVenue>> fetchMonumentVenues({required String ville}) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'mode': 'eq.culture',
      'category': 'eq.Monument historique',
      'ville': 'ilike.$ville*',
      'order': 'groupe.asc,name.asc',
    };

    final response = await _dio.get('venues', queryParameters: params);
    final data = response.data as List;
    return data.map((e) => _mapToMonumentVenue(e as Map<String, dynamic>)).toList();
  }

  static MonumentVenue _mapToMonumentVenue(Map<String, dynamic> json) {
    final photo = (json['photo'] as String?) ?? '';
    return MonumentVenue(
      id: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? '',
      group: json['groupe'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      websiteUrl: json['website_url'] as String? ?? '',
      lienMaps: json['lien_maps'] as String? ?? '',
      image: photo.isNotEmpty ? photo : 'assets/images/pochette_visite.png',
    );
  }

  /// Fetch library venues as [LibraryVenue] objects, filtered by [ville].
  Future<List<LibraryVenue>> fetchLibraryVenues({required String ville}) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'mode': 'eq.culture',
      'category': 'eq.Bibliotheque',
      'ville': 'ilike.$ville*',
      'order': 'groupe.asc,name.asc',
    };

    final response = await _dio.get('venues', queryParameters: params);
    final data = response.data as List;
    return data.map((e) => _mapToLibraryVenue(e as Map<String, dynamic>)).toList();
  }

  static LibraryVenue _mapToLibraryVenue(Map<String, dynamic> json) {
    final photo = (json['photo'] as String?) ?? '';
    return LibraryVenue(
      id: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      group: json['groupe'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      horaires: json['horaires'] as String? ?? '',
      services: json['services'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      websiteUrl: json['website_url'] as String? ?? '',
      lienMaps: json['lien_maps'] as String? ?? '',
      image: photo.isNotEmpty ? photo : 'assets/images/pochette_culture_art.png',
    );
  }

  /// Fetch les venues les plus animees (display_count eleve).
  Future<List<CommerceModel>> fetchHotVenues({
    required String ville,
    int limit = 10,
  }) async {
    final response = await _dio.get('venues', queryParameters: {
      'select': '*',
      'is_active': 'eq.true',
      'ville': 'ilike.$ville*',
      'display_count': 'gt.0',
      'order': 'display_count.desc',
      'limit': '$limit',
    });
    final data = response.data as List;
    return data.map((e) => _mapToCommerce(e as Map<String, dynamic>)).toList();
  }

  /// Fetch tous les venues d'une ville (toutes categories).
  Future<List<CommerceModel>> fetchAllVenues({
    required String ville,
    String? category,
  }) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'ville': 'ilike.$ville*',
      'order': 'name.asc',
    };
    if (category != null) params['category'] = 'ilike.*$category*';

    final response = await _dio.get('venues', queryParameters: params);
    final data = response.data as List;
    return data.map((e) => _mapToCommerce(e as Map<String, dynamic>)).toList();
  }

  /// Enregistrer un check-in utilisateur (upsert, expire apres 2h).
  Future<void> checkIn(int venueId) async {
    try {
      final userId = await UserIdentityService.getUserId();
      final now = DateTime.now().toUtc();
      await _dio.post(
        'venue_presence',
        data: {
          'venue_id': venueId,
          'user_id': userId,
          'checked_in_at': now.toIso8601String(),
          'expires_at': now.add(const Duration(hours: 2)).toIso8601String(),
        },
        options: Options(
          headers: {
            'Prefer': 'return=minimal,resolution=merge-duplicates',
          },
        ),
      );
    } catch (e) {
      debugPrint('[VenuesService] checkIn($venueId) failed: $e');
    }
  }

  static CommerceModel _mapToCommerce(Map<String, dynamic> json) {
    final photo = (json['photo'] as String?) ?? '';
    return CommerceModel(
      nom: json['name'] as String? ?? '',
      categorie: json['category'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      ville: json['ville'] as String? ?? 'Toulouse',
      telephone: json['telephone'] as String? ?? '',
      horaires: json['horaires'] as String? ?? '',
      siteWeb: json['website_url'] as String? ?? '',
      lienMaps: json['lien_maps'] as String? ?? '',
      photo: photo,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      displayCount: (json['display_count'] as num?)?.toInt() ?? 0,
      videoUrl: json['video_url'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  /// Revendiquer une venue par un pro.
  Future<void> claimVenue({
    required int venueId,
    required String proId,
    String? siret,
    String? proofUrl,
    String? message,
  }) async {
    await _dio.post(
      'venue_claims',
      data: {
        'venue_id': venueId,
        'pro_id': proId,
        'siret': siret ?? '',
        'proof_url': proofUrl ?? '',
        'message': message ?? '',
      },
      options: Options(
        headers: {'Prefer': 'return=minimal'},
      ),
    );
  }

  /// Mettre a jour une venue par son proprietaire (marque is_verified).
  Future<void> updateVenueAsPro({
    required int venueId,
    Map<String, dynamic>? updates,
  }) async {
    final data = {
      ...?updates,
      'is_verified': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _dio.patch(
      'venues?id=eq.$venueId',
      data: data,
      options: Options(
        headers: {'Prefer': 'return=minimal'},
      ),
    );
  }
}
