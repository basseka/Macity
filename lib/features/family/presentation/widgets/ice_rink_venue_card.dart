import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/commerce_row_card.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/family/data/ice_rink_venues_data.dart';

class IceRinkVenueCard extends ConsumerWidget {
  final IceRinkVenue venue;

  const IceRinkVenueCard({super.key, required this.venue});

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
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: modeTheme.primaryColor.withValues(alpha: 0.08),
                  ),
                  alignment: Alignment.center,
                  child: const Text('\u{26F8}\u{FE0F}', style: TextStyle(fontSize: 24)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
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
                        venue.horaires,
                        modeTheme.primaryColor,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => _openUrl(venue.websiteUrl),
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
    final description = [
      if (venue.description.isNotEmpty) venue.description,
      if (venue.tarif.isNotEmpty) 'Tarif : ${venue.tarif}',
    ].join('\n\n');
    final commerce = CommerceModel(
      nom: venue.name,
      categorie: 'Patinoire',
      adresse: venue.adresse,
      horaires: venue.horaires,
      telephone: venue.telephone,
      siteWeb: venue.websiteUrl,
      lienMaps: venue.lienMaps,
      latitude: venue.latitude,
      longitude: venue.longitude,
      description: description,
    );
    CommerceRowCard.showDetailSheet(context, commerce);
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _share() {
    final buffer = StringBuffer();
    buffer.writeln(venue.name);
    buffer.writeln(venue.adresse);
    buffer.writeln(venue.tarif);
    buffer.writeln(venue.telephone);
    buffer.writeln(venue.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
