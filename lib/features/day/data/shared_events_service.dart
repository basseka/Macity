import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';

/// Un contact du telephone qui est aussi utilisateur de l'app.
class AppContact {
  final String userId;
  final String prenom;
  final String telephone;
  final String? contactName; // nom dans les contacts du telephone

  const AppContact({
    required this.userId,
    required this.prenom,
    required this.telephone,
    this.contactName,
  });
}

/// Resultat d'un pick via le Contact Picker systeme.
/// [pulzUser] non-null si le numero matche un utilisateur Pulz.
class PickedContact {
  final String displayName;
  final String phone;
  final AppContact? pulzUser;

  const PickedContact({
    required this.displayName,
    required this.phone,
    this.pulzUser,
  });

  bool get isOnPulz => pulzUser != null;
}

/// Service pour le partage d'events entre utilisateurs.
class SharedEventsService {
  final Dio _dio;

  SharedEventsService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  // ─────────────────────────────────────────
  // Contacts : Android Contact Picker (un a la fois, sans permission)
  // ─────────────────────────────────────────

  /// Ouvre le Contact Picker systeme et matche le numero retourne.
  /// Aucune permission n'est requise (le picker tourne dans le processus systeme).
  /// Retourne null si l'utilisateur a annule.
  Future<PickedContact?> pickContactAndMatch() async {
    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return null;

    final normalizedPhones = contact.phones
        .map((p) => _normalizePhone(p.number))
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();

    if (normalizedPhones.isEmpty) {
      return PickedContact(displayName: contact.displayName, phone: '');
    }

    try {
      final myUserId = await UserIdentityService.getUserId();
      final response = await _dio.post(
        'rpc/find_users_by_phones',
        data: {'phones': normalizedPhones},
      );
      final data = response.data as List;
      for (final row in data) {
        final uid = row['user_id'] as String;
        if (uid == myUserId) continue;
        final tel = row['telephone'] as String;
        return PickedContact(
          displayName: contact.displayName,
          phone: tel,
          pulzUser: AppContact(
            userId: uid,
            prenom: row['prenom'] as String? ?? '',
            telephone: tel,
            contactName: contact.displayName,
          ),
        );
      }
    } catch (e) {
      debugPrint('[SharedEvents] pickContactAndMatch RPC failed: $e');
    }
    return PickedContact(
      displayName: contact.displayName,
      phone: normalizedPhones.first,
    );
  }

  /// Normalise un numero : garde uniquement les chiffres,
  /// remplace le 0 initial par +33 (France).
  static String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('0') && digits.length == 10) {
      return '+33${digits.substring(1)}';
    }
    if (digits.startsWith('33') && digits.length == 11) {
      return '+$digits';
    }
    return digits;
  }

  // ─────────────────────────────────────────
  // CRUD shared_events
  // ─────────────────────────────────────────

  /// Partage un event avec plusieurs utilisateurs.
  Future<void> shareEvent({
    required String eventId,
    required List<String> toUserIds,
  }) async {
    final fromUserId = await UserIdentityService.getUserId();
    final rows = toUserIds
        .map((uid) => {
              'event_id': eventId,
              'from_user_id': fromUserId,
              'to_user_id': uid,
            })
        .toList();

    await _dio.post(
      'shared_events',
      data: rows,
      options: Options(
        headers: {
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
      ),
    );
  }

  /// Recupere les events partages avec moi (to_user_id = moi).
  Future<List<UserEvent>> fetchSharedWithMe() async {
    final myUserId = await UserIdentityService.getUserId();
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Jointure : shared_events inner join user_events
    final response = await _dio.get(
      'shared_events',
      queryParameters: {
        'select': 'from_user_id,user_events!inner(*)',
        'to_user_id': 'eq.$myUserId',
        'user_events.date': 'gte.$today',
        'order': 'created_at.desc',
      },
    );

    final data = response.data as List;
    return data.map((row) {
      final eventJson = row['user_events'] as Map<String, dynamic>;
      return UserEvent.fromSupabaseJson(eventJson);
    }).toList();
  }

  /// Nombre d'events partages avec moi.
  Future<int> countSharedWithMe() async {
    final myUserId = await UserIdentityService.getUserId();
    final response = await _dio.get(
      'shared_events',
      queryParameters: {
        'select': 'id',
        'to_user_id': 'eq.$myUserId',
      },
      options: Options(
        headers: {'Prefer': 'count=exact'},
      ),
    );
    // Le header content-range contient le count
    final range = response.headers.value('content-range');
    if (range != null && range.contains('/')) {
      return int.tryParse(range.split('/').last) ?? 0;
    }
    return (response.data as List).length;
  }
}
