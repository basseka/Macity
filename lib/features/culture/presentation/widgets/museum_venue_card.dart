import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/widgets/venue_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/museum_venues_data.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/core/widgets/verified_badge.dart';

class MuseumVenueCard extends ConsumerWidget {
  final MuseumVenue museum;

  const MuseumVenueCard({super.key, required this.museum});

  static const _categoryLabels = {
    'art': 'Art',
    'histoire': 'Histoire',
    'science': 'Science',
    'culture': 'Culture',
  };

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
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Pochette arrondie à gauche ──
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: VenueImage(imageUrl: museum.image, defaultAsset: 'assets/images/pochette_musee.webp'),
                    ),
                    if (museum.hasOnlineTicket)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BILLETTERIE',
                            style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Infos a droite ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            museum.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: modeTheme.primaryDarkColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (museum.isVerified) ...[
                          const SizedBox(width: 4),
                          const VerifiedBadge.small(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Horaires
                    if (museum.horaires.isNotEmpty)
                      _buildInfoRow(
                        Icons.access_time,
                        museum.horaires,
                        modeTheme.primaryColor,
                      ),

                    const Spacer(),

                    // Actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _openUrl(museum.websiteUrl),
                          child: Icon(
                            Icons.language,
                            color: modeTheme.primaryColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _openDetail(BuildContext context) {
    // Detail unifie (meme structure que Night : video/photo + galerie + avis).
    final isHttp = museum.image.startsWith('http');
    final commerce = CommerceModel(
      nom: museum.name,
      categorie: _categoryLabels[museum.category] ?? museum.category,
      adresse: museum.city,
      ville: museum.city,
      horaires: museum.horaires,
      siteWeb: museum.websiteUrl,
      photo: museum.image,
      description: museum.description,
      isVerified: museum.isVerified,
    );
    CommerceRowCard.showDetailSheet(
      context,
      commerce,
      imageAsset: isHttp ? null : museum.image,
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textDim,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _share() {
    final buffer = StringBuffer();
    buffer.writeln(museum.name);
    if (museum.description.isNotEmpty) {
      buffer.writeln(museum.description);
    }
    buffer.writeln(museum.city);
    buffer.writeln(museum.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');

    Share.share(buffer.toString());
  }
}
