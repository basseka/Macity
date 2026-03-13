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
    final venues = await service.fetchDanceVenues();
    if (venues.isNotEmpty) return venues;
    return _staticDanceFallback();
  } catch (e) {
    debugPrint('[danceVenuesProvider] Supabase error: $e');
    return _staticDanceFallback();
  }
});

List<DanceVenue> _staticDanceFallback() {
  return const [
    DanceVenue(id: 'd1', name: 'Encas-Danses Studio', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Classique / Ballet', city: 'Toulouse', horaires: '', websiteUrl: 'https://www.encas-danses.com/', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd2', name: 'Le 144 Dance Avenue', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Hip-Hop / Street / Breakdance', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd3', name: 'Studio9 Toulouse', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Classique / Ballet', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd4', name: 'La Salle', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Classique / Ballet', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd5', name: 'La Maison De La Danse', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Contemporaine', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd6', name: 'Choreographic Centre De Toulouse', description: 'Centre choregraphique', category: 'Centre choregraphique', group: 'Contemporaine', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd7', name: 'Atelier Danse', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Classique / Ballet', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd8', name: 'La Place De La Danse CDCN', description: 'Centre choregraphique', category: 'Centre choregraphique', group: 'Contemporaine', city: 'Toulouse', horaires: '', websiteUrl: 'https://www.laplacedeladanse.com/', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd9', name: 'Ballet School Harold & Alexandra Paturet', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Classique / Ballet', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd10', name: 'Brigade Fantome - Hip Hop & Breakdance', description: 'Crew de danse', category: 'Crew', group: 'Hip-Hop / Street / Breakdance', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd11', name: 'Puntatalon Academy - Danses Latines', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Salsa / Latine', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd12', name: 'Laliana Danse Orientale Et Armenienne', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Orientale / Traditionnelle', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd13', name: 'La Residence Des Arts', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Contemporaine', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd14', name: 'Dance Studio', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Classique / Ballet', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd15', name: 'Art Dance International', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Hip-Hop / Street / Breakdance', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd16', name: 'Three Time Dense', description: 'Ecole de danse', category: 'Ecole de danse', group: 'Contemporaine', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
    DanceVenue(id: 'd17', name: 'Cecile - Cours De Danse & Sport Sante', description: 'Danse bien-etre', category: 'Danse bien-etre', group: 'Bien-etre / Fitness', city: 'Toulouse', horaires: '', image: 'assets/images/pochette_stagedanse.png'),
  ];
}

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
