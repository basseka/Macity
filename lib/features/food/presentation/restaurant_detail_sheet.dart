import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/food/data/restaurant_reservation_service.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
import 'package:pulz_app/features/food/presentation/reservation_form_sheet.dart';
import 'package:pulz_app/features/food/state/restaurant_reservation_provider.dart';

/// Ouvre la fiche detail d'un restaurant.
///
/// Layout :
///   [photo] [titre]
///   [badge reservation active (si l'user en a)]
///   [infos]
///   [Reserver une table]   <- gros bouton, grise si pas de claim resto
///   [Site web]              <- gros bouton outlined, en dessous
///   [♡ Aimer] [↗ Partager] [📞 Appeler]   <- 3 pills sur une ligne
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
    // Galerie : pochette + photos enregistrées (galerie admin.html). Les
    // visuels génériques de plats ne servent que de repli quand le restaurant
    // n'a aucune photo réelle.
    final photos = <String>[];
    if (venue.photo.isNotEmpty && venue.photo.startsWith('http')) {
      photos.add(venue.photo);
    }
    for (final p in venue.photos) {
      if (p.isNotEmpty && !photos.contains(p)) photos.add(p);
    }
    if (photos.isEmpty) {
      photos.addAll(_defaultRestaurantPhotos);
    }

    final venueIdInt = int.tryParse(venue.id) ?? 0;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _RestaurantDetailWrapper(
        venue: venue,
        venueIdInt: venueIdInt,
        photos: photos,
        placeholderAsset: placeholderAsset,
      ),
    );
  }
}

/// Wrapper Consumer pour resoudre canReserveProvider avant de construire
/// l'ItemDetailSheet. On a besoin de savoir si on doit griser le CTA.
class _RestaurantDetailWrapper extends ConsumerWidget {
  final RestaurantVenue venue;
  final int venueIdInt;
  final List<String> photos;
  final String placeholderAsset;

  const _RestaurantDetailWrapper({
    required this.venue,
    required this.venueIdInt,
    required this.photos,
    required this.placeholderAsset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReserveAsync = venueIdInt > 0
        ? ref.watch(canReserveProvider(venueIdInt))
        : const AsyncValue.data(false);

    // Loading state : on suppose "true" (bouton actif) le temps du fetch
    // pour eviter un flash visuel. canReserveAsync remplace le state au resultat.
    final canReserve = canReserveAsync.maybeWhen(
      data: (b) => b,
      orElse: () => true,
    );

    return ItemDetailSheet(
      title: venue.name,
      emoji: '',
      imageAsset: venue.photo.isNotEmpty && !venue.photo.startsWith('http')
          ? venue.photo
          : placeholderAsset,
      imageUrl: venue.photo.isNotEmpty && venue.photo.startsWith('http')
          ? venue.photo
          : null,
      photoGallery: photos,
      likeId: 'restaurant_${venue.id}',
      shareText:
          '${venue.name}\n${venue.adresse}\n${venue.telephone.isNotEmpty ? '${venue.telephone}\n' : ''}${venue.websiteUrl}\n\nDecouvre sur MaCity',
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
      // Badge des reservations actives juste sous les infos (au-dessus du CTA).
      extraContent: venueIdInt > 0
          ? _ReservationBadges(venueId: venueIdInt)
          : null,
      // CTA principal "Reserver une table" : grise si le resto n'a pas
      // de claim approuve (no email -> submit echouerait de toute facon).
      primaryAction: DetailAction(
        icon: Icons.event_available,
        label: canReserve ? 'Réserver une table' : 'Réservation indisponible',
        disabled: !canReserve || venueIdInt <= 0,
        onTap: () => ReservationFormSheet.show(
          context,
          venueId: venueIdInt,
          venueName: venue.name,
        ),
      ),
      // Site web : juste sous le CTA, en outlined (gros bouton secondaire).
      secondaryButton: venue.websiteUrl.isNotEmpty
          ? DetailAction(
              icon: Icons.language,
              label: 'Site web',
              url: venue.websiteUrl,
            )
          : null,
      // 3 pills sur une ligne : Aimer (via likeId) + Partager (via shareText)
      // + Appeler. Pas de Maps en pill — l'address row reste cliquable.
      secondaryActions: [
        if (venue.telephone.isNotEmpty)
          DetailAction(
            icon: Icons.phone_outlined,
            label: 'Appeler',
            url: 'tel:${venue.telephone.replaceAll(' ', '')}',
          ),
        if (venue.lienMaps.isNotEmpty)
          DetailAction(
            icon: Icons.map_outlined,
            label: 'Maps',
            url: venue.lienMaps,
          ),
      ],
    );
  }
}

/// Badge affiche en haut de la fiche resto si l'user a des reservations
/// actives (pending ou accepted, < 2h apres l'heure de reservation).
class _ReservationBadges extends ConsumerWidget {
  final int venueId;
  const _ReservationBadges({required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeReservationsProvider(venueId));
    return async.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:
                list.map((r) => _ReservationBadge(reservation: r)).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ReservationBadge extends StatelessWidget {
  final RestaurantReservation reservation;
  const _ReservationBadge({required this.reservation});

  static const _accepted = Color(0xFF22C55E);
  static const _pending = Color(0xFFFB923C);

  @override
  Widget build(BuildContext context) {
    final isAccepted = reservation.isAccepted;
    final color = isAccepted ? _accepted : _pending;
    final dateFr =
        DateFormat('EEE d MMM', 'fr_FR').format(reservation.dateReservation);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAccepted ? Icons.check : Icons.hourglass_top,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAccepted ? 'Réservation validée' : 'Demande en attente',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateFr · ${reservation.heureReservation} · ${reservation.nbPersonnes} pers.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                if (isAccepted && reservation.code.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Code · ${reservation.code}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
