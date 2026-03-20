import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/dynamic_hub_grid.dart';
import 'package:pulz_app/features/food/state/food_venues_provider.dart';

/// Hub grid Food — construit dynamiquement depuis la table categories.
class FoodHubGrid extends StatelessWidget {
  const FoodHubGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicHubGrid(
      mode: 'food',
      countProvider: (tag) => foodCategoryCountProvider(tag),
      avenirSubtitle: 'Restaurants, brunchs, bien-etre...',
    );
  }
}
