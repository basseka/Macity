import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/reported_events/domain/models/chat_message.dart';

/// Service Supabase pour le chat communautaire des signalements.
///
/// Table : `reported_event_messages` (cascade depuis reported_events).
class ReportedEventChatService {
  final Dio _dio;

  ReportedEventChatService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch initial OU incremental.
  /// - [since] null → ramene les [limit] derniers messages (initial load)
  /// - [since] non null → ramene uniquement les messages plus recents
  Future<List<ChatMessage>> fetchMessages(
    String eventId, {
    DateTime? since,
    int limit = 200,
  }) async {
    final query = <String, String>{
      'select': '*',
      'reported_event_id': 'eq.$eventId',
      'order': 'created_at.asc',
      'limit': limit.toString(),
    };
    if (since != null) {
      query['created_at'] = 'gt.${since.toUtc().toIso8601String()}';
    }
    final res = await _dio.get(
      'reported_event_messages',
      queryParameters: query,
    );
    final data = res.data as List;
    return data
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Envoie un message. UUID genere cote client + return=minimal pour eviter
  /// les faux 42501 (cf. feedback PostgREST RLS sur INSERT).
  Future<String> sendMessage({
    required String eventId,
    required String userId,
    required String prenom,
    String? avatarUrl,
    required String content,
  }) async {
    final id = const Uuid().v4();
    await _dio.post(
      'reported_event_messages',
      data: {
        'id': id,
        'reported_event_id': eventId,
        'user_id': userId,
        'prenom': prenom,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
        'content': content,
      },
      options: Options(headers: {'Prefer': 'return=minimal'}),
    );
    return id;
  }

  Future<void> reportMessage(String messageId) async {
    await _dio.post(
      'rpc/report_chat_message',
      data: {'p_message_id': messageId},
    );
  }
}
