import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/core/widgets/item_detail_sheet.dart';
import 'package:pulz_app/features/family/data/cinema_venues_data.dart';

class CinemaVenueCard extends ConsumerWidget {
  final CinemaVenue cinema;

  const CinemaVenueCard({super.key, required this.cinema});

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
                child: Container(
                  color: modeTheme.primaryColor.withValues(alpha: 0.08),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('\uD83C\uDFAC', style: TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      if (cinema.ticketUrl.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SEANCES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
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
                        cinema.name,
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
                        cinema.horaires,
                        modeTheme.primaryColor,
                      ),

                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => _openUrl(cinema.websiteUrl),
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
        title: cinema.name,
        emoji: '\uD83C\uDFAC',
        infos: [
          if (cinema.horaires.isNotEmpty)
            DetailInfoItem(Icons.access_time, cinema.horaires),
          if (cinema.adresse.isNotEmpty)
            DetailInfoItem(Icons.location_on_outlined, cinema.adresse),
          if (cinema.telephone.isNotEmpty)
            DetailInfoItem(Icons.phone_outlined, cinema.telephone),
        ],
        primaryAction: cinema.ticketUrl.isNotEmpty
            ? DetailAction(icon: Icons.confirmation_number_outlined, label: 'Seances', url: cinema.ticketUrl)
            : cinema.websiteUrl.isNotEmpty
                ? DetailAction(icon: Icons.language, label: 'Site web', url: cinema.websiteUrl)
                : null,
        secondaryActions: [
          if (cinema.ticketUrl.isNotEmpty && cinema.websiteUrl.isNotEmpty)
            DetailAction(icon: Icons.language, label: 'Site web', url: cinema.websiteUrl),
          if (cinema.telephone.isNotEmpty)
            DetailAction(icon: Icons.phone_outlined, label: 'Appeler', url: 'tel:${cinema.telephone.replaceAll(' ', '')}'),
        ],
        shareText: '${cinema.name}\n${cinema.adresse}\n${cinema.telephone}\n${cinema.websiteUrl}\n\nDecouvre sur MaCity',
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
    buffer.writeln(cinema.name);
    buffer.writeln(cinema.adresse);
    buffer.writeln(cinema.telephone);
    buffer.writeln(cinema.websiteUrl);
    buffer.writeln('\nDecouvre sur MaCity');
    Share.share(buffer.toString());
  }
}
