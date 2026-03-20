import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/dynamic_hub_grid.dart';
import 'package:pulz_app/features/culture/state/culture_venues_provider.dart';

/// Hub grid Culture — construit dynamiquement depuis la table categories.
class CultureHubGrid extends StatelessWidget {
  const CultureHubGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicHubGrid(
      mode: 'culture',
      countProvider: (tag) => cultureCategoryCountProvider(tag),
      avenirSubtitle: 'Spectacles, expos, visites...',
    );
  }
}
