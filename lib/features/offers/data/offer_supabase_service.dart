import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';

/// Service Supabase pour les offres promotionnelles.
///
/// Table PostgREST : `offers`
/// Bucket Storage  : `offers`
class OfferSupabaseService {
  final Dio _restDio;
  final Dio _storageDio;

  OfferSupabaseService({Dio? restDio, Dio? storageDio})
      : _restDio = restDio ?? _createRestDio(),
        _storageDio = storageDio ?? _createStorageDio();

  static Dio _createRestDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  static Dio _createStorageDio() {
    final dio = DioClient.withBaseUrl(
      '${SupabaseConfig.supabaseUrl}/storage/v1/',
    );
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  // ───────────────────────────────────────────
  // Storage : upload photo
  // ───────────────────────────────────────────

  /// Upload une photo locale vers Supabase Storage.
  /// Retourne l'URL publique de l'image.
  Future<String> uploadPhoto(String localPath) async {
    final file = File(localPath);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${localPath.split('/').last}';

    final bytes = await file.readAsBytes();

    final ext = localPath.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    await _storageDio.post(
      'object/offers/$fileName',
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': contentType,
        },
      ),
    );

    return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/offers/$fileName';
  }

  /// Recupere les offres actives et non expirees.
  Future<List<Offer>> fetchActiveOffers({String? city}) async {
    final params = <String, dynamic>{
      'select': '*',
      'is_active': 'eq.true',
      'expires_at': 'gte.${DateTime.now().toUtc().toIso8601String()}',
      'order': 'created_at.desc',
      'limit': '10',
    };
    if (city != null) {
      params['city'] = 'eq.$city';
    }

    final response = await _restDio.get(
      'offers',
      queryParameters: params,
    );
    final data = response.data as List;
    return data
        .map((e) => Offer.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Insere une nouvelle offre.
  Future<void> insertOffer(Offer offer) async {
    await _restDio.post(
      'offers',
      data: offer.toSupabaseJson(),
      options: Options(
        headers: {'Prefer': 'return=minimal'},
      ),
    );
  }

  /// Incremente claimed_spots pour une offre.
  Future<void> claimSpot(String offerId) async {
    // Utilise RPC ou PATCH avec un header special pour incrementer
    // PostgREST ne supporte pas l'increment natif, on lit puis ecrit.
    final response = await _restDio.get(
      'offers',
      queryParameters: {
        'select': 'claimed_spots',
        'id': 'eq.$offerId',
      },
    );
    final data = response.data as List;
    if (data.isEmpty) return;
    final current = data.first['claimed_spots'] as int;

    await _restDio.patch(
      'offers',
      queryParameters: {'id': 'eq.$offerId'},
      data: {'claimed_spots': current + 1},
      options: Options(
        headers: {'Prefer': 'return=minimal'},
      ),
    );
  }
}
