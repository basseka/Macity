import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/core/widgets/rubrique/rubrique_landing_view.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/reported_events/data/city_centers.dart';
import 'package:pulz_app/features/sport/presentation/widgets/venues_map_view.dart';

/// Carte de la section « Affinez votre recherche » (Famille, Culture, Sport).
///
/// Les marqueurs sont posés une fois à partir de [all] ; [visible] ne fait que
/// les masquer/réafficher quand le filtre change, sans recharger la webview.
/// Le cadrage est figé sur le centre de la ville sélectionnée — jamais sur la
/// position de l'utilisateur — pour que la vue ne saute pas d'un filtre à
/// l'autre. Vit ici, à côté de [VenuesMapView], plutôt que dans `core` : la
/// vue générique de rubrique ne doit pas dépendre des features.
class RefineMapSection extends ConsumerWidget {
  /// Tous les items de la section (les non géolocalisés sont ignorés).
  final List<RubriqueItem> all;

  /// Ceux que le filtre courant laisse voir.
  final List<RubriqueItem> visible;

  /// Couleur des points, en hex (ex: '#A020F0').
  final String accentColor;

  /// Titre du popup natif Leaflet (invisible quand [onVenueTap] prend la main).
  final String title;

  final double height;

  const RefineMapSection({
    super.key,
    required this.all,
    required this.visible,
    required this.accentColor,
    required this.title,
    this.height = 390,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);
    final center = CityCenters.center(city) ?? (lat: 43.6047, lng: 1.4442);
    final located = [
      for (final it in all)
        if (it.commerce != null &&
            it.commerce!.latitude != 0 &&
            it.commerce!.longitude != 0)
          it,
    ];
    if (located.isEmpty) return const SizedBox.shrink();

    // Null quand tout est visible : evite un aller-retour JS inutile.
    final visibleSet = visible.toSet();
    final indices = visibleSet.length == located.length
        ? null
        : [
            for (var i = 0; i < located.length; i++)
              if (visibleSet.contains(located[i])) i,
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: height,
          child: VenuesMapView(
            venues: [for (final it in located) it.commerce!],
            title: title,
            accentColor: accentColor,
            autoLocate: false,
            showClosestPanel: false,
            showLegend: false,
            initialZoom: 13,
            centerLat: center.lat,
            centerLng: center.lng,
            visibleIndices: indices,
            onVenueTap: (c) => CommerceRowCard.showDetailSheet(context, c),
          ),
        ),
      ),
    );
  }
}
