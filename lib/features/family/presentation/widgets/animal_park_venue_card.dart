import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
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
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Pochette a gauche ──
              SizedBox(
                width: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/sc_parc_animalier.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Emoji badge
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '\uD83E\uDD81',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    // Billetterie badge
                    if (park.ticketUrl.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'BILLETTERIE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                          fontSize: 12,
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
        title: park.name,
        emoji: '\uD83E\uDD81',
        imageAsset: 'assets/images/sc_parc_animalier.png',
        infos: [
          if (park.description.isNotEmpty)
            DetailInfoItem(Icons.info_outline, park.description),
          if (park.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, park.horaires),
          if (park.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, park.adresse),
          if (park.telephone.isNotEmpty)
            DetailInfoItem(Icons.phone_outlined, park.telephone),
        ],
        primaryAction: park.ticketUrl.isNotEmpty
            ? DetailAction(icon: Icons.confirmation_number_outlined, label: 'Billetterie', url: park.ticketUrl)
            : park.websiteUrl.isNotEmpty
                ? DetailAction(icon: Icons.language, label: 'Site web', url: park.websiteUrl)
                : null,
        secondaryActions: [
          if (park.ticketUrl.isNotEmpty && park.websiteUrl.isNotEmpty)
            DetailAction(icon: Icons.language, label: 'Site web', url: park.websiteUrl),
          if (park.telephone.isNotEmpty)
            DetailAction(icon: Icons.phone_outlined, label: 'Appeler', url: 'tel:${park.telephone.replaceAll(' ', '')}'),
        ],
        shareText: '${park.name}\n${park.description}\n${park.adresse}\n${park.telephone}\n${park.websiteUrl}\n\nDecouvre sur MaCity',
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
    buffer.writeln(park.name);
    buffer.writeln(park.description);
    buffer.writeln(park.adresse);
    buffer.writeln(park.telephone);
    buffer.writeln(park.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
