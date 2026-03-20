import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/dynamic_hub_grid.dart';

/// Hub grid Tourisme — construit dynamiquement depuis la table categories.
class TourismeHubGrid extends StatelessWidget {
  const TourismeHubGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicHubGrid(
      mode: 'tourisme',
      cardWidth: 160,
    );
  }
}
