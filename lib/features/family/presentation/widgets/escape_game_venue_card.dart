import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/family/data/escape_game_venues_data.dart';

class EscapeGameVenueCard extends ConsumerWidget {
  final EscapeGameVenue venue;

  const EscapeGameVenueCard({super.key, required this.venue});

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
              SizedBox(
                width: 90,
                child: Container(
                  color: modeTheme.primaryColor.withValues(alpha: 0.08),
                  alignment: Alignment.center,
                  child: const Text('\u{1F510}', style: TextStyle(fontSize: 30)),
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
        title: venue.name,
        emoji: '\u{1F510}',
        infos: [
          if (venue.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, venue.horaires),
          if (venue.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, venue.adresse),
          if (venue.telephone.isNotEmpty)
            DetailInfoItem(Icons.phone_outlined, venue.telephone),
        ],
        primaryAction: venue.websiteUrl.isNotEmpty
            ? DetailAction(icon: Icons.language, label: 'Site web', url: venue.websiteUrl)
            : null,
        secondaryActions: [
          if (venue.telephone.isNotEmpty)
            DetailAction(icon: Icons.phone_outlined, label: 'Appeler', url: 'tel:${venue.telephone.replaceAll(' ', '')}'),
        ],
        shareText: '${venue.name}\n${venue.adresse}\n${venue.telephone}\n${venue.websiteUrl}\n\nDecouvre sur MaCity',
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
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
    buffer.writeln(venue.telephone);
    buffer.writeln(venue.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
