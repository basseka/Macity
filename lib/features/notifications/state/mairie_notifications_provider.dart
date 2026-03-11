import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/notifications/data/mairie_notifications_service.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';

final mairieNotificationsServiceProvider =
    Provider((_) => MairieNotificationsService());

final mairieNotificationsProvider =
    FutureProvider<List<MairieNotification>>((ref) async {
  final ville = await ref.watch(userVilleProvider.future);
  if (ville.isEmpty) return [];
  final service = ref.read(mairieNotificationsServiceProvider);
  return service.fetchForCity(ville);
});
