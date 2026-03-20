import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/widgets/venue_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/culture/data/monument_venues_data.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';

class MonumentVenueCard extends ConsumerWidget {
  final MonumentVenue monument;

  const MonumentVenueCard({super.key, required this.monument});

  static const _typeEmojis = {
    'Hotel particulier': '\uD83C\uDFDB\uFE0F',
    'Vestige': '\uD83C\uDFF0',
    'Edifice religieux': '\u26EA',
    'Pont': '\uD83C\uDF09',
    'Ouvrage hydraulique': '\u2699\uFE0F',
    'Immeuble': '\uD83C\uDFE0',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);
    final emoji = _typeEmojis[monument.type] ?? '\uD83C\uDFF0';

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
      elevation: 2,
      shadowColor: Colors.black12,
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
                  child: VenueImage(imageUrl: monument.image, defaultAsset: 'assets/images/pochette_theatre.png'),
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
                      monument.name,
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
                      Icons.location_on_outlined,
                      monument.adresse,
                      modeTheme.primaryColor,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _openUrl(monument.websiteUrl),
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
                            color: Colors.grey.shade400,
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
    ItemDetailSheet.show(
      context,
      ItemDetailSheet(
        title: monument.name,
        emoji: '',
        imageAsset: monument.image,
        infos: [
          if (monument.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, monument.description),
          if (monument.type.isNotEmpty)
            DetailInfoItem(Icons.category_outlined, monument.type),
          if (monument.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, monument.adresse),
        ],
        primaryAction: monument.websiteUrl.isNotEmpty
            ? DetailAction(icon: Icons.language, label: 'Site web', url: monument.websiteUrl)
            : null,
        shareText: '${monument.name}\n${monument.description}\n${monument.adresse}\n${monument.websiteUrl}\n\nDecouvre sur MaCity',
      ),
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
              color: Colors.grey.shade600,
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
    buffer.writeln(monument.name);
    buffer.writeln(monument.description);
    buffer.writeln(monument.adresse);
    buffer.writeln(monument.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
