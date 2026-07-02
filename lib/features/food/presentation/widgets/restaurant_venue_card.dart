import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
import 'package:pulz_app/features/food/presentation/restaurant_detail_sheet.dart';
import 'package:pulz_app/core/widgets/verified_badge.dart';

class RestaurantVenueCard extends ConsumerWidget {
  final RestaurantVenue venue;

  const RestaurantVenueCard({super.key, required this.venue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
        elevation: 2,
        shadowColor: AppColors.line,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: modeTheme.primaryColor.withValues(alpha: 0.08),
                ),
                alignment: Alignment.center,
                child: const Text('\u{1F37D}\u{FE0F}', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            venue.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: modeTheme.primaryDarkColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (venue.isVerified) ...[
                          const SizedBox(width: 4),
                          const VerifiedBadge.small(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (venue.horaires.isNotEmpty)
                      _buildInfoRow(
                        Icons.access_time,
                        venue.horaires,
                        modeTheme.primaryColor,
                      )
                    else if (venue.adresse.isNotEmpty)
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        venue.adresse,
                        modeTheme.primaryColor,
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _share(),
                child: Icon(
                  Icons.share_outlined,
                  color: AppColors.textFaint,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    // Delegate au helper centralise pour que le bouton "Reserver" + badge
    // de reservations actives soient cohérents partout (carte / liste / map).
    RestaurantDetailSheet.show(context, venue);
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: AppColors.textDim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _share() {
    final buffer = StringBuffer();
    buffer.writeln(venue.name);
    buffer.writeln(venue.adresse);
    if (venue.telephone.isNotEmpty) buffer.writeln(venue.telephone);
    if (venue.websiteUrl.isNotEmpty) buffer.writeln(venue.websiteUrl);
    // Lien profond cliquable (WhatsApp auto-linke https). venue.id = id
    // etablissement. App Links macity.app/food/* ouvrent la fiche dans l'app.
    final id = int.tryParse(venue.id);
    if (id != null && id > 0) {
      buffer.writeln('\nDecouvre sur MaCity 👉');
      buffer.writeln('https://macity.app/lieu/etablissement/$id');
    } else {
      buffer.writeln('\nDecouvre sur MaCity');
    }
    Share.share(buffer.toString());
  }
}
