import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/dynamic_hub_grid.dart';
import 'package:pulz_app/features/gaming/state/gaming_venues_provider.dart';

/// Hub grid Gaming — construit dynamiquement depuis la table categories.
class GamingHubGrid extends StatelessWidget {
  const GamingHubGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicHubGrid(
      mode: 'gaming',
      countProvider: (tag) => gamingCategoryCountProvider(tag),
      avenirSubtitle: 'Tournois, conventions, events...',
    );
  }
}
