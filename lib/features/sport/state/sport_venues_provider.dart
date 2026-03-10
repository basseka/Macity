import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/sport_venues_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/culture/data/dance_venues_data.dart';
import 'package:pulz_app/features/sport/data/basketball_venues_data.dart';
import 'package:pulz_app/features/sport/data/boxing_venues_data.dart';
import 'package:pulz_app/features/sport/data/fitness_venues_data.dart';
import 'package:pulz_app/features/sport/data/football_venues_data.dart';
import 'package:pulz_app/features/sport/data/golf_venues_data.dart';
import 'package:pulz_app/features/sport/data/racket_venues_data.dart';
import 'package:pulz_app/features/sport/data/swimming_venues_data.dart';

/// Provider qui charge les venues sport depuis Supabase,
/// avec fallback sur les donnees statiques en cas d'erreur.
final sportVenuesProvider =
    FutureProvider.family<List<CommerceModel>, String>((ref, sportType) async {
  // Seule Toulouse est implémentée pour l'instant
  final city = ref.watch(selectedCityProvider);
  if (city.toLowerCase() != 'toulouse') return [];

  try {
    final service = SportVenuesSupabaseService();
    final venues = await service.fetchVenues(sportType: sportType);
    if (venues.isNotEmpty) return venues;
    // Si la table est vide, fallback statique
    return _staticFallback(sportType);
  } catch (e) {
    debugPrint('[sportVenuesProvider] Supabase error for $sportType: $e');
    return _staticFallback(sportType);
  }
});

/// Combine toutes les venues raquette (5 sous-types).
final racketAllVenuesProvider =
    FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  if (city.toLowerCase() != 'toulouse') return [];

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
  if (city.toLowerCase() != 'toulouse') return [];

  try {
    final service = SportVenuesSupabaseService();
    return await service.fetchDanceVenues();
  } catch (e) {
    debugPrint('[danceVenuesProvider] Supabase error: $e');
    return [];
  }
});

List<CommerceModel> _staticFallback(String sportType) {
  return switch (sportType) {
    'fitness' => FitnessVenuesData.venues,
    'boxe' => BoxingVenuesData.venues,
    'golf' => GolfVenuesData.venues,
    'terrain-football' => FootballVenuesData.venues,
    'terrain-basketball' => BasketballVenuesData.venues,
    'piscine' => SwimmingVenuesData.venues,
    'tennis' => RacketVenuesData.tennis,
    'padel' => RacketVenuesData.padel,
    'squash' => RacketVenuesData.squash,
    'ping-pong' => RacketVenuesData.pingPong,
    'badminton' => RacketVenuesData.badminton,
    _ => <CommerceModel>[],
  };
}
