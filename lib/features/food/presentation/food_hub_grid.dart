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
      fallbackImageProvider: _fallbackImageFor,
      avenirSubtitle: 'Selection editorialisee — restaurants, brunchs, bars.',
    );
  }

  /// Pochette locale si la categorie n'a pas d'image_url en BDD.
  static String? _fallbackImageFor(String tag) {
    switch (tag) {
      case 'Guinguette':
        return 'assets/images/pochette_guinguette.webp';
      case 'Buffets':
        return 'assets/images/pochette_buffet.webp';
      case 'Spa hammam':
      case 'Massage':
        return 'assets/images/pochette_spa&hammam.webp';
      case 'Salon de the':
        return 'assets/images/pochette_salondethe.jpg';
      case 'Brunch':
        return 'assets/images/pochette_brunch.jpg';
      case 'Yoga meditation':
        return 'assets/images/pochette_yoga.jpg';
      default:
        return null;
    }
  }
}
