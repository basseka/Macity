import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/dynamic_hub_grid.dart';
import 'package:pulz_app/features/sport/state/sport_matches_provider.dart';

/// Hub grid Sport — construit dynamiquement depuis la table categories.
class SportHubGrid extends StatelessWidget {
  const SportHubGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicHubGrid(
      mode: 'sport',
      countProvider: (tag) => sportSubcategoryCountProvider(tag),
    );
  }
}
