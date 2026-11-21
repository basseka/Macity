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

/// Disponibilité de l'option « Notification push + teaser » pour un event
/// (RPC `push_teaser_availability`, migration 20261121120000).
/// [reason] : null | 'inactive' | 'ville' | 'trop_tard' | 'complet'.
class PushTeaserAvailability {
  final bool available;
  final String? reason;
  final int priceCents;
  final int minPhones;
  final int maxPhones;
  final String villeLabel;
  final DateTime? sendAt;

  const PushTeaserAvailability({
    required this.available,
    this.reason,
    this.priceCents = 0,
    this.minPhones = 0,
    this.maxPhones = 0,
    this.villeLabel = '',
    this.sendAt,
  });

  /// L'option s'affiche (cochable ou « complet »). Masquée sinon.
  bool get isShown => available || reason == 'complet';

  String get formattedPrice {
    final euros = priceCents / 100;
    return euros == euros.roundToDouble()
        ? '${euros.toStringAsFixed(0)} €'
        : '${euros.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  factory PushTeaserAvailability.fromJson(Map<String, dynamic> j) =>
      PushTeaserAvailability(
        available: (j['available'] as bool?) ?? false,
        reason: j['reason'] as String?,
        priceCents: (j['price_cents'] as num?)?.toInt() ?? 0,
        minPhones: (j['min_phones'] as num?)?.toInt() ?? 0,
        maxPhones: (j['max_phones'] as num?)?.toInt() ?? 0,
        villeLabel: j['ville_label'] as String? ?? '',
        sendAt: DateTime.tryParse(j['send_at'] as String? ?? '')?.toLocal(),
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

  /// Disponibilité de l'option push teaser pour cette ville et ce créneau.
  /// Retourne null en cas d'erreur réseau ou si la migration n'est pas
  /// appliquée : l'option reste alors masquée.
  Future<PushTeaserAvailability?> fetchPushTeaserAvailability({
    required String ville,
    required String date,
    required String heure,
  }) async {
    try {
      final res = await _restDio.post(
        'rpc/push_teaser_availability',
        data: {'p_ville': ville, 'p_date': date, 'p_heure': heure},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return PushTeaserAvailability.fromJson(data);
      }
    } catch (e) {
      debugPrint('[Publication] push teaser availability error: $e');
    }
    return null;
  }

  /// Crée la session Stripe et ouvre la page de paiement.
  /// [payload] = UserEvent.toSupabaseJson(userId: deviceUuid).
  /// Retourne null si la page Stripe s'est ouverte, sinon le message d'erreur
  /// à afficher (ex. option push devenue complète entre-temps).
  Future<String?> checkout({
    required Map<String, dynamic> payload,
    required String tier,
    required String durationKey,
    required String userId,
    String? ville,
    String? eventTitle,
    bool pushTeaser = false,
    String? establishmentId,
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
          if (pushTeaser) 'push_teaser': true,
          if (establishmentId != null) 'establishment_id': establishmentId,
        },
        options: Options(headers: {
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        }),
      );
      final url = response.data['url'] as String?;
      if (url == null || url.isEmpty) {
        debugPrint('[Publication] no checkout url');
        return 'Le paiement n\'a pas pu s\'ouvrir. Réessaie.';
      }
      final opened =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return opened ? null : 'Le paiement n\'a pas pu s\'ouvrir. Réessaie.';
    } on DioException catch (e) {
      debugPrint('[Publication] checkout error: $e');
      final data = e.response?.data;
      if (data is Map && data['error'] is String && e.response?.statusCode == 409) {
        return data['error'] as String;
      }
      if (data is Map && data['error'] is String && e.response?.statusCode == 400) {
        return data['error'] as String;
      }
      return 'Le paiement n\'a pas pu s\'ouvrir. Réessaie.';
    } catch (e) {
      debugPrint('[Publication] checkout error: $e');
      return 'Le paiement n\'a pas pu s\'ouvrir. Réessaie.';
    }
  }
}
