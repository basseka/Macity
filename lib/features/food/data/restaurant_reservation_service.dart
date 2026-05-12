import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/core/config/supabase_config.dart';

/// Reservation restaurant (etat affiche cote app).
class RestaurantReservation {
  final String id;
  final int venueId;
  final String userId;
  final String userPrenom;
  final String userTelephone;
  final DateTime dateReservation;
  final String heureReservation; // 'HH:MM'
  final int nbPersonnes;
  final String commentaire;
  final String status; // pending, accepted, declined, expired
  final String code;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;

  const RestaurantReservation({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.userPrenom,
    required this.userTelephone,
    required this.dateReservation,
    required this.heureReservation,
    required this.nbPersonnes,
    required this.commentaire,
    required this.status,
    required this.code,
    required this.createdAt,
    required this.respondedAt,
    required this.expiresAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isVisible =>
      (isPending || isAccepted) && expiresAt.isAfter(DateTime.now());

  factory RestaurantReservation.fromJson(Map<String, dynamic> j) {
    return RestaurantReservation(
      id: j['id'] as String,
      venueId: (j['venue_id'] as num).toInt(),
      userId: j['user_id'] as String,
      userPrenom: (j['user_prenom'] as String?) ?? '',
      userTelephone: (j['user_telephone'] as String?) ?? '',
      dateReservation: DateTime.parse(j['date_reservation'] as String),
      heureReservation: (j['heure_reservation'] as String).substring(0, 5),
      nbPersonnes: (j['nb_personnes'] as num).toInt(),
      commentaire: (j['commentaire'] as String?) ?? '',
      status: j['status'] as String,
      code: (j['code'] as String?) ?? '',
      createdAt: DateTime.parse(j['created_at'] as String),
      respondedAt: j['responded_at'] != null
          ? DateTime.parse(j['responded_at'] as String)
          : null,
      expiresAt: DateTime.parse(j['expires_at'] as String),
    );
  }
}

class RestaurantReservationService {
  final _dio = Dio();

  /// Soumet une demande de reservation. Retourne l'id si OK, throw sinon.
  Future<String> submit({
    required int venueId,
    required String userPrenom,
    required String userTelephone,
    required DateTime date,
    required String heure,
    required int nbPersonnes,
    required String commentaire,
  }) async {
    final userId = await UserIdentityService.getUserId();
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final res = await _dio.post(
        '${SupabaseConfig.supabaseUrl}/functions/v1/submit-reservation',
        data: {
          'venue_id': venueId,
          'user_id': userId,
          'user_prenom': userPrenom,
          'user_telephone': userTelephone,
          'date': dateStr,
          'heure': heure,
          'nb_personnes': nbPersonnes,
          'commentaire': commentaire,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
            'apikey': SupabaseConfig.supabaseAnonKey,
          },
          validateStatus: (_) => true,
        ),
      );
      if (res.statusCode == 200 && res.data is Map) {
        return res.data['reservation_id'] as String;
      }
      final errMsg = res.data is Map && res.data['message'] is String
          ? res.data['message']
          : (res.data is Map && res.data['error'] is String
              ? res.data['error']
              : 'Erreur ${res.statusCode}');
      throw Exception(errMsg);
    } catch (e) {
      debugPrint('[ReservationService] submit error: $e');
      rethrow;
    }
  }

  /// Recupere les reservations actives (pending ou accepted, non expirees) du
  /// user courant pour un venue. Liste vide si rien.
  Future<List<RestaurantReservation>> fetchActive(int venueId) async {
    final userId = await UserIdentityService.getUserId();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    try {
      final res = await _dio.get(
        '${SupabaseConfig.supabaseUrl}/rest/v1/restaurant_reservations',
        queryParameters: {
          'select': '*',
          'user_id': 'eq.$userId',
          'venue_id': 'eq.$venueId',
          'status': 'in.(pending,accepted)',
          'expires_at': 'gt.$nowIso',
          'order': 'created_at.desc',
        },
        options: Options(
          headers: {
            'apikey': SupabaseConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          },
        ),
      );
      final raw = res.data is String ? jsonDecode(res.data) : res.data;
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(RestaurantReservation.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[ReservationService] fetchActive error: $e');
      return const [];
    }
  }
}
