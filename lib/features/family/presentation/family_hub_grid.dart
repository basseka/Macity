import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/dynamic_hub_grid.dart';
import 'package:pulz_app/features/family/state/family_venues_provider.dart';

/// Hub grid Famille — construit dynamiquement depuis la table categories.
class FamilyHubGrid extends StatelessWidget {
  const FamilyHubGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicHubGrid(
      mode: 'family',
      countProvider: (tag) => familyCategoryCountProvider(tag),
      avenirSubtitle: 'Sorties en famille, parcs...',
    );
  }
}
