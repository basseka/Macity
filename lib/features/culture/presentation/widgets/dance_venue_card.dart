import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/widgets/venue_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/dance_venues_data.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/core/widgets/verified_badge.dart';

class DanceVenueCard extends ConsumerWidget {
  final DanceVenue dance;
  final List<CommerceModel>? pagerSiblings;
  final int? pagerIndex;

  const DanceVenueCard({
    super.key,
    required this.dance,
    this.pagerSiblings,
    this.pagerIndex,
  });

  /// Convertit un DanceVenue en CommerceModel — pour construire `pagerSiblings`.
  static CommerceModel toCommerce(DanceVenue dance) => CommerceModel(
        nom: dance.name,
        categorie: _categoryLabels[dance.category] ?? dance.category,
        adresse: dance.city,
        ville: dance.city,
        horaires: dance.horaires,
        siteWeb: dance.websiteUrl ?? '',
        photo: dance.image,
        description: dance.description,
        isVerified: dance.isVerified,
      );

  static const _categoryLabels = {
    'Ecole generale': 'Ecole generale',
    'Specialisation': 'Specialisation & style',
    'Formation pro': 'Formation professionnelle',
    'Autre': 'Ecole de danse',
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: VenueImage(imageUrl: dance.image, defaultAsset: 'assets/images/pochette_theatre.webp'),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dance.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: modeTheme.primaryDarkColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (dance.isVerified) ...[
                          const SizedBox(width: 4),
                          const VerifiedBadge.small(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),

                    if (dance.horaires.isNotEmpty)
                      _buildInfoRow(
                        Icons.access_time,
                        dance.horaires,
                        modeTheme.primaryColor,
                      ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (dance.websiteUrl != null)
                          GestureDetector(
                            onTap: () => _openUrl(dance.websiteUrl!),
                            child: Icon(
                              Icons.language,
                              color: modeTheme.primaryColor,
                              size: 16,
                            ),
                          ),
                        if (dance.websiteUrl != null)
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
    final isHttp = dance.image.startsWith('http');
    CommerceRowCard.openDetail(
      context,
      toCommerce(dance),
      imageAsset: isHttp ? null : dance.image,
      siblings: pagerSiblings,
      index: pagerIndex,
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
    buffer.writeln(dance.name);
    if (dance.description.isNotEmpty) {
      buffer.writeln(dance.description);
    }
    buffer.writeln(dance.city);
    if (dance.websiteUrl != null) {
      buffer.writeln(dance.websiteUrl);
    }
    buffer.writeln('\nDecouvre sur MaCity');

    Share.share(buffer.toString());
  }
}
