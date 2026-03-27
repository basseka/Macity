import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
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
  // Contacts : lire & matcher
  // ─────────────────────────────────────────

  /// Demande la permission contacts et lit les numeros.
  Future<List<AppContact>> findAppContacts() async {
    final status = await Permission.contacts.request();
    debugPrint('[SHARE-DEBUG] contacts permission: $status');
    if (!status.isGranted) {
      debugPrint('[SHARE-DEBUG] permission NOT granted');
      return [];
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    debugPrint('[SHARE-DEBUG] contacts loaded: ${contacts.length}');

    // Extraire tous les numeros, normalises
    final phoneToName = <String, String>{};
    for (final c in contacts) {
      for (final phone in c.phones) {
        final normalized = _normalizePhone(phone.number);
        debugPrint('[SHARE-DEBUG] ${c.displayName}: raw="${phone.number}" -> normalized="$normalized"');
        if (normalized.isNotEmpty) {
          phoneToName[normalized] = c.displayName;
        }
      }
    }

    debugPrint('[SHARE-DEBUG] unique phones: ${phoneToName.length}');
    if (phoneToName.isEmpty) return [];

    // Appeler la RPC Supabase pour trouver les users correspondants
    final myUserId = await UserIdentityService.getUserId();
    final phones = phoneToName.keys.toList();
    debugPrint('[SHARE-DEBUG] calling RPC with ${phones.length} phones, first 5: ${phones.take(5).toList()}');

    try {
      final response = await _dio.post(
        'rpc/find_users_by_phones',
        data: {'phones': phones},
      );
      final data = response.data as List;
      debugPrint('[SHARE-DEBUG] RPC returned ${data.length} matches');
      return data
          .map((row) {
            final uid = row['user_id'] as String;
            final tel = row['telephone'] as String;
            return AppContact(
              userId: uid,
              prenom: row['prenom'] as String? ?? '',
              telephone: tel,
              contactName: phoneToName[tel],
            );
          })
          .where((c) => c.userId != myUserId) // exclure soi-meme
          .toList();
    } catch (e) {
      debugPrint('[SharedEvents] findAppContacts RPC failed: $e');
      return [];
    }
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
