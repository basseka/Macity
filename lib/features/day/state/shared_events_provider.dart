import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/day/data/shared_events_service.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';

final sharedEventsServiceProvider = Provider((_) => SharedEventsService());

/// Events partages avec moi.
final sharedWithMeProvider = FutureProvider<List<UserEvent>>((ref) {
  final service = ref.read(sharedEventsServiceProvider);
  return service.fetchSharedWithMe();
});
