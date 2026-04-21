import 'package:flutter/material.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';

/// Ouvre le bottom sheet detail d'un restaurant. Reutilisable depuis la liste
/// ou la carte (tap sur un marqueur).
class RestaurantDetailSheet {
  RestaurantDetailSheet._();

  static const _defaultRestaurantPhotos = [
    'assets/images/plat-01.png',
    'assets/images/plat-02.png',
    'assets/images/plat-03.png',
    'assets/images/plat-04.png',
    'assets/images/plat-05.png',
    'assets/images/plat-06.png',
  ];

  static void show(
    BuildContext context,
    RestaurantVenue venue, {
    String placeholderAsset = 'assets/images/pochette_restaurant.jpg',
  }) {
    final photos = <String>[];
    if (venue.photo.isNotEmpty && venue.photo.startsWith('http')) {
      photos.add(venue.photo);
    }
    for (final p in _defaultRestaurantPhotos) {
      if (photos.length >= 6) break;
      if (!photos.contains(p)) photos.add(p);
    }

    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: venue.name,
        emoji: '',
        imageAsset: venue.photo.isNotEmpty && !venue.photo.startsWith('http')
            ? venue.photo
            : placeholderAsset,
        imageUrl: venue.photo.isNotEmpty && venue.photo.startsWith('http')
            ? venue.photo
            : null,
        photoGallery: photos,
        infos: [
          if (venue.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, venue.description),
          if (venue.theme.isNotEmpty)
            DetailInfoItem(Icons.restaurant_menu, 'Theme: ${venue.theme}'),
          if (venue.style.isNotEmpty)
            DetailInfoItem(Icons.style, 'Style: ${venue.style}'),
          if (venue.quartier.isNotEmpty)
            DetailInfoItem(Icons.location_city, 'Quartier: ${venue.quartier}'),
          if (venue.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, venue.horaires),
          if (venue.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, venue.adresse),
          if (venue.telephone.isNotEmpty)
            DetailInfoItem(Icons.phone_outlined, venue.telephone),
        ],
        primaryAction: venue.websiteUrl.isNotEmpty
            ? DetailAction(
                icon: Icons.language,
                label: 'Site web',
                url: venue.websiteUrl,
              )
            : null,
        secondaryActions: [
          if (venue.lienMaps.isNotEmpty)
            DetailAction(
              icon: Icons.map_outlined,
              label: 'Maps',
              url: venue.lienMaps,
            ),
          if (venue.telephone.isNotEmpty)
            DetailAction(
              icon: Icons.phone_outlined,
              label: 'Appeler',
              url: 'tel:${venue.telephone.replaceAll(' ', '')}',
            ),
        ],
        shareText:
            '${venue.name}\n${venue.adresse}\n${venue.telephone.isNotEmpty ? '${venue.telephone}\n' : ''}${venue.websiteUrl}\n\nDecouvre sur MaCity',
      ),
    );
  }
}
