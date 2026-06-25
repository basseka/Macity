import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

/// Un palier tarifaire de publication (tier × durée) lu depuis la table
/// `publication_prices` (modifiable en base / admin).
class PublicationPrice {
  final String tier;          // 'standard' | 'au_top' | 'a_la_une'
  final String durationKey;   // 'semaine' | 'mois' | 'date'
  final int amountCents;
  final bool isActive;

  const PublicationPrice({
    required this.tier,
    required this.durationKey,
    required this.amountCents,
    required this.isActive,
  });

  String get formatted {
    final euros = amountCents / 100;
    return euros == euros.roundToDouble()
        ? '${euros.toStringAsFixed(0)} €'
        : '${euros.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  factory PublicationPrice.fromJson(Map<String, dynamic> j) => PublicationPrice(
        tier: j['tier'] as String,
        durationKey: j['duration_key'] as String,
        amountCents: (j['amount_cents'] as num).toInt(),
        isActive: (j['is_active'] as bool?) ?? true,
      );
}

/// Service de publication payante d'un event public par un particulier.
/// Lit la grille de prix et lance le Checkout Stripe via l'edge function
/// `create-publication-checkout` (qui stocke l'event en attente puis crée la
/// session). Le webhook insérera l'event dans user_events après paiement.
class PublicationService {
  final Dio _restDio;

  PublicationService({Dio? restDio}) : _restDio = restDio ?? _createRestDio();

  static Dio _createRestDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Charge la grille tarifaire active depuis `publication_prices`.
  Future<List<PublicationPrice>> fetchPrices() async {
    final res = await _restDio.get(
      'publication_prices',
      queryParameters: {
        'select': 'tier,duration_key,amount_cents,is_active',
        'is_active': 'eq.true',
      },
    );
    final list = res.data as List;
    return list
        .map((e) => PublicationPrice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crée la session Stripe et ouvre la page de paiement.
  /// [payload] = UserEvent.toSupabaseJson(userId: deviceUuid).
  /// Retourne true si la page Stripe s'est ouverte.
  Future<bool> checkout({
    required Map<String, dynamic> payload,
    required String tier,
    required String durationKey,
    required String userId,
    String? ville,
    String? eventTitle,
  }) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        '${SupabaseConfig.supabaseUrl}/functions/v1/create-publication-checkout',
        data: {
          'payload': payload,
          'tier': tier,
          'duration_key': durationKey,
          'user_id': userId,
          'ville': ville,
          'event_title': eventTitle,
        },
        options: Options(headers: {
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        }),
      );
      final url = response.data['url'] as String?;
      if (url == null || url.isEmpty) {
        debugPrint('[Publication] no checkout url');
        return false;
      }
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[Publication] checkout error: $e');
      return false;
    }
  }
}
