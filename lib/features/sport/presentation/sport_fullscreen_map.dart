import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/presentation/widgets/venues_map_view.dart';
import 'package:pulz_app/features/sport/state/sport_venues_provider.dart';

/// Carte plein ecran pour les venues sport.
class SportFullscreenMap extends ConsumerWidget {
  final String mapTag;

  const SportFullscreenMap({super.key, required this.mapTag});

  static const _mapTags = <String, String>{
    'Golf carte': 'Golf',
    'Fitness carte': 'Salle de fitness',
    'Boxe salles carte': 'Salles de boxe',
    'Football carte': 'Terrain de football',
    'Basketball carte': 'Terrain de basketball',
    'Piscine carte': 'Piscine',
    'Raquette carte': 'Raquette',
    'Tennis carte': 'Tennis',
    'Padel carte': 'Padel',
    'Squash carte': 'Squash',
    'Ping-pong carte': 'Ping-pong',
    'Badminton carte': 'Badminton',
    'Danse carte': 'Danse',
  };

  static bool isMapTag(String? tag) => tag != null && _mapTags.containsKey(tag);
  static String backTarget(String tag) => _mapTags[tag]!;

  static const _mapTagToSportType = <String, String>{
    'Golf carte': 'golf',
    'Fitness carte': 'fitness',
    'Boxe salles carte': 'boxe',
    'Football carte': 'terrain-football',
    'Basketball carte': 'terrain-basketball',
    'Piscine carte': 'piscine',
    'Tennis carte': 'tennis',
    'Padel carte': 'padel',
    'Squash carte': 'squash',
    'Ping-pong carte': 'ping-pong',
    'Badminton carte': 'badminton',
    'Danse carte': 'danse',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final backTo = _mapTags[mapTag]!;

    final AsyncValue<List<CommerceModel>> venuesAsync;
    if (mapTag == 'Raquette carte') {
      venuesAsync = ref.watch(racketAllVenuesProvider);
    } else {
      final sportType = _mapTagToSportType[mapTag];
      venuesAsync = sportType != null
          ? ref.watch(sportVenuesProvider(sportType))
          : const AsyncValue.data([]);
    }

    final title = switch (mapTag) {
      'Golf carte' => 'Golf le plus proche',
      'Fitness carte' => 'Salle la plus proche',
      'Boxe salles carte' => 'Salle la plus proche',
      'Football carte' => 'Terrain le plus proche',
      'Basketball carte' => 'Terrain le plus proche',
      'Piscine carte' => 'Piscine la plus proche',
      'Raquette carte' => 'Club le plus proche',
      'Tennis carte' => 'Club de tennis le plus proche',
      'Padel carte' => 'Club de padel le plus proche',
      'Squash carte' => 'Salle de squash la plus proche',
      'Ping-pong carte' => 'Club de ping-pong le plus proche',
      'Badminton carte' => 'Club de badminton le plus proche',
      'Danse carte' => 'Salle de danse la plus proche',
      _ => 'Le plus proche',
    };

    final color = switch (mapTag) {
      'Golf carte' => '#228B22',
      'Fitness carte' => '#E53935',
      'Boxe salles carte' => '#D84315',
      'Football carte' => '#4CAF50',
      'Basketball carte' => '#FF9800',
      'Piscine carte' => '#0288D1',
      'Raquette carte' => '#1565C0',
      'Tennis carte' => '#1565C0',
      'Padel carte' => '#1565C0',
      'Squash carte' => '#1565C0',
      'Ping-pong carte' => '#1565C0',
      'Badminton carte' => '#1565C0',
      'Danse carte' => '#E91E63',
      _ => '#228B22',
    };

    return venuesAsync.when(
      data: (venues) => Stack(
        children: [
          VenuesMapView(venues: venues, title: title, accentColor: color),
          _buildListButton(ref, modeTheme, backTo),
        ],
      ),
      loading: () => Stack(
        children: [
          LoadingIndicator(color: modeTheme.primaryColor),
          _buildListButton(ref, modeTheme, backTo),
        ],
      ),
      error: (_, __) => Stack(
        children: [
          const Center(child: Text('Erreur de chargement')),
          _buildListButton(ref, modeTheme, backTo),
        ],
      ),
    );
  }

  Widget _buildListButton(WidgetRef ref, ModeTheme modeTheme, String backTo) {
    return Positioned(
      top: 8,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(modeSubcategoriesProvider.notifier).select('sport', backTo),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: modeTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list, size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text('Liste', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
