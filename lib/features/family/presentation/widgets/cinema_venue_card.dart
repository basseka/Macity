import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pulz_app/core/theme/mode_theme_provider.dart';
import 'package:pulz_app/features/family/data/cinema_venues_data.dart';

class CinemaVenueCard extends ConsumerWidget {
  final CinemaVenue cinema;

  const CinemaVenueCard({super.key, required this.cinema});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeTheme = ref.watch(modeThemeProvider);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
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
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cinema.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: modeTheme.primaryDarkColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cinema.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.access_time,
                      cinema.horaires,
                      modeTheme.primaryColor,
                    ),
                    const SizedBox(height: 3),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      cinema.adresse,
                      modeTheme.primaryColor,
                    ),
                    if (cinema.telephone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      GestureDetector(
                        onTap: () async {
                          final cleaned = cinema.telephone.replaceAll(' ', '');
                          final uri = Uri(scheme: 'tel', path: cleaned);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 13, color: modeTheme.primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              cinema.telephone,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: modeTheme.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (cinema.ticketUrl.isNotEmpty)
                          GestureDetector(
                            onTap: () => _openUrl(cinema.ticketUrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: modeTheme.primaryColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.confirmation_number_outlined,
                                    size: 12,
                                    color: modeTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Seances',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: modeTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _openUrl(cinema.lienMaps),
                          child: Icon(
                            Icons.map_outlined,
                            color: modeTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _openUrl(cinema.websiteUrl),
                          child: Icon(
                            Icons.language,
                            color: modeTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _share(),
                          child: Icon(
                            Icons.share_outlined,
                            color: Colors.grey.shade400,
                            size: 20,
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
