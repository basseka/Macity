import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/dynamic_hub_grid.dart';
import 'package:pulz_app/features/night/state/night_venues_provider.dart';

/// Hub grid Nuit — construit dynamiquement depuis la table categories.
class NightHubGrid extends StatelessWidget {
  const NightHubGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicHubGrid(
      mode: 'night',
      countProvider: (tag) => nightCategoryCountProvider(tag),
      avenirSubtitle: 'Soirees, events nocturnes...',
    );
  }
}
