import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/theme/mode_theme.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/loading_indicator.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
import 'package:pulz_app/features/food/presentation/restaurant_detail_sheet.dart';
import 'package:pulz_app/features/food/state/food_venues_provider.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';
import 'package:pulz_app/features/sport/presentation/widgets/venues_map_view.dart';

/// Carte plein ecran affichant tous les restaurants de la ville courante.
/// Tap sur un pin -> fiche detail restaurant.
class FoodRestaurantsFullscreenMap extends ConsumerWidget {
  const FoodRestaurantsFullscreenMap({super.key});

  static const mapTag = 'Restaurant carte';
  static const _backTag = 'Restaurant';

  static bool isMapTag(String? tag) => tag == mapTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final restaurantsAsync = ref.watch(restaurantsSupabaseProvider);

    return restaurantsAsync.when(
      data: (restaurants) {
        // Garde seulement ceux avec des coords valides et cree un index nom -> venue
        final valid = restaurants
            .where((r) => r.latitude != 0 && r.longitude != 0)
            .toList();
        final byKey = <String, RestaurantVenue>{
          for (final r in valid) _venueKey(r): r
        };
        final commerceList = valid.map(_toCommerce).toList();

        return Stack(
          children: [
            VenuesMapView(
              venues: commerceList,
              title: 'Restaurant le plus proche',
              accentColor: '#F97316',
              categoryColors: const {'Restaurant': '#F97316'},
              showLabels: true,
              showClosestPanel: false,
              onVenueTap: (c) {
                final v = byKey[_commerceKey(c)];
                if (v != null) {
                  RestaurantDetailSheet.show(context, v);
                }
              },
            ),
            _buildListButton(ref, modeTheme),
          ],
        );
      },
      loading: () => Stack(
        children: [
          LoadingIndicator(color: modeTheme.primaryColor),
          _buildListButton(ref, modeTheme),
        ],
      ),
      error: (_, __) => Stack(
        children: [
          const Center(child: Text('Erreur de chargement')),
          _buildListButton(ref, modeTheme),
        ],
      ),
    );
  }

  /// Cle unique par restaurant pour retrouver l'original apres passage par
  /// le pont CommerceModel. Base sur (nom + lat + lng) arrondis.
  static String _venueKey(RestaurantVenue v) =>
      '${v.name.toLowerCase()}|${v.latitude.toStringAsFixed(5)}|${v.longitude.toStringAsFixed(5)}';

  static String _commerceKey(CommerceModel c) =>
      '${c.nom.toLowerCase()}|${c.latitude.toStringAsFixed(5)}|${c.longitude.toStringAsFixed(5)}';

  /// Adapte un RestaurantVenue au modele CommerceModel consomme par la map.
  static CommerceModel _toCommerce(RestaurantVenue v) => CommerceModel(
        nom: v.name,
        adresse: v.adresse,
        latitude: v.latitude,
        longitude: v.longitude,
        horaires: v.horaires,
        categorie: 'Restaurant',
        lienMaps: v.lienMaps,
        telephone: v.telephone,
        photo: v.photo,
        siteWeb: v.websiteUrl,
        isVerified: v.isVerified,
      );

  Widget _buildListButton(WidgetRef ref, ModeTheme modeTheme) {
    return Positioned(
      top: 8,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref
              .read(modeSubcategoriesProvider.notifier)
              .select('food', _backTag),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [modeTheme.primaryColor, modeTheme.primaryDarkColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: modeTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list, size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'Liste',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
