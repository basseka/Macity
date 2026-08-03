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
  ///
  /// Une offre SANS date d'expiration est permanente, pas invisible : le filtre
  /// `expires_at >= maintenant` écartait les NULL (toute comparaison SQL avec
  /// NULL est fausse), alors que le champ est facultatif dans l'admin. Une
  /// offre créée sans date n'apparaissait donc jamais, sans le moindre signal.
  Future<List<Offer>> fetchActiveOffers({String? city}) async {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    final params = <String, dynamic>{
      'select': '*',
      'is_active': 'eq.true',
      'or': '(expires_at.is.null,expires_at.gte.$maintenant)',
      'order': 'created_at.desc',
      // Pas de limite : au-delà de 10 offres, les plus anciennes
      // disparaissaient sans avertissement — un client pouvait payer pour une
      // offre que personne ne voyait. La grille défile, elle absorbe le volume.
    };
    if (city != null) {
      // `ilike` et non `eq` : le reste de l'app compare les villes sans tenir
      // compte de la casse, et `offers.city` n'était pas dans la normalisation
      // (sa colonne s'appelle `city`, pas `ville`). Un « TOULOUSE » saisi à la
      // main faisait disparaître l'offre.
      params['city'] = 'ilike.$city';
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

  /// Recupere TOUTES les offres d'un pro (actives + expirees + inactives).
  /// Trie par created_at desc. Utilise pour l'ecran "Mes offres".
  Future<List<Offer>> fetchOffersByPro(String proProfileId) async {
    final response = await _restDio.get(
      'offers',
      queryParameters: {
        'select': '*',
        'pro_profile_id': 'eq.$proProfileId',
        'order': 'created_at.desc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => Offer.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Met a jour une offre existante (titre, description, dates, places, etc.).
  /// L'id de l'offre doit etre dans `offer.id`.
  Future<void> updateOffer(Offer offer) async {
    await _restDio.patch(
      'offers',
      queryParameters: {'id': 'eq.${offer.id}'},
      data: offer.toSupabaseJson(),
      options: Options(
        headers: {'Prefer': 'return=minimal'},
      ),
    );
  }

  /// Supprime une offre. Le pro ne peut supprimer que ses propres offres
  /// (RLS permissive actuellement, a durcir cote DB si besoin).
  Future<void> deleteOffer(String offerId) async {
    await _restDio.delete(
      'offers',
      queryParameters: {'id': 'eq.$offerId'},
      options: Options(
        headers: {'Prefer': 'return=minimal'},
      ),
    );
  }

  /// Reclame une place et retourne le justificatif a afficher en QR.
  ///
  /// Passe par la RPC `claim_offer`, qui verrouille la ligne d'offre : c'est
  /// elle qui garantit le compteur quand deux personnes cliquent en meme
  /// temps, ce que l'ancien lire-puis-ecrire de [claimSpot] ne faisait pas.
  /// La RPC est idempotente par device : rouvrir la popup renvoie le meme
  /// code au lieu de consommer une seconde place.
  ///
  /// Leve une [OfferClaimException] avec un message lisible quand l'offre est
  /// pleine, expiree ou desactivee.
  Future<OfferClaim> claimOffer(String offerId, String deviceId) async {
    try {
      final res = await _restDio.post(
        'rpc/claim_offer',
        data: {'p_offer_id': offerId, 'p_device_id': deviceId},
      );
      return OfferClaim.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // PostgREST remonte le RAISE EXCEPTION de la RPC dans `message`.
      final data = e.response?.data;
      final msg = data is Map ? data['message'] as String? : null;
      throw OfferClaimException(msg ?? 'La reclamation a echoue');
    }
  }

  /// Incremente claimed_spots pour une offre.
  @Deprecated('Utiliser claimOffer : incrementation non atomique, sans trace.')
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

/// Justificatif d'une place reclamee. `code` est ce qui est encode dans le QR
/// et affiche en clair dessous, pour la saisie manuelle si le scan echoue.
class OfferClaim {
  final String id;
  final String code;
  final String offerTitle;
  final String businessName;
  final DateTime? redeemedAt;

  /// Vrai quand ce device avait deja reclame l'offre : on lui reaffiche son
  /// code existant, aucune place supplementaire n'a ete consommee.
  final bool alreadyClaimed;

  const OfferClaim({
    required this.id,
    required this.code,
    this.offerTitle = '',
    this.businessName = '',
    this.redeemedAt,
    this.alreadyClaimed = false,
  });

  /// Deja presente au commercant : le code ne vaut plus rien.
  bool get isRedeemed => redeemedAt != null;

  factory OfferClaim.fromJson(Map<String, dynamic> json) => OfferClaim(
        id: json['id'] as String,
        code: json['code'] as String,
        offerTitle: json['offer_title'] as String? ?? '',
        businessName: json['business_name'] as String? ?? '',
        redeemedAt: json['redeemed_at'] != null
            ? DateTime.tryParse(json['redeemed_at'] as String)
            : null,
        alreadyClaimed: json['already_claimed'] as bool? ?? false,
      );
}

/// Refus metier renvoye par `claim_offer` (offre pleine, expiree, inactive).
/// Le message est deja redige pour etre montre a l'utilisateur.
class OfferClaimException implements Exception {
  final String message;
  const OfferClaimException(this.message);
  @override
  String toString() => message;
}
