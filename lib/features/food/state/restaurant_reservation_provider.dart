import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/food/data/restaurant_reservation_service.dart';

/// Reservations actives (pending+accepted, non expirees) du user pour un
/// venue donne. Re-fetch periodique (30s) pour capter la reponse du resto
/// sans necessiter une push notification.
final activeReservationsProvider = StreamProvider.family
    .autoDispose<List<RestaurantReservation>, int>((ref, venueId) async* {
  final service = RestaurantReservationService();

  // Premier fetch immediat
  yield await service.fetchActive(venueId);

  // Refresh toutes les 30s tant que la sheet est ouverte
  final timer = Stream.periodic(const Duration(seconds: 30));
  await for (final _ in timer) {
    yield await service.fetchActive(venueId);
  }
});
