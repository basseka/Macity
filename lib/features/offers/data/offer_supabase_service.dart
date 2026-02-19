import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/offers/domain/models/offer.dart';

/// Service Supabase pour les offres promotionnelles.
///
/// Table PostgREST : `offers`
class OfferSupabaseService {
  final Dio _restDio;

  OfferSupabaseService({Dio? restDio})
      : _restDio = restDio ?? _createRestDio();

  static Dio _createRestDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
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
