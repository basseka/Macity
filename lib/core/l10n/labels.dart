import 'package:flutter/widgets.dart';
import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';

// Libelles affiches dont la valeur francaise sert AUSSI de cle dans le code
// (filtres, switch, valeurs en base). On garde la cle francaise pour la
// logique et on ne traduit qu'a l'affichage, via ces fonctions.

/// Code de langue pour DateFormat ('fr', 'en', 'es').
extension DateLocaleX on BuildContext {
  String get dateLocale => Localizations.localeOf(this).languageCode;
}

/// Rubrique a partir de son code DB ('food', 'family', 'tourisme'...).
String rubriqueLabel(BuildContext context, String mode) {
  final l10n = context.l10n;
  return switch (mode) {
    'food' => l10n.rubriqueFood,
    'culture' => l10n.rubriqueCulture,
    'family' => l10n.rubriqueFamily,
    'night' => l10n.rubriqueNight,
    'sport' => l10n.rubriqueSport,
    'tourisme' => l10n.rubriqueEvasion,
    _ => mode,
  };
}

/// Chips de categorie du feed (cles : 'Tout', 'Concerts', 'Soirée'...).
String feedCategoryLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'Tout' => l10n.catAll,
    'Concerts' => l10n.catConcerts,
    'Soirée' => l10n.catParty,
    'Spectacle' => l10n.catShow,
    'Danse' => l10n.catDance,
    'Cinéma' => l10n.catCinema,
    'Food' => l10n.rubriqueFood,
    'Sport' => l10n.rubriqueSport,
    'Famille' => l10n.rubriqueFamily,
    _ => key,
  };
}

/// Nom long d'un mode (equivalent traduit de [AppMode.label]).
String modeLabel(BuildContext context, AppMode mode) {
  final l10n = context.l10n;
  return switch (mode) {
    AppMode.day => l10n.modeDay,
    AppMode.sport => l10n.modeSport,
    AppMode.culture => l10n.modeCulture,
    AppMode.family => l10n.modeFamily,
    AppMode.food => l10n.modeFood,
    AppMode.gaming => l10n.modeGaming,
    AppMode.night => l10n.modeNight,
    AppMode.tourisme => l10n.modeTourisme,
  };
}

/// Libelle court d'un mode (equivalent traduit de [AppMode.shortLabel]).
String modeShortLabel(BuildContext context, AppMode mode) {
  final l10n = context.l10n;
  return switch (mode) {
    AppMode.day => l10n.modeShortDay,
    AppMode.sport => l10n.rubriqueSport,
    AppMode.culture => l10n.rubriqueCulture,
    AppMode.family => l10n.rubriqueFamily,
    AppMode.food => l10n.rubriqueFood,
    AppMode.gaming => l10n.modeShortGaming,
    AppMode.night => l10n.modeShortNight,
    AppMode.tourisme => l10n.modeShortTourisme,
  };
}

/// Sections de la page "Quoi faire ce soir" (cles : 'Concerts', 'Soirées'...).
String nightSectionLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'Concerts' => l10n.tonightSectionConcerts,
    'Soirées' => l10n.tonightSectionParties,
    'Spectacles' => l10n.tonightSectionShows,
    'Autres sorties' => l10n.tonightSectionOther,
    'Cinéma' => l10n.catCinema,
    _ => key,
  };
}

/// Sous-rubriques Culture (cles searchTag : 'Musee', 'Theatre', 'A venir'...).
String cultureCategoryLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'Musee' => l10n.cultureCatMuseum,
    'Cinema' => l10n.catCinema,
    'Theatre' => l10n.cultureCatTheatre,
    'Danse' => l10n.catDance,
    "Galerie d'art" || 'Galerie' => l10n.cultureCatGallery,
    'Monument historique' => l10n.cultureCatMonument,
    'Bibliotheque' => l10n.cultureCatLibrary,
    'Visites guidees' => l10n.cultureCatGuidedTours,
    'Exposition' => l10n.cultureCatExhibition,
    'A venir' => l10n.cultureCatUpcoming,
    _ => key,
  };
}

/// Sous-rubriques Night (cles categorie : 'Club Discotheque', 'Bar a chicha'...).
String nightCategoryLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'Club Discotheque' => l10n.nightCatClub,
    'Bar de nuit' => l10n.nightCatNightBar,
    'Bar a cocktails' => l10n.nightCatCocktails,
    'Bar a chicha' => l10n.nightCatShisha,
    'Pub' => l10n.nightCatPub,
    'A venir' => l10n.cultureCatUpcoming,
    _ => key,
  };
}

/// Sous-rubriques Sport (cles : 'Salle de fitness', 'Courses a pied'...).
String sportCategoryLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'Sport' => l10n.rubriqueSport,
    'Matchs' => l10n.sportCatMatches,
    'Events' => l10n.sportCatEvents,
    'Complexe sportif' => l10n.sportCatComplex,
    'Marathon' => l10n.sportCatMarathon,
    'Raquette' => l10n.sportCatRacket,
    'Boxe' => l10n.sportCatBoxing,
    'Natation' => l10n.sportCatSwimming,
    'Courses a pied' => l10n.sportCatRunning,
    'Competition' => l10n.sportCatCompetition,
    'Stage de danse' => l10n.sportCatDanceWorkshop,
    'Danse' => l10n.catDance,
    'Salle de fitness' => l10n.sportCatGym,
    'Salles de boxe' => l10n.sportCatBoxingGym,
    'Terrain de football' => l10n.sportCatFootballPitch,
    'Terrain de basketball' => l10n.sportCatBasketCourt,
    'Piscine' => l10n.sportCatPool,
    'Padel' => l10n.sportCatPadel,
    'Ping-pong' => l10n.sportCatTableTennis,
    'Badminton' => l10n.sportCatBadminton,
    'Football' => l10n.sportCatFootball,
    'Basketball' => l10n.sportCatBasketball,
    'Handball' => l10n.sportCatHandball,
    'Gala / Matchs' => l10n.sportCatGala,
    'JO 2028' => l10n.sportCatOlympics,
    'A venir' => l10n.cultureCatUpcoming,
    _ => key,
  };
}

/// Groupes et sous-rubriques Famille (cles : nom de groupe ou searchTag).
String familyCategoryLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'Famille' => l10n.rubriqueFamily,
    'A venir' => l10n.cultureCatUpcoming,
    'Divertissements' => l10n.familyGroupEntertainment,
    "Jeux d'enfants" => l10n.familyGroupKidsPlay,
    'Animaux et Nature' => l10n.familyGroupAnimals,
    'Activite Aquatique' => l10n.familyGroupWater,
    'Sortie en Plein Air' => l10n.familyGroupOutdoor,
    'Decouvrir' => l10n.familyGroupDiscover,
    "Parc d'attractions" => l10n.familyCatThemePark,
    'Laser game' => l10n.familyCatLaserGame,
    'Escape game' => l10n.familyCatEscapeGame,
    'Bowling' => l10n.familyCatBowling,
    'Cinema' || 'Cinéma' => l10n.catCinema,
    'Patinoire' => l10n.familyCatIceRink,
    'Aire de jeux' => l10n.familyCatPlayground,
    'Parc de loisirs' => l10n.familyCatLeisurePark,
    'Parc animalier' => l10n.familyCatWildlifePark,
    'Ferme pedagogique' || 'Ferme pédagogique' => l10n.familyCatFarm,
    'Aquarium' => l10n.familyCatAquarium,
    'Zoo' => l10n.familyCatZoo,
    'Jardin botanique' => l10n.familyCatBotanicGarden,
    'Centre aquatique' => l10n.familyCatWaterPark,
    'Piscine' => l10n.sportCatPool,
    'Parcs' => l10n.familyCatParks,
    'Balade familiale' => l10n.familyCatWalks,
    'Accrobranche' => l10n.familyCatTreetop,
    'Mini golf' => l10n.familyCatMiniGolf,
    'Base de loisirs' => l10n.familyCatLeisureBase,
    'Musee pour enfants' => l10n.familyCatKidsMuseum,
    'Planetarium' => l10n.familyCatPlanetarium,
    'Atelier creatif' => l10n.familyCatWorkshop,
    'Restaurant familial' => l10n.familyCatRestaurant,
    _ => key,
  };
}

/// Categories Tourisme (cles : categorie des points touristiques en base).
String tourismeCategoryLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'Tourisme' => l10n.tourismeTitle,
    'Visiter' => l10n.tourismeVisit,
    'Se deplacer' => l10n.tourismeGetAround,
    'Categories' => l10n.commonCategories,
    'Monument' => l10n.tourismeCatMonument,
    'Musee' => l10n.tourismeCatMuseum,
    'Attraction' => l10n.tourismeCatAttraction,
    'Site naturel' => l10n.tourismeCatNature,
    'Place' => l10n.tourismeCatSquare,
    'Lieu culturel' => l10n.tourismeCatCultural,
    'Office de tourisme' => l10n.tourismeCatTouristOffice,
    'Quartier' => l10n.tourismeCatDistrict,
    _ => key,
  };
}

/// Libelles d'actions et de badges passes en francais aux fiches detail
/// (ItemDetailSheet, popups) : 'Site web', 'Maps', 'Appeler'...
String actionLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'Site web' => l10n.websiteLabel,
    'Appeler' => l10n.commonCall,
    'Partager' => l10n.commonShare,
    'Billetterie' => l10n.ticketsLabel,
    'Billets' => l10n.ticketsShort,
    'Itineraire' || 'Itinéraire' => l10n.mapDirections,
    'Partenaire' => l10n.detailPartner,
    'Domaine partenaire' => l10n.detailPartnerEstate,
    'En savoir plus' => l10n.commonLearnMore,
    _ => key,
  };
}
