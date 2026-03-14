import 'package:pulz_app/features/night/data/night_bars_data.dart';
import 'package:pulz_app/features/family/data/cinema_venues_data.dart';
import 'package:pulz_app/features/family/data/bowling_venues_data.dart';
import 'package:pulz_app/features/family/data/laser_game_venues_data.dart';
import 'package:pulz_app/features/family/data/escape_game_venues_data.dart';
import 'package:pulz_app/features/family/data/park_venues_data.dart';
import 'package:pulz_app/features/family/data/playground_venues_data.dart';
import 'package:pulz_app/features/family/data/family_restaurant_venues_data.dart';
import 'package:pulz_app/features/family/data/animal_park_venues_data.dart';
class LieuSuggestion {
  final String nom;
  final String adresse;

  const LieuSuggestion({required this.nom, required this.adresse});
}

/// Mapping rubrique display name → Supabase rubrique key.
const rubriqueDisplayToKey = <String, String>{
  'Nuit': 'nuit',
  'En Famille': 'famille',
  'Culture & Arts': 'culture',
  'Food & lifestyle': 'food',
};

/// Builds lieu suggestions from Supabase [CommerceModel] list.
/// Used when Supabase data is available.
List<LieuSuggestion> getLieuxFromCommerces(
  List<dynamic> commerces, {
  List<LieuSuggestion> danceVenues = const [],
}) {
  final lieux = <LieuSuggestion>[
    ...commerces.map(
      (c) => LieuSuggestion(
        nom: (c as dynamic).nom as String,
        adresse: (c as dynamic).adresse as String,
      ),
    ),
    ...danceVenues,
  ];
  return _deduplicateAndSort(lieux);
}

/// Static fallback: builds lieu suggestions from hardcoded data files.
/// Used when Supabase is unreachable.
List<LieuSuggestion> getLieuxForRubriqueStatic(String rubrique) {
  return getLieuxForRubrique(rubrique);
}

List<LieuSuggestion> getLieuxForRubrique(String rubrique, {List<LieuSuggestion> danceVenues = const []}) {
  final List<LieuSuggestion> lieux;

  switch (rubrique) {
    case 'Nuit':
      lieux = NightBarsData.toulouseBars
          .map((b) => LieuSuggestion(nom: b.nom, adresse: b.adresse))
          .toList();

    case 'En Famille':
      lieux = [
        ...CinemaVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: v.adresse)),
        ...BowlingVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: v.adresse)),
        ...LaserGameVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: v.adresse)),
        ...EscapeGameVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: v.adresse)),
        ...ParkVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.nom, adresse: v.adresse)),
        ...PlaygroundVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: v.adresse)),
        ...FamilyRestaurantVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: v.adresse)),
        ...AnimalParkVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: v.adresse)),
      ];

    case 'Culture & Arts':
      lieux = [
        ...danceVenues,
      ];

    case 'Food & lifestyle':
      lieux = [];

    default:
      return [];
  }

  return _deduplicateAndSort(lieux);
}

List<LieuSuggestion> _deduplicateAndSort(List<LieuSuggestion> lieux) {
  final seen = <String>{};
  final deduped = <LieuSuggestion>[];
  for (final lieu in lieux) {
    if (seen.add(lieu.nom)) {
      deduped.add(lieu);
    }
  }
  deduped.sort((a, b) => a.nom.compareTo(b.nom));
  return deduped;
}
