import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/sport_venues_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/culture/data/dance_venues_data.dart';

/// Provider qui charge les venues sport depuis Supabase, filtrées par ville.
final sportVenuesProvider =
    FutureProvider.family<List<CommerceModel>, String>((ref, sportType) async {
  final city = ref.watch(selectedCityProvider);

  try {
    final service = SportVenuesSupabaseService();
    return await service.fetchVenues(sportType: sportType, ville: city);
  } catch (e) {
    debugPrint('[sportVenuesProvider] Supabase error for $sportType: $e');
    return <CommerceModel>[];
  }
});

/// Combine toutes les venues raquette (5 sous-types).
final racketAllVenuesProvider =
    FutureProvider<List<CommerceModel>>((ref) async {
  ref.watch(selectedCityProvider);

  final results = await Future.wait([
    ref.watch(sportVenuesProvider('tennis').future),
    ref.watch(sportVenuesProvider('padel').future),
    ref.watch(sportVenuesProvider('squash').future),
    ref.watch(sportVenuesProvider('ping-pong').future),
    ref.watch(sportVenuesProvider('badminton').future),
  ]);
  return results.expand((list) => list).toList();
});

/// Provider pour les salles de danse depuis Supabase.
final danceVenuesProvider =
    FutureProvider<List<DanceVenue>>((ref) async {
  final city = ref.watch(selectedCityProvider);

  try {
    final service = SportVenuesSupabaseService();
    return await service.fetchDanceVenues(ville: city);
  } catch (e) {
    debugPrint('[danceVenuesProvider] Supabase error: $e');
    return <DanceVenue>[];
  }
});
