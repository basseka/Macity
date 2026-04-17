import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/reported_events/state/reported_events_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider qui ouvre un abonnement Supabase Realtime sur la table
/// `reported_events`. Chaque INSERT/UPDATE/DELETE invalide le feed provider,
/// ce qui re-fetch et met a jour la carte + carousel en temps reel.
///
/// Pour activer l'abonnement, il suffit de `ref.watch()` ce provider depuis
/// n'importe quel widget visible (home_screen / feed_screen). Le channel
/// se ferme automatiquement via `ref.onDispose` quand plus aucun consumer
/// ne l'ecoute.
final reportedEventsRealtimeProvider = Provider<void>((ref) {
  final client = Supabase.instance.client;
  final channel = client
      .channel('public:reported_events')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'reported_events',
        callback: (payload) {
          debugPrint('[Realtime] INSERT reported_events ${payload.newRecord['id']}');
          ref.invalidate(reportedEventsFeedProvider);
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'reported_events',
        callback: (payload) {
          debugPrint('[Realtime] UPDATE reported_events ${payload.newRecord['id']}');
          ref.invalidate(reportedEventsFeedProvider);
        },
      )
      .subscribe();

  ref.onDispose(() {
    debugPrint('[Realtime] disposing reported_events channel');
    client.removeChannel(channel);
  });
});
