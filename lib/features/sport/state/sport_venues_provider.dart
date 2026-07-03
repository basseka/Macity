import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/sport_venues_supabase_service.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/culture/data/dance_venues_data.dart';

/// Map sportType → category dans la table venues
const _sportTypeToCategory = <String, String>{
  'fitness': 'Salle de fitness',
  'boxe': 'Salles de boxe',
  'terrain-football': 'Terrain de football',
  'terrain-basketball': 'Terrain de basketball',
  'piscine': 'Piscine',
  'golf': 'Golf',
  'tennis': 'Tennis',
  'padel': 'Padel',
  'squash': 'Squash',
  'ping-pong': 'Ping-pong',
  'badminton': 'Badminton',
};

/// Photo de pochette par chaine (token -> photo_url), depuis `fitness_chains`.
/// Sert a afficher une vraie photo sur la carte chaine (Basic-Fit, Keep Cool…).
/// Vide en cas d'erreur : la carte retombe sur le logo asset puis l'icone.
final fitnessChainPhotosProvider =
    FutureProvider<Map<String, String>>((ref) async {
  try {
    return await SportVenuesSupabaseService().fetchChainPhotos();
  } catch (e) {
    debugPrint('[fitnessChainPhotos] $e');
    return const <String, String>{};
  }
});

/// Provider qui charge les venues sport depuis Supabase, filtrées par ville.
/// Essaie d'abord sport_venues (ancienne table), puis venues (nouvelle table OSM).
final sportVenuesProvider =
    FutureProvider.autoDispose.family<List<CommerceModel>, String>((ref, sportType) async {
  final city = ref.watch(selectedCityProvider);

  List<CommerceModel> venues = <CommerceModel>[];
  try {
    final service = SportVenuesSupabaseService();
    final results = await service.fetchVenues(sportType: sportType, ville: city);
    if (results.isNotEmpty) venues = results;
  } catch (e) {
    debugPrint('[sportVenuesProvider] sport_venues error for $sportType: $e');
  }

  // Fallback sur la table venues (donnees OSM) si rien trouve
  if (venues.isEmpty) {
    final category = _sportTypeToCategory[sportType];
    if (category != null) {
      try {
        venues = await VenuesSupabaseService().fetchVenues(
          mode: 'sport', ville: city, category: category,
        );
      } catch (e) {
        debugPrint('[sportVenuesProvider] venues fallback error: $e');
      }
    }
  }

  return venues;
});

/// Combine toutes les venues raquette (5 sous-types).
final racketAllVenuesProvider =
    FutureProvider.autoDispose<List<CommerceModel>>((ref) async {
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
    FutureProvider.autoDispose<List<DanceVenue>>((ref) async {
  final city = ref.watch(selectedCityProvider);

  try {
    final service = SportVenuesSupabaseService();
    return await service.fetchDanceVenues(ville: city);
  } catch (e) {
    debugPrint('[danceVenuesProvider] Supabase error: $e');
    return <DanceVenue>[];
  }
});
