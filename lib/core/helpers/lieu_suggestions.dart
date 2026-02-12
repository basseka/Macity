import 'package:pulz_app/features/night/data/night_bars_data.dart';
import 'package:pulz_app/features/family/data/cinema_venues_data.dart';
import 'package:pulz_app/features/family/data/bowling_venues_data.dart';
import 'package:pulz_app/features/family/data/laser_game_venues_data.dart';
import 'package:pulz_app/features/family/data/escape_game_venues_data.dart';
import 'package:pulz_app/features/family/data/park_venues_data.dart';
import 'package:pulz_app/features/family/data/playground_venues_data.dart';
import 'package:pulz_app/features/family/data/family_restaurant_venues_data.dart';
import 'package:pulz_app/features/family/data/animal_park_venues_data.dart';
import 'package:pulz_app/features/culture/data/museum_venues_data.dart';
import 'package:pulz_app/features/culture/data/theatre_venues_data.dart';
import 'package:pulz_app/features/culture/data/dance_venues_data.dart';
import 'package:pulz_app/features/culture/data/gallery_venues_data.dart';
import 'package:pulz_app/features/culture/data/monument_venues_data.dart';
import 'package:pulz_app/features/culture/data/library_venues_data.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';

class LieuSuggestion {
  final String nom;
  final String adresse;

  const LieuSuggestion({required this.nom, required this.adresse});
}

List<LieuSuggestion> getLieuxForRubrique(String rubrique) {
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
        ...MuseumVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: '')),
        ...TheatreVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: '')),
        ...DanceVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: '')),
        ...GalleryVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.nom, adresse: v.adresse)),
        ...MonumentVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: v.adresse)),
        ...LibraryVenuesData.venues
            .map((v) => LieuSuggestion(nom: v.name, adresse: v.adresse)),
      ];

    case 'Food & lifestyle':
      lieux = RestaurantVenuesData.venues
          .map((v) => LieuSuggestion(nom: v.name, adresse: v.adresse))
          .toList();

    default:
      return [];
  }

  // Deduplicate by name and sort alphabetically
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
