import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/reported_events/data/reported_event_chat_service.dart';
import 'package:pulz_app/features/reported_events/domain/models/chat_message.dart';

final reportedEventChatServiceProvider =
    Provider((_) => ReportedEventChatService());

/// Etat d'activite du chat (typing/scroll recent).
/// Active = polling 3s. Inactif = polling 15s. Reduit la charge serveur
/// d'un facteur 5 sur les chats peu actifs.
class ChatActivityNotifier extends StateNotifier<bool> {
  ChatActivityNotifier() : super(true);

  Timer? _idleTimer;

  void touch() {
    state = true;
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) state = false;
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}

final chatActivityProvider = StateNotifierProvider.family<
    ChatActivityNotifier, bool, String>((ref, _) => ChatActivityNotifier());

/// Stream de messages pour un signalement.
/// - 1er fetch : 200 derniers messages
/// - Tours suivants : DELTA seulement (created_at > last) → ~5 KB/req au lieu
///   de 250 KB. Reduit la bande passante d'un facteur 50 sur chats actifs.
/// - Backoff : 3s si actif, 15s sinon (lit chatActivityProvider).
final reportedEventChatProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, eventId) async* {
  final svc = ref.watch(reportedEventChatServiceProvider);
  final accumulated = <ChatMessage>[];
  DateTime? lastSeen;

  // Initial fetch
  try {
    final initial = await svc.fetchMessages(eventId, limit: 200);
    accumulated.addAll(initial);
    if (initial.isNotEmpty) lastSeen = initial.last.createdAt;
    yield List.of(accumulated);
  } catch (_) {
    yield <ChatMessage>[];
  }

  // Polling incremental avec backoff
  while (true) {
    final isActive = ref.read(chatActivityProvider(eventId));
    await Future<void>.delayed(
      Duration(seconds: isActive ? 3 : 15),
    );
    try {
      final delta = await svc.fetchMessages(eventId, since: lastSeen, limit: 200);
      if (delta.isNotEmpty) {
        accumulated.addAll(delta);
        lastSeen = delta.last.createdAt;
        yield List.of(accumulated);
      }
    } catch (_) {
      // Garde la derniere valeur en cas d'echec reseau
    }
  }
});
