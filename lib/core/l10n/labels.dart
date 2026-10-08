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
