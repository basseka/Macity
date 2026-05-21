import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/family/data/animal_park_venues_data.dart';

class AnimalParkVenueCard extends ConsumerWidget {
  final AnimalParkVenue park;

  const AnimalParkVenueCard({super.key, required this.park});

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
                        child: Image.asset('assets/images/sc_parc_animalier.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                      if (park.ticketUrl.isNotEmpty)
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
                      Text(
                        park.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: modeTheme.primaryDarkColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      _buildInfoRow(
                        Icons.access_time,
                        park.horaires,
                        modeTheme.primaryColor,
                      ),

                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => _openUrl(park.websiteUrl),
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
    const imagePath = 'assets/images/sc_parc_animalier.jpg';
    final commerce = CommerceModel(
      nom: park.name,
      categorie: 'Parc animalier',
      adresse: park.adresse,
      horaires: park.horaires,
      telephone: park.telephone,
      siteWeb: park.ticketUrl.isNotEmpty ? park.ticketUrl : park.websiteUrl,
      lienMaps: park.lienMaps,
      photo: imagePath,
      description: park.description,
    );
    CommerceRowCard.showDetailSheet(context, commerce, imageAsset: imagePath);
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
    buffer.writeln(park.name);
    buffer.writeln(park.description);
    buffer.writeln(park.adresse);
    buffer.writeln(park.telephone);
    buffer.writeln(park.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
