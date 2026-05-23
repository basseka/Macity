import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';

/// Ouvre la fiche detail d'un restaurant.
///
/// Depuis le refactor d'unification, un restaurant ouvre le MEME ecran de
/// detail que les boites de nuit / commerces : on convertit le
/// [RestaurantVenue] en [CommerceModel] et on delegue a
/// [CommerceRowCard.showDetailSheet].
///
/// La signature publique `RestaurantDetailSheet.show(context, venue,
/// {placeholderAsset})` reste inchangee pour ne pas toucher les appelants.
class RestaurantDetailSheet {
  RestaurantDetailSheet._();

  static void show(
    BuildContext context,
    RestaurantVenue venue, {
    String placeholderAsset = 'assets/images/pochette_restaurant.jpg',
    List<RestaurantVenue>? siblings,
    int? index,
  }) {
    final commerce = toCommerce(venue);

    // imageAsset : on ne passe un asset local que si la photo principale du
    // venue est un asset (pas une URL http). Sinon null -> CommerceRowCard
    // resout l'image (photo http ou fallback categorie).
    final hasLocalAsset =
        venue.photo.isNotEmpty && !venue.photo.startsWith('http');

    // Si une liste de siblings est fournie, on ouvre un pager swipable sur
    // tous les restaurants (meme detail unifie pour chacun).
    final commerceSiblings = siblings?.map(toCommerce).toList();
    CommerceRowCard.openDetail(
      context,
      commerce,
      imageAsset: hasLocalAsset ? venue.photo : null,
      siblings: commerceSiblings,
      index: index,
    );
  }

  /// Convertit un [RestaurantVenue] (modele rubrique Food) vers le
  /// [CommerceModel] generique attendu par le detail unifie. Public pour que
  /// les parents qui construisent un `pagerSiblings` n'aient pas a redupliquer.
  static CommerceModel toCommerce(RestaurantVenue venue) {
    // categorie : on privilegie le theme (ex: "Asiatique"), sinon le group.
    final categorie = venue.theme.isNotEmpty ? venue.theme : venue.group;

    // sourceId / sourceTable : si l'id du venue est un entier exploitable,
    // on le branche sur la table `etablissements` pour que les avis marchent.
    final venueIdInt = int.tryParse(venue.id);
    final hasNumericId = venueIdInt != null && venueIdInt > 0;

    return CommerceModel(
      nom: venue.name,
      adresse: venue.adresse,
      ville: venue.quartier,
      latitude: venue.latitude,
      longitude: venue.longitude,
      horaires: venue.horaires,
      categorie: categorie,
      lienMaps: venue.lienMaps,
      telephone: venue.telephone,
      photo: venue.photo,
      siteWeb: venue.websiteUrl,
      isVerified: venue.isVerified,
      // On force food.mp4 pour les fiches non revendiquees : les categories
      // food (Asiatique, Brunch, Guinguette…) sont trop variees pour etre
      // matchees fiablement par mots-cles dans _defaultVideoUrlFor.
      videoUrl: venue.isVerified ? '' : CommerceRowCard.defaultFoodVideo,
      sourceId: hasNumericId ? venueIdInt : null,
      sourceTable: hasNumericId ? 'etablissements' : null,
      description: venue.description,
      photos: venue.photos,
    );
  }
}
