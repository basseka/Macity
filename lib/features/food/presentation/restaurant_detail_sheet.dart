import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/food/data/restaurant_reservation_service.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
import 'package:pulz_app/features/food/presentation/reservation_form_sheet.dart';
import 'package:pulz_app/features/food/state/restaurant_reservation_provider.dart';

/// Ouvre le bottom sheet detail d'un restaurant.
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

    final venueIdInt = int.tryParse(venue.id) ?? 0;

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
        // Bloc "Reserver" + badges reservations en haut de la fiche (avant les
        // infos) pour qu'on ne puisse pas le rater. extraContent est rendu
        // juste apres le titre, gros CTA gradient avec icone calendrier.
        extraContent: _ReservationBlock(
          venueId: venueIdInt,
          venueName: venue.name,
        ),
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
          if (venue.websiteUrl.isNotEmpty)
            DetailAction(
              icon: Icons.language,
              label: 'Site web',
              url: venue.websiteUrl,
            ),
        ],
        shareText:
            '${venue.name}\n${venue.adresse}\n${venue.telephone.isNotEmpty ? '${venue.telephone}\n' : ''}${venue.websiteUrl}\n\nDecouvre sur MaCity',
      ),
    );
  }
}

/// Bloc affiche en haut de la fiche resto : gros CTA "Reserver" + badges
/// des reservations actives (pending / accepted) si l'user en a.
class _ReservationBlock extends ConsumerWidget {
  final int venueId;
  final String venueName;
  const _ReservationBlock({required this.venueId, required this.venueName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = venueId > 0
        ? ref.watch(activeReservationsProvider(venueId))
        : const AsyncValue<List<RestaurantReservation>>.data([]);
    return async.when(
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badges si reservations actives
          ...list.map((r) => _ReservationBadge(reservation: r)),
          if (list.isNotEmpty) const SizedBox(height: 4),
          // CTA Reserver
          _ReserverCta(venueId: venueId, venueName: venueName),
          const SizedBox(height: 4),
        ],
      ),
      loading: () => _ReserverCta(venueId: venueId, venueName: venueName),
      error: (_, __) => _ReserverCta(venueId: venueId, venueName: venueName),
    );
  }
}

class _ReserverCta extends StatelessWidget {
  final int venueId;
  final String venueName;
  const _ReserverCta({required this.venueId, required this.venueName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () {
            if (venueId <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Réservation indisponible pour ce restaurant.'),
                ),
              );
              return;
            }
            ReservationFormSheet.show(
              context,
              venueId: venueId,
              venueName: venueName,
            );
          },
          icon: const Icon(Icons.event_available, size: 20),
          label: const Text(
            'Réserver une table',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B2D8E),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            shadowColor: const Color(0xFF7B2D8E).withValues(alpha: 0.4),
          ),
        ),
      ),
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
    final dateFr = DateFormat('EEE d MMM', 'fr_FR').format(reservation.dateReservation);
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
                    color: Colors.grey.shade700,
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
