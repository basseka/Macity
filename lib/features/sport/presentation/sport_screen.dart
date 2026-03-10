import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/presentation/boxe_events_grid.dart';
import 'package:pulz_app/features/sport/presentation/complexe_sportif_hub.dart';
import 'package:pulz_app/features/sport/presentation/dance_venues_list.dart';
import 'package:pulz_app/features/sport/presentation/marathon_hub.dart';
import 'package:pulz_app/features/sport/presentation/marathon_race_info.dart';
import 'package:pulz_app/features/sport/presentation/match_events_hub.dart';
import 'package:pulz_app/features/sport/presentation/raquette_hub.dart';
import 'package:pulz_app/features/sport/presentation/sport_fullscreen_map.dart';
import 'package:pulz_app/features/sport/presentation/sport_hub_grid.dart';
import 'package:pulz_app/features/sport/presentation/sport_matches_list.dart';
import 'package:pulz_app/features/sport/presentation/sport_venues_list.dart';

class SportScreen extends ConsumerWidget {
  const SportScreen({super.key});

  // Sous-categories qui ont un bouton Carte
  static const _venueMapTags = <String, String>{
    'Golf': 'Golf carte',
    'Salle de fitness': 'Fitness carte',
    'Salles de boxe': 'Boxe salles carte',
    'Terrain de football': 'Football carte',
    'Terrain de basketball': 'Basketball carte',
    'Piscine': 'Piscine carte',
    'Tennis': 'Tennis carte',
    'Padel': 'Padel carte',
    'Squash': 'Squash carte',
    'Ping-pong': 'Ping-pong carte',
    'Badminton': 'Badminton carte',
  };

  // Map searchTag → sport_type pour les sous-types raquette
  static const _raquetteTagToSportType = <String, String>{
    'Tennis': 'tennis',
    'Padel': 'padel',
    'Squash': 'squash',
    'Ping-pong': 'ping-pong',
    'Badminton': 'badminton',
  };

  // Tags des courses marathon
  static const _marathonChildren = {
    'Marathon info', 'Semi-Marathon info', '10K info',
    'Marathon relais info', 'Course Enfants info',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(sportSubcategoryProvider);

    // Cartes plein ecran (sans barre titre)
    if (SportFullscreenMap.isMapTag(sub)) {
      return SportFullscreenMap(mapTag: sub!);
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(child: _resolve(sub)),
      ],
    );
  }

  Widget _resolve(String? sub) {
    if (sub == null) return const SportHubGrid();

    return switch (sub) {
      'Matchs' => const MatchEventsHub(hubType: MatchHubType.matchs),
      'Events' => const MatchEventsHub(hubType: MatchHubType.events),
      'Complexe sportif' => const ComplexeSportifHub(),
      'Marathon' => const MarathonHub(),
      'Raquette' => const RaquetteHub(),
      'Boxe' => const BoxeEventsGrid(),
      'Danse' => const DanceVenuesList(),
      // Venues avec sport_type direct
      'Salle de fitness' => SportVenuesList(sportType: 'fitness', displayTitle: 'Salle de fitness', mapTag: _venueMapTags['Salle de fitness']),
      'Salles de boxe' => SportVenuesList(sportType: 'boxe', displayTitle: 'Salles de boxe', mapTag: _venueMapTags['Salles de boxe']),
      'Terrain de football' => SportVenuesList(sportType: 'terrain-football', displayTitle: 'Terrain de football', mapTag: _venueMapTags['Terrain de football']),
      'Terrain de basketball' => SportVenuesList(sportType: 'terrain-basketball', displayTitle: 'Terrain de basketball', mapTag: _venueMapTags['Terrain de basketball']),
      'Piscine' => SportVenuesList(sportType: 'piscine', displayTitle: 'Piscine', mapTag: _venueMapTags['Piscine']),
      'Golf' => SportVenuesList(sportType: 'golf', displayTitle: 'Golf', mapTag: _venueMapTags['Golf'], backLabel: 'Events', backTarget: 'Events'),
      // Sous-types raquette
      'Tennis' || 'Padel' || 'Squash' || 'Ping-pong' || 'Badminton' =>
        _buildRaquetteVenues(sub),
      // Marathon race info
      _ when _marathonChildren.contains(sub) => MarathonRaceInfo(subcategory: sub),
      // Matchs (Rugby, Football, Basketball, etc.)
      _ => SportMatchesList(subcategory: sub),
    };
  }

  Widget _buildRaquetteVenues(String tag) {
    final sportType = _raquetteTagToSportType[tag] ?? tag.toLowerCase();
    return SportVenuesList(
      sportType: sportType,
      displayTitle: tag,
      mapTag: _venueMapTags[tag],
      backLabel: 'Raquette',
      backTarget: 'Raquette',
    );
  }
}
