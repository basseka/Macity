import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/evasion/data/evasion_venues_service.dart';
import 'package:pulz_app/features/evasion/domain/evasion_venue.dart';

/// Lieux d'évasion rattachés à la ville sélectionnée (colonne `hub_ville`).
/// Liste vide tant que la table est vide / la ville n'a aucune escapade, ce
/// qui masque les carrousels côté écran.
final evasionVenuesProvider =
    FutureProvider.autoDispose<List<EvasionVenue>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  try {
    return await EvasionVenuesService().fetchVenues(ville: city);
  } catch (e) {
    debugPrint('[evasionVenuesProvider] $e');
    return const <EvasionVenue>[];
  }
});
